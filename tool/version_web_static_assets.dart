import 'dart:io';
import 'package:crypto/crypto.dart';

/// Fingerprint public website JS/CSS in-place in the BUILD directory only.
/// Aliases remain available for older pages and relative asset references.
Future<void> versionWebStaticAssets(Directory buildWeb) async {
  final assets = Directory('${buildWeb.path}/public-assets');
  if (!await assets.exists()) return;
  final replacements = <String, String>{};
  await for (final entity in assets.list()) {
    if (entity is! File) continue;
    final name = entity.uri.pathSegments.last;
    if (!RegExp(r'^[a-zA-Z0-9_-]+\.(js|css)$').hasMatch(name)) continue;
    final bytes = await entity.readAsBytes();
    final split = name.lastIndexOf('.');
    final digest = sha256.convert(bytes).toString();
    final versioned =
        '${name.substring(0, split)}.$digest${name.substring(split)}';
    await File('${assets.path}/$versioned').writeAsBytes(bytes);
    replacements['public-assets/$name'] = 'public-assets/$versioned';
  }
  await for (final entity in buildWeb.list(
    recursive: true,
    followLinks: false,
  )) {
    if (entity is! File || !entity.path.endsWith('.html')) continue;
    var html = await entity.readAsString();
    final original = html;
    for (final entry in replacements.entries) {
      html = html.replaceAll(entry.key, entry.value);
    }
    if (html != original) await entity.writeAsString(html);
  }
}
