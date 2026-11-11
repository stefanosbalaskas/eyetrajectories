# Frozen source eyetrajectoriespy 1.2.0 stability.py
# bootstrap_fpca_component_envelopes at
# c1cd95ad718327550f7e55393ff38582872f7a94.
# Source result is an R scientific FPCA list rather than Python dataclass.

.etr_source_envelope_fixture<-function(two_channels=TRUE){
  n<-12L; nt<-19L;t<-seq(0,1,length.out=nt)
  d<-if(two_channels)2L else 1L
  values<-array(0,c(n,nt,d))
  for(i in seq_len(n)){
    values[i,,1L]<-sin(2*pi*t)*(1+i/23)+
      .3*cos(4*pi*t+i/7)+t*i/13
    if(two_channels)
      values[i,,2L]<-cos(2*pi*t+i/9)+
        (i/17)*sin(pi*t)+.1*t^2
  }
  etr_trajectory_set(t,values,sprintf("c%02d",seq_len(n)),
    if(two_channels)c("x","y") else "x",
    metadata=data.frame(subject=rep(sprintf("p%02d",1:6),each=2)),
    coordinate_system="normalized",time_unit="s")
}

test_that("source mode emits exactly the nine Python envelope fields",{
  x<-.etr_source_envelope_fixture()
  for(unit in c("curve","participant")){
    label<-if(unit=="participant")"subject" else NULL
    for(k in c(1L,2L)){
      z<-etr_bootstrap_fpca_component_envelopes(
        x,n_bootstrap=5L,n_components=k,level=.8,
        resample_unit=unit,participant_column=label,
        random_state=41L,python_boundary_mode=TRUE)
      expect_identical(names(z),c("reference","lower","median",
        "upper","similarities","level","resampling_unit",
        "random_state","provenance"))
      expect_s3_class(z,"etr_fpca_component_envelope")
      expect_identical(dim(z$lower),c(k,19L,2L))
      expect_identical(dim(z$median),c(k,19L,2L))
      expect_identical(dim(z$upper),c(k,19L,2L))
      expect_identical(dim(z$similarities),c(5L,k))
      expect_true(all(z$lower<=z$median & z$median<=z$upper))
      expect_true(all(is.finite(z$similarities)))
      expect_identical(names(z$provenance),
        c("method","n_bootstrap","n_components","scaling",
          "participant_column","coverage_claim"))
      expect_identical(z$provenance$coverage_claim,
        "descriptive_pointwise_only")
      expect_identical(z$provenance$n_bootstrap,5L)
      expect_identical(z$provenance$n_components,k)
      expect_identical(z$provenance$participant_column,label)
      again<-etr_bootstrap_fpca_component_envelopes(
        x,n_bootstrap=5L,n_components=k,level=.8,
        resample_unit=unit,participant_column=label,
        random_state=41L,python_boundary_mode=TRUE)
      expect_identical(z$lower,again$lower)
      expect_identical(z$median,again$median)
      expect_identical(z$upper,again$upper)
      expect_identical(z$similarities,again$similarities)
    }
  }
})

test_that("source fixed-bootstrap interface stays separate from R extensions",{
  x<-.etr_source_envelope_fixture(FALSE)
  native<-etr_bootstrap_fpca_component_envelopes(
    x,n_bootstrap=3L,n_components=1L,random_state=22L)
  expect_false(native$provenance$source_python_equivalent_stochastic_draws)
  expect_identical(native$provenance$random_engine,"numpy_pcg64")
  expect_error(etr_bootstrap_fpca_component_envelopes(x,
    n_bootstrap=3L,n_components=1L,python_boundary_mode=TRUE,
    bootstrap_unit_indices=rep(list(rep(0L,12L)),3L)),
    "caller-supplied bootstrap indices")
  expect_error(etr_bootstrap_fpca_component_envelopes(x,
    n_bootstrap=3L,n_components=1L,
    python_boundary_mode=1),"python_boundary_mode")
  with_null<-etr_bootstrap_fpca_component_envelopes(x,
    n_bootstrap=2L,n_components=1L,random_state=NULL,
    python_boundary_mode=TRUE)
  expect_null(with_null$random_state)
  expect_identical(dim(with_null$lower),c(1L,19L,1L))
  expect_true(all(is.finite(with_null$lower)))
})

test_that("pinned Python 1.2 dense curve and grouped FPCA envelopes match all values",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("requires frozen Python 1.2 source runtime")
  expect_identical(et_python_version(),"1.2.0")
  for(two_channels in c(FALSE,TRUE)){
    x<-.etr_source_envelope_fixture(two_channels)
    py_x<-reticulate::py_call(etpy_get_export("TrajectorySet"),
      time=x$time,values=x$values,
      curve_ids=do.call(reticulate::tuple,as.list(x$curve_ids)),
      dimension_names=do.call(reticulate::tuple,as.list(x$dimension_names)),
      metadata=x$metadata,coordinate_system=x$coordinate_system,
      time_unit=x$time_unit)
    for(unit in c("curve","participant")){
      label<-if(unit=="participant")"subject"else NULL
      for(seed in c(0L,7L,41L)){
        args<-list(n_bootstrap=5L,n_components=2L,
          scaling="none",resample_unit=unit,
          participant_column=label,level=.8,
          random_state=seed)
        r<-do.call(etr_bootstrap_fpca_component_envelopes,
          c(list(trajectories=x),args,list(python_boundary_mode=TRUE)))
        py<-do.call(reticulate::py_call,
          c(list(etpy_get_export("bootstrap_fpca_component_envelopes"),
                 py_x),args))
        for(field in c("lower","median","upper","similarities"))
          expect_equal(r[[field]],
            et_to_r(reticulate::py_get_attr(py,field)),
            tolerance=1e-7,ignore_attr=TRUE,
            info=paste("envelopes",two_channels,unit,seed,field))
        for(field in c("level","resampling_unit","random_state"))
          expect_equal(r[[field]],
            et_to_r(reticulate::py_get_attr(py,field)),
            tolerance=0,ignore_attr=TRUE,
            info=paste("source output metadata",field))
        pyprovenance<-et_to_r(reticulate::py_get_attr(py,"provenance"))
        expect_identical(names(r$provenance),names(pyprovenance))
        for(field in names(r$provenance))
          expect_equal(r$provenance[[field]],pyprovenance[[field]],
            ignore_attr=TRUE,
            info=paste("source scientific provenance",field))
        # Source reference fit is an estimand, not an R-executed
        # sklearn or Python object. Its numerical spectrum must match.
        pyreference<-reticulate::py_get_attr(py,"reference")
        expect_equal(r$reference$explained_variance,
          et_to_r(reticulate::py_get_attr(pyreference,"explained_variance")),
          tolerance=1e-7,ignore_attr=TRUE)
      }
    }
  }
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
