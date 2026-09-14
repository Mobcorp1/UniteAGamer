import 'package:cloud_firestore/cloud_firestore.dart';

/// Read only projection of server-owned raider_verified_results documents.
/// Never construct rankings from user counters or legacy completed contracts.
class ArcHunterVerifiedResult {
  const ArcHunterVerifiedResult({
    required this.contractId,
    required this.hunterUid,
    required this.countryCode,
    required this.verifiedAt,
  });

  final String contractId;
  final String hunterUid;
  final String countryCode;
  final DateTime verifiedAt;

  static ArcHunterVerifiedResult? fromServerRecord(
    String documentId,
    Map<String, dynamic> data,
  ) {
    final issuer = data['issuerUid'];
    final hunter = data['hunterUid'];
    final timestamp = data['verifiedAt'];
    if (documentId.isEmpty ||
        data['contractId'] != documentId ||
        data['verificationStatus'] != 'verified' ||
        issuer is! String ||
        issuer.isEmpty ||
        hunter is! String ||
        hunter.isEmpty ||
        hunter == issuer ||
        data['verifiedByUid'] != issuer ||
        data['evidenceSubmissionId'] is! String ||
        (data['evidenceSubmissionId'] as String).isEmpty ||
        timestamp is! Timestamp)
      return null;
    final country = '${data['countryCode'] ?? ''}'.toUpperCase();
    return ArcHunterVerifiedResult(
      contractId: documentId,
      hunterUid: hunter,
      countryCode: RegExp(r'^[A-Z]{2}$').hasMatch(country) ? country : '',
      verifiedAt: timestamp.toDate().toUtc(),
    );
  }

  /// One point per contract, optionally restricted to a country and UTC month.
  static Map<String, int> totals(
    Iterable<ArcHunterVerifiedResult> results, {
    String? countryCode,
    DateTime? month,
  }) {
    final counts = <String, int>{};
    final seen = <String>{};
    for (final result in results) {
      if (countryCode != null &&
          (result.countryCode.isEmpty ||
              result.countryCode != countryCode.toUpperCase()))
        continue;
      if (month != null &&
          (result.verifiedAt.year != month.toUtc().year ||
              result.verifiedAt.month != month.toUtc().month))
        continue;
      if (!seen.add(result.contractId)) continue;
      counts.update(result.hunterUid, (value) => value + 1, ifAbsent: () => 1);
    }
    return Map.unmodifiable(counts);
  }
}
