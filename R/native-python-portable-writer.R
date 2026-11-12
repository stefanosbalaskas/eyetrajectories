# Native R writer for the frozen Python 1.2 JSON + NPZ portable schema.
# Explicit native trajectory and FPCA mappings into portable snapshots.

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

.etr_portable_writer_mapping <- function(items) {
  list('__portable_type__'="mapping",
    entries=lapply(seq_along(items),function(i) list(names(items)[[i]],items[[i]])))
}

.etr_portable_writer_json <- function(x,depth=0L,add_array=NULL) {
  .etr_assert(depth<=32L,"portable provenance nesting exceeds safe limit")
  if(is.null(x)) return(NULL)
  if(!is.null(add_array) && is.array(x)) {
    .etr_assert((is.numeric(x)||is.logical(x)) && all(is.finite(x)),
      "portable workflow arrays must be finite numeric or logical values")
    return(add_array(x))
  }
  if(is.list(x) && !is.object(x)){
    keys <- names(x)
    if(!is.null(keys))
      .etr_assert(!anyNA(keys)&&all(nzchar(keys))&&!anyDuplicated(keys),
        "portable mapping requires unique nonempty keys")
    items <- lapply(x,.etr_portable_writer_json,depth=depth+1L,add_array=add_array)
    if(is.null(keys)) return(items)
    return(.etr_portable_writer_mapping(items))
  }
  .etr_assert(is.atomic(x)&&is.null(dim(x))&&
    (is.character(x)||is.numeric(x)||is.logical(x))&&
    !anyNA(x)&&(!is.numeric(x)||all(is.finite(x))),
    "portable provenance must be finite JSON-like values")
  if(length(x)==1L)return(unname(x))
  lapply(as.list(unname(x)),.etr_portable_writer_json,depth=depth+1L)
}

.etr_portable_writer_record <- function(type, fields, module="eyetrajectoriespy.types") {
  list('__portable_type__'="dataclass",
    python_type=paste0(module,".",type),fields=fields)
}

.etr_portable_writer_tuple <- function(values) {
  list('__portable_type__'="tuple",items=unname(as.list(values)))
}

.etr_portable_writer_provenance <- function(provenance) {
  if(is.null(provenance)) provenance <- list()
  .etr_assert(.etr_provenance_valid(provenance),
    "portable provenance must be a JSON-like named list")
  if(!length(provenance))
    return(list('__portable_type__'="mapping",entries=list()))
  .etr_portable_writer_json(provenance)
}

.etr_portable_writer_dataframe <- function(metadata,index,add_array) {
  .etr_assert(is.data.frame(metadata) && nrow(metadata)==length(index) &&
    !anyNA(names(metadata)) && all(nzchar(names(metadata))) &&
    !anyDuplicated(names(metadata)) &&
    all(vapply(metadata,function(z)
      is.null(dim(z)) && !is.factor(z) &&
        (is.numeric(z)||is.character(z)||is.logical(z)),
      logical(1L))),
    "unsupported metadata column type or labels")
  encode_column <- function(column) {
    if ((is.character(column) || is.logical(column)) && anyNA(column)) {
      items <- lapply(as.list(unname(column)),function(x) if(is.na(x))NULL else x)
      return(list('__portable_type__'="object_array",
        shape=list(length(column)),items=items))
    }
    add_array(column)
  }
  list('__portable_type__'="dataframe",columns=as.list(names(metadata)),
    index=unname(as.list(index)),data=unname(lapply(metadata,encode_column)))
}

.etr_portable_writer_trajectories <- function(result,add_array,irregular) {
  if(irregular) {
    .etr_irregular_validate_samples(result)
    time <- .etr_portable_writer_tuple(lapply(result$time,add_array))
    values <- .etr_portable_writer_tuple(lapply(result$values,add_array))
    type <- "IrregularTrajectorySet"
  } else {
    etr_validate(result)
    time <- add_array(result$time)
    values <- add_array(result$values)
    type <- "TrajectorySet"
  }
  .etr_portable_writer_record(type,list(time=time,values=values,
    curve_ids=.etr_portable_writer_tuple(result$curve_ids),
    dimension_names=.etr_portable_writer_tuple(result$dimension_names),
    metadata=.etr_portable_writer_dataframe(result$metadata,result$curve_ids,add_array),
    coordinate_system=result$coordinate_system,time_unit=result$time_unit,
    provenance=.etr_portable_writer_provenance(result$provenance)))
}

