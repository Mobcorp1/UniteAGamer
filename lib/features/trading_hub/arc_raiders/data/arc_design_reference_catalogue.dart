/// Verified ARC Raiders 2.0 furniture Design names, alphabetically sorted.
/// Source: https://www.arcscrappy.com/en/items (Design, 100 items).
/// IMPORTANT: this is NOT the in-game 17-column positional sequence.
/// A name must be explicitly assigned to a slot; never infer a name from
/// its alphabetical index, as doing so would mislabel ownership and trades.
class ArcDesignReferenceCatalogue {
  const ArcDesignReferenceCatalogue._();
  static const names = <String>[
    'Alpine Wardrobe',
    'Archive Floor Lamp',
    'Bar Table',
    'Barstool',
    'Battered Aviary Table',
    'Battered Bureau Chair',
    'Battered Bureau Sofa',
    'Battered Den Bed',
    'Battered Den Shelf',
    'Battered Diner Chair',
    'Battered Faculty Table',
    'Battered Lab Cabinet (Wide)',
    'Battered Lab Cabinet',
    'Battered Lab Chair',
    'Battered Shelf',
    'Battered Stash',
    'Battered Weapon Rack',
    'Blue Lab Cabinet',
    'Bureau Ceiling Lamp',
    'Cafeteria Table',
    'Chambers Lamp',
    'Chambers Nightstand',
    'Chambers Shelf',
    'Chandelier',
    'Clinic Medical Cabinet',
    'Console Chest',
    'Diner Ceiling Lamp',
    'Diner Cupboard',
    'Diner Shelf',
    'Diner Sofa',
    'Diner Stool',
    'Diner Table',
    'Draped Debris A',
    'Draped Debris B',
    'Draped Debris C',
    'Draped Debris E',
    'Draped Debris F',
    'Draped Debris G',
    'Faculty Closet',
    'Faculty Dresser',
    'Floor Lamp',
    'Geometric Fabric Chair',
    'Glass Ceiling Lamp',
    'Green Geometric Chair',
    'Green Geometric Sofa',
    'Green Lab Sofa',
    'Holly Bush',
    'Hotel Chair',
    'Lab Ceiling Light',
    'Lab Stool',
    'Multicolored Geometric Sofa',
    'Ornate Den Bed',
    'Ornate Den Shelf',
    'Ornate Stash',
    'Ornate Wardrobe',
    'Polished Den Bed',
    'Polished Den Shelf',
    'Polished Diner Chair',
    'Polished Faculty Chair',
    'Polished Faculty Table',
    'Polished Round Sofa',
    'Polished Stash',
    'Polished Study Sofa',
    'Polished Wardrobe',
    'Polished Weapon Rack',
    'Printed Fabric Chair',
    'Printed Lab Sofa',
    'Red Study Sofa',
    'Restaurant Table',
    'Security Chair',
    'Small Lab Cabinet',
    'Solid Green Chair',
    'Study Armchair (Uncommon)',
    'Study Armchair (Legendary)',
    'Study Ceiling Lamp',
    'Study Piano',
    'Study TV Stand',
    'Sturdy Aviary Table',
    'Sturdy Bureau Chair',
    'Sturdy Bureau Sofa',
    'Sturdy Den Bed',
    'Sturdy Den Shelf',
    'Sturdy Faculty Chair',
    'Sturdy Faculty Table',
    'Sturdy Lab Cabinet (Wide)',
    'Sturdy Lab Cabinet',
    'Sturdy Lab Chair',
    'Sturdy Shelf',
    'Sturdy Stash',
    'Sturdy Wardrobe',
    'Sturdy Weapon Rack',
    'Tufted Sofa',
    'Venetian Dresser',
    'Warehouse Chair',
    'Warehouse Desk',
    'Warehouse Dresser',
    'Weather Station Chair',
    'Weather Station Table',
    'Winter Table',
    'Work Light',
  ];

