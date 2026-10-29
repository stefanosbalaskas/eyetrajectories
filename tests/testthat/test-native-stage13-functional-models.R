# Stage 13: native scientific estimator and simulation tests.
# Pinned Python numerical reference is opt-in and source-verified.

.etr13_fixture<-function(participant=FALSE){
  t<-seq(0,1,length.out=15L)
  z<-rep(seq(-1.5,1.5,length.out=8L),each=if(participant)2L else 1L)
  n<-length(z)
  a<-array(0,c(n,length(t),2L))
  for(i in seq_len(n)){
    a[i,,1L]<-2+.6*z[i]+sin(pi*t)*(.3+.2*z[i])+
      sin(3*pi*t+i/7)*.04
    a[i,,2L]<-1+.4*z[i]+cos(pi*t)*(.2-.15*z[i])+
      cos(4*pi*t+i/9)*.03
  }
  md<-if(participant)
    data.frame(participant_id=rep(sprintf("p%02d",1:8),each=2L))
    else NULL
  x<-etr_trajectory_set(t,a,sprintf("c%02d",seq_len(n)),
    c("x","y"),metadata=md,coordinate_system="normalized",time_unit="s")
  list(x=x,design=data.frame(curve_id=x$curve_ids,z=z))
}

test_that("Stage 13 pointwise function-on-scalar OLS and HC1 agree analytically",{
  f<-.etr13_fixture()
  r<-etr_fit_function_on_scalar_regression(f$x,f$design,"z")
  expect_s3_class(r,"etr_function_on_scalar")
  expect_equal(dim(r$coefficients),c(2L,15L,2L))
  expect_identical(r$coefficient_names,c("Intercept","z"))
  expect_equal(r$design_rank,2L)
  expect_equal(r$residual_degrees_of_freedom,6L)
  expect_equal(r$unit_ids,f$x$curve_ids)
  expect_equal(dim(r$fitted_functions),dim(f$x$values))
  expect_equal(dim(r$standard_errors),dim(r$coefficients))
  expect_true(all(r$standard_errors>=0))
  for(i in 1:15)for(j in 1:2){
    lmfit<-stats::lm.fit(cbind(1,f$design$z),f$x$values[,i,j])
    expect_equal(as.numeric(r$coefficients[,i,j]),
      as.numeric(lmfit$coefficients),tolerance=1e-11)
    expect_equal(as.numeric(r$residual_functions[,i,j]),
      as.numeric(lmfit$residuals),tolerance=1e-10)
  }
  tab<-etr_function_on_scalar_coefficient_frame(r)
  expect_identical(names(tab),c("coefficient","time",
    "dimension","estimate","standard_error"))
  expect_equal(nrow(tab),2L*15L*2L)
  expect_identical(tab$coefficient[1L],"Intercept")
  expect_identical(tab$coefficient[31L],"z")
  bad<-f$design;bad$curve_id<-rev(bad$curve_id)
  expect_error(etr_fit_function_on_scalar_regression(f$x,bad,"z"),
    "curve_id")
  expect_error(etr_fit_function_on_scalar_regression(f$x,f$design,
    predictors="missing"),"predictors")
  bad<-f$x;bad$coordinate_system<-"probability_simplex"
  expect_error(etr_fit_function_on_scalar_regression(bad,f$design,"z"),
    "probability_simplex")
})

test_that("Stage 13 participant units aggregate trials without pseudoreplication",{
  f<-.etr13_fixture(participant=TRUE)
  r<-etr_fit_function_on_scalar_regression(f$x,f$design,"z",
    unit="participant",participant_column="participant_id")
  expect_identical(r$unit,"participant")
  expect_equal(length(r$unit_ids),8L)
  expect_true(all(r$curves_per_unit==2L))
  expect_equal(dim(r$observed_functions),c(8L,15L,2L))
  expect_equal(r$residual_degrees_of_freedom,6L)
  r2<-etr_fit_function_on_scalar_regression(f$x,f$design,"z",
    dimensions="y",unit="participant",participant_column="participant_id")
  expect_equal(dim(r2$coefficients),c(2L,15L,1L))
  bad<-f$design;bad$z[2L]<-999
  expect_error(etr_fit_function_on_scalar_regression(f$x,bad,"z",
    unit="participant",participant_column="participant_id"),
    "vary within participant")
  expect_error(etr_fit_function_on_scalar_regression(f$x,f$design,"z",
    unit="participant"),"participant_column")
  expect_error(etr_fit_function_on_scalar_regression(f$x,f$design,"z",
    participant_column="participant_id"),"unit='curve'")
})