.etr_portable_writer_fpca <- function(result,add_array) {
  .etr_assert(inherits(result,"etr_fpca") && is.list(result),
    "expected a native dense etr_fpca fit")
  n <- length(result$curve_ids)
  nt <- length(result$time)
  nd <- length(result$dimension_names)
  k <- result$n_components
  .etr_assert(is.numeric(k) && length(k)==1L && is.finite(k) &&
    k==floor(k) && k>=1 && k<=min(n,nt*nd) && nt>=2L && nd>=1L && n>=2L,
    "native FPCA component count or fit dimensions are invalid")
  k <- as.integer(k)
  for(field in c("curve_ids","dimension_names")) {
    ids <- result[[field]]
    .etr_assert(is.character(ids) && !anyNA(ids) && !anyDuplicated(ids),
      paste("invalid native FPCA",field))
  }
  for(field in c("coordinate_system","time_unit")) {
    unit <- result[[field]]
    .etr_assert(is.character(unit) && length(unit)==1L && !is.na(unit),
      paste("invalid native FPCA",field))
  }
  shapes <- list(mean=c(nt,nd),components=c(k,nt,nd),scores=c(n,k),
    explained_variance=k,explained_variance_ratio=k,time=nt,
    weights=nt,scale=nd)
  for(field in names(shapes)) {
    x <- result[[field]]
    shape <- if(is.null(dim(x))) length(x) else dim(x)
    .etr_assert(is.numeric(x) && identical(shape,shapes[[field]]) &&
      all(is.finite(x)),paste("invalid native FPCA array",field))
  }
  .etr_assert(all(diff(result$time)>0) && all(result$weights>0) &&
    all(result$scale>0) && all(result$explained_variance>=0) &&
    all(result$explained_variance_ratio>=0),"invalid native FPCA spectrum or grid")
  .etr_assert(is.numeric(result$total_variance) &&
    length(result$total_variance)==1L && is.finite(result$total_variance) &&
    result$total_variance>0 && length(result$scaling)==1L &&
    is.character(result$scaling) && result$scaling %in% c("none","dimension_sd") &&
    is.null(result$model),"invalid native FPCA fit audit or backend object")
  .etr_assert(is.null(result$provenance) || .etr_provenance_valid(result$provenance),
    "portable provenance must be a JSON-like named list")
  provenance <- c(result$provenance,list(native_r_fpca=list(
    n_components=k,scaling=result$scaling,total_variance=result$total_variance)))
  .etr_portable_writer_record("FPCAResult",c(
    lapply(result[names(shapes)[1:6]],add_array),
    list(dimension_names=.etr_portable_writer_tuple(result$dimension_names),
      coordinate_system=result$coordinate_system,time_unit=result$time_unit,
      curve_ids=.etr_portable_writer_tuple(result$curve_ids),
      weights=add_array(result$weights),scale=add_array(result$scale),
      provenance=.etr_portable_writer_provenance(provenance),model=NULL)))
}

.etr_portable_writer_compositional <- function(result,add_array) {
  dimensions <- result$original_dimension_names
  reference <- result$reference_dimension
  epsilon <- result$epsilon
  .etr_assert(inherits(result$fpca,"etr_fpca") && is.list(result$fpca) &&
    is.character(dimensions) && length(dimensions)>=3L &&
    !anyNA(dimensions) && !anyDuplicated(dimensions) &&
    length(dimensions)==length(result$fpca$dimension_names)+1L &&
    is.numeric(reference) && length(reference)==1L && is.finite(reference) &&
    reference==floor(reference) && reference>=0 && reference<length(dimensions) &&
    is.numeric(epsilon) && length(epsilon)==1L && is.finite(epsilon) && epsilon>0,
    "invalid native compositional FPCA dimensions or transform parameters")
  .etr_portable_writer_record("CompositionalFPCAResult",list(
    fpca=.etr_portable_writer_fpca(result$fpca,add_array),
    reference_dimension=as.integer(reference),
    original_dimension_names=.etr_portable_writer_tuple(dimensions),
    epsilon=epsilon,provenance=.etr_portable_writer_provenance(result$provenance)))
}

