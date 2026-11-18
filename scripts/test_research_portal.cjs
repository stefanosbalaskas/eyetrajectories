#!/usr/bin/env node
"use strict";
const fs=require("node:fs"),path=require("node:path"),
 assert=require("node:assert/strict"),vm=require("node:vm");
const root=path.resolve(process.argv[2]||"pkg/site");
const html=fs.readFileSync(path.join(root,"research-portal.html"),"utf8");
for(const id of ["preflightForm","csvFile","csvPaste","timeUnit","coordUnit","csvStatus",
  "exportAudit","applyStructure","obsGrid","researchGoal","studyHierarchy",
  "uncertainty","selection","matrixSearch","matrixFamily","matrixGrid",
  "workflowRows","routeDetail","detailImage"])
 assert(html.includes('id="'+id+'"'),"Missing portal UI control "+id);
assert(html.includes('connect-src &#39;none&#39;')||
       html.includes("connect-src 'none'"),
       "Browser portal must prohibit network connections with a CSP");
assert(html.includes('src="research-workflows.js"')&&
       html.includes('src="research-portal.js"'),
       "Scripts must load as same-origin external files for strict CSP");
const js=fs.readFileSync(path.join(root,"research-portal.js"),"utf8");
new vm.Script(js,{filename:"research-portal.js"});
for(const forbidden of [/fetch\s*\(/,/XMLHttpRequest\b/,/WebSocket\s*\(/,/navigator\.sendBeacon\s*\(/,/localStorage\s*[\[.]/])
 assert(!forbidden.test(js),"A network/storage API or unsafe persistence pattern was found: "+forbidden);
const catalog={window:{}};
const source=fs.readFileSync(path.join(root,"research-workflows.js"),"utf8");
vm.runInNewContext(source,catalog,{timeout:10000});
const payload=catalog.window.ET_RESEARCH_PORTAL;
assert.equal(payload.schema,"eyetrajectories-research-workflow-portal/v1");
assert.equal(payload.versions.r,"0.4.3");assert.equal(payload.versions.python,"1.2.0");
const rows=payload.workflows;
assert.equal(rows.length,10);
assert.equal(new Set(rows.map(x=>x.python)).size,10);
assert.equal(new Set(rows.map(x=>x.rWorkflow)).size,10);
const raw=JSON.parse(fs.readFileSync(path.join(root,"research-workflows.json"),"utf8"));
assert.deepEqual(JSON.parse(JSON.stringify(payload)),raw,"Published JSON/JavaScript mismatch");
const pngs=fs.readdirSync(path.join(root,"plot-atlas","images")).filter(x=>x.endsWith(".png"));
assert(pngs.length>=108,"Wave 7 must preserve complete native figures");
for(const x of rows){
 assert(x.python.startsWith("run_")&&x.rWorkflow.startsWith("etr_run_"));
 assert(x.rEstimator.startsWith("etr_")&&x.plot.startsWith("etr_plot_"));
 assert(x.rWorkflowDoc?.href&&x.rEstimatorDoc?.href);
 for(const d of [x.rWorkflowDoc,x.rEstimatorDoc,x.rSecondaryDoc].filter(Boolean)){
  assert(fs.existsSync(path.join(root,d.href)),x.id+": broken R docs "+d.href);
  if(d.exact)assert(d.href.includes(".html")&&!d.href.includes("index.html"));
  else assert.equal(d.href,"reference/index.html");
 }
 assert(x.plotPage==="plot-atlas.html?function="+encodeURIComponent(x.plot));
 assert(fs.existsSync(path.join(root,x.plotImage)),x.id+": broken PNG");
 assert(fs.existsSync(path.join(root,x.plotScript)),x.id+": broken R example script");
 const sample=fs.readFileSync(path.join(root,x.plotScript),"utf8");
 assert(sample.includes("library(eyetrajectories)")&&sample.includes(x.plot+"("),
  x.id+": script does not execute actual native plot");
 assert.equal(x.scientificEvidence,"SITE_VALIDATION.html");
 assert(fs.existsSync(path.join(root,x.scientificEvidence)));
 assert(x.boundary.length>45&&x.assumptions.length>45);
 assert(x.plotNote.toLowerCase().includes("synthetic")||x.plotNote.toLowerCase().includes("related"));
}
const manifest=fs.readFileSync(path.join(root,"research-portal-manifest.txt"),"utf8");
assert(manifest.includes("Source-matched Python workflow routes: 10"));
assert(manifest.includes("Verified exported native R orchestration routes: 10"));
assert(manifest.includes("Full source-contract independent scientific certifications: 0/508"));
assert(fs.existsSync(path.join(root,"SITE_RESEARCH_PORTAL.html")),
  "Missing static portal methodology and privacy specification");
assert(fs.readFileSync(path.join(root,"index.html"),"utf8")
 .includes('href="research-portal.html"'),"Homepage does not link to the research portal");
assert(fs.readFileSync(path.join(root,"plot-atlas.html"),"utf8")
 .includes('new URLSearchParams(window.location.search).get("function")'),
 "Atlas must support safe function deep links");
console.log("WAVE7_STATIC_PORTAL_PASS routes=10 native=10 plots=10 R_docs_resolved=20"+
 " structural_CSV_and_no_network_contracts_verified");