test_that("Stage 13 wild bootstrap is fixed-design, entire-function and reproducible",{
  f<-.etr13_fixture()
  r<-etr_fit_function_on_scalar_regression(f$x,f$design,"z")
  set.seed(125)
  before<-.Random.seed
  b<-etr_bootstrap_function_on_scalar_coefficients(r,n_bootstrap=100L,
    multiplier="rademacher",random_state=8L)
  expect_identical(before,.Random.seed)
  expect_s3_class(b,"etr_function_on_scalar_bootstrap")
  expect_equal(dim(b$bootstrap_coefficients),c(100L,2L,15L,2L))
  expect_equal(dim(b$multipliers),c(100L,8L))
  expect_true(all(b$multipliers%in%c(-1,1)))
  expect_equal(b$reference$design_matrix,r$design_matrix)
  b2<-etr_bootstrap_function_on_scalar_coefficients(r,n_bootstrap=100L,
    multiplier="rademacher",random_state=8L)
  expect_identical(b$bootstrap_coefficients,b2$bootstrap_coefficients)
  expect_error(etr_bootstrap_function_on_scalar_coefficients(r,
    n_bootstrap=50L),"n_bootstrap")
  bands<-etr_function_on_scalar_simultaneous_bands(b,
    confidence_level=.9)
  expect_s3_class(bands,"etr_function_on_scalar_band")
  expect_equal(dim(bands$lower),dim(r$coefficients))
  expect_true(all(bands$lower<=r$coefficients+1e-10))
  expect_true(all(bands$upper>=r$coefficients-1e-10))
  expect_equal(dim(bands$max_statistics),c(100L,2L))
  family<-etr_function_on_scalar_simultaneous_bands(b,
    confidence_level=.9,simultaneous_scope="family")
  expect_equal(dim(family$max_statistics),c(100L,1L))
  expect_true(all(family$critical_values>=bands$critical_values-1e-12))
  tab<-etr_function_on_scalar_coefficient_frame(r,band=bands)
  expect_true(all(c("lower","upper","critical_value")%in%names(tab)))
  expect_error(etr_function_on_scalar_simultaneous_bands(b,
    confidence_level=1),"confidence_level")
})

test_that("Stage 13 delay AMI and FNN give deterministic, declared diagnostics",{
  t<-seq(0,5,length.out=101L)
  v<-array(0,c(1L,length(t),1L))
  v[1L,,1L]<-sin(2*pi*t)+.2*cos(6*pi*t)+.03*t
  x<-etr_trajectory_set(t,v,"wave","signal",time_unit="s")
  delay<-etr_embedding_delay_diagnostics(x,"wave","signal",
    max_lag=10L,bins=8L)
  expect_s3_class(delay,"etr_embedding_delay_diagnostics")
  expect_equal(nrow(delay$table),10L)
  expect_identical(names(delay$table),c("lag_samples","lag_time",
    "autocorrelation","average_mutual_information",
    "first_ami_local_minimum"))
  expect_equal(delay$table$lag_samples,1:10)
  expect_true(all(is.finite(delay$table$average_mutual_information)))
  expect_true(all(delay$table$average_mutual_information>=-1e-10))
  expect_true(sum(delay$table$first_ami_local_minimum)<=1L)
  fnn<-etr_embedding_dimension_diagnostics(x,1L,"signal",
    delay=2L,max_dimension=4L,theiler_window=2L)
  expect_s3_class(fnn,"etr_embedding_dimension_diagnostics")
  expect_equal(nrow(fnn$table),4L)
  expect_true(all(fnn$table$false_neighbor_fraction>=0 &
                  fnn$table$false_neighbor_fraction<=1))
  expect_true(all(diff(fnn$table$n_reference_states)==-2L))
  expect_false(isTRUE(fnn$provenance$automatic_dimension_selection))
  odd<-x;odd$time[2L]<-.06
  expect_error(etr_embedding_delay_diagnostics(odd,1L,"signal",5L),
    "regular")
  expect_error(etr_embedding_dimension_diagnostics(x,1L,"signal",
    delay=0L),"delay")
})

