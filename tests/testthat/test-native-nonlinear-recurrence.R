# Stage 8: source-verified native-R nonlinear recurrence tests.
# Python imported only with ET_RUN_PYTHON_TESTS="true".

test_that("recurrence-network triangle and connected-component cases are exact",{
  time <- 0:5
  adj <- matrix(FALSE,6,6)
  edges <- rbind(c(1,2),c(2,3),c(1,3),c(4,5))
  for(k in seq_len(nrow(edges))){
    a<-edges[k,1L];b<-edges[k,2L]
    adj[a,b]<-adj[b,a]<-TRUE
  }
  rec<-structure(list(matrix=adj,kind="auto",time=as.numeric(time),
    time_unit="s",theiler=0L,radius=.5,recurrence_rate=sum(adj)/30),
    class="etr_recurrence")
  net<-etr_recurrence_network(rec)
  expect_equal(net$edge_count,4L)
  expect_equal(net$degree,c(2L,2L,2L,1L,1L,0L))
  expect_equal(net$graph_density,4/15)
  expect_equal(net$local_clustering,c(1,1,1,0,0,0))
  expect_equal(net$transitivity,1)
  expect_equal(net$n_connected_components,3L)
  expect_equal(net$component_sizes,c(3L,2L,1L))
  expect_equal(net$component_labels,c(0L,0L,0L,1L,1L,2L))
  expect_equal(net$largest_component_fraction,.5)
  expect_equal(net$isolated_node_fraction,1/6)
  nodes<-etr_recurrence_network_node_frame(net)
  expect_identical(nodes$node_index,0:5)
  expect_identical(nodes$component_size,c(3L,3L,3L,2L,2L,1L))
  summary<-etr_recurrence_network_summary_frame(net)
  expect_equal(summary$edge_count,4L)
  expect_equal(summary$mean_degree,8/6)
  expect_equal(summary$transitivity,1)
  expect_error(etr_recurrence_network(etr_cross_recurrence_matrix(
    matrix(1:6,ncol=1),matrix(2:7,ncol=1),radius=2)),"auto")
  incorrect<-rec;incorrect$matrix[1,2]<-FALSE
  expect_error(etr_recurrence_network(incorrect),"symmetric")
  expect_error(etr_recurrence_network_node_frame(list()),"result")
})

test_that("joint recurrence is synchronized, exact and fail-closed",{
  arr<-array(0,c(2L,8L,1L))
  arr[1L,,1L]<-c(0,0,0,1,1,2,2,2)
  arr[2L,,1L]<-c(0,0,1,1,1,2,2,2)
  x<-etr_trajectory_set(0:7,arr,c("A","B"),"x",
                        time_unit="s")
  r1<-etr_recurrence_matrix(x,curve="A",radius=.01,theiler=1L)
  r2<-etr_recurrence_matrix(x,curve="B",radius=.01,theiler=1L)
  joint<-etr_joint_recurrence_matrix(list(r1,r2),labels=c("X","Y"))
  expect_s3_class(joint,"etr_joint_recurrence")
  expect_identical(joint$matrix,r1$matrix & r2$matrix)
  expect_equal(joint$n_joint_recurrent_pairs,
               sum(joint$matrix[upper.tri(joint$matrix)]))
  expect_equal(joint$joint_recurrence_rate,
               joint$n_joint_recurrent_pairs/joint$eligible_pair_count)
  table<-etr_joint_recurrence_component_frame(joint)
  expect_identical(table$label,c("X","Y"))
  expect_identical(table$theiler_window_samples,c(1L,1L))
  rqa<-etr_joint_rqa_metrics(joint)
  expect_equal(rqa$recurrence_rate,joint$joint_recurrence_rate)
  expect_true(is.numeric(rqa$center_of_recurrence_mass))
  expect_true(all(c("min_diagonal_length","n_diagonal_lines",
                    "laminarity") %in% names(rqa)))
  expect_error(etr_joint_recurrence_matrix(list(r1)),"at least two")
  # A malformed component must fail its *own* grid validation.
  bad<-r2;bad$time[1]<-99
  expect_error(etr_joint_recurrence_matrix(list(r1,bad)),
               "strictly increasing")
  # A valid but different grid reaches the cross-component alignment check.
  bad<-r2;bad$time<-r2$time+0.5
  expect_true(all(diff(bad$time)>0))
  expect_error(etr_joint_recurrence_matrix(list(r1,bad)),
               "same time grid")
  bad<-r2;bad$theiler<-0L
  expect_error(etr_joint_recurrence_matrix(list(r1,bad)),"same Theiler")
  expect_error(etr_joint_recurrence_matrix(list(r1,r2),
               labels=c("same","same")),"labels")
})

