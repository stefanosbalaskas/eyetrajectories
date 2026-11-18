#!/usr/bin/env node
// Website-only smoke check: catalogue provenance and real native R PNGs.
"use strict";
const fs=require("node:fs"),path=require("node:path"),
assert=require("node:assert/strict"),vm=require("node:vm");
const root=process.argv[2]||"pkg/site";
const html=fs.readFileSync(path.join(root,"plot-atlas.html"),"utf8");
assert(html.includes('src="plot-atlas/catalog.js"'),"Catalog script not loaded");
assert(html.includes('id="search"')&&html.includes('id="family"')&&
  html.includes('id="backend"')&&html.includes('id="onlyPreview"'),"Missing filtering controls");
const inline=html.match(/<script>([\s\S]*?)<\/script>/)?.[1];
assert(inline,"Inline UI script missing");new vm.Script(inline,{filename:"plot-atlas-ui.js"});
assert(html.includes('src="plot-atlas-wave6.js"')&&
  html.includes('id="compareFunctions"')&&
  html.includes('id="rightFunction"')&&
  html.includes('id="rightVariant"')&&
  html.includes('id="downloadScript"')&&
  html.includes('id="parameterGuide"'),"Missing Wave 6 UI controls");
const wave6js=fs.readFileSync(path.join(root,"plot-atlas-wave6.js"),"utf8");
new vm.Script(wave6js,{filename:"plot-atlas-wave6.js"});
assert(wave6js.includes("ET_ATLAS_WAVE6")&&wave6js.includes("renderGuide"),
  "Wave 6 browser extension must bind actual R catalogue and source parameter guides");
assert(/id="onlyPreview"\s+type="checkbox" checked/.test(html),
  "Atlas must start with R-illustrated functions enabled");
assert(inline.includes('$("onlyPreview").checked=true'),
  "Browser must initialize in illustrated-only mode");
assert(inline.includes('matches.find(x=>x.name==="etr_plot_trajectories")'),
  "Atlas must select a real gaze plot at startup");
assert(inline.includes('Number(has(b))-Number(has(a))'),
  "Atlas must list illustrated functions first");
assert(html.includes("documentation-only entries")&&
       html.includes('id="coverageNote"'),
  "Atlas must explain preview limitations to readers");
const code=fs.readFileSync(path.join(root,"plot-atlas","catalog.js"),"utf8");
const sandbox={window:{}};vm.runInNewContext(code,sandbox,{timeout:10000});
const rows=sandbox.window.ET_PLOT_ATLAS_CATALOG;
assert(Array.isArray(rows),"Catalogue JSON is not an array");
const native=rows.filter(x=>x.backend==="Native R"),bridge=rows.filter(x=>x.backend==="Python-backed");
assert(native.length>40,"Missing native plotting exports");
assert(rows.length===new Set(rows.map(x=>x.name)).size,"Duplicate plotting exports");
assert(native.every(x=>x.name.startsWith("etr_plot_")),"Non-exported native title in inventory");
assert(bridge.every(x=>/^etpy_plot_|^et_plot_/.test(x.name)),"Unexpected bridge");
const shown=rows.filter(x=>x.variants&&x.variants.length);
assert(shown.length===81,"Wave 5 requires all 81 real native R plotting functions");
const taxonomy=[
 "Trajectories & reconstruction","Functional PCA & diagnostics",
 "Functional regression","Mixed-effects & covariance",
 "Functional inference & bootstrap","Sparse functional data",
 "Nonlinear dynamics & RQA","Information transfer & surrogates",
 "Registration & alignment","Simulation & recovery","Workflow dispatch"
];
assert.deepEqual([...new Set(native.map(x=>x.category))].sort(),taxonomy.slice().sort(),
  "All 11 precisely defined native R scientific categories must be represented");
