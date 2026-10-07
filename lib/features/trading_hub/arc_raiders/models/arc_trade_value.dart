import 'package:flutter/foundation.dart';

enum ArcUagValueTier { sPlus, s, a, b, c }

extension ArcUagValueTierX on ArcUagValueTier {
  String get label => switch (this) {
    ArcUagValueTier.sPlus => 'S+',
    ArcUagValueTier.s => 'S',
    ArcUagValueTier.a => 'A',
    ArcUagValueTier.b => 'B',
    ArcUagValueTier.c => 'C',
  };

  int get points => switch (this) {
    ArcUagValueTier.sPlus => 16,
    ArcUagValueTier.s => 8,
    ArcUagValueTier.a => 4,
    ArcUagValueTier.b => 2,
    ArcUagValueTier.c => 1,
  };

  int get sortWeight => switch (this) {
    ArcUagValueTier.sPlus => 5,
    ArcUagValueTier.s => 4,
    ArcUagValueTier.a => 3,
    ArcUagValueTier.b => 2,
    ArcUagValueTier.c => 1,
  };

  String get marketLabel => switch (this) {
    ArcUagValueTier.sPlus => 'Elite value',
    ArcUagValueTier.s => 'High value',
    ArcUagValueTier.a => 'Strong value',
    ArcUagValueTier.b => 'Standard value',
    ArcUagValueTier.c => 'Lower value',
  };
}

@immutable
class ArcBlueprintValueProfile {
  const ArcBlueprintValueProfile({
    required this.blueprintId,
    required this.tradeTier,
    required this.reason,
    this.gameplayTier,
  });

  final String blueprintId;
  final ArcUagValueTier tradeTier;
  final ArcUagValueTier? gameplayTier;
  final String reason;

  int get tradePoints => tradeTier.points;
  String get tradeLabel => tradeTier.label;
  String? get gameplayLabel => gameplayTier?.label;
}