test_that("radius profiles count empirical CDF exactly without choosing a radius",{
  v<-array(c(0,1,2,3,4),c(1L,5L,1L))
  x<-etr_trajectory_set(0:4,v,"A","x",time_unit="s")
  p<-etr_recurrence_radius_profile(x,"A",c(.5,1,1.5,3),theiler_window=1L)
  expect_equal(p$eligible_pair_count,6L)
  expect_equal(p$table$cumulative_recurrent_pairs,c(0L,0L,0L,5L))
  expect_equal(p$table$excluded_theiler_pairs_within_radius,
               c(0L,4L,4L,4L))
  expect_equal(p$table$recurrence_rate,c(0,0,0,5/6))
  expect_equal(p$table$shell_pair_count,c(0L,0L,0L,5L))
  expect_true(is.na(p$table$previous_radius[1L]))
  expect_error(etr_recurrence_radius_profile(x,radii=c(1,1)),
               "strictly increasing")
  expect_error(etr_recurrence_radius_profile(x,radii=c(-1,2)),
               "positive")
  expect_error(etr_recurrence_radius_profile(x,radii=c(1,2),
               metric="unknown"),"metric")
  expect_error(etr_recurrence_radius_profile(x,radii=c(1,2),
               theiler_window_units="time"),"cannot be converted")
  physical<-etr_recurrence_radius_profile(x,"A",c(.5,1,1.5,3),
    theiler_window=1,theiler_window_units="s")
  expect_identical(physical$theiler_window_samples,1L)
  expect_equal(physical$table,p$table,tolerance=0)
})

test_that("windowed RQA accounts for non-independent overlapping windows",{
  v<-array(0,c(2L,12L,1L))
  v[1L,,1L]<-rep(c(0,1,2),4)
  v[2L,,1L]<-rep(c(0,0,1,1),3)
  x<-etr_trajectory_set(0:11,v,c("a","b"),"x",
                        time_unit="s",
                        provenance=list(source="recording"))
  w<-etr_windowed_rqa(x,curve="a",window=6L,step=2L,
                       radius=1.1)
  expect_s3_class(w,"etr_windowed_rqa")
  expect_equal(nrow(w$table),4L)
  expect_equal(w$table$start_index,c(0L,2L,4L,6L))
  expect_equal(w$table$stop_index,c(6L,8L,10L,12L))
  expect_equal(w$table$center_time,c(2.5,4.5,6.5,8.5))
  expect_equal(w$dropped_tail_samples,0L)
  expect_error(etr_windowed_rqa(x,window=4,step=5,radius=1),
               "step")
  # Frozen Python 1.2 requires exactly one of fixed radius or
  # target_recurrence_rate; this formerly tested an R-only fixed-radius
  # restriction, which Batch C intentionally removed.
  expect_error(etr_windowed_rqa(x,window=3,step=1,
               radius=1,target_recurrence_rate=.05),
               "supply exactly one of radius or target_recurrence_rate")
  f<-etr_windowed_rqa_trajectory_set(x,c("recurrence_rate","determinism"),
    window=6L,step=2L,radius=1.1,undefined_policy="keep")
  expect_s3_class(f,"etr_windowed_rqa_functional")
  expect_identical(dim(f$trajectories$values),c(2L,4L,2L))
  expect_equal(f$trajectories$time,w$table$center_time)
  expect_equal(f$overlap_samples,4L)
  expect_equal(f$overlap_fraction,4/6)
  expect_false(f$trajectories$provenance$window_rows_are_independent)
  expect_equal(f$trajectories$values[1L,,1L],w$table$recurrence_rate)
  expect_error(etr_windowed_rqa_trajectory_set(
      x,c("unknown"),window=6L,step=2L,radius=1),
      "Unknown")
})

test_that("cross RQA has no automatically defined recurrence center of mass",{
  a<-matrix(c(0,0,1,1,2,2),ncol=2L,byrow=TRUE)
  b<-matrix(c(0,0,1,1,2,2),ncol=2L,byrow=TRUE)
  cr<-etr_cross_recurrence_matrix(a,b,radius=.01)
  metrics<-etr_cross_rqa_metrics(cr)
  expect_true(is.nan(metrics$center_of_recurrence_mass))
  expect_equal(metrics$recurrence_rate,cr$recurrence_rate)
  expect_error(etr_cross_rqa_metrics(list()),"cross")
})

