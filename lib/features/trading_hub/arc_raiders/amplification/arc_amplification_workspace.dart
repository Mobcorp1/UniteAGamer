import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_raid_intelligence_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trader_hub_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'arc_amplification_catalog.dart';
import 'arc_amplification_repository.dart';
import 'arc_amplification_state.dart';

/// Full shared progress editor, displayed inside the Research Workstation.
class ArcAmplificationWorkspace extends StatefulWidget {
  const ArcAmplificationWorkspace({super.key});
  @override
  State<ArcAmplificationWorkspace> createState()=>_ArcAmplificationWorkspaceState();
}
class _ArcAmplificationWorkspaceState extends State<ArcAmplificationWorkspace> {
  final ArcAmplificationRepository _repo=ArcAmplificationRepository();
  late final Stream<ArcAmplificationState> _progress;
  @override
  void initState(){super.initState();_progress=_repo.watch();}
  bool _busy=false;
  String? _focused;
  Future<void> _run(ArcAmplificationState Function(ArcAmplificationState) operation) async {
    if(_busy)return;
    setState(()=>_busy=true);
    try {await _repo.update(operation);} catch(error){
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Research not saved: $error')));
    } finally {if(mounted)setState(()=>_busy=false);}
  }
  Future<int?> _number(String title,int original,{int? max}) async {
    final controller=TextEditingController(text:original.toString());
    try {
      return await showDialog<int>(context:context,builder:(context)=>AlertDialog(
        title:Text(title),content:TextField(controller:controller,keyboardType:TextInputType.number,
          autofocus:true,decoration:const InputDecoration(labelText:'Quantity',helperText:'Enter your actual in-game amount')),
        actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Cancel')),
          FilledButton(onPressed:(){final value=int.tryParse(controller.text.trim());
            if(value==null || value<0 || (max!=null && value>max) || value>999999999)return;
            Navigator.pop(context,value);
          },child:const Text('Save'))],
      ));
    } finally {controller.dispose();}
  }
  Future<void> _setPoints(ArcAmplificationState s) async {
    final n=await _number('Available Research Points',s.researchPoints);
    if(n!=null && mounted) await _run((state)=>state.setPoints(n));
  }
  Future<void> _study(ArcAmplificationState s) async {
    final name=await showDialog<String>(context:context,builder:(context)=>SimpleDialog(
      title:const Text('Research item studied'),children:[for(final entry in ArcAmplificationCatalog.researchItemPoints.entries)
        SimpleDialogOption(onPressed:()=>Navigator.pop(context,entry.key),child:Text('${entry.key} · +${entry.value} RP'))]));
    if(!mounted || name==null)return;
    final count=await _number('How many $name did you study?',1,max:99999);
    if(count!=null && count>0 && mounted)await _run((state)=>state.study(name,count));
  }
  Future<void> _material(ArcAmplificationProject p,ArcAmplificationState s) async {
    final n=await _number('${p.material} in your stash',s.materials[p.material]??0,max:999999);
    if(n!=null && mounted)await _run((state)=>state.setMaterial(p.material,n));
  }
  Future<void> _objective(ArcAmplificationProject p,int index,ArcAmplificationState s) async {
    final n=await _number(p.objectives[index].label,s.objectiveCount(p.id,index),max:p.objectives[index].target);
    if(n!=null && mounted)await _run((state)=>state.setObjective(p.id,index,n));
  }
  Future<void> _complete(ArcAmplificationProject p) async {
    final approve=await showDialog<bool>(context:context,builder:(context)=>AlertDialog(
      title:Text('Complete ${p.title}?'),
      content:Text('Only confirm after completing this research in-game. Your UAG balance will deduct 5,000 Research Points and ${p.materialCount} ${p.material}(s).'),
      actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Cancel')),
        FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Confirm completion'))]));
    if(approve==true && mounted)await _run((state)=>state.complete(p.id));
  }
  void _showTradeBrief(ArcAmplificationProject p,ArcAmplificationState s) async {
    final missing=s.shortage(p.id);
    if(missing==0)return;
    final text='UAG ARC Raiders · Amplification research: ${p.title}. Wanted: $missing × ${p.material}. Research Points are not tradeable. Please confirm this material can be traded before arranging any exchange.';
    await Clipboard.setData(ClipboardData(text:text));
    if(!mounted)return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Material request copied. Check trade eligibility before posting.')));
    Navigator.push(context,MaterialPageRoute<void>(builder:(_)=>const TraderHubScreen(initialIndex:1)));
  }
  Widget _chip(String text,{Color color=ArcUiTokens.primaryAccent})=>Container(
    padding:const EdgeInsets.symmetric(horizontal:9,vertical:5),
    decoration:BoxDecoration(color:color.withValues(alpha:0.10),border:Border.all(color:color.withValues(alpha:0.3)),borderRadius:BorderRadius.circular(10)),
    child:Text(text,style:TextStyle(color:color,fontSize:12,fontWeight:FontWeight.w600)));
  Widget _card(Widget child)=>Container(
    padding:const EdgeInsets.all(12),
    decoration:BoxDecoration(color:ArcUiTokens.surfacePanel,borderRadius:BorderRadius.circular(12),border:Border.all(color:ArcUiTokens.primaryAccent.withValues(alpha:.24))),child:child);

  @override
  Widget build(BuildContext context){
    return StreamBuilder<ArcAmplificationState>(
      stream:_progress,builder:(context,snapshot){
        if(snapshot.hasError)return _card(Text('Research sync unavailable. Sign in or check your connection: ${snapshot.error}',style:const TextStyle(color:ArcUiTokens.warning)));
        if(!snapshot.hasData)return const Center(child:Padding(padding:EdgeInsets.all(24),child:CircularProgressIndicator()));
        final s=snapshot.data!;
        final active=s.active.map(ArcAmplificationCatalog.project).toList();
        return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
          _card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text('AMPLIFICATION RESEARCH',style:ArcUiTokens.display(fontSize:22,color:ArcUiTokens.primaryAccent)),
            const SizedBox(height:6),
            Wrap(spacing:8,runSpacing:8,children:[
              _chip('${active.length} / 5 ACTIVE'),_chip('${s.completed.length} / 15 UNLOCKED',color:ArcUiTokens.secondaryAccent),
              _chip('${s.researchPoints} RP AVAILABLE',color:ArcUiTokens.success),
            ]),
            const SizedBox(height:8),
            const Text('Manual game tracking · synced to your UAG account. Progress is not read from the console. Research unlocks perks; a weapon must still be amplified and upgraded in-game.',style:TextStyle(color:ArcUiTokens.textSecondary,fontSize:12)),
            Wrap(spacing:6,children:[
              TextButton.icon(onPressed:_busy?null:()=>_setPoints(s),icon:const Icon(Icons.edit_note),label:const Text('Set RP balance')),
              TextButton.icon(onPressed:_busy?null:()=>_study(s),icon:const Icon(Icons.menu_book),label:const Text('Study an item')),
            ]),
          ])),
          const SizedBox(height:12),
          for(final p in active) ...[_projectCard(p,s),const SizedBox(height:9)],
          _card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text('RESEARCH CATALOGUE',style:ArcUiTokens.display(fontSize:19,color:ArcUiTokens.secondaryAccent)),
            const SizedBox(height:7),
            for(final p in ArcAmplificationCatalog.projects) if(!s.active.contains(p.id))
              ListTile(contentPadding:EdgeInsets.zero,dense:true,title:Text(p.title,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold)),
                subtitle:Text('${p.perk} · ${p.weapons.join(', ')}',style:const TextStyle(color:ArcUiTokens.textSecondary)),
                trailing:s.completed.contains(p.id)?const Icon(Icons.verified,color:ArcUiTokens.success):
                  TextButton(onPressed:(_busy || !s.canStartMore)?null:()=>_run((state)=>state.start(p.id)),child:const Text('Start')),
                onTap:()=>setState(()=>_focused==p.id ? _focused=null : _focused=p.id),
              ),
            if(_focused!=null && !s.active.contains(_focused))
              Builder(builder:(_){final p=ArcAmplificationCatalog.project(_focused!);
                return _card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Text(p.title,style:const TextStyle(color:ArcUiTokens.primaryAccent,fontWeight:FontWeight.bold)),
                  ...p.objectives.map((o)=>Text('• ${o.label}: ${o.target}',style:const TextStyle(color:ArcUiTokens.textSecondary))),
                  Text('Step 2: 5,000 RP + ${p.materialCount} × ${p.material}',style:const TextStyle(color:ArcUiTokens.textSecondary)),
                ]));}),
          ])),
        ]);
      });
  }
  Widget _projectCard(ArcAmplificationProject p,ArcAmplificationState s){
    final complete=s.canComplete(p.id);
    return _card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(p.title.toUpperCase(),style:ArcUiTokens.display(fontSize:19,color:ArcUiTokens.primaryAccent)),
          Text('${p.perk} · ${p.weapons.join(' / ')}',style:const TextStyle(color:ArcUiTokens.textSecondary,fontSize:12)),
        ])),
        IconButton(onPressed:_busy?null:()=>_run((state)=>state.pause(p.id)),tooltip:'Pause research (keeps progress)',icon:const Icon(Icons.remove_circle_outline,color:ArcUiTokens.warning)),
      ]),
      const SizedBox(height:8),
      _chip(s.objectivesDone(p.id)?'STEP 2 · HAND IN MATERIALS':'STEP 1 · RAID OBJECTIVES',color:s.objectivesDone(p.id)?ArcUiTokens.success:ArcUiTokens.warning),
      const SizedBox(height:6),
      for(var i=0;i<p.objectives.length;i++) ...[
        Builder(builder:(context){final o=p.objectives[i]; final current=s.objectiveCount(p.id,i);
          return Padding(padding:const EdgeInsets.only(top:5),child:InkWell(onTap:_busy?null:()=>_objective(p,i,s),child:Row(children:[
            Icon(current>=o.target?Icons.check_circle:Icons.radio_button_unchecked,color:current>=o.target?ArcUiTokens.success:ArcUiTokens.textSecondary,size:19),
            const SizedBox(width:7),
            Expanded(child:Text(o.label,style:const TextStyle(color:ArcUiTokens.textPrimary,fontSize:12))),
            Text('$current/${o.target}',style:const TextStyle(color:ArcUiTokens.primaryAccent,fontSize:12)),
            const Icon(Icons.edit,color:ArcUiTokens.textTertiary,size:16),
          ])));}),
      ],
      if(p.sourceNote!=null)Padding(padding:const EdgeInsets.only(top:7),child:Text(p.sourceNote!,style:const TextStyle(color:ArcUiTokens.warning,fontSize:12))),
      const Divider(),
      Row(children:[
        Expanded(child:Text('Research Points: ${s.researchPoints} / 5,000',style:const TextStyle(color:ArcUiTokens.textSecondary,fontSize:12))),
        TextButton(onPressed:_busy?null:()=>_setPoints(s),child:const Text('Edit RP')),
      ]),
      Row(children:[
        Expanded(child:Text('${p.material}: ${s.materials[p.material]??0} / ${p.materialCount}',style:const TextStyle(color:ArcUiTokens.textSecondary,fontSize:12))),
        TextButton(onPressed:_busy?null:()=>_material(p,s),child:const Text('Edit stock')),
      ]),
      Wrap(spacing:7,runSpacing:6,children:[
        OutlinedButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute<void>(builder:(_)=>ArcRaidIntelligenceScreen(initialMapId:p.suggestedMap,initialSearchQuery:p.targetEnemy))),icon:const Icon(Icons.map_outlined,size:17),label:Text(p.targetEnemy==null?'Open raid maps':'Find ${p.targetEnemy}')),
        if(s.shortage(p.id)>0)OutlinedButton.icon(onPressed:()=>_showTradeBrief(p,s),icon:const Icon(Icons.swap_horiz,size:17),label:Text('Trade brief: ${s.shortage(p.id)} needed')),
        FilledButton(onPressed:(_busy || !complete)?null:()=>_complete(p),child:const Text('Complete in-game research')),
      ]),
      const Text('Map opens existing marker filters; enemy spawn availability is not guaranteed. Trade eligibility must be verified in-game.',style:TextStyle(color:ArcUiTokens.textTertiary,fontSize:11)),
    ]));
  }
}

