# Frozen Python 1.2 source _functional_simulation.py::_sample_curve_scores
# immutable c1cd95ad718327550f7e55393ff38582872f7a94.
# Student-t applies ONLY to curve scores; participant and trial scores
# remain Gaussian. Variance correction ensures component eigenvalues
# remain the intended finite-variance curve score moments.
# Native draws use base R by default or the supplied PCG64 stream.

.etr_functional_simulation_score_spec <- function(
    score_distribution,score_df) {
  .etr_assert(is.character(score_distribution)&&
    length(score_distribution)==1L&&!is.na(score_distribution)&&
    score_distribution%in%c("normal","student_t"),
    "score_distribution must be 'normal' or 'student_t'")
  if(identical(score_distribution,"normal"))
    return(list(kind="normal"))
  # Frozen Python float(score_df) accepts numeric or float-coercible
  # scalar strings. A df>2 restriction is essential: otherwise
  # the requested component score variance is undefined.
  .etr_assert((is.numeric(score_df)||is.logical(score_df)||
    is.character(score_df))&&length(score_df)==1L&&!is.na(score_df),
    "score_df must be finite and greater than 2 for score_distribution='student_t'")
  df<-suppressWarnings(as.numeric(score_df))
  .etr_assert(length(df)==1L&&is.finite(df)&&df>2,
    "score_df must be finite and greater than 2 for score_distribution='student_t'")
  list(kind="student_t",df=as.numeric(df))
}

.etr_functional_simulation_sample_curve_scores <- function(
    n,eigenvalues,spec,rng=NULL) {
  .etr_assert(is.numeric(n)&&length(n)==1L&&is.finite(n)&&
    n>=1L&&n==floor(n)&&
    is.numeric(eigenvalues)&&length(eigenvalues)>=1L&&
    all(is.finite(eigenvalues))&&all(eigenvalues>0),
    "source curve score dimensions and eigenvalues must be finite and positive")
  k<-length(eigenvalues)
  if(identical(spec$kind,"normal"))
    return(.etr_functional_simulation_normal_scores(n,eigenvalues,rng))
  .etr_assert(identical(spec$kind,"student_t")&&
    is.numeric(spec$df)&&length(spec$df)==1L&&
    is.finite(spec$df)&&spec$df>2,
    "Student-t score distribution requires finite df > 2")
  df<-spec$df
  # Var[t_df] = df/(df-2). Multiply by sqrt((df-2)/df),
  # making Var[curve score component j] = eigenvalues[j].
  scale<-sqrt(eigenvalues*((df-2)/df))
  draws<-if(is.null(rng))matrix(stats::rt(n*k,df=df),n,k) else {
    shape<-df/2
    values<-vapply(seq_len(as.double(n)*k),function(i){
      numerator<-rng$normal(1L)
      denominator<-.etr_functional_simulation_numpy_gamma(rng,shape)
      sqrt(shape)*numerator/sqrt(denominator)
    },numeric(1L))
    matrix(values,n,k,byrow=TRUE)
  }
  draws*matrix(rep(scale,each=n),n,k)
}