test_that("Stage 13 return-map stability classifies empirical Jacobian eigenvalues",{
  a<-etr_return_map_stability(list(jacobian=diag(c(.8,.7))),
    tolerance=.01)
  expect_identical(a$classification,"contracting")
  expect_equal(a$spectral_radius,.8)
  b<-etr_return_map_stability(list(jacobian=diag(c(1.2,.7))))
  expect_identical(b$classification,"expanding")
  c<-etr_return_map_stability(list(jacobian=diag(c(1,.8))))
  expect_identical(c$classification,"near-neutral")
  rot<-etr_return_map_stability(list(jacobian=matrix(c(0,1,-1,0),2,2)))
  expect_equal(rot$spectral_radius,1,tolerance=1e-10)
  expect_error(etr_return_map_stability(list(jacobian=matrix(1:6,2,3))),
    "square")
  expect_error(etr_return_map_stability(list(jacobian=diag(2)),-1),
    "tolerance")
})

test_that("Stage 13 two generators return reproducible true trajectory containers",{
  set.seed(400)
  rng<-.Random.seed
  x<-etr_simulate_planar_trajectories(3L,2L,11L,1,7L)
  expect_identical(rng,.Random.seed)
  y<-etr_simulate_planar_trajectories(3L,2L,11L,1,7L)
  expect_identical(x$values,y$values)
  expect_equal(dim(x$values),c(6L,11L,2L))
  expect_true(all(x$values>=0 & x$values<=1))
  expect_identical(x$dimension_names,c("x","y"))
  expect_identical(x$curve_ids[1L],"P001|T01")
  expect_identical(as.integer(table(x$metadata$condition)),c(3L,3L))
  a<-etr_simulate_aoi_probability_trajectories(6L,11L,3L,1,8L)
  expect_identical(rng,.Random.seed)
  expect_equal(dim(a$values),c(6L,11L,3L))
  expect_true(all(a$values>0))
  expect_equal(apply(a$values,c(1L,2L),sum),
    matrix(1,nrow=6L,ncol=11L),tolerance=1e-12)
  expect_true(isTRUE(a$provenance$synthetic))
  expect_equal(a$values,
    etr_simulate_aoi_probability_trajectories(6L,11L,3L,1,8L)$values)
  expect_error(etr_simulate_planar_trajectories(n_participants=1L),
    "participants")
  expect_error(etr_simulate_aoi_probability_trajectories(n_aoi=1L),"AOIs")
})

test_that("Stage 13 explicit irregular source long-grid conversion has no extrapolation",{
  raw<-data.frame(participant=c("a","a","a","b","b","b"),
    time=c(0,1,3,1,2,3),x=c(1,2,4,4,3,2),
    y=c(3,4,5,4,3,2))
  x<-etr_from_irregular_long_dataframe(raw,
    curve_columns="participant",time_column="time",
    value_columns=c("x","y"),grid=c(0,1,2,3),method="linear")
  expect_s3_class(x,"etr_trajectory_set")
  expect_equal(dim(x$values),c(2L,4L,2L))
  expect_equal(as.numeric(x$values[1L,,1L]),c(1,2,3,4))
  expect_true(is.na(x$values[2L,1L,1L]))
  expect_equal(as.numeric(x$values[2L,2:4,1L]),c(4,3,2))
  bad<-raw;bad$time[2L]<-0
  expect_error(etr_from_irregular_long_dataframe(bad,
    "participant","time",c("x","y"),grid=0:3),"Duplicate|increasing")
})

