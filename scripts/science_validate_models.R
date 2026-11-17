# Independent numerical/model oracles for native eyetrajectories R.
# Synthetic known truth; no participant data; optional fdapace backend tested
# distinctly from independently calculated analytic truth.
# source(url("https://raw.githubusercontent.com/stefanosbalaskas/eyetrajectories/main/scripts/science_validate_models.R"))
# Requires an installed eyetrajectories or pkgload::load_all(".").
# ET_SCI_MODEL_NO_AUTORUN=true to define functions only.

.sci_model_w <- function(t) {
  d<-diff(t);c(d[1L]/2,
              if(length(d)>1L)(d[-1L]+d[-length(d)])/2,
              tail(d,1L)/2)
}
.sci_model_data <- function(n=60L,nt=45L,seed=20261117L){
  set.seed(seed)
  t<-sort(c(0,1,stats::runif(nt-2L)))
  nsub<-n%/%3L;participant<-rep(seq_len(nsub),each=3L)
  subject_a<-stats::rnorm(nsub);subject_b<-stats::rnorm(nsub)
  trial_a<-stats::rnorm(n,sd=.4);trial_b<-stats::rnorm(n,sd=.3)
  a<-subject_a[participant]+trial_a
  b<-subject_b[participant]+trial_b
  x<-array(0,c(n,nt,2L))
  for(i in seq_len(n)){
    x[i,,1]<-1+2*sin(pi*t)+a[i]*sin(2*pi*t)+b[i]*cos(3*pi*t)
    x[i,,2]<-3+cos(2*pi*t)+.7*a[i]*cos(pi*t)-.3*b[i]*sin(4*pi*t)
  }
  list(time=t,values=x,participant=participant,coeff=cbind(a,b))
}
.sci_model_spectrum <- function(values,time){
  n<-dim(values)[1];nt<-dim(values)[2];nd<-dim(values)[3]
  w<-.sci_model_w(time)
  x<-matrix(0,n,nt*nd)
  for(t in seq_len(nt))for(j in seq_len(nd)){
    v<-values[,t,j]
    x[,(t-1L)*nd+j]<-(v-mean(v))*sqrt(w[t])
  }
  eig<-eigen(crossprod(x)/(n-1L),symmetric=TRUE,only.values=TRUE)$values
  eig[eig<0&abs(eig)<1e-9]<-0
  eig
}
.sci_model_compare <- function(observed,reference,tol=1e-8){
  length(observed)==length(reference)&&
    all(is.finite(observed))&&all(is.finite(reference))&&
    max(abs(observed-reference))<=tol*(1+max(abs(reference)))
}
sci_validate_models <- function(out=tempfile("SCIENCE_MODEL_ORACLES_"),
                                run_sparse=TRUE,seed=20261117L) {
  if(!dir.create(out,recursive=TRUE))stop("Cannot create evidence folder")
  d<-.sci_model_data(seed=seed)
  ids<-sprintf("example_%03d",seq_len(dim(d$values)[1]))
  X<-eyetrajectories::etr_trajectory_set(
    d$time,d$values,curve_ids=ids,dimension_names=c("x","y"),
    coordinate_system="pixels",time_unit="normalized")
  fit<-eyetrajectories::etr_fit_mfpca(X,n_components=3L)
  eig<-.sci_model_spectrum(d$values,d$time)
  max_error<-max(abs(fit$explained_variance-eig[1:3]))
  score_proj<-eyetrajectories::etr_transform_fpca(fit,X)
  score_diff<-min(max(abs(fit$scores-score_proj)),
                  max(abs(fit$scores+score_proj))) # reference scores may sign flip
  reconstruction<-eyetrajectories::etr_reconstruct_fpca(fit,n_components=3L)
  residual_rmse<-sqrt(mean((reconstruction$values-d$values)^2))
  average_rmse<-sqrt(mean((d$values-
          array(rep(as.vector(apply(d$values,c(2,3),mean)),each=length(ids)),
                    dim=dim(d$values)))^2))
  rows<-list(
    list(check="MFPCA_weighted_covariance_eigenspectrum",
         status=if(max_error<=1e-8)"PASS" else "FAIL",
         observed=max_error,reference=0,tolerance=1e-8,
         caveat="Independent crossprod/eigen decomposition on irregular grid"),
    list(check="MFPCA_train_projection_consistency",
         status=if(score_diff<=1e-8)"PASS" else "FAIL",
         observed=score_diff,reference=0,tolerance=1e-8,
         caveat="Score basis consistency, fitted training data"),
    list(check="MFPCA_reconstruction_vs_mean",
         status=if(residual_rmse<average_rmse)"PASS" else "FAIL",
         observed=residual_rmse,reference=average_rmse,tolerance=NA_real_,
         caveat="Improvement versus constant mean, not external ground truth")
  )
  # Regression comparison against independent least-squares linear algebra.
  y<-2 + .4*fit$scores[,1L]-.2*fit$scores[,2L]+
    stats::rnorm(nrow(fit$scores),sd=.05)
  reg<-eyetrajectories::etr_fit_scalar_on_fpca(fit,y,n_components=2L)
  design<-cbind(Intercept=1,fit$scores[,1:2,drop=FALSE])
  oracle<-qr.solve(design,y)
  coefs<-as.numeric(stats::coef(reg$model))
  beta_diff<-max(abs(coefs-oracle))
  rows[[length(rows)+1L]]<-list(
    check="scalar_on_fpca_independent_QR_OLS",
    status=if(beta_diff<1e-9)"PASS" else "FAIL",
    observed=beta_diff,reference=0,tolerance=1e-9,
    caveat="Conditional on estimated FPCA scores; not calibrated coefficient inference")
  # Subject-held-out prediction: do not leak FPCA basis from test participants.
  train<-which(d$participant<=15L)
  test<-which(d$participant>15L)
  Xt<-eyetrajectories::etr_subset(X,train)
  Xh<-eyetrajectories::etr_subset(X,test)
  f_train<-eyetrajectories::etr_fit_mfpca(Xt,n_components=2L)
  yt<-as.numeric(1.1+1.5*d$coeff[,1L]-.8*d$coeff[,2L])
  r_train<-eyetrajectories::etr_fit_scalar_on_fpca(f_train,yt[train],
                                                   n_components=2L)
  pred<-eyetrajectories::etr_predict_scalar_on_fpca(r_train,Xh)
  test_rmse<-sqrt(mean((pred-yt[test])^2))
  baseline_rmse<-sqrt(mean((mean(yt[train])-yt[test])^2))
  rows[[length(rows)+1L]]<-list(
    check="subject_heldout_scalar_on_fpca",
    status=if(all(is.finite(pred)))"PASS" else "FAIL",
    observed=test_rmse,reference=baseline_rmse,tolerance=NA_real_,
    caveat="Entire held-out participants, training-only FPCA; RMSE is descriptive")
  # Sparse PACE adapter delegates to fdapace; comparison to the SAME backend is
  # an interface parity check, not independent estimator validation.
  if(isTRUE(run_sparse)&&requireNamespace("fdapace",quietly=TRUE)){
    set.seed(seed+1L);n<-60L
    ts<-lapply(seq_len(n),function(i)sort(stats::runif(sample(7:12,1))))
    xi<-stats::rnorm(n)
    ys<-lapply(seq_len(n),function(i)
      1+sin(pi*ts[[i]])+xi[i]*cos(2*pi*ts[[i]])+
        stats::rnorm(length(ts[[i]]),sd=.07))
    collection<-eyetrajectories::etr_sparse_curves(ts,ys)
    opt<-list(dataType="Sparse",methodXi="CE",plot=FALSE,
              lean=TRUE,FVEthreshold=.95,maxK=2L)
    p<-tryCatch(eyetrajectories::etr_fit_sparse_pace(
      collection,max_components=2L,fve=.95),error=function(e)e)
    if(inherits(p,"error")) {
      rows[[length(rows)+1L]]<-list(check="sparse_PACE_backend_fit",
        status="ERROR",observed=NA_real_,reference=NA_real_,
        tolerance=NA_real_,caveat=conditionMessage(p))
    } else {
      direct<-tryCatch(fdapace::FPCA(Ly=ys,Lt=ts,optns=opt),
                       error=function(e)e)
      if(inherits(direct,"error")){
        rows[[length(rows)+1L]]<-list(check="sparse_PACE_backend_parity",
          status="ERROR",observed=NA_real_,reference=NA_real_,
          tolerance=NA_real_,caveat=conditionMessage(direct))
      } else {
        delta<-max(abs(p$model$xiEst-direct$xiEst))
        rows[[length(rows)+1L]]<-list(check="sparse_PACE_fdapace_adapter_parity",
          status=if(is.finite(delta)&&delta<=1e-9)"PASS" else "FAIL",
          observed=delta,reference=0,tolerance=1e-9,
          caveat="Same fdapace backend, not an independent PACE estimator oracle")
        fitted<-eyetrajectories::etr_sparse_pace_fitted(p)
        rows[[length(rows)+1L]]<-list(check="sparse_PACE_fitted_grid_is_finite",
          status=if(all(is.finite(fitted$fitted)))"PASS" else "FAIL",
          observed=mean(fitted$fitted^2),reference=NA_real_,
          tolerance=NA_real_,
          caveat="Finite reconstructed sparse curves, not a coverage test")
        # Separate estimator accuracy from backend parity. Compare the fitted
        # conditional-expectation curves to an INDEPENDENT analytic generator.
        truth <- matrix(0,n,length(fitted$time))
        for(i in seq_len(n))
          truth[i,] <- 1+sin(pi*fitted$time)+xi[i]*cos(2*pi*fitted$time)
        sparse_rmse <- sqrt(mean((fitted$fitted-truth)^2))
        mean_only <- matrix(rep(1+sin(pi*fitted$time),each=n),
                            nrow=n,ncol=length(fitted$time))
        baseline_rmse <- sqrt(mean((mean_only-truth)^2))
        rows[[length(rows)+1L]] <- list(check="sparse_PACE_independent_known_truth_RMSE",
          status="MEASURED_NOT_CERTIFIED",observed=sparse_rmse,
          reference=baseline_rmse,tolerance=NA_real_,
          caveat="Sparse Gaussian one-factor process; benchmark versus known generator and mean-only baseline")
        # This is sign-invariant and diagnostic, never a universal quality PASS.
        abs_score_corr <- abs(stats::cor(as.vector(p$model$xiEst[,1L]),xi))
        rows[[length(rows)+1L]] <- list(check="sparse_PACE_known_truth_score_correlation",
          status="MEASURED_NOT_CERTIFIED",observed=abs_score_corr,
          reference=1,tolerance=NA_real_,
          caveat="Absolute correlation to independent latent score, one-factor process")
      }
    }
  } else rows[[length(rows)+1L]]<-list(check="sparse_PACE_fdapace_backend",
      status="NOT_RUN",observed=NA_real_,reference=NA_real_,tolerance=NA_real_,
      caveat="Install optional fdapace or rerun with run_sparse=TRUE")
  frame<-do.call(rbind,lapply(rows,function(r)as.data.frame(r,
    stringsAsFactors=FALSE,check.names=FALSE)))
  utils::write.csv(frame,file.path(out,"model_oracles.csv"),row.names=FALSE,na="")
  writeLines(c("# Model validation — synthetic known truth","",
    paste0("Executed: ",format(Sys.time(),"%Y-%m-%d %H:%M:%S %Z")),
    paste0("Executed checks: ",sum(frame$status %in% c("PASS","FAIL")),
           "; failures: ",sum(frame$status %in% c("FAIL","ERROR")),"."),
    "Dense FPCA: independent weighted covariance eigenvalues, projection,",
    "and reconstruction. Scalar regression: independent QR OLS and held-out",
    "participants, with training-only estimated score basis.",
    "Sparse PACE: optional fdapace adapter parity (same backend), NOT",
    "independent estimation equivalence. All data synthetic; no new real-data",
    "scientific inference certification."),file.path(out,"MODEL_SCOPE.md"))
  writeLines(capture.output(utils::sessionInfo()),
             file.path(out,"R_session_info.txt"))
  if(any(frame$status %in% c("FAIL","ERROR")))
    warning("Some model checks failed; inspect model_oracles.csv")
  message("SCIENCE_MODEL_RESULTS=",out)
  invisible(frame)
}
if(!identical(tolower(Sys.getenv("ET_SCI_MODEL_NO_AUTORUN")),"true"))
  sci_validate_models()
