#!/usr/bin/env node
// Offline browser-DOM smoke test of the standalone educational methods lab.
// Does not assert numerical parity with native R or independently validate estimators.
"use strict";
const assert=require("node:assert/strict");
const fs=require("node:fs");
const vm=require("node:vm");
const file=process.argv[2];
assert(file,"Usage: node test_methods_laboratory.cjs <path/to/methods-laboratory.html>");
const html=fs.readFileSync(file,"utf8");
const script=html.match(/<script>([\s\S]*?)<\/script>/)?.[1];
assert(script,"Script missing from laboratory");
new vm.Script(script,{filename:"methods-laboratory.js"}); // syntax check

const nodes=new Map();
const invalid=[];
let exported="";
const methods=["fpca","dtw","rqa"];
for(const match of html.matchAll(/<[a-zA-Z][^>]*\bid="([^"]+)"[^>]*>/g)){
  const [tag,id]=match;
  const value=tag.match(/\bvalue="([^"]+)"/)?.[1]||({"rqa-model":"orbit"}[id])||"";
  const node={
    id,value,textContent:"",checked:tag.includes("checked"),tabIndex:0,
    listeners:{},attributes:{},style:{},
    classList:{toggle(){}},
    setAttribute(key,val){this.attributes[key]=val;},
    getBoundingClientRect(){return{width:680,height:id==="primary"?310:220};},
    addEventListener(event,handler){this.listeners[event]=handler;},
    focus(){},
  };
  if(id==="primary"||id==="secondary"){
    node.getContext=function(){
      const check=(type,coords)=>{
        if(!coords.every(Number.isFinite)) invalid.push(id+" "+type+" "+String(coords));
      };
      return {
        setTransform(){},clearRect(){},beginPath(){},stroke(){},fill(){},save(){},restore(){},
        moveTo(x,y){check("moveTo",[x,y]);},
        lineTo(x,y){check("lineTo",[x,y]);},
        fillRect(x,y,w,h){check("fillRect",[x,y,w,h]);},
        fillText(text,x,y){check("fillText",[x,y]);},
        arc(x,y,r){check("arc",[x,y,r]);},
        translate(x,y){check("translate",[x,y]);},
        rotate(a){check("rotate",[a]);},
      };
    };
  }
  nodes.set(id,node);
}
const element=id=>{
  assert(nodes.has(id),"Missing DOM element #"+id);
  return nodes.get(id);
};
const document={
  getElementById:element,
  body:{appendChild(){}},
  createElement(){return{set href(v){},set download(v){},click(){},remove(){}};}
};
const browser={
  devicePixelRatio:1,
  addEventListener(){},
};
class FakeBlob{
  constructor(parts){this.parts=parts;}
}
const mockURL={
  createObjectURL(blob){exported=blob.parts.join("");return"blob:test";},
  revokeObjectURL(){}
};
const queueFrame=callback=>{callback(1);return 1;};
const context={
  document,
  window:browser,
  Blob:FakeBlob,
  URL:mockURL,
  requestAnimationFrame:queueFrame,
  setTimeout:(callback)=>callback(),
};
vm.runInNewContext(script,context,{filename:"methods-laboratory.js",timeout:20000});
const click=id=>{
  const fn=element(id).listeners.click;assert(fn,"Missing click listener "+id);fn();
};
const input=(id,value)=>{
  element(id).value=String(value);
  const fn=element(id).listeners.input;assert(fn,"Missing input listener "+id);fn();
};
const stat=i=>Number.parseFloat(element("stat-"+i).textContent);
const finiteStats=()=>{
  for(let i=1;i<=3;i++) assert(Number.isFinite(stat(i)),"Nonfinite metric "+i+" under "+element("method-title").textContent);
};
finiteStats();
assert(stat(1)>1&&stat(1)<100,"FPCA component variance is outside credible range");
input("fpca-k",1);const error1=stat(3);
input("fpca-k",3);const error3=stat(3);
assert(error3<=error1+.002,"FPCA reconstruction should improve or remain stable when retaining more components");

click("tab-dtw");
finiteStats();
assert.equal(element("tab-dtw").attributes["aria-selected"],"true");
input("dtw-phase",0);
assert(Math.abs(stat(1))<.001,"Identical same-phase signals must have zero simultaneous difference");
assert(Math.abs(stat(2))<.001,"Identical same-phase signals must have zero DTW cost");
input("dtw-phase",.3);
assert(stat(1)>0.05,"Shifting phase should increase simultaneous difference");
assert(stat(2)>=0,"DTW cost should be nonnegative");
input("dtw-samples",121);
finiteStats();

click("tab-rqa");
finiteStats();
input("rqa-radius",.08);const smallRadius=stat(1);
input("rqa-radius",.30);const largeRadius=stat(1);
assert(largeRadius>=smallRadius,"Recurrence rate must be nondecreasing as radius increases");
assert(stat(2)>=0&&stat(2)<=100,"DET must be in 0-100%");
for(const model of ["figure","drift","orbit"]){
 input("rqa-model",model);
 finiteStats();
}
click("export");
assert(exported.startsWith("time,x,y\n"),"Expected recurrence CSV content");
assert(exported.split("\n").length>=52,"CSV should contain observations");
click("reset");
assert.equal(element("rqa-radius").value,".16","Reset should restore the threshold");
assert.equal(invalid.length,0,"Nonfinite canvas coordinates: "+invalid.slice(0,5).join("; "));
for(const m of methods){
 assert(element("panel-"+m),"Missing tabpanel "+m);
 assert(element("tab-"+m),"Missing tab "+m);
}
console.log("METHODS_LAB_SMOKE_PASS: FPCA reconstruction, DTW alignment, RQA thresholds, tab state, reset, CSV and finite canvas coordinates");