test_that("Python 1.2 independent recurrence network, joint and radius oracles agree",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Python 1.2 recurrence-network and nonlinear RQA oracle is opt-in")
  expect_identical(as.character(et_python_version()),"1.2.0")
  ctor<-etpy_get_export("TrajectorySet")
  py_rec<-etpy_get_export("recurrence_matrix")
  py_net<-etpy_get_export("recurrence_network")
  py_node<-etpy_get_export("recurrence_network_node_frame")
  py_summary<-etpy_get_export("recurrence_network_summary_frame")
  py_joint<-etpy_get_export("joint_recurrence_matrix")
  py_joint_frame<-etpy_get_export("joint_recurrence_component_frame")
  py_joint_rqa<-etpy_get_export("joint_rqa_metrics")
  py_cross<-etpy_get_export("cross_recurrence_matrix")
  py_cross_rqa<-etpy_get_export("cross_rqa_metrics")
  py_radius<-etpy_get_export("recurrence_radius_profile")
  py_win<-etpy_get_export("windowed_rqa")
  py_func<-etpy_get_export("windowed_rqa_trajectory_set")
  nt<-12L
  values<-array(0,c(2L,nt,1L))
  values[1L,,1L]<-rep(c(0,0,1,1),3)
  values[2L,,1L]<-rep(c(0,1,0,1),3)
  x<-etr_trajectory_set(0:(nt-1L),values,c("A","B"),"x",
                       coordinate_system="pixels",time_unit="s")
  py_x<-reticulate::py_call(ctor,time=x$time,
    values=reticulate::r_to_py(values),
    curve_ids=as.list(x$curve_ids),dimension_names=as.list("x"),
    coordinate_system="pixels",time_unit="s")
  compare_na<-function(a,b,label) {
    expect_identical(is.na(a),is.na(b),info=label)
    if(any(is.finite(b)))expect_equal(
       as.numeric(a[is.finite(b)]),
       as.numeric(b[is.finite(b)]),tolerance=1e-10,info=label)
  }
  r<-vector("list",2L);p<-vector("list",2L)
  for(i in 1:2) {
    r[[i]]<-etr_recurrence_matrix(x,i,radius=.5,theiler=1L)
    p[[i]]<-reticulate::py_call(py_rec,source=py_x,
       curve=as.integer(i-1L),radius=.5,theiler_window=1L,
       dimensions=as.list("x"))
    native<-etr_recurrence_network(r[[i]])
    python<-reticulate::py_call(py_net,recurrence=p[[i]])
    expect_equal(native$degree,as.integer(et_to_r(python$degree)))
    compare_na(native$local_clustering,
       as.numeric(et_to_r(python$local_clustering)),"local clustering")
    compare_na(native$transitivity,
       as.numeric(et_to_r(python$transitivity)),"transitivity")
    expect_equal(native$edge_count,
       as.integer(et_to_r(python$edge_count)))
    expect_equal(native$component_sizes,
       as.integer(et_to_r(python$component_sizes)))
    tab<-etr_recurrence_network_node_frame(native)
    pytab<-et_to_r(reticulate::py_call(py_node,result=python))
    for(col in c("node_index","degree","normalized_degree",
                 "local_clustering","component","component_size"))
      compare_na(tab[[col]],pytab[[col]],paste("network",i,col))
    sm<-etr_recurrence_network_summary_frame(native)
    pysm<-et_to_r(reticulate::py_call(py_summary,result=python))
    for(col in c("edge_count","graph_density","mean_degree",
                 "mean_local_clustering","transitivity",
                 "n_connected_components","largest_component_fraction"))
      compare_na(sm[[col]],pysm[[col]],paste("summary",i,col))
    if(i==1L) {
      radii<-c(.1,.5,1,1.5,2.5)
      rr<-etr_recurrence_radius_profile(x,i,radii,theiler_window=1L)
      pr<-reticulate::py_call(py_radius,source=py_x,
        curve=as.integer(0L),radii=as.list(radii),
        theiler_window=1L,dimensions=as.list("x"))
      table<-et_to_r(pr$table)
      for(col in names(rr$table))compare_na(rr$table[[col]],
        table[[col]],paste("radius",col))
    }
  }
  j<-etr_joint_recurrence_matrix(r,labels=c("A","B"))
  pj<-reticulate::py_call(py_joint,recurrences=p,
    labels=as.list(c("A","B")))
  expect_equal(j$joint_recurrence_rate,
    as.numeric(et_to_r(pj$joint_recurrence_rate)))
  expect_equal(j$n_joint_recurrent_pairs,
    as.integer(et_to_r(pj$n_joint_recurrent_pairs)))
  jt<-etr_joint_recurrence_component_frame(j)
  pyjt<-et_to_r(reticulate::py_call(py_joint_frame,result=pj))
  for(col in c("radius","achieved_recurrence_rate",
               "state_dimension","theiler_window_samples"))
    compare_na(jt[[col]],pyjt[[col]],paste("joint component",col))
  jr<-etr_joint_rqa_metrics(j)
  pjr<-reticulate::py_call(py_joint_rqa,result=pj)
  for(col in c("recurrence_rate","determinism","laminarity",
               "center_of_recurrence_mass","trapping_time"))
    compare_na(jr[[col]],as.numeric(et_to_r(
      reticulate::py_get_attr(pjr,col))),paste("joint RQA",col))
  a<-matrix(values[1L,,1L],ncol=1L)
  b<-matrix(values[2L,,1L],ncol=1L)
  cross_r<-etr_cross_rqa_metrics(etr_cross_recurrence_matrix(
    a,b,radius=.5))
  pcross<-reticulate::py_call(py_cross,source_a=py_x,source_b=py_x,
    curve_a=0L,curve_b=1L,radius=.5,
    dimensions_a=as.list("x"),dimensions_b=as.list("x"))
  pcross_r<-reticulate::py_call(py_cross_rqa,recurrence=pcross)
  for(col in c("recurrence_rate","determinism","laminarity",
               "trapping_time","center_of_recurrence_mass"))
    compare_na(cross_r[[col]],as.numeric(et_to_r(
      reticulate::py_get_attr(pcross_r,col))),paste("cross RQA",col))
  win<-etr_windowed_rqa(x,1L,window=6L,step=2L,radius=.5,
                        theiler_window=1L)
  pwin<-reticulate::py_call(py_win,trajectories=py_x,
    curve=as.integer(0L),window=6L,step=2L,radius=.5,
    theiler_window=1L,dimensions=as.list("x"))
  pytable<-et_to_r(pwin$table)
  for(col in c("start_index","stop_index","center_time",
               "recurrence_rate","determinism","laminarity",
               "center_of_recurrence_mass"))
    compare_na(win$table[[col]],pytable[[col]],paste("windowed",col))
  functional<-etr_windowed_rqa_trajectory_set(
    x,metrics="recurrence_rate",window=6L,step=2L,radius=.5,
    theiler_window=1L,dimensions="x")
  pfunctional<-reticulate::py_call(py_func,trajectories=py_x,
    metrics=as.list("recurrence_rate"),window=6L,step=2L,
    radius=.5,theiler_window=1L,dimensions=as.list("x"))
  expect_identical(dim(functional$trajectories$values),
    dim(et_to_r(pfunctional$trajectories$values)))
  compare_na(as.vector(functional$trajectories$values),
    as.vector(et_to_r(pfunctional$trajectories$values)),
    "functional-window RQA")
  expect_equal(functional$overlap_fraction,
    as.numeric(et_to_r(pfunctional$overlap_fraction)))
})


