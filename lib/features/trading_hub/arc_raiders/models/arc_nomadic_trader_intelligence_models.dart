import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_command_centre_models.dart';

class ArcNomadicTraderResourceDefinition {
  const ArcNomadicTraderResourceDefinition({
    required this.id,
    required this.name,
    required this.value,
    required this.highTier,
    required this.icon,
  });

  final String id;
  final String name;
  final int value;
  final bool highTier;
  final IconData icon;
}

class ArcNomadicTraderGoalDefinition {
  const ArcNomadicTraderGoalDefinition({
    required this.name,
    required this.target,
    required this.icon,
  });

  final String name;
  final int target;
  final IconData icon;
}

class ArcNomadicTraderCatalog {
  const ArcNomadicTraderCatalog._();

  static const defaultGoals = <ArcNomadicTraderGoalDefinition>[
    ArcNomadicTraderGoalDefinition(
      name: 'Stash Expansion',
      target: 200000,
      icon: Icons.inventory_2_outlined,
    ),
    ArcNomadicTraderGoalDefinition(
      name: 'Expedition Vault',
      target: 200000,
      icon: Icons.door_back_door_outlined,
    ),
    ArcNomadicTraderGoalDefinition(
      name: 'Backpack Charm',
      target: 100000,
      icon: Icons.star_border_rounded,
    ),
    ArcNomadicTraderGoalDefinition(
      name: 'Raider Tokens',
      target: 150000,
      icon: Icons.toll_outlined,
    ),
    ArcNomadicTraderGoalDefinition(
      name: 'Cosmetic',
      target: 100000,
      icon: Icons.checkroom_outlined,
    ),
    ArcNomadicTraderGoalDefinition(
      name: 'Emote',
      target: 100000,
      icon: Icons.emoji_emotions_outlined,
    ),
    ArcNomadicTraderGoalDefinition(
      name: 'Quick Use',
      target: 100000,
      icon: Icons.bolt_outlined,
    ),
    ArcNomadicTraderGoalDefinition(
      name: 'Recyclable',
      target: 100000,
      icon: Icons.recycling_rounded,
    ),
    ArcNomadicTraderGoalDefinition(
      name: 'Blueprint',
      target: 100000,
      icon: Icons.article_outlined,
    ),
    ArcNomadicTraderGoalDefinition(
      name: 'Weapon',
      target: 100000,
      icon: Icons.gps_fixed_rounded,
    ),
  ];

  static const highTierResources = <ArcNomadicTraderResourceDefinition>[
    ArcNomadicTraderResourceDefinition(
      id: 'queen_reactor',
      name: 'Queen Reactor',
      value: 11000,
      highTier: true,
      icon: Icons.battery_charging_full_rounded,
    ),
    ArcNomadicTraderResourceDefinition(
      id: 'matriarch_reactor',
      name: 'Matriarch Reactor',
      value: 11000,
      highTier: true,
      icon: Icons.battery_charging_full_rounded,
    ),
    ArcNomadicTraderResourceDefinition(
      id: 'vaporizer_regulator',
      name: 'Vaporizer Regulator',
      value: 6000,
      highTier: true,
      icon: Icons.settings_input_component_rounded,
    ),
    ArcNomadicTraderResourceDefinition(
      id: 'turbine_compressor',
      name: 'Turbine Compressor',
      value: 5000,
      highTier: true,
      icon: Icons.settings_applications_rounded,
    ),
    ArcNomadicTraderResourceDefinition(
      id: 'assessor_matrix',
      name: 'Assessor Matrix',
      value: 5000,
      highTier: true,
      icon: Icons.grid_view_rounded,
    ),
    ArcNomadicTraderResourceDefinition(
      id: 'rocketeer_driver',
      name: 'Rocketeer Driver',
      value: 3000,
      highTier: true,
      icon: Icons.rocket_launch_outlined,
    ),
    ArcNomadicTraderResourceDefinition(
      id: 'bastion_cell',
      name: 'Bastion Cell',
      value: 3000,
      highTier: true,
      icon: Icons.inventory_2_rounded,
    ),
    ArcNomadicTraderResourceDefinition(
      id: 'bombardier_cell',
      name: 'Bombardier Cell',
      value: 3000,
      highTier: true,
      icon: Icons.blur_circular_rounded,
    ),
    ArcNomadicTraderResourceDefinition(
      id: 'leaper_pulse_unit',
      name: 'Leaper Pulse Unit',
      value: 3000,
      highTier: true,
      icon: Icons.sensors_rounded,
    ),
    ArcNomadicTraderResourceDefinition(
      id: 'duplicate_blueprint',
      name: 'Duplicate Blueprint',
      value: 5000,
      highTier: true,
      icon: Icons.article_outlined,
    ),
  ];

