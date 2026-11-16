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
assert(shown.length>=9,"Expected 9 direct native function demos");
const count=shown.reduce((a,x)=>a+x.variants.length,0);
assert(count>=16,"Expected >=16 real R-rendered variants");
for(const entry of rows){
 assert(entry.doc&&fs.existsSync(path.join(root,entry.doc)),entry.name+": broken documentation route "+entry.doc);
 if(!entry.variants.length)continue;
 assert(entry.backend==="Native R",entry.name+": nonnative preview mislabelled");
 for(const variant of entry.variants){
   assert(variant.code.includes(entry.name+"("),entry.name+": code omits function");
   assert(variant.code.includes("library(eyetrajectories)"),entry.name+": missing reproducible package setup");
   assert(variant.image.startsWith("plot-atlas/images/"),entry.name+": unexpected image path");
   const file=path.join(root,variant.image);
   assert(fs.existsSync(file),entry.name+": missing native figure "+file);
   const stat=fs.statSync(file);assert(stat.size>3500,entry.name+": empty/invalid PNG");
   const sig=fs.readFileSync(file).subarray(0,8).toString("hex");
   assert.equal(sig,"89504e470d0a1a0a",entry.name+": invalid PNG bytes");
 }
}
const manifest=fs.readFileSync(path.join(root,"plot-atlas","MANIFEST.txt"),"utf8");
assert(manifest.includes("v0.4.3")&&manifest.includes("actual"),"Missing provenance");
assert(html.includes("pre-generated R outputs"),"Cannot claim client-side R recomputation");
assert(html.includes("10.5281/zenodo.24288857"),"Missing Zenodo citation");
console.log("ACTUAL_R_PLOT_ATLAS_PASS native="+native.length+
  " python="+bridge.length+" illustrated="+shown.length+" figures="+count+
  " all_docs_and_pngs_verified");