const examples={
 "etr_plot_trajectories":"Trajectories & reconstruction",
 "etr_plot_fpca_component":"Functional PCA & diagnostics",
 "etr_plot_fpca_regression_slope_band":"Functional regression",
 "etr_plot_generalized_function_on_scalar_coefficients":"Functional regression",
 "etr_plot_functional_random_effects":"Mixed-effects & covariance",
 "etr_plot_fpca_wild_bootstrap_family_test":"Functional inference & bootstrap",
 "etr_plot_sparse_mfpca_covariance_blocks":"Sparse functional data",
 "etr_plot_windowed_rqa_sensitivity":"Nonlinear dynamics & RQA",
 "etr_plot_transfer_entropy_sensitivity":"Information transfer & surrogates",
 "etr_plot_multivariate_iaaft_diagnostics":"Information transfer & surrogates",
 "etr_plot_registration":"Registration & alignment",
 "etr_plot_functional_recovery_summary":"Simulation & recovery",
 "etr_plot_workflow_result":"Workflow dispatch"
};
for(const [name,family] of Object.entries(examples))
 assert.equal(native.find(x=>x.name===name)?.category,family,
   name+": incorrect scientific family");
assert(native.every(x=>x.parameters?.length>=1),"Source R function formals are missing");
for(const entry of native){
 const keys=entry.parameters.map(x=>x.name);
 assert.equal(keys.length,new Set(keys).size,entry.name+": duplicate formal");
 assert.ok(entry.parameters.every(x=>
  x.explanation?.length>=30&&x.default?.length>=1),
  entry.name+": missing scientific parameter explanation or formal default");
}
assert(native.every(x=>x.variants&&x.variants.length>0),
  "No native R function may remain documentation-only");
const count=shown.reduce((a,x)=>a+x.variants.length,0);
assert(count>=108,"Wave 5 requires >=108 direct native R PNG variants");
for(const entry of rows){
 assert(entry.doc&&fs.existsSync(path.join(root,entry.doc)),entry.name+": broken documentation route "+entry.doc);
 if(!entry.variants.length)continue;
 assert(entry.backend==="Native R",entry.name+": nonnative preview mislabelled");
 for(const variant of entry.variants){
   assert(variant.code.includes(entry.name+"("),entry.name+": code omits function");
   assert(variant.code.includes("library(eyetrajectories)"),entry.name+": missing reproducible package setup");
   assert(variant.image.startsWith("plot-atlas/images/"),entry.name+": unexpected image path");
   assert(variant.script?.startsWith("plot-atlas/scripts/"),
     entry.name+": missing downloadable R script");
   const script=path.join(root,variant.script);
   assert(fs.existsSync(script),entry.name+": missing R script file");
   const source=fs.readFileSync(script,"utf8");
   assert.equal(source,variant.code,entry.name+": download does not match copyable code");
   assert(source.includes('packageVersion("eyetrajectories")) == "0.4.3"'),
      entry.name+": missing R package version check");
   assert(source.includes(entry.name+"("),
     entry.name+": downloaded file omits its actual native plotting function");
   const file=path.join(root,variant.image);
   assert(fs.existsSync(file),entry.name+": missing native figure "+file);
   const stat=fs.statSync(file);assert(stat.size>3500,entry.name+": empty/invalid PNG");
   const sig=fs.readFileSync(file).subarray(0,8).toString("hex");
   assert.equal(sig,"89504e470d0a1a0a",entry.name+": invalid PNG bytes");
 }
}
const manifest=fs.readFileSync(path.join(root,"plot-atlas","MANIFEST.txt"),"utf8");
assert(manifest.includes("v0.4.3")&&manifest.includes("actual"),"Missing provenance");
const audit=fs.readFileSync(path.join(root,"plot-atlas","EXTENSION_AUDIT.txt"),"utf8");
assert(audit.includes("Additional direct native R plot exports"),"Missing scientific fixture audit");
const wave3=fs.readFileSync(path.join(root,"plot-atlas","WAVE3_AUDIT.txt"),"utf8");
assert(wave3.includes("Rendered native plotting functions: 14"),"All 14 advanced-inference functions must render");
assert(wave3.includes("Not yet rendered: 0"),"No incomplete Wave 3 plot may be marked illustrated");
const expectedWave3=[
  "etr_plot_fpca_regression_future_prediction_interval",
  "etr_plot_fpca_regression_mean_prediction_uncertainty",
  "etr_plot_fpca_regression_slope_band",
  "etr_plot_fpca_regression_slope_uncertainty",
  "etr_plot_fpca_wild_bootstrap_projection",
  "etr_plot_fpca_wild_bootstrap_simultaneous_interval",
  "etr_plot_fpca_wild_bootstrap_family_test",
  "etr_plot_fpca_wild_bootstrap_monte_carlo_diagnostics",
  "etr_plot_fpca_wild_bootstrap_truncation_scan",
  "etr_plot_conformal_fpca_anomaly",
  "etr_plot_covariance_sensitivity_coefficients",
  "etr_plot_covariance_sensitivity_band_widths",
  "etr_plot_functional_mixed_effects_bootstrap_comparison",
  "etr_plot_generalized_function_on_scalar_predictions"
];
for(const name of expectedWave3){
  const entry=rows.find(x=>x.name===name);
  assert(entry && entry.backend==="Native R",name+": missing native R export");
  assert(entry.variants?.length>0,name+": no executed direct R figure");
  assert(wave3.includes("PASS "+name),name+": missing wave-3 proof");
}

