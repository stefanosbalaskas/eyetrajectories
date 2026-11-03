# Exact dense linear-sum assignment in pure native R.
# Frozen Python source: scipy.optimize.linear_sum_assignment(-abs(similarity)),
# stability.py::match_fpca_components, eyetrajectoriespy 1.2.0.
# This is the O(k^3) Hungarian primal-dual augmenting-path algorithm;
# unlike a 2^k subset DP it supports realistic fitted component counts.

.etr_exact_assignment_hungarian <- function(cost) {
  .etr_assert(is.matrix(cost)&&is.numeric(cost)&&
    nrow(cost)>=1L&&nrow(cost)==ncol(cost)&&
    all(is.finite(cost)),
    "assignment cost must be a finite square numeric matrix")
  n<-nrow(cost)
  # Index 1 is the algorithm's dummy zero column/row; real columns use
  # j+1. Row pointers p are 1-based real rows or 0 for unassigned.
  u<-numeric(n+1L);v<-numeric(n+1L)
  p<-integer(n+1L);way<-integer(n+1L)
  for(i in seq_len(n)){
    p[1L]<-i
    j0<-0L
    minv<-rep(Inf,n+1L)
    used<-rep(FALSE,n+1L)
    repeat {
      used[j0+1L]<-TRUE
      i0<-p[j0+1L]
      delta<-Inf
      j1<-NA_integer_
      for(j in seq_len(n)) if(!used[j+1L]){
        current<-cost[i0,j]-u[i0+1L]-v[j+1L]
        if(current<minv[j+1L]){
          minv[j+1L]<-current
          way[j+1L]<-j0
        }
        if(minv[j+1L]<delta){
          delta<-minv[j+1L]
          j1<-j
        }
      }
      .etr_assert(is.finite(delta)&&!is.na(j1),
        "exact assignment has no finite augmenting path")
      for(j in 0:n){
        if(used[j+1L]){
          u[p[j+1L]+1L]<-u[p[j+1L]+1L]+delta
          v[j+1L]<-v[j+1L]-delta
        }else minv[j+1L]<-minv[j+1L]-delta
      }
      j0<-j1
      if(p[j0+1L]==0L)break
    }
    repeat {
      j1<-way[j0+1L]
      p[j0+1L]<-p[j1+1L]
      j0<-j1
      if(j0==0L)break
    }
  }
  assignment<-integer(n)
  for(j in seq_len(n))assignment[p[j+1L]]<-j-1L
  .etr_assert(identical(sort(assignment),as.integer(seq_len(n)-1L)),
    "exact Hungarian assignment is not a permutation")
  assignment
}
