# Actual native functional simulator and frozen Python 1.2 plotting.py,
# c1cd95ad718327550f7e55393ff38582872f7a94.
# Geometry parity only: a base-R device is not a Matplotlib Axes.

.etr_sim_artist_real_fixture<-function(){
  etr_simulate_functional_process(
    mean=function(t)0*t,
    eigenfunctions=list(function(t)sqrt(2)*sin(pi*t)),
    eigenvalues=1,
    truth_grid=seq(0,1,length.out=41L),
    n_participants=3L,
    trials_per_participant=2L,
    dimension_names="value",
    coordinate_system="unknown",
    time_unit="s",
    participant_eigenvalues=.2,
    trial_eigenvalues=.1,
    measurement_noise_sd=.04,
    random_state=821L)
}
.etr_sim_artist_pdf<-function(expr){
  path<-tempfile(fileext=".pdf")
  grDevices::pdf(path)
  on.exit({
    if(grDevices::dev.cur()>1L)grDevices::dev.off()
    unlink(path)
  },add=TRUE)
  force(expr)
}

test_that("strict simulation audit artists use real native truth and zero-based source curve index",{
  result<-.etr_sim_artist_real_fixture()
  expect_s3_class(result,"etr_functional_simulation_result")
  .etr_sim_artist_pdf({
    c<-etr_plot_functional_simulation_curve(
      result,curve=0L,dimension=0L,strict_source_record=TRUE)
    expect_s3_class(c,"etr_functional_simulation_artist_source_record")
    expect_identical(c$source_export,"plot_functional_simulation_curve")
    expect_identical(c$python_return_kind,"matplotlib.axes.Axes")
    expect_identical(c$source_options$curve,0L)
    expect_identical(c$source_options$dimension,0L)
    expect_false(c$matplotlib_object_identity)
    expect_false(c$independently_certified)
    a<-c$axes[[1L]]
    expect_identical(a$title,paste0(
      "Functional simulation truth audit: ",
      result$observations$curve_ids[[1L]]))
    expect_identical(a$ylabel,"value")
    expect_identical(a$xlabel,"Time (s)")
    expect_identical(a$lines[[1L]]$label,"latent truth")
    expect_equal(a$lines[[1L]]$xdata,result$truth$truth_grid)
    expect_equal(a$lines[[1L]]$ydata,
      result$truth$latent_on_truth_grid[1L,,1L])
    expect_identical(a$collections[[1L]]$label,"observed")
    expect_equal(a$collections[[1L]]$offsets,
      cbind(result$truth$observation_times[[1L]],
        result$observations$values[1L,,1L]),
      tolerance=1e-12,ignore_attr=TRUE)
    # Source Python indexes 0 from its public API, whereas legacy R
    # continues to use its documented one-based numeric indices.
    legacy<-etr_plot_functional_simulation_curve(
      result,curve=1L,dimension=1L)
    expect_equal(legacy$latent$value,a$lines[[1L]]$ydata)
    expect_identical(legacy$curve_id,result$observations$curve_ids[[1L]])
    phase<-etr_plot_functional_simulation_phase_warps(result,
      max_curves=4L,alpha=.4,strict_source_record=TRUE)
    expect_identical(phase$source_export,
      "plot_functional_simulation_phase_warps")
    expect_identical(phase$axes[[1L]]$title,
      "Retained phase warps (n=4)")
    expect_length(phase$axes[[1L]]$lines,5L)
    expect_identical(phase$axes[[1L]]$lines[[1L]]$label,"identity warp")
    expect_identical(phase$axes[[1L]]$lines[[1L]]$linestyle,"--")
    expect_equal(phase$axes[[1L]]$lines[[1L]]$ydata,
      result$truth$truth_grid)
    for(i in seq_len(4L)){
      expect_equal(phase$axes[[1L]]$lines[[i+1L]]$ydata,
        result$truth$phase_warps_on_truth_grid[i,])
      expect_equal(phase$axes[[1L]]$lines[[i+1L]]$alpha,.4)
    }
    var<-etr_plot_functional_simulation_score_variances(
      result,strict_source_record=TRUE)
    expect_identical(var$source_export,
      "plot_functional_simulation_score_variances")
    expect_identical(var$axes[[1L]]$variance_ddof,0L)
    expect_length(var$axes[[1L]]$patches,6L)
    expect_identical(var$axes[[1L]]$xticklabels,"component 1")
    native<-etr_plot_functional_simulation_score_variances(result)
    expect_equal(vapply(var$axes[[1L]]$patches,
      function(p)p$center,numeric(1L)),native$geometry$center)
    expect_equal(vapply(var$axes[[1L]]$patches,
      function(p)p$height,numeric(1L)),native$geometry$variance)
    expect_equal(native$realized[,1L],
      colMeans(sweep(result$truth$curve_scores,2L,
        colMeans(result$truth$curve_scores),"-")^2))
  })
})

