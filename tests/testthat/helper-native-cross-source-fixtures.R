# Common deterministic scientific fixtures needed by multiple test files.
# In an installed-package R CMD check, testthat isolates per-file environments;
# helpers must be in helper-*.R, not imported from another test-*.R.
# No Python or independent certification is implied.

# Shared installed/source test fixture from tests/testthat/test-native-miaaft-fixed-permutation-source.R
.etr_miaaft_fixed_fixture <- function(n=32L) {
  tt<-seq(0,1,length.out=n)
  j<-seq_len(n)-1L
  vals<-array(0,c(2L,n,3L))
  for(k in 1:2) {
    vals[k,,1L]<-sin(.47*j+.21*k)+.11*cos(.83*j)+.013*j
    vals[k,,2L]<-cos(.37*j+.16*k)+.14*sin(.71*j)+.008*j
    vals[k,,3L]<-sin(.27*j+.11*k)+.07*cos(.51*j)+.019*j
  }
  etr_trajectory_set(tt,vals,c("a","b"),c("x","y","z"),
    coordinate_system="pixels",time_unit="s")
}
.etr_miaaft_fixed_orders <- function(b,n,d) {
  out<-array(0L,c(b,n,d))
  for(k in seq_len(b)) for(j in seq_len(d))
    out[k,,j]<-as.integer((seq_len(n)-1L + 3L*(j-1L) + k-1L)%%n)
  out
}

# Shared installed/source test fixture from tests/testthat/test-native-joint-fixed-covariance-bootstrap.R
.etr_joint_fixed_boot_fixture<-function(){
  time<-seq(0,1,length.out=7L)
  ids<-sprintf("curve%02d",seq_len(24L))
  pid<-rep(sprintf("P%02d",seq_len(8L)),each=3L)
  x<-rep(c(-1,0,1),8L)
  y<-array(0,c(24L,7L,1L))
  for(i in seq_len(24L)){
    g<-ceiling(i/3)
    y[i,,1L]<-.7+.23*time+x[i]*(.25-.15*time)+
      .18*sin(g*.6)+.13*cos(g*.31)*time+
      .06*sin(i*.7+time*4)+.035*cos(1.5*i*time)
  }
  tr<-etr_trajectory_set(time,y,curve_ids=ids,
    dimension_names="signal",metadata=data.frame(pid=pid),
    coordinate_system="degrees",time_unit="s")
  design<-data.frame(curve_id=rev(ids),x=rev(x))
  etr_fit_joint_bspline_functional_mixed_effects(tr,design,
    "x","pid","signal",fixed_basis_size=2L,
    random_basis_size=2L,spline_degree=1L,reml=TRUE)
}

# Shared installed/source test fixture from tests/testthat/test-native-joint-likelihood-full-refit-bootstrap.R
.etr_joint_full_refit_reference<-function(){
  t<-seq(0,1,length.out=7L)
  ids<-sprintf("curve%02d",seq_len(24L))
  pid<-rep(sprintf("P%02d",seq_len(8L)),each=3L)
  x<-rep(c(-1,0,1),8L)
  y<-array(0,c(24L,7L,1L))
  for(i in seq_len(24L)){
    g<-ceiling(i/3)
    y[i,,1L]<-.7+.23*t+x[i]*(.25-.15*t)+
      .18*sin(g*.6)+.13*cos(g*.31)*t+
      .06*sin(i*.7+t*4)+.035*cos(1.5*i*t)
  }
  tr<-etr_trajectory_set(t,y,ids,"signal",
    metadata=data.frame(pid=pid),
    coordinate_system="degrees",time_unit="s")
  design<-data.frame(curve_id=rev(ids),x=rev(x))
  etr_fit_joint_bspline_functional_mixed_effects(
    tr,design,"x","pid","signal",
    fixed_basis_size=2L,random_basis_size=2L,
    spline_degree=1L,reml=TRUE,maxiter=500L)
}