  /// MetaForge Design Tracker's 100 in-game positions (17 columns, final row partial).
  /// This is DISPLAY metadata only. Saved ownership and dupes continue to use
  /// their existing numeric slot IDs; manual user-verified names take precedence.
  /// The two Study Armchair variants cannot safely be assigned a rarity to a
  /// position without independent in-game verification.
  static const inGameOrder = <String>[
    'Printed Lab Sofa',
    'Sturdy Faculty Chair',
    'Diner Ceiling Lamp',
    'Multicolored Geometric Sofa',
    'Polished Wardrobe',
    'Diner Sofa',
    'Winter Table',
    'Battered Lab Cabinet (Wide)',
    'Draped Debris F',
    'Sturdy Stash',
    'Alpine Wardrobe',
    'Security Chair',
    'Draped Debris E',
    'Green Geometric Chair',
    'Battered Weapon Rack',
    'Faculty Closet',
    'Battered Stash',
    'Battered Shelf',
    'Faculty Dresser',
    'Chambers Nightstand',
    'Chambers Shelf',
    'Clinic Medical Cabinet',
    'Ornate Wardrobe',
    'Polished Faculty Table',
    'Ornate Stash',
    'Diner Stool',
    'Lab Stool',
    'Polished Study Sofa',
    'Polished Round Sofa',
    'Lab Ceiling Light',
    'Tufted Sofa',
    'Sturdy Lab Cabinet (Wide)',
    'Work Light',
    'Sturdy Lab Cabinet',
    'Sturdy Wardrobe',
    'Draped Debris B',
    'Study Armchair',
    'Bar Table',
    'Battered Bureau Sofa',
    'Sturdy Bureau Chair',
    'Hotel Chair',
    'Polished Den Bed',
    'Draped Debris A',
    'Chambers Lamp',
    'Sturdy Weapon Rack',
    'Glass Ceiling Lamp',
    'Polished Diner Chair',
    'Cafeteria Table',
    'Study TV Stand',
    'Diner Table',
    'Diner Shelf',
    'Weather Station Chair',
    'Battered Den Shelf',
    'Study Ceiling Lamp',
    'Console Chest',
    'Sturdy Bureau Sofa',
    'Geometric Fabric Chair',
    'Study Piano',
    'Sturdy Den Bed',
    'Weather Station Table',
    'Battered Faculty Table',
    'Ornate Den Shelf',
    'Battered Bureau Chair',
    'Battered Aviary Table',
    'Barstool',
    'Holly Bush',
    'Green Lab Sofa',
    'Battered Lab Chair',
    'Warehouse Dresser',
    'Red Study Sofa',
    'Polished Den Shelf',
    'Battered Lab Cabinet',
    'Solid Green Chair',
    'Venetian Dresser',
    'Battered Den Bed',
    'Sturdy Shelf',
    'Draped Debris G',
    'Polished Faculty Chair',
    'Diner Cupboard',
    'Chandelier',
    'Draped Debris C',
    'Bureau Ceiling Lamp',
    'Floor Lamp',
    'Battered Diner Chair',
    'Ornate Den Bed',
    'Polished Stash',
    'Study Armchair',
    'Restaurant Table',
    'Archive Floor Lamp',
    'Polished Weapon Rack',
    'Printed Fabric Chair',
    'Sturdy Aviary Table',
    'Warehouse Desk',
    'Green Geometric Sofa',
    'Small Lab Cabinet',
    'Sturdy Lab Chair',
    'Blue Lab Cabinet',
    'Warehouse Chair',
    'Sturdy Faculty Table',
    'Sturdy Den Shelf',
  ];

  static String? nameAt(int slot) =>
      slot >= 1 && slot <= inGameOrder.length ? inGameOrder[slot - 1] : null;

  /// Simple filename: no design_ prefix or grid number. e.g.
  /// Battered Lab Cabinet (Wide) -> battered_lab_cabinet_wide.webp.
  /// 'Study Armchair' is intentionally generic at slots 37 and 87;
  /// a manually verified rarity name gets a rarity-specific filename.
  static String artworkFilenameForName(String name) {
    final stem = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return '$stem.webp';
  }

  /// Artwork supplied for named furniture designs. This list is not a
  /// positional grid: the native Design collection uses independently verified
  /// 1-based slot assignments.
  static const Map<String, String> suppliedArtwork = <String, String>{
    'Diner Sofa': 'assets/arc_raiders/blueprints/diner_sofa.webp',
    'Draped Debris F': 'assets/arc_raiders/blueprints/draped_debris_f.webp',
    'Multicolored Geometric Sofa':
        'assets/arc_raiders/blueprints/multicolored_geometric_sofa.webp',
    'Polished Wardrobe':
        'assets/arc_raiders/blueprints/polished_wardrobe.webp',
    'Printed Lab Sofa':
        'assets/arc_raiders/blueprints/printed_lab_sofa.webp',
    'Winter Table': 'assets/arc_raiders/blueprints/winter_table.webp',
  };

  static String? artworkForName(String? name) =>
      name == null ? null : suppliedArtwork[name];

  /// Do not infer in-game position from an alphabetical Design name.
  /// Only explicitly verified user slot assignments may display artwork.
  static String? artworkForVerifiedSlot(
    int slot,
    Map<int, String> verifiedAssignments,
  ) => artworkForName(inGameNameForSlot(slot, verifiedAssignments));

  // These two slot labels are already present in the existing collection UI.
  // No extra positions are inferred from the alphabetical reference list.
  static const Map<int, String> knownDisplaySlots = <int, String>{
    1: 'Printed Lab Sofa',
    4: 'Multicolored Geometric Sofa',
  };

  static String? displayNameForSlot(
    int slot,
    Map<int, String> userAssignments,
  ) => slot < 1 || slot > 100
      ? null
      : (userAssignments[slot] ?? knownDisplaySlots[slot]);

  static String? artworkForDisplaySlot(
    int slot,
    Map<int, String> userAssignments,
  ) => artworkForName(displayNameForSlot(slot, userAssignments));

  static String? inGameNameForSlot(
    int slot,
    Map<int, String> verifiedAssignments,
  ) => slot >= 1 && slot <= 100 ? verifiedAssignments[slot] : null;
}
