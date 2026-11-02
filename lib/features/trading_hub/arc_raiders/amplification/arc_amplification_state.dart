import 'arc_amplification_catalog.dart';

/// The player maintains this progress manually. It never pretends to sync from
/// the ARC Raiders game or to know actual inventory/weapon upgrade state.
class ArcAmplificationState {
  const ArcAmplificationState({
    this.researchPoints = 0,
    this.active = const <String>[],
    this.completed = const <String>[],
    this.objectives = const <String, List<int>>{},
    this.materials = const <String, int>{},
    this.plannedPerks = const <String, String>{},
    this.installedPerks = const <String, List<String>>{},
  });
  final int researchPoints;
  final List<String> active;
  final List<String> completed;
  final Map<String, List<int>> objectives;
  final Map<String, int> materials;
  final Map<String, String> plannedPerks;
  final Map<String, List<String>> installedPerks;

  static const ArcAmplificationState empty = ArcAmplificationState();
  factory ArcAmplificationState.fromMap(Map<String, dynamic>? json) {
    if (json == null) return empty;
    final ids = ArcAmplificationCatalog.projects.map((p) => p.id).toSet();
    final parsedActive = ((json['active'] as List?) ?? const [])
        .whereType<String>().where(ids.contains).toSet().take(ArcAmplificationCatalog.maxActive).toList();
    final parsedCompleted = ((json['completed'] as List?) ?? const [])
        .whereType<String>().where(ids.contains).toSet().toList();
    final savedObjectives = <String, List<int>>{};
    final objectiveRaw = json['objectives'];
    if (objectiveRaw is Map) {
      for (final project in ArcAmplificationCatalog.projects) {
        final values = objectiveRaw[project.id];
        if (values is List) {
          savedObjectives[project.id] = List<int>.generate(project.objectives.length, (i) {
            final n = i < values.length && values[i] is num ? (values[i] as num).toInt() : 0;
            return n.clamp(0, project.objectives[i].target).toInt();
          });
        }
      }
    }
    final savedMaterials = <String, int>{};
    final materialsRaw = json['materials'];
    if (materialsRaw is Map) {
      for (final material in materialsRaw.keys) {
        final n = materialsRaw[material];
        if (material is String && ArcAmplificationCatalog.isKnownMaterial(material) && n is num) {
          savedMaterials[material] = n.toInt().clamp(0, 999999).toInt();
        }
      }
    }
    final planned = <String,String>{};
    if (json['plannedPerks'] is Map) {
      (json['plannedPerks'] as Map).forEach((key, value) {
        if (key is String && value is String && ArcAmplificationCatalog.forWeapon(key).any((p) => p.id == value)) planned[key] = value;
      });
    }
    final installed = <String,List<String>>{};
    if (json['installedPerks'] is Map) {
      (json['installedPerks'] as Map).forEach((key, value) {
        if (key is String && value is List) {
          installed[key] = value.whereType<String>().where((id) => ArcAmplificationCatalog.forWeapon(key).any((p)=>p.id==id)).toSet().toList();
        }
      });
    }
    return ArcAmplificationState(
      researchPoints: ((json['researchPoints'] as num?)?.toInt() ?? 0).clamp(0,999999999).toInt(),
      active: parsedActive.where((id)=>!parsedCompleted.contains(id)).toList(),
      completed: parsedCompleted,
      objectives: savedObjectives,
      materials: savedMaterials,
      plannedPerks: planned,
      installedPerks: installed,
    );
  }
  Map<String, dynamic> toMap() => <String,dynamic>{
    'researchPoints': researchPoints,
    'active': active,
    'completed': completed,
    'objectives': objectives,
    'materials': materials,
    'plannedPerks': plannedPerks,
    'installedPerks': installedPerks,
  };
  ArcAmplificationState _change({int? researchPoints,List<String>? active,List<String>? completed,Map<String,List<int>>? objectives,Map<String,int>? materials, Map<String,String>? plannedPerks,Map<String,List<String>>? installedPerks}) => ArcAmplificationState(
    researchPoints:researchPoints ?? this.researchPoints,
    active:active ?? this.active,
    completed:completed ?? this.completed,
    objectives:objectives ?? this.objectives,
    materials:materials ?? this.materials,
    plannedPerks:plannedPerks ?? this.plannedPerks,
    installedPerks:installedPerks ?? this.installedPerks,
  );
  bool get canStartMore => active.length < ArcAmplificationCatalog.maxActive;
  ArcAmplificationState start(String id) {
    ArcAmplificationCatalog.project(id);
    if (completed.contains(id) || active.contains(id)) return this;
    if (!canStartMore) throw StateError('Only five research projects may be active.');
    return _change(active:[...active,id]);
  }
  ArcAmplificationState pause(String id) {
    if (!active.contains(id)) return this;
    return _change(active:active.where((value) => value != id).toList());
  }
  int objectiveCount(String id,int index) {
    final project = ArcAmplificationCatalog.project(id);
    RangeError.checkValidIndex(index,project.objectives);
    final stored = objectives[id];
    return stored != null && index < stored.length ? stored[index] : 0;
  }
  ArcAmplificationState setObjective(String id, int index, int value) {
    final project = ArcAmplificationCatalog.project(id);
    if (!active.contains(id) || completed.contains(id)) throw StateError('Start this project before recording progress.');
    RangeError.checkValidIndex(index,project.objectives);
    if (value < 0) throw RangeError.value(value,'value');
    final counts = List<int>.generate(project.objectives.length,(i)=>objectiveCount(id,i));
    counts[index] = value.clamp(0,project.objectives[index].target).toInt();
    return _change(objectives:{...objectives,id:counts});
  }
  bool objectivesDone(String id) {
    final p = ArcAmplificationCatalog.project(id);
    return p.objectives.asMap().entries.every((e) => objectiveCount(id,e.key) >= e.value.target);
  }
  int shortage(String id) {
    final p=ArcAmplificationCatalog.project(id);
    final diff=p.materialCount - (materials[p.material] ?? 0);
    return diff < 0 ? 0 : diff;
  }
  bool canComplete(String id) {
    final p=ArcAmplificationCatalog.project(id);
    return active.contains(id) && objectivesDone(id) && researchPoints >= p.researchCost && shortage(id)==0;
  }
  ArcAmplificationState complete(String id) {
    if (!canComplete(id)) throw StateError('Research objectives, points or materials are still missing.');
    final p=ArcAmplificationCatalog.project(id);
    return _change(
      researchPoints:researchPoints-p.researchCost,
      materials:{...materials,p.material:(materials[p.material] ?? 0)-p.materialCount},
      active:active.where((value)=>value != id).toList(),
      completed:[...completed,id],
    );
  }
  ArcAmplificationState setPoints(int points) {
    if (points < 0 || points>999999999) throw RangeError.value(points,'points');
    return _change(researchPoints:points);
  }
  ArcAmplificationState study(String item,int count) {
    final yieldPerItem=ArcAmplificationCatalog.researchItemPoints[item];
    if (yieldPerItem == null || count < 1 || count > 99999) throw ArgumentError('Invalid study item or amount');
    return setPoints(researchPoints + yieldPerItem*count);
  }
  ArcAmplificationState setMaterial(String material,int count) {
    if (!ArcAmplificationCatalog.isKnownMaterial(material) || count<0 || count>999999) throw ArgumentError('Invalid material or count');
    return _change(materials:{...materials,material:count});
  }
  ArcAmplificationState planPerk(String weapon,String? id) {
    final map={...plannedPerks};
    if (id == null) {map.remove(weapon);} else {
      if (!ArcAmplificationCatalog.forWeapon(weapon).any((p)=>p.id==id)) throw ArgumentError('Incompatible weapon and perk');
      map[weapon] = id;
    }
    return _change(plannedPerks:map);
  }
  Map<String,int> missingNodeMaterials(String weapon,String id) {
    final cost=ArcAmplificationCatalog.nodeCost(weapon,id);
    if(cost==null) return const <String,int>{};
    return <String,int>{for(final item in cost.entries)
      if((materials[item.key]??0) < item.value) item.key:item.value-(materials[item.key]??0)};
  }
  ArcAmplificationState confirmApplied(String weapon,String id) {
    if(!completed.contains(id) || !ArcAmplificationCatalog.forWeapon(weapon).any((p)=>p.id==id)) throw StateError('Research not unlocked or incompatible weapon.');
    if(installedPerks[weapon]?.contains(id)??false) return this;
    final parent=ArcAmplificationCatalog.researchNodePrerequisites['$weapon|$id'];
    if(parent!=null && !(installedPerks[weapon]?.contains(parent)??false)) throw StateError('Required preceding weapon perk not marked installed.');
    final excluded=ArcAmplificationCatalog.researchNodeConflicts['$weapon|$id'] ?? const <String>[];
    if(excluded.any((other)=>installedPerks[weapon]?.contains(other)??false)) throw StateError('This weapon has an incompatible perk installed.');
    final cost=ArcAmplificationCatalog.nodeCost(weapon,id);
    if(cost==null || missingNodeMaterials(weapon,id).isNotEmpty) throw StateError('Missing node materials or unverified cost.');
    final nextMaterials={...materials};
    for(final item in cost.entries){nextMaterials[item.key]=(nextMaterials[item.key]??0)-item.value;}
    return _change(materials:nextMaterials,installedPerks:{...installedPerks,weapon:[...(installedPerks[weapon] ?? <String>[]),id]});
  }

}
