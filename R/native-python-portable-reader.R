# Stage 6: Python 1.2 portable scientific-result READER, implemented in R.
# The published Python source of record is portable_results.py.
# This file NEVER imports Python or calls reticulate.
#
# Explicit subset: manifest v1, NumPy .npy v1/v2/v3, little endian
# f4/f8, signed i1/i2/i4/i8, unsigned u1/u2/u4/u8 (safe integers),
# bool b1, UTF-32 Unicode U, and primitive JSON-only object arrays.
# Pickled objects and unsupported descriptors FAIL CLOSED. This is NOT a Python portable-result writer.

.etr_portable_require <- function(package) {
  if (!requireNamespace(package,quietly=TRUE))
    stop("Install optional native-R interoperability dependency: ",
         package,call.=FALSE)
}

.etr_portable_single <- function(x,label) {
  .etr_assert(is.character(x) && length(x)==1L &&
                !is.na(x) && nzchar(x),
              paste(label,"must be one nonempty string"))
  x
}

.etr_npy_header <- function(con) {
  magic <- readBin(con,what="raw",n=6L)
  .etr_assert(identical(magic,as.raw(c(147,78,85,77,80,89))),
              "invalid NumPy .npy magic bytes")
  ver <- readBin(con,what="integer",n=2L,size=1L,signed=FALSE)
  .etr_assert(length(ver)==2L && ver[1L] %in% c(1L,2L,3L),
              "unsupported NumPy .npy header version")
  nheader <- readBin(con,what="integer",n=1L,
    size=if(ver[1L]==1L)2L else 4L,endian="little",signed=FALSE)
  .etr_assert(length(nheader)==1L && !is.na(nheader) &&
                nheader > 0L && nheader <= 1048576L,
              "invalid NumPy .npy header length")
  bytes <- readBin(con,what="raw",n=nheader)
  .etr_assert(length(bytes)==nheader,"truncated NumPy .npy header")
  header <- rawToChar(bytes)
  field <- function(rx,description) {
    m <- regmatches(header,regexec(rx,header,perl=TRUE))[[1L]]
    .etr_assert(length(m)>=2L,
      paste("invalid NumPy .npy header field:",description))
    m[2L]
  }
  descr <- field("['\"]descr['\"]\\s*:\\s*['\"]([^'\"]+)['\"]","descr")
  flag <- field("['\"]fortran_order['\"]\\s*:\\s*(True|False)","fortran_order")
  tuple <- field("['\"]shape['\"]\\s*:\\s*\\(([^)]*)\\)","shape")
  parts <- trimws(strsplit(tuple,",",fixed=TRUE)[[1L]])
  parts <- parts[nzchar(parts)]
  shape <- if(length(parts)) {
    .etr_assert(all(grepl("^[0-9]+$",parts)),
                "invalid NumPy .npy array shape")
    as.numeric(parts)
  } else numeric(0)
  .etr_assert(all(is.finite(shape)) && all(shape>=0) &&
                length(shape)<=6L,
              "unsupported NumPy .npy array dimensions")
  list(descr=descr,fortran=identical(flag,"True"),shape=shape)
}

.etr_npy_decode_u64 <- function(blob,signed=TRUE) {
  .etr_assert(length(blob)%%8L==0L,"truncated NumPy int64 values")
  n <- length(blob)%/%8L
  if(n==0L)return(numeric(0))
  # Avoid R's unsupported unsigned 64-bit integer type; reject any value
  # that cannot be represented EXACTLY as an IEEE-754 double.
  bytes <- matrix(as.double(as.integer(blob)),nrow=8L,ncol=n)
  powers <- 256^(0:3)
  low <- as.numeric(crossprod(powers,bytes[1:4,,drop=FALSE]))
  high <- as.numeric(crossprod(powers,bytes[5:8,,drop=FALSE]))
  if(signed) high <- ifelse(high>=2^31,high-2^32,high)
  value <- low+high*2^32
  .etr_assert(all(is.finite(value)) && all(abs(value)<=2^53),
              "NumPy int64 exceeds exact base-R double integer range")
  value
}

.etr_npy_decode_utf32 <- function(blob,n,width) {
  .etr_assert(length(blob)==n*width*4,
              "truncated NumPy Unicode payload")
  if(n==0L)return(character(0))
  con <- rawConnection(blob,open="rb")
  on.exit(close(con),add=TRUE)
  # UTF-32 scalar values fit signed 32-bit integers (<= 0x10FFFF).
  # signed=FALSE is unsupported for R 4-byte integer readBin on Windows.
  ints <- readBin(con,what="integer",n=n*width,size=4L,
                  signed=TRUE,endian="little")
  .etr_assert(length(ints)==n*width && all(!is.na(ints)),
              "invalid NumPy UTF-32 code points")
  matrix_code <- matrix(ints,nrow=width,ncol=n)
  vapply(seq_len(n),function(i) {
    cps <- matrix_code[,i]
    cps <- cps[cps!=0L]
    .etr_assert(all(cps>0L & cps<=1114111L &
              !(cps>=55296L & cps<=57343L)),
              "invalid Unicode code point in NumPy array")
    intToUtf8(cps)
  },character(1))
}

