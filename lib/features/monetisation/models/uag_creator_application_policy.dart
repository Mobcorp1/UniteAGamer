class UagCreatorApplicationPolicy {
  const UagCreatorApplicationPolicy();

  static const int currentTermsVersion = 1;
  static const List<String> supportedPlatforms = <String>[
    'TikTok',
    'YouTube',
    'Twitch',
    'Instagram',
    'Facebook',
    'X',
    'Other',
  ];

  UagCreatorApplicationValidation validate({
    required String displayName,
    required Iterable<String> platforms,
    required Map<String, String> socialHandles,
    required bool termsAccepted,
  }) {
    final cleanName = displayName.trim();
    final cleanPlatforms = platforms
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
    final cleanHandles = socialHandles.entries
        .where(
          (entry) =>
              entry.key.trim().isNotEmpty && entry.value.trim().isNotEmpty,
        )
        .toList(growable: false);

    final errors = <String>[];
    if (cleanName.length < 2) {
      errors.add('Enter the creator name you want UAG to review.');
    }
    if (cleanPlatforms.isEmpty) {
      errors.add('Select at least one creator platform.');
    }
    if (cleanHandles.isEmpty) {
      errors.add('Add at least one social handle or channel.');
    }
    if (!termsAccepted) {
      errors.add('Accept the Creator Programme terms before applying.');
    }

    return UagCreatorApplicationValidation(
      valid: errors.isEmpty,
      errors: errors,
    );
  }

  String creatorIdFor({required String uid, required String displayName}) {
    final slug = displayName
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '')
        .padRight(3, 'U');
    final suffixSource = uid.trim().toUpperCase().replaceAll(
      RegExp(r'[^A-Z0-9]'),
      '',
    );
    final suffix = suffixSource.length <= 6
        ? suffixSource.padLeft(6, '0')
        : suffixSource.substring(suffixSource.length - 6);
    final head = slug.length <= 10 ? slug : slug.substring(0, 10);
    return 'UAG-$head-$suffix';
  }

  String defaultCodeFor(String displayName) {
    var slug = displayName.trim().toUpperCase().replaceAll(
      RegExp(r'[^A-Z0-9]'),
      '',
    );
    if (slug.length < 3) {
      slug = '${slug}CREATOR';
    }
    if (slug.length > 16) {
      slug = slug.substring(0, 16);
    }
    return 'UAG$slug';
  }
}

class UagCreatorApplicationValidation {
  const UagCreatorApplicationValidation({
    required this.valid,
    required this.errors,
  });

  final bool valid;
  final List<String> errors;
}
