/// Canonical artwork for workstation progression surfaces.
/// This is presentation-only; changing artwork never changes bench progress.
class ArcBenchArtwork {
  const ArcBenchArtwork._();

  static const String root = 'assets/arc_raiders/hub/benches/';

  static const Map<String, String> stationArtwork = <String, String>{
    'Gunsmith': '${root}gunsmith.webp',
    'Explosives Station': '${root}explosives_station.webp',
    'Gear Bench': '${root}gear_bench.webp',
    'Medical Lab': '${root}medical_lab.webp',
    'Utility Station': '${root}utility_station.webp',
    'Refiner': '${root}refiner.webp',
    'Research Station': '${root}research_station.webp',
    'Scrappy': '${root}scrappy_bench.webp',
    'Workbench': '${root}workbench.webp',
  };

  static String? forStation(String station) => stationArtwork[station.trim()];
}
