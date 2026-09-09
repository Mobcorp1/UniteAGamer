class UagCommunityReferralLink {
  const UagCommunityReferralLink({
    required this.referrerUid,
    required this.code,
  });

  final String referrerUid;
  final String code;

  String get normalizedCode =>
      code.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9-]'), '');

  bool get isValid =>
      referrerUid.trim().isNotEmpty && normalizedCode.isNotEmpty;

  static UagCommunityReferralLink? tryParse(Uri uri) {
    final referrer = (uri.queryParameters['referrer'] ?? '').trim();
    final code = (uri.queryParameters['refcode'] ?? '').trim();
    if (referrer.isEmpty || code.isEmpty) return null;
    final result = UagCommunityReferralLink(referrerUid: referrer, code: code);
    return result.isValid ? result : null;
  }
}
