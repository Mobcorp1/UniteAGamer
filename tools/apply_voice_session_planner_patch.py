#!/usr/bin/env python3
from __future__ import annotations
import json
import re
from pathlib import Path

ROOT = Path.cwd()
VOICE_DIR = ROOT / 'lib/features/trading_hub/arc_raiders/voice'
SESSION_DIR = ROOT / 'lib/features/trading_hub/arc_raiders/session_planner'
DATA_DIR = ROOT / 'lib/features/trading_hub/arc_raiders/data'

REQUIRED_DEPS = {
    'speech_to_text': '^7.0.0',
    'flutter_tts': '^4.0.2',
    'table_calendar': '^3.1.2',
    'uuid': '^4.5.1',
    'timezone': '^0.9.4',
    'flutter_timezone': '^4.0.0',
    'add_2_calendar': '^3.0.1',
}

def write(path: Path, content: str):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content.strip() + '\n', encoding='utf-8')
    print(f'WRITE {path.relative_to(ROOT)}')

def patch_pubspec():
    path = ROOT / 'pubspec.yaml'
    text = path.read_text(encoding='utf-8')
    lines = text.splitlines()
    insert_at = None
    for i, line in enumerate(lines):
        if line.strip().startswith('intl:'):
            insert_at = i + 1
    if insert_at is None:
        for i, line in enumerate(lines):
            if line.startswith('dev_dependencies:'):
                insert_at = i
                break
    if insert_at is None:
        raise RuntimeError('Could not locate dependency insertion point in pubspec.yaml')
    for dep, version in REQUIRED_DEPS.items():
        if not re.search(rf'^\s{{2}}{re.escape(dep)}\s*:', text, re.M):
            lines.insert(insert_at, f'  {dep}: {version}')
            insert_at += 1
            print(f'ADD dependency {dep}')
    text = '\n'.join(lines) + '\n'
    if 'assets/arc_raiders/items/' not in text:
        text = text.replace('    - assets/arc_raiders/scrappy_resources/\n', '    - assets/arc_raiders/scrappy_resources/\n    - assets/arc_raiders/items/\n')
        print('ADD assets/arc_raiders/items/')
    path.write_text(text, encoding='utf-8')

def patch_analysis_options():
    path = ROOT / 'analysis_options.yaml'
    if not path.exists():
        path.write_text("include: package:flutter_lints/flutter.yaml\n\nanalyzer:\n  exclude:\n    - '**/_patch_backups/**'\n    - '**/_patch_recovery_backups/**'\n    - '**/.patch_backups/**'\n", encoding='utf-8')
        print('WRITE analysis_options.yaml')
        return
    text = path.read_text(encoding='utf-8')
    excludes = ["    - '**/_patch_backups/**'", "    - '**/_patch_recovery_backups/**'", "    - '**/.patch_backups/**'"]
    if 'analyzer:' not in text:
        text += "\nanalyzer:\n  exclude:\n" + '\n'.join(excludes) + '\n'
    elif 'exclude:' not in text:
        text += "\n  exclude:\n" + '\n'.join(excludes) + '\n'
    else:
        for e in excludes:
            if e not in text:
                text += e + '\n'
    path.write_text(text, encoding='utf-8')
    print('PATCH analysis_options.yaml')

def patch_main():
    path = ROOT / 'lib/main.dart'
    text = path.read_text(encoding='utf-8')
    imp = "import 'package:uag_traders_hub/features/trading_hub/arc_raiders/session_planner/session_planner_screen.dart';"
    if imp not in text:
        marker = "import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_activity_screen.dart';"
        if marker in text:
            text = text.replace(marker, imp + ' ' + marker)
            print('ADD SessionPlannerScreen import')
        else:
            text = imp + ' ' + text
            print('ADD SessionPlannerScreen import at top')
    if 'case SessionPlannerScreen.routeName:' not in text:
        marker = "case TradingTradeSessionsScreen.routeName: return MaterialPageRoute("
        route = "case SessionPlannerScreen.routeName: return MaterialPageRoute( builder: (_) => const FeatureAccessRouteGate( flag: FeatureAccessFlag.traderHub, title: 'Session Planner', child: SessionPlannerScreen(), ), settings: settings, ); "
        if marker not in text:
            raise RuntimeError('Could not find insertion point in main.dart for SessionPlannerScreen route')
        text = text.replace(marker, route + marker)
        print('ADD SessionPlannerScreen route')
    path.write_text(text, encoding='utf-8')

def norm(value: str) -> str:
    value = value.lower().replace('&', ' and ')
    value = re.sub(r"['’]", '', value)
    value = re.sub(r'[^a-z0-9]+', '_', value).strip('_')
    return value

def extract_items_from_file(path: Path, source_label: str):
    if not path.exists():
        return []
    text = path.read_text(encoding='utf-8', errors='ignore')
    items = []
    patterns = [(r"\bid\s*:\s*'([^']+)'", r"\bname\s*:\s*'([^']+)'"), (r"\bitemId\s*:\s*'([^']+)'", r"\bitemName\s*:\s*'([^']+)'"), (r"\bvalue\s*:\s*'([^']+)'", r"\blabel\s*:\s*'([^']+)'")]
    for id_pat, name_pat in patterns:
        for m in re.finditer(id_pat, text):
            window = text[m.start():m.start()+900]
            n = re.search(name_pat, window)
            if not n:
                continue
            item_id, name = m.group(1), n.group(1)
            if len(name) < 2 or name in {'Owned','Wanted','Missing','All','None','Search','Filter'}:
                continue
            items.append((item_id, name, source_label))
    return items

