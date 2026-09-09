class UagCreatorReferralLink {
  const UagCreatorReferralLink({required this.creatorUid, required this.code});

  final String creatorUid;
  final String code;

  bool get isValid => creatorUid.trim().isNotEmpty && code.trim().isNotEmpty;

  String get normalizedCode =>
      code.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9-]'), '');

  Uri toUri({String base = 'https://unite-a-gamer.web.app/'}) {
    final root = Uri.parse(base);
    return root.replace(
      queryParameters: <String, String>{
        ...root.queryParameters,
        'creator': creatorUid.trim(),
        'code': normalizedCode,
      },
    );
  }

  static UagCreatorReferralLink? tryParse(Uri uri) {
    final creator = (uri.queryParameters['creator'] ?? '').trim();
    final code = (uri.queryParameters['code'] ?? '').trim();
    if (creator.isEmpty || code.isEmpty) {
      return null;
    }
    final link = UagCreatorReferralLink(creatorUid: creator, code: code);
    return link.isValid ? link : null;
  }
}
