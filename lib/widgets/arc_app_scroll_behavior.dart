import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class ArcAppScrollBehavior extends MaterialScrollBehavior {
  const ArcAppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    final desktop = switch (defaultTargetPlatform) {
      TargetPlatform.windows ||
      TargetPlatform.macOS ||
      TargetPlatform.linux => true,
      _ => false,
    };

    // A primary controller can be inherited by more than one nested view.
    // An always-visible Scrollbar asserts when that happens. Mobile already
    // has platform scrolling affordances, and desktop gets a precision
    // scrollbar only when the Scrollable owns a dedicated controller.
    if (!desktop || details.controller == null) return child;

    return Scrollbar(
      controller: details.controller,
      thumbVisibility: true,
      interactive: true,
      child: child,
    );
  }
}
