# Frozen Python eyetrajectoriespy==1.2.0 recurrence_networks.py
# scientific source, commit c1cd95ad718327550f7e55393ff38582872f7a94.
# The native sparse Matrix output is the R scientific CSR analogue.
# Python dataclass identity is NOT represented by R's S3 list class.

.etr_net_source_fixture <- function(case="triangle",storage="sparse",
                                    null_unit=FALSE) {
  n<-7L
  m<-matrix(FALSE,n,n)
  edges<-switch(case,
    triangle=matrix(c(1,3,1,5,3,5,2,7),byrow=TRUE,ncol=2),
    independent=matrix(c(1,4,2,5,3,6),byrow=TRUE,ncol=2),
    empty=matrix(integer(0),ncol=2),
    stop("unknown fixture"))
  if(nrow(edges))for(i in seq_len(nrow(edges))){
    m[edges[i,1],edges[i,2]]<-TRUE
    m[edges[i,2],edges[i,1]]<-TRUE
  }
  if(storage=="sparse"){
    skip_if_not_installed("Matrix")
    m<-Matrix::Matrix(m,sparse=TRUE)
  }
  time<-c(0,.1,.3,.6,1,1.7,2.2)
  theiler<-1L
  eligible<-(n-theiler-1L)*(n-theiler)/2
  list(matrix=m,time_a=time,time_b=time,
    source_curve_ids="fish-1",radius=.52,target_recurrence_rate=NULL,
    achieved_recurrence_rate=nrow(edges)/eligible,
    metric="euclidean",theiler_window_samples=theiler,
    kind="auto",state_dimension=2L,
    time_unit=if(null_unit)NULL else "s",
    provenance=list(study="source-network-2026",
      recurrence_rate_denominator=
        "eligible_off_diagonal_pairs_outside_theiler_window"))
}

test_that("source topology preserves canonical fields, triangle counting and components",{
  for(storage in c("dense","sparse")){
    rec<-.etr_net_source_fixture("triangle",storage)
    x<-etr_recurrence_network(rec,python_boundary_mode=TRUE)
    expect_s3_class(x,"etr_recurrence_network")
    expect_identical(names(x),c("adjacency","degree",
      "normalized_degree","local_clustering","component_labels",
      "component_sizes","edge_count","graph_density","transitivity",
      "mean_local_clustering","n_connected_components",
      "largest_component_fraction","isolated_node_fraction",
      "source_recurrence","provenance"))
    expect_true(inherits(x$adjacency,"sparseMatrix"))
    expect_equal(as.matrix(x$adjacency),
      as.matrix(rec$matrix),tolerance=0,ignore_attr=TRUE)
    expect_identical(x$degree,c(2L,1L,2L,0L,2L,0L,1L))
    expect_equal(x$normalized_degree,x$degree/6,tolerance=0)
    expect_identical(x$component_labels,c(0L,1L,0L,2L,0L,3L,1L))
    expect_identical(x$component_sizes,c(3L,2L,1L,1L))
    expect_identical(x$edge_count,4L)
    expect_equal(x$graph_density,4/21,tolerance=0)
    expect_equal(x$local_clustering,c(1,0,1,0,1,0,0),
      tolerance=0)
    expect_equal(x$mean_local_clustering,3/7,tolerance=0)
    expect_equal(x$transitivity,1,tolerance=0)
    expect_identical(x$n_connected_components,4L)
    expect_equal(x$largest_component_fraction,3/7)
    expect_equal(x$isolated_node_fraction,2/7)
    expect_identical(x$provenance$triangle_count,1L)
    expect_false(x$provenance$dense_adjacency_materialized)
    expect_false(x$provenance$automatic_threshold_selection)
    expect_false(x$provenance$automatic_community_detection)
    expect_identical(x$source_recurrence,rec)
    nodes<-etr_recurrence_network_node_frame(x)
    summary<-etr_recurrence_network_summary_frame(x)
    expect_identical(nodes$time,rec$time_a)
    expect_identical(nodes$node_index,0:6)
    expect_equal(summary$source_achieved_recurrence_rate,
      rec$achieved_recurrence_rate,tolerance=0)
    expect_identical(summary$edge_count,4L)
  }
})

test_that("source disconnected and empty graphs retain NaN transitivity",{
  for(case in c("independent","empty")){
    source<-.etr_net_source_fixture(case)
    x<-etr_recurrence_network(source,python_boundary_mode=TRUE)
    expect_identical(length(x$degree),7L)
    expect_true(is.nan(x$transitivity))
    expect_true(all(x$local_clustering==0))
    expect_equal(x$mean_local_clustering,0,tolerance=0)
    if(case=="empty"){
      expect_identical(x$edge_count,0L)
      expect_identical(x$n_connected_components,7L)
      expect_equal(x$isolated_node_fraction,1)
      expect_equal(x$largest_component_fraction,1/7)
      expect_identical(as.integer(Matrix::nnzero(x$adjacency)),0L)
    }else {
      expect_identical(x$edge_count,3L)
      expect_equal(x$graph_density,3/21,tolerance=0)
    }
  }
})

