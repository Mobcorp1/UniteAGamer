#!/usr/bin/env python3
from pathlib import Path
import json
import re

ROOT = Path.cwd()
MAIN = ROOT / 'lib' / 'main.dart'
RULES = ROOT / 'firestore.rules'
INDEXES = ROOT / 'firestore.indexes.json'
SESSION_SCREEN = ROOT / 'lib' / 'features' / 'trading_hub' / 'arc_raiders' / 'session_planner' / 'session_planner_screen.dart'

IMPORT = "import 'package:uag_traders_hub/features/trading_hub/arc_raiders/session_planner/session_planner_screen.dart';"
ROUTE = "case SessionPlannerScreen.routeName: return MaterialPageRoute( builder: (_) => const FeatureAccessRouteGate( flag: FeatureAccessFlag.traderHub, title: 'Session Planner', child: SessionPlannerScreen(), ), settings: settings, );"


def backup(path: Path):
    if not path.exists():
        return
    backup_dir = ROOT / '_patch_backups_safe' / 'voice_session_route_fix'
    dest = backup_dir / path.relative_to(ROOT)
    dest.parent.mkdir(parents=True, exist_ok=True)
    if not dest.exists():
        dest.write_text(path.read_text(encoding='utf-8'), encoding='utf-8')


def patch_main():
    if not MAIN.exists():
        raise RuntimeError(f'Missing {MAIN}')
    if not SESSION_SCREEN.exists():
        raise RuntimeError(f'Missing {SESSION_SCREEN}. Re-run the previous Voice + Session Planner package first.')
    backup(MAIN)
    text = MAIN.read_text(encoding='utf-8')
    original = text

    if IMPORT not in text:
        marker = "import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/play_like_a_pro_screen.dart';"
        if marker in text:
            text = text.replace(marker, marker + ' ' + IMPORT, 1)
        else:
            # Insert before first non-import token.
            m = re.search(r"(import\s+'[^']+';\s*)+", text)
            if not m:
                raise RuntimeError('Could not find import block in main.dart')
            text = text[:m.end()] + IMPORT + ' ' + text[m.end():]
        print('ADD SessionPlannerScreen import')
    else:
        print('SKIP SessionPlannerScreen import already present')

    if 'case SessionPlannerScreen.routeName:' not in text:
        # Prefer placing after RaidPlanner route.
        marker = "case RaidPlannerScreen.routeName: return MaterialPageRoute( builder: (_) => const RaidPlannerScreen(), settings: settings, );"
        if marker in text:
            text = text.replace(marker, marker + ' ' + ROUTE, 1)
        else:
            # Fallback before Trader Hub route.
            marker = "case TraderHubScreen.routeName:"
            if marker not in text:
                raise RuntimeError('Could not find route insertion point in main.dart')
            text = text.replace(marker, ROUTE + ' ' + marker, 1)
        print('ADD SessionPlannerScreen route')
    else:
        print('SKIP SessionPlannerScreen route already present')

    if text != original:
        MAIN.write_text(text, encoding='utf-8')


def patch_rules():
    if not RULES.exists():
        print('SKIP firestore.rules not found')
        return
    backup(RULES)
    text = RULES.read_text(encoding='utf-8')
    if 'match /sessions/{sessionId}' in text:
        print('SKIP Firestore sessions rules already present')
        return
    block = """

    match /sessions/{sessionId} {
      allow read: if request.auth != null && (
        resource.data.participantOneUid == request.auth.uid ||
        resource.data.participantTwoUid == request.auth.uid ||
        resource.data.createdBy == request.auth.uid
      );

      allow create: if request.auth != null &&
        request.resource.data.createdBy == request.auth.uid &&
        (request.resource.data.participantOneUid == request.auth.uid ||
         request.resource.data.participantTwoUid == request.auth.uid);

      allow update: if request.auth != null && (
        resource.data.participantOneUid == request.auth.uid ||
        resource.data.participantTwoUid == request.auth.uid ||
        resource.data.createdBy == request.auth.uid
      );

      allow delete: if false;
    }
"""
    # Insert before final closing brace if possible.
    idx = text.rfind('}')
    if idx == -1:
        raise RuntimeError('Could not patch firestore.rules: no closing brace found')
    text = text[:idx] + block + text[idx:]
    RULES.write_text(text, encoding='utf-8')
    print('ADD Firestore sessions rules')


def patch_indexes():
    if not INDEXES.exists():
        print('SKIP firestore.indexes.json not found')
        return
    backup(INDEXES)
    data = json.loads(INDEXES.read_text(encoding='utf-8'))
    indexes = data.setdefault('indexes', [])
    wanted = [
        {
            'collectionGroup': 'sessions',
            'queryScope': 'COLLECTION',
            'fields': [
                {'fieldPath': 'participantOneUid', 'order': 'ASCENDING'},
                {'fieldPath': 'scheduledAt', 'order': 'DESCENDING'},
            ],
        },
        {
            'collectionGroup': 'sessions',
            'queryScope': 'COLLECTION',
            'fields': [
                {'fieldPath': 'participantTwoUid', 'order': 'ASCENDING'},
                {'fieldPath': 'scheduledAt', 'order': 'DESCENDING'},
            ],
        },
        {
            'collectionGroup': 'sessions',
            'queryScope': 'COLLECTION',
            'fields': [
                {'fieldPath': 'type', 'order': 'ASCENDING'},
                {'fieldPath': 'scheduledAt', 'order': 'DESCENDING'},
            ],
        },
    ]
    added = 0
    for item in wanted:
        if item not in indexes:
            indexes.append(item)
            added += 1
    INDEXES.write_text(json.dumps(data, indent=2), encoding='utf-8')
    print(f'ADD Firestore indexes: {added}' if added else 'SKIP Firestore indexes already present')


def main():
    patch_main()
    patch_rules()
    patch_indexes()
    print('DONE voice/session planner route fix')

if __name__ == '__main__':
    main()
