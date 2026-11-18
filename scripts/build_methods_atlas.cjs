#!/usr/bin/env node
/* Build the static Methods Atlas from published v0.4.3 and the curated
 * development evidence file; no gaze data or Python application used. */
"use strict";
const fs=require("node:fs"),path=require("node:path"),assert=require("node:assert/strict");
const site=path.resolve(process.argv[2]||"pkg/site");
const registryFile=path.resolve(process.argv[3]||"pkg/site/method-registry-v0.4.3.json");
const assets=path.resolve(process.argv[4]||"website/site-interactive");
const data=JSON.parse(fs.readFileSync(registryFile,"utf8"));
assert.equal(data.schema,"eyetrajectories-method-registry/v1");
assert.equal(data.release,"v0.4.3");
assert.equal(data.total_exports,904);
assert.equal(data.methods.length,904);
assert.equal(data.curated+data.provisional,904);
const names=new Set(),tierSet=new Set();
for(const m of data.methods){
 assert(/^(etr_|et_|etpy_)[A-Za-z0-9_]+$/.test(m.name),m.name);
 assert(!names.has(m.name),"Duplicate method "+m.name);names.add(m.name);
 assert(["core","advanced","experimental"].includes(m.tier),m.name);
 tierSet.add(m.tier);
 assert(["curated","provisional_lexical"].includes(m.classification_basis),m.name);
 assert(typeof m.caveat==="string"&&m.caveat.length>=35,m.name);
 assert(typeof m.evidence_status==="string",m.name);
 assert(m.source_release==="v0.4.3",m.name);
 if(m.evidence)assert(/^docs\/[A-Za-z0-9._/-]+\.md$/.test(m.evidence),m.name);
 const exact="reference/"+m.name+".html";
 m.reference_href=fs.existsSync(path.join(site,exact))?exact:"reference/index.html";
}
assert.equal(tierSet.size,3);
assert.equal(data.methods.filter(x=>x.classification_basis==="curated").length,data.curated);
assert(fs.existsSync(path.join(site,"reference/index.html")),"pkgdown reference absent");
for(const file of ["methods-atlas.html","methods-atlas.css","methods-atlas.js",
                   "flagship-workflows.html","flagship-workflows.css"]){
 const src=path.join(assets,file);
 assert(fs.statSync(src).size>100,"Site source missing "+file);
 fs.copyFileSync(src,path.join(site,file));
}
const js="/* Generated from frozen v0.4.3 NAMESPACE; site-local only. */\n"+
  "window.ET_METHOD_REGISTRY="+JSON.stringify(data)+";\n";
fs.writeFileSync(path.join(site,"methods-atlas-data.js"),js,"utf8");
const counts={
 schema:data.schema,release:data.release,
 exported:data.total_exports,curated:data.curated,provisional:data.provisional,
 tiers:Object.fromEntries([...tierSet].sort().map(t=>
    [t,data.methods.filter(m=>m.tier===t).length])),
 backends:Object.fromEntries([...new Set(data.methods.map(m=>m.backend))].sort().map(b=>
    [b,data.methods.filter(m=>m.backend===b).length])),
 no_scientific_certification_claim:true
};
fs.writeFileSync(path.join(site,"methods-atlas-manifest.json"),
   JSON.stringify(counts,null,2)+"\n");
console.log("SCIENTIFIC_METHODS_ATLAS_BUILD_PASS",JSON.stringify(counts));
