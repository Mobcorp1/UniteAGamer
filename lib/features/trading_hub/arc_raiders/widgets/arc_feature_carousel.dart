import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_feature_card.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_feature_model.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_global_visual_system.dart';
import 'package:uag_arc_raiders_hub/widgets/uag_page_carousel.dart';

class ArcFeatureCarousel extends StatefulWidget {
  const ArcFeatureCarousel({super.key, required this.items});

  final List<ArcFeatureItem> items;

  @override
  State<ArcFeatureCarousel> createState() => _ArcFeatureCarouselState();
}

class _ArcFeatureCarouselState extends State<ArcFeatureCarousel> {
  int _active = 0;

  @override
  Widget build(BuildContext context) {
    return UagPageCarousel(
      viewportFraction: 0.82,
      tabletViewportFraction: 0.58,
      webViewportFraction: 0.42,
      onPageChanged: (value) {
        setState(() => _active = value);
      },
      pages: List<Widget>.generate(widget.items.length, (index) {
        final selected = index == _active;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: ArcElectricActionBorder(
            active: selected,
            child: ArcFeatureCard(
              item: widget.items[index],
              selected: selected,
            ),
          ),
        );
      }),
    );
  }
}
