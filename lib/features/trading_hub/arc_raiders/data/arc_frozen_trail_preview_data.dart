import 'package:flutter/material.dart';

enum ArcFrozenTrailContentType {
  map,
  operation,
  enemy,
  weapon,
  gadget,
  progression,
  system,
  workstation,
  instrument,
}

class ArcFrozenTrailContentItem {
  const ArcFrozenTrailContentItem({
    required this.id,
    required this.name,
    required this.type,
    required this.summary,
    required this.icon,
    this.detail = '',
    this.imageAssetPath,
  });

  final String id;
  final String name;
  final ArcFrozenTrailContentType type;
  final String summary;
  final String detail;
  final IconData icon;
  final String? imageAssetPath;

  String get typeLabel => switch (type) {
    ArcFrozenTrailContentType.map => 'MAP',
    ArcFrozenTrailContentType.operation => 'ARC OPERATION',
    ArcFrozenTrailContentType.enemy => 'ARC',
    ArcFrozenTrailContentType.weapon => 'WEAPON',
    ArcFrozenTrailContentType.gadget => 'GADGET',
    ArcFrozenTrailContentType.progression => 'PROGRESSION',
    ArcFrozenTrailContentType.system => 'SYSTEM',
    ArcFrozenTrailContentType.workstation => 'RESEARCH',
    ArcFrozenTrailContentType.instrument => 'INSTRUMENT',
  };
}

/// Confirmed Frozen Trail preview information from Embark's
/// 23 September 2026 First Look. Unknown launch-day stats, recipes,
/// attachment layouts, Blueprint positions and map coordinates are not guessed.
class ArcFrozenTrailPreviewData {
  const ArcFrozenTrailPreviewData._();

  static const String updateName = 'Frozen Trail';
  static const String releaseDateIso = '2026-10-08';
  static const String sourceLabel =
      'Embark Frozen Trail First Look · 23 September 2026';

  static const String mapId = 'pendola_pass';
  static const String mapName = 'Pendola Pass';
  static const String mapImageSlot =
      'assets/arc_raiders/maps/pendola_pass/pendola_pass_master.webp';

