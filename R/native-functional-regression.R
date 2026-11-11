# Stage 13 — numerical function-on-scalar regression, fixed-design wild
# bootstrap and observed-grid simultaneous bands. No Python bridge.
# Source: eyetrajectoriespy==1.2.0 function_on_scalar.py.

.etr_function_scalar_result_check <- function(x) {
  .etr_assert(inherits(x,"etr_function_on_scalar") &&
    is.matrix(x$design_matrix) &&
    is.array(x$coefficients) && length(dim(x$coefficients))==3L &&
    is.array(x$standard_errors) &&
    identical(dim(x$coefficients),dim(x$standard_errors)) &&
    is.array(x$residual_functions) &&
    is.array(x$fitted_functions) &&
    identical(dim(x$residual_functions),dim(x$fitted_functions)) &&
    nrow(x$design_matrix)==dim(x$fitted_functions)[1L] &&
    ncol(x$design_matrix)==dim(x$coefficients)[1L],
    "result must be a native function-on-scalar regression")
  invisible(x)
}

#' Fit observed-grid function-on-scalar OLS and HC1 sandwich pointwise SE
#' @param trajectories Complete native functional response trajectories.
#' @param design Curve-aligned numeric scalar design, one row per source curve.
#' @param predictors Nonempty distinct predictor column names (excluding Intercept).
#' @param dimensions Optional selected response dimensions in requested order.
#' @param participant_column Metadata field for equal-weight participant units.
#' @param unit Curve-level or participant-level independent inference units.
#' @export
etr_fit_function_on_scalar_regression <- function(trajectories,design,
    predictors,dimensions=NULL,participant_column=NULL,unit="curve"){
  etr_validate(trajectories,require_complete=TRUE)
  .etr_assert(!identical(trajectories$coordinate_system,"probability_simplex"),
    "probability_simplex requires an explicit log-ratio transformation")
  .etr_assert(is.data.frame(design) &&
    nrow(design)==length(trajectories$curve_ids),
    "design must contain exactly one row per source trajectory")
  .etr_assert(is.character(predictors)&&length(predictors)>0L &&
    !anyNA(predictors)&&all(nzchar(predictors))&&!anyDuplicated(predictors) &&
    !("Intercept"%in%predictors) && all(predictors%in%names(design)),
    "predictors must be distinct declared numeric columns (Intercept reserved)")
  if("curve_id"%in%names(design))
    .etr_assert(identical(as.character(design$curve_id),
      trajectories$curve_ids),"design curve_id order must match trajectories")
  else .etr_assert(identical(rownames(design),as.character(seq_len(nrow(design)))),
    "design without curve_id must have default row order")
  for(col in predictors).etr_assert(is.numeric(design[[col]]) &&
    all(is.finite(design[[col]])),
    paste("predictor",col,"must be finite numeric; categorical variables require explicit encoding"))
  if(is.null(dimensions))dimensions<-trajectories$dimension_names
  .etr_assert(is.character(dimensions)&&length(dimensions)>0L &&
    !anyNA(dimensions)&&!anyDuplicated(dimensions) &&
    all(dimensions%in%trajectories$dimension_names),
    "dimensions must be distinct existing functional channels")
  .etr_assert(is.character(unit)&&length(unit)==1L&&unit%in%c("curve","participant"),
    "unit must be 'curve' or 'participant'")
  idx<-match(dimensions,trajectories$dimension_names)
  n<-length(trajectories$curve_ids);nt<-length(trajectories$time);nd<-length(idx)
  y<-array(trajectories$values[,,idx,drop=FALSE],c(n,nt,nd))
  pred<-as.matrix(design[,predictors,drop=FALSE])
  .etr_assert(all(is.finite(y)),
    "function-on-scalar regression requires complete finite values")
  if(unit=="curve"){
    .etr_assert(is.null(participant_column),
      "participant_column must be NULL when unit='curve'")
    uids<-trajectories$curve_ids;counts<-rep(1L,n)
    unit_y<-y;unit_x<-pred
    policy<-"source curves are asserted to be independent inference units"
  }else{
    .etr_assert(is.character(participant_column)&&
      length(participant_column)==1L &&
      participant_column%in%names(trajectories$metadata),
      "participant_column is required in trajectory metadata")
    groups<-trajectories$metadata[[participant_column]]
    .etr_assert(!anyNA(groups),"participant_column contains missing values")
    groups<-as.character(groups);uids<-unique(groups)
    .etr_assert(length(uids)>=2L,"At least two unique participants required")
    counts<-vapply(uids,function(g)sum(groups==g),integer(1L))
    unit_y<-array(0,c(length(uids),nt,nd))
    unit_x<-matrix(0,length(uids),length(predictors))
    for(i in seq_along(uids)){
      ids<-which(groups==uids[i])
      selected<-pred[ids,,drop=FALSE]
      .etr_assert(all(sweep(selected,2L,selected[1L,],"-")==0),
        paste("predictors vary within participant",uids[i],
              "; trial-varying predictors need a mixed-effects model"))
      unit_x[i,]<-selected[1L,]
      for(t in seq_len(nt))for(d in seq_len(nd))
        unit_y[i,t,d]<-mean(y[ids,t,d])
    }
    policy<-"participants are independent equal-weight inference units"
  }
  n_units<-length(uids)
  x<-cbind(Intercept=rep(1,n_units),unit_x)
  colnames(x)<-c("Intercept",predictors)
  rank<-qr(x)$rank;np<-ncol(x);df<-n_units-rank
  .etr_assert(rank==np,
    "design matrix is rank deficient; remove redundant predictors")
  .etr_assert(df>0,
    "function-on-scalar regression requires positive residual degrees of freedom")
  inv<-solve(crossprod(x))
  projection<-inv%*%t(x)
  coef<-array(0,c(np,nt,nd))
  fitted<-array(0,c(n_units,nt,nd))
  resid<-array(0,c(n_units,nt,nd))
  se<-array(0,c(np,nt,nd))
  influence<-x%*%inv
  for(t in seq_len(nt))for(d in seq_len(nd)){
    beta<-as.vector(projection%*%unit_y[,t,d])
    yhat<-as.vector(x%*%beta)
    err<-unit_y[,t,d]-yhat
    coef[,t,d]<-beta;fitted[,t,d]<-yhat;resid[,t,d]<-err
    for(k in seq_len(np))
      se[k,t,d]<-sqrt((n_units/df)*sum((influence[,k]*err)^2))
  }
  provenance<-trajectories$provenance
  provenance$function_on_scalar_regression<-list(
    method="observed_grid_ordinary_least_squares",
    pointwise_standard_errors="HC1_sandwich",
    predictors=as.list(predictors),dimensions=as.list(dimensions),
    unit=unit,participant_column=participant_column,
    design_rank=rank,residual_degrees_of_freedom=df,
    smoothing=FALSE,basis_expansion=FALSE,
    automatic_model_selection=FALSE,
    simultaneous_inference=FALSE,
    participant_predictor_policy=policy)
  structure(list(coefficients=coef,standard_errors=se,
    fitted_functions=fitted,residual_functions=resid,
    observed_functions=unit_y,design_matrix=x,
    coefficient_names=c("Intercept",predictors),
    predictor_names=predictors,design_rank=rank,
    residual_degrees_of_freedom=df,unit=unit,unit_ids=uids,
    curves_per_unit=as.integer(counts),
    participant_column=if(unit=="participant")participant_column else NULL,
    time=trajectories$time,dimension_names=dimensions,
    coordinate_system=trajectories$coordinate_system,
    time_unit=trajectories$time_unit,
    source_curve_ids=trajectories$curve_ids,
    provenance=provenance),class="etr_function_on_scalar")
}

