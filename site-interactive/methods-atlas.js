/* Source-verified v0.4.3 method explorer. Static local JS, no network. */
(function(){"use strict";
const reg=window.ET_METHOD_REGISTRY;
if(!reg||reg.schema!=="eyetrajectories-method-registry/v1"||
   reg.release!=="v0.4.3"||reg.total_exports!==904||
   !Array.isArray(reg.methods)||reg.methods.length!==904)
  throw Error("Method registry missing or invalid: refusing to misrepresent the API");
const $=id=>document.getElementById(id);
const perPage=24;
let page=0,visible=reg.methods.slice();
const text=(el,value)=>{el.textContent=String(value??"");return el};
function elem(tag,parent,content,cls){
 const e=document.createElement(tag);if(cls)e.className=cls;
 if(content!==undefined)text(e,content);
 if(parent)parent.append(e);return e;
}
function anchor(parent,label,href){
 const a=elem("a",parent,label);a.href=href;return a;
}
function tag(parent,label,cls){
 return elem("span",parent,label,"tag "+(cls||""));
}
function normalize(v){return String(v||"").toLocaleLowerCase("en");}
function update(){
 const q=normalize($("search").value.trim());
 const tier=$("tier").value,backend=$("backend").value,review=$("review").value;
 visible=reg.methods.filter(m=>
  (tier==="all"||m.tier===tier) &&
  (backend==="all"||m.backend===backend) &&
  (review==="all"||m.classification_basis===review) &&
  (!q||[m.name,m.family,m.caveat,m.evidence_status,m.backend].some(v=>normalize(v).includes(q)))
 );
 page=Math.min(page,Math.max(0,Math.ceil(visible.length/perPage)-1));
 render();
}
function render(){
 const root=$("results");root.replaceChildren();
 const start=page*perPage;
 const slice=visible.slice(start,start+perPage);
 for(const m of slice){
  const card=elem("article",root,undefined,"method");
  const h=elem("h3",card);
  text(h,m.name);
  const metadata=elem("div",card,undefined,"meta");
  tag(metadata,m.tier,m.tier);
  tag(metadata,m.backend);
  tag(metadata,m.classification_basis==="curated"?"Evidence curated":"Provisional role");
  elem("p",card,m.family);
  const strong=elem("p",card);
  const strongLabel=elem("strong",strong,"Evidence: ");
  text(strong, "");strong.append(strongLabel,
       document.createTextNode(m.evidence_status.replaceAll("_"," ")));
  elem("p",card,m.caveat);
  const actions=elem("div",card,undefined,"actions");
  anchor(actions,"R documentation",m.reference_href||"reference/index.html");
  if(m.evidence){
    const evidence=String(m.evidence);
    if(/^docs\/[a-zA-Z0-9_./-]+\.md$/.test(evidence))
      anchor(actions,"Recorded evidence",
        "https://github.com/stefanosbalaskas/eyetrajectories/blob/main/"+evidence);
  }
  elem("span",card,m.classification_basis==="curated"?
   "Curated interpretation of published API (not full certification).":
   "Provisional lexical classification; method evidence not yet curated.",
   "review");
 }
 if(!slice.length)elem("div",root,
    "No matching method. Try a broader query or reset the filters.","empty");
 const count=visible.length;
 const nPages=Math.max(1,Math.ceil(count/perPage));
 text($("count"),count+" matching exported interfaces · "+reg.curated+
   " curated evidence entries of "+reg.total_exports+" source exports.");
 text($("bottomCount"),count+" records match");
 text($("pageState"),"Page "+(page+1)+" / "+nPages);
 const disabledPrev=page===0,disabledNext=page+1>=nPages;
 for(const name of ["previous","previousBottom"])$(name).disabled=disabledPrev;
 for(const name of ["next","nextBottom"])$(name).disabled=disabledNext;
}
function turn(diff){page+=diff;render();$("count").scrollIntoView({block:"nearest"});}
const form=$("filters");
form.addEventListener("submit",e=>e.preventDefault());
$("search").addEventListener("input",()=>{page=0;update();});
for(const id of ["tier","backend","review"])
 $(id).addEventListener("change",()=>{page=0;update();});
form.addEventListener("reset",()=>{
 for(const id of ["search","tier","backend","review"])
   $(id).value=id==="search"?"":"all";
 page=0;update();
});
for(const id of ["previous","previousBottom"])
 $(id).addEventListener("click",()=>turn(-1));
for(const id of ["next","nextBottom"])
 $(id).addEventListener("click",()=>turn(1));
text($("totalExports"),reg.total_exports);
text($("curatedCount"),reg.curated);
text($("provisionalCount"),reg.provisional);
update();
window.ET_METHOD_ATLAS_API={
 getState:()=>({shown:visible.length,page,total:reg.total_exports,curated:reg.curated}),
 filter:(q,t="all",b="all",r="all")=>{
   $("search").value=q;$("tier").value=t;$("backend").value=b;
   $("review").value=r;page=0;update();return visible.length;
 }
};
})();