.etr_npy_read <- function(zipfile,entry,max_array_bytes) {
  con <- unz(zipfile,entry,open="rb")
  on.exit(close(con),add=TRUE)
  hdr <- .etr_npy_header(con)
  descriptor <- hdr$descr
  .etr_assert(grepl("^[<|]",descriptor),
    "Only native little-endian or byte-independent NumPy arrays are supported")
  dtype <- sub("^[<|]","",descriptor)
  typ <- substr(dtype,1L,1L)
  width <- suppressWarnings(as.integer(substring(dtype,2L)))
  .etr_assert(!is.na(width) && width>0L,
              paste("unsupported NumPy dtype:",descriptor))
  if(typ=="U") {
    .etr_assert(startsWith(descriptor,"<"),"Unicode arrays must be little-endian")
    itemsize <- width*4
  } else {
    .etr_assert(
      (typ=="f" && width %in% c(4L,8L) && startsWith(descriptor,"<")) ||
      (typ=="i" && width %in% c(1L,2L,4L,8L)) ||
      (typ=="u" && width %in% c(1L,2L,4L,8L)) ||
      (typ=="b" && width==1L),
      paste("unsupported NumPy dtype:",descriptor))
    itemsize <- width
  }
  n <- if(!length(hdr$shape))1 else prod(hdr$shape)
  bytes_needed <- n*itemsize
  .etr_assert(is.finite(bytes_needed) && bytes_needed<=max_array_bytes,
              "NumPy array exceeds declared native R safety limit")
  bytes <- readBin(con,what="raw",n=as.integer(bytes_needed))
  .etr_assert(length(bytes)==bytes_needed,
              "truncated NumPy .npy array payload")
  values <- if(typ=="U"){
    .etr_npy_decode_utf32(bytes,as.integer(n),width)
  } else if(typ=="b"){
    .etr_assert(all(as.integer(bytes) %in% c(0L,1L)),
                "NumPy boolean array has invalid bit values")
    as.logical(as.integer(bytes))
  } else if((typ=="u"||typ=="i") && width==8L) {
    .etr_npy_decode_u64(bytes,signed=typ=="i")
  } else if(typ %in% c("u","i") && width==4L) {
    # R's 32-bit INT_MIN is reserved for NA_integer_, so decode both
    # signed/unsigned int32 to exact doubles from bytes instead of
    # silently mapping the valid NumPy value -2147483648 to missing.
    bb <- matrix(as.numeric(as.integer(bytes)),nrow=4L)
    value <- as.numeric(crossprod(256^(0:3),bb))
    if(typ=="i") ifelse(value>=2^31,value-2^32,value) else value
  } else {
    rc <- rawConnection(bytes,open="rb")
    on.exit(close(rc),add=TRUE)
    if(typ=="f") {
      readBin(rc,what="numeric",n=as.integer(n),size=width,
              endian="little")
    } else {
      readBin(rc,what="integer",n=as.integer(n),size=width,
              signed=typ=="i",endian="little")
    }
  }
  .etr_assert(length(values)==n,"NumPy array decoded length mismatch")
  shape <- hdr$shape
  if(length(shape)==0L)return(values[[1L]])
  .etr_assert(prod(shape)<= .Machine$integer.max,
              "NumPy shape is too large for a native R array")
  # Python C contiguous payload has last axis fastest. R column-major
  # order has first axis fastest, so reverse reshape then aperm.
  shape <- as.integer(shape)
  if(length(shape)==1L) return(array(values,dim=shape))
  if(hdr$fortran) return(array(values,dim=shape))
  a <- array(values,dim=rev(shape))
  aperm(a,rev(seq_along(shape)))
}