def generate_unified_index():
    source_files = [('arc_scrappy_seed_data.dart','Scrappy Tracker'), ('arc_bench_upgrade_seed_data.dart','Bench Tracker'), ('arc_quest_requirement_seed_data.dart','Quest Tracker'), ('arc_trade_catalog.dart','Trading Hub'), ('trade_items_data.dart','Trading Hub')]
    merged = {}
    for filename, label in source_files:
        for item_id, name, source in extract_items_from_file(DATA_DIR/filename, label):
            key = norm(name) or norm(item_id)
            if not key: continue
            existing = merged.setdefault(key, {'id': norm(item_id).replace('_','-'), 'name': name, 'usedIn': set(), 'aliases': set()})
            existing['usedIn'].add(source)
            existing['aliases'].add(norm(item_id).replace('_',' '))
            existing['aliases'].add(name.lower())
    entries = sorted(merged.values(), key=lambda x: x['name'].lower())
    lines = ["import 'package:flutter/foundation.dart';", '', '@immutable', 'class UnifiedItemEntry {', '  const UnifiedItemEntry({', '    required this.id,', '    required this.name,', '    required this.usedIn,', '    this.aliases = const <String>[],', '  });', '  final String id;', '  final String name;', '  final List<String> usedIn;', '  final List<String> aliases;', "  bool get neededForBench => usedIn.contains('Bench Tracker');", "  bool get neededForQuest => usedIn.contains('Quest Tracker');", "  bool get neededForScrappy => usedIn.contains('Scrappy Tracker');", "  bool get tradeRelevant => usedIn.contains('Trading Hub');", '}', '', 'class UnifiedItemIndex {', '  const UnifiedItemIndex._();', '  static const List<UnifiedItemEntry> items = <UnifiedItemEntry>[']
    for e in entries:
        used = ', '.join([repr(x) for x in sorted(e['usedIn'])])
        aliases = sorted(a for a in e['aliases'] if a and a != e['name'].lower())
        alias_str = ', '.join([repr(x) for x in aliases[:10]])
        lines.append(f"    UnifiedItemEntry(id: '{e['id']}', name: {e['name']!r}, usedIn: <String>[{used}], aliases: <String>[{alias_str}]),")
    lines += ['  ];', '', '  static String normalize(String value) {', "    return value.toLowerCase().replaceAll('&', ' and ').replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();", '  }', '', '  static UnifiedItemEntry? findBest(String query) {', '    final normalized = normalize(query);', '    if (normalized.isEmpty) return null;', '    for (final item in items) {', '      if (normalize(item.name) == normalized || normalize(item.id) == normalized) return item;', '      for (final alias in item.aliases) {', '        if (normalize(alias) == normalized) return item;', '      }', '    }', '    for (final item in items) {', '      final name = normalize(item.name);', '      if (name.contains(normalized) || normalized.contains(name)) return item;', '      for (final alias in item.aliases) {', '        final normalizedAlias = normalize(alias);', '        if (normalizedAlias.contains(normalized) || normalized.contains(normalizedAlias)) return item;', '      }', '    }', '    return null;', '  }', '', '  static List<UnifiedItemEntry> search(String query) {', '    final normalized = normalize(query);', '    if (normalized.isEmpty) return const <UnifiedItemEntry>[];', '    return items.where((item) {', '      final name = normalize(item.name);', '      if (name.contains(normalized) || normalized.contains(name)) return true;', '      return item.aliases.any((alias) => normalize(alias).contains(normalized));', '    }).take(20).toList(growable: false);', '  }', '}']
    write(DATA_DIR/'unified_item_index.dart', '\n'.join(lines))
    print(f'Generated unified item index with {len(entries)} items')

