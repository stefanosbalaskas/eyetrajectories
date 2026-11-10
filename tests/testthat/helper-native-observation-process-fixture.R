.etr_obs_fixture_frame <- function(ids=c("a","b","c")){
  times<-list(0:5,1:6,3:7)
  observed<-c(1,1,0,0,1,1,1,0,1,0,1,0,0,0,0,0,0)
  n<-length(observed)
  x<-seq_len(n)/3
  y<-(seq_len(n)%%4)^2/10
  x[observed==0]<-y[observed==0]<-NA_real_
  data.frame(curve=rep(ids,lengths(times)),
    participant=rep(c("p1","p1","p2"),lengths(times)),
    time=unlist(times,use.names=FALSE),observed=observed,
    design=seq(0,1,length.out=n),condition=rep(c("A","B","B"),lengths(times)),
    fixed=rep(2,n),x=x,y=y,stringsAsFactors=FALSE)
}

.etr_obs_fixture_input <- function(frame=.etr_obs_fixture_frame()){
  list(frame=frame,curve_column="curve",time_column="time",observed_column="observed",
    group_column="participant",candidate_predictors=c("design","condition","fixed"),
    predictor_sources=list(design="design",condition="design",fixed="external_candidate_time"),
    coordinate_columns=c("x","y"),time_unit="s",coordinate_system="degrees")
}

.etr_obs_fixture_options <- function(){
  list(risk_set="after_observed",time_bins=c(0,2.5,5,7),association_bins=3L,
    low_support_threshold=.6,eccentricity_reference=c(.1,.2),
    history_predictors=c("previous_observed_x","previous_observed_y",
      "previous_observed_speed","previous_observed_eccentricity",
      "time_since_last_observed","preceding_observed_run_length",
      "preceding_missing_run_length"))
}
