# Unsigned arithmetic on 16-bit limbs stays exact in R doubles.
.etr_numpy_u32_xor <- function(a,b) {
  limb<-2^16
  bitwXor(a%%limb,b%%limb)+limb*bitwXor(floor(a/limb),floor(b/limb))
}

.etr_numpy_u32_mul <- function(a,b) {
  limb<-2^16
  low_a<-a%%limb
  low_b<-b%%limb
  cross<-(floor(a/limb)*low_b+floor(b/limb)*low_a)%%limb
  (low_a*low_b+limb*cross)%%2^32
}

# NumPy uses the low bits of each word, redrawing values above the interval.
.etr_numpy_masked_permutation <- function(n,raw32) {
  result<-seq_len(n)
  if(n<=1L)return(result)
  for(i in seq.int(n,2L)){
    bound<-2^ceiling(log2(i))
    repeat{
      j<-1+raw32()%%bound
      if(j<=i)break
    }
    first<-result[i]
    result[i]<-result[j]
    result[j]<-first
  }
  result
}