VOICE_INTENT = '''
enum UagVoiceIntentType {
  needCheck,
  tradeCheck,
  benchLookup,
  questLookup,
  keepCheck,
  unknown,
}

class UagVoiceIntent {
  const UagVoiceIntent({
    required this.type,
    required this.rawText,
    this.itemQuery,
  });

  final UagVoiceIntentType type;
  final String rawText;
  final String? itemQuery;
}
'''
VOICE_PARSER = '''
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/unified_item_index.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/voice/voice_intent.dart';

class UagVoiceIntentParser {
  const UagVoiceIntentParser();

  UagVoiceIntent parse(String text) {
    final raw = text.trim();
    final normalized = UnifiedItemIndex.normalize(raw);
    if (normalized.isEmpty) {
      return UagVoiceIntent(type: UagVoiceIntentType.unknown, rawText: raw);
    }

    if (normalized.contains('what can i trade') ||
        normalized.contains('safe to trade') ||
        normalized.contains('can i trade')) {
      return UagVoiceIntent(type: UagVoiceIntentType.tradeCheck, rawText: raw, itemQuery: _extractItem(raw));
    }
    if (normalized.contains('bench')) {
      return UagVoiceIntent(type: UagVoiceIntentType.benchLookup, rawText: raw, itemQuery: _extractItem(raw));
    }
    if (normalized.contains('quest')) {
      return UagVoiceIntent(type: UagVoiceIntentType.questLookup, rawText: raw, itemQuery: _extractItem(raw));
    }
    if (normalized.contains('keep') || normalized.contains('need')) {
      return UagVoiceIntent(type: UagVoiceIntentType.needCheck, rawText: raw, itemQuery: _extractItem(raw));
    }
    return UagVoiceIntent(type: UagVoiceIntentType.needCheck, rawText: raw, itemQuery: _extractItem(raw));
  }

  String? _extractItem(String raw) {
    var cleaned = raw.toLowerCase();
    const phrases = <String>['do i need','do we need','should i keep','can i trade','what can i trade','is this needed','is it needed','for bench','for quest','uag raider','hey uag raider'];
    for (final phrase in phrases) { cleaned = cleaned.replaceAll(phrase, ' '); }
    cleaned = cleaned.replaceAll('?', ' ').trim();
    return cleaned.isEmpty ? null : cleaned;
  }
}
'''
VOICE_RESPONSE = '''
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/unified_item_index.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/voice/voice_intent.dart';

class UagVoiceResponse {
  const UagVoiceResponse({required this.title, required this.body, required this.shouldSpeak});
  final String title;
  final String body;
  final bool shouldSpeak;
}

class UagVoiceResponseBuilder {
  const UagVoiceResponseBuilder();
  UagVoiceResponse build(UagVoiceIntent intent) {
    final query = intent.itemQuery ?? intent.rawText;
    final item = UnifiedItemIndex.findBest(query);
    if (item == null) {
      return const UagVoiceResponse(title: 'No item match found', body: 'I could not match that to a tracked ARC Raiders item yet.', shouldSpeak: true);
    }
    final usedIn = item.usedIn.isEmpty ? 'No tracker usage found yet.' : item.usedIn.join(', ');
    final keepLevel = item.neededForBench || item.neededForQuest || item.neededForScrappy ? 'KEEP' : item.tradeRelevant ? 'TRADE RELEVANT' : 'CHECK MANUALLY';
    final body = '${item.name}: $keepLevel. Used in: $usedIn.';
    return UagVoiceResponse(title: item.name, body: body, shouldSpeak: true);
  }
}
'''
VOICE_SERVICE = '''
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/voice/voice_intent_parser.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/voice/voice_response_builder.dart';

class UagVoiceAssistantService extends ChangeNotifier {
  UagVoiceAssistantService({stt.SpeechToText? speech, FlutterTts? tts}) : _speech = speech ?? stt.SpeechToText(), _tts = tts ?? FlutterTts();
  final stt.SpeechToText _speech;
  final FlutterTts _tts;
  final UagVoiceIntentParser _parser = const UagVoiceIntentParser();
  final UagVoiceResponseBuilder _responseBuilder = const UagVoiceResponseBuilder();
  bool _available = false;
  bool _listening = false;
  String _transcript = '';
  UagVoiceResponse? _lastResponse;
  bool get available => _available;
  bool get listening => _listening;
  String get transcript => _transcript;
  UagVoiceResponse? get lastResponse => _lastResponse;
  Future<void> initialize() async {
    _available = await _speech.initialize(onError: (error) => debugPrint('UAG voice error: $error'), onStatus: (status) => debugPrint('UAG voice status: $status'));
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    notifyListeners();
  }
  Future<void> startListening() async {
    if (!_available) await initialize();
    if (!_available || _listening) return;
    _transcript = '';
    _lastResponse = null;
    _listening = true;
    notifyListeners();
    await _speech.listen(listenMode: stt.ListenMode.confirmation, onResult: (result) { _transcript = result.recognizedWords; if (result.finalResult) { _listening = false; _handleTranscript(_transcript); } notifyListeners(); });
  }
  Future<void> stopListening() async { await _speech.stop(); _listening = false; if (_transcript.trim().isNotEmpty) _handleTranscript(_transcript); notifyListeners(); }
  Future<void> speak(String text) async { await _tts.stop(); await _tts.speak(text); }
  void submitText(String text) { _transcript = text; _handleTranscript(text); notifyListeners(); }
  void _handleTranscript(String text) { final intent = _parser.parse(text); final response = _responseBuilder.build(intent); _lastResponse = response; if (response.shouldSpeak) speak(response.body); }
  @override void dispose() { _speech.cancel(); _tts.stop(); super.dispose(); }
}
'''
VOICE_SHEET = '''
import 'package:flutter/material.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/voice/voice_assistant_service.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class UagVoiceAssistantSheet extends StatefulWidget {
  const UagVoiceAssistantSheet({super.key});
  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(context: context, isScrollControlled: true, backgroundColor: AppTheme.cardBackgroundDeep, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (_) => const UagVoiceAssistantSheet());
  @override State<UagVoiceAssistantSheet> createState() => _UagVoiceAssistantSheetState();
}

class _UagVoiceAssistantSheetState extends State<UagVoiceAssistantSheet> {
  late final UagVoiceAssistantService _service;
  final TextEditingController _textController = TextEditingController();
  @override void initState() { super.initState(); _service = UagVoiceAssistantService()..initialize(); _service.addListener(_onServiceChanged); }
  @override void dispose() { _service.removeListener(_onServiceChanged); _service.dispose(); _textController.dispose(); super.dispose(); }
  void _onServiceChanged() => setState(() {});
  @override Widget build(BuildContext context) {
    final response = _service.lastResponse;
    return SafeArea(top: false, child: Padding(padding: EdgeInsets.only(left: AppTheme.spaceL, right: AppTheme.spaceL, top: AppTheme.spaceL, bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spaceL), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(999)))),
      const SizedBox(height: AppTheme.spaceL),
      Text('UAG Raider Voice', style: AppTheme.tradingHeading(fontSize: 24, color: AppTheme.neonPink)),
      const SizedBox(height: AppTheme.spaceS),
      Text('Ask: “Do I need ARC Alloy?” or “Can I trade lemons?”', style: AppTheme.bodyTextStyle(fontSize: 14, color: Colors.white70)),
      const SizedBox(height: AppTheme.spaceL),
      ElevatedButton.icon(onPressed: _service.listening ? _service.stopListening : _service.startListening, icon: Icon(_service.listening ? Icons.stop_rounded : Icons.mic_rounded), label: Text(_service.listening ? 'Listening… tap to stop' : 'Tap and ask UAG Raider')),
      const SizedBox(height: AppTheme.spaceM),
      TextField(controller: _textController, style: const TextStyle(color: Colors.white), decoration: AppTheme.tradingInputDecoration(label: 'Type instead'), onSubmitted: _service.submitText),
      const SizedBox(height: AppTheme.spaceS),
      OutlinedButton.icon(onPressed: () => _service.submitText(_textController.text), icon: const Icon(Icons.search_rounded), label: const Text('Search')),
      if (_service.transcript.trim().isNotEmpty) ...[const SizedBox(height: AppTheme.spaceM), Text('Heard: ${_service.transcript}', style: AppTheme.bodyTextStyle(fontSize: 13, color: AppTheme.neonCyan))],
      if (response != null) ...[const SizedBox(height: AppTheme.spaceL), Container(padding: const EdgeInsets.all(AppTheme.spaceM), decoration: AppTheme.tradingCardDecoration(borderColor: AppTheme.neonCyan.withValues(alpha: 0.38)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(response.title, style: AppTheme.tradingHeading(fontSize: 20, color: AppTheme.neonCyan)), const SizedBox(height: AppTheme.spaceS), Text(response.body, style: AppTheme.bodyTextStyle(fontSize: 14, color: Colors.white))]))],
    ])));
  }
}
'''
SESSION_MODEL = '''
import 'package:cloud_firestore/cloud_firestore.dart';

class UagSession {
  const UagSession({required this.id, required this.type, required this.game, required this.createdBy, required this.participantOneUid, required this.participantTwoUid, required this.participantOneDisplayName, required this.participantTwoDisplayName, required this.participantOneEmbarkId, required this.participantTwoEmbarkId, required this.scheduledAt, required this.timezone, required this.status, this.tradeListingId, this.matchmakingId, this.notes, this.participantOneReady = false, this.participantTwoReady = false, this.participantOneCompleted = false, this.participantTwoCompleted = false, this.participantOneNoShow = false, this.participantTwoNoShow = false});
  final String id; final String type; final String game; final String createdBy; final String participantOneUid; final String participantTwoUid; final String participantOneDisplayName; final String participantTwoDisplayName; final String participantOneEmbarkId; final String participantTwoEmbarkId; final DateTime scheduledAt; final String timezone; final String status; final String? tradeListingId; final String? matchmakingId; final String? notes; final bool participantOneReady; final bool participantTwoReady; final bool participantOneCompleted; final bool participantTwoCompleted; final bool participantOneNoShow; final bool participantTwoNoShow;
  factory UagSession.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) { final data = doc.data() ?? <String, dynamic>{}; DateTime readTime(Object? value) { if (value is Timestamp) return value.toDate(); if (value is String) return DateTime.tryParse(value) ?? DateTime.now(); return DateTime.now(); } return UagSession(id: data['id'] as String? ?? doc.id, type: data['type'] as String? ?? 'trade', game: data['game'] as String? ?? 'arc_raiders', createdBy: data['createdBy'] as String? ?? '', participantOneUid: data['participantOneUid'] as String? ?? '', participantTwoUid: data['participantTwoUid'] as String? ?? '', participantOneDisplayName: data['participantOneDisplayName'] as String? ?? 'Player One', participantTwoDisplayName: data['participantTwoDisplayName'] as String? ?? 'Player Two', participantOneEmbarkId: data['participantOneEmbarkId'] as String? ?? '', participantTwoEmbarkId: data['participantTwoEmbarkId'] as String? ?? '', scheduledAt: readTime(data['scheduledAt']), timezone: data['timezone'] as String? ?? 'Europe/London', status: data['status'] as String? ?? 'scheduled', tradeListingId: data['tradeListingId'] as String?, matchmakingId: data['matchmakingId'] as String?, notes: data['notes'] as String?, participantOneReady: data['participantOneReady'] as bool? ?? false, participantTwoReady: data['participantTwoReady'] as bool? ?? false, participantOneCompleted: data['participantOneCompleted'] as bool? ?? false, participantTwoCompleted: data['participantTwoCompleted'] as bool? ?? false, participantOneNoShow: data['participantOneNoShow'] as bool? ?? false, participantTwoNoShow: data['participantTwoNoShow'] as bool? ?? false); }
  Map<String, dynamic> toMap() => <String, dynamic>{'id': id, 'type': type, 'game': game, 'createdBy': createdBy, 'participantOneUid': participantOneUid, 'participantTwoUid': participantTwoUid, 'participantOneDisplayName': participantOneDisplayName, 'participantTwoDisplayName': participantTwoDisplayName, 'participantOneEmbarkId': participantOneEmbarkId, 'participantTwoEmbarkId': participantTwoEmbarkId, 'participantOneEmbarkVisible': true, 'participantTwoEmbarkVisible': true, 'scheduledAt': Timestamp.fromDate(scheduledAt), 'timezone': timezone, 'status': status, 'tradeListingId': tradeListingId, 'matchmakingId': matchmakingId, 'notes': notes, 'participantOneReady': participantOneReady, 'participantTwoReady': participantTwoReady, 'participantOneCompleted': participantOneCompleted, 'participantTwoCompleted': participantTwoCompleted, 'participantOneNoShow': participantOneNoShow, 'participantTwoNoShow': participantTwoNoShow, 'updatedAt': FieldValue.serverTimestamp()};
}
'''
SESSION_REPO = '''
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/session_planner/session_model.dart';

class UagSessionRepository {
  UagSessionRepository({FirebaseFirestore? firestore, FirebaseAuth? auth}) : _firestore = firestore ?? FirebaseFirestore.instance, _auth = auth ?? FirebaseAuth.instance;
  final FirebaseFirestore _firestore; final FirebaseAuth _auth; static const String collectionPath = 'uag_sessions';
  CollectionReference<Map<String, dynamic>> get _sessions => _firestore.collection(collectionPath);
  String get currentUid { final uid = _auth.currentUser?.uid; if (uid == null) throw StateError('User must be signed in.'); return uid; }
  Future<String> createManualSession({required String type, required String participantTwoUid, required String participantTwoDisplayName, required String participantTwoEmbarkId, required DateTime scheduledAt, required String timezone, required String notes}) async { final user = _auth.currentUser; if (user == null) throw StateError('User must be signed in.'); final id = const Uuid().v4(); final session = UagSession(id: id, type: type, game: 'arc_raiders', createdBy: user.uid, participantOneUid: user.uid, participantTwoUid: participantTwoUid, participantOneDisplayName: user.displayName ?? user.email ?? 'You', participantTwoDisplayName: participantTwoDisplayName, participantOneEmbarkId: '', participantTwoEmbarkId: participantTwoEmbarkId, scheduledAt: scheduledAt, timezone: timezone, status: 'scheduled', notes: notes); final data = session.toMap(); data['createdAt'] = FieldValue.serverTimestamp(); await _sessions.doc(id).set(data); return id; }
  Stream<List<UagSession>> streamMySessions() { final uid = currentUid; final controller = StreamController<List<UagSession>>(); List<UagSession> one = <UagSession>[]; List<UagSession> two = <UagSession>[]; void emit() { final merged = <String, UagSession>{}; for (final session in [...one, ...two]) { merged[session.id] = session; } final sessions = merged.values.toList()..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt)); if (!controller.isClosed) controller.add(sessions); } final subOne = _sessions.where('participantOneUid', isEqualTo: uid).orderBy('scheduledAt').snapshots().listen((snapshot) { one = snapshot.docs.map(UagSession.fromDoc).toList(growable: false); emit(); }, onError: controller.addError); final subTwo = _sessions.where('participantTwoUid', isEqualTo: uid).orderBy('scheduledAt').snapshots().listen((snapshot) { two = snapshot.docs.map(UagSession.fromDoc).toList(growable: false); emit(); }, onError: controller.addError); controller.onCancel = () async { await subOne.cancel(); await subTwo.cancel(); }; return controller.stream; }
  Future<void> updateStatus(String id, String status) => _sessions.doc(id).update(<String, dynamic>{'status': status, 'updatedAt': FieldValue.serverTimestamp()});
  Future<void> toggleReady(UagSession session) { final uid = currentUid; final field = uid == session.participantOneUid ? 'participantOneReady' : 'participantTwoReady'; final current = uid == session.participantOneUid ? session.participantOneReady : session.participantTwoReady; return _sessions.doc(session.id).update(<String, dynamic>{field: !current, 'updatedAt': FieldValue.serverTimestamp()}); }
  Future<void> markComplete(UagSession session) { final uid = currentUid; final field = uid == session.participantOneUid ? 'participantOneCompleted' : 'participantTwoCompleted'; return _sessions.doc(session.id).update(<String, dynamic>{field: true, 'status': 'completed', 'updatedAt': FieldValue.serverTimestamp()}); }
  Future<void> markNoShow(UagSession session) { final uid = currentUid; final field = uid == session.participantOneUid ? 'participantTwoNoShow' : 'participantOneNoShow'; return _sessions.doc(session.id).update(<String, dynamic>{field: true, 'status': 'no_show', 'updatedAt': FieldValue.serverTimestamp()}); }
}
'''
SESSION_CREATION = '''
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/session_planner/session_repository.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class SessionCreationSheet extends StatefulWidget {
  const SessionCreationSheet({super.key, required this.repository});
  final UagSessionRepository repository;
  static Future<void> show(BuildContext context, UagSessionRepository repository) => showModalBottomSheet<void>(context: context, isScrollControlled: true, backgroundColor: AppTheme.cardBackgroundDeep, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (_) => SessionCreationSheet(repository: repository));
  @override State<SessionCreationSheet> createState() => _SessionCreationSheetState();
}
class _SessionCreationSheetState extends State<SessionCreationSheet> {
  final TextEditingController _uidController = TextEditingController(); final TextEditingController _nameController = TextEditingController(); final TextEditingController _embarkController = TextEditingController(); final TextEditingController _notesController = TextEditingController(); DateTime _date = DateTime.now().add(const Duration(days: 1)); TimeOfDay _time = const TimeOfDay(hour: 20, minute: 0); String _type = 'trade'; bool _saving = false;
  @override void dispose() { _uidController.dispose(); _nameController.dispose(); _embarkController.dispose(); _notesController.dispose(); super.dispose(); }
  Future<void> _pickDate() async { final result = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime.now().subtract(const Duration(days: 1)), lastDate: DateTime.now().add(const Duration(days: 365))); if (result != null) setState(() => _date = result); }
  Future<void> _pickTime() async { final result = await showTimePicker(context: context, initialTime: _time); if (result != null) setState(() => _time = result); }
  Future<void> _save() async { if (_saving) return; if (_uidController.text.trim().isEmpty || _nameController.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add the other player UID and display name.'))); return; } setState(() => _saving = true); try { final timezone = await FlutterTimezone.getLocalTimezone(); final scheduledAt = DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute); await widget.repository.createManualSession(type: _type, participantTwoUid: _uidController.text.trim(), participantTwoDisplayName: _nameController.text.trim(), participantTwoEmbarkId: _embarkController.text.trim(), scheduledAt: scheduledAt, timezone: timezone, notes: _notesController.text.trim()); if (!mounted) return; Navigator.of(context).pop(); } catch (e) { if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not create session: $e'))); } finally { if (mounted) setState(() => _saving = false); } }
  @override Widget build(BuildContext context) => SafeArea(top: false, child: Padding(padding: EdgeInsets.only(left: AppTheme.spaceL, right: AppTheme.spaceL, top: AppTheme.spaceL, bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spaceL), child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text('Schedule Session', style: AppTheme.tradingHeading(fontSize: 24, color: AppTheme.neonPink)), const SizedBox(height: AppTheme.spaceM), DropdownButtonFormField<String>(value: _type, decoration: AppTheme.tradingInputDecoration(label: 'Type'), dropdownColor: AppTheme.cardBackgroundAlt, items: const [DropdownMenuItem(value: 'trade', child: Text('Trade')), DropdownMenuItem(value: 'matchmaking', child: Text('Matchmaking'))], onChanged: (value) => setState(() => _type = value ?? 'trade')), const SizedBox(height: AppTheme.spaceM), TextField(controller: _uidController, style: const TextStyle(color: Colors.white), decoration: AppTheme.tradingInputDecoration(label: 'Other player UID')), const SizedBox(height: AppTheme.spaceM), TextField(controller: _nameController, style: const TextStyle(color: Colors.white), decoration: AppTheme.tradingInputDecoration(label: 'Other player display name')), const SizedBox(height: AppTheme.spaceM), TextField(controller: _embarkController, style: const TextStyle(color: Colors.white), decoration: AppTheme.tradingInputDecoration(label: 'Other player Embark ID')), const SizedBox(height: AppTheme.spaceM), Row(children: [Expanded(child: OutlinedButton.icon(onPressed: _pickDate, icon: const Icon(Icons.calendar_month_rounded), label: Text('${_date.day}/${_date.month}/${_date.year}'))), const SizedBox(width: AppTheme.spaceS), Expanded(child: OutlinedButton.icon(onPressed: _pickTime, icon: const Icon(Icons.schedule_rounded), label: Text(_time.format(context))))]), const SizedBox(height: AppTheme.spaceM), TextField(controller: _notesController, minLines: 2, maxLines: 4, style: const TextStyle(color: Colors.white), decoration: AppTheme.tradingInputDecoration(label: 'Notes')), const SizedBox(height: AppTheme.spaceL), ElevatedButton.icon(onPressed: _saving ? null : _save, icon: const Icon(Icons.save_rounded), label: Text(_saving ? 'Saving…' : 'Create Session'))]))));
}
'''
EMBARK_CARD = '''
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class EmbarkIdCard extends StatelessWidget {
  const EmbarkIdCard({super.key, required this.label, required this.embarkId});
  final String label; final String embarkId;
  @override Widget build(BuildContext context) { final visible = embarkId.trim().isNotEmpty; return Container(padding: const EdgeInsets.all(AppTheme.spaceM), decoration: AppTheme.tradingCardDecoration(borderColor: AppTheme.neonCyan.withValues(alpha: 0.24)), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: AppTheme.bodyTextStyle(fontSize: 12, color: Colors.white60, isBold: true)), const SizedBox(height: 4), Text(visible ? embarkId : 'Not added yet', style: AppTheme.tradingHeading(fontSize: 16, color: visible ? AppTheme.neonCyan : Colors.white54))])), IconButton(tooltip: 'Copy Embark ID', onPressed: visible ? () => Clipboard.setData(ClipboardData(text: embarkId)) : null, icon: const Icon(Icons.copy_rounded))])); }
}
'''
SESSION_SCREEN = '''
import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/session_planner/embark_id_card.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/session_planner/session_creation_sheet.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/session_planner/session_model.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/session_planner/session_repository.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/voice/voice_assistant_sheet.dart';
import 'package:uag_traders_hub/widgets/static_watermark.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class SessionPlannerScreen extends StatefulWidget { const SessionPlannerScreen({super.key}); static const routeName = '/trading-hub/arc-raiders/session-planner'; @override State<SessionPlannerScreen> createState() => _SessionPlannerScreenState(); }
class _SessionPlannerScreenState extends State<SessionPlannerScreen> {
  final UagSessionRepository _repository = UagSessionRepository(); DateTime _focusedDay = DateTime.now(); DateTime? _selectedDay;
  List<UagSession> _sessionsForDay(List<UagSession> sessions, DateTime day) => sessions.where((session) => isSameDay(session.scheduledAt, day)).toList(growable: false);
  Future<void> _addToCalendar(UagSession session) async { final event = Event(title: 'UAG ${session.type == 'trade' ? 'Trade' : 'Match'}: ${session.participantTwoDisplayName}', description: 'Game: ARC Raiders\nEmbark ID: ${session.participantTwoEmbarkId}\nNotes: ${session.notes ?? ''}', startDate: session.scheduledAt, endDate: session.scheduledAt.add(const Duration(hours: 1))); await Add2Calendar.addEvent2Cal(event); }
  Future<void> _share(UagSession session) async { final text = 'UAG ${session.type} session for ARC Raiders\nWhen: ${session.scheduledAt}\nWith: ${session.participantTwoDisplayName}\nEmbark ID: ${session.participantTwoEmbarkId}\n${session.notes?.isNotEmpty == true ? 'Notes: ${session.notes}' : ''}'; await Share.share(text); }
  @override Widget build(BuildContext context) => Scaffold(backgroundColor: AppTheme.darkBackground, appBar: AppBar(title: const Text('Session Planner'), actions: [IconButton(tooltip: 'Ask UAG Raider', onPressed: () => UagVoiceAssistantSheet.show(context), icon: const Icon(Icons.mic_rounded))]), floatingActionButton: FloatingActionButton.extended(backgroundColor: AppTheme.neonPink.withValues(alpha: 0.92), foregroundColor: AppTheme.darkBackground, onPressed: () => SessionCreationSheet.show(context, _repository), icon: const Icon(Icons.add_rounded), label: const Text('Session')), body: Stack(children: [const StaticWatermark(), StreamBuilder<List<UagSession>>(stream: _repository.streamMySessions(), builder: (context, snapshot) { if (snapshot.hasError) return Center(child: Text('Could not load sessions: ${snapshot.error}', style: const TextStyle(color: Colors.white70))); final sessions = snapshot.data ?? const <UagSession>[]; final selected = _sessionsForDay(sessions, _selectedDay ?? _focusedDay); return ListView(padding: const EdgeInsets.all(AppTheme.spaceL), children: [Container(decoration: AppTheme.tradingCardDecoration(borderColor: AppTheme.neonCyan.withValues(alpha: 0.26)), child: TableCalendar<UagSession>(firstDay: DateTime.now().subtract(const Duration(days: 365)), lastDay: DateTime.now().add(const Duration(days: 365)), focusedDay: _focusedDay, selectedDayPredicate: (day) => isSameDay(_selectedDay, day), eventLoader: (day) => _sessionsForDay(sessions, day), calendarStyle: CalendarStyle(markerDecoration: const BoxDecoration(color: AppTheme.neonPink, shape: BoxShape.circle), todayDecoration: BoxDecoration(color: AppTheme.neonCyan.withValues(alpha: 0.22), shape: BoxShape.circle), selectedDecoration: const BoxDecoration(color: AppTheme.neonPink, shape: BoxShape.circle), defaultTextStyle: const TextStyle(color: Colors.white), weekendTextStyle: const TextStyle(color: Colors.white70)), headerStyle: const HeaderStyle(titleCentered: true, formatButtonVisible: false, titleTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)), daysOfWeekStyle: const DaysOfWeekStyle(weekdayStyle: TextStyle(color: Colors.white70), weekendStyle: TextStyle(color: Colors.white54)), onDaySelected: (selectedDay, focusedDay) { setState(() { _selectedDay = selectedDay; _focusedDay = focusedDay; }); })), const SizedBox(height: AppTheme.spaceL), Text('Sessions', style: AppTheme.tradingHeading(fontSize: 22, color: AppTheme.neonPink)), const SizedBox(height: AppTheme.spaceM), if (selected.isEmpty) Container(padding: const EdgeInsets.all(AppTheme.spaceL), decoration: AppTheme.tradingCardDecoration(), child: Text('No sessions on this day.', style: AppTheme.bodyTextStyle(fontSize: 14, color: Colors.white70))) else ...selected.map(_buildSessionCard)]); })]));
  Widget _buildSessionCard(UagSession session) { final color = session.type == 'trade' ? AppTheme.neonCyan : AppTheme.neonPink; return Container(margin: const EdgeInsets.only(bottom: AppTheme.spaceM), padding: const EdgeInsets.all(AppTheme.spaceM), decoration: AppTheme.tradingCardDecoration(borderColor: color.withValues(alpha: 0.35)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(session.type == 'trade' ? Icons.swap_horiz_rounded : Icons.groups_rounded, color: color), const SizedBox(width: AppTheme.spaceS), Expanded(child: Text('${session.type.toUpperCase()} • ${session.status}', style: AppTheme.tradingHeading(fontSize: 16, color: color)))]), const SizedBox(height: AppTheme.spaceS), Text('${session.scheduledAt}', style: AppTheme.bodyTextStyle(fontSize: 13, color: Colors.white70)), const SizedBox(height: AppTheme.spaceM), EmbarkIdCard(label: session.participantTwoDisplayName, embarkId: session.participantTwoEmbarkId), if (session.notes?.isNotEmpty == true) ...[const SizedBox(height: AppTheme.spaceS), Text(session.notes!, style: AppTheme.bodyTextStyle(fontSize: 13, color: Colors.white))], const SizedBox(height: AppTheme.spaceM), Wrap(spacing: AppTheme.spaceS, runSpacing: AppTheme.spaceS, children: [OutlinedButton.icon(onPressed: () => _repository.toggleReady(session), icon: const Icon(Icons.check_circle_outline_rounded), label: const Text('Ready')), OutlinedButton.icon(onPressed: () => _repository.markComplete(session), icon: const Icon(Icons.done_all_rounded), label: const Text('Complete')), OutlinedButton.icon(onPressed: () => _repository.markNoShow(session), icon: const Icon(Icons.report_gmailerrorred_rounded), label: const Text('No-show')), OutlinedButton.icon(onPressed: () => _addToCalendar(session), icon: const Icon(Icons.event_rounded), label: const Text('Calendar')), OutlinedButton.icon(onPressed: () => _share(session), icon: const Icon(Icons.ios_share_rounded), label: const Text('Share'))]) ])); }
}
'''
RULES_SNIPPET = '''
// UAG Session Planner
match /uag_sessions/{sessionId} {
  allow read: if request.auth != null && (resource.data.participantOneUid == request.auth.uid || resource.data.participantTwoUid == request.auth.uid);
  allow create: if request.auth != null && request.resource.data.createdBy == request.auth.uid && (request.resource.data.participantOneUid == request.auth.uid || request.resource.data.participantTwoUid == request.auth.uid);
  allow update: if request.auth != null && (resource.data.participantOneUid == request.auth.uid || resource.data.participantTwoUid == request.auth.uid);
}
'''