  static const List<ArcFrozenTrailContentItem> items = [
    ArcFrozenTrailContentItem(
      id: 'pendola_pass',
      name: 'Pendola Pass',
      type: ArcFrozenTrailContentType.map,
      summary:
          'Frozen Italian village and Exodus transport hub beyond the Rust Belt mountains.',
      detail:
          'Embark has named a supermarket, town square, observatory and buried train depot. The map also features flash freezes and a fallen Emperor.',
      icon: Icons.ac_unit_rounded,
      imageAssetPath: mapImageSlot,
    ),
    ArcFrozenTrailContentItem(
      id: 'frigate',
      name: 'Frigate',
      type: ArcFrozenTrailContentType.operation,
      summary:
          'A huge boardable ARC vessel and high-skill ARC Operation above Pendola Pass.',
      detail:
          'Raiders navigate internal passages, unlock routes and fight ARC and other Raiders in close quarters.',
      icon: Icons.air_rounded,
    ),
    ArcFrozenTrailContentItem(
      id: 'bully',
      name: 'Bully',
      type: ArcFrozenTrailContentType.enemy,
      summary:
          'Fast, aggressive machine that gallops onto positions and refuses to give ground.',
      icon: Icons.warning_amber_rounded,
      imageAssetPath: 'assets/arc_raiders/items/bully.webp',
    ),
    ArcFrozenTrailContentItem(
      id: 'skulker',
      name: 'Skulker',
      type: ArcFrozenTrailContentType.enemy,
      summary:
          'Opportunistic ARC that lurks at the edge of vision, retreats and re-engages.',
      icon: Icons.visibility_off_rounded,
      imageAssetPath: 'assets/arc_raiders/items/skulker.webp',
    ),
    ArcFrozenTrailContentItem(
      id: 'hydra',
      name: 'Hydra',
      type: ArcFrozenTrailContentType.enemy,
      summary: 'Three-part autonomous turret encountered aboard the Frigate.',
      detail:
          'Its three stacked sections move independently and create a triple weapon threat.',
      icon: Icons.hub_rounded,
      imageAssetPath: 'assets/arc_raiders/items/hydra.webp',
    ),
    ArcFrozenTrailContentItem(
      id: 'stiletto',
      name: 'Stiletto',
      type: ArcFrozenTrailContentType.weapon,
      summary:
          'Light-ammo battle rifle positioned as an early-game Renegade alternative.',
      detail:
          'Embark says it is cheap to craft and rewards controlled ranged fire. Recipe, bench level and attachment layout remain launch-pending.',
      icon: Icons.gps_fixed_rounded,
      imageAssetPath: 'assets/arc_raiders/items/stiletto.webp',
    ),
    ArcFrozenTrailContentItem(
      id: 'bantam',
      name: 'Bantam',
      type: ArcFrozenTrailContentType.weapon,
      summary:
          'Snub-nosed heavy-ammo revolver with a unique hip-fire capability.',
      detail:
          'Exact recipe, source and attachment layout remain launch-pending.',
      icon: Icons.my_location_rounded,
      imageAssetPath: 'assets/arc_raiders/items/bantam.webp',
    ),
    ArcFrozenTrailContentItem(
      id: 'grappling_hook',
      name: 'Grappling Hook',
      type: ArcFrozenTrailContentType.gadget,
      summary:
          'Traversal gadget for climbing, abseiling and swinging across gaps.',
      icon: Icons.vertical_align_top_rounded,
      imageAssetPath: 'assets/arc_raiders/items/grappling-hook.webp',
    ),
    ArcFrozenTrailContentItem(
      id: 'tether_launcher',
      name: 'Tether Launcher',
      type: ArcFrozenTrailContentType.gadget,
      summary:
          'Connects two points with a tether to root targets or attach Raiders to ARC.',
      icon: Icons.cable_rounded,
      imageAssetPath: 'assets/arc_raiders/items/tether-launcher.webp',
    ),
    ArcFrozenTrailContentItem(
      id: 'yank_grenade',
      name: 'Yank Grenade',
      type: ArcFrozenTrailContentType.gadget,
      summary:
          'Pulls a nearby target with force, including flying ARC or Raiders in cover.',
      icon: Icons.adjust_rounded,
      imageAssetPath: 'assets/arc_raiders/items/yank-grenade.webp',
    ),
    ArcFrozenTrailContentItem(
      id: 'camera',
      name: 'Camera',
      type: ArcFrozenTrailContentType.gadget,
      summary:
          'Photography gadget with zoom, aperture, manual/auto focus and selfie functionality.',
      detail: 'Pictures save to the in-game Codex.',
      icon: Icons.photo_camera_rounded,
      imageAssetPath: 'assets/arc_raiders/items/camera.webp',
    ),
    ArcFrozenTrailContentItem(
      id: 'outpost',
      name: 'Outpost',
      type: ArcFrozenTrailContentType.system,
      summary:
          'A surface home-away-from-home that can be customised with modules and furniture.',
      detail:
          'Embark describes the Outpost as the first step in reclaiming parts of the surface.',
      icon: Icons.home_work_rounded,
    ),
    ArcFrozenTrailContentItem(
      id: 'research_workstation',
      name: 'Research Workstation',
      type: ArcFrozenTrailContentType.workstation,
      summary:
          'New Outpost research bench for investigating the world and unlocking higher levels of weapon customisation and modding.',
      detail:
          'A fully upgraded Research Workstation unlocks the fifth weapon quality level and branching Amplified Weapon enhancements. Exact upgrade costs and tier requirements have not yet been published.',
      icon: Icons.science_rounded,
      imageAssetPath:
          'assets/arc_raiders/operations/research_workstation_card.webp',
    ),
    ArcFrozenTrailContentItem(
      id: 'amplified_weapons',
      name: 'Amplified Weapons',
      type: ArcFrozenTrailContentType.progression,
      summary:
          'A fifth quality level with branching weapon enhancements for 15 weapons.',
      detail:
          'Embark examples include a fully automatic Burletta, scoped Renegade and incendiary Rattler with a 64-round magazine.',
      icon: Icons.upgrade_rounded,
    ),
    ArcFrozenTrailContentItem(
      id: 'reward_pass',
      name: 'Reward Pass',
      type: ArcFrozenTrailContentType.progression,
      summary: 'New progression system evolving the Raider Deck experience.',
      icon: Icons.card_membership_rounded,
    ),
    ArcFrozenTrailContentItem(
      id: 'harmonica',
      name: 'Harmonica',
      type: ArcFrozenTrailContentType.instrument,
      summary: 'New playable instrument arriving with Frozen Trail.',
      icon: Icons.music_note_rounded,
    ),
    ArcFrozenTrailContentItem(
      id: 'banjo',
      name: 'Banjo',
      type: ArcFrozenTrailContentType.instrument,
      summary: 'New playable instrument arriving with Frozen Trail.',
      icon: Icons.music_note_rounded,
    ),
  ];

  static List<ArcFrozenTrailContentItem> byType(
    ArcFrozenTrailContentType type,
  ) => items.where((item) => item.type == type).toList(growable: false);

  static ArcFrozenTrailContentItem get researchWorkstation =>
      items.firstWhere((item) => item.id == 'research_workstation');
}