.etr_portable_decode <- function(value,arrays=list(),depth=0L) {
  .etr_assert(depth<=64L,
              "portable payload nesting exceeds native R safety limit")
  if(is.null(value)||is.atomic(value))return(value)
  .etr_assert(is.list(value),"invalid portable payload type")
  keys <- names(value)
  if(is.null(keys))return(lapply(value,.etr_portable_decode,
                                arrays=arrays,depth=depth+1L))
  if(is.null(value$'__portable_type__')) {
    return(lapply(value,.etr_portable_decode,arrays=arrays,depth=depth+1L))
  }
  marker <- .etr_portable_single(value$'__portable_type__',"portable marker")
  if(marker=="ndarray") {
    key <- .etr_portable_single(value$key,"NumPy archive key")
    .etr_assert(key %in% names(arrays),
                "portable manifest references missing NumPy array key")
    out <- arrays[[key]]
    .etr_assert(identical(as.integer(dim(out)),
                          as.integer(unlist(value$shape))),
                paste("manifest shape differs from NumPy header:",key))
    # Avoid silently converting dimensions or field types to different
    # scientific semantics. The .npy header is authoritative for values.
    return(out)
  }
  if(marker=="tuple")return(structure(
    lapply(value$items,.etr_portable_decode,arrays=arrays,depth=depth+1L),
    class="etr_python_tuple"))
  if(marker=="mapping") {
    out <- list()
    for(pair in value$entries) {
      .etr_assert(is.list(pair) && length(pair)==2L,
                  "invalid portable mapping entry")
      key <- .etr_portable_decode(pair[[1L]],arrays,depth+1L)
      .etr_assert(is.character(key) && length(key)==1L &&
                    nzchar(key) && !key %in% names(out),
                    "portable mapping requires unique string keys in R")
      out[key] <- list(.etr_portable_decode(pair[[2L]],arrays,depth+1L))
    }
    return(out)
  }
  if(marker=="dataclass") {
    .etr_assert(is.list(value$fields) && !is.null(names(value$fields)),
                "portable dataclass fields must be a mapping")
    result <- lapply(value$fields,.etr_portable_decode,
                     arrays=arrays,depth=depth+1L)
    return(c(list('__python_type__'=value$python_type),result))
  }
  if(marker=="nonportable")return(list(
    '__nonportable__'=TRUE,
    python_type=value$python_type,
    representation=value$representation))
  if(marker=="path")return(value$value)
  if(marker=="object_array") {
    # Python's writer stores dtype=object arrays as JSON items, never as
    # pickled NPZ content. Decode only homogeneous JSON scalar arrays,
    # not arbitrary backend Python objects, and retain C-order shape.
    shape <- as.numeric(unlist(value$shape))
    .etr_assert(all(is.finite(shape)) && all(shape>=0) &&
       length(shape)<=6L && prod(shape)<=1048576,
       "unsupported or excessive portable JSON object-array shape")
    items <- .etr_portable_decode(value$items,arrays,depth+1L)
    flatten <- function(x,level=0L){
      .etr_assert(level<=16L,"object array nesting exceeds limit")
      if(is.list(x) && is.null(names(x)))
        return(unlist(lapply(x,flatten,level=level+1L),
                      recursive=FALSE))
      list(x)
    }
    entries <- flatten(items)
    .etr_assert(length(entries)==prod(shape),
                "portable object-array shape/item count mismatch")
    scalar_type <- function(z,t) {
      is.atomic(z) && length(z)==1L && !is.na(z) &&
        switch(t,string=is.character(z),
               numeric=is.numeric(z) && is.finite(z),
               logical=is.logical(z))
    }
    present <- !vapply(entries,is.null,logical(1L))
    nonmissing <- entries[present]
    if(length(entries) && !length(nonmissing))
      out <- rep(NA,length(entries))
    else if(all(vapply(nonmissing,scalar_type,logical(1L),t="string")))
      out <- rep(NA_character_,length(entries))
    else if(all(vapply(nonmissing,scalar_type,logical(1L),t="numeric")))
      out <- rep(NA_real_,length(entries))
    else if(all(vapply(nonmissing,scalar_type,logical(1L),t="logical")))
      out <- rep(NA,length(entries))
    else stop("heterogeneous or nonscalar portable JSON object array ",
              "requires a higher-level type policy; rejected",call.=FALSE)
    out[present] <- unlist(nonmissing,use.names=FALSE)
    if(!length(shape)) return(out[[1L]])
    if(length(shape)==1L)return(array(out,dim=as.integer(shape)))
    return(aperm(array(out,dim=rev(as.integer(shape))),
                 rev(seq_along(shape))))
  }
  if(marker %in% c("dataframe","series")) {
    cols <- if(marker=="dataframe")
      .etr_portable_decode(value$columns,arrays,depth+1L) else
      list(.etr_portable_decode(value$name,arrays,depth+1L))
    index <- .etr_portable_decode(value$index,arrays,depth+1L)
    contents <- if(marker=="dataframe") value$data else list(value$data)
    .etr_assert(is.list(cols) && length(cols)==length(contents),
                "portable DataFrame column count mismatch")
    v <- lapply(contents,function(field) {
      arr <- .etr_portable_decode(field,arrays,depth+1L)
      .etr_assert(is.atomic(arr) && length(dim(arr))<=1L,
                  "portable table columns must be one-dimensional arrays")
      as.vector(arr)
    })
    .etr_assert(all(vapply(v,length,integer(1L))==length(index)),
                "portable DataFrame index/column length mismatch")
    colnames <- vapply(cols,as.character,character(1L))
    .etr_assert(!anyDuplicated(colnames) && all(nzchar(colnames)),
                "portable DataFrame columns require unique nonempty labels")
    names(v) <- colnames
    df <- if(length(v)) as.data.frame(v,optional=TRUE,stringsAsFactors=FALSE,
                                    check.names=FALSE) else
      data.frame(row.names=seq_along(index))
    attr(df,"python_index") <- index
    if(marker=="series")return(df[[1L]])
    return(df)
  }
  stop("unsupported Python portable marker: ",marker,call.=FALSE)
}

