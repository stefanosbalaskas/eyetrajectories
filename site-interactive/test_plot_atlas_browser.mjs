#!/usr/bin/env node
// Wave 6 actual Chromium interaction, visual structure and R script downloads.
// No participant data; the fixture gallery was generated in native R first.
import assert from "node:assert/strict";
import fs from "node:fs/promises";
import http from "node:http";
import os from "node:os";
import path from "node:path";
import {fileURLToPath} from "node:url";
import {chromium} from "playwright";

const root=path.resolve(process.argv[2]||"pkg/site");
const shots=path.resolve(process.argv[3]||path.join(os.tmpdir(),"eyetrajectories-wave6-browser"));
await fs.mkdir(shots,{recursive:true});
const mime={".html":"text/html; charset=utf-8",".js":"text/javascript; charset=utf-8",
 ".css":"text/css; charset=utf-8",".png":"image/png",".svg":"image/svg+xml",
 ".R":"text/plain; charset=utf-8",".txt":"text/plain; charset=utf-8"};
const server=http.createServer(async(req,res)=>{
 try{
  const pathname=decodeURIComponent(new URL(req.url,"http://localhost").pathname);
  const file=path.resolve(root,"."+pathname);
  if(!file.startsWith(root+path.sep)){res.writeHead(403);res.end();return;}
  const data=await fs.readFile(file);
  res.setHeader("Content-Type",mime[path.extname(file)]||"application/octet-stream");
  res.setHeader("Cache-Control","no-store");
  res.writeHead(200);res.end(data);
 }catch(err){res.writeHead(err.code==="ENOENT"?404:500);res.end("Not found");}
});
await new Promise(resolve=>server.listen(0,"127.0.0.1",resolve));
const base="http://127.0.0.1:"+server.address().port+"/";
let browser;
const failures=[];
function monitor(page){
 page.on("pageerror",error=>failures.push("pageerror: "+error.message));
 page.on("response",res=>{
  if(res.url().startsWith(base)&&res.status()>=400)
   failures.push("HTTP "+res.status()+" "+res.url());
 });
}
async function checkImage(page,id){
 return page.locator("#"+id).evaluate(async img=>{
  await img.decode();
  return img.naturalWidth>100&&img.naturalHeight>100;
 });
}
function filenameDownload(download){return download.suggestedFilename();}
try{
 browser=await chromium.launch({headless:true,args:["--no-sandbox"]});
 const context=await browser.newContext({viewport:{width:1440,height:930},
   acceptDownloads:true,deviceScaleFactor:1});
 const page=await context.newPage();
 monitor(page);
 await page.goto(base+"plot-atlas.html",{waitUntil:"networkidle"});
 await page.waitForFunction(()=>window.ET_ATLAS_WAVE6?.getState()?.left);
 const initial=await page.evaluate(()=>({
  native:document.getElementById("nativeCount").textContent,
  bridge:document.getElementById("pythonCount").textContent,
  illustrated:document.getElementById("previewCount").textContent,
  figures:document.getElementById("figureCount").textContent,
  categories:[...document.querySelectorAll("#family option")].slice(1).map(x=>x.value),
  current:window.ET_ATLAS_WAVE6.getState().left,
  params:document.querySelectorAll("#parameterGuide .parameter-row").length
 }));
 assert.equal(initial.native,"81");
 assert.equal(initial.bridge,"79");
 assert.equal(initial.illustrated,"81");
 assert.ok(Number(initial.figures)>=108);
 assert.ok(initial.categories.length>=11,"Missing scientific categories");
 assert.ok(initial.params>0,"Source-arg guide missing");
 assert.ok(initial.current.startsWith("etr_plot_"));

 // Native source metadata, direct images and downloadable scripts:
 const inventory=await page.evaluate(()=>window.ET_PLOT_ATLAS_CATALOG);
 const native=inventory.filter(x=>x.backend==="Native R");
 const optional=inventory.filter(x=>x.backend==="Python-backed");
 assert.equal(native.length,81);assert.equal(optional.length,79);
 assert.ok(native.every(x=>x.variants.length>0&&x.parameters.length>0));
 assert.ok(optional.every(x=>x.variants.length===0));
 const variants=native.flatMap(x=>x.variants);
 assert.equal(variants.length,Number(initial.figures));
 for(const x of variants){
  assert.ok(x.script?.startsWith("plot-atlas/scripts/"));
  assert.ok(x.code.includes('packageVersion("eyetrajectories")'));
 }
 // Decode every preview in bounded batches, ensuring browsers, not only
 // Node's PNG magic-byte check, can display all native R artwork.
 for(let i=0;i<variants.length;i+=10){
  const paths=variants.slice(i,i+10).map(x=>x.image);
  const decoded=await page.evaluate(async(paths)=>{
   return Promise.all(paths.map(src=>new Promise(resolve=>{
    const img=new Image();
    img.onload=()=>resolve(img.naturalWidth>200&&img.naturalHeight>200);
    img.onerror=()=>resolve(false);img.src=src;
   })));
  },paths);
  assert.ok(decoded.every(Boolean),"A native R PNG cannot be decoded by Chromium");
 }
 console.log("WAVE6_ALL_NATIVE_IMAGES_DECODED="+variants.length);

 await page.locator("#family").selectOption("Functional regression");
 let count=await page.locator("#results .entry").count();
 assert.ok(count>=5&&count<81,"Category should filter to regression functions");
 let categories=await page.locator("#results .entry small").allTextContents();
 assert.ok(categories.every(x=>x==="Functional regression"));
 await page.locator("#family").selectOption("all");
 await page.locator("#search").fill("etr_plot_fpca_component");
 assert.ok(await page.locator("#results .entry").count()>=1);
 await page.locator("#results .entry").filter({hasText:"etr_plot_fpca_component()"}).first().click();
 await page.waitForFunction(()=>window.ET_ATLAS_WAVE6?.getState().left==="etr_plot_fpca_component");
 assert.ok(await checkImage(page,"mainImage"));
 assert.ok(await page.locator("#parameterGuide .parameter-row").count()>=2);
 const paramText=await page.locator("#parameterGuide").innerText();
 assert.ok(paramText.includes("component"),"FPCA component parameter not explained");

 // Preserve existing within-function variant comparison.
 await page.locator("#comparison").click();
 assert.ok(await page.locator("#compareView figure").count()>=2);
 await page.locator("#comparison").click();

 // New cross-function, two actual, independent native R visuals.
 await page.locator("#compareFunctions").click();
 assert.equal(await page.locator("#compareFunctions").getAttribute("aria-pressed"),"true");
 await page.locator("#rightFunction").selectOption("etr_plot_recurrence");
 await page.locator("#rightVariant").selectOption("1");
 const state=await page.evaluate(()=>window.ET_ATLAS_WAVE6.getState());
 assert.equal(state.left,"etr_plot_fpca_component");
 assert.equal(state.right,"etr_plot_recurrence");
 assert.equal(state.rightVariant,1);
 assert.ok(await checkImage(page,"leftImage"));
 assert.ok(await checkImage(page,"rightImage"));
 assert.ok((await page.locator("#crossCaveat").innerText()).includes("NOT a controlled"));
 assert.ok((await page.locator("#rightParameters .parameter-row").count())>=1);

 // Compare distinct documents and reproducible self-contained scripts.
 const d1=page.waitForEvent("download");
 await page.locator("#downloadScript").click();
 const download=await d1;
 assert.ok(filenameDownload(download).endsWith(".R"));
 const leftText=await fs.readFile(await download.path(),"utf8");
 assert.ok(leftText.includes("etr_plot_fpca_component("));
 assert.ok(leftText.includes('packageVersion("eyetrajectories")'));
 const d2=page.waitForEvent("download");
 await page.locator("#rightScript").click();
 const rightDownload=await d2;
 const rightText=await fs.readFile(await rightDownload.path(),"utf8");
 assert.ok(rightText.includes("etr_plot_recurrence("));

 await page.locator("#swapFunctions").click();
 await page.waitForFunction(()=>window.ET_ATLAS_WAVE6.getState().left==="etr_plot_recurrence");
 assert.equal(await page.locator("#functionName").innerText(),"etr_plot_recurrence()");
 await page.locator("#compareFunctions").click();
 assert.equal(await page.locator("#compareFunctions").getAttribute("aria-pressed"),"false");
 assert.ok(await page.locator("#imageView").isVisible());
 await page.screenshot({path:path.join(shots,"wave6-atlas-desktop.png"),fullPage:true});

 // Search empty-state behavior, then recover a real preview.
 await page.locator("#search").fill("wave6_impossible_function_qxh");
 assert.ok(await page.locator("#no-preview").isVisible());
 assert.ok(!(await page.locator("#downloadScript").isVisible()));
 await page.locator("#search").fill("");
 assert.ok(await page.locator("#downloadScript").isVisible());

 // Responsive and keyboard interaction on mobile viewport.
 const mobile=await browser.newContext({viewport:{width:390,height:844},
   deviceScaleFactor:1,acceptDownloads:true,isMobile:true,hasTouch:true});
 const pageM=await mobile.newPage();monitor(pageM);
 await pageM.goto(base+"plot-atlas.html",{waitUntil:"networkidle"});
 await pageM.locator("#compareFunctions").focus();
 await pageM.keyboard.press("Enter");
 assert.equal(await pageM.locator("#compareFunctions").getAttribute("aria-pressed"),"true");
 await pageM.locator("#rightFunction").selectOption("etr_plot_recurrence");
 assert.ok(await checkImage(pageM,"leftImage"));
 assert.ok(await checkImage(pageM,"rightImage"));
 const geom=await pageM.evaluate(()=>{
  const a=document.querySelector("#leftFigure").getBoundingClientRect();
  const b=document.querySelector("#rightFigure").getBoundingClientRect();
  return {scroll:document.documentElement.scrollWidth,
    viewport:window.innerWidth,first:{x:a.x,y:a.y,w:a.width},
    second:{x:b.x,y:b.y,w:b.width}};
 });
 assert.ok(geom.scroll<=geom.viewport+4,
   "Mobile layout has horizontal overflow: "+JSON.stringify(geom));
 assert.ok(geom.second.y>geom.first.y+100,
   "Cross-function cards should stack on narrow screens");
 await pageM.screenshot({path:path.join(shots,"wave6-atlas-mobile.png"),fullPage:true});
 await mobile.close();await context.close();
 assert.deepEqual(failures,[],"Browser JavaScript/HTTP failures");
 console.log("WAVE6_BROWSER_PASS native=81 bridge=79 categories="+initial.categories.length+
   " figures="+variants.length+" script_downloads=2 comparisons=2 mobile=PASS");
 console.log("WAVE6_BROWSER_SCREENSHOTS "+shots);
}finally{
 if(browser)await browser.close();
 await new Promise(resolve=>server.close(resolve));
}
