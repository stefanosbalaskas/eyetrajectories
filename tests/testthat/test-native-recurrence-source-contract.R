# Frozen Python 1.2.0 reference: recurrence_networks.py at
# c1cd95ad718327550f7e55393ff38582872f7a94.
# Scientific graph geometry can be source-matched without certifying
# Python sparse CSR/dataclass identity as native R S3/dense-matrix parity.

.etr_recurrence_source_fixture <- function(){
  x<-etr_trajectory_set(as.numeric(0:5),
    array(c(0,0,0,5,5,11),dim=c(1L,6L,1L)),"curve","x",
    coordinate_system="unknown",time_unit="s")
  list(trajectory=x,recurrence=etr_recurrence_matrix(x,curve=1L,
    radius=.01,theiler=0L))
}

test_that("canonical recurrence network is source-aligned and legacy R view is explicit",{
  z<-.etr_recurrence_source_fixture()
  net<-etr_recurrence_network(z$recurrence)
  expect_identical(net$edge_count,4L)
  expect_equal(net$graph_density,4/15,tolerance=0)
  expect_identical(net$degree,c(2L,2L,2L,1L,1L,0L))
  expect_equal(net$local_clustering,c(1,1,1,0,0,0),tolerance=0)
  expect_identical(net$component_labels,c(0L,0L,0L,1L,1L,2L))
  expect_identical(net$component_sizes,c(3L,2L,1L))
  expect_identical(net$n_connected_components,3L)
  expect_equal(net$mean_local_clustering,.5,tolerance=0)
  expect_equal(net$transitivity,1,tolerance=0)
  expect_equal(net$isolated_node_fraction,1/6,tolerance=0)
  expect_equal(net$largest_component_fraction,.5,tolerance=0)
  expect_identical(net$n_nodes,6L)
  expect_equal(net$n_edges,net$edge_count)
  expect_equal(net$density,net$graph_density)
  expect_equal(net$triangles,1)
  expect_identical(net$n_components,net$n_connected_components)
  expect_identical(net$component,net$component_labels+1L)
  expect_identical(net$provenance$local_clustering_degree_lt_2,0)
  expect_identical(net$provenance$dense_adjacency_materialized,TRUE)
  expect_identical(net$provenance$legacy_R_alias_fields_present,TRUE)
  exact<-etr_recurrence_network_node_frame(net)
  legacy<-etr_recurrence_network_nodes(net)
  expect_identical(names(exact),c("node_index","time","degree",
    "normalized_degree","local_clustering","component","component_size"))
  expect_identical(exact$local_clustering,c(1,1,1,0,0,0))
  expect_identical(exact$component,c(0L,0L,0L,1L,1L,2L))
  expect_true(all(is.na(legacy$clustering[4:6])))
  expect_identical(legacy$component,c(1L,1L,1L,2L,2L,3L))
  expect_identical(legacy$degree,as.numeric(exact$degree))
  expect_true(grepl("Theiler window of 0 samples",
    etr_recurrence_network_reporting_text(net),fixed=TRUE))
  expect_identical(etr_recurrence_network_summary_frame(net)$edge_count,4L)
  rec<-z$recurrence;rec$matrix[,]<-FALSE;rec$recurrence_rate<-0
  empty<-etr_recurrence_network(rec)
  expect_identical(empty$edge_count,0L)
  expect_identical(empty$degree,rep(0L,6L))
  expect_identical(empty$local_clustering,rep(0,6L))
  expect_true(is.nan(empty$transitivity))
  expect_equal(empty$isolated_node_fraction,1)
  expect_identical(empty$n_connected_components,6L)
})

test_that("native graph entrypoint has exactly one public function definition",{
  root<-normalizePath(file.path(testthat::test_path(),"..",".."),
    mustWork=TRUE)
  if(!dir.exists(file.path(root,"R")))skip("source tree is unavailable")
  files<-list.files(file.path(root,"R"),pattern="\\.R$",
    full.names=TRUE)
  lines<-lapply(files,readLines,warn=FALSE)
  matches<-vapply(lines,function(x)sum(grepl(
    "^etr_recurrence_network[[:space:]]*<-[[:space:]]*function",x)),
    integer(1L))
  expect_identical(sum(matches),1L)
  expect_identical(basename(files[which(matches>0L)]),
    "native-nonlinear-recurrence.R")
})

test_that("published Python 1.2 recurrence network matches real triangle-and-isolates",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("published Python 1.2 network topology oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  x<-.etr_recurrence_source_fixture()
  ctor<-etpy_get_export("TrajectorySet")
  pyx<-reticulate::py_call(ctor,time=reticulate::r_to_py(x$trajectory$time),
    values=reticulate::r_to_py(x$trajectory$values),
    curve_ids=as.list(x$trajectory$curve_ids),
    dimension_names=as.list(x$trajectory$dimension_names),
    coordinate_system="unknown",time_unit="s")
  pyrec<-reticulate::py_call(etpy_get_export("recurrence_matrix"),
    source=pyx,curve=as.integer(0L),radius=.01,
    theiler_window=as.integer(0L),dimensions=as.list("x"))
  pygraph<-reticulate::py_call(etpy_get_export("recurrence_network"),
    recurrence=pyrec)
  rgraph<-etr_recurrence_network(x$recurrence)
  for(name in c("edge_count","graph_density","mean_local_clustering",
    "transitivity","n_connected_components",
    "largest_component_fraction","isolated_node_fraction")){
    native<-rgraph[[name]]
    source<-as.numeric(et_to_r(reticulate::py_get_attr(pygraph,name)))
    expect_equal(as.numeric(native),source,tolerance=1e-12,info=name)
  }
  for(name in c("degree","normalized_degree","local_clustering",
    "component_labels","component_sizes")){
    native<-as.numeric(rgraph[[name]])
    source<-as.numeric(et_to_r(reticulate::py_get_attr(pygraph,name)))
    expect_equal(native,source,tolerance=1e-12,info=name)
  }
  python_nodes<-et_to_r(reticulate::py_call(
    etpy_get_export("recurrence_network_node_frame"),result=pygraph))
  native_nodes<-etr_recurrence_network_node_frame(rgraph)
  for(col in names(native_nodes))
    expect_equal(unname(native_nodes[[col]]),
      unname(python_nodes[[col]]),tolerance=1e-12,info=col)
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
