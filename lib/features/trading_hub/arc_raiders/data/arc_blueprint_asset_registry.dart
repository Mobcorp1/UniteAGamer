class ArcBlueprintAssetRegistry {
  const ArcBlueprintAssetRegistry._();

  static const String _basePath = 'assets/arc_raiders/blueprints';

  static const Map<String, String> _aliases = {
    'anvil splitter': 'anvil_splitter',
    'kinetic converter': 'kinetic_converter',
    'padded stock': 'padded-stock',
    'harpin': 'harpin',
    'hairpin': 'harpin',
    'triggernade': 'trigger-nade',
    'trigger nade': 'trigger-nade',
    'combat augment': 'combat-mk-3-aggressive',
    'mobility augment': 'combat-mk-3-flanking',
    'utility augment': 'tactical-mk-3-defensive',
    'survivor': 'looting-mk-3-survivor',
    'safekeeper': 'looting-mk-3-safekeeper',
    'shield level 2': 'barricade-kit',
    'empty slot': '',
  };

  static String? assetFor(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) return null;
    final normalised = raw.toLowerCase();
    final alias = _aliases[normalised];
    if (alias != null) {
      if (alias.isEmpty) return null;
      return '$_basePath/$alias.webp';
    }

    final slug = normalised
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');

    if (slug.isEmpty) return null;
    return '$_basePath/$slug.webp';
  }

  static String? assetForWithBlueprintFallback({
    required String itemName,
    String? blueprintAssetPath,
  }) {
    if (blueprintAssetPath != null && blueprintAssetPath.trim().isNotEmpty) {
      return blueprintAssetPath;
    }
    return assetFor(itemName);
  }
}
