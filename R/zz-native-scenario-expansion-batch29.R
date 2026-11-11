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
    if(typeof(value)=="integer")return(as.character(value))
    # Python float str/repr uses a shortest round-trippable decimal and
    # exponential notation for decimal exponent <-4 or >=16. R's default
    # format(...,digits=15) can collapse distinct binary64 values.
    negative <- value<0 || (value==0 && (1/value)==-Inf)
    x <- abs(value)
    if(x==0)return(if(negative)"-0.0" else "0.0")
    shortest <- NULL
    for(n in seq_len(17L)) {
      candidate <- sprintf(paste0("%.",n,"g"),x)
      if(identical(suppressWarnings(as.numeric(candidate)),x)) {
        shortest <- candidate
        break
      }
    }
    if(is.null(shortest))shortest <- sprintf("%.17g",x)
    parts <- regmatches(shortest,regexec(
      "^([0-9]+)(?:\\.([0-9]+))?(?:[eE]([+-]?[0-9]+))?$",
      shortest,perl=TRUE))[[1L]]
    if(!length(parts))stop("cannot format source float slug",call.=FALSE)
    whole <- parts[[2L]]
    fraction <- if(length(parts)>=3L)parts[[3L]] else ""
    exponent <- if(length(parts)>=4L && nzchar(parts[[4L]]))
      as.integer(parts[[4L]]) else 0L
    digits <- paste0(whole,fraction)
    first <- regexpr("[1-9]",digits)[[1L]]
    if(first<1L)stop("nonzero float parsed as zero",call.=FALSE)
    decimal_exponent <- nchar(whole)+exponent-first
    significant <- sub("0+$","",substring(digits,first))
    if(decimal_exponent < -4L || decimal_exponent >= 16L) {
      mantissa <- if(nchar(significant)==1L)significant else paste0(
        substr(significant,1L,1L),".",
        substr(significant,2L,nchar(significant)))
      magnitude <- abs(decimal_exponent)
      exp_text <- paste0(if(decimal_exponent>=0L)"+" else "-",
        if(magnitude<10L)"0" else "",as.character(magnitude))
      rendered <- paste0(mantissa,"e",exp_text)
    } else {
      pos <- decimal_exponent+1L
      if(pos<=0L) {
        rendered <- paste0("0.",strrep("0",-pos),significant)
      } else if(pos>=nchar(significant)) {
        rendered <- paste0(significant,
          strrep("0",pos-nchar(significant)),".0")
      } else {
        rendered <- paste0(substr(significant,1L,pos),".",
          substr(significant,pos+1L,nchar(significant)))
      }
    }
    return(paste0(if(negative)"-" else "",rendered))
  }
  as.character(value)
}
.etr_b29_scenario_factor_slug <- function(value) {
  if(is.list(value) && !is.null(names(value))) {
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
  # Python's frozen dataclass cannot be edited after construction. Native
  # R lists can: replay the complete constructor before factor expansion
  # so an invalid edited base never silently leaks to every experiment.
  base <- do.call(etr_functional_simulation_scenario,unclass(base))
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