#' Fixed-design wild bootstrap of entire functional residual curves
#' @param result Native FOS regression.
#' @param n_bootstrap Number of replicates (>=100).
#' @param multiplier Rademacher +/-1 or Gaussian weights.
#' @param random_state Nonnegative integer seed below 2^53, or NULL to use
#'   the current R RNG stream.
#' @param random_engine Use `"numpy"` for source-seeded draws or `"base_R"`
#'   to replay previous native seeded weights.
#' @export
etr_bootstrap_function_on_scalar_coefficients <- function(result,
    n_bootstrap=1000L,multiplier="rademacher",random_state=0L,
    random_engine="numpy"){
  .etr_function_scalar_result_check(result)
  .etr_assert(is.numeric(n_bootstrap)&&length(n_bootstrap)==1L&&
    is.finite(n_bootstrap)&&n_bootstrap==as.integer(n_bootstrap)&&
    n_bootstrap>=100L,
    "n_bootstrap must be an integer >= 100")
  .etr_assert(identical(multiplier,"rademacher")||
    identical(multiplier,"normal"),
    "multiplier must be 'rademacher' or 'normal'")
  random_engine<-match.arg(random_engine,c("numpy","base_R"))
  rng<-NULL
  engine<-"base_R_unseeded"
  if(!is.null(random_state)){
    if(random_engine=="numpy"){
      rng<-.etr_numpy_pcg64(random_state)
      engine<-"numpy_pcg64"
    }else{
      restore<-.etr_simulation_rng(random_state)
      on.exit(restore(),add=TRUE)
      engine<-"base_R_not_NumPy"
    }
    if(random_state<=.Machine$integer.max)random_state<-as.integer(random_state)
  }
  draw<-if(multiplier=="rademacher"){
    if(is.null(rng))function(n)sample(c(-1,1),n,replace=TRUE)
      else function(n)2*rng$integers(n,2L)-1
  }else if(is.null(rng))stats::rnorm else rng$normal
  x<-result$design_matrix;n<-nrow(x)
  projection<-solve(crossprod(x))%*%t(x)
  sh<-dim(result$coefficients)
  b<-as.integer(n_bootstrap)
  coefs<-array(0,c(b,sh))
  weights<-matrix(0,b,n)
  for(i in seq_len(b)){
    w<-draw(n)
    weights[i,]<-w
    for(t in seq_len(sh[2L]))for(d in seq_len(sh[3L]))
      coefs[i,,t,d]<-as.vector(projection%*%(
        result$fitted_functions[,t,d]+w*result$residual_functions[,t,d]))
  }
  provenance<-result$provenance
  provenance$function_on_scalar_bootstrap<-list(
    method="fixed_design_wild_bootstrap",n_bootstrap=b,
    multiplier=multiplier,random_state=random_state,
    unit=result$unit,n_units=n,design_resampled=FALSE,
    residual_functions_multiplied_as_whole_functions=TRUE,
    simultaneous_band_calibration=FALSE,
    random_engine=engine)
  structure(list(reference=result,bootstrap_coefficients=coefs,
    multipliers=weights,multiplier=multiplier,
    random_state=random_state,provenance=provenance),
    class="etr_function_on_scalar_bootstrap")
}

