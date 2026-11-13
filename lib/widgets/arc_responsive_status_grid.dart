import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/widgets/responsive_layout_helper.dart';

class ArcResponsiveStatusGrid extends StatelessWidget {
  final List<Widget> children;

  const ArcResponsiveStatusGrid({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveLayoutHelper.cardGridColumns(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: children.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: ResponsiveLayoutHelper.isDesktop(context) ? 2.8 : 1.4,
      ),
      itemBuilder: (context, index) {
        return children[index];
      },
    );
  }
}
