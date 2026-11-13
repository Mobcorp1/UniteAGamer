/* UAG Research Material Calculator — public, offline-first, no account required. */
(function () {
  'use strict';
  const OUTPOST={"1":{"Planks":3,"Sheet Metal":5,"ARC Alloy":10,"Advanced Electrical Components":3},"2":{"Steel Cable":3,"Sheet Metal":20,"Cable Strippers":3},"3":{"Epoxy Buckets":3,"Planks":35,"Hand Drills":3},"4":{"Sheet Metal":40,"Laser Levels":3,"Insulation Rolls":3}};
  const RESEARCH={"1":{"Planks":35,"Battered Paperbacks":5,"Mini Pumps":3},"2":{"Calculators":3,"Raider Logbooks":3,"Skulker Targeters":5},"3":{"Differential Microphones":3,"Exodus Technical Handbooks":3,"Bully Fragmenters":6},"4":{"Thermal Shakers":3,"ARC Data Modules":3,"Frigate Inductor":1}};
  function toCount(value, cap=999999){
 const n=Number(value);
 return Number.isFinite(n)?Math.max(0,Math.min(cap,Math.floor(n))):0;
}
  function calculatePlan(config={}, stocks={}){
 const currentOutpost=toCount(config.currentOutpost,4);
 const currentResearch=toCount(config.currentResearch,4);
 const requestedOutpost=toCount(config.targetOutpost,4);
 const requestedResearch=toCount(config.targetResearch,4);
 const bantamUnlock=Boolean(config.bantamUnlock);
 const stilettoUnlock=Boolean(config.stilettoUnlock);
 const bantamCraft=toCount(config.bantamCraft,99);
 const stilettoCraft=toCount(config.stilettoCraft,99);
 const warnings=[];
 if(currentResearch>currentOutpost){
  return {error:"Research Station level cannot be higher than the Outpost level in this planning model. Check the levels selected.",rows:[],stages:[],warnings:[]};
 }
 const targetResearch=Math.max(currentResearch,requestedResearch,bantamUnlock||stilettoUnlock?1:0);
 const targetOutpost=Math.max(currentOutpost,requestedOutpost,targetResearch);
 const totals=new Map(),stages=[];
 function add(stage,items){
  stages.push(stage);
  for(const [resource,quantity] of Object.entries(items)) totals.set(resource,(totals.get(resource)||0)+quantity);
 }
 for(let level=currentOutpost+1;level<=targetOutpost;level++) add("Outpost "+["","I","II","III","IV"][level],OUTPOST[level]);
 for(let level=currentResearch+1;level<=targetResearch;level++) add("Research Station "+["","I","II","III","IV"][level],RESEARCH[level]);
 if(bantamUnlock) add("Bantam blueprint research unlock",{"Research Points":3000,"Hornet Drivers":8});
 if(stilettoUnlock) add("Stiletto blueprint research unlock",{"Research Points":3000,"Wasp Drivers":15});
 if(bantamCraft>0) add("Bantam I × "+bantamCraft,{"Simple Gun Parts":4*bantamCraft,"Mechanical Components":4*bantamCraft});
 if(stilettoCraft>0) add("Stiletto I × "+stilettoCraft,{"Simple Gun Parts":4*stilettoCraft,"Mechanical Components":4*stilettoCraft});
 if((bantamCraft>0&&!bantamUnlock)||(stilettoCraft>0&&!stilettoUnlock)){
  warnings.push("Crafting quantities assume you already have access to those blueprints unless you also select their research unlocks.");
 }
 if(targetOutpost>requestedOutpost&&targetOutpost>currentOutpost){
  warnings.push("Additional Outpost levels were included because the requested Research Station or blueprint unlock depends on them.");
 }
 const rows=[...totals.entries()].map(([name,required])=>{
  const owned=toCount(stocks[name]);
  return {name,required,owned,missing:Math.max(0,required-owned)};
 }).sort((a,b)=>a.name.localeCompare(b.name,"en-GB"));
 return {error:null,rows,stages,warnings,requiredOutpost:targetOutpost,requiredResearch:targetResearch};
}
  if (typeof module !== 'undefined' && module.exports) {
    module.exports = {OUTPOST,RESEARCH,toCount,calculatePlan};
  }
  if (typeof document === 'undefined') return;
  document.addEventListener('DOMContentLoaded', function () {
    const form=document.getElementById('material-form');
    const body=document.getElementById('materials-body');
    const summary=document.getElementById('plan-summary');
    const warnings=document.getElementById('plan-warnings');
    const included=document.getElementById('included-stages');
    const status=document.getElementById('calculator-status');
    if (!form||!body||!summary||!warnings||!included||!status) return;
    const storageKey='uag-research-planner-v1';
    const fields=['currentOutpost','currentResearch','targetOutpost','targetResearch','bantamUnlock','stilettoUnlock','bantamCraft','stilettoCraft'];
    let holdings={};
    function readForm(){
      const cfg={};
      for(const key of fields){
        const element=form.elements.namedItem(key);
        cfg[key]=element.type==='checkbox'?element.checked:element.value;
      }
      return cfg;
    }
    function save(){
      try{window.localStorage.setItem(storageKey,JSON.stringify({version:1,config:readForm(),holdings}));}catch(_error){}
    }
    function restore(){
      try{
        const raw=window.localStorage.getItem(storageKey);
        if(!raw)return;
        const state=JSON.parse(raw);
        if(!state||state.version!==1)return;
        if(state.config&&typeof state.config==='object'){
          for(const key of fields){
            if(!Object.prototype.hasOwnProperty.call(state.config,key))continue;
            const e=form.elements.namedItem(key);
            if(e.type==='checkbox')e.checked=state.config[key]===true;
            else e.value=String(toCount(state.config[key],key.endsWith('Craft')?99:4));
          }
        }
        if(state.holdings&&typeof state.holdings==='object'&&!Array.isArray(state.holdings)){
          holdings=Object.fromEntries(Object.entries(state.holdings)
            .filter(([key])=>typeof key==='string'&&key.length<120)
            .map(([key,val])=>[key,toCount(val)]));
        }
      }catch(_error){holdings={};}
    }
    function makeCell(row,text,cls){
      const td=document.createElement('td');
      if(cls)td.className=cls;
      td.textContent=String(text);
      row.appendChild(td);
      return td;
    }
    function displayWarnings(plan){
      warnings.replaceChildren();
      const lines=plan.error?[plan.error]:plan.warnings;
      warnings.hidden=lines.length===0;
      for(const line of lines){
        const li=document.createElement('li');
        li.textContent=line;
        warnings.appendChild(li);
      }
    }
    function displaySummary(plan){
      summary.textContent=plan.error?'Check your current levels before calculating.':
        plan.rows.length===0?'Choose an upgrade, blueprint unlock or craft quantity to build a checklist.':
        plan.rows.filter(x=>x.missing>0).length+' material types still needed across '+plan.stages.length+' selected steps.';
      included.replaceChildren();
      if(!plan.error){
        for(const stage of plan.stages){
          const li=document.createElement('li');li.textContent=stage;included.appendChild(li);
        }
      }
      displayWarnings(plan);
      document.getElementById('download-checklist').disabled=Boolean(plan.error)||plan.rows.length===0;
    }
    function render(){
      const plan=calculatePlan(readForm(),holdings);
      body.replaceChildren();
      displaySummary(plan);
      for(const row of plan.rows){
        const tr=document.createElement('tr');
        makeCell(tr,row.name,'material-name');
        makeCell(tr,row.required.toLocaleString('en-GB'),'number');
        const ownedTd=document.createElement('td');
        const input=document.createElement('input');
        input.type='number';input.min='0';input.max='999999';input.step='1';
        input.value=String(row.owned);input.inputMode='numeric';
        input.setAttribute('aria-label','Amount already owned: '+row.name);
        ownedTd.appendChild(input);tr.appendChild(ownedTd);
        const missing=makeCell(tr,row.missing.toLocaleString('en-GB'),'number missing');
        input.addEventListener('input',function(){
          holdings[row.name]=toCount(input.value);
          const current=calculatePlan(readForm(),holdings);
          const item=current.rows.find(x=>x.name===row.name);
          missing.textContent=item?item.missing.toLocaleString('en-GB'):'0';
          displaySummary(current);save();
        });
        body.appendChild(tr);
      }
      status.textContent=plan.error?'Please correct the levels.':'Checklist calculated locally; no account required.';
      save();
    }
    form.addEventListener('input',render);
    form.addEventListener('change',render);
    document.getElementById('download-checklist').addEventListener('click',function(){
      const plan=calculatePlan(readForm(),holdings);
      if(plan.error||!plan.rows.length)return;
      const lines=['UAG ARC Raiders — Research Material Checklist','Reference: UAG PASS 11D REV4 (18 October 2026)','Created: '+new Date().toLocaleDateString('en-GB'),'','Planned steps:',...plan.stages.map(x=>'- '+x),'','Resources (required | owned | still needed):',...plan.rows.map(x=>x.name+': '+x.required+' | '+x.owned+' | '+x.missing),'','Verify recipes and completed upgrades in ARC Raiders before spending.'];
      const blob=new Blob([lines.join('\n')+'\n'],{type:'text/plain;charset=utf-8'});
      const url=URL.createObjectURL(blob);
      const a=document.createElement('a');a.href=url;a.download='uag-research-material-checklist.txt';
      document.body.appendChild(a);a.click();a.remove();
      setTimeout(()=>URL.revokeObjectURL(url),1000);
    });
    document.getElementById('reset-checklist').addEventListener('click',function(){
      form.reset();holdings={};
      try{window.localStorage.removeItem(storageKey);}catch(_error){}
      render();
    });
    restore();render();
  });
})();