const wave4=fs.readFileSync(path.join(root,"plot-atlas","WAVE4_AUDIT.txt"),"utf8");
assert(wave4.includes("Rendered native plotting functions: 11"),
  "All 11 native nonlinear dynamics plots must render");
assert(wave4.includes("Not yet rendered: 0"),
  "Unrendered nonlinear plots cannot be counted");
const expectedWave4=[
  "etr_plot_recurrence_network_degree",
  "etr_plot_local_divergence",
  "etr_plot_surrogate_nonlinearity",
  "etr_plot_kantz_sensitivity",
  "etr_plot_lyapunov_sensitivity",
  "etr_plot_windowed_rqa_sensitivity",
  "etr_plot_transfer_entropy_sensitivity",
  "etr_plot_transfer_entropy_circular_shift_test",
  "etr_plot_conditional_transfer_entropy_circular_shift_test",
  "etr_plot_multivariate_iaaft_diagnostics",
  "etr_plot_multivariate_surrogate_nonlinearity"
];
for(const name of expectedWave4){
  const entry=rows.find(x=>x.name===name);
  assert(entry&&entry.backend==="Native R",name+": missing native export");
  assert(entry.variants?.length>0,name+": missing real executed R preview");
  assert(wave4.includes("PASS "+name),name+": missing Wave 4 evidence");
  const expected=/(transfer_entropy|surrogate_nonlinearity|multivariate_iaaft)/.test(name)?
    "Information transfer & surrogates":"Nonlinear dynamics & RQA";
  assert.equal(entry.category,expected,name+": wrong scientific family");
}

const wave5=fs.readFileSync(path.join(root,"plot-atlas","WAVE5_AUDIT.txt"),"utf8");
assert(wave5.includes("Rendered native plotting functions: 8"),
  "All eight remaining native R plotting functions must render");
assert(wave5.includes("Not yet rendered: 0"),"Wave 5 must have zero missing plots");
const expectedWave5=[
  "etr_plot_function_on_scalar_coefficients",
  "etr_plot_rqa_metric_mean_bootstrap",
  "etr_plot_functional_recovery_summary",
  "etr_plot_functional_random_effects",
  "etr_plot_functional_trial_random_effects",
  "etr_plot_generalized_function_on_scalar_mean_difference",
  "etr_plot_generalized_function_on_scalar_coefficients",
  "etr_plot_workflow_result"
];
for(const name of expectedWave5){
  const entry=rows.find(x=>x.name===name);
  assert(entry && entry.backend==="Native R",name+": must be a real native export");
  assert(entry.variants?.length>0,name+": missing R-executed figure");
  assert(wave5.includes("PASS "+name),name+": missing Wave 5 evidence");
}

const wave6audit=fs.readFileSync(path.join(root,"plot-atlas","WAVE6_AUDIT.txt"),"utf8");
assert(wave6audit.includes("Native plotting functions: 81")&&
  wave6audit.includes("Scientific method categories: 11")&&
  wave6audit.includes("Generated R reproduction scripts: "+count),
 "Wave 6 native source/parameter/script evidence missing");
assert(html.includes("pre-generated R outputs"),"Cannot claim client-side R recomputation");
assert(html.includes("10.5281/zenodo.24288857"),"Missing Zenodo citation");
console.log("ACTUAL_R_PLOT_ATLAS_PASS native="+native.length+
  " python="+bridge.length+" illustrated="+shown.length+" figures="+count+
  " all_docs_and_pngs_verified");