/// Compact, independent read-only preview; does not alter any locked
/// Favourite Loadout attachment, slot or ownership behavior.
class ArcAmplificationLoadoutPanel extends StatefulWidget {
  const ArcAmplificationLoadoutPanel({super.key,required this.primary,required this.secondary});
  final String primary;
  final String secondary;
  @override
  State<ArcAmplificationLoadoutPanel> createState()=>_ArcAmplificationLoadoutPanelState();
}
class _ArcAmplificationLoadoutPanelState extends State<ArcAmplificationLoadoutPanel> {
  late final Stream<ArcAmplificationState> _progress;
  @override
  void initState(){super.initState();_progress=ArcAmplificationRepository().watch();}
  @override
  Widget build(BuildContext context)=>StreamBuilder<ArcAmplificationState>(
    stream:_progress,builder:(context,snapshot){
      final progress=snapshot.data;
      return Container(
        padding:const EdgeInsets.all(10),
        decoration:BoxDecoration(color:ArcUiTokens.surfacePanel,border:Border.all(color:ArcUiTokens.secondaryAccent.withValues(alpha:.32)),borderRadius:BorderRadius.circular(10)),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[
            Expanded(child:Text('AMPLIFIED WEAPON RESEARCH',style:ArcUiTokens.display(fontSize:17,color:ArcUiTokens.secondaryAccent))),
            TextButton(onPressed:()=>Navigator.of(context).pushNamed('/trading-hub/arc-raiders/research-workstation'),child:const Text('Research Station')),
          ]),
          if(snapshot.hasError)const Text('Research sync unavailable',style:TextStyle(color:ArcUiTokens.warning))
          else if(progress==null)const LinearProgressIndicator()
          else for(final weapon in <String>{widget.primary,widget.secondary}) if(ArcAmplificationCatalog.moduleByWeapon.containsKey(weapon))
            _WeaponPerkLine(weapon:weapon,state:progress),
          const Text('Research unlock and installed weapon perks are separate. Weapon upgrades must be confirmed manually.',style:TextStyle(color:ArcUiTokens.textTertiary,fontSize:11)),
        ]),
      );
    });
}
class _WeaponPerkLine extends StatelessWidget {
  Future<void> _editStock(BuildContext context,String name,int current) async {
    final controller=TextEditingController(text:current.toString());
    try {
      final next=await showDialog<int>(context:context,builder:(dialogContext)=>AlertDialog(
        title:Text('Available $name'),
        content:TextField(controller:controller,autofocus:true,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Actual in-game stash quantity')),
        actions:[TextButton(onPressed:()=>Navigator.pop(dialogContext),child:const Text('Cancel')),
          FilledButton(onPressed:(){final n=int.tryParse(controller.text);if(n!=null && n>=0 && n<=999999)Navigator.pop(dialogContext,n);},child:const Text('Save'))],
      ));
      if(next!=null && context.mounted){
        await ArcAmplificationRepository().update((s)=>s.setMaterial(name,next));
      }
    } catch(error){
      if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Stock not saved: $error')));
    } finally {controller.dispose();}
  }
  Future<void> _apply(BuildContext context,String weapon,String id,String title) async {
    final confirmed=await showDialog<bool>(context:context,builder:(dialogContext)=>AlertDialog(
      title:const Text('Confirm installed in-game'),
      content:Text('Only confirm if $title has actually been applied to your $weapon in ARC Raiders. Amplifications are permanent. The saved node materials will be deducted.'),
      actions:[TextButton(onPressed:()=>Navigator.pop(dialogContext,false),child:const Text('Cancel')),
        FilledButton(onPressed:()=>Navigator.pop(dialogContext,true),child:const Text('Confirm applied'))],
    ));
    if(confirmed==true && context.mounted){
      try{await ArcAmplificationRepository().update((s)=>s.confirmApplied(weapon,id));}
      catch(error){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Perk not marked as applied: $error')));}
    }
  }
  const _WeaponPerkLine({required this.weapon,required this.state});
  final String weapon;
  final ArcAmplificationState state;
  @override
  Widget build(BuildContext context){
    final research=ArcAmplificationCatalog.forWeapon(weapon);
    final selected=state.plannedPerks[weapon];
    final marked=selected==null?null:ArcAmplificationCatalog.project(selected);
    final installed=selected!=null && (state.installedPerks[weapon]?.contains(selected)??false);
    return Padding(padding:const EdgeInsets.only(bottom:8),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text('$weapon · Mk. ${ArcAmplificationCatalog.moduleByWeapon[weapon]}',style:const TextStyle(color:ArcUiTokens.textPrimary,fontWeight:FontWeight.bold)),
      Row(children:[
        Expanded(child:DropdownButton<String?>(isExpanded:true,value:selected,dropdownColor:ArcUiTokens.surfaceRaised,
          hint:const Text('Select research goal',style:TextStyle(color:ArcUiTokens.textSecondary)),
          items:[const DropdownMenuItem<String?>(value:null,child:Text('No planned perk')),
            for(final p in research)DropdownMenuItem<String?>(value:p.id,child:Text(p.perk,overflow:TextOverflow.ellipsis))],
          onChanged:(id) async {
            try {await ArcAmplificationRepository().update((s)=>s.planPerk(weapon,id));}
            catch(error){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not save perk choice: $error')));}
          },)),
        if(marked!=null)Icon(installed?Icons.verified:state.completed.contains(marked.id)?Icons.lock_open_rounded:Icons.lock_outline,
          color:installed?ArcUiTokens.success:ArcUiTokens.warning),
      ]),
      if(marked!=null) ...[
        if(ArcAmplificationCatalog.nodeCost(weapon,marked.id)!=null)
          for(final item in ArcAmplificationCatalog.nodeCost(weapon,marked.id)!.entries)
            Row(children:[
              Expanded(child:Text('Node: ${item.value} × ${item.key} · have ${state.materials[item.key]??0}',style:const TextStyle(color:ArcUiTokens.textSecondary,fontSize:12))),
              TextButton(onPressed:()=>_editStock(context,item.key,state.materials[item.key]??0),child:const Text('Edit stock')),
            ]),
        if(ArcAmplificationCatalog.nodePrerequisite(weapon,marked.id)!=null)
          Text(ArcAmplificationCatalog.nodePrerequisite(weapon,marked.id)!,style:const TextStyle(color:ArcUiTokens.warning,fontSize:12)),
        Wrap(spacing:8,crossAxisAlignment:WrapCrossAlignment.center,children:[
        Text(installed?'Applied in-game':state.completed.contains(marked.id)?'Research unlocked; not applied':'Research locked',style:const TextStyle(color:ArcUiTokens.textSecondary,fontSize:12)),
        if(state.completed.contains(marked.id) && !installed)
          TextButton(onPressed:state.missingNodeMaterials(weapon,marked.id).isEmpty
            ?()=>_apply(context,weapon,marked.id,marked.perk):null,child:const Text('Confirm applied in-game')),
        ]),
      ],
    ]));
  }
}
