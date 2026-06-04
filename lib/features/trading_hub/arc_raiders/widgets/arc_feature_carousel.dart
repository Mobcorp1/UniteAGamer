import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_feature_card.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_feature_model.dart';

class ArcFeatureCarousel extends StatefulWidget {
  const ArcFeatureCarousel({super.key, required this.items});

  final List<ArcFeatureItem> items;

  @override
  State<ArcFeatureCarousel> createState() => _ArcFeatureCarouselState();
}

class _ArcFeatureCarouselState extends State<ArcFeatureCarousel> {
  late final PageController _controller;
  int _active = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.52);
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _controller,
      itemCount: widget.items.length,
      onPageChanged: (value) {
        setState(() => _active = value);
      },
      itemBuilder: (context, index) {
        final selected = index == _active;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: ArcFeatureCard(item: widget.items[index], selected: selected),
        );
      },
    );
  }
}