#' Observed-grid maximum-studentized FOS simultaneous coefficient bands
#' @param bootstrap Native FOS wild-bootstrap results.
#' @param confidence_level Confidence fraction strictly between 0 and 1.
#' @param simultaneous_scope Coefficient-specific or whole family.
#' @export
etr_function_on_scalar_simultaneous_bands <- function(bootstrap,
    confidence_level=.95,simultaneous_scope="coefficient"){
  .etr_assert(inherits(bootstrap,"etr_function_on_scalar_bootstrap"),
    "bootstrap must be native function-on-scalar bootstrap")
  ref<-bootstrap$reference;.etr_function_scalar_result_check(ref)
  .etr_assert(is.numeric(confidence_level)&&length(confidence_level)==1L&&
    is.finite(confidence_level)&&confidence_level>0&&confidence_level<1,
    "confidence_level must lie in (0,1)")
  .etr_assert(simultaneous_scope%in%c("coefficient","family"),
    "simultaneous_scope must be 'coefficient' or 'family'")
  a<-bootstrap$bootstrap_coefficients
  sh<-dim(ref$coefficients);b<-dim(a)[1L]
  .etr_assert(is.array(a)&&length(dim(a))==4L&&
    identical(dim(a)[-1L],sh)&&all(is.finite(a)),
    "bootstrap coefficients must align to fitted functional grid")
  absstat<-matrix(0,b,sh[1L])
  pos<-ref$standard_errors>.Machine$double.eps
  for(i in seq_len(b))for(k in seq_len(sh[1L])){
    err<-abs(a[i,k,,]-ref$coefficients[k,,])
    sd<-ref$standard_errors[k,,]
    absstat[i,k]<-max(ifelse(sd>.Machine$double.eps,err/pmax(sd,.Machine$double.eps),0))
  }
  quantile_higher<-function(v)sort(v)[max(1L,as.integer(ceiling(confidence_level*length(v))))]
  if(simultaneous_scope=="coefficient"){
    critical<-apply(absstat,2L,quantile_higher)
    maxstat<-absstat
  }else{
    family<-apply(absstat,1L,max)
    critical<-rep(quantile_higher(family),sh[1L])
    maxstat<-matrix(family,ncol=1L)
  }
  lower<-upper<-array(0,sh)
  for(k in seq_len(sh[1L])){
    lower[k,,]<-ref$coefficients[k,,]-critical[k]*ref$standard_errors[k,,]
    upper[k,,]<-ref$coefficients[k,,]+critical[k]*ref$standard_errors[k,,]
  }
  provenance<-bootstrap$provenance
  provenance$function_on_scalar_simultaneous_bands<-list(
    method="wild_bootstrap_reference_studentized_maximum",
    simultaneous_scope=simultaneous_scope,
    confidence_level=confidence_level,
    continuous_between_grid_points=FALSE,
    zero_standard_error_cells=sum(!pos),
    zero_standard_error_cells_receive_zero_width=TRUE)
  structure(list(reference=ref,lower=lower,upper=upper,
    critical_values=as.numeric(critical),max_statistics=maxstat,
    confidence_level=confidence_level,simultaneous_scope=simultaneous_scope,
    bootstrap=bootstrap,provenance=provenance),
    class="etr_function_on_scalar_band")
}

#' Tidy coefficient curves and optional simultaneous uncertainty bounds
#' @param result Native FOS regression.
#' @param band Optional native band from matching exact result reference.
#' @export
etr_function_on_scalar_coefficient_frame <- function(result,band=NULL){
  .etr_function_scalar_result_check(result)
  if(!is.null(band))
    .etr_assert(inherits(band,"etr_function_on_scalar_band") &&
      identical(band$reference,result),
      "band.reference must be the supplied result object")
  sh<-dim(result$coefficients)
  rows<-vector("list",prod(sh));i<-0L
  for(k in seq_len(sh[1L]))for(d in seq_len(sh[3L]))
    for(t in seq_len(sh[2L])){
      i<-i+1L
      row<-data.frame(coefficient=result$coefficient_names[k],
        time=result$time[t],dimension=result$dimension_names[d],
        estimate=result$coefficients[k,t,d],
        standard_error=result$standard_errors[k,t,d])
      if(!is.null(band)){
        row$lower<-band$lower[k,t,d]
        row$upper<-band$upper[k,t,d]
        row$critical_value<-band$critical_values[k]
      }
      rows[[i]]<-row
    }
  do.call(rbind,rows)
}
