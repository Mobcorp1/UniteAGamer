#!/usr/bin/env node
'use strict';
/* PASS 14: deterministic UI-only codemod + all-lib Dart UI surface inventory.
 * Reads the source on the target machine, never assumes remote source is current.
 * Built-in Node only; no network or npm packages.
 */
const fs=require('fs'),path=require('path'),crypto=require('crypto');
const ROOT=path.resolve(get('--project')||process.cwd());
const MODE=get('--mode')||'plan';
const OUT=get('--out');
const THEME='lib/widgets/theme.dart';
const IMPORT="import 'package:uag_arc_raiders_hub/widgets/theme.dart' as uag_pass14_theme;";
const SKIP=new Set([
  'lib/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart',
  'lib/features/trading_hub/arc_raiders/widgets/blueprint_tile.dart',
  'lib/features/trading_hub/arc_raiders/screens/favourite_loadout_screen.dart',
]);
const COLLECTIONS=new Set([
  'lib/features/trading_hub/arc_raiders/widgets/arc_collection_dupe_manager.dart',
  'lib/features/trading_hub/arc_raiders/widgets/arc_collections_category_bar.dart',
  'lib/features/trading_hub/arc_raiders/screens/arc_additional_collections_screen.dart',
  'lib/features/trading_hub/arc_raiders/screens/arc_blueprint_collection_overview_screen.dart',
  'lib/features/trading_hub/arc_raiders/screens/arc_collections_tracker_screen.dart',
  'lib/features/trading_hub/arc_raiders/widgets/arc_collection_visual_share.dart',
]);
const DRIFT=['FFFF3C97','FFFF61B6','FFFF8FC1','FF8B426D','FFFF4FAB','FFFF90CA','FFFF4EA4'];
const MODALS=new Set(['AlertDialog','SimpleDialog','Dialog','showModalBottomSheet','showMenu']);
function get(flag){const i=process.argv.indexOf(flag);return i<0?null:process.argv[i+1]}
function fail(s){throw Error(s)}
function hash(s){return crypto.createHash('sha256').update(s).digest('hex')}
function list(dir){if(!fs.existsSync(dir))fail('Directory missing: '+dir);let out=[];for(const d of fs.readdirSync(dir,{withFileTypes:true})){const p=path.join(dir,d.name);if(d.isDirectory())out.push(...list(p));else if(d.isFile()&&p.endsWith('.dart')&&!/\.(g|freezed|gr)\.dart$/.test(p))out.push(p)}return out}
function rel(p){return path.relative(ROOT,p).split(path.sep).join('/')}
function protectedPath(p){return SKIP.has(p)||p.includes('/generated/')||p.includes('/firebase_options.dart')}
function codeMask(s){const m=new Uint8Array(s.length);for(let i=0;i<s.length;){
  if(s.startsWith('//',i)){i=s.indexOf('\n',i);if(i<0)break;continue}
  if(s.startsWith('/*',i)){let depth=1;i+=2;while(i<s.length&&depth){if(s.startsWith('/*',i)){depth++;i+=2}else if(s.startsWith('*/',i)){depth--;i+=2}else i++}continue}
  if(s[i]==='"'||s[i]==="'"){const q=s[i],triple=s.slice(i,i+3)===q.repeat(3);i+=triple?3:1;while(i<s.length){if(s[i]==='\\'){i+=2;continue}if(triple?s.slice(i,i+3)===q.repeat(3):s[i]===q){i+=triple?3:1;break}i++}continue}
  m[i]=1;i++
}return m}
function closeParen(s,m,start){let n=0;for(let i=start;i<s.length;i++){if(!m[i])continue;if(s[i]==='(')n++;if(s[i]===')'&&!--n)return i}fail('Cannot balance Dart invocation at '+start)}
function topKeys(s,m,start,end){const keys=new Set();let p=0,b=0,c=0,seg=start;for(let i=start;i<=end;i++){
 const boundary=i===end||(m[i]&&s[i]===','&&p===0&&b===0&&c===0);
 if(boundary){let j=seg;while(j<i&&/\s/.test(s[j]))j++;const match=/^([a-zA-Z_]\w*)\s*:/.exec(s.slice(j,i));if(match&&m[j])keys.add(match[1]);seg=i+1;continue}
 if(!m[i])continue;if(s[i]==='(')p++;else if(s[i]===')')p--;else if(s[i]==='[')b++;else if(s[i]===']')b--;else if(s[i]==='{')c++;else if(s[i]==='}')c--;
}return keys}
function modalCalls(s){const m=codeMask(s),calls=[];const re=/\b(AlertDialog|SimpleDialog|Dialog|showModalBottomSheet|showMenu)\s*(?:<[^>\n]*>)?\s*\(/g;let v;while((v=re.exec(s))){if(!m[v.index])continue;const k=v[1],open=s.indexOf('(',v.index);if(!m[open])continue;const end=closeParen(s,m,open);const keys=topKeys(s,m,open+1,end);const col=s.lastIndexOf('\n',v.index)+1;const whitespace=(s.slice(col,v.index).match(/^\s*/)||[''])[0];calls.push({k,start:v.index,open,end,keys,indent:whitespace});re.lastIndex=open+1}
 return calls}
function tweakModals(s){const calls=modalCalls(s);let n=0,updates=[];for(const q of calls){const pieces=[];
 const bgKey=q.k==='showMenu'?'color':'backgroundColor';
 if(!q.keys.has(bgKey))pieces.push(bgKey+': uag_pass14_theme.AppTheme.cardBackgroundDeep');
 else {
   // Do not override intentionally transparent or custom-coloured surfaces.
   // Only replace unmistakable default WHITE/BLUE popup backgrounds.
   const inside=s.slice(q.open+1,q.end);
   const top=/\b(?:backgroundColor|color)\s*:\s*(?:const\s+)?(?:Colors\.(?:white|blue(?:Accent)?)|Color\(0x(?:FFFFFFFF|FF2196F3|FF448AFF)\))/g;
   let v;while((v=top.exec(inside))){
     const before=inside.slice(0,v.index);const local=codeMask(inside);
     if(!local[v.index])continue;
     // Require the field to occur at current invocation's top level.
     // A nested child/background is not the dialog's background.
     const fields=topLevelOffsets(inside,local);
     if(fields.has(v.index)&&v[0].trimStart().startsWith(bgKey+':')){
       updates.push({at:q.open+1+v.index,replaceLength:v[0].length,value:bgKey+': uag_pass14_theme.AppTheme.cardBackgroundDeep'});
       n++;break;
     }
   }
 }
 if(['Dialog','SimpleDialog','AlertDialog'].includes(q.k)&&!q.keys.has('surfaceTintColor'))pieces.push('surfaceTintColor: Colors.transparent');
 if(pieces.length){
   // Insert after an existing newline+indent, rather than before it.
   // REV3 inserted `\n + padding` before the original `\n`, leaving a
   // whitespace-only added line and causing `git diff --check` to reject it.
   const after=s.slice(q.open+1,q.end);
   const firstLine=/^\n([ \t]*)/.exec(after);
   if(firstLine){
     const pad=firstLine[1];
     updates.push({at:q.open+1+firstLine[0].length,
       value:pieces.join(',\n'+pad)+',\n'+pad});
   }else{
     const pad=q.indent+'  ';
     const next=after.trimStart();
     // For an empty single-line dialog, indent the closing parenthesis at
     // the invocation's level, not with a dangling whitespace-only line.
     const endPad=next===''?q.indent:pad;
     updates.push({at:q.open+1,
       value:'\n'+pad+pieces.join(',\n'+pad)+',\n'+endPad});
   }
   n++;
 }
}
 for(const t of updates.sort((a,b)=>b.at-a.at))s=s.slice(0,t.at)+t.value+s.slice(t.at+(t.replaceLength||0));
 return {text:s,count:n,calls:calls.length};}
function topLevelOffsets(s,m){const offsets=new Set();let p=0,b=0,c=0;for(let i=0;i<s.length;i++){
 if(!m[i])continue;if(s[i]==='(')p++;else if(s[i]===')')p--;else if(s[i]==='[')b++;else if(s[i]===']')b--;else if(s[i]==='{')c++;else if(s[i]==='}')c--;
 if(p===0&&b===0&&c===0&&(s[i]===','||i===0)){
   let j=i===0?i:i+1;while(j<s.length&&/\s/.test(s[j]))j++;if(j<s.length)offsets.add(j);
 }
}return offsets}
const THEME_BLOCK=`      // PASS14: these are application-wide defaults, including routes that do
      // not explicitly use the shared UAG dialog/widget wrappers.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: neonCyan,
          foregroundColor: darkBackground,
          disabledBackgroundColor: cardBackgroundAlt,
          disabledForegroundColor: Colors.white38,
          textStyle: buttonTextStyle(color: darkBackground, fontSize: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: neonCyan,
          textStyle: buttonTextStyle(color: neonCyan, fontSize: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: neonCyan,
          side: BorderSide(color: neonCyan.withValues(alpha: 0.55)),
          textStyle: buttonTextStyle(color: neonCyan, fontSize: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: cardBackgroundDeep,
        surfaceTintColor: Colors.transparent,
        textStyle: bodyTextStyle(fontSize: 14, color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(color: neonCyan.withValues(alpha: 0.3)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cardBackgroundAlt,
        selectedColor: neonCyan.withValues(alpha: 0.16),
        disabledColor: cardBackgroundDeep,
        labelStyle: bodyTextStyle(fontSize: 12, color: Colors.white),
        side: BorderSide(color: neonCyan.withValues(alpha: 0.25)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: cardBackgroundDeep,
          border: Border.all(color: neonCyan.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(buttonRadius),
        ),
        textStyle: bodyTextStyle(fontSize: 12, color: Colors.white),
      ),
`;
function injectTheme(s){const anchor='      dialogTheme: DialogThemeData(';if(s.includes('PASS14: these are application-wide defaults'))return s;if(s.split(anchor).length!==2)fail('Theme anchor drift (dialogTheme must occur exactly once)');s=s.replace(anchor,THEME_BLOCK+anchor);const after='        backgroundColor: cardBackgroundDeep,\n        surfaceTintColor: Colors.transparent,\n        elevation: 0,\n        shape:';if(!s.includes(after))fail('Dialog theme drift');s=s.replace(after,'        backgroundColor: cardBackgroundDeep,\n        surfaceTintColor: Colors.transparent,\n        titleTextStyle: titleTextStyle(fontSize: 20, color: neonCyan, isBold: true),\n        contentTextStyle: bodyTextStyle(fontSize: 14, color: Colors.white70),\n        elevation: 0,\n        shape:');return s}
// Flutter projects commonly use CRLF working-tree checkouts on Windows.
// Work in LF internally, then restore each file's original line endings.
// Never introduce mixed EOL or require exact LF-only source anchors.
function transform(source,file){
 const crlf=source.includes('\r\n');
 let s=crlf?source.replace(/\r\n/g,'\n'):source;
 const finish=(text,stats)=>({text:crlf?text.replace(/\n/g,'\r\n'):text,stats});
 let st={modals:0,drift:0,theme:false};
 if(protectedPath(file))return {text:source,stats:st};
 if(file===THEME){s=injectTheme(s);st.theme=true;return finish(s,st)}
 if(COLLECTIONS.has(file)){
  for(const h of DRIFT){const re=new RegExp('(?:const\\s+)?Color\\(0x'+h+'\\)','g');let count=0;s=s.replace(re,()=>{count++;return 'uag_pass14_theme.AppTheme.neonPink'});st.drift+=count;}
 }
 const m=tweakModals(s);s=m.text;st.modals=m.count;
 // Inject the prefixed theme import only when our generated Dart actually
 // references it. Some already-themed dialogs only need a transparent surface
 // tint; importing AppTheme for those creates an unused_import analyzer warning.
 if(s.includes('uag_pass14_theme.AppTheme')&&!s.includes(IMPORT)){
  if(s.includes("import 'package:flutter/material.dart';")){s=s.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\n"+IMPORT)}else {const at=/^import\s+['"][^'"]+['"];?/m.exec(s);if(!at)return {text:source,stats:{modals:0,drift:0,theme:false,skipped:'Cannot insert themed import into Dart part/library'}};s=s.slice(0,at.index+at[0].length)+'\n'+IMPORT+s.slice(at.index+at[0].length)}
 }
 // Git diff --check is a hard release gate. Normalize whitespace-only lines
 // in files we actually touched; retain all nonblank content and original EOL.
 // This also protects unusual modal layouts with pre-existing empty indent.
 if(s!== (crlf?source.replace(/\r\n/g,'\n'):source))s=s.replace(/^[ \t]+$/gm,'');
 return finish(s,st);}
function inventory(s,file){const calls=modalCalls(s);const badRaw=/\b(?:Colors\.blue\w*|Colors\.white|Color\(0xFF(?:FF[0-9A-Fa-f]{4}|[0-9A-Fa-f]{6})\))\b/g;const issues=[];
 for(const q of calls){const key=q.k==='showMenu'?'color':'backgroundColor';const explicit=q.keys.has(key);if(explicit&&/\b(?:Colors\.white|Colors\.blue\w*)/.test(s.slice(q.open,Math.min(q.end,q.open+500))))issues.push({line:line(s,q.start),type:'modal_explicit_colour_review',widget:q.k});}
 const mask=codeMask(s);for(const m of s.matchAll(/\b(?:showDatePicker|showTimePicker|CupertinoAlertDialog|showGeneralDialog|showCupertinoModalPopup|Dialog\.fullscreen|OverlayEntry\s*\(|ThemeData\s*\(|MaterialApp\s*\()/g)){if(!mask[m.index])continue;issues.push({line:line(s,m.index),type:'review_special_surface',widget:m[0]})}
 return {file,screen:/\/screens?\//.test(file),modalCalls:calls.length,modalKinds:calls.reduce((a,q)=>(a[q.k]=(a[q.k]||0)+1,a),{}),customOverrides:issues,hardcodedColourCount:(s.match(/\bColor\(0x[0-9a-fA-F]{8}\)/g)||[]).length};}
function line(s,n){return s.slice(0,n).split('\n').length}
function emit(p,obj){if(!p)return;fs.mkdirSync(path.dirname(path.resolve(p)),{recursive:true});fs.writeFileSync(p,JSON.stringify(obj,null,2)+'\n')}
function main(){if(MODE==='self-test'){selfTest();return}if(!['plan','apply','verify'].includes(MODE))fail('Unknown mode '+MODE);
 const items=[];const audit=[];const skipped=[];let countModal=0,countDrift=0;for(const abs of list(path.join(ROOT,'lib'))){const file=rel(abs),before=fs.readFileSync(abs,'utf8'),t=transform(before,file);if(t.stats.skipped)skipped.push({file,reason:t.stats.skipped});if(MODE==='apply'&&before!==t.text)fs.writeFileSync(abs,t.text,'utf8');if(MODE==='verify'&&before!==t.text)fail('PASS14 convergence drift: '+file+' (rerun installer, do NOT reapply a patch to unverified HEAD)');
 if(before!==t.text)items.push({path:file,beforeSha256:hash(before),afterSha256:hash(t.text),modalFixes:t.stats.modals,dupeColourFixes:t.stats.drift});countModal+=t.stats.modals;countDrift+=t.stats.drift;audit.push(inventory(MODE==='apply'?t.text:before,file));}
 const baseline=get('--baseline');
 if(MODE==='verify'&&baseline){
   if(!fs.existsSync(baseline))fail('PASS14 approved baseline missing: '+baseline);
   const b=JSON.parse(fs.readFileSync(baseline,'utf8'));
   const previous=new Map((b.manualReview||[]).map(x=>[x.file,x]));
   const regressions=[];
   for(const x of audit){const old=previous.get(x.file);
     if(x.hardcodedColourCount>(old?.hardcodedColourCount||0))regressions.push(x.file+': new hardcoded colours');
     if(x.customOverrides.length>(old?.customOverrides?.length||0))regressions.push(x.file+': new custom theme/modal exceptions');
   }
   if(regressions.length)fail('New visual drift since PASS14 baseline: '+regressions.slice(0,15).join('; '));
 }
 const totals={dartFiles:audit.length,screenFiles:audit.filter(x=>x.screen).length,modalCalls:audit.reduce((n,x)=>n+x.modalCalls,0),hardcodedColourDeclarations:audit.reduce((n,x)=>n+x.hardcodedColourCount,0),manualReviewFlags:audit.reduce((n,x)=>n+x.customOverrides.length,0)};
 const result={mode:MODE,sourceHeadRequired:'ef7d31468532991827b9c7c213917ae3a20d90a6',affectedFiles:items.length,modalStylesApplied:countModal,duplicateAccentsNormalised:countDrift,changes:items,inventory:totals,manualReview:audit.filter(x=>x.customOverrides.length||x.hardcodedColourCount>0),skipped,protected:[...SKIP],note:'Code checks cannot certify screenshots, third-party/native UI, nested subthemes or subjective visual acceptance. Manual UI route audit remains required.'};emit(OUT,result);console.log(JSON.stringify({mode:MODE,affectedFiles:items.length,modals:countModal,dupeAccents:countDrift,inventory:totals,report:OUT||null}));}
function selfTest(){const a=`import 'package:flutter/material.dart';\nvoid f() { showDialog(context: context, builder: (c) => const AlertDialog(title: Text('Hi'), content: Text('Ok'))); showModalBottomSheet<void>(context: context, builder: (c) => Text('x')); }`;
 const one=transform(a,'lib/features/example/screens/demo.dart').text;if(!one.includes('uag_pass14_theme.AppTheme.cardBackgroundDeep')||!one.includes('surfaceTintColor: Colors.transparent'))fail('Modal self test failed');if(transform(one,'lib/features/example/screens/demo.dart').text!==one)fail('Codemod not idempotent');const b=`import 'package:flutter/material.dart';\nclass X { Widget build(c) => const AlertDialog(backgroundColor: Colors.black, content: Text('yes')); }`;let v=transform(b,'lib/demo.dart').text;if(v.includes('uag_pass14_theme.AppTheme.cardBackgroundDeep'))fail('Explicit custom modal background overwritten');const t=transform("import 'package:flutter/material.dart';\nconst c = Color(0xFFFF8FC1);", 'lib/features/trading_hub/arc_raiders/widgets/arc_collection_dupe_manager.dart').text;if(!t.includes('AppTheme.neonPink'))fail('Dupe colour normalize failed');
 const white="import 'package:flutter/material.dart';\nfinal w = AlertDialog(backgroundColor: Colors.white, title: const Text('Own it'));";
 const darkened=transform(white,'lib/demo.dart').text;
 if(!darkened.includes('backgroundColor: uag_pass14_theme.AppTheme.cardBackgroundDeep'))fail('White modal not normalised');
 if(transform(darkened,'lib/demo.dart').text!==darkened)fail('White modal not idempotent');
 // Regression: Windows core.autocrlf checkouts must not be rejected or
 // rewritten with mixed CRLF/LF line endings.
 const sampleTheme=`import 'package:flutter/material.dart';
class AppTheme {
  static ThemeData get theme => ThemeData(
      dialogTheme: DialogThemeData(
        backgroundColor: cardBackgroundDeep,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(),
      ),
  );
}`;
 for(const eol of ['\n','\r\n']){
   const original=sampleTheme.replace(/\n/g,eol);
   const styled=transform(original,THEME).text;
   if(!styled.includes('titleTextStyle: titleTextStyle('))fail('Dialog theme formatting regression');
   if(eol==='\r\n'&&/(^|[^\r])\n/.test(styled))fail('Mixed EOL introduced on Windows');
   if(transform(styled,THEME).text!==styled)fail('Theme transformer not idempotent');
 }
 // Regression from REV2 Windows flutter analyze: a modal with its own themed
 // background receives only surfaceTintColor, and MUST NOT gain an unused
 // uag_pass14_theme import. This affected nine app-owned Dart files.
 const alreadyDark="import 'package:flutter/material.dart';\nimport 'package:uag_arc_raiders_hub/widgets/theme.dart';\nfinal w = AlertDialog(backgroundColor: AppTheme.cardBackgroundDeep, title: const Text('Owned'));";
 const themed=transform(alreadyDark,'lib/features/example/screens/demo.dart').text;
 if(!themed.includes('surfaceTintColor: Colors.transparent'))fail('Custom dialog transparency missing');
 if(themed.includes(IMPORT))fail('Regression: unused alias import for already themed dialog');
 if(transform(themed,'lib/features/example/screens/demo.dart').text!==themed)fail('Already themed modal not idempotent');
 const tokenOnly=transform("import 'package:flutter/material.dart';\nconst c = Color(0xFFFF8FC1);",'lib/features/trading_hub/arc_raiders/widgets/arc_collection_dupe_manager.dart').text;
 if(!tokenOnly.includes(IMPORT))fail('Missing alias import for canonical pink token');
 const overlay=transform("import 'package:flutter/material.dart';\nfinal w = AlertDialog(backgroundColor: Colors.transparent, title: const Text('HUD'));",'lib/features/example/screens/demo.dart').text;
 if(overlay.includes(IMPORT))fail('Regression: unnecessary import for transparent dialog');
 const crlfDialog=a.replace(/\n/g,'\r\n');
 const styledDialog=transform(crlfDialog,'lib/features/example/screens/demo.dart').text;
 if(/(^|[^\r])\n/.test(styledDialog))fail('CRLF modal formatting regression');
 if(transform(styledDialog,'lib/features/example/screens/demo.dart').text!==styledDialog)fail('CRLF modal not idempotent');
 const protectedSample=transform(a,'lib/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart').text;
 if(protectedSample!==a)fail('Protected Blueprint source modified');
 // REV4 regression: multiline modal insertion must never create blank lines
 // containing spaces. Windows Git rejects these through `git diff --check`.
 const malformed=`import 'package:flutter/material.dart';
Widget modal(BuildContext context) {
  return AlertDialog(
    title: const Text('A'),
    actions: [TextButton(onPressed: () {}, child: const Text('OK'))],
  );
}`;
 const fixed=transform(malformed,'lib/features/legal/widgets/modal_sample.dart').text;
 if(fixed.split('\n').some(l=>/[ \t]+$/.test(l)))fail('REV4 trailing whitespace in multiline dialog');
 if(fixed.includes('  \n'))fail('REV4 whitespace-only line introduced');
 if(transform(fixed,'lib/features/legal/widgets/modal_sample.dart').text!==fixed)fail('REV4 dialog idempotency failed');
 const modalCrLf=malformed.replace(/\n/g,'\r\n');
 const fixedCrLf=transform(modalCrLf,'lib/features/legal/widgets/modal_sample.dart').text;
 if(fixedCrLf.split('\r\n').some(l=>/[ \t]+$/.test(l)))fail('REV4 trailing whitespace in Windows dialog');
 if(/(^|[^\r])\n/.test(fixedCrLf))fail('REV4 introduced mixed Windows EOL');
 const inline="import 'package:flutter/material.dart';\nWidget f()=>AlertDialog(title: const Text('A'));";
 const inlineStyled=transform(inline,'lib/features/legal/widgets/inline_dialog.dart').text;
 if(inlineStyled.split('\n').some(l=>/[ \t]+$/.test(l)))fail('REV4 inline whitespace regression');
 const blankInside="import 'package:flutter/material.dart';\nWidget f()=>AlertDialog(\n  \n  title: const Text('A'),\n);";
 const blankStyled=transform(blankInside,'lib/features/legal/widgets/blank_dialog.dart').text;
 if(blankStyled.split('\n').some(l=>/[ \t]+$/.test(l)))fail('REV4 empty indent regression');
 console.log('PASS14 REV5 codemod self-test PASS')}
try{main()}catch(e){console.error('PASS14 CODEMOD FAILED: '+e.message);process.exitCode=1}
