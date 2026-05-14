from pathlib import Path
import re

ROOT = Path.cwd()
main = ROOT / 'lib' / 'main.dart'
index = ROOT / 'web' / 'index.html'

if not main.exists():
    raise SystemExit('Run this from the project root: C:\\Users\\mikem\\uag_traders_hub')

text = main.read_text(encoding='utf-8')

# Tidy broken one-line imports caused by earlier patching.
text = text.replace("import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/play_like_a_pro_screen.dart'; import 'package:uag_traders_hub/features/trading_hub/arc_raiders/session_planner/session_planner_screen.dart';",
                    "import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/play_like_a_pro_screen.dart';\nimport 'package:uag_traders_hub/features/trading_hub/arc_raiders/session_planner/session_planner_screen.dart';")

# Tidy route formatting if it exists as a one-liner.
text = text.replace("case SessionPlannerScreen.routeName: return MaterialPageRoute( builder: (_) => const FeatureAccessRouteGate( flag: FeatureAccessFlag.traderHub, title: 'Session Planner', child: SessionPlannerScreen(), ), settings: settings, ); case TraderHubScreen.routeName:",
"""case SessionPlannerScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const FeatureAccessRouteGate(
            flag: FeatureAccessFlag.traderHub,
            title: 'Session Planner',
            child: SessionPlannerScreen(),
          ),
          settings: settings,
        );

      case TraderHubScreen.routeName:""")

# Add a MaterialApp builder that forces the Flutter root child to occupy the full viewport.
if 'UAG_WEB_FULL_WIDTH_GUARD' not in text:
    marker = "      navigatorKey: TradingPushService.instance.navigatorKey,\n"
    replacement = """      navigatorKey: TradingPushService.instance.navigatorKey,
      builder: (context, child) {
        // UAG_WEB_FULL_WIDTH_GUARD
        // Prevents web builds from rendering inside a narrow left-side column
        // when an inner screen accidentally reports mobile-width constraints.
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.textScalerOf(context),
          ),
          child: SizedBox.expand(
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
"""
    if marker not in text:
        raise SystemExit('Could not find MaterialApp navigatorKey insertion point in lib/main.dart')
    text = text.replace(marker, replacement, 1)

main.write_text(text, encoding='utf-8')
print('PATCHED lib/main.dart')

if index.exists():
    html = index.read_text(encoding='utf-8')
    css = """
  <style id="uag-web-fullscreen-guard">
    html, body {
      width: 100%;
      height: 100%;
      min-width: 100%;
      margin: 0;
      padding: 0;
      overflow: hidden;
      background: #090529;
    }
    body > *,
    flt-glass-pane,
    flutter-view,
    #flutter_target,
    #app-container {
      width: 100% !important;
      height: 100% !important;
      min-width: 100% !important;
      max-width: none !important;
      margin: 0 !important;
      padding: 0 !important;
    }
    canvas {
      max-width: none !important;
    }
  </style>
"""
    if 'uag-web-fullscreen-guard' not in html:
        if '</head>' in html:
            html = html.replace('</head>', css + '</head>', 1)
        else:
            html = css + html
        index.write_text(html, encoding='utf-8')
        print('PATCHED web/index.html')
    else:
        print('OK web/index.html already patched')
else:
    print('SKIP web/index.html not found')