test_that("source-selected windowed RQA ignores unrelated missing channels",{
  t<-as.numeric(0:17)
  values<-array(0,c(2L,length(t),2L))
  for(i in seq_len(2L)){
    values[i,,1L]<-sin(t/3+i/4)+.08*t
    values[i,,2L]<-cos(t/4+i/3)
  }
  x<-etr_trajectory_set(t,values,c("A","B"),c("x","y"),
    coordinate_system="arbitrary",time_unit="s",
    provenance=list(origin="selected_window_input"))
  missing<-x
  missing$values[1L,2L,2L]<-NA_real_
  missing$values[2L,4L,2L]<-NA_real_
  baseline<-etr_windowed_rqa(x,curve="A",window=6L,step=3L,
    radius=1.2,dimensions="x")
  selected<-etr_windowed_rqa(missing,curve="A",window=6L,
    step=3L,radius=1.2,dimensions="x")
  expect_equal(selected$table,baseline$table,tolerance=0)
  expect_identical(selected$provenance$source_provenance,x$provenance)
  expect_identical(selected$provenance$window_samples,6L)
  expect_identical(selected$provenance$step_samples,3L)
  expect_identical(selected$provenance$dropped_tail_samples,
    selected$dropped_tail_samples)
  target<-etr_windowed_rqa(missing,curve="A",window=6L,step=3L,
    target_recurrence_rate=.35,dimensions="x")
  expected_target<-etr_windowed_rqa(x,curve="A",window=6L,step=3L,
    target_recurrence_rate=.35,dimensions="x")
  expect_equal(target$table,expected_target$table,tolerance=0)
  functional<-etr_windowed_rqa_trajectory_set(missing,
    metrics="recurrence_rate",window=6L,step=3L,
    radius=1.2,dimensions="x")
  full<-etr_windowed_rqa_trajectory_set(x,
    metrics="recurrence_rate",window=6L,step=3L,
    radius=1.2,dimensions="x")
  expect_equal(functional$trajectories$values,
    full$trajectories$values,tolerance=0)
  provenance<-functional$trajectories$provenance
  expect_identical(provenance$source_provenance,x$provenance)
  expect_identical(provenance$source_dimension_names,"x")
  expect_identical(provenance$metric_units$recurrence_rate,"proportion")
  expect_false(provenance$window_rows_are_independent)
  expect_identical(provenance$radius_policy,"fixed")
  expect_identical(provenance$dropped_tail_samples,
    functional$dropped_tail_samples)
  expect_error(etr_windowed_rqa(missing,curve="A",window=6L,
    step=3L,radius=1.2,dimensions="y"),"complete finite selected")
  expect_error(etr_windowed_rqa_trajectory_set(missing,
    metrics="recurrence_rate",window=6L,step=3L,
    radius=1.2,dimensions="y"),"complete finite selected")
})


