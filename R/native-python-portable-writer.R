# Native R writer for the frozen Python 1.2 JSON + NPZ portable schema.
# A bounded interoperable TrajectorySet snapshot, not a Python dataclass
# exporter or a claim of full source-contract parity.

.etr_portable_writer_npy <- function(path, x) {
  .etr_assert(is.atomic(x) && !is.factor(x) &&
    (is.numeric(x) || is.character(x) || is.logical(x)),
    "portable writer supports numeric, character and logical array fields")
  .etr_assert(!is.character(x) || !anyNA(x),
    "missing character metadata is not supported")
  .etr_assert(!is.logical(x) || !anyNA(x),
    "missing logical metadata is not supported")
  shape <- dim(x)
  if(is.null(shape)) shape <- as.integer(length(x))
  .etr_assert(length(shape)>=1L && length(shape)<=3L &&
    all(shape>=0L), "unsupported portable array shape")
  order <- if(length(shape)>1L) as.vector(aperm(array(x,dim=shape),
    rev(seq_along(shape)))) else as.vector(x)
  integer_array <- is.integer(x) && !anyNA(x)
  if(is.character(x)){
    order <- enc2utf8(order)
    width <- max(1L,vapply(order,function(z)length(utf8ToInt(z)),
      integer(1L)),na.rm=TRUE)
    descr <- paste0("<U",width)
  } else if(is.logical(x)) {
    descr <- "|b1"
  } else if(integer_array) {
    descr <- "<i4"
  } else {
    descr <- "<f8"
  }
  shape_text <- if(length(shape)==1L) {
    paste0(shape[[1L]],",")
  } else {
    paste(shape,collapse=", ")
  }
  header <- sprintf("{'descr': '%s', 'fortran_order': False, 'shape': (%s), }",
    descr,shape_text)
  padding <- (16L-(10L+nchar(header,type="bytes")+1L)%%16L)%%16L
  header <- paste0(header,strrep(" ",padding),"\n")
  header_bytes <- charToRaw(header)
  .etr_assert(length(header_bytes)<=65535L,"NumPy header too long")
  con <- file(path,open="wb")
  on.exit(close(con),add=TRUE)
  writeBin(as.raw(c(147,78,85,77,80,89,1,0)),con)
  n <- length(header_bytes)
  writeBin(as.raw(c(n%%256L,n%/%256L)),con)
  writeBin(header_bytes,con)
  if(is.character(x)){
    for(value in order){
      cps <- utf8ToInt(value)
      writeBin(as.integer(c(cps,rep(0L,width-length(cps)))),con,
        size=4L,endian="little")
    }
  } else if(is.logical(x)){
    writeBin(as.raw(as.integer(order)),con)
  } else if(integer_array){
    writeBin(order,con,size=4L,endian="little")
  } else {
    .etr_assert(!any(is.infinite(order) | is.nan(order)),
      "portable numeric arrays must not contain infinity or NaN")
    writeBin(as.double(order),con,size=8L,endian="little")
  }
  dtype <- if(is.character(x)) {
    descr
  } else if(is.logical(x)) {
    "bool"
  } else if(integer_array) {
    "int32"
  } else {
    "float64"
  }
  list(dtype=dtype,shape=as.list(as.integer(shape)))
}

.etr_portable_writer_json <- function(x,depth=0L) {
  .etr_assert(depth<=32L,"portable provenance nesting exceeds safe limit")
  if(is.null(x)) return(NULL)
  if(is.list(x) && !is.object(x)){
    keys <- names(x)
    if(is.null(keys))
      return(lapply(x,.etr_portable_writer_json,depth=depth+1L))
    .etr_assert(!anyNA(keys)&&all(nzchar(keys))&&!anyDuplicated(keys),
      "portable mapping requires unique nonempty keys")
    return(list('__portable_type__'="mapping",
      entries=lapply(seq_along(x),function(i)
        list(keys[[i]],.etr_portable_writer_json(x[[i]],depth+1L)))))
  }
  .etr_assert(is.atomic(x)&&is.null(dim(x))&&
    (is.character(x)||is.numeric(x)||is.logical(x))&&
    !anyNA(x)&&(!is.numeric(x)||all(is.finite(x))),
    "portable provenance must be finite JSON-like values")
  if(length(x)==1L)return(unname(x))
  lapply(as.list(unname(x)),.etr_portable_writer_json,depth=depth+1L)
}

