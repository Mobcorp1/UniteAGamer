import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_raid_intelligence_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trader_hub_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'arc_amplification_catalog.dart';
import 'arc_amplification_repository.dart';
import 'arc_amplification_state.dart';
import 'arc_research_quantity_dialog.dart';

/// Full shared progress editor, displayed inside the Research Workstation.
class ArcAmplificationWorkspace extends StatefulWidget {
  const ArcAmplificationWorkspace({super.key, this.initialProjectId});
  final String? initialProjectId;
  @override
  State<ArcAmplificationWorkspace> createState()=>_ArcAmplificationWorkspaceState();
}
class _ArcAmplificationWorkspaceState extends State<ArcAmplificationWorkspace> {
  final ArcAmplificationRepository _repo=ArcAmplificationRepository();
  late final Stream<ArcAmplificationState> _progress;
  @override
  void initState(){
    super.initState();
    _progress=_repo.watch();
    _focused=widget.initialProjectId;
    if (_focused != null) {
      _openProjects.add(_focused!);
      _showCatalogue=true;
    }
  }
  bool _busy=false;
  String? _focused;
  bool _showCatalogue = false;
  final Set<String> _openProjects = <String>{};
  Future<void> _run(ArcAmplificationState Function(ArcAmplificationState) operation) async {
    if(_busy)return;
    setState(()=>_busy=true);
    try {await _repo.update(operation);} catch(_){
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Research not saved. Try again.')));
    } finally {if(mounted)setState(()=>_busy=false);}
  }
  Future<int?> _number(String title, int original, {int? max}) =>
      showDialog<int>(
        context: context,
        builder: (_) => ArcResearchQuantityDialog(
          title: title,
          initialValue: original,
          maxValue: max ?? 999999,
        ),
      );

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
  Future<void> _completeObjective(ArcAmplificationProject p,int index) async {
    final objective = p.objectives[index];
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mark objective complete?'),
        content: Text('Confirm you completed "${objective.label}" in ARC Raiders.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Complete')),
        ],
      ),
    );
    if (approved == true && mounted) {
      await _run((state) => state.setObjective(p.id,index,objective.target));
    }
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

  String _artwork(ArcAmplificationProject project) {
    final id = project.id == 'magazine_geometry_101'
        ? 'magazine_geometry' : project.id;
    return 'assets/arc_raiders/blueprints/$id.webp';
  }

  Widget _projectArtwork(ArcAmplificationProject project,
      {double size = 56, bool completed = false}) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: ArcUiTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: completed ? ArcUiTokens.success.withValues(alpha: .7)
              : ArcUiTokens.primaryAccent.withValues(alpha: .34),
        ),
      ),
      child: ColorFiltered(
        colorFilter: completed
            ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
            : const ColorFilter.matrix(<double>[
                .28, .59, .11, 0, 0,
                .28, .59, .11, 0, 0,
                .28, .59, .11, 0, 0,
                0, 0, 0, 1, 0,
              ]),
        child: Image.asset(
          _artwork(project),
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const Icon(
            Icons.memory_outlined, color: ArcUiTokens.textTertiary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ArcAmplificationState>(
      stream: _progress,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _card(const Text('Research unavailable. Try again.',
              style: TextStyle(color: ArcUiTokens.warning)));
        }
        if (!snapshot.hasData) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
        }
        final s = snapshot.data!;
        final active = s.active.map(ArcAmplificationCatalog.project).toList();
        final stepOne = active.where((p) => !s.objectivesDone(p.id)).toList();
        final stepTwo = active.where((p) => s.objectivesDone(p.id)).toList();
        final inactive = ArcAmplificationCatalog.projects
            .where((p) => !s.active.contains(p.id)).toList(growable: false);
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: ArcUiTokens.surfacePanel,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ArcUiTokens.primaryAccent.withValues(alpha: .35)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: ArcUiTokens.primaryAccent.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(9)),
                        child: const Icon(Icons.bolt_rounded,
                            color: ArcUiTokens.primaryAccent, size: 24),
                      ),
                      const SizedBox(width: 9),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AMPLIFICATION PROJECTS', maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ArcUiTokens.display(fontSize: 17,
                                color: ArcUiTokens.primaryAccent)),
                          const SizedBox(height: 3),
                          Text('${s.stepOneActiveCount}/5 STEP 1  |  '
                              '${s.stepTwoActiveCount} STEP 2  |  '
                              '${s.completed.length}/15 COMPLETE  |  '
                              '${s.researchPoints} RP',
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: ArcUiTokens.textSecondary, fontSize: 11)),
                        ],
                      )),
                      PopupMenuButton<String>(
                        tooltip: 'Research actions',
                        icon: const Icon(Icons.more_vert_rounded,
                            color: ArcUiTokens.primaryAccent),
                        onSelected: (value) {
                          if (value == 'rp') _setPoints(s);
                          if (value == 'study') _study(s);
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'rp', child: Text('Set Research Points')),
                          PopupMenuItem(value: 'study', child: Text('Study items')),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _activeStageSection(
                  label: 'STEP 1 - RAID OBJECTIVES',
                  projects: stepOne,
                  state: s,
                  accent: ArcUiTokens.primaryAccent,
                ),
                const SizedBox(height: 12),
                _activeStageSection(
                  label: 'STEP 2 - MATERIALS & RESEARCH',
                  projects: stepTwo,
                  state: s,
                  accent: ArcUiTokens.secondaryAccent,
                ),
                const SizedBox(height: 9),
                const SizedBox(height: 5),
                Container(
                  decoration: BoxDecoration(
                    color: ArcUiTokens.surfacePanel,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color:
                        ArcUiTokens.secondaryAccent.withValues(alpha: .34)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      InkWell(
                        onTap: () => setState(() => _showCatalogue = !_showCatalogue),
                        child: Row(children: [
                          const Icon(Icons.grid_view_rounded,
                              color: ArcUiTokens.secondaryAccent, size: 20),
                          const SizedBox(width: 7),
                          Expanded(child: Text('BROWSE RESEARCH',
                              style: ArcUiTokens.display(fontSize: 17,
                                  color: ArcUiTokens.secondaryAccent))),
                          _chip('${inactive.length} PROJECTS',
                              color: ArcUiTokens.secondaryAccent),
                          Icon(_showCatalogue ? Icons.expand_less : Icons.expand_more,
                              color: ArcUiTokens.secondaryAccent),
                        ]),
                      ),
                      if (_showCatalogue) ...[
                        const SizedBox(height: 10),
                        LayoutBuilder(builder: (context, constraints) {
                          final columns = constraints.maxWidth >= 440 ? 2 : 1;
                          final tileWidth = (constraints.maxWidth - (columns - 1) * 8)
                              / columns;
                          return Wrap(spacing: 8, runSpacing: 8, children: [
                            for (final p in inactive)
                              SizedBox(width: tileWidth,
                                child: InkWell(
                                  onTap: () => setState(() =>
                                      _focused = _focused == p.id ? null : p.id),
                                  child: Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: ArcUiTokens.surfaceRaised,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: (_focused == p.id
                                          ? ArcUiTokens.secondaryAccent
                                          : ArcUiTokens.primaryAccent)
                                          .withValues(alpha: .4)),
                                    ),
                                    child: Row(children: [
                                      _projectArtwork(p, size: 48,
                                          completed: s.completed.contains(p.id)),
                                      const SizedBox(width: 7),
                                      Expanded(child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(p.title.toUpperCase(), maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: ArcUiTokens.textPrimary,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 11, height: 1.1)),
                                          const SizedBox(height: 3),
                                          if (s.completed.contains(p.id))
                                            const Text('COMPLETE', style: TextStyle(
                                                color: ArcUiTokens.success, fontSize: 10))
                                          else SizedBox(height: 26,
                                            child: TextButton(
                                              onPressed: (_busy || !s.canStartMore)
                                                  ? null : () => _run((state) => state.start(p.id)),
                                              style: TextButton.styleFrom(
                                                padding: EdgeInsets.zero,
                                                minimumSize: const Size(48, 26)),
                                              child: const Text('START', style: TextStyle(fontSize: 11)),
                                            ),
                                          ),
                                        ],
                                      )),
                                    ]),
                                  ),
                                ),
                              ),
                          ]);
                        }),
                        if (_focused != null && !s.active.contains(_focused))
                          Builder(builder: (_) {
                            final p = ArcAmplificationCatalog.project(_focused!);
                            return Padding(
                              padding: const EdgeInsets.only(top: 9),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.title.toUpperCase(), style: const TextStyle(
                                      color: ArcUiTokens.primaryAccent,
                                      fontWeight: FontWeight.bold)),
                                  Text(p.perk, style: const TextStyle(
                                      color: ArcUiTokens.textSecondary, fontSize: 12)),
                                  for (final objective in p.objectives)
                                    Text('${objective.label} (${objective.target})',
                                      style: const TextStyle(
                                          color: ArcUiTokens.textSecondary, fontSize: 12)),
                                  Text('5000 RP | ${p.materialCount} x ${p.material}',
                                    style: const TextStyle(
                                        color: ArcUiTokens.textSecondary, fontSize: 12)),
                                ],
                              ),
                            );
                          }),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  /// Shared research-stage layout. Its colours and spacing use the same UAG
  /// theme tokens as other Collections surfaces, without duplicating state.
  Widget _activeStageSection({
    required String label,
    required List<ArcAmplificationProject> projects,
    required ArcAmplificationState state,
    required Color accent,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Expanded(child: Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ArcUiTokens.display(fontSize: 17, color: accent))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .12),
              border: Border.all(color: accent.withValues(alpha: .65)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('${projects.length}${label.startsWith('STEP 1') ? '/5' : ''}',
              style: TextStyle(color: accent, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 7),
        if (projects.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            decoration: BoxDecoration(
              color: ArcUiTokens.surfacePanel,
              border: Border.all(color: accent.withValues(alpha: .25)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('No projects in this stage',
              style: const TextStyle(color: ArcUiTokens.textSecondary)),
          )
        else
          LayoutBuilder(builder: (context, constraints) {
            final columns = constraints.maxWidth >= 850
                ? 3 : constraints.maxWidth >= 540 ? 2 : 1;
            final itemWidth = (constraints.maxWidth - (columns - 1) * 9) / columns;
            return Wrap(
              spacing: 9,
              runSpacing: 9,
              children: [
                for (final project in projects)
                  SizedBox(width: itemWidth,
                    child: _activeCompactCard(project, state, accent)),
              ],
            );
          }),
        for (final project in projects)
          if (_openProjects.contains(project.id))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: _projectCard(project, state),
                ),
              ),
            ),
      ],
    );
  }

  Widget _activeCompactCard(
      ArcAmplificationProject project,
      ArcAmplificationState state,
      Color accent) {
    final expanded = _openProjects.contains(project.id);
    final completedObjectives = project.objectives.asMap().entries
        .where((entry) => state.objectiveCount(project.id, entry.key)
            >= entry.value.target)
        .length;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: () => setState(() {
          if (expanded) {
            _openProjects.remove(project.id);
          } else {
            _openProjects.add(project.id);
          }
        }),
        child: Container(
          height: 94,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ArcUiTokens.surfacePanel,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: accent.withValues(alpha: expanded ? .95 : .62),
              width: expanded ? 1.8 : 1,
            ),
          ),
          child: Row(children: [
            _projectArtwork(project, size: 60),
            const SizedBox(width: 9),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(project.title.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ArcUiTokens.textPrimary,
                    fontWeight: FontWeight.w700,
                    height: 1.08,
                    fontSize: 13,
                  )),
                const SizedBox(height: 6),
                Text('$completedObjectives/${project.objectives.length} OBJECTIVES',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  )),
                if (state.shortage(project.id) > 0)
                  Text('${state.shortage(project.id)} MATERIALS NEEDED',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ArcUiTokens.textSecondary,
                      fontSize: 10,
                    )),
              ],
            )),
            Icon(expanded ? Icons.expand_less : Icons.expand_more,
              size: 18, color: accent),
          ]),
        ),
      ),
    );
  }

  String _twoLineTitle(String title) {
    final words = title.toUpperCase().split(' ');
    if (words.length < 3) return title.toUpperCase();
    var split = 1;
    var best = 100000;
    for (var i = 1; i < words.length; i++) {
      final left = words.take(i).join(' ').length;
      final right = words.skip(i).join(' ').length;
      final difference = (left - right).abs();
      if (difference < best) {
        best = difference;
        split = i;
      }
    }
    return '${words.take(split).join(' ')}\n${words.skip(split).join(' ')}';
  }

  Widget _projectCard(ArcAmplificationProject p,ArcAmplificationState s){
    final complete=s.canComplete(p.id);
    final expanded=_openProjects.contains(p.id);
    final objectivesDone=p.objectives.where((o)=>s.objectiveCount(p.id,p.objectives.indexOf(o))>=o.target).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: ArcUiTokens.surfacePanel,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: ArcUiTokens.primaryAccent.withValues(alpha: .37)),
      ),
      child: Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      InkWell(
        onTap:()=>setState(()=>expanded?_openProjects.remove(p.id):_openProjects.add(p.id)),
        child:Row(children:[
          _projectArtwork(p, size: 54, completed: s.completed.contains(p.id)),
          const SizedBox(width:8),
          Icon(expanded?Icons.expand_less:Icons.expand_more,color:ArcUiTokens.primaryAccent, size:19),
          const SizedBox(width:4),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(_twoLineTitle(p.title),maxLines:2,overflow:TextOverflow.ellipsis,style:ArcUiTokens.display(fontSize:16,color:ArcUiTokens.primaryAccent)),
            Text('$objectivesDone/${p.objectives.length} OBJECTIVES · ${s.shortage(p.id)} MATERIALS NEEDED',style:const TextStyle(color:ArcUiTokens.textSecondary,fontSize:11)),
          ])),
          Icon(complete?Icons.check_circle:Icons.radio_button_unchecked,color:complete?ArcUiTokens.success:ArcUiTokens.textTertiary,size:19),
        ]),
      ),
      if(expanded) ...[
      const SizedBox(height:9),
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
          return Padding(padding: const EdgeInsets.only(top: 5), child: Row(children: [
            Icon(current >= o.target ? Icons.check_circle : Icons.radio_button_unchecked,
              color: current >= o.target ? ArcUiTokens.success : ArcUiTokens.textSecondary, size: 19),
            const SizedBox(width: 7),
            Expanded(child: Text(o.label, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: ArcUiTokens.textPrimary, fontSize: 12))),
            Text('$current/${o.target}', style: const TextStyle(color: ArcUiTokens.primaryAccent, fontSize: 12)),
            if (current < o.target) TextButton(
              onPressed: _busy ? null : () => _completeObjective(p,i),
              child: const Text('COMPLETE')),
            IconButton(
              tooltip: 'Edit partial objective count',
              onPressed: _busy ? null : () => _objective(p,i,s),
              icon: const Icon(Icons.edit, color: ArcUiTokens.textTertiary, size: 16)),
          ]));}),
      ],
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
        OutlinedButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute<void>(builder:(_)=>ArcRaidIntelligenceScreen(initialMapId:p.suggestedMap))),icon:const Icon(Icons.map_outlined,size:17),label:Text(p.targetEnemy==null?'Open raid maps':'Find ${p.targetEnemy}')),
        if(s.shortage(p.id)>0)OutlinedButton.icon(onPressed:()=>_showTradeBrief(p,s),icon:const Icon(Icons.swap_horiz,size:17),label:Text('Trade brief: ${s.shortage(p.id)} needed')),
        FilledButton(onPressed:(_busy || !complete)?null:()=>_complete(p),child:const Text('Complete in-game research')),
      ]),
      ],
    ]));
  }
}

