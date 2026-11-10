# Native R workflow export and a bounded Python 1.2 portable format.

.etr_native_bundle_name<-function(x,kind){
  .etr_assert(is.character(x)&&length(x)==1L&&!is.na(x)&&
    grepl("^[A-Za-z0-9][A-Za-z0-9_.-]*$",x)&&
    !grepl("\\.\\.",x),
    paste0(kind," must be a safe simple filename"))
  x
}

.etr_native_bundle_json<-function(x,path){
  .etr_workflow_json(x,path,validate_only=TRUE)
  paste0(as.character(jsonlite::toJSON(x,auto_unbox=TRUE,
    null="null",na="null",digits=NA,pretty=TRUE)),"\n")
}

.etr_native_bundle_write_text<-function(value,path){
  writeLines(enc2utf8(value),path,useBytes=TRUE)
  invisible(path)
}

.etr_native_bundle_occupied<-function(directory){
  link<-Sys.readlink(directory)
  file.exists(directory)||dir.exists(directory)||(!is.na(link)&&nzchar(link))
}

.etr_native_bundle_stage<-function(directory){
  target<-normalizePath(dirname(directory),winslash="/",mustWork=FALSE)
  if(!dir.exists(target))dir.create(target,recursive=TRUE,showWarnings=FALSE)
  .etr_assert(dir.exists(target),"cannot create workflow bundle parent")
  temp<-tempfile("etr_native_workflow_",tmpdir=target)
  .etr_assert(dir.create(temp),"could not allocate temporary bundle")
  temp
}

.etr_native_bundle_publish<-function(temp,directory,portable=FALSE){
  files<-list.files(temp,recursive=TRUE,all.files=TRUE,include.dirs=FALSE)
  files<-sort(gsub("\\\\","/",files),method=if(portable)"radix" else "auto")
  .etr_assert(!("SHA256SUMS"%in%files),"SHA256SUMS must not exist before manifest hashing")
  sums<-vapply(files,function(rel)
    digest::digest(file.path(temp,rel),algo="sha256",file=TRUE),character(1L))
  lines<-paste(sums,files,sep="  ")
  .etr_native_bundle_write_text(if(portable)lines else c(lines,""),
    file.path(temp,"SHA256SUMS"))
  .etr_assert(!.etr_native_bundle_occupied(directory),
    "bundle destination became occupied during export")
  .etr_assert(file.rename(temp,directory),"native workflow bundle atomic publication failed")
  invisible(normalizePath(directory,winslash="/",mustWork=TRUE))
}

.etr_native_bundle_validate_artifacts<-function(result){
  for(collection in list(result$reports,result$tables))
    if(length(collection))
      .etr_assert(!is.null(names(collection))&&
        !anyDuplicated(names(collection))&&
        all(vapply(names(collection),function(nm){
          tryCatch({.etr_native_bundle_name(nm,"entry");TRUE},
            error=function(e)FALSE)
        },logical(1L))),
        "workflow report/table names must be unique simple filenames")
  .etr_assert(all(vapply(result$reports,function(x)
    is.character(x)&&length(x)==1L&&!is.na(x),logical(1L))),
    "workflow reports must be complete scalar text")
  .etr_assert(all(vapply(result$tables,is.data.frame,logical(1L))),
    "workflow tables must be data frames")
}

