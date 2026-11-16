#!/usr/bin/env node
/* Wave 7 website overlay: fail-closed, source-pinned workflow navigator.
 * Output is static JSON/JS. Does NOT execute Python or any R estimator.
 * The scientific figure gallery is independently produced by native R. */
"use strict";
const fs=require("node:fs"),path=require("node:path"),
 assert=require("node:assert/strict"),vm=require("node:vm");
const pkg=path.resolve(process.argv[2]||"pkg");
const source=path.resolve(process.argv[3]||"website/site-interactive/research-workflows.json");
const site=path.join(pkg,"site");
const raw=JSON.parse(fs.readFileSync(source,"utf8"));
assert.equal(raw.schema,"eyetrajectories-research-workflow-portal/v1");
assert.equal(raw.versions.r,"0.4.3");
assert.equal(raw.versions.python,"1.2.0");
assert.equal(raw.workflows.length,10);
const pythonNames=[
 "run_sparse_fpca_workflow","run_sparse_mfpca_workflow",
 "run_sparse_mfpca_async_workflow","run_sparse_multilevel_workflow",
 "run_sparse_prediction_workflow","run_fpca_workflow",
 "run_function_on_scalar_workflow","run_functional_mixed_effects_workflow",
 "run_generalized_functional_workflow","run_recurrence_workflow"
];
assert.deepEqual(raw.workflows.map(x=>x.python),pythonNames,
 "The Python 1.2 source-defined ten workflows must remain exact and ordered");
const ns=fs.readFileSync(path.join(pkg,"NAMESPACE"),"utf8");
const exported=new Set([...ns.matchAll(/^export\(([A-Za-z0-9_]+)\)$/gm)].map(x=>x[1]));
const sourcePage=fs.readFileSync(path.join(site,"plot-atlas","catalog.js"),"utf8");
const sandbox={window:{}};vm.runInNewContext(sourcePage,sandbox,{timeout:10000});
const nativePlot=new Map(sandbox.window.ET_PLOT_ATLAS_CATALOG
 .filter(x=>x.backend==="Native R").map(x=>[x.name,x]));
assert.equal(nativePlot.size,81);
const pages={};
function doc(name){
 const exact="reference/"+name+".html";
 if(fs.existsSync(path.join(site,exact)))return {href:exact,exact:true};
 assert(fs.existsSync(path.join(site,"reference/index.html")));
 return {href:"reference/index.html",exact:false};
}
const clean=/^etr_[A-Za-z0-9_]+$/;
const workflows=raw.workflows.map((x,i)=>{
 for(const key of ["rWorkflow","rEstimator","rSecondary","plot"]){
   if(!x[key])continue;
   assert(clean.test(x[key]),x.id+": nonnative identifier "+x[key]);
   assert(exported.has(x[key]),x.id+": no actual frozen-R NAMESPACE export "+x[key]);
 }
 assert(x.rWorkflow.startsWith("etr_run_"),x.id+": misleading workflow symbol");
 assert(x.rEstimator.startsWith("etr_"),x.id+": missing R estimator symbol");
 const plot=nativePlot.get(x.plot);
 assert(plot?.variants?.length,x.id+": no native-generated R figure "+x.plot);
 const fig=plot.variants[0];
 assert(fs.existsSync(path.join(site,fig.image)),x.id+": figure path broken");
 assert(fs.existsSync(path.join(site,fig.script)),x.id+": reproduction script path broken");
 for(const key of ["title","inputs","estimand","assumptions","boundary","plotNote"]){
  assert(typeof x[key]==="string"&&x[key].length>45,x.id+": empty/underspecified "+key);
 }
 assert(Array.isArray(x.families)&&x.families.length>=1);
 return {...x,
   rWorkflowDoc:doc(x.rWorkflow),rEstimatorDoc:doc(x.rEstimator),
   rSecondaryDoc:x.rSecondary?doc(x.rSecondary):null,
   plotPage:"plot-atlas.html?function="+encodeURIComponent(x.plot),
   plotImage:fig.image,plotScript:fig.script,
   scientificEvidence:raw.evidence,
   completeParityLedger:raw.fullSourceLedger,
   pythonGuide:raw.pythonGuide,
   exactPythonSource:"https://github.com/stefanosbalaskas/eyetrajectoriespy/blob/v1.2.0/src/eyetrajectoriespy/workflows/__init__.py",
   status:"Native R research capability; Python source-contract equivalence not independently certified",
   displayOrder:i+1
 };
});
assert.equal(new Set(workflows.map(x=>x.id)).size,10);
assert.equal(new Set(workflows.map(x=>x.rWorkflow)).size,10);
assert(workflows.every(x=>x.plotImage.startsWith("plot-atlas/images/")));
const output={schema:raw.schema,versions:raw.versions,
 boundary:"Website navigation only. Synthetic R images; no client-side estimator, causal inference, model calibration, missing-data mechanism identification or Python full-source equivalence.",
 localOnly:"CSV preflight runs locally in the reader's browser. No file is transmitted.",
 workflows};
fs.writeFileSync(path.join(site,"research-workflows.js"),
 "window.ET_RESEARCH_PORTAL="+JSON.stringify(output)+";\n","utf8");
fs.writeFileSync(path.join(site,"research-workflows.json"),
 JSON.stringify(output,null,2)+"\n","utf8");
fs.writeFileSync(path.join(site,"research-portal-manifest.txt"),[
 "EYETRAJECTORIES_WAVE7_STATIC_NAVIGATION",
 "Immutable native R source version: 0.4.3",
 "Referenced Python workflows: 1.2.0 stable module API",
 "Source-matched Python workflow routes: "+pythonNames.length,
 "Verified exported native R orchestration routes: "+workflows.length,
 "Native R estimator references resolved: "+workflows.length,
 "Qualified atlas native-R plot references: "+workflows.length,
 "Full source-contract independent scientific certifications: 0/508",
 "CSV rows analysed in browser only; no server computation or upload.",
 "Figures are synthetic teaching examples, not workflow-specific estimator parity.",
 "Exact R reference pages available for "+workflows.filter(x=>x.rWorkflowDoc.exact).length+" workflow routes and "+
  workflows.filter(x=>x.rEstimatorDoc.exact).length+" estimators.",
 "All unresolved routes fall back to the verified reference index."
].join("\n")+"\n");
console.log("WAVE7_DATA_PASS python=10 native_workflows=10 native_estimators=10 figures=10"+
 " exact_workflow_docs="+workflows.filter(x=>x.rWorkflowDoc.exact).length);
