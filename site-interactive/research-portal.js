/* Wave 7 research navigator, v0.4.3 scientific website overlay.
 * All CSV data processing occurs in this tab. No fetch, XHR,
 * WebSocket, analytics, localStorage or remote R/Python execution. */
(function(){
"use strict";
const dataset=window.ET_RESEARCH_PORTAL;
if(!dataset||dataset.workflows?.length!==10)throw Error("Versioned workflow catalogue unavailable");
const entries=dataset.workflows;
const byId=new Map(entries.map(x=>[x.id,x]));
const $=id=>document.getElementById(id);
const maxChars=1200000,maxRows=12000;
let audit=null,selectedRoute=null;
function el(tag,parent,value,cls){
 const x=document.createElement(tag);
 if(cls)x.className=cls;
 if(value!==undefined)x.textContent=value;
 if(parent)parent.append(x);
 return x;
}
function link(parent,text,href){
 const a=el("a",parent,text);a.href=href;return a;
}
function setStatus(message,type){
 $("csvStatus").textContent=message;
 $("csvStatus").className="status"+(type?" "+type:"");
}
function parseCSV(text){
 if(typeof text!=="string"||text.length===0)throw Error("Provide nonempty CSV text.");
 if(text.length>maxChars)throw Error("CSV exceeds 1.2 million characters; inspect a smaller file locally.");
 text=text.replace(/^\uFEFF/,"");
 const rows=[];let row=[],field="",inQuotes=false,closed=false;
 function pushField(){
  row.push(field);field="";closed=false;
  if(row.length>60)throw Error("CSV has more than 60 columns; use an appropriate long-format extract.");
 }
 function pushRow(){
  pushField();
  if(row.length>1||row[0].trim()!=="")rows.push(row);
  row=[];
  if(rows.length>maxRows+1)throw Error("CSV has more than 12,000 data rows.");
 }
 for(let i=0;i<text.length;i++){
  const c=text[i],n=text[i+1];
  if(inQuotes){
   if(c==='"'){
    if(n==='"'){field+='"';i++;}
    else{inQuotes=false;closed=true;}
   }else field+=c;
  }else if(c==='"'){
   if(field.length!==0||closed)throw Error("Malformed CSV quoting near a field boundary.");
   inQuotes=true;
  }else if(c===",")pushField();
  else if(c==="\n"||c==="\r"){
   pushRow();if(c==="\r"&&n==="\n")i++;
  }else{
   if(closed&&c!==" "&&c!=="\t")throw Error("Unexpected text after a closing CSV quote.");
   field+=c;
  }
 }
 if(inQuotes)throw Error("Unclosed quoted CSV cell.");
 if(field.length||closed||row.length)pushRow();
 if(rows.length<2)throw Error("CSV needs a header and at least one data row.");
 const header=rows.shift().map(x=>x.trim());
 if(new Set(header).size!==header.length||header.some(x=>!x))
  throw Error("CSV header names must be nonempty and unique.");
 const required=["participant_id","trial_id","x","y"];
 for(const name of required)if(!header.includes(name))
  throw Error("Missing required column: "+name);
 const timeCols=["time_s","time_ms","time"].filter(x=>header.includes(x));
 if(timeCols.length!==1)throw Error("Declare exactly one time column: time_s, time_ms or time.");
 for(let i=0;i<rows.length;i++)
  if(rows[i].length!==header.length)
   throw Error("CSV row "+(i+2)+" has "+rows[i].length+" values, expected "+header.length+".");
 const idx=Object.fromEntries(header.map((k,i)=>[k,i]));
 return {header,rows,idx,timeColumn:timeCols[0]};
}
function isMissing(x){return x===""||/^(na|nan|null|missing)$/i.test(x.trim());}
function numeric(x){
 const v=x.trim();
 if(isMissing(v))return {missing:true,value:null,invalid:false};
 if(!/^[+-]?(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?$/.test(v))
  return {missing:false,value:null,invalid:true};
 const n=Number(v);
 return Number.isFinite(n)?{missing:false,value:n,invalid:false}:
  {missing:false,value:null,invalid:true};
}
function inspectCSV(text,units,coordinate){
 const p=parseCSV(text),{rows,idx,timeColumn}=p;
 const groups=new Map(),participants=new Map();
 const metric={rows:rows.length,participants:0,trials:0,repeatedParticipants:0,
  missingX:0,missingY:0,missingBoth:0,onlyX:0,onlyY:0,
  invalidCoordinate:0,invalidTime:0,invalidIds:0,duplicateTimes:0,
  outOfOrder:0,pairedValid:0,commonGrid:false,
  timeUnit:units,coordinateUnit:coordinate,timeHeader:timeColumn,
  minGroupRows:0,maxGroupRows:0};
 for(const row of rows){
  const pid=row[idx.participant_id].trim(),tid=row[idx.trial_id].trim();
  if(!pid||!tid){metric.invalidIds++;continue;}
  const key=JSON.stringify([pid,tid]);
  let g=groups.get(key);
  if(!g){g={times:[],seen:new Set(),n:0,complete:0,last:null};groups.set(key,g);}
  if(!participants.has(pid))participants.set(pid,new Set());
  participants.get(pid).add(tid);
  g.n++;
  const t=numeric(row[idx[timeColumn]]),
        x=numeric(row[idx.x]),y=numeric(row[idx.y]);
  if(t.invalid||t.missing)metric.invalidTime++;
  else{
   if(g.seen.has(t.value))metric.duplicateTimes++;
   if(g.last!==null&&t.value<g.last)metric.outOfOrder++;
   g.seen.add(t.value);g.times.push(t.value);g.last=t.value;
  }
  if(x.missing)metric.missingX++;
  if(y.missing)metric.missingY++;
  if(x.missing&&y.missing)metric.missingBoth++;
  if(!x.missing&&!x.invalid&&y.missing)metric.onlyX++;
  if(!y.missing&&!y.invalid&&x.missing)metric.onlyY++;
  if(x.invalid)metric.invalidCoordinate++;
  if(y.invalid)metric.invalidCoordinate++;
  if(!x.missing&&!y.missing&&!x.invalid&&!y.invalid){
   metric.pairedValid++;g.complete++;
  }
 }
 metric.participants=participants.size;metric.trials=groups.size;
 metric.repeatedParticipants=[...participants.values()].filter(s=>s.size>1).length;
 const gg=[...groups.values()];
 metric.minGroupRows=gg.length?Math.min(...gg.map(x=>x.n)):0;
 metric.maxGroupRows=gg.length?Math.max(...gg.map(x=>x.n)):0;
 const signatures=gg.map(g=>g.times.slice().sort((a,b)=>a-b).join("\u001f"));
 metric.commonGrid=gg.length>0&&gg.every(g=>g.n>=2&&g.n===g.complete&&g.times.length===g.n)
  &&new Set(signatures).size===1&&metric.duplicateTimes===0&&
  metric.outOfOrder===0&&metric.invalidTime===0&&metric.invalidIds===0&&
  metric.invalidCoordinate===0;
 const warnings=[];
 if(units==="unknown")warnings.push("Time units are undeclared; the inspector never guesses whether a number means seconds or milliseconds.");
 if(coordinate==="unknown")warnings.push("Coordinate units are undeclared; comparisons may not share a physical scale.");
 if(timeColumn==="time_s"&&units!=="seconds")warnings.push("Header time_s denotes seconds but the declared time unit is not seconds; verify and correct the source metadata.");
 if(timeColumn==="time_ms"&&units!=="milliseconds")warnings.push("Header time_ms denotes milliseconds but the declared unit differs; verify metadata.");
 if(metric.invalidIds)warnings.push(metric.invalidIds+" rows have missing participant/trial IDs; these cannot be safely assigned to a curve.");
 if(metric.invalidTime)warnings.push(metric.invalidTime+" rows have missing or nonfinite/non-numeric timestamps.");
 if(metric.invalidCoordinate)warnings.push(metric.invalidCoordinate+" coordinate cells contain invalid nonnumeric values (missing tokens are counted separately).");
 if(metric.duplicateTimes)warnings.push(metric.duplicateTimes+" repeated timestamps occur within recorded participant/trial curves.");
 if(metric.outOfOrder)warnings.push(metric.outOfOrder+" decreasing time steps occur in original row order; no sorting was applied to the data.");
 if(metric.missingX||metric.missingY)
  warnings.push("Missing x/y observations are explicitly counted and never replaced with zero or interpolated.");
 if(metric.onlyX||metric.onlyY)
  warnings.push("Only-one-channel rows do not establish asynchronous sensor acquisition: original channel-specific timestamps and measurement process must be verified.");
 if(metric.repeatedParticipants)
  warnings.push("Repeated trials are nested in participants. A naive independent-curve analysis may misstate uncertainty.");
 if(!metric.commonGrid)
  warnings.push("The observed x/y support is not a complete common time grid across all valid curves. This is not proof that a particular sparse estimator is appropriate.");
 if(metric.commonGrid)warnings.push("Common-grid compatibility is structural only; calibrations, smoothing, power and inference remain unassessed.");
 const summary={schema:"eyetrajectories-browser-structural-preflight/v1",source:"Browser-local aggregate; no participant/trial IDs or raw coordinates",
  ...metric,warnings};
 return summary;
}
function metric(parent,label,value){
 const box=el("div",parent,undefined,"metric");
 el("strong",box,String(value));el("span",box,label);
}
function displayAudit(a){
 const root=$("preflightReport");root.replaceChildren();
 el("h4",root,"Structural assessment");
 el("div",root,a.commonGrid?
  "Observed common-grid shape: compatible for further dense-model screening, not scientifically qualified.":
  "Not a fully observed common grid: examine missingness, timing and channel-support constraints.","verdict");
 const m=el("div",root,undefined,"metrics");
 metric(m,"Data rows",a.rows);metric(m,"Participants",a.participants);
 metric(m,"Participant/trial curves",a.trials);metric(m,"Repeated participants",a.repeatedParticipants);
 metric(m,"x missing",a.missingX);metric(m,"y missing",a.missingY);
 metric(m,"Within-curve duplicate times",a.duplicateTimes);
 metric(m,"Out-of-order time steps",a.outOfOrder);
 metric(m,"Invalid numeric/IDs",a.invalidCoordinate+a.invalidTime+a.invalidIds);
 const h=el("h4",root,"Interpretation and warnings");
 const ul=el("ul",root);
 for(const w of a.warnings)el("li",ul,w);
 el("p",root,"Preflight does not read calibration files, classify fixations/AOIs, estimate effects, infer MNAR mechanisms or run R/Python. No raw observations are retained in the exported summary.");
}
function clearAudit(){
 audit=null;$("exportAudit").disabled=true;$("applyStructure").disabled=true;
 $("preflightReport").replaceChildren(el("p",null,"No local data has been inspected yet."));
}
const sample=[
"participant_id,trial_id,time_s,x,y",
"P01,T01,0,0.43,0.31","P01,T01,0.5,0.48,0.36","P01,T01,1,0.52,0.40",
"P01,T02,0,0.41,0.32","P01,T02,0.5,0.47,0.35","P01,T02,1,0.55,0.41",
"P02,T01,0,0.36,0.39","P02,T01,0.5,0.43,0.42","P02,T01,1,0.49,0.47"].join("\n");
$("sampleCSV").addEventListener("click",()=>{
 $("csvFile").value="";$("csvPaste").value=sample;
 $("timeUnit").value="seconds";$("coordUnit").value="normalized";
 $("preflightForm").requestSubmit();
});
$("clearCSV").addEventListener("click",()=>{
 $("csvFile").value="";$("csvPaste").value="";
 $("timeUnit").value="unknown";$("coordUnit").value="unknown";
 clearAudit();setStatus("Local input cleared. The next inspection uses only newly supplied data.");
});
$("preflightForm").addEventListener("submit",async event=>{
 event.preventDefault();clearAudit();
 try{
  const file=$("csvFile").files?.[0],typed=$("csvPaste").value;
  if(file&&typed.trim())throw Error("Choose either a file or pasted CSV. Clear one input to avoid accidental use of the wrong data.");
  if(file&&file.size>maxChars*4)throw Error("CSV file exceeds the local preflight size limit.");
  const content=file?await file.text():typed;
  audit=inspectCSV(content,$("timeUnit").value,$("coordUnit").value);
  $("exportAudit").disabled=false;
  $("applyStructure").disabled=audit.participants===0||audit.invalidIds>0;
  displayAudit(audit);setStatus("Browser-only structural inspection completed for "+audit.rows+" rows. No raw gaze data was uploaded.","success");
 }catch(e){clearAudit();setStatus("Inspection blocked: "+e.message,"error");}
});
$("exportAudit").addEventListener("click",()=>{
 if(!audit)return;
 const blob=new Blob([JSON.stringify(audit,null,2)+"\n"],{type:"application/json"});
 const url=URL.createObjectURL(blob),a=el("a",document.body);
 a.href=url;a.download="eyetrajectories_structural_preflight_summary.json";
 a.click();a.remove();setTimeout(()=>URL.revokeObjectURL(url),4000);
});
$("applyStructure").addEventListener("click",()=>{
 if(!audit)return;
 $("obsGrid").value=audit.commonGrid?"dense":"unknown";
 $("studyHierarchy").value=audit.repeatedParticipants?"repeated":"independent";
 renderWizard();$("selector").scrollIntoView({block:"start"});
});
// Native R mapping is a scientific navigator, never a model fit.
function chooseRoute({grid,goal,hierarchy,uncertainty}){
 let id=null,reason="",warnings=[];
 if(grid==="unknown")
  return {id:null,reason:"Observed time support must be verified before choosing a workflow.",warnings:["Inspect the source timing and missingness structure first. No automatic dense or sparse inference is possible."]};
 if(uncertainty==="mnar")
  return {id:null,reason:"A gaze observation mechanism cannot be identified from observed values alone.",warnings:["No workflow can infer outcome-dependent missing-gaze mechanisms without explicit design assumptions or external information.","Use the original recording, calibration and observation-process evidence."]};
 if(goal==="variation"){
  if(grid==="dense"){id="dense-fpca";reason="Observed common-grid trajectories support exploratory functional decomposition.";}
  if(grid==="sparse"){id=hierarchy==="repeated"?"sparse-multilevel":"sparse-fpca";
    reason="Native sparse sampling requires support-aware covariance methods rather than silently filled dense curves.";}
  if(grid==="paired"){id="sparse-paired";reason="Paired x/y support permits declaring joint cross-channel covariance.";}
  if(grid==="async"){id="sparse-async";reason="Separate channel-specific timestamps need an asynchronous method without invented pairing.";}
  if(hierarchy==="repeated"&&grid!=="sparse")
   warnings.push("Repeated trials require participant-level clustering or explicit decomposition in any inferential extension; an exploratory joint component fit does not remove clustering.");
 }else if(goal==="effects"){
  if(grid==="dense"){
   id=hierarchy==="repeated"?"mixed":"fos";
   reason=hierarchy==="repeated"?
    "Repeated participant/trial curves suggest a prespecified functional mixed-effects design.":
    "A continuous common-grid response with independent units can support function-on-scalar modelling.";
  }else reason="No single supported dense function-on-scalar workflow can be selected for these native sparse/asynchronous predictors without a separately specified model and data contract.";
 }else if(goal==="outcomes"){
  if(grid==="dense"&&hierarchy==="independent"){
   id="generalized";reason="Declared non-Gaussian response family, link and denominator/exposure are essential.";
  }else reason="This combination needs an explicitly qualified generalized model for its actual sparse support and/or repeated-unit covariance. No single route is automatically justified.";
 }else if(goal==="prediction"){
  if(grid==="sparse"){
   id="sparse-prediction";reason="A partially observed single-coordinate history can motivate sparse-score prediction with a declared future horizon.";
  }else reason="Partial-path prediction requires explicitly documented sparse history and holdout design; this selection does not automatically validate a dense, paired or asynchronous prediction route.";
 }else if(goal==="dynamics"){
  if(grid==="dense"){
   id="recurrence";reason="Observed ordered states and declared embedding/recurrence parameters support descriptive recurrence exploration.";
   if(hierarchy==="repeated")warnings.push("Analyze declared trajectories and summarize at the independent participant level; do not pool samples as independent units.");
  }else reason="A recurrence analysis of sparse/asynchronous observations needs a defensible state reconstruction policy; the wizard will not invent one.";
 }
 if(uncertainty==="simultaneous")
  warnings.push("Nominal simultaneous bands are NOT universally calibrated. Whole-function coverage requires method-, estimator-, design- and cluster-specific scientific validation.");
 if(uncertainty==="pointwise")
  warnings.push("Pointwise estimates/intervals are conditional on the fitting and sampling assumptions; this tool does not verify coverage.");
 if(id==="mixed")warnings.push("The native R mixed-effects optimizer and covariance contracts can differ from Python SciPy/statsmodels.");
 if(id==="sparse-prediction")warnings.push("Training, calibration and test units must remain separated; prediction scores are not automatic full-path coverage guarantees.");
 return {id,reason,warnings:id?warnings:warnings.concat("Review the full ten-workflow matrix or consult a statistician rather than forcing a model.")};
}
function routeLink(parent,text,x){
 return link(parent,text,"#matrix");
}
function renderWizard(){
 const inputs={grid:$("obsGrid").value,goal:$("researchGoal").value,
  hierarchy:$("studyHierarchy").value,uncertainty:$("uncertainty").value};
 const suggestion=chooseRoute(inputs),x=suggestion.id?byId.get(suggestion.id):null;
 $("selection").classList.toggle("refusal",!x);
 $("choiceName").textContent=x?x.title:"No automatic method selected";
 $("choiceReason").textContent=suggestion.reason;
 const w=$("choiceWarnings");w.replaceChildren();
 for(const note of suggestion.warnings)el("li",w,note);
 const links=$("choiceLinks");links.replaceChildren();
 if(x){
  const btn=el("button",links,"Inspect the mapped R workflow");
  btn.type="button";btn.addEventListener("click",()=>{
   $("matrixSearch").value="";$("matrixFamily").value="all";$("matrixGrid").value="all";
   renderMatrix();selectRoute(x.id);
   $("matrix").scrollIntoView({block:"start"});
  });
  link(links,"Native R figure",x.plotPage);
  link(links,x.rWorkflowDoc.exact?"R workflow help":"R reference index",x.rWorkflowDoc.href);
 }
 link(links,"Evidence and restrictions","#evidence");
}
for(const id of ["obsGrid","researchGoal","studyHierarchy","uncertainty"])
 $(id).addEventListener("change",renderWizard);
$("resetMethod").addEventListener("click",()=>{
 $("obsGrid").value="dense";$("researchGoal").value="variation";
 $("studyHierarchy").value="independent";$("uncertainty").value="descriptive";
 renderWizard();
});
function docsLink(parent,name,doc){
 const label=doc.exact?name+"()":"Find "+name+"() in R reference";
 return link(parent,label,doc.href);
}
function selectRoute(id){
 const x=byId.get(id);if(!x)return;
 selectedRoute=id;
 for(const tr of $("workflowRows").querySelectorAll("tr"))
  tr.dataset.selected=String(tr.dataset.id===id);
 $("detailTitle").textContent=x.title+" — "+x.rWorkflow+"()";
 $("detailInputs").textContent="Required inputs: "+x.inputs;
 $("detailEstimand").textContent=x.estimand;
 $("detailAssumptions").textContent=x.assumptions;
 $("detailBoundary").textContent=x.boundary;
 $("detailImage").src=x.plotImage;
 $("detailImage").alt="Executed native R synthetic "+x.plot+" figure";
 $("detailCaption").textContent=x.plotNote+" Generated by "+x.plot+"() on synthetic inputs; a related method illustration only.";
 const area=$("detailLinks");area.replaceChildren();
 docsLink(area,"R workflow: "+x.rWorkflow,x.rWorkflowDoc);
 docsLink(area,"R estimator: "+x.rEstimator,x.rEstimatorDoc);
 if(x.rSecondary)docsLink(area,"R diagnostic: "+x.rSecondary,x.rSecondaryDoc);
 link(area,"Open native R figure",x.plotPage);
 link(area,"Download figure R script",x.plotScript).setAttribute("download",x.plot+"-sample.R");
 link(area,"Scientific qualification",x.scientificEvidence);
 link(area,"Python source workflow",x.pythonGuide);
 link(area,"508-export parity ledger",x.completeParityLedger);
}
function createRow(x){
 const tr=el("tr",$("workflowRows"));tr.dataset.id=x.id;
 tr.dataset.selected=String(selectedRoute===x.id);
 const td1=el("td",tr);
 el("strong",td1,x.title);
 el("code",td1,x.python+"()");
 el("p",td1,"Published Python 1.2.0 module-scoped route.");
 const td2=el("td",tr);
 const a=el("div",td2,undefined,"route-links");
 docsLink(a,x.rWorkflow,x.rWorkflowDoc);
 el("span",td2,x.rEstimator+"()","code-chip");
 if(x.rSecondary)el("span",td2,x.rSecondary+"()","code-chip");
 el("p",td2,"Native exported entry; source-contract equivalence not certified.");
 const td3=el("td",tr);el("span",td3,x.grid,"tag");
 el("p",td3,x.estimand);
 const td4=el("td",tr);el("p",td4,x.boundary);
 const act=el("div",td4,undefined,"route-links");
 const b=el("button",act,"Inspect assumptions");b.type="button";
 b.addEventListener("click",()=>selectRoute(x.id));
 link(act,"Native R plot",x.plotPage);
 link(act,"Validation",x.scientificEvidence);
}
function renderMatrix(){
 const q=$("matrixSearch").value.trim().toLowerCase(),
 family=$("matrixFamily").value,grid=$("matrixGrid").value;
 const match=entries.filter(x=>
  (family==="all"||x.families.includes(family))&&
  (grid==="all"||x.grid===grid)&&
  (!q||[x.title,x.python,x.rWorkflow,x.rEstimator,x.estimand,x.inputs,x.assumptions,x.boundary,x.grid].join(" ").toLowerCase().includes(q)));
 $("matrixCount").textContent=match.length+" of "+entries.length+" native R workflow correspondences shown";
 $("workflowRows").replaceChildren();
 for(const x of match)createRow(x);
 if(!match.length){
  const tr=el("tr",$("workflowRows"));
  el("td",tr,"No matching workflows. Clear the filters and reconsider your observation support.").colSpan=4;
 }else if(!selectedRoute||!match.some(x=>x.id===selectedRoute))
  selectRoute(match[0].id);
}
for(const id of ["matrixSearch","matrixFamily","matrixGrid"])
 $(id).addEventListener(id==="matrixSearch"?"input":"change",renderMatrix);
renderMatrix();renderWizard();
window.ET_RESEARCH_PORTAL_API=Object.freeze({parseCSV,inspectCSV,chooseRoute,
 getState:()=>({selectedRoute,auditAvailable:!!audit,visibleRows:$("workflowRows").querySelectorAll("tr").length})});
})();