  static const lowTierResources = <ArcNomadicTraderResourceDefinition>[
    ArcNomadicTraderResourceDefinition(
      id: 'shredder_gyro',
      name: 'Shredder Gyro',
      value: 2000,
      highTier: false,
      icon: Icons.track_changes_rounded,
    ),
    ArcNomadicTraderResourceDefinition(
      id: 'sentinel_firing_core',
      name: 'Sentinel Firing Core',
      value: 2000,
      highTier: false,
      icon: Icons.adjust_rounded,
    ),
    ArcNomadicTraderResourceDefinition(
      id: 'surveyor_vault',
      name: 'Surveyor Vault',
      value: 1000,
      highTier: false,
      icon: Icons.inventory_2_outlined,
    ),
    ArcNomadicTraderResourceDefinition(
      id: 'snitch_scanner',
      name: 'Snitch Scanner',
      value: 1000,
      highTier: false,
      icon: Icons.radar_rounded,
    ),
    ArcNomadicTraderResourceDefinition(
      id: 'hornet_driver',
      name: 'Hornet Driver',
      value: 1000,
      highTier: false,
      icon: Icons.bug_report_outlined,
    ),
    ArcNomadicTraderResourceDefinition(
      id: 'firefly_burner',
      name: 'Firefly Burner',
      value: 1000,
      highTier: false,
      icon: Icons.local_fire_department_outlined,
    ),
    ArcNomadicTraderResourceDefinition(
      id: 'damaged_leaper_pulse_unit',
      name: 'Damaged Leaper Pulse Unit',
      value: 1000,
      highTier: false,
      icon: Icons.sensors_off_rounded,
    ),
    ArcNomadicTraderResourceDefinition(
      id: 'damaged_rocketeer_driver',
      name: 'Damaged Rocketeer Driver',
      value: 1000,
      highTier: false,
      icon: Icons.rocket_launch_outlined,
    ),
    ArcNomadicTraderResourceDefinition(
      id: 'fireball_burner',
      name: 'Fireball Burner',
      value: 640,
      highTier: false,
      icon: Icons.local_fire_department_rounded,
    ),
    ArcNomadicTraderResourceDefinition(
      id: 'damaged_hornet_driver',
      name: 'Damaged Hornet Driver',
      value: 640,
      highTier: false,
      icon: Icons.bug_report_rounded,
    ),
    ArcNomadicTraderResourceDefinition(
      id: 'tick_pod',
      name: 'Tick Pod',
      value: 640,
      highTier: false,
      icon: Icons.trip_origin_rounded,
    ),
    ArcNomadicTraderResourceDefinition(
      id: 'duplicate_blueprint',
      name: 'Duplicate Blueprint',
      value: 5000,
      highTier: false,
      icon: Icons.article_outlined,
    ),
  ];

  static const purchaseSuggestions = <String>[
    'Industrial Magnet',
    'Number Plate',
    'Air Freshener',
    'ARC Thermal Lining',
    'Train Model',
    'Vintage Steering Wheel',
    'Spectrum Analyser',
    'Silver Tunic',
    'Teaspoon Set',
    'Vinyl Wristwatch',
    'Sextant',
    'Equatorial Sundial',
    'Metal Bracket',
    'ARC Performance Steel',
    'Teleron',
    'Elephant Obelisk',
    'Light Bulb',
    'ARC Coolant',
    'Colourful Shoes',
    'ARC Synthetic Resin',
    'Queen Reactor',
    'Matriarch Reactor',
    'Vaporizer Regulator',
    'Electrocore',
  ];
}

class ArcNomadicTraderResourceSnapshot {
  const ArcNomadicTraderResourceSnapshot({
    required this.id,
    required this.name,
    required this.value,
    required this.highTier,
    required this.quantity,
  });

  final String id;
  final String name;
  final int value;
  final bool highTier;
  final int quantity;

  int get totalValue => value * quantity;
  bool get tracked => quantity > 0;
}

class ArcNomadicTraderPurchaseRequirementSnapshot {
  const ArcNomadicTraderPurchaseRequirementSnapshot({
    required this.id,
    required this.name,
    required this.requiredQty,
    required this.ownedQty,
    required this.isCustom,
  });

  final String id;
  final String name;
  final int requiredQty;
  final int ownedQty;
  final bool isCustom;

  int get remainingQty => math.max(0, requiredQty - ownedQty);
  bool get complete => remainingQty == 0;
  double get progress =>
      requiredQty <= 0 ? 0 : (ownedQty / requiredQty).clamp(0, 1);