.etr_native_bundle_write_artifacts<-function(result,temp,portable=FALSE){
  filenames<-function(names,suffix,kind){
    paths<-ifelse(grepl("\\.[^.]+$",names),names,paste0(names,suffix))
    for(path in paths).etr_native_bundle_name(path,paste(kind,"filename"))
    .etr_assert(!anyDuplicated(if(portable)tolower(paths) else paths),
      if(kind=="table")"table filename must be a unique CSV" else
        "report filename collision after extension normalization")
    if(portable)
      .etr_assert(!any(grepl("^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(\\.|$)",
        paths,ignore.case=TRUE)),"portable artifact uses a reserved filename")
    paths
  }
  report_names<-character()
  if(length(result$reports)){
    report_names<-filenames(names(result$reports),".txt","report")
    dir.create(file.path(temp,"reports"))
    for(i in seq_along(report_names)){
      value<-result$reports[[i]]
      value<-if(portable) sub("(*UCP)[\\s\\x{001C}-\\x{001F}]+$","",enc2utf8(value),perl=TRUE) else
        paste0(sub("\\s+$","",value),"\n")
      .etr_native_bundle_write_text(value,file.path(temp,"reports",report_names[[i]]))
    }
  }
  table_names<-character()
  if(length(result$tables)){
    table_names<-filenames(names(result$tables),".csv","table")
    .etr_assert(all(grepl("\\.csv$",table_names,ignore.case=TRUE)),
      "table filename must be a unique CSV")
    dir.create(file.path(temp,"tables"))
    for(i in seq_along(table_names)){
      path<-file.path(temp,"tables",table_names[[i]])
      if(portable) .etr_write_python_workflow_csv(result$tables[[i]],path)
      else utils::write.csv(result$tables[[i]],path,row.names=FALSE,na="")
    }
  }
  sorting<-if(portable)"radix" else "auto"
  list(reports=sort(report_names,method=sorting),tables=sort(table_names,method=sorting))
}