def patch_firestore_rules():
    path = ROOT/'firestore.rules'
    if not path.exists(): print('SKIP firestore.rules not found'); return
    text = path.read_text(encoding='utf-8')
    if 'match /uag_sessions/{sessionId}' in text: print('SKIP firestore.rules sessions already present'); return
    marker = 'match /databases/{database}/documents {'
    if marker in text:
        text = text.replace(marker, marker + '\n' + RULES_SNIPPET, 1)
        path.write_text(text, encoding='utf-8')
        print('PATCH firestore.rules')
    else: print('SKIP firestore.rules marker not found')

def patch_indexes():
    path = ROOT/'firestore.indexes.json'
    if not path.exists(): print('SKIP firestore.indexes.json not found'); return
    data=json.loads(path.read_text(encoding='utf-8'))
    indexes=data.setdefault('indexes', [])
    def exists(field):
        return any(idx.get('collectionGroup')=='uag_sessions' and idx.get('fields', [{}])[0].get('fieldPath')==field for idx in indexes)
    for field in ['participantOneUid','participantTwoUid']:
        if not exists(field):
            indexes.append({'collectionGroup':'uag_sessions','queryScope':'COLLECTION','fields':[{'fieldPath':field,'order':'ASCENDING'},{'fieldPath':'scheduledAt','order':'ASCENDING'}]})
            print(f'ADD firestore index {field}+scheduledAt')
    path.write_text(json.dumps(data, indent=2), encoding='utf-8')

