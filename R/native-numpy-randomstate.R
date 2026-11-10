# NumPy 2.3.5 legacy RandomState scalar seed and MT19937 interval shuffle.
# Upstream notices are in inst/licenses/NUMPY-MT19937.txt.
.etr_numpy_randomstate_permutation <- function(n,seed) {
  .etr_assert(is.numeric(seed)&&is.null(dim(seed))&&length(seed)==1L&&
    is.finite(seed)&&seed==floor(seed)&&seed>=0&&seed<2^32,
    "random_state must be an unsigned 32-bit integer for NumPy shuffle")
  if(n<=1L)return(seq_len(n))
  xor<-.etr_numpy_u32_xor
  and<-function(a,b)
    bitwAnd(a%%2^16,b%%2^16)+2^16*bitwAnd(floor(a/2^16),floor(b/2^16))
  state<-numeric(624L)
  state[[1L]]<-seed
  for(i in 2:624){
    previous<-state[[i-1L]]
    state[[i]]<-(.etr_numpy_u32_mul(xor(previous,floor(previous/2^30)),
      0x6c078965)+i-1L)%%2^32
  }
  cursor<-624L
  raw32<-function(){
    if(cursor==624L){
      twisted<-state
      for(i in seq_len(624L)){
        current<-twisted[[i]]
        following<-twisted[[1L+i%%624L]]
        joined<-current-current%%2^31+following%%2^31
        shift<-floor(joined/2)
        if(joined%%2==1)shift<-xor(shift,0x9908b0df)
        twisted[[i]]<-xor(twisted[[1L+(i+396L)%%624L]],shift)
      }
      state<<-twisted
      cursor<<-0L
    }
    cursor<<-cursor+1L
    value<-state[[cursor]]
    value<-xor(value,floor(value/2^11))
    value<-xor(value,and((value*2^7)%%2^32,0x9d2c5680))
    value<-xor(value,and((value*2^15)%%2^32,0xefc60000))
    xor(value,floor(value/2^18))
  }
  .etr_numpy_masked_permutation(n,raw32)
}