test_that("Stage 13 508-source inventory remains fail-closed",{
  was<-reticulate::py_available(initialize=FALSE)
  z<-etr_native_parity_catalog()
  expect_equal(nrow(z),508L)
  expect_equal(sum(z$is_python_function),380L)
  expect_equal(sum(z$named_native_candidate),236L)
  expect_equal(sum(z$is_python_function & !z$named_native_candidate),144L)
  expect_equal(sum(z$native_implementation_started),211L)
  expect_equal(sum(z$native_implementation_stage==13L,na.rm=TRUE),12L)
  expect_equal(sum(!is.na(z$native_representation_stage)),7L)
  expect_true(all(!z$one_to_one_native_contract_complete))
  expect_error(etr_native_parity_catalog(require_complete=TRUE),"NOT complete")
  expect_identical(was,reticulate::py_available(initialize=FALSE))
})

test_that("Stage 13 pinned Python 1.2 fixed-design FOS OLS reference is opt-in",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Stage 13 Python 1.2 numerical FOS oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  f<-.etr13_fixture()
  pyx<-reticulate::py_call(etpy_get_export("TrajectorySet"),
    time=reticulate::r_to_py(f$x$time),
    values=reticulate::r_to_py(f$x$values),
    curve_ids=as.list(f$x$curve_ids),
    dimension_names=as.list(f$x$dimension_names),
    coordinate_system="normalized",time_unit="s")
  pd<-reticulate::import("pandas",convert=FALSE)
  design<-pd$DataFrame(reticulate::r_to_py(f$design))
  py<-reticulate::py_call(etpy_get_export("fit_function_on_scalar_regression"),
    trajectories=pyx,design=design,predictors=as.list("z"))
  r<-etr_fit_function_on_scalar_regression(f$x,f$design,"z")
  expect_equal(unname(r$coefficients),
    unname(et_to_r(py$coefficients)),tolerance=1e-8)
  expect_equal(unname(r$standard_errors),
    unname(et_to_r(py$standard_errors)),tolerance=1e-8)
  expect_equal(unname(r$residual_functions),
    unname(et_to_r(py$residual_functions)),tolerance=1e-8)
  expect_equal(unname(r$design_matrix),
    unname(et_to_r(py$design_matrix)),tolerance=1e-9)
  pframe<-et_to_r(reticulate::py_call(
    etpy_get_export("function_on_scalar_coefficient_frame"),
    result=py))
  rframe<-etr_function_on_scalar_coefficient_frame(r)
  expect_identical(names(rframe),names(pframe))
  expect_equal(rframe$estimate,as.numeric(pframe$estimate),tolerance=1e-8)
  expect_equal(rframe$standard_error,as.numeric(pframe$standard_error),
    tolerance=1e-8)
  # Separately evaluate participant-level samples to guard against
  # treating repeated trials as independent units.
  f<-.etr13_fixture(participant=TRUE)
  pyx<-reticulate::py_call(etpy_get_export("TrajectorySet"),
    time=reticulate::r_to_py(f$x$time),
    values=reticulate::r_to_py(f$x$values),
    curve_ids=as.list(f$x$curve_ids),
    dimension_names=as.list(f$x$dimension_names),
    metadata=pd$DataFrame(reticulate::r_to_py(f$x$metadata)),
    coordinate_system="normalized",time_unit="s")
  py<-reticulate::py_call(etpy_get_export("fit_function_on_scalar_regression"),
    trajectories=pyx,design=pd$DataFrame(reticulate::r_to_py(f$design)),
    predictors=as.list("z"),unit="participant",
    participant_column="participant_id")
  r<-etr_fit_function_on_scalar_regression(f$x,f$design,"z",
    unit="participant",participant_column="participant_id")
  expect_equal(unname(r$coefficients),
    unname(et_to_r(py$coefficients)),tolerance=1e-8)
  expect_equal(unname(r$standard_errors),
    unname(et_to_r(py$standard_errors)),tolerance=1e-8)
})


