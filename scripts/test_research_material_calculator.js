'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { calculatePlan, toCount } = require('../web/public-assets/research-planner.js');

function value(plan, name, key='required') {
  const row=plan.rows.find((x)=>x.name===name);
  assert.ok(row, 'Missing item in calculator: '+name);
  return row[key];
}

const researchOne=calculatePlan({targetResearch:1});
assert.equal(researchOne.error,null);
assert.equal(researchOne.requiredOutpost,1);
assert.equal(value(researchOne,'Planks'),38);
assert.equal(value(researchOne,'Sheet Metal'),5);
assert.equal(value(researchOne,'ARC Alloy'),10);
assert.equal(value(researchOne,'Battered Paperbacks'),5);

const progressing=calculatePlan({
  currentOutpost:2,currentResearch:1,targetOutpost:4,targetResearch:4
});
assert.equal(progressing.stages.filter(x=>x.startsWith('Outpost')).length,2);
assert.equal(progressing.stages.filter(x=>x.startsWith('Research Station')).length,3);
assert.equal(value(progressing,'Sheet Metal'),40);
assert.equal(value(progressing,'Epoxy Buckets'),3);

const weapons=calculatePlan({
  bantamUnlock:true,stilettoUnlock:true,bantamCraft:2,stilettoCraft:1
},{'Research Points':2000,'Simple Gun Parts':7,'Mechanical Components':20});
assert.equal(value(weapons,'Research Points'),6000);
assert.equal(value(weapons,'Research Points','missing'),4000);
assert.equal(value(weapons,'Hornet Drivers'),8);
assert.equal(value(weapons,'Wasp Drivers'),15);
assert.equal(value(weapons,'Simple Gun Parts'),12);
assert.equal(value(weapons,'Simple Gun Parts','missing'),5);
assert.equal(value(weapons,'Mechanical Components'),12);
assert.equal(value(weapons,'Mechanical Components','missing'),0);
assert.equal(weapons.requiredResearch,1);
assert.equal(weapons.requiredOutpost,1);

assert.ok(calculatePlan({currentOutpost:0,currentResearch:2}).error);
assert.equal(calculatePlan({targetOutpost:0,targetResearch:0}).rows.length,0);
assert.ok(calculatePlan({bantamCraft:1}).warnings.length);
assert.equal(toCount('-1'),0);
assert.equal(toCount('4.9'),4);
assert.equal(toCount('not-a-number'),0);
assert.equal(toCount('100000000'),999999);

const root=path.resolve(__dirname,'..','web');
const html=fs.readFileSync(path.join(root,'tools/research-material-calculator/index.html'),'utf8');
const sitemap=fs.readFileSync(path.join(root,'sitemap.xml'),'utf8');
const tools=fs.readFileSync(path.join(root,'tools/index.html'),'utf8');
const guides=fs.readFileSync(path.join(root,'guides/index.html'),'utf8');
for (const needle of [
  'https://uniteagamer.com/tools/research-material-calculator/',
  'id="material-form"',
  'id="materials-body"',
  'research-planner.js',
  'Research Station IV',
  '38 Planks'
]) assert.ok(html.includes(needle),'Expected public page feature: '+needle);
assert.ok(sitemap.includes('https://uniteagamer.com/tools/research-material-calculator/'));
assert.ok(tools.includes('href="/tools/research-material-calculator/"'));
assert.ok(guides.includes('href="/tools/research-material-calculator/"'));
console.log('PASS UAG research material calculator: model, reference amounts, guardrails and static discovery');