#' Export native trajectories in a Python 1.2 readable portable container
#'
#' @description Writes JSON and unpickled NumPy arrays using the frozen
#'   Python 1.2 portable schema. Native export supports only common-grid
#'   trajectory results and one-dimensional numeric, character, or logical
#'   metadata. Missing character and logical cells use JSON null.
#' @param result An etr_trajectory_set; other result classes are unsupported.
#' @param directory New or empty destination directory.
#' @param include_environment Must be FALSE: an R environment is not a
#'   Python software environment and cannot impersonate one.
#' @param overwrite Must be FALSE to prevent destructive overwrites.
#' @return Normalized destination directory, invisibly.
#' @export
etr_export_python_portable_result <- function(result,directory,
    include_environment=FALSE,overwrite=FALSE){
  .etr_portable_require("jsonlite")
  .etr_portable_require("digest")
  .etr_portable_require("zip")
  .etr_assert(inherits(result,"etr_trajectory_set"),
    "native portable writer supports etr_trajectory_set only")
  etr_validate(result)
  .etr_assert(identical(include_environment,FALSE),
    "native writer cannot claim a Python environment snapshot")
  .etr_assert(identical(overwrite,FALSE),
    "native writer does not overwrite existing files")
  .etr_assert(is.character(directory)&&length(directory)==1L&&
    !is.na(directory)&&nzchar(directory),
    "directory must be a nonempty path")
  if(dir.exists(directory)) {
    .etr_assert(length(list.files(directory,all.files=TRUE,
      no..=TRUE))==0L,"portable destination directory is not empty")
  } else {
    .etr_assert(!file.exists(directory),"portable destination is a file")
  }
  .etr_assert(is.data.frame(result$metadata) &&
    !anyNA(names(result$metadata)) && all(nzchar(names(result$metadata))) &&
    !anyDuplicated(names(result$metadata)) &&
    all(vapply(result$metadata,function(z)
      is.null(dim(z)) && !is.factor(z) &&
        (is.numeric(z)||is.character(z)||is.logical(z)),
      logical(1L))),
    "unsupported metadata column type or labels")
  temp <- tempfile("etr_portable_writer_")
  dir.create(temp,recursive=TRUE)
  on.exit(unlink(temp,recursive=TRUE),add=TRUE)
  counter <- 0L
  saved <- character()
  add_array <- function(x){
    key <- sprintf("array_%05d",counter)
    counter <<- counter+1L
    filename <- paste0(key,".npy")
    info <- .etr_portable_writer_npy(file.path(temp,filename),x)
    saved <<- c(saved,filename)
    c(list('__portable_type__'="ndarray",key=key),info)
  }
  md <- result$metadata
  encode_column <- function(column) {
    if ((is.character(column) || is.logical(column)) && anyNA(column)) {
      return(list('__portable_type__'="object_array",
        shape=list(length(column)), items=as.list(unname(column))))
    }
    add_array(column)
  }
  payload <- list(
    '__portable_type__'="dataclass",
    python_type="eyetrajectoriespy.types.TrajectorySet",
    fields=list(
      time=add_array(result$time),
      values=add_array(result$values),
      curve_ids=list('__portable_type__'="tuple",
        items=as.list(result$curve_ids)),
      dimension_names=list('__portable_type__'="tuple",
        items=as.list(result$dimension_names)),
      metadata=list('__portable_type__'="dataframe",
        columns=as.list(names(md)),
        index=as.list(result$curve_ids),
        data=unname(lapply(md,encode_column))),
      coordinate_system=result$coordinate_system,
      time_unit=result$time_unit,
      provenance=if(!length(result$provenance))
        list('__portable_type__'='mapping',entries=list())
      else .etr_portable_writer_json(result$provenance)))
  archive <- file.path(temp,"arrays.npz")
  zip::zipr(zipfile=archive,files=saved,root=temp,compression_level=6L)
  .etr_assert(file.exists(archive),"portable NPZ archive was not created")
  manifest <- list(
    schema_version=1L,
    format="eyetrajectoriespy-portable-scientific-result",
    source_package_version=paste0("R-native-eyetrajectories-",
      as.character(getNamespaceVersion("eyetrajectories"))),
    result_type="eyetrajectoriespy.types.TrajectorySet",
    portable_scope=paste(
      "Scientific arrays, identifiers, specifications, units, diagnostics",
      "and provenance. Backend-native/opaque objects are not promised",
      "portable or reconstructible."),
    arrays_file="arrays.npz",
    arrays_sha256=digest::digest(archive,algo="sha256",file=TRUE,
      serialize=FALSE),
    units=list(time_unit=result$time_unit,
      coordinate_system=result$coordinate_system),
    nonportable_fields=list(),environment=NULL,payload=payload)
  json <- jsonlite::toJSON(manifest,auto_unbox=TRUE,null="null",
    pretty=TRUE,digits=NA,na="null")
  writeLines(as.character(json),file.path(temp,"manifest.json"),
    useBytes=TRUE)
  if(!dir.exists(directory))dir.create(directory,recursive=TRUE)
  .etr_assert(dir.exists(directory),"could not create portable destination")
  .etr_assert(file.copy(file.path(temp,"arrays.npz"),
    file.path(directory,"arrays.npz"),overwrite=FALSE),
    "could not write portable archive")
  if(!file.copy(file.path(temp,"manifest.json"),
      file.path(directory,"manifest.json"),overwrite=FALSE)){
    unlink(file.path(directory,"arrays.npz"))
    stop("could not write portable manifest",call.=FALSE)
  }
  invisible(normalizePath(directory,winslash="/",mustWork=TRUE))
}