test_that("frozen Python 1.2 windowed and functional RQA match selected source channels",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Published Python 1.2 windowed RQA selected-channel oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  t<-as.numeric(0:17)
  values<-array(0,c(2L,length(t),2L))
  for(i in seq_len(2L)){
    values[i,,1L]<-sin(t/3+i/4)+.08*t
    values[i,,2L]<-cos(t/4+i/3)
  }
  x<-etr_trajectory_set(t,values,c("A","B"),c("x","y"),
    coordinate_system="arbitrary",time_unit="s",
    provenance=list(origin="window_source_direct"))
  px<-reticulate::py_call(etpy_get_export("TrajectorySet"),
    time=reticulate::r_to_py(x$time),
    values=reticulate::r_to_py(x$values),
    curve_ids=as.list(x$curve_ids),
    dimension_names=as.list(x$dimension_names),
    coordinate_system="arbitrary",time_unit="s")
  for(metric in c("cityblock","euclidean","chebyshev")){
    native<-etr_windowed_rqa(x,curve="A",window=6L,step=3L,
      radius=1.2,metric=metric,dimensions="x")
    py<-reticulate::py_call(etpy_get_export("windowed_rqa"),
      trajectories=px,curve="A",window=as.integer(6L),
      step=as.integer(3L),radius=1.2,metric=metric,
      dimensions=as.list("x"))
    source_table<-as.data.frame(et_to_r(
      reticulate::py_get_attr(py,"table")))
    for(column in c("start_index","stop_index","start_time",
      "end_time","center_time","radius","recurrence_rate",
      "determinism","mean_diagonal_length","max_diagonal_length",
      "diagonal_entropy","laminarity","trapping_time",
      "max_vertical_length","center_of_recurrence_mass")){
      a<-as.numeric(native$table[[column]])
      b<-as.numeric(source_table[[column]])
      expect_identical(is.na(a),is.na(b),info=paste(metric,column))
      if(any(is.finite(b)))
        expect_equal(a[is.finite(b)],b[is.finite(b)],
          tolerance=1e-10,info=paste(metric,column))
    }
  }
  native_functional<-etr_windowed_rqa_trajectory_set(x,
    metrics="recurrence_rate",window=6L,step=3L,
    radius=1.2,dimensions="x")
  source_functional<-reticulate::py_call(
    etpy_get_export("windowed_rqa_trajectory_set"),
    trajectories=px,metrics=as.list("recurrence_rate"),
    window=as.integer(6L),step=as.integer(3L),
    radius=1.2,dimensions=as.list("x"))
  expect_equal(native_functional$trajectories$values,
    et_to_r(source_functional$trajectories$values),tolerance=1e-10)
  expect_equal(native_functional$trajectories$time,
    as.numeric(et_to_r(source_functional$trajectories$time)),
    tolerance=0)
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})


