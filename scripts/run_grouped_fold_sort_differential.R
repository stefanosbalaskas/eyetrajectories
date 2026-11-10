# Compare native integer ordering with NumPy 2.3.5's dispatched and scalar
# paths. These are sorting witnesses, separate from public API comparisons.
.etr_grouped_fold_sort_differential <- function() {
  pkgload::load_all(".",quiet=TRUE)
  python <- reticulate::py_config()$python
  scratch <- tempfile("etr_fold_sort_")
  stopifnot(dir.create(scratch))
  on.exit(unlink(scratch,recursive=TRUE),add=TRUE)
  path <- function(name) file.path(scratch,name)
  writeLines(c(
    "import json, sys, numpy as np",
    "from numpy._core._multiarray_umath import __cpu_dispatch__",
    "assert np.__version__ == '2.3.5'",
    "with open(sys.argv[1]) as f:",
    "    counts = json.load(f)",
    "with open(sys.argv[2], 'w') as f:",
    "    json.dump(dict(dispatch=__cpu_dispatch__,",
    "        witness=np.argsort([2, 2, 1, 1]).tolist(),",
    "        orders=[np.argsort(np.array(x, dtype=np.intp)).tolist() for x in counts]), f)"
  ),path("oracle.py"),useBytes=TRUE)
  run <- function(cases,disabled=NULL) {
    jsonlite::write_json(cases,path("input.json"),auto_unbox=FALSE)
    if(!is.null(disabled)){
      previous <- Sys.getenv("NPY_DISABLE_CPU_FEATURES",unset=NA_character_)
      on.exit(if(is.na(previous))Sys.unsetenv("NPY_DISABLE_CPU_FEATURES") else
        Sys.setenv(NPY_DISABLE_CPU_FEATURES=previous),add=TRUE)
      Sys.setenv(NPY_DISABLE_CPU_FEATURES=paste(disabled,collapse=","))
    }
    status <- system2(python,shQuote(path(c("oracle.py","input.json","output.json"))))
    stopifnot(identical(status,0L))
    jsonlite::read_json(path("output.json"),simplifyVector=FALSE)
  }
  small <- do.call(c,lapply(2:8,function(n){
    grid <- as.matrix(expand.grid(rep(list(1:3),n)))
    lapply(seq_len(nrow(grid)),function(i)grid[i,])
  }))
  boundary <- c(9L,15L,16L,17L,31L,32L,33L,63L,64L,65L,99L,127L,
    128L,129L,199L,255L,256L)
  cases <- c(small,.etr_seed_scope(643L,function()do.call(c,
    lapply(boundary,function(n)replicate(100L,sample.int(14L,n,replace=TRUE),
      simplify=FALSE)))))
  scalar_extra <- .etr_seed_scope(644L,function()do.call(c,lapply(
    c(257L,512L,1025L,2048L),function(n){
      ordered <- rep(seq_len(ceiling(n/3)),each=3L,length.out=n)
      c(list(ordered,rev(ordered),c(seq_len(n%/%2L),rev(seq_len(n-n%/%2L)))),
        replicate(20L,sample.int(18L,n,replace=TRUE),simplify=FALSE))
    })))
  normal <- run(cases)
  witness <- as.integer(unlist(normal$witness))
  simd <- identical(witness,c(3L,2L,1L,0L))
  stopifnot(simd || identical(witness,c(2L,3L,0L,1L)))
  disabled <- intersect(unlist(normal$dispatch),
    c("AVX2","AVX512F","AVX512_SKX","AVX512_CLX","AVX512_CNL",
      "AVX512_ICL","AVX512_SPR"))
  scalar_cases <- c(cases,scalar_extra)
  scalar <- run(scalar_cases,disabled)
  stopifnot(identical(as.integer(unlist(scalar$witness)),c(2L,3L,0L,1L)))
  compare <- function(cases,expected,sort_indices,profile) {
    for(i in seq_along(cases)){
      got <- sort_indices(cases[[i]])-1L
      want <- as.integer(unlist(expected[[i]]))
      if(!identical(got,want))stop(paste(profile,"argsort mismatch at case",i,
        "with",length(got),"groups"),call.=FALSE)
    }
    cat("GROUPED_FOLD_SORT_PROFILE=",profile,";CASES=",length(cases),
      ";DIFFERENCES=0\n",sep="")
  }
  if(simd)compare(cases,normal$orders,.etr_numpy_group_argsort_simd,"numpy_simd")
  compare(scalar_cases,scalar$orders,.etr_numpy_group_argsort_scalar,"numpy_scalar")
}
.etr_grouped_fold_sort_differential()
