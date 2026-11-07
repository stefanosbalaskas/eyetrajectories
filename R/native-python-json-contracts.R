# Native source-compatible JSON for published eyetrajectoriespy 1.2.0.
# Frozen Python uses _jsonable, json.dumps(sort_keys=True) and two separator
# conventions: compact for workflows and spaced for simulation design frames.
# This is an explicit native R value representation, not Python object identity.
.etr_python_json_string <- function(x) {
  .etr_assert(is.character(x)&&length(x)==1L&&!is.na(x),
    "JSON string must be one complete character value")
  if (!requireNamespace("jsonlite",quietly=TRUE))
    stop("jsonlite required for source JSON quoting",call.=FALSE)
  raw<-as.character(jsonlite::toJSON(enc2utf8(x),auto_unbox=TRUE))
  # Python json.dumps defaults to ensure_ascii=True. Encode non-ASCII scalar
  # values, including supplementary-plane pairs, as JSON Unicode escapes.
  points<-utf8ToInt(enc2utf8(raw))
  paste0(vapply(points,function(p){
    if(p<=127L)return(intToUtf8(p))
    if(p<=65535L)return(sprintf("\\u%04x",p))
    z<-p-65536L
    paste0(sprintf("\\u%04x",55296L+z%/%1024L),
           sprintf("\\u%04x",56320L+z%%1024L))
  },character(1L)),collapse="")
}

.etr_python_json_float <- function(x) {
  .etr_assert(is.numeric(x)&&length(x)==1L&&!is.na(x)&&is.finite(x),
    "source JSON floats must be finite")
  if(x==0)return(if(is.infinite(1/x) && 1/x<0)"-0.0" else "0.0")
  shortest<-NULL; significant<-17L
  # Choose the shortest decimal number with a round-trip double representation.
  # This reproduces Python's conventional shortest-float notation for ordinary
  # finite simulation/report values. Difficult halfway/huge cases remain an
  # explicit domain to compare with the direct source, not assumed equivalent.
  for(k in 1:17){
    candidate<-sprintf(paste0("%.",k,"g"),x)
    if(identical(suppressWarnings(as.numeric(candidate)),as.numeric(x))){
      shortest<-candidate;significant<-k;break
    }
  }
  if(is.null(shortest))shortest<-sprintf("%.17g",x)
  ax<-abs(x)
  if(ax<1e-4 || ax>=1e16){
    # Normalize e+005/e-005 to Python's e+05/e-05 notation.
    candidate<-sprintf(paste0("%.",significant-1L,"e"),x)
    pieces<-strsplit(candidate,"e",fixed=TRUE)[[1L]]
    exponent<-as.integer(pieces[[2L]])
    mantissa<-sub("0+$","",pieces[[1L]])
    mantissa<-sub("\\.$","",mantissa)
    return(paste0(mantissa,"e",if(exponent>=0)"+" else "-",
      sprintf("%02d",abs(exponent))))
  }
  if(grepl("[eE]",shortest)){
    # Rebuild fixed-point notation, keeping enough digits to round trip.
    digits_after<-max(0L,significant-1L-floor(log10(ax)))
    shortest<-sprintf(paste0("%.",digits_after,"f"),x)
    if(grepl("\\.",shortest)) {
      shortest<-sub("0+$","",shortest)
      shortest<-sub("\\.$","",shortest)
    }
  }
  if(!grepl("\\.",shortest))shortest<-paste0(shortest,".0")
  shortest
}

.etr_python_json_encode <- function(value,compact=TRUE,force_array=FALSE,
                                    empty_mapping=FALSE) {
  .etr_assert(is.logical(compact)&&length(compact)==1L&&!is.na(compact),
    "compact must be TRUE or FALSE")
  sep<-if(compact)"," else ", "
  colon<-if(compact)":" else ": "
  encode<-function(x,array=FALSE,map=FALSE){
    if(is.null(x))return("null")
    if(is.factor(x)||is.data.frame(x)||is.complex(x))
      stop("source JSON requires explicit supported scalar, vector or mapping types",call.=FALSE)
    if(is.matrix(x)){
      .etr_assert(is.numeric(x)||is.logical(x),
        "source JSON matrix must be numeric or logical")
      rows<-lapply(seq_len(nrow(x)),function(i)as.vector(x[i,,drop=TRUE]))
      return(paste0("[",paste(vapply(rows,function(y)encode(y,array=TRUE),
        character(1L)),collapse=sep),"]"))
    }
    if(is.list(x)){
      nm<-names(x)
      if(!is.null(nm)){
        .etr_assert(length(nm)==length(x)&&!anyNA(nm)&&
          !anyDuplicated(nm),"JSON mapping keys must be unique strings")
        o<-order(nm,method="radix")
        parts<-vapply(o,function(i)paste0(
          .etr_python_json_string(nm[[i]]),colon,encode(x[[i]])),character(1L))
        return(paste0("{",paste(parts,collapse=sep),"}"))
      }
      if(!length(x)&&map)return("{}")
      return(paste0("[",paste(vapply(x,encode,character(1L)),collapse=sep),"]"))
    }
    if(!is.atomic(x)||(!is.character(x)&&!is.numeric(x)&&!is.logical(x)))
      stop("unsupported source JSON value type",call.=FALSE)
    if(anyNA(x)||(is.numeric(x)&&any(!is.finite(x))))
      stop("source JSON contains nonfinite or missing values",call.=FALSE)
    if(length(x)!=1L||array){
      if(length(x)==0L)return("[]")
      return(paste0("[",paste(vapply(seq_along(x),function(i)
        encode(x[[i]]),character(1L)),collapse=sep),"]"))
    }
    if(is.character(x))return(.etr_python_json_string(x))
    if(is.logical(x))return(if(x)"true" else "false")
    if(is.integer(x))return(as.character(x))
    .etr_python_json_float(x)
  }
  encode(value,array=force_array,map=empty_mapping)
}