test_that("native recurrence networks support 900 nodes with exact path and triangle components",{
  n_groups<-300L
  positions<-rep(10*seq.int(0L,n_groups-1L),each=3L)+
    rep(c(0,.1,.2),n_groups)
  t<-as.numeric(seq_along(positions)-1L)
  x<-etr_trajectory_set(t,array(positions,dim=c(1L,length(t),1L)),
    curve_ids="A",dimension_names="x",
    coordinate_system="arbitrary",time_unit="s")
  for(radius in c(.15,.25)){
    rec<-etr_recurrence_matrix(x,curve="A",radius=radius)
    network<-etr_recurrence_network(rec)
    expect_s3_class(network,"etr_recurrence_network")
    expect_identical(network$n_nodes,900L)
    expect_identical(network$n_connected_components,300L)
    expect_identical(network$component_sizes,rep(3L,300L))
    expect_identical(network$component_labels,
      rep(seq.int(0L,299L),each=3L))
    expected_triangles<-if(radius>.2)300L else 0L
    expected_edges<-if(radius>.2)900L else 600L
    expect_identical(network$edge_count,expected_edges)
    expect_equal(network$triangles,expected_triangles,tolerance=0)
    expect_equal(network$transitivity,
      if(radius>.2)1 else 0,tolerance=0)
    expect_identical(network$provenance$triangle_count_method,
      "forward_neighbor_intersections")
    expect_identical(network$provenance$connected_components_method,
      "queue_head_breadth_first_search")
    expect_equal(network$isolated_node_fraction,0,tolerance=0)
    expect_identical(nrow(etr_recurrence_network_node_frame(network)),900L)
    expect_identical(nrow(etr_recurrence_network_summary_frame(network)),1L)
  }
})

test_that("frozen Python 1.2 graph topology agrees beyond former 750-node R bound",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Frozen Python 1.2 large recurrence network graph oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  n_groups<-300L
  positions<-rep(10*seq.int(0L,n_groups-1L),each=3L)+
    rep(c(0,.1,.2),n_groups)
  t<-as.numeric(seq_along(positions)-1L)
  vals<-array(positions,dim=c(1L,length(t),1L))
  x<-etr_trajectory_set(t,vals,"A","x",
    coordinate_system="arbitrary",time_unit="s")
  px<-reticulate::py_call(etpy_get_export("TrajectorySet"),
    time=reticulate::r_to_py(t),values=reticulate::r_to_py(vals),
    curve_ids=as.list("A"),dimension_names=as.list("x"),
    coordinate_system="arbitrary",time_unit="s")
  for(radius in c(.15,.25)){
    native<-etr_recurrence_network(
      etr_recurrence_matrix(x,curve="A",radius=radius))
    py_rec<-reticulate::py_call(etpy_get_export("recurrence_matrix"),
      source=px,curve="A",radius=radius,dimensions=as.list("x"))
    py<-reticulate::py_call(etpy_get_export("recurrence_network"),
      recurrence=py_rec)
    for(field in c("degree","normalized_degree","local_clustering",
      "component_labels","component_sizes","edge_count",
      "graph_density","transitivity","mean_local_clustering",
      "n_connected_components","largest_component_fraction",
      "isolated_node_fraction")){
      expected<-et_to_r(reticulate::py_get_attr(py,field))
      actual<-native[[field]]
      expect_equal(as.numeric(actual),as.numeric(expected),
        tolerance=1e-12,info=paste(field,"radius",radius))
    }
    expect_equal(unname(native$adjacency),
      unname(et_to_r(py$adjacency$toarray())),tolerance=0)
    for(framename in c("recurrence_network_node_frame",
      "recurrence_network_summary_frame")){
      nfn<-get(paste0("etr_",framename))
      own<-nfn(native)
      pyframe<-reticulate::py_call(etpy_get_export(framename),result=py)
      other<-as.data.frame(et_to_r(pyframe))
      expect_identical(names(own),names(other),info=framename)
      expect_identical(nrow(own),nrow(other),info=framename)
      for(col in names(own))
        expect_equal(as.numeric(own[[col]]),as.numeric(other[[col]]),
          tolerance=1e-12,info=paste(framename,col))
    }
  }
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
