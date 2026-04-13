import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StaticWatermark extends StatefulWidget {
  const StaticWatermark({super.key});

  @override
  State<StaticWatermark> createState() => _StaticWatermarkState();
}

class _StaticWatermarkState extends State<StaticWatermark> {
  static ui.Image? _cachedImage;
  static Future<ui.Image>? _loadingFuture;

  ui.Image? _image;

  @override
  void initState() {
    super.initState();

    if (_cachedImage != null) {
      _image = _cachedImage;
      return;
    }

    _loadingFuture ??= _loadAssetImage(
      'assets/icon/uag_traders_icon_transparent.webp',
    );

    _attachLoader();
  }

  Future<void> _attachLoader() async {
    try {
      final image = await _loadingFuture!;
      _cachedImage = image;

      if (!mounted) return;

      setState(() {
        _image = image;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _image = null;
      });
    }
  }

  Future<ui.Image> _loadAssetImage(String asset) async {
    final byteData = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(byteData.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  @override
  Widget build(BuildContext context) {
    final image = _image ?? _cachedImage;

    if (image == null) {
      return const SizedBox.shrink();
    }

    return CustomPaint(
      painter: StaticWatermarkPainter(image),
      size: Size.infinite,
    );
  }
}

class StaticWatermarkPainter extends CustomPainter {
  const StaticWatermarkPainter(this.image);

  final ui.Image image;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color.fromRGBO(255, 255, 255, 0.24);

    final logoWidth = (size.shortestSide / 4.6).clamp(86.0, 168.0);
    final logoHeight = logoWidth * (image.height / image.width);
    final xStep = logoWidth * 1.12;
    final yStep = logoHeight * 1.08;

    for (double y = -logoHeight * 0.3; y < size.height + logoHeight; y += yStep) {
      final rowOffset = (((y / yStep).round()).isOdd) ? logoWidth * 0.42 : 0.0;
      for (double x = -logoWidth * 0.25; x < size.width + logoWidth; x += xStep) {
        canvas.drawImageRect(
          image,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          Rect.fromLTWH(x + rowOffset, y, logoWidth, logoHeight),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant StaticWatermarkPainter oldDelegate) {
    return oldDelegate.image != image;
  }
}