#' Export a source-auditable native R scientific workflow bundle
#'
#' @description Writes config, steps, decisions, provenance, reports, tables,
#'   and SHA-256 checksums without modifying input results.
#'   The default uses an RDS snapshot. The Python 1.2 format supports native
#'   dense FPCA workflows with measured elapsed times and writes JSON/NPZ.
#' @param result Explicit native R workflow with scientific fit and provenance.
#' @param directory Non-existing output directory; atomic best-effort rename.
#' @param overwrite Must be FALSE; never delete prior scientific evidence.
#' @param format Use `"native_r"` for the RDS bundle or `"python_1_2"` for the
#'   portable FPCA workflow bundle.
#' @return Normalized directory path invisibly.
#' @export
etr_export_workflow_bundle<-function(result,directory,overwrite=FALSE,
    format=c("native_r","python_1_2")){
  format<-match.arg(format)
  .etr_assert(identical(overwrite,FALSE),
    "overwrite must be FALSE: native workflow evidence is immutable")
  .etr_assert(is.character(directory)&&length(directory)==1L&&
    !is.na(directory)&&nzchar(trimws(directory)),
    "directory must be a nonempty output path")
  .etr_assert(!.etr_native_bundle_occupied(directory),
    "workflow bundle destination already exists")
  .etr_assert(requireNamespace("jsonlite",quietly=TRUE)&&
    requireNamespace("digest",quietly=TRUE),
    "jsonlite and digest must be installed for native bundle export")
  .etr_assert(is.list(result)&&
    all(c("workflow_schema_version","workflow_contract",
      "config","steps","decisions","provenance","reports","tables")%in%
      names(result))&&
    is.list(result$config)&&is.list(result$steps)&&
    is.list(result$decisions)&&is.list(result$provenance)&&
    is.list(result$reports)&&is.list(result$tables),
    "result must be a structured native scientific workflow with reports and tables")
  .etr_assert(identical(result$workflow_schema_version,1L)&&
    is.character(result$workflow_contract)&&
    length(result$workflow_contract)==1L&&
    !is.na(result$workflow_contract)&&nzchar(result$workflow_contract),
    "workflow schema version and contract are malformed")
  if(format=="python_1_2")
    return(.etr_export_python_fpca_workflow_bundle(result,directory))
  .etr_workflow_json(result$config,"config",validate_only=TRUE)
  .etr_workflow_json(result$provenance,"provenance",validate_only=TRUE)
  .etr_assert(length(result$steps)>0L&&
    all(vapply(result$steps,function(step)
      is.list(step)&&is.character(step$name)&&length(step$name)==1L&&
      !is.na(step$name)&&nzchar(step$name)&&
      is.character(step[["function"]])&&
      length(step[["function"]])==1L&&
      !is.na(step[["function"]])&&nzchar(step[["function"]])&&
      is.character(step$status)&&length(step$status)==1L&&
      !is.na(step$status)&&nzchar(step$status)&&
      is.list(step$parameters),logical(1L))),
    "workflow step records must include explicit names functions statuses and parameters")
  .etr_assert(!is.null(names(result$decisions))&&
    !anyDuplicated(names(result$decisions))&&
    all(nzchar(names(result$decisions)))&&
    all(vapply(result$decisions,function(v)
      is.list(v)&&is.character(v$source)&&length(v$source)==1L&&
      !is.na(v$source)&&nzchar(v$source),logical(1L))),
    "decisions must contain named scientific source records")
  for(d in result$decisions)
    .etr_workflow_json(d$value,"decision.value",validate_only=TRUE)
  .etr_native_bundle_validate_artifacts(result)
  temp<-.etr_native_bundle_stage(directory)
  on.exit(unlink(temp,recursive=TRUE),add=TRUE)
  dir.create(file.path(temp,"result"))
  .etr_native_bundle_write_text(
    .etr_native_bundle_json(result$config,"config"),
    file.path(temp,"config.json"))
  .etr_native_bundle_write_text(
    .etr_native_bundle_json(result$provenance,"provenance"),
    file.path(temp,"provenance.json"))
  .etr_native_bundle_write_text(
    .etr_native_bundle_json(list(
      runtime="R",python_environment_impersonated=FALSE,
      portable_python_result=FALSE),"environment"),
    file.path(temp,"environment.json"))
  steps<-do.call(rbind,lapply(seq_along(result$steps),function(i){
    v<-result$steps[[i]]
    data.frame(order=as.integer(i),name=v$name,
      function_name=v[["function"]],status=v$status,
      parameters_json=.etr_workflow_json(v$parameters,
        "step.parameters",empty_mapping=TRUE),
      duration_seconds=if(is.numeric(v$duration_seconds)&&
        length(v$duration_seconds)==1L) v$duration_seconds else NA_real_,
      duration_measured=isTRUE(v$duration_measured),
      stringsAsFactors=FALSE)
  }))
  names(steps)[3L]<-"function"
  utils::write.csv(steps,file.path(temp,"steps.csv"),
    row.names=FALSE,na="")
  decisions<-do.call(rbind,lapply(names(result$decisions),function(nm){
    v<-result$decisions[[nm]]
    data.frame(name=nm,value_json=.etr_workflow_json(v$value,
      "decision.value"),source=v$source,
      criterion=if(is.null(v$criterion))NA_character_ else as.character(v$criterion),
      stringsAsFactors=FALSE)
  }))
  utils::write.csv(decisions,file.path(temp,"decisions.csv"),
    row.names=FALSE,na="")
  saveRDS(result,file.path(temp,"result","result.rds"),version=3L)
  artifacts<-.etr_native_bundle_write_artifacts(result,temp)
  manifest<-list(
    schema_version=1L,format="etr_native_r_workflow_bundle_v1",
    workflow_schema_version=result$workflow_schema_version,
    workflow_contract=result$workflow_contract,
    result_type=class(result)[1L],portable_result_directory="result",
    result_encoding="RDS_not_Python_NPZ",
    reports=artifacts$reports,tables=artifacts$tables,
    figure_export_included=FALSE,
    figure_export_status="separate_explicit_native_R_graphics_export",
    full_published_source_contract_certified=FALSE)
  .etr_native_bundle_write_text(
    .etr_native_bundle_json(manifest,"workflow"),
    file.path(temp,"workflow.json"))
  .etr_native_bundle_publish(temp,directory)
}
