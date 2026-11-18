#!/usr/bin/env node
/* Fail-closed acceptance for source-derived Methods Atlas. */
"use strict";
const fs=require("node:fs"),path=require("node:path"),assert=require("node:assert/strict"),vm=require("node:vm");
const root=path.resolve(process.argv[2]||"pkg/site");
const read=f=>fs.readFileSync(path.join(root,f),"utf8");
const data=JSON.parse(read("method-registry-v0.4.3.json"));
const manifest=JSON.parse(read("methods-atlas-manifest.json"));
assert.equal(manifest.exported,904);
assert.equal(data.methods.length,904);
assert.equal(data.methods.filter(m=>m.classification_basis==="curated").length,manifest.curated);
assert.equal(data.methods.filter(m=>m.classification_basis!=="curated").length,manifest.provisional);
assert.equal(data.methods.filter(m=>m.name==="etr_pairwise_l2")[0].tier,"core");
assert.equal(data.methods.filter(m=>m.name==="etr_fit_sparse_pace")[0].backend,"r-delegated-fdapace");
assert.equal(data.methods.filter(m=>m.name==="etr_fit_multilevel_fpca")[0].evidence_status,"descriptive_only");
assert.equal(data.methods.filter(m=>m.name==="etr_bootstrap_mean_band")[0].evidence_status,"simulation_characterized");
assert(data.methods.some(m=>m.backend==="python-bridge"));
assert(!data.methods.some(m=>m.backend==="native-r"));
assert.equal(data.methods.filter(m=>m.backend==="native-R").length,502);
assert(data.methods.some(m=>m.classification_basis==="provisional_lexical"));
const js=read("methods-atlas-data.js");
const global={window:{}};
vm.runInNewContext(js,global,{timeout:2000});
const enhanced=global.window.ET_METHOD_REGISTRY;
assert.equal(enhanced.methods.length,904);
for(const m of enhanced.methods) {
 assert(typeof m.reference_href==="string"&&
        fs.existsSync(path.join(root,m.reference_href)),
      m.name+" has broken generated reference link");
 if(m.classification_basis!=="curated")
  assert(m.evidence_status==="evidence_not_curated");
}
for(const file of ["methods-atlas.html","methods-atlas.css","methods-atlas.js",
"flagship-workflows.html","flagship-workflows.css"]) {
 assert(fs.statSync(path.join(root,file)).size>100,file);
}
const atlas=read("methods-atlas.html");
for(const id of ["id=\"search\"","id=\"tier\"","id=\"backend\"","id=\"review\"",
                 "id=\"results\"","methods-atlas-data.js","flagship-workflows.html"])
 assert(atlas.includes(id),"Missing atlas control "+id);
assert(!/fetch\s*\(|XMLHttpRequest|WebSocket|localStorage/.test(read("methods-atlas.js")),
      "Atlas must work from embedded static data without external data requests");
const wf=read("flagship-workflows.html");
for(const [slug,source] of [
 ["01-dense","01_complete_gaze_trajectory.R"],
 ["02-multilevel","02_multilevel_functional_variation.R"],
 ["03-sparse","03_sparse_irregular_recovery.R"],
 ["04-uncertainty","04_uncertainty_paired_contrast.R"]]){
 assert(wf.includes("workflows/"+source),"Missing flagship source link");
 assert(wf.includes("workflows/"+slug+"/preview.png"));
 for(const file of ["METHODS_AND_LIMITATIONS.md","sessionInfo.txt","preview.png"])
  assert(fs.statSync(path.join(root,"workflows",slug,file)).size>100,slug+"/"+file);
}
console.log("SCIENTIFIC_ATLAS_904_AND_FOUR_FLAGSHIP_SITE_ACCEPTANCE_PASS");
