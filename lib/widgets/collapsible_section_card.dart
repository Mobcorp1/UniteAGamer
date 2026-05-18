import 'package:flutter/material.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class CollapsibleSectionCard extends StatefulWidget {
  const CollapsibleSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.initiallyExpanded = true,
    this.titleColor = AppTheme.neonPink,
  });

  final String title;
  final Widget child;
  final bool initiallyExpanded;
  final Color titleColor;

  @override
  State<CollapsibleSectionCard> createState() => _CollapsibleSectionCardState();
}

class _CollapsibleSectionCardState extends State<CollapsibleSectionCard> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: AppTheme.tradingCardDecoration(radius: 18),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: AppTheme.sectionCardPadding,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: AppTheme.tradingHeading(
                        fontSize: 20,
                        color: widget.titleColor,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.0 : -0.25,
                    duration: AppTheme.fastAnimation,
                    child: Icon(
                      Icons.expand_more_rounded,
                      color: widget.titleColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: AppTheme.fastAnimation,
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceL,
                0,
                AppTheme.spaceL,
                AppTheme.spaceL,
              ),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}