#' Export native trajectories or FPCA in a Python 1.2 readable container
#'
#' @description Writes JSON and unpickled NumPy arrays using the frozen
#'   Python 1.2 portable schema. Native export supports common-grid and
#'   irregular trajectories, dense FPCA/MFPCA and compositional FPCA.
#'   Missing character and logical metadata cells use JSON null.
#'   Frozen Python 1.2 sparse MFPCA strict 29-field joint PACE scientific
#'   records and fixed-bandwidth paired W2 workflows are additionally
#'   supported without Python runtime type identity.
#' @param result An etr_trajectory_set, etr_irregular_trajectory_set,
#'   etr_fpca, or etr_compositional_fpca.
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
  .etr_assert(is.list(result) && inherits(result,c("etr_trajectory_set",
    "etr_irregular_trajectory_set","etr_fpca","etr_compositional_fpca",
    "etr_sparse_mfpca_w2_scientific_record",
    "etr_sparse_mfpca_paired_source_workflow")),
    paste("native portable writer supports etr_trajectory_set,",
      "etr_irregular_trajectory_set, etr_fpca and etr_compositional_fpca"))
  .etr_assert(identical(include_environment,FALSE),
    "native writer cannot claim a Python environment snapshot")
  .etr_assert(identical(overwrite,FALSE),
    "native writer does not overwrite existing files")
  .etr_write_python_portable_result(directory,function(add_array) {
    if(inherits(result,"etr_trajectory_set")) {
      .etr_portable_writer_trajectories(result,add_array,irregular=FALSE)
    } else if(inherits(result,"etr_irregular_trajectory_set")) {
      .etr_portable_writer_trajectories(result,add_array,irregular=TRUE)
    } else if(inherits(result,"etr_fpca")) {
      .etr_portable_writer_fpca(result,add_array)
    } else if(inherits(result,"etr_sparse_mfpca_paired_source_workflow")){
      .etr_python_mfpca_portable_workflow(result,add_array)
    } else if(inherits(result,"etr_sparse_mfpca_w2_scientific_record")){
      .etr_python_mfpca_portable_fit(result,add_array)
    } else {
      .etr_portable_writer_compositional(result,add_array)
    }
  })
}

.etr_write_python_portable_result <- function(directory,encode_payload,
    encode_manifest=function(x) jsonlite::toJSON(x,auto_unbox=TRUE,null="null",
      pretty=TRUE,digits=NA,na="null")) {
  .etr_assert(is.character(directory)&&length(directory)==1L&&
    !is.na(directory)&&nzchar(directory),
    "directory must be a nonempty path")
  if(dir.exists(directory)) {
    .etr_assert(length(list.files(directory,all.files=TRUE,
      no..=TRUE))==0L,"portable destination directory is not empty")
  } else {
    .etr_assert(!file.exists(directory),"portable destination is a file")
  }
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
  payload <- encode_payload(add_array)
  unit_names <- intersect(c("time_unit","coordinate_system"),names(payload$fields))
  units <- if(length(unit_names)) payload$fields[unit_names] else
    structure(list(),names=character())
  archive <- file.path(temp,"arrays.npz")
  zip::zipr(zipfile=archive,files=saved,root=temp,compression_level=6L)
  .etr_assert(file.exists(archive),"portable NPZ archive was not created")
  manifest <- list(
    schema_version=1L,
    format="eyetrajectoriespy-portable-scientific-result",
    source_package_version=paste0("R-native-eyetrajectories-",
      as.character(getNamespaceVersion("eyetrajectories"))),
    result_type=payload$python_type,
    portable_scope=paste(
      "Scientific arrays, identifiers, specifications, units, diagnostics",
      "and provenance. Backend-native/opaque objects are not promised",
      "portable or reconstructible."),
    arrays_file="arrays.npz",
    arrays_sha256=digest::digest(archive,algo="sha256",file=TRUE,
      serialize=FALSE),
    units=units,
    nonportable_fields=list(),environment=NULL,payload=payload)
  json <- encode_manifest(manifest)
  writeLines(as.character(json),file.path(temp,"manifest.json"),
    useBytes=TRUE)
  if(!dir.exists(directory))
    dir.create(directory,recursive=TRUE,showWarnings=FALSE)
  .etr_assert(dir.exists(directory),"could not create portable destination")
  # Claim the empty destination before staging either file. Publish the
  # manifest last so readers only find it after the complete archive.
  stage <- file.path(directory,".etr-portable-write")
  .etr_assert(dir.create(stage,showWarnings=FALSE),
    "could not stage portable result in destination")
  on.exit(unlink(stage,recursive=TRUE),add=TRUE)
  .etr_assert(identical(list.files(directory,all.files=TRUE,no..=TRUE),
    basename(stage)),"portable destination directory is not empty")
  files <- c("arrays.npz","manifest.json")
  .etr_assert(all(file.copy(file.path(temp,files),stage,overwrite=FALSE)),
    "could not stage portable archive and manifest")
  target <- file.path(directory,files)
  .etr_assert(!any(file.exists(target)) &&
    file.rename(file.path(stage,files[[1L]]),target[[1L]]),
    "could not write portable archive")
  if(file.exists(target[[2L]]) ||
      !file.rename(file.path(stage,files[[2L]]),target[[2L]])){
    unlink(target[[1L]])
    stop("could not write portable manifest",call.=FALSE)
  }
  invisible(normalizePath(directory,winslash="/",mustWork=TRUE))
}
