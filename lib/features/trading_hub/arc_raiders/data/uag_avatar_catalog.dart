class UagAvatarOption {
  const UagAvatarOption({required this.id, required this.label});

  final String id;
  final String label;

  String get assetPath => 'assets/uag/avatars/uag_avatar_$id.webp';
}

abstract final class UagAvatarCatalog {
  static const defaultId = 'shadow';

  static const options = <UagAvatarOption>[
    UagAvatarOption(id: 'shadow', label: 'Shadow'),
    UagAvatarOption(id: 'pathfinder', label: 'Pathfinder'),
    UagAvatarOption(id: 'scrappy', label: 'Scrappy'),
    UagAvatarOption(id: 'vanguard', label: 'Vanguard'),
    UagAvatarOption(id: 'phantom', label: 'Phantom'),
    UagAvatarOption(id: 'striker', label: 'Striker'),
    UagAvatarOption(id: 'trader', label: 'Trader'),
    UagAvatarOption(id: 'intel', label: 'Intel'),
    UagAvatarOption(id: 'survivor', label: 'Survivor'),
    UagAvatarOption(id: 'outlaw', label: 'Outlaw'),
    UagAvatarOption(id: 'technician', label: 'Technician'),
    UagAvatarOption(id: 'medic', label: 'Medic'),
    UagAvatarOption(id: 'recon', label: 'Recon'),
    UagAvatarOption(id: 'elite', label: 'Elite'),
    UagAvatarOption(id: 'community', label: 'Community'),
    UagAvatarOption(id: 'creator', label: 'Creator'),
    UagAvatarOption(id: 'sentinel', label: 'Sentinel'),
    UagAvatarOption(id: 'wraith', label: 'Wraith'),
    UagAvatarOption(id: 'nomad', label: 'Nomad'),
    UagAvatarOption(id: 'enforcer', label: 'Enforcer'),
    UagAvatarOption(id: 'spectre', label: 'Spectre'),
    UagAvatarOption(id: 'frost', label: 'Frost'),
    UagAvatarOption(id: 'firestorm', label: 'Firestorm'),
    UagAvatarOption(id: 'ranger', label: 'Ranger'),
  ];

  static UagAvatarOption byId(String? id) {
    final wanted = (id ?? '').trim().toLowerCase();
    for (final option in options) {
      if (option.id == wanted) return option;
    }
    return options.first;
  }

  static bool contains(String? id) => options.any((item) => item.id == id);
}
