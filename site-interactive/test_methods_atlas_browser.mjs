#!/usr/bin/env node
/* Browser E2E for the scientific Methods Atlas and four R-generated studies.
 * No real participant data, backend models, external network or form upload. */
import assert from "node:assert/strict";
import fs from "node:fs/promises";
import http from "node:http";
import os from "node:os";
import path from "node:path";
import {chromium} from "playwright";

const root=path.resolve(process.argv[2]||"pkg/site");
const shots=path.resolve(process.argv[3]||path.join(os.tmpdir(),"et-methods-atlas-browser"));
await fs.mkdir(shots,{recursive:true});
const types={".html":"text/html; charset=utf-8",".js":"text/javascript; charset=utf-8",
 ".css":"text/css; charset=utf-8",".json":"application/json",
 ".png":"image/png",".svg":"image/svg+xml",".pdf":"application/pdf",
 ".R":"text/plain; charset=utf-8",".md":"text/plain; charset=utf-8"};
const server=http.createServer(async(req,res)=>{
 try{
  const name=decodeURIComponent(new URL(req.url,"http://localhost").pathname);
  const full=path.resolve(root,"."+name);
  if(!full.startsWith(root+path.sep)){res.writeHead(403);res.end();return}
  const bytes=await fs.readFile(full);
  res.writeHead(200,{"Content-Type":types[path.extname(full)]||"application/octet-stream",
    "Cache-Control":"no-store"});
  res.end(bytes);
 }catch(error){res.writeHead(error.code==="ENOENT"?404:500);res.end("Missing")}
});
await new Promise(resolve=>server.listen(0,"127.0.0.1",resolve));
const base="http://127.0.0.1:"+server.address().port+"/";
let browser;
const errors=[];
function watch(page){
 page.on("pageerror",e=>errors.push("JS "+e.message));
 page.on("request",req=>{
  const url=req.url();
  if(!url.startsWith(base)&&!url.startsWith("blob:")&&!url.startsWith("data:"))
   errors.push("Unexpected outgoing request "+url);
 });
 page.on("response",res=>{
  if(res.url().startsWith(base)&&res.status()>=400)
   errors.push("HTTP "+res.status()+" "+res.url());
 });
}
async function expectCount(page,expected){
 await page.waitForFunction(n=>window.ET_METHOD_ATLAS_API?.getState()?.shown===n,
   expected,{timeout:20000});
 const n=await page.evaluate(()=>window.ET_METHOD_ATLAS_API.getState().shown);
 assert.equal(n,expected);
}
try{
 browser=await chromium.launch({headless:true,args:["--no-sandbox"]});
 const context=await browser.newContext({viewport:{width:1440,height:960},
  deviceScaleFactor:1,acceptDownloads:true});
 const page=await context.newPage();watch(page);
 await page.goto(base+"methods-atlas.html",{waitUntil:"networkidle"});
 await page.waitForFunction(()=>window.ET_METHOD_ATLAS_API?.getState()?.total===904);
 const initial=await page.evaluate(()=>window.ET_METHOD_ATLAS_API.getState());
 assert.equal(initial.total,904);assert.equal(initial.curated,41);
 assert.equal(initial.shown,904);
 assert.equal(await page.locator("#results .method").count(),24);
 assert.match(await page.locator("#pageState").innerText(),/Page 1/);
 await page.screenshot({path:path.join(shots,"methods-atlas-desktop.png"),fullPage:true});
 await page.locator("#next").click();
 assert.match(await page.locator("#pageState").innerText(),/Page 2/);
 await page.locator("#previous").click();
 assert.match(await page.locator("#pageState").innerText(),/Page 1/);

 // Searching must select exactly the real exported R function, no guess.
 await page.locator("#search").fill("etr_fit_sparse_pace");
 await expectCount(page,1);
 assert.match(await page.locator("#results").innerText(),/fdapace/);
 assert.match(await page.locator("#results").innerText(),/Evidence curated/);
 assert.equal(await page.locator("#results .method").count(),1);
 await page.locator("#search").fill("");
 await page.locator("#review").selectOption("curated");
 await expectCount(page,41);
 await page.locator("#tier").selectOption("core");
 await expectCount(page,24);
 await page.locator("#backend").selectOption("native-R");
 await expectCount(page,24);
 await page.locator("#filters button[type=reset]").click();
 await expectCount(page,904);

 // Explicit source mapping; python-bridge API is not mislabeled native R.
 await page.locator("#backend").selectOption("python-bridge");
 await expectCount(page,383);
 assert.match(await page.locator("#results").innerText(),/Python bridge/i);
 await page.locator("#filters button[type=reset]").click();
 await expectCount(page,904);

 const mobile=await browser.newContext({viewport:{width:390,height:844},
  deviceScaleFactor:1,isMobile:true,hasTouch:true});
 const mpage=await mobile.newPage();watch(mpage);
 await mpage.goto(base+"methods-atlas.html",{waitUntil:"networkidle"});
 await mpage.waitForFunction(()=>window.ET_METHOD_ATLAS_API?.getState()?.total===904);
 await mpage.locator("#search").fill("etr_bootstrap_mean_band");
 await mpage.waitForFunction(()=>window.ET_METHOD_ATLAS_API.getState().shown===1);
 const overflow=await mpage.evaluate(()=>
    document.documentElement.scrollWidth-document.documentElement.clientWidth);
 assert(overflow<=2,"Mobile horizontal overflow "+overflow);
 await mpage.screenshot({path:path.join(shots,"methods-atlas-mobile.png"),fullPage:true});

 const workflow=await context.newPage();watch(workflow);
 await workflow.goto(base+"flagship-workflows.html",{waitUntil:"networkidle"});
 assert.equal(await workflow.locator(".workflow").count(),4);
 assert.equal(await workflow.locator("a[download][href$='.R']").count(),4);
 assert.equal(await workflow.locator(".workflow figure img").count(),4);
 const images=await workflow.locator(".workflow figure img").evaluateAll(
  nodes=>nodes.map(n=>({complete:n.complete,width:n.naturalWidth})));
 assert(images.every(im=>im.complete&&im.width>100),
   "Actual R-rendered figure previews must load");
 assert.match(await workflow.locator("body").innerText(),/synthetic/i);
 await workflow.screenshot({path:path.join(shots,"flagship-workflows-desktop.png"),
   fullPage:true});

 for(const name of ["01_complete_gaze_trajectory.R",
                    "02_multilevel_functional_variation.R",
                    "03_sparse_irregular_recovery.R",
                    "04_uncertainty_paired_contrast.R"]){
  const r=await context.request.get(base+"workflows/"+name);
  assert.equal(r.status(),200,name);
  assert.match(await r.text(),/FLAGSHIP/i,name);
 }
 for(const pathName of ["01-dense/01_planar_trajectories.pdf",
                        "02-multilevel/02_descriptive_variance.pdf",
                        "03-sparse/02_sparse_known_truth.pdf",
                        "04-uncertainty/01_paired_difference_bands.pdf"]){
  const resp=await context.request.get(base+"workflows/"+pathName);
  assert.equal(resp.status(),200,pathName);
  assert.equal((await resp.body()).subarray(0,5).toString(),"%PDF-",pathName);
 }
 assert.deepEqual(errors,[],"No external requests, broken routes or JS errors");
 console.log("METHOD_ATLAS_904_BROWSER_SEARCH_FILTER_MOBILE_FOUR_REAL_R_WORKFLOWS_PASS");
}finally{
 await browser?.close();
 await new Promise(resolve=>server.close(resolve));
}
