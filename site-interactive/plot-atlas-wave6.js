/* Wave 6: native R plotting atlas research comparison UI.
   Comparisons display pre-rendered figures, never recompute statistics.
   The underlying package is immutable eyetrajectories v0.4.3. */
(function(){
"use strict";
const rows=window.ET_PLOT_ATLAS_CATALOG||[];
const native=rows.filter(x=>x.backend==="Native R"&&x.variants?.length);
const byName=new Map(native.map(x=>[x.name,x]));
const $=id=>document.getElementById(id);
const CATEGORIES=[...new Set(rows.map(x=>x.category))].sort((a,b)=>a.localeCompare(b));
const family=$("family");
for(const name of CATEGORIES){
 const opt=document.createElement("option");opt.textContent=name;
 opt.value=name;family.append(opt);
}
const second=$("rightFunction"),variant=$("rightVariant");
const categories=[...new Set(native.map(x=>x.category))].sort((a,b)=>a.localeCompare(b));
for(const cat of categories){
 const group=document.createElement("optgroup");
 group.label=cat;
 for(const x of native.filter(z=>z.category===cat).sort((a,b)=>a.name.localeCompare(b.name))){
  const opt=document.createElement("option");opt.value=x.name;
  opt.textContent=x.name+"()";group.append(opt);
 }
 second.append(group);
}
let active=null,index=0,right=null,rightIndex=0,open=false;
function show(id,visible){$(id).classList.toggle("hidden",!visible);}
function clear(node){node.replaceChildren();}
function add(tag,parent,content,className){
 const el=document.createElement(tag);
 if(className)el.className=className;
 if(content!==undefined)el.textContent=content;
 parent.append(el);return el;
}
function renderGuide(entry,target){
 clear(target);
 if(!entry){add("p",target,"Select a plotting function to inspect its source signature.");return;}
 const title=entry.name+"()";
 add("h3",target,"Scientific parameter guide — "+title);
 add("p",target,entry.backend==="Native R"?
   "Arguments and defaults come from the released v0.4.3 R signature. Explanations are interpretive reminders, not substitute documentation.":
   "This optional Python-backed interface is not executed on this website. Read its reference before using it.");
 if(!entry.parameters?.length){
  add("p",target,"No native R formals are available for this interface.");return;
 }
 const list=add("dl",target,undefined,"parameter-list");
 for(const p of entry.parameters){
  const row=add("div",list,undefined,"parameter-row");
  const dt=add("dt",row);
  const code=add("code",dt,p.name);
  code.setAttribute("aria-label","Argument "+p.name);
  add("span",dt,p.default,"param-default");
  add("dd",row,p.explanation);
 }
 const more=add("p",target,"Read the exact R documentation for parameter constraints, input classes, time units, and statistical assumptions.","param-boundary");
}
function selectedRight(){
 const x=byName.get(second.value);
 if(!x)return null;
 const i=Math.max(0,Math.min(Number(variant.value)||0,x.variants.length-1));
 return {entry:x,i,preview:x.variants[i]};
}
function renderRight(){
 const x=byName.get(second.value);
 if(!x){show("rightFigure",false);return;}
 show("rightFigure",true);
 const previous=right;
 if(previous!==x.name){
  variant.replaceChildren();
  x.variants.forEach((v,i)=>{
   const opt=document.createElement("option");
   opt.value=String(i);opt.textContent=v.label;variant.append(opt);
  });
  right=x.name;rightIndex=0;variant.value="0";
 }else{
  rightIndex=Math.max(0,Math.min(rightIndex,x.variants.length-1));
  variant.value=String(rightIndex);
 }
 const v=x.variants[rightIndex];
 $("rightFunctionTitle").textContent=x.name+"()";
 $("rightCategory").textContent=x.category;
 $("rightImage").src=v.image;
 $("rightImage").alt="Synthetic, R-generated "+x.name+" plot: "+v.label;
 $("rightImageCaption").textContent=v.label+" · "+x.name+"()";
 $("rightDocs").href=x.doc;
 $("rightDocs").textContent=x.exactDoc?"Open function documentation":"Reference index";
 $("rightScript").href=v.script;
 $("rightScript").download=x.name+"__"+String(rightIndex+1)+".R";
 $("rightDownloadImage").href=v.image;
 $("rightDownloadImage").download=x.name+"__"+String(rightIndex+1)+".png";
 $("rightCode").textContent=v.code;
 renderGuide(x,$("rightParameters"));
 const same=active?.name===x.name;
 $("crossCaveat").textContent=same?
   "Same-function comparison: use independently selected variants; this is a rendering comparison, not a new fitted model.":
   "Methodological caution: the two example plots may use different synthetic fixtures, estimands, model assumptions, vertical axes or units. Side-by-side viewing is NOT a controlled performance comparison or evidence that either method is statistically validated.";
}
function renderLeft(){
 if(!active?.variants?.length){show("leftFigure",false);return;}
 show("leftFigure",true);
 const v=active.variants[index]||active.variants[0];
 $("leftFunctionTitle").textContent=active.name+"()";
 $("leftCategory").textContent=active.category;
 $("leftImage").src=v.image;
 $("leftImage").alt="Synthetic, R-generated "+active.name+" plot: "+v.label;
 $("leftImageCaption").textContent=v.label+" · "+active.name+"()";
}
function applyMode(){
 const yes=!!active?.variants?.length,enabled=open&&yes;
 show("crossCompare",enabled);
 $("compareFunctions").setAttribute("aria-pressed",String(enabled));
 $("compareFunctions").textContent=enabled?"Close function comparison":"Compare two functions";
 if(enabled){
  show("imageView",false);show("compareView",false);
  show("comparison",false);
 }else{
  // The original atlas's single-variant compare mode remains independent.
  if(yes){
   const oldVariants=$("comparison").textContent==="Single figure";
   show("imageView",!oldVariants);
   show("compareView",oldVariants);
   show("comparison",active.variants.length>=2);
  }
 }
}
function sync(entry,variantIndex){
 active=entry||null;index=Number(variantIndex)||0;
 if(active){
  const candidate=second.value;
  if(!byName.has(candidate)||(!right&&candidate===active.name)){
   const preferred=["etr_plot_fpca_component","etr_plot_recurrence",
                    "etr_plot_function_on_scalar_coefficients"]
                    .find(x=>byName.has(x)&&x!==active.name);
   second.value=preferred||native.find(x=>x.name!==active.name)?.name||active.name;
  }
  renderGuide(active,$("parameterGuide"));
  renderLeft();renderRight();
  show("downloadScript",!!active.variants?.length);
 }else{
  renderGuide(null,$("parameterGuide"));show("downloadScript",false);
  open=false;
 }
 applyMode();
}
$("compareFunctions").addEventListener("click",()=>{
 if(!active?.variants?.length)return;
 open=!open;renderLeft();renderRight();applyMode();
 if(open)$("rightFunction").focus();
});
second.addEventListener("change",()=>{right=null;rightIndex=0;renderRight();});
variant.addEventListener("change",()=>{
 rightIndex=Math.max(0,Number(variant.value)||0);renderRight();
});
$("swapFunctions").addEventListener("click",()=>{
 const r=selectedRight();
 if(!r||!active)return;
 // A swap is a user selection: the existing main catalogue remains
 // authoritative. Expose only this explicitly triggered callback.
 const saved=active.name;
 document.dispatchEvent(new CustomEvent("et-atlas-choose-primary",
   {detail:{name:r.entry.name}}));
 second.value=saved;right=null;rightIndex=0;renderRight();
});
$("downloadScript").setAttribute("aria-label","Download the selected, version-pinned R reproduction script");
$("parameterGuide").setAttribute("aria-live","polite");
$("crossCompare").setAttribute("aria-live","polite");
const api={
 sync,
 choosePrimary:null,
 getState:()=>({left:active?.name||null,right:second.value,
   open,variant:index,rightVariant:rightIndex})
};
window.ET_ATLAS_WAVE6=api;
const selected=$("functionName").textContent.replace(/\(\)$/,"");
const start=rows.find(x=>x.name===selected)||native[0]||null;
sync(start,Number($("variant").value)||0);
})();