test_that("source simulation plotting rejects incorrect indices and non-native source result",{
  result<-.etr_sim_artist_real_fixture()
  .etr_sim_artist_pdf({
    expect_error(etr_plot_functional_simulation_curve(result,
      curve=-1L,dimension=0L,strict_source_record=TRUE),
      "zero-based")
    expect_error(etr_plot_functional_simulation_curve(result,
      curve=6L,dimension=0L,strict_source_record=TRUE),
      "zero-based")
    expect_error(etr_plot_functional_simulation_curve(result,
      curve=0L,dimension=1L,strict_source_record=TRUE),
      "zero-based")
    expect_error(etr_plot_functional_simulation_curve(result,
      strict_source_record=NA),"strict_source_record")
    expect_error(etr_plot_functional_simulation_phase_warps(result,
      max_curves=0L,strict_source_record=TRUE),"max_curves")
    expect_error(etr_plot_functional_simulation_phase_warps(result,
      alpha=0,strict_source_record=TRUE),"alpha")
    expect_error(etr_plot_functional_simulation_score_variances(
      unclass(result),strict_source_record=TRUE),
      "genuine native functional simulation")
    expect_error(etr_plot_functional_simulation_curve(result,
      strict_source_record=1L),"strict_source_record")
  })
})

test_that("frozen Python 1.2 source artists match real native functional simulation values",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("direct Matplotlib 1.2 geometry oracle requires explicit opt-in")
  expect_identical(et_python_version(),"1.2.0")
  result<-.etr_sim_artist_real_fixture()
  .etr_sim_artist_pdf({
    c<-etr_plot_functional_simulation_curve(result,curve=0L,
      dimension=0L,strict_source_record=TRUE)
    p<-etr_plot_functional_simulation_phase_warps(result,
      max_curves=4L,alpha=.4,strict_source_record=TRUE)
    v<-etr_plot_functional_simulation_score_variances(result,
      strict_source_record=TRUE)
    reticulate::py_run_string("
import numpy as np
import matplotlib
matplotlib.use('Agg',force=True)
import matplotlib.pyplot as plt
import eyetrajectoriespy as et
def _et_sim_source_artists(grid,latent,observations,ids,
   observation_times,phase_warps,curve_scores,participant_scores,
   trial_scores,eigenvalues,participant_eigenvalues,trial_eigenvalues):
    truth=object.__new__(et.FunctionalSimulationTruth)
    vals={
      'truth_grid':np.asarray(grid,dtype=float),
      'latent_on_truth_grid':np.asarray(latent,dtype=float),
      'observation_times':tuple(np.asarray(t,dtype=float)
                                for t in observation_times),
      'phase_warps_on_truth_grid':np.asarray(phase_warps,dtype=float),
      'curve_scores':np.asarray(curve_scores,dtype=float),
      'participant_scores':np.asarray(participant_scores,dtype=float),
      'trial_scores':np.asarray(trial_scores,dtype=float),
      'eigenvalues':np.asarray(eigenvalues,dtype=float),
      'participant_eigenvalues':np.asarray(participant_eigenvalues,dtype=float),
      'trial_eigenvalues':np.asarray(trial_eigenvalues,dtype=float),
      'dimension_names':('value',),'time_unit':'s'}
    for name,value in vals.items():
      object.__setattr__(truth,name,value)
    obs=object.__new__(et.TrajectorySet)
    for name,value in {'curve_ids':tuple(ids),
       'values':np.asarray(observations,dtype=float)}.items():
      object.__setattr__(obs,name,value)
    sim=object.__new__(et.FunctionalSimulationResult)
    object.__setattr__(sim,'truth',truth)
    object.__setattr__(sim,'observations',obs)
    curve=et.plot_functional_simulation_curve(sim,curve=0,dimension=0)
    phase=et.plot_functional_simulation_phase_warps(
       sim,max_curves=4,alpha=.4)
    var=et.plot_functional_simulation_score_variances(sim)
    payload={
       'curve_title':curve.get_title(),
       'curve_line':np.asarray(curve.lines[0].get_ydata()),
       'curve_scatter':np.asarray(curve.collections[0].get_offsets().data),
       'phase_title':phase.get_title(),
       'phase_lines':[np.asarray(line.get_ydata()) for line in phase.lines],
       'phase_alpha':[line.get_alpha() for line in phase.lines],
       'score_patches':[(r.get_x()+r.get_width()/2,r.get_height(),
                          r.get_width()) for r in var.patches],
       'score_labels':[x.get_text() for x in var.get_xticklabels()],
       'score_legend':[x.get_text() for x in var.get_legend().get_texts()]}
    plt.close('all')
    return payload
")
    src<-reticulate::py_call(
      reticulate::py_eval("_et_sim_source_artists",convert=FALSE),
      grid=result$truth$truth_grid,
      latent=result$truth$latent_on_truth_grid,
      observations=result$observations$values,
      ids=as.list(result$observations$curve_ids),
      observation_times=result$truth$observation_times,
      phase_warps=result$truth$phase_warps_on_truth_grid,
      curve_scores=result$truth$curve_scores,
      participant_scores=result$truth$participant_scores,
      trial_scores=result$truth$trial_scores,
      eigenvalues=result$truth$eigenvalues,
      participant_eigenvalues=result$truth$participant_eigenvalues,
      trial_eigenvalues=result$truth$trial_eigenvalues)
    get<-function(n)et_to_r(reticulate::py_get_item(src,n))
    expect_identical(c$axes[[1L]]$title,get("curve_title"))
    expect_equal(c$axes[[1L]]$lines[[1L]]$ydata,
      get("curve_line"),tolerance=1e-10,ignore_attr=TRUE)
    expect_equal(c$axes[[1L]]$collections[[1L]]$offsets,
      get("curve_scatter"),tolerance=1e-10,ignore_attr=TRUE)
    expect_identical(p$axes[[1L]]$title,get("phase_title"))
    pyphase<-get("phase_lines")
    for(j in seq_along(pyphase))
      expect_equal(p$axes[[1L]]$lines[[j]]$ydata,
        pyphase[[j]],tolerance=1e-10,ignore_attr=TRUE)
    pybars<-get("score_patches")
    expect_length(pybars,length(v$axes[[1L]]$patches))
    for(j in seq_along(pybars)){
      expect_equal(v$axes[[1L]]$patches[[j]]$center,
        as.numeric(pybars[[j]][[1L]]),tolerance=1e-10)
      expect_equal(v$axes[[1L]]$patches[[j]]$height,
        as.numeric(pybars[[j]][[2L]]),tolerance=1e-10)
      expect_equal(v$axes[[1L]]$patches[[j]]$width,
        as.numeric(pybars[[j]][[3L]]),tolerance=1e-10)
    }
    expect_identical(v$axes[[1L]]$xticklabels,
      as.character(get("score_labels")))
    expect_identical(v$axes[[1L]]$legend_labels,
      as.character(get("score_legend")))
  })
})
