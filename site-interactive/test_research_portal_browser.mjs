#!/usr/bin/env node
/* Wave 7 headless desktop/mobile Chromium acceptance with privacy assertions.
 * Browser test runs on a local static server; no gaze data is uploaded. */
import assert from "node:assert/strict";
import fs from "node:fs/promises";
import http from "node:http";
import os from "node:os";
import path from "node:path";
import {chromium} from "playwright";

const root=path.resolve(process.argv[2]||"pkg/site");
const shots=path.resolve(process.argv[3]||path.join(os.tmpdir(),"eyetrajectories-wave7-browser"));
await fs.mkdir(shots,{recursive:true});
const types={".html":"text/html; charset=utf-8",".js":"text/javascript; charset=utf-8",
 ".css":"text/css; charset=utf-8",".png":"image/png",".svg":"image/svg+xml",
 ".R":"text/plain; charset=utf-8",".json":"application/json",".txt":"text/plain"};
const server=http.createServer(async(req,res)=>{
 try{
  const name=decodeURIComponent(new URL(req.url,"http://localhost").pathname);
  const full=path.resolve(root,"."+name);
  if(!full.startsWith(root+path.sep)){res.writeHead(403);res.end();return;}
  const bytes=await fs.readFile(full);
  res.writeHead(200,{"Content-Type":types[path.extname(full)]||"application/octet-stream",
   "Cache-Control":"no-store"});res.end(bytes);
 }catch(e){res.writeHead(e.code==="ENOENT"?404:500);res.end("Not found");}
});
await new Promise(resolve=>server.listen(0,"127.0.0.1",resolve));
const base="http://127.0.0.1:"+server.address().port+"/";
let browser;
const errors=[];
function watch(page){
 page.on("pageerror",e=>errors.push("JS "+e.message));
 page.on("request",req=>{
  if(!req.url().startsWith(base)&&!req.url().startsWith("blob:")&&
     !req.url().startsWith("data:"))
   errors.push("Unexpected network request "+req.url());
 });
 page.on("response",res=>{
  if(res.url().startsWith(base)&&res.status()>=400)
   errors.push("HTTP "+res.status()+" "+res.url());
 });
}
try{
 browser=await chromium.launch({headless:true,args:["--no-sandbox"]});
 const context=await browser.newContext({viewport:{width:1440,height:960},
   acceptDownloads:true,deviceScaleFactor:1});
 const page=await context.newPage();watch(page);
 await page.goto(base+"research-portal.html",{waitUntil:"networkidle"});
 await page.waitForFunction(()=>window.ET_RESEARCH_PORTAL_API?.getState());
 const routes=await page.evaluate(()=>window.ET_RESEARCH_PORTAL.workflows);
 assert.equal(routes.length,10,"Ten real native R workflows required");
 assert.equal(await page.locator("#workflowRows tr").count(),10);
 assert.ok(await page.locator("#choiceName").innerText().then(s=>s.includes("FPCA")));

 // CSV parser: quoted commas and embedded newlines, BOM and preserved zero.
 const parsed=await page.evaluate(()=>{
  const fn=window.ET_RESEARCH_PORTAL_API.parseCSV;
  return fn('\ufeffparticipant_id,trial_id,time_s,x,y,note\n' +
    'P01,T01,0,0,0,"first,\nsecond"\nP01,T01,1,,0.4,"ok"');
 });
 assert.equal(parsed.rows.length,2);
 assert.equal(parsed.rows[0][5],"first,\nsecond");
 assert.equal(parsed.rows[0][3],"0");
 assert.equal(parsed.rows[1][3],"");
 const malformed=await page.evaluate(()=>{
  try{window.ET_RESEARCH_PORTAL_API.parseCSV(
   "participant_id,trial_id,time_s,x,y\nP01,T01,0,0\n");return false}
  catch(e){return /expected/i.test(e.message)}
 });
 assert.ok(malformed,"Ragged CSV must fail closed");
 const ambiguous=await page.evaluate(()=>{
  try{window.ET_RESEARCH_PORTAL_API.parseCSV(
   "participant_id,trial_id,time,time_s,x,y\nP01,T01,0,0,0,0");return false}
  catch(e){return /exactly one time/i.test(e.message)}
 });
 assert.ok(ambiguous,"Ambiguous timestamp schema must fail closed");
 const risk=await page.evaluate(()=>{
  return window.ET_RESEARCH_PORTAL_API.inspectCSV(
   "participant_id,trial_id,time_s,x,y\nP01,T01,0,0,0\nP01,T01,0,1,\nP01,T01,-1,,3",
   "seconds","pixels");
 });
 assert.equal(risk.duplicateTimes,1);
 assert.equal(risk.outOfOrder,1);
 assert.equal(risk.missingX,1);
 assert.equal(risk.missingY,1);
 assert.equal(risk.commonGrid,false);
 assert.ok(risk.warnings.some(x=>x.includes("asynchronous sensor acquisition")));
 const tooMany=await page.evaluate(()=>{
  try{window.ET_RESEARCH_PORTAL_API.parseCSV("participant_id,trial_id,time_s,x,y\n"+
   "P,T,0,1,2\n".repeat(12001));return false}
  catch(e){return /12,000/.test(e.message)}
 });
 assert.ok(tooMany,"12k row cap must be enforced");
 console.log("WAVE7_CSV_PARSER_PASS BOM=YES quotes=YES zero=YES missing=YES time=YES limit=YES");

 // Actual browser-local input (no network) and explicit propagation to chooser.
 await page.locator("#sampleCSV").click();
 await page.waitForFunction(()=>window.ET_RESEARCH_PORTAL_API.getState().auditAvailable);
 const aggregate=await page.locator("#preflightReport").innerText();
 assert.ok(aggregate.includes("9")&&aggregate.includes("participants"));
 assert.ok(await page.locator("#exportAudit").isEnabled());
 assert.ok(await page.locator("#applyStructure").isEnabled());
 await page.locator("#applyStructure").click();
 assert.equal(await page.locator("#obsGrid").inputValue(),"dense");
 assert.equal(await page.locator("#studyHierarchy").inputValue(),"repeated");
 const downPromise=page.waitForEvent("download");
 await page.locator("#exportAudit").click();
 const down=await downPromise;
 assert.ok(down.suggestedFilename().endsWith(".json"));
 const json=JSON.parse(await fs.readFile(await down.path(),"utf8"));
 assert.equal(json.rows,9);assert.equal(json.repeatedParticipants,1);
 assert.equal(json.commonGrid,true);
 assert.ok(!JSON.stringify(json).includes("P01")&&!JSON.stringify(json).includes("0.43"));
 assert.ok(!Object.keys(json).includes("fileName"));

 // Uploaded local file API must be read in page only, no request event.
 await page.locator("#clearCSV").click();
 assert.ok(!(await page.locator("#exportAudit").isEnabled()));
 const file="participant_id,trial_id,time_s,x,y\n"+
  '"PRIVATE-PATIENT",T01,0,0.21852,0.3\n'+
  '"PRIVATE-PATIENT",T01,1,0.4,0.5\n';
 await page.locator("#csvFile").setInputFiles({
  name:"private-example.csv",mimeType:"text/csv",buffer:Buffer.from(file)
 });
 await page.locator("#timeUnit").selectOption("seconds");
 await page.locator("#coordUnit").selectOption("normalized");
 await page.locator("#inspectCSV").click();
 await page.waitForFunction(()=>window.ET_RESEARCH_PORTAL_API.getState().auditAvailable);
 const dp=page.waitForEvent("download");await page.locator("#exportAudit").click();
 const exportDown=await dp;
 const exported=await fs.readFile(await exportDown.path(),"utf8");
 assert.ok(!exported.includes("PRIVATE-PATIENT")&&!exported.includes("0.21852")&&
  !exported.includes("private-example.csv"),"Raw private values leaked into JSON");
 await page.locator("#clearCSV").click();

 // Inference refusal behavior: no automatic MNAR or wrong sparse outcome model.
 await page.locator("#obsGrid").selectOption("dense");
 await page.locator("#uncertainty").selectOption("mnar");
 assert.equal(await page.locator("#choiceName").innerText(),"No automatic method selected");
 await page.locator("#uncertainty").selectOption("simultaneous");
 assert.ok((await page.locator("#choiceWarnings").innerText()).includes("NOT universally calibrated"));
 await page.locator("#obsGrid").selectOption("async");
 await page.locator("#researchGoal").selectOption("variation");
 assert.ok((await page.locator("#choiceName").innerText()).includes("asynchronous"));
 await page.locator("#researchGoal").selectOption("effects");
 assert.equal(await page.locator("#choiceName").innerText(),"No automatic method selected");
 await page.locator("#obsGrid").selectOption("dense");
 await page.locator("#studyHierarchy").selectOption("repeated");
 assert.ok((await page.locator("#choiceName").innerText()).includes("mixed effects"));
 await page.locator("#researchGoal").selectOption("outcomes");
 assert.equal(await page.locator("#choiceName").innerText(),"No automatic method selected");
 await page.locator("#resetMethod").click();
 assert.ok((await page.locator("#choiceName").innerText()).includes("FPCA"));
 console.log("WAVE7_WIZARD_PASS no_MNAR_inference=YES no_invalid_forced_route=YES");

 // Matrix filters and linked, actual native-R scientific artwork.
 await page.locator("#matrixFamily").selectOption("sparse");
 assert.equal(await page.locator("#workflowRows tr").count(),5);
 await page.locator("#matrixFamily").selectOption("all");
 await page.locator("#matrixSearch").fill("recurrence");
 assert.equal(await page.locator("#workflowRows tr").count(),1);
 await page.locator("#workflowRows button").click();
 assert.ok(await page.locator("#detailTitle").innerText().then(x=>x.includes("Recurrence")));
 assert.ok(await page.locator("#detailImage").evaluate(async img=>{
  await img.decode();return img.naturalWidth>200&&img.naturalHeight>200;
 }));
 const hrefs=await page.locator("#detailLinks a").evaluateAll(links=>
  links.map(a=>({text:a.textContent,url:a.getAttribute("href")})));
 assert.ok(hrefs.some(x=>x.url.includes("plot-atlas.html?function=etr_plot_recurrence")));
 assert.ok(hrefs.some(x=>x.url.includes("SITE_VALIDATION.html")));
 await page.locator("#matrixSearch").fill("");
 assert.equal(await page.locator("#workflowRows tr").count(),10);
 await page.locator("#matrixGrid").selectOption("async");
 assert.equal(await page.locator("#workflowRows tr").count(),1);
 await page.locator("#matrixGrid").selectOption("all");
 // Open browser atlas via a verified deep-linked plot, not generic index.
 await page.goto(base+"plot-atlas.html?function=etr_plot_sparse_mfpca_component",
   {waitUntil:"networkidle"});
 await page.waitForFunction(()=>window.ET_ATLAS_WAVE6?.getState().left==="etr_plot_sparse_mfpca_component");
 assert.ok(await page.locator("#mainImage").evaluate(async img=>{
  await img.decode();return img.naturalWidth>200;
 }));
 await page.goto(base+"research-portal.html",{waitUntil:"networkidle"});
 await page.screenshot({path:path.join(shots,"wave7-research-portal-desktop.png"),fullPage:true});

 // Real mobile layout, browser CSV sample, method selection, vertical scrolling.
 const mobile=await browser.newContext({viewport:{width:390,height:844},
   deviceScaleFactor:1,isMobile:true,hasTouch:true,acceptDownloads:true});
 const pm=await mobile.newPage();watch(pm);
 await pm.goto(base+"research-portal.html",{waitUntil:"networkidle"});
 await pm.locator("#sampleCSV").click();
 await pm.waitForFunction(()=>window.ET_RESEARCH_PORTAL_API.getState().auditAvailable);
 await pm.locator("#obsGrid").selectOption("paired");
 assert.ok((await pm.locator("#choiceName").innerText()).includes("Paired sparse"));
 const geom=await pm.evaluate(()=>({
  scrollWidth:document.documentElement.scrollWidth,
  innerWidth:window.innerWidth,
  tableWidth:document.querySelector(".table-scroll").scrollWidth,
  tableClient:document.querySelector(".table-scroll").clientWidth
 }));
 assert.ok(geom.scrollWidth<=geom.innerWidth+4,
   "Portal overflows mobile viewport: "+JSON.stringify(geom));
 assert.ok(geom.tableWidth>geom.tableClient,
   "Workflow comparison table should be independently horizontally scrollable");
 await pm.screenshot({path:path.join(shots,"wave7-research-portal-mobile.png"),fullPage:true});
 await mobile.close();await context.close();
 assert.deepEqual(errors,[],"Browser JS/HTTP errors or forbidden outgoing requests");
 console.log("WAVE7_BROWSER_PASS routes=10 local_csv=PASS csv_download=PASS"+
  " privacy=PASS wizard_refusals=PASS native_plot_deeplink=PASS mobile=PASS");
 console.log("WAVE7_VISUAL_EVIDENCE "+shots);
}finally{
 if(browser)await browser.close();
 await new Promise(resolve=>server.close(resolve));
}