  ArcNomadicTraderPurchaseRequirementSnapshot copyWith({
    String? id,
    String? name,
    int? requiredQty,
    int? ownedQty,
    bool? isCustom,
  }) {
    return ArcNomadicTraderPurchaseRequirementSnapshot(
      id: id ?? this.id,
      name: name ?? this.name,
      requiredQty: requiredQty ?? this.requiredQty,
      ownedQty: ownedQty ?? this.ownedQty,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'requiredQty': requiredQty,
      'ownedQty': ownedQty,
      'isCustom': isCustom,
    };
  }

  factory ArcNomadicTraderPurchaseRequirementSnapshot.fromJson(
    Map<String, dynamic> json,
  ) {
    return ArcNomadicTraderPurchaseRequirementSnapshot(
      id:
          (json['id'] as String?) ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: (json['name'] as String?) ?? 'Custom Resource',
      requiredQty: (json['requiredQty'] as num?)?.toInt() ?? 1,
      ownedQty: (json['ownedQty'] as num?)?.toInt() ?? 0,
      isCustom: (json['isCustom'] as bool?) ?? true,
    );
  }
}

class ArcNomadicTraderPurchaseSnapshot {
  const ArcNomadicTraderPurchaseSnapshot({
    required this.id,
    required this.name,
    required this.requiredQty,
    required this.ownedQty,
    required this.isGalleryProject,
    required this.isCustom,
    this.requirements = const [],
  });

  final String id;
  final String name;
  final int requiredQty;
  final int ownedQty;
  final bool isGalleryProject;
  final bool isCustom;
  final List<ArcNomadicTraderPurchaseRequirementSnapshot> requirements;

  int get remainingQty => math.max(0, requiredQty - ownedQty);
  bool get alreadyPurchased => remainingQty == 0;
  double get progress =>
      requiredQty <= 0 ? 0 : (ownedQty / requiredQty).clamp(0, 1);
  int get missingRequirementCount => requirements.fold<int>(
    0,
    (total, requirement) => total + requirement.remainingQty,
  );

  ArcNomadicTraderPurchaseSnapshot copyWith({
    String? id,
    String? name,
    int? requiredQty,
    int? ownedQty,
    bool? isGalleryProject,
    bool? isCustom,
    List<ArcNomadicTraderPurchaseRequirementSnapshot>? requirements,
  }) {
    return ArcNomadicTraderPurchaseSnapshot(
      id: id ?? this.id,
      name: name ?? this.name,
      requiredQty: requiredQty ?? this.requiredQty,
      ownedQty: ownedQty ?? this.ownedQty,
      isGalleryProject: isGalleryProject ?? this.isGalleryProject,
      isCustom: isCustom ?? this.isCustom,
      requirements: requirements ?? this.requirements,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'requiredQty': requiredQty,
      'ownedQty': ownedQty,
      'isGalleryProject': isGalleryProject,
      'isCustom': isCustom,
      'requirements': requirements
          .map((requirement) => requirement.toJson())
          .toList(),
    };
  }

  factory ArcNomadicTraderPurchaseSnapshot.fromJson(Map<String, dynamic> json) {
    final decodedRequirements = json['requirements'];
    return ArcNomadicTraderPurchaseSnapshot(
      id:
          (json['id'] as String?) ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: (json['name'] as String?) ?? 'Custom Resource',
      requiredQty: (json['requiredQty'] as num?)?.toInt() ?? 1,
      ownedQty: (json['ownedQty'] as num?)?.toInt() ?? 0,
      isGalleryProject: (json['isGalleryProject'] as bool?) ?? false,
      isCustom: (json['isCustom'] as bool?) ?? true,
      requirements: decodedRequirements is List
          ? decodedRequirements
                .whereType<Map>()
                .map(
                  (item) =>
                      ArcNomadicTraderPurchaseRequirementSnapshot.fromJson(
                        Map<String, dynamic>.from(item),
                      ),
                )
                .toList()
          : const [],
    );
  }
}

class ArcNomadicTraderTrackerSnapshot {
  const ArcNomadicTraderTrackerSnapshot({
    required this.savedStateKnown,
    required this.goalName,
    required this.highTier,
    required this.targetValue,
    required this.resources,
    required this.purchases,
  });

  final bool savedStateKnown;
  final String goalName;
  final bool highTier;
  final int targetValue;
  final List<ArcNomadicTraderResourceSnapshot> resources;
  final List<ArcNomadicTraderPurchaseSnapshot> purchases;

  static const empty = ArcNomadicTraderTrackerSnapshot(
    savedStateKnown: false,
    goalName: 'Nomadic Trader',
    highTier: true,
    targetValue: 0,
    resources: <ArcNomadicTraderResourceSnapshot>[],
    purchases: <ArcNomadicTraderPurchaseSnapshot>[],
  );

