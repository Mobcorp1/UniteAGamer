class UagVoicePronunciation {
  const UagVoicePronunciation._();

  static const Map<String, List<String>> itemAliases = <String, List<String>>{
    'dolabra': <String>['dalabra', 'doll abra', 'dol abra', 'doh labra', 'do labra', 'doll labra'],
    'aphelion': <String>['a feelion', 'ap helium', 'a phelium', 'aph elion'],
    'arpeggio': <String>['ar pedgio', 'ar peg io', 'arpegeo', 'ar peggio'],
    'venator': <String>['ven ata', 'venetor', 'venater', 'ven ator'],
    'burletta': <String>['berletta', 'bur leta', 'bur letter'],
    'il toro': <String>['ill toro', 'el toro', 'il t oro'],
    'bettina': <String>['betina', 'bett ina'],
    'canto': <String>['canto blueprint', 'kanto', 'can toe'],
    'torrente': <String>['torrent', 'torrenti', 'tor ente'],
    'vulcano': <String>['volcano', 'vul cano'],
    'anvil': <String>['and ville', 'an ville'],
    'hullcracker': <String>['hull cracker', 'whole cracker'],
    'snap hook': <String>['snaphook', 'snap hock'],
    'surge coil': <String>['search coil', 'serge coil'],
    'vita shot': <String>['vital shot', 'veeta shot'],
    'vita spray': <String>['vital spray', 'veeta spray'],
    'matriarch reactor': <String>['matriac reactor', 'matrix reactor'],
    'assessor matrix': <String>['assessor metrics', 'assessor metre x'],
  };

  static const Map<String, String> spokenReplacements = <String, String>{
    'Dolabra': 'Doh-LAH-brah',
    'Aphelion': 'Ah-FEEL-ee-on',
    'Arpeggio': 'Ar-PEJ-ee-oh',
    'Venator': 'Venn-ay-tor',
    'Burletta': 'Bur-LET-ah',
    'Il Toro': 'Ill TOH-roh',
    'Bettina': 'Beh-TEE-nah',
    'Canto': 'CAN-toh',
    'Torrente': 'Toh-REN-tay',
    'Vulcano': 'Vul-KAH-noh',
    'Vita Shot': 'Vee-tah Shot',
    'Vita Spray': 'Vee-tah Spray',
  };

  static String normaliseForLookup(String text) {
    var output = text.toLowerCase().trim();
    for (final entry in itemAliases.entries) {
      for (final alias in entry.value) {
        output = output.replaceAll(alias.toLowerCase(), entry.key);
      }
    }
    return output;
  }

  static String improveSpeech(String text) {
    var output = text;
    for (final entry in spokenReplacements.entries) {
      output = output.replaceAll(entry.key, entry.value);
    }
    return output;
  }
}
