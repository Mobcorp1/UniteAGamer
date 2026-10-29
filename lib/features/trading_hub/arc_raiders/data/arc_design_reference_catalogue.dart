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

  static String? inGameNameForSlot(int slot, Map<int,String> verifiedAssignments) =>
    slot >= 1 && slot <= 100 ? verifiedAssignments[slot] : null;
}