#' Verify and read a Python 1.2 portable scientific result without Python
#'
#' Reads the exact published Python v1 JSON+NPZ container, verifies SHA-256
#' over arrays.npz before decoding, and restricts NPY types to a documented
#' safe native subset. Does not run Python or unpickle object arrays.
#'
#' @param directory Existing Python portable-result bundle directory.
#' @param max_array_bytes Maximum uncompressed size per array (default 64 MiB).
#' @param max_total_bytes Maximum advertised uncompressed total (128 MiB).
#' @return An etr_python_portable_snapshot list including the original
#'   manifest, decoded payload, source package version, units, environment,
#'   explicitly nonportable fields and checked archive digest.
#' @export
etr_read_python_portable_result <- function(
    directory,max_array_bytes=64*1024^2,max_total_bytes=128*1024^2) {
  .etr_portable_require("jsonlite")
  .etr_portable_require("digest")
  .etr_assert(is.character(directory) && length(directory)==1L &&
              !is.na(directory) && dir.exists(directory),
              "directory must be an existing Python portable-result folder")
  max_limits <- c(max_array_bytes,max_total_bytes)
  .etr_assert(is.numeric(max_limits) && all(is.finite(max_limits)) &&
              all(max_limits>=1024) && all(max_limits<=1024^3),
              "max_array_bytes/max_total_bytes must be finite safe byte limits")
  manifest_path <- file.path(directory,"manifest.json")
  .etr_assert(file.exists(manifest_path),
              "Python portable-result manifest.json not found")
  manifest <- jsonlite::fromJSON(manifest_path,simplifyVector=FALSE)
  .etr_assert(is.list(manifest) &&
    identical(manifest$format,"eyetrajectoriespy-portable-scientific-result") &&
    identical(manifest$schema_version,1L),
    "unsupported Python portable-result format or schema version")
  .etr_assert(identical(manifest$arrays_file,"arrays.npz"),
              "unexpected array archive path (requires arrays.npz)")
  expected <- .etr_portable_single(manifest$arrays_sha256,"arrays_sha256")
  .etr_assert(grepl("^[0-9a-f]{64}$",expected),
              "invalid SHA-256 manifest digest")
  archive <- file.path(directory,"arrays.npz")
  .etr_assert(file.exists(archive),"Python portable-result arrays.npz not found")
  observed <- digest::digest(archive,algo="sha256",file=TRUE,
                            serialize=FALSE)
  .etr_assert(identical(tolower(observed),tolower(expected)),
              "Python portable-result arrays.npz SHA-256 checksum mismatch")
  listing <- utils::unzip(archive,list=TRUE)
  .etr_assert(is.data.frame(listing) && nrow(listing)>0L,
              "empty Python NPZ archive")
  names_in_zip <- listing$Name
  .etr_assert(!anyDuplicated(names_in_zip) &&
    all(grepl("^array_[0-9]{5}[.]npy$",names_in_zip)) &&
    all(is.finite(listing$Length)) &&
    all(listing$Length>=0) &&
    sum(as.double(listing$Length))<=max_total_bytes,
    "NPZ archive has unsafe filenames, duplicate entries or excessive size")
  arrays <- list()
  for(entry in names_in_zip) {
    key <- sub("[.]npy$","",entry)
    arrays[[key]] <- .etr_npy_read(archive,entry,max_array_bytes)
  }
  payload <- .etr_portable_decode(manifest$payload,arrays)
  structure(list(
    result_type=manifest$result_type,
    source_package_version=manifest$source_package_version,
    payload=payload,
    units=manifest$units,
    nonportable_fields=manifest$nonportable_fields,
    environment=manifest$environment,
    arrays_sha256=observed,
    manifest=manifest,
    archive_keys=names(arrays)
  ),class="etr_python_portable_snapshot")
}