test_that("source graph preserves only exact matched time axes with optional metadata",{
  source<-.etr_net_source_fixture("triangle",storage="sparse",
    null_unit=TRUE)
  # Python's source validator compares the axes for equality, not monotonicity.
  source$time_a[2L]<-source$time_a[1L]
  source$time_b<-source$time_a
  result<-etr_recurrence_network(source,python_boundary_mode=TRUE)
  expect_null(result$provenance$source_time_unit)
  expect_identical(result$source_recurrence$time_a,source$time_a)
  expect_identical(etr_recurrence_network_node_frame(result)$time,
    source$time_a)
  expect_error(etr_recurrence_network(source), "native sparse Matrix source")
})

test_that("invalid source network kind, geometry, Theiler, and topology fail closed",{
  source<-.etr_net_source_fixture()
  bad<-source;bad$kind<-"cross"
  expect_error(etr_recurrence_network(bad,python_boundary_mode=TRUE),
    "auto-recurrence")
  bad<-source;bad$time_b[1L]<-.2
  expect_error(etr_recurrence_network(bad,python_boundary_mode=TRUE),
    "identical time grids")
  bad<-source;bad$theiler_window_samples<--1
  expect_error(etr_recurrence_network(bad,python_boundary_mode=TRUE),
    "non-negative")
  bad<-source
  bad$matrix<-as.matrix(bad$matrix)
  bad$matrix[1L,1L]<-TRUE
  expect_error(etr_recurrence_network(bad,python_boundary_mode=TRUE),
    "main diagonal")
  bad<-source
  bad$matrix<-as.matrix(bad$matrix)
  bad$matrix[1L,2L]<-bad$matrix[2L,1L]<-TRUE
  expect_error(etr_recurrence_network(bad,python_boundary_mode=TRUE),
    "Theiler")
  bad<-source
  bad$matrix<-as.matrix(bad$matrix)
  bad$matrix[3L,1L]<-FALSE
  expect_error(etr_recurrence_network(bad,python_boundary_mode=TRUE),
    "symmetric")
  bad<-source;bad$matrix<-matrix(FALSE,1L,1L)
  bad$time_a<-bad$time_b<-0
  expect_error(etr_recurrence_network(bad,python_boundary_mode=TRUE),
    "at least two nodes")
  bad<-source;bad$provenance<-NULL
  expect_error(etr_recurrence_network(bad,python_boundary_mode=TRUE),
    "complete Python RecurrenceResult")
})

test_that("full frozen Python typed RecurrenceResult yields all source topology and provenance",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 source recurrence-network typed oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  skip_if_not_installed("Matrix")
  reticulate::py_run_string("
import numpy as np
from scipy import sparse
import eyetrajectoriespy as et
from eyetrajectoriespy.nonlinear_types import RecurrenceResult
_net_py={}
_net_times=np.array([0.,.1,.3,.6,1.,1.7,2.2])
_net_edges={'triangle':[(0,2),(0,4),(2,4),(1,6)],
            'independent':[(0,3),(1,4),(2,5)],'empty':[]}
for _case,_edges in _net_edges.items():
    _m=np.zeros((7,7),dtype=bool)
    for _i,_j in _edges:
        _m[_i,_j]=_m[_j,_i]=True
    _t=1
    _eligible=(7-_t-1)*(7-_t)//2
    _src=RecurrenceResult(matrix=sparse.csr_matrix(_m),
       time_a=_net_times,time_b=_net_times,
       source_curve_ids=('fish-1',),radius=.52,
       target_recurrence_rate=None,
       achieved_recurrence_rate=len(_edges)/_eligible,
       metric='euclidean',theiler_window_samples=_t,
       kind='auto',state_dimension=2,time_unit='s',
       provenance={'study':'source-network-2026',
          'recurrence_rate_denominator':
            'eligible_off_diagonal_pairs_outside_theiler_window'})
    _net_py[_case]=et.recurrence_network(_src)
")
  for(case in c("triangle","independent","empty")){
    source<-.etr_net_source_fixture(case)
    actual<-etr_recurrence_network(source,python_boundary_mode=TRUE)
    py<-reticulate::py_eval(paste0("_net_py['",case,"']"),
      convert=FALSE)
    pyadj<-reticulate::py_call(
      reticulate::py_get_attr(reticulate::py_get_attr(
        py,"adjacency"),"toarray"))
    expect_equal(as.matrix(actual$adjacency),et_to_r(pyadj),
      tolerance=0,ignore_attr=TRUE,info=paste("CSR adjacency",case))
    fields<-setdiff(names(actual),c("adjacency","source_recurrence",
      "provenance"))
    for(field in fields)
      expect_equal(actual[[field]],
        et_to_r(reticulate::py_get_attr(py,field)),
        tolerance=2e-12,ignore_attr=TRUE,
        info=paste("recurrence network",case,field))
    expect_equal(actual$provenance,
      et_to_r(reticulate::py_get_attr(py,"provenance")),
      tolerance=2e-12,ignore_attr=TRUE,
      info=paste("recurrence source provenance",case))
    pyref<-reticulate::py_get_attr(py,"source_recurrence")
    expect_equal(actual$source_recurrence$time_a,
      et_to_r(reticulate::py_get_attr(pyref,"time_a")),
      tolerance=0,ignore_attr=TRUE)
  }
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
