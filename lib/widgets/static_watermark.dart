import 'package:flutter/material.dart';

class StaticWatermark extends StatelessWidget {
  const StaticWatermark({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.of(context).size.width;
          final height = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : MediaQuery.of(context).size.height;

          final shortestSide = width < height ? width : height;

          // Tighter, denser pattern with smaller logos and reduced gaps.
          final logoWidth = (shortestSide / 5.8).clamp(64.0, 124.0);
          final logoHeight = logoWidth;
          final xStep = logoWidth * 0.92;
          final yStep = logoHeight * 0.86;
          final rowOffset = logoWidth * 0.46;

          final columns = ((width + logoWidth) / xStep).ceil() + 3;
          final rows = ((height + logoHeight) / yStep).ceil() + 3;

          return Stack(
            fit: StackFit.expand,
            children: [
              for (int row = 0; row < rows; row++)
                for (int col = 0; col < columns; col++)
                  Positioned(
                    left:
                        (-logoWidth * 0.45) +
                        (col * xStep) +
                        ((row.isOdd) ? rowOffset : 0.0),
                    top: (-logoHeight * 0.4) + (row * yStep),
                    child: Opacity(
                      opacity: 0.06,
                      child: SizedBox(
                        width: logoWidth,
                        height: logoHeight,
                        child: Image.asset(
                          'assets/icon/uag_traders_icon_transparent.webp',
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.low,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}