def write_dart_files():
    write(VOICE_DIR/'voice_intent.dart', VOICE_INTENT)
    write(VOICE_DIR/'voice_intent_parser.dart', VOICE_PARSER)
    write(VOICE_DIR/'voice_response_builder.dart', VOICE_RESPONSE)
    write(VOICE_DIR/'voice_assistant_service.dart', VOICE_SERVICE)
    write(VOICE_DIR/'voice_assistant_sheet.dart', VOICE_SHEET)
    write(SESSION_DIR/'session_model.dart', SESSION_MODEL)
    write(SESSION_DIR/'session_repository.dart', SESSION_REPO)
    write(SESSION_DIR/'session_creation_sheet.dart', SESSION_CREATION)
    write(SESSION_DIR/'embark_id_card.dart', EMBARK_CARD)
    write(SESSION_DIR/'session_planner_screen.dart', SESSION_SCREEN)

def main():
    if not (ROOT/'pubspec.yaml').exists(): raise RuntimeError('Run this from your Flutter project root: C:\\Users\\mikem\\uag_traders_hub')
    patch_pubspec(); patch_analysis_options(); generate_unified_index(); write_dart_files(); patch_main(); patch_firestore_rules(); patch_indexes()
    print('\nDONE voice + session planner patch. Run flutter clean, flutter pub get, flutter analyze.')
if __name__ == '__main__': main()