test_that("Stage 13 explicit Poincare-to-return-map pipeline is numerical and auditable",{
  t<-seq(0,13,by=1)
  vals<-array(0,c(1L,length(t),2L))
  vals[1L,,1L]<-rep(c(-1,1),length.out=length(t))
  vals[1L,,2L]<-sin(t*.41)+.09*t+.1*cos(t*.7)
  x<-etr_trajectory_set(t,vals,"periodic",c("section","state"),
    coordinate_system="normalized",time_unit="s")
  c<-etr_poincare_crossings(x,1L,"section",0,"positive",
    state_dimensions="state")
  expect_s3_class(c,"etr_poincare_crossings")
  expect_true(length(c$times)>=5L)
  expect_equal(c$times,seq(.5,12.5,by=2))
  expect_equal(c$left_indices,seq(0L,12L,by=2L))
  expect_equal(c$fractions,rep(.5,7L))
  expect_identical(dim(c$states),c(7L,1L))
  expect_equal(c$states[,1L],
    rowMeans(cbind(vals[1L,seq(1L,13L,by=2L),2L],
      vals[1L,seq(2L,14L,by=2L),2L])))
  fit<-etr_fit_local_return_map(c,reference="mean",n_neighbors=5L)
  expect_s3_class(fit,"etr_local_return_map")
  expect_identical(dim(fit$jacobian),c(1L,1L))
  expect_equal(fit$n_transitions,5L)
  expect_equal(fit$neighborhood_policy,"n_neighbors")
  expect_true(is.finite(fit$design_condition_number))
  result<-etr_return_map_stability(fit)
  expect_s3_class(result,"etr_return_map_stability")
  expect_equal(result$spectral_radius,abs(fit$jacobian[1L,1L]),
    tolerance=1e-10)
  expect_true(result$classification%in%
    c("contracting","expanding","near-neutral"))
  expect_error(etr_poincare_crossings(x,1L,"section",0,"positive",
    state_dimensions="section"),"state_dimensions")
  expect_error(etr_fit_local_return_map(c,reference="mean",
    n_neighbors=5L,neighborhood_radius=1),"exactly one")
})

test_that("Stage 13 Python 1.2 Poincare crossing interpolation oracle is opt-in",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Stage 13 Python 1.2 Poincare crossing oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  t<-seq(0,13,by=1)
  vals<-array(0,c(1L,length(t),2L))
  vals[1L,,1L]<-rep(c(-1,1),length.out=length(t))
  vals[1L,,2L]<-sin(t*.41)+.09*t+.1*cos(t*.7)
  x<-etr_trajectory_set(t,vals,"periodic",c("section","state"),
    time_unit="s")
  native<-etr_poincare_crossings(x,"periodic","section",0,"positive",
    state_dimensions="state")
  pyx<-reticulate::py_call(etpy_get_export("TrajectorySet"),
    time=reticulate::r_to_py(x$time),
    values=reticulate::r_to_py(x$values),
    curve_ids=as.list(x$curve_ids),
    dimension_names=as.list(x$dimension_names),time_unit="s")
  py<-reticulate::py_call(etpy_get_export("poincare_crossings"),
    trajectories=pyx,curve="periodic",section_dimension="section",
    section_value=0,direction="positive",state_dimensions=as.list("state"))
  expect_equal(unname(native$states),unname(et_to_r(py$states)),
    tolerance=1e-12)
  expect_equal(native$times,as.numeric(et_to_r(py$times)),tolerance=1e-12)
  expect_equal(native$fractions,as.numeric(et_to_r(py$fractions)),
    tolerance=1e-12)
  expect_equal(native$left_indices,as.integer(et_to_r(py$left_indices)))
})