  int get currentValue =>
      resources.fold<int>(0, (total, resource) => total + resource.totalValue);
  int get remainingValue => math.max(0, targetValue - currentValue);
  int get completionPercent => targetValue <= 0
      ? 0
      : ((currentValue / targetValue) * 100).round().clamp(0, 100);
  bool get goalAffordable => targetValue > 0 && remainingValue == 0;
  bool get hasResourceProgress => resources.any((resource) => resource.tracked);
  bool get hasPurchaseTracking => purchases.isNotEmpty;
  bool get trackingKnown =>
      savedStateKnown || hasResourceProgress || hasPurchaseTracking;
  int get completedPurchaseCount =>
      purchases.where((purchase) => purchase.alreadyPurchased).length;
}

class ArcNomadicTraderPurchaseIntelligence {
  const ArcNomadicTraderPurchaseIntelligence({
    required this.purchase,
    required this.priorityScore,
    required this.priorityLabel,
    required this.reason,
    required this.recommendedAction,
    required this.progressImpact,
    required this.canAfford,
    required this.nearlyAffords,
    required this.impossibleToBuy,
    required this.neededForQuest,
    required this.neededForBench,
    required this.neededForLoadout,
    required this.neededForBlueprintProgression,
    required this.missingResources,
    required this.status,
  });

  final ArcNomadicTraderPurchaseSnapshot purchase;
  final int priorityScore;
  final String priorityLabel;
  final String reason;
  final String recommendedAction;
  final String progressImpact;
  final bool canAfford;
  final bool nearlyAffords;
  final bool impossibleToBuy;
  final bool neededForQuest;
  final bool neededForBench;
  final bool neededForLoadout;
  final bool neededForBlueprintProgression;
  final List<String> missingResources;
  final ArcCommandStatus status;

  bool get alreadyPurchased => purchase.alreadyPurchased;
  bool get hasProgressImpact =>
      neededForQuest ||
      neededForBench ||
      neededForLoadout ||
      neededForBlueprintProgression ||
      purchase.isGalleryProject;
  String get missingShortText => missingResources.isEmpty
      ? 'No missing resources'
      : missingResources.join(', ');
}

class ArcNomadicTraderIntelligence {
  const ArcNomadicTraderIntelligence({
    required this.trackingKnown,
    required this.goalName,
    required this.statusLabel,
    required this.summary,
    required this.recommendation,
    required this.actionLabel,
    required this.status,
    required this.completionPercent,
    required this.targetValue,
    required this.currentValue,
    required this.remainingValue,
    required this.trackedPurchaseCount,
    required this.completedPurchaseCount,
    required this.affordablePurchaseCount,
    required this.nearlyAffordablePurchaseCount,
    required this.tradeNeedLabels,
    required this.topPurchases,
    this.bestPurchase,
    this.resetLabel,
  });

  final bool trackingKnown;
  final String goalName;
  final String statusLabel;
  final String summary;
  final String recommendation;
  final String actionLabel;
  final ArcCommandStatus status;
  final int completionPercent;
  final int targetValue;
  final int currentValue;
  final int remainingValue;
  final int trackedPurchaseCount;
  final int completedPurchaseCount;
  final int affordablePurchaseCount;
  final int nearlyAffordablePurchaseCount;
  final List<String> tradeNeedLabels;
  final List<ArcNomadicTraderPurchaseIntelligence> topPurchases;
  final ArcNomadicTraderPurchaseIntelligence? bestPurchase;
  final String? resetLabel;

  bool get hasPurchaseTracking => trackedPurchaseCount > 0;
  bool get goalAffordable => targetValue > 0 && remainingValue == 0;
  bool get hasActionablePurchase =>
      bestPurchase != null && !bestPurchase!.alreadyPurchased;
  bool get canAffordBestPurchase =>
      bestPurchase != null && bestPurchase!.canAfford;
  bool get hasImportantGap =>
      bestPurchase != null &&
      !bestPurchase!.canAfford &&
      bestPurchase!.hasProgressImpact;
  bool get hasTradeableNeed => tradeNeedLabels.isNotEmpty;
  bool get shouldVisit =>
      canAffordBestPurchase || hasImportantGap || goalAffordable;

  String get progressLabel => trackingKnown
      ? '$completionPercent% toward $goalName'
      : 'Set up trader tracker';
  String get missingShortText {
    if (!trackingKnown) return 'Trader state not tracked';
    if (bestPurchase != null && bestPurchase!.missingResources.isNotEmpty) {
      return bestPurchase!.missingShortText;
    }
    if (remainingValue > 0) return '$remainingValue Ermal value';
    return 'No missing trader resources';
  }
}