/// One distinct Amplification Mod slot beside each weapon's regular attachments.
/// The slot does not modify the original attachment list or saved-loadout schema.
/// Perk planning and actual in-game application live in the shared research state.
class ArcAmplificationAttachmentSlot extends StatefulWidget {
  const ArcAmplificationAttachmentSlot({
    super.key,
    required this.weapon,
    required this.accent,
    this.compact = false,
    this.size = 46,
    this.progressStream,
  });

  final String weapon;
  final Color accent;
  final bool compact;
  final double size;
  /// Optional deterministic progress source for widget testing.
  final Stream<ArcAmplificationState>? progressStream;

  @override
  State<ArcAmplificationAttachmentSlot> createState() =>
      _ArcAmplificationAttachmentSlotState();
}

class _ArcAmplificationAttachmentSlotState
    extends State<ArcAmplificationAttachmentSlot> {
  late final Stream<ArcAmplificationState> _progress;
  ArcAmplificationState? _lastState;

  @override
  void initState() {
    super.initState();
    // The attachment chip and its bottom sheet can be mounted at the same
    // time. Keep one upstream listener, even when a test passes Stream.value
    // (a single-subscription stream) as the deterministic progress source.
    _progress = (widget.progressStream ?? ArcAmplificationRepository().watch())
        .asBroadcastStream(onCancel: (subscription) => subscription.cancel());
  }

  Future<void> _openEditor() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(12),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.82,
          ),
          decoration: ArcUiTokens.surfaceDecoration(
            role: ArcSurfaceRole.overlay,
            accent: widget.accent,
            radius: ArcUiTokens.radiusXL,
            borderOpacity: 0.35,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${widget.weapon.toUpperCase()} · AMPLIFICATION MOD',
                        style: ArcUiTokens.sectionTitle(
                          fontSize: 20,
                          color: widget.accent,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: ArcUiTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Select a perk for this weapon.',
                  style: ArcUiTokens.bodySmall(
                    color: ArcUiTokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                StreamBuilder<ArcAmplificationState>(
                  // Broadcast streams do not replay their last event for a
                  // newly opened sheet. Seed it from the chip's last value.
                  initialData: _lastState,
                  stream: _progress,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Text(
                        'Research sync unavailable. Check your account or connection.',
                        style: TextStyle(color: ArcUiTokens.warning),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return _WeaponPerkLine(
                      weapon: widget.weapon,
                      state: snapshot.data!,
                    );
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      Navigator.of(context).pushNamed(
                        '/trading-hub/arc-raiders/research-workstation',
                      );
                    },
                    icon: const Icon(Icons.science_outlined),
                    label: const Text('Open Research Station'),
                  ),
                ),
                Text(
                  'Mark upgrades after applying them in-game.',
                  style: ArcUiTokens.bodySmall(
                    color: ArcUiTokens.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!ArcAmplificationCatalog.moduleByWeapon.containsKey(widget.weapon)) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<ArcAmplificationState>(
      stream: _progress,
      builder: (context, snapshot) {
        if (snapshot.hasData) _lastState = snapshot.data;
        final state = snapshot.data;
        final selected = state?.plannedPerks[widget.weapon];
        final perk = selected == null
            ? null
            : ArcAmplificationCatalog.project(selected);
        final installed = selected != null &&
            (state?.installedPerks[widget.weapon]?.contains(selected) ?? false);
        final unlocked = perk != null &&
            (state?.completed.contains(perk.id) ?? false);
        final status = snapshot.hasError
            ? 'Sync error'
            : state == null
                ? 'Loading'
                : installed
                    ? 'Applied'
                    : unlocked
                        ? 'Unlocked'
                        : perk == null
                            ? 'Not set'
                            : 'Research';
        final statusColor = installed
            ? ArcUiTokens.success
            : perk == null
                ? widget.accent
                : ArcUiTokens.warning;

        return Tooltip(
          message: 'Amplification Mod: ${perk?.perk ?? 'Empty'} · $status',
          child: Semantics(
            button: true,
            label: 'Edit ${widget.weapon} Amplification Mod',
            child: InkWell(
              onTap: snapshot.hasError ? null : _openEditor,
              borderRadius: BorderRadius.circular(ArcUiTokens.radiusM),
              child: widget.compact
                  ? Container(
                      width: widget.size,
                      height: widget.size,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.42),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            installed
                                ? Icons.verified_rounded
                                : Icons.bolt_rounded,
                            color: statusColor,
                            size: widget.size * 0.43,
                          ),
                          Text(
                            'AMP',
                            style: TextStyle(
                              color: widget.accent,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(
                      width: 148,
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(ArcUiTokens.radiusM),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.42),
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 34,
                            height: 34,
                            child: Icon(
                              installed
                                  ? Icons.verified_rounded
                                  : Icons.bolt_rounded,
                              color: statusColor,
                              size: 29,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'AMPLIFICATION',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: ArcUiTokens.label(
                                    color: widget.accent,
                                  ).copyWith(fontSize: 8),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  perk?.perk ?? 'Empty',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: ArcUiTokens.textPrimary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  status,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 8.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _WeaponPerkLine extends StatelessWidget {
  Future<void> _editStock(BuildContext context,String name,int current) async {
    try {
      final next=await showDialog<int>(
        context:context,
        builder:(_)=>ArcResearchQuantityDialog(
          title:'Available $name',
          initialValue:current,
        ),
      );
      if(next!=null && context.mounted){
        await ArcAmplificationRepository().update((s)=>s.setMaterial(name,next));
      }
    } catch(_){
      if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Stock not saved. Try again.')));
    }
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
      catch(_){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Perk not saved. Try again.')));}
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
            catch(_){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Perk selection not saved. Try again.')));}
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
