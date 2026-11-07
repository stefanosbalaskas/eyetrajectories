# Batch 29 v4 reference expansion. DOES NOT override the existing public function.
# Frozen Python source c1cd95ad718327550f7e55393ff38582872f7a94.
# No gap closure or independent certification is implied.

# Python 1.2 _scenario_factor_slug parity for supported native R values.
# Python source: eyetrajectoriespy 1.2.0 simulate.py at c1cd95ad718327550f7e55393ff38582872f7a94.
.etr_b29_factor_py_scalar <- function(value) {
  if(is.null(value))return("None")
  if(length(value)!=1L)stop("factor slug scalar must have length 1",call.=FALSE)
  if(is.logical(value)) {
    if(is.na(value))return("None")
    return(if(value)"True" else "False")
  }
  if(is.character(value))return(if(is.na(value))"None" else value)
  if(is.numeric(value)) {
    if(is.nan(value))return("nan")
    if(is.na(value))return("None")
    if(is.infinite(value))return(if(value>0)"inf" else "-inf")
    raw <- format(value,digits=15L,scientific=FALSE,trim=TRUE)
    if(typeof(value)=="double" && is.finite(value) &&
       !grepl("[.eE]",raw))raw<-paste0(raw,".0")
    return(raw)
  }
  as.character(value)
}

.etr_b29_scenario_factor_slug <- function(value) {
  if(is.list(value) && !is.null(names(value)) &&
     any(nzchar(names(value)))) {
    raw <- .etr_b29_factor_py_scalar(
      if("kind" %in% names(value)) value[["kind"]] else "mapping")
  } else if(is.array(value) && length(dim(value))>0L) {
    raw <- paste0("array",length(value))
  } else if(is.list(value) || length(value)>1L) {
    if(length(value)>4L) {
      raw <- paste0("seq",length(value))
    } else {
      raw <- paste(vapply(as.list(value),.etr_b29_factor_py_scalar,
                          character(1L)),collapse="-")
    }
  } else {
    raw <- .etr_b29_factor_py_scalar(value)
  }
  slug <- gsub("[^A-Za-z0-9_.+-]+","-",raw,perl=TRUE)
  slug <- sub("^-+","",sub("-+$","",slug))
  if(nzchar(slug))slug else "value"
}

# Internal reference implementation for comparison with locally modified source.
#' Expand scenario factors using Python 1.2 ordered Cartesian semantics
#' @param base Validated native FunctionalSimulationScenario.
#' @param factors Named list of factor-level sequences; vector-valued levels
#'   must be wrapped in a list, e.g. eigenvalues=list(c(1,.5),c(1,.2)).
#' @param seed_policy Explicit shared or disjoint replicate-seed blocks.
#' @return Ordered native scenario objects, with Python-compatible slugs
#'   on supported scalar, sequence, array and mapping values. Runtime classes,
#'   arbitrary Python objects and exception types are not equivalent.
etr_expand_functional_simulation_scenarios_b29 <- function(base,factors,
    seed_policy=c("shared","disjoint")) {
  .etr_assert(inherits(base,"etr_functional_simulation_scenario"),
    "base must be a native functional simulation scenario")
  seed_policy <- match.arg(seed_policy)
  .etr_assert(is.list(factors) && length(factors)>0L &&
    !is.null(names(factors)) && !anyNA(names(factors)) &&
    all(nzchar(names(factors))) && !anyDuplicated(names(factors)),
    "factors must be a named nonempty list")
  factor_names <- names(factors)
  .etr_assert(!("seed_start" %in% factor_names),
    "seed_start is controlled by seed_policy (unsupported factor)")
  allowed <- setdiff(names(unclass(base)),c("name","seed_start"))
  .etr_assert(all(factor_names %in% allowed),
    "unknown or currently unsupported scenario factor")
  levels <- lapply(seq_along(factors),function(j) {
    v <- factors[[j]]
    # Atomic R vectors encode sequences of scalar levels; list() encodes
    # arbitrary nested Python sequence/mapping/array-like factor values.
    .etr_assert(is.list(v) || (is.atomic(v) && is.null(dim(v))),
      "factor must be an explicit sequence of levels")
    .etr_assert(length(v)>0L,"factor must contain at least one level")
    if(!is.list(v))v<-as.list(v)
    v
  })
  grid <- do.call(expand.grid,c(rev(lapply(levels,seq_along)),
    list(KEEP.OUT.ATTRS=FALSE,stringsAsFactors=FALSE)))
  grid <- grid[,ncol(grid):1L,drop=FALSE]
  results <- vector("list",nrow(grid))
  for(i in seq_len(nrow(grid))) {
    src <- unclass(base)
    suffix <- character(length(levels))
    for(j in seq_along(levels)) {
      value <- levels[[j]][[grid[i,j]]]
      nm <- factor_names[[j]]
      # Single-index list assignment rather than [[<- retains explicit NULL.
      src[nm] <- list(value)
      suffix[[j]] <- paste0(nm,"=",.etr_b29_scenario_factor_slug(value))
    }
    src$name <- paste0(base$name,"__",paste(suffix,collapse="__"))
    next_seed <- if(seed_policy=="shared")as.double(base$seed_start) else
      as.double(base$seed_start)+(i-1L)*as.double(base$replicates)
    .etr_assert(is.finite(next_seed)&&
      next_seed>=-.Machine$integer.max&&next_seed<=.Machine$integer.max,
      "disjoint seed_start exceeds native R integer domain")
    src$seed_start <- as.integer(next_seed)
    results[[i]] <- do.call(etr_functional_simulation_scenario,src)
  }
  results
}
