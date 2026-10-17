import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Only the Stencils and Designs screenshot profiles live here. The locked
/// 91-slot Blueprint classifier remains in its existing implementation.
enum ArcNativeCollectionKind {
  stencils,
  designs;

  String get title => this == stencils ? 'Stencils' : 'Designs';
  String get key => name;
  int get slots => this == stencils ? 14 : 100;
  int get columns => this == stencils ? 9 : 17;
}

enum ArcNativeSlotState { owned, missing, review }

class ArcNativeCollectionSlot {
  const ArcNativeCollectionSlot({
    required this.slot,
    required this.state,
    required this.evidence,
  });

  final int slot; // 1-based, row-major in the game's visible order.
  final ArcNativeSlotState state;
  final double evidence;
}

class ArcNativeCollectionResult {
  const ArcNativeCollectionResult({
    required this.kind,
    required this.slots,
    required this.status,
  });

  final ArcNativeCollectionKind kind;
  final List<ArcNativeCollectionSlot> slots;
  final String status;

  int count(ArcNativeSlotState state) =>
      slots.where((slot) => slot.state == state).length;
}

/// Fixed-layout profile for the native 16:9 ARC Collections screen.
///
/// Uses card centre evidence PLUS the top-right checkmark, never card colour
/// alone. The profile is deliberately not used for mobile photographs,
/// perspective crops, or other game pages. Every ambiguous slot is reviewed.
/// Original screenshots supplied October 13 2026 anchor all test geometry.
class ArcNativeCollectionScreenshotRecognizer {
  const ArcNativeCollectionScreenshotRecognizer();

  ArcNativeCollectionResult analyse(
    Uint8List encoded,
    ArcNativeCollectionKind kind,
  ) {
    final picture = img.decodeImage(encoded);
    if (picture == null) {
      throw const FormatException('Image could not be decoded. Upload the original screenshot.');
    }
    if (picture.width < 1280 || picture.height < 720 ||
        ((picture.width / picture.height) - 16 / 9).abs() > .025) {
      throw const FormatException(
        'Use an uncropped 16:9 in-game screenshot. TV photos are not supported in this beta.',
      );
    }

    // Reference coordinates calibrated on 2048x1152 native PS5 screenshots.
    // Normalised image positions support other native 16:9 resolutions.
    final isStencil = kind == ArcNativeCollectionKind.stencils;
    final x0 = isStencil ? 50.0 : 51.0;
    final y0 = isStencil ? 311.0 : 312.0;
    final pitchX = isStencil ? 211.0 : 110.5;
    final pitchY = isStencil ? 249.0 : 110.4;
    final width = isStencil ? 180.0 : 102.0;
    final height = isStencil ? 216.0 : 103.0;
    final slots = <ArcNativeCollectionSlot>[];
    var borderedCards = 0;

    for (var index = 0; index < kind.slots; index++) {
      final row = index ~/ kind.columns;
      final col = index % kind.columns;
      final x = x0 + col * pitchX;
      final y = y0 + row * pitchY;

      // Outer left border is a sanity check that the image really contains
      // the expected native Collections view at the expected scale.
      final border = _fraction(picture, x, y, width, height,
        .00, .35, .06, .75, _luminous);
      if (border > .05) borderedCards++;

      late final bool isOwned;
      late final bool isEmpty;
      final double content;
      final double tick;
      if (isStencil) {
        // Empty stencil cards have a centred grey number, no yellow tick.
        content = _fraction(picture, x, y, width, height,
          .15, .20, .85, .80, _vivid);
        tick = _fraction(picture, x, y, width, height,
          .76, .05, .95, .24, _yellow);
        isOwned = tick > .012 && content > .10;
        isEmpty = tick < .003 && content < .015;
      } else {
        // Design cards contain varied art and small '+' marks, and a white
        // check in the top right; blanks lack both the art and the check.
        content = _fraction(picture, x, y, width, height,
          .15, .20, .85, .80, _bright);
        tick = _fraction(picture, x, y, width, height,
          .76, .05, .95, .24, _white);
        isOwned = tick > .035 && content > .040;
        isEmpty = tick < .010 && content < .012;
      }
      final state = isOwned
          ? ArcNativeSlotState.owned
          : isEmpty
              ? ArcNativeSlotState.missing
              : ArcNativeSlotState.review;
      slots.add(ArcNativeCollectionSlot(
        slot: index + 1,
        state: state,
        evidence: content.clamp(0.0, 1.0),
      ));
    }
    // Refuse a generic black screenshot or a cropped/misaligned screen.
    if (borderedCards < (kind.slots * .60).ceil()) {
      throw const FormatException(
        'Could not verify the full native collection grid. Upload an uncropped screenshot of the correct tab.',
      );
    }
    if (!slots.any((slot) => slot.state == ArcNativeSlotState.owned)) {
      throw const FormatException(
        'No owned cards were confirmed. Check the selected tab or review the image manually.',
      );
    }
    return ArcNativeCollectionResult(
      kind: kind,
      slots: List.unmodifiable(slots),
      status: 'Screenshot analysed. Review every uncertain card before saving.',
    );
  }

  static bool _luminous(int r, int g, int b) =>
      (r > 35 || g > 35 || b > 35);
  static bool _vivid(int r, int g, int b) {
    final hi = r > g ? (r > b ? r : b) : (g > b ? g : b);
    final lo = r < g ? (r < b ? r : b) : (g < b ? g : b);
    return hi > 65 && hi - lo > 25;
  }
  static bool _bright(int r, int g, int b) => r > 100 || g > 100 || b > 100;
  static bool _white(int r, int g, int b) => r > 130 && g > 130 && b > 130;
  static bool _yellow(int r, int g, int b) =>
      r > 130 && g > 90 && b < 105;

  static double _fraction(
    img.Image picture,
    double cellX,
    double cellY,
    double cellW,
    double cellH,
    double left,
    double top,
    double right,
    double bottom,
    bool Function(int r, int g, int b) test,
  ) {
    final sx = picture.width / 2048;
    final sy = picture.height / 1152;
    final x1 = ((cellX + cellW * left) * sx).round().clamp(0, picture.width - 1);
    final x2 = ((cellX + cellW * right) * sx).round().clamp(0, picture.width);
    final y1 = ((cellY + cellH * top) * sy).round().clamp(0, picture.height - 1);
    final y2 = ((cellY + cellH * bottom) * sy).round().clamp(0, picture.height);
    var hits = 0;
    var samples = 0;
    // Sampling stride keeps 100-card inspection quick on mobile and web.
    for (var py = y1; py < y2; py += 2) {
      for (var px = x1; px < x2; px += 2) {
        final pixel = picture.getPixel(px, py);
        if (test(pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt())) hits++;
        samples++;
      }
    }
    return samples == 0 ? 0 : hits / samples;
  }
}
