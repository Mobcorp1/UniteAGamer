import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_subscription_tier.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/services/uag_entitlement_service.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/voice/voice_intent_parser.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/voice/voice_pronunciation.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/voice/voice_profiles.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/voice/voice_response_builder.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class UagVoiceArcAssistantService extends ChangeNotifier {
  UagVoiceArcAssistantService({
    stt.SpeechToText? speech,
    FlutterTts? tts,
    ArcBlueprintRepository? blueprintRepository,
    UagEntitlementService? entitlementService,
  }) : _speech = speech ?? stt.SpeechToText(),
       _tts = tts ?? FlutterTts(),
       _blueprintRepository = blueprintRepository ?? ArcBlueprintRepository(),
       _entitlementService = entitlementService ?? UagEntitlementService();

  static const String _voicePreferenceKey = 'uag_voice_assistant_profile_id';
  static const String _companionModePreferenceKey =
      'uag_voice_raid_companion_mode';
  static const String _handsFreePreferenceKey = 'uag_voice_hands_free_enabled';
  static const String _handsFreePromptedKey = 'uag_voice_hands_free_prompted';

  final stt.SpeechToText _speech;
  final FlutterTts _tts;
  final ArcBlueprintRepository _blueprintRepository;
  final UagEntitlementService _entitlementService;
  final UagVoiceIntentParser _parser = const UagVoiceIntentParser();
  final UagVoiceResponseBuilder _responseBuilder =
      const UagVoiceResponseBuilder();

  bool _available = false;
  bool _initialised = false;
  bool _initialising = false;
  bool _listening = false;
  bool _speaking = false;
  bool _speakingPreview = false;
  bool _adminBypass = false;
  bool _raidCompanionMode = false;
  bool _handsFreeEnabled = false;
  bool _handsFreePrompted = false;
  bool _awaitingHandsFreeConsent = false;
  bool _handsFreeOfferShownThisSession = false;
  bool _wakeCommandMode = false;
  bool _listenAfterSpeech = false;

  Timer? _wakeCommandTimer;
  Timer? _handsFreeWakeRearmTimer;
  bool _handsFreeWakeRearmQueued = false;

  UagSubscriptionTier _tier = UagSubscriptionTier.free;
  String _transcript = '';
  String? _lastError;
  UagVoiceResponse? _lastResponse;
  String? _pendingSuggestionName;
  _VoiceIntelReportDraft? _pendingIntelReport;

  Map<String, ArcBlueprintState> _blueprintStates = const {};
  List<UagResolvedVoiceProfile> _voiceProfiles = const [];
  UagResolvedVoiceProfile? _selectedVoice;

  StreamSubscription<Map<String, ArcBlueprintState>>? _blueprintSubscription;
  StreamSubscription<dynamic>? _entitlementSubscription;

  bool get available => _available;
  bool get initialised => _initialised;
  bool get initialising => _initialising;
  bool get listening => _listening;
  bool get speaking => _speaking;
  bool get thinking => _initialising;
  bool get speakingPreview => _speakingPreview;
  bool get adminBypass => _adminBypass;
  bool get raidCompanionMode => _raidCompanionMode;
  bool get handsFreeEnabled => _handsFreeEnabled;
  bool get handsFreePrompted => _handsFreePrompted;
  UagSubscriptionTier get tier => _tier;
  String get transcript => _transcript;
  String? get lastError => _lastError;
  UagVoiceResponse? get lastResponse => _lastResponse;
  String? get pendingSuggestionName => _pendingSuggestionName;
  Map<String, ArcBlueprintState> get blueprintStates =>
      Map.unmodifiable(_blueprintStates);
  List<UagResolvedVoiceProfile> get voiceProfiles =>
      List.unmodifiable(_voiceProfiles);
  UagResolvedVoiceProfile? get selectedVoice => _selectedVoice;

  Future<void> initialize() async {
    if (_initialised || _initialising) {
      return;
    }

    _initialising = true;
    _lastError = null;
    notifyListeners();

    try {
      _startBlueprintStateListener();
      _startEntitlementListener();
      await _loadCompanionModePreference();

      _available = await _speech.initialize(
        onError: (error) {
          final errorMessage = error.errorMsg.toLowerCase();
          _listening = false;

          if (errorMessage.contains('no_match') ||
              errorMessage.contains('speech_timeout')) {
            _lastError = null;
          } else {
            _lastError = error.errorMsg;
          }

          debugPrint('UAG voice error: $error');
          notifyListeners();
        },
        onStatus: (status) {
          debugPrint('UAG voice status: $status');

          if (status == 'done' || status == 'notListening') {
            _listening = false;
            notifyListeners();
          }
        },
      );

      await _tts.setVolume(1.0);
      _tts.setStartHandler(() {
        _speaking = true;
        notifyListeners();
      });
      _tts.setCompletionHandler(() {
        _speaking = false;
        notifyListeners();

        if (_listenAfterSpeech) {
          _listenAfterSpeech = false;

          Future<void>.delayed(const Duration(milliseconds: 250), () {
            if (_raidCompanionMode && !_listening && !_speaking) {
              unawaited(startListening());
            }
          });
        }
      });
      _tts.setCancelHandler(() {
        _speaking = false;
        notifyListeners();
      });

      await _loadVoiceProfiles();

      if (!_available) {
        _lastError =
            'Microphone permission is blocked or speech recognition is not available on this device/browser.';
      }
    } catch (error) {
      _available = false;
      _lastError = 'Voice assistant could not start: $error';
      debugPrint('UAG voice initialise failed: $error');
    } finally {
      _initialised = true;
      _initialising = false;
      notifyListeners();
    }
  }

  Future<void> startRaidHandsFreeSetup() async {
    if (!_initialised) {
      await initialize();
    }

    if (!_available) {
      _lastError ??=
          'Microphone permission is blocked or speech recognition is not available.';
      notifyListeners();
      return;
    }

    try {
      if (_listening) {
        await _speech.stop();
      }

      if (_speaking) {
        await _tts.stop();
      }
    } catch (error) {
      debugPrint('UAG voice raid setup reset failed: $error');
    }

    _listening = false;
    _speaking = false;
    _transcript = '';
    _lastError = null;
    _pendingSuggestionName = null;
    _pendingIntelReport = null;
    _wakeCommandMode = false;
    _awaitingHandsFreeConsent = true;
    _handsFreeOfferShownThisSession = true;
    _handsFreePrompted = true;
    _raidCompanionMode = true;

    try {
      await WakelockPlus.enable();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_handsFreePromptedKey, true);
      await prefs.setBool(_companionModePreferenceKey, true);
    } catch (error) {
      debugPrint('UAG voice raid setup preference failed: $error');
    }

    _lastResponse = const UagVoiceResponse(
      title: 'Hands-free raid mode',
      body:
          'Do you want to activate hands-free mode for your raid? Say yes and I will listen for Hey Raider while this assistant is open.',
      spokenBody:
          'Do you want to activate hands-free mode for your raid? Say yes, and I will listen for Hey Raider while this assistant is open.',
      shouldSpeak: true,
    );

    _listenAfterSpeech = true;
    unawaited(speak(_lastResponse!.spokenBody ?? _lastResponse!.body));
    notifyListeners();
  }

  Future<void> startListening() async {
    _handsFreeWakeRearmQueued = false;
    _handsFreeWakeRearmTimer?.cancel();
    if (!_initialised) {
      await initialize();
    }

    if (!_available) {
      _lastError ??=
          'Microphone permission is blocked or speech recognition is not available.';
      notifyListeners();
      return;
    }

    if (_listening) {
      return;
    }

    if (!_handsFreeEnabled &&
        !_awaitingHandsFreeConsent &&
        !_handsFreeOfferShownThisSession) {
      await _offerHandsFreeMode();
      return;
    }

    if (_speaking) {
      await _tts.stop();
      _speaking = false;
    }

    _transcript = '';
    _lastError = null;
    _lastResponse = null;
    _listening = true;
    notifyListeners();

    try {
      await _speech.listen(
        onResult: (result) {
          _transcript = result.recognizedWords;

          if (result.finalResult) {
            _listening = false;
            final handled = _handleTranscript(_transcript);
            notifyListeners();

            if (!handled) {
              _queueHandsFreeWakeRearm();
            }
          } else {
            notifyListeners();
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenFor:
              _handsFreeEnabled &&
                  !_wakeCommandMode &&
                  _pendingIntelReport == null
              ? const Duration(seconds: 45)
              : const Duration(seconds: 24),
          pauseFor:
              _handsFreeEnabled &&
                  !_wakeCommandMode &&
                  _pendingIntelReport == null
              ? const Duration(seconds: 5)
              : const Duration(seconds: 4),
          localeId: 'en_GB',
          listenMode:
              _handsFreeEnabled &&
                  !_wakeCommandMode &&
                  _pendingIntelReport == null
              ? stt.ListenMode.dictation
              : stt.ListenMode.confirmation,
        ),
      );
    } catch (error) {
      _listening = false;
      _lastError = 'Could not start microphone: $error';
      debugPrint('UAG voice listen failed: $error');
      notifyListeners();
    }
  }

  Future<void> stopListening() async {
    try {
      await _speech.stop();
    } catch (error) {
      debugPrint('UAG voice stop failed: $error');
    }

    _listening = false;

    if (_transcript.trim().isNotEmpty) {
      _handleTranscript(_transcript);
    }

    notifyListeners();
  }

  Future<void> stopSpeakingForUser() async {
    try {
      await _tts.stop();
    } catch (error) {
      debugPrint('UAG voice stop speaking failed: $error');
    }

    _speaking = false;
    _lastError = null;
    notifyListeners();

    if (_raidCompanionMode) {
      await startListening();
    }
  }

  Future<void> setRaidCompanionMode(bool enabled) async {
    _raidCompanionMode = enabled;
    _lastError = null;
    notifyListeners();

    try {
      await WakelockPlus.toggle(enable: enabled);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_companionModePreferenceKey, enabled);

      if (!enabled) {
        if (_listening) {
          await _speech.stop();
        }

        _clearWakeCommandMode();
        _listenAfterSpeech = false;
        _handsFreeEnabled = false;
        _awaitingHandsFreeConsent = false;
        _listening = false;
      }
    } catch (error) {
      _raidCompanionMode = false;
      _lastError =
          'Could not ${enabled ? 'enable' : 'disable'} Raid Companion Mode: $error';
      notifyListeners();
    }
  }

  Future<void> selectVoice(UagResolvedVoiceProfile voice) async {
    if (!voice.profile.isUnlockedFor(_tier, adminBypass: _adminBypass)) {
      _lastError =
          '${voice.displayName} is part of ${voice.tierLabel}. Upgrade to select this voice.';
      notifyListeners();
      return;
    }

    _selectedVoice = voice;
    await _applyVoice(voice);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_voicePreferenceKey, voice.id);

    _lastError = null;
    notifyListeners();
  }

  Future<void> previewVoice(UagResolvedVoiceProfile voice) async {
    _speakingPreview = true;
    _lastError = null;
    notifyListeners();

    try {
      await _tts.stop();
      await _applyVoice(voice);
      await _tts.speak(
        UagVoicePronunciation.improveSpeech(voice.profile.previewText),
      );

      if (_selectedVoice != null) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        await _applyVoice(_selectedVoice!);
      }
    } catch (error) {
      _lastError = 'Could not preview ${voice.displayName}: $error';
    } finally {
      _speakingPreview = false;
      notifyListeners();
    }
  }

  Future<void> speak(String text) async {
    await _tts.stop();

    final selected = _selectedVoice;
    if (selected != null) {
      await _applyVoice(selected);
    }

    final prefix = selected?.profile.personalityPrefix ?? '';
    final spokenText = UagVoicePronunciation.improveSpeech('$prefix$text');

    _speaking = true;
    notifyListeners();

    await _tts.speak(spokenText);
  }

  void submitText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }

    _transcript = trimmed;
    _lastError = null;
    _handleTranscript(trimmed);
    notifyListeners();
  }

  void confirmSuggestedItem() {
    final suggestion = _pendingSuggestionName;
    if (suggestion == null || suggestion.trim().isEmpty) {
      return;
    }

    final response = _responseBuilder.buildConfirmedSuggestion(
      suggestion,
      blueprintStates: _blueprintStates,
    );

    _pendingSuggestionName = null;
    _lastResponse = response;
    _transcript = suggestion;

    if (response.shouldSpeak) {
      unawaited(speak(response.spokenBody ?? response.body));
    }

    notifyListeners();
  }

  Future<void> _offerHandsFreeMode() async {
    _handsFreeOfferShownThisSession = true;
    _awaitingHandsFreeConsent = true;
    _handsFreePrompted = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_handsFreePromptedKey, true);

    _lastResponse = const UagVoiceResponse(
      title: 'Hands-free raid mode',
      body:
          'Do you want to activate hands-free mode for your raid? Say yes and I will listen for Hey Raider while this assistant is open.',
      spokenBody:
          'Do you want to activate hands-free mode for your raid? Say yes, and I will listen for Hey Raider while this assistant is open.',
      shouldSpeak: true,
    );

    _listenAfterSpeech = true;
    unawaited(speak(_lastResponse!.spokenBody ?? _lastResponse!.body));
    notifyListeners();
  }

  Future<void> _setHandsFreeEnabled(bool enabled) async {
    _handsFreeWakeRearmTimer?.cancel();
    _handsFreeWakeRearmQueued = false;
    _handsFreeEnabled = enabled;
    _awaitingHandsFreeConsent = false;
    _raidCompanionMode = enabled;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_handsFreePreferenceKey, enabled);
    await prefs.setBool(_companionModePreferenceKey, enabled);
    await WakelockPlus.toggle(enable: enabled);
  }

  Future<void> _loadCompanionModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _handsFreePrompted = prefs.getBool(_handsFreePromptedKey) ?? false;
    _handsFreeEnabled = prefs.getBool(_handsFreePreferenceKey) ?? false;
    final enabled =
        (prefs.getBool(_companionModePreferenceKey) ?? false) ||
        _handsFreeEnabled;
    _raidCompanionMode = enabled;

    if (enabled) {
      await WakelockPlus.enable();
    }
  }

  Future<void> _loadVoiceProfiles() async {
    final rawVoices = await _tts.getVoices;
    _voiceProfiles = resolveUagVoiceProfiles(rawVoices);

    if (_voiceProfiles.isEmpty) {
      _lastError =
          'No English text-to-speech voices were found on this device/browser.';
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final savedProfileId = prefs.getString(_voicePreferenceKey);

    UagResolvedVoiceProfile preferred;
    try {
      preferred = _voiceProfiles.firstWhere(
        (voice) => voice.id == savedProfileId,
      );
    } catch (_) {
      preferred = _voiceProfiles.firstWhere(
        (voice) =>
            voice.profile.isUnlockedFor(_tier, adminBypass: _adminBypass),
        orElse: () => _voiceProfiles.first,
      );
    }

    if (!preferred.profile.isUnlockedFor(_tier, adminBypass: _adminBypass)) {
      preferred = _voiceProfiles.firstWhere(
        (voice) =>
            voice.profile.isUnlockedFor(_tier, adminBypass: _adminBypass),
        orElse: () => _voiceProfiles.first,
      );
    }

    _selectedVoice = preferred;
    await _applyVoice(preferred);
  }

  Future<void> _applyVoice(UagResolvedVoiceProfile voice) async {
    await _tts.setVoice(voice.ttsVoice);
    await _tts.setSpeechRate(voice.profile.rate);
    await _tts.setPitch(voice.profile.pitch);
    await _tts.setVolume(1.0);
  }

  String _normaliseWakeText(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9 ]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _hasWakePhrase(String value) {
    final text = _normaliseWakeText(value);

    const wakePhrases = <String>[
      'hey raider',
      'hay raider',
      'hay radar',
      'hay reader',
      'hay rider',
      'hay rader',
      'hay rayder',
      'hey radar',
      'hey reader',
      'hey rider',
      'hey rader',
      'hey rayder',
      'okay raider',
      'okay radar',
      'okay reader',
      'ok raider',
      'ok radar',
      'ok reader',
      'arc raider',
      'arc radar',
      'arc reader',
      'ark raider',
      'ark radar',
      'ark reader',
      'hey arc',
      'okay arc',
      'ok arc',
      'arc assistant',
      'uag raider',
      'uag radar',
      'uag reader',
    ];

    if (wakePhrases.any(text.contains)) {
      return true;
    }

    return text == 'raider' ||
        text == 'radar' ||
        text == 'reader' ||
        text == 'rider' ||
        text == 'rader' ||
        text.startsWith('raider ') ||
        text.startsWith('radar ') ||
        text.startsWith('hay raider ') ||
        text.startsWith('hay radar ') ||
        text.startsWith('hay reader ') ||
        text.startsWith('reader ') ||
        text.startsWith('rider ') ||
        text.startsWith('rader ');
  }

  String _stripWakePhrase(String value) {
    var text = value;

    final patterns = <RegExp>[
      RegExp(r'\bhey\s+raider\b', caseSensitive: false),
      RegExp(r'\bhay\s+raider\b', caseSensitive: false),
      RegExp(r'\bhay\s+radar\b', caseSensitive: false),
      RegExp(r'\bhay\s+reader\b', caseSensitive: false),
      RegExp(r'\bhay\s+rider\b', caseSensitive: false),
      RegExp(r'\bhay\s+rader\b', caseSensitive: false),
      RegExp(r'\bhay\s+rayder\b', caseSensitive: false),
      RegExp(r'\bhey\s+radar\b', caseSensitive: false),
      RegExp(r'\bhey\s+reader\b', caseSensitive: false),
      RegExp(r'\bhey\s+rider\b', caseSensitive: false),
      RegExp(r'\bhey\s+rader\b', caseSensitive: false),
      RegExp(r'\bhey\s+rayder\b', caseSensitive: false),
      RegExp(r'\bokay\s+raider\b', caseSensitive: false),
      RegExp(r'\bokay\s+radar\b', caseSensitive: false),
      RegExp(r'\bokay\s+reader\b', caseSensitive: false),
      RegExp(r'\barc\s+raider\b', caseSensitive: false),
      RegExp(r'\barc\s+radar\b', caseSensitive: false),
      RegExp(r'\barc\s+reader\b', caseSensitive: false),
      RegExp(r'\bark\s+raider\b', caseSensitive: false),
      RegExp(r'\bark\s+radar\b', caseSensitive: false),
      RegExp(r'\bark\s+reader\b', caseSensitive: false),
      RegExp(r'\bok\s+raider\b', caseSensitive: false),
      RegExp(r'\bok\s+radar\b', caseSensitive: false),
      RegExp(r'\bok\s+reader\b', caseSensitive: false),
      RegExp(r'\bhey\s+arc\b', caseSensitive: false),
      RegExp(r'\bokay\s+arc\b', caseSensitive: false),
      RegExp(r'\bok\s+arc\b', caseSensitive: false),
      RegExp(r'\barc\s+assistant\b', caseSensitive: false),
      RegExp(r'\buag\s+raider\b', caseSensitive: false),
      RegExp(r'\buag\s+radar\b', caseSensitive: false),
      RegExp(r'\buag\s+reader\b', caseSensitive: false),
      RegExp(r'\braider\b', caseSensitive: false),
      RegExp(r'\bradar\b', caseSensitive: false),
      RegExp(r'\breader\b', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      text = text.replaceAll(pattern, ' ');
    }

    return text
        .replaceAll(RegExp(r'[,.:;!?]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  void _armWakeCommandMode() {
    _wakeCommandMode = true;
    _wakeCommandTimer?.cancel();
    _wakeCommandTimer = Timer(const Duration(seconds: 12), () {
      _wakeCommandMode = false;
      notifyListeners();
    });
  }

  void _clearWakeCommandMode() {
    _wakeCommandMode = false;
    _wakeCommandTimer?.cancel();
    _wakeCommandTimer = null;
  }

  bool _handleWakePhraseOnly() {
    _armWakeCommandMode();
    _listenAfterSpeech = true;
    _lastResponse = const UagVoiceResponse(
      title: 'ARC listening',
      body: 'Listening. Ask your command.',
      spokenBody: 'Listening.',
      shouldSpeak: true,
    );

    unawaited(speak(_lastResponse!.spokenBody ?? _lastResponse!.body));
    notifyListeners();
    return true;
  }

  bool _handleTranscript(String text) {
    var commandText = text.trim();

    if (_awaitingHandsFreeConsent) {
      final accepted = _isAffirmative(commandText);
      final declined = _isNegative(commandText);

      if (accepted || declined) {
        unawaited(_setHandsFreeEnabled(accepted));

        _lastResponse = UagVoiceResponse(
          title: accepted ? 'Hands-free enabled' : 'Hands-free skipped',
          body: accepted
              ? 'Done. Say Hey Raider when you need me during raids.'
              : 'No problem. Tap the mic when you need me.',
          spokenBody: accepted
              ? 'Done. Say Hey Raider when you need me during raids.'
              : 'No problem. Tap the mic when you need me.',
          shouldSpeak: true,
        );

        _listenAfterSpeech = accepted;
        unawaited(speak(_lastResponse!.spokenBody ?? _lastResponse!.body));
        notifyListeners();
        return true;
      }

      _lastResponse = const UagVoiceResponse(
        title: 'Hands-free raid mode',
        body: 'Say yes to enable hands-free mode, or no to keep tap-to-talk.',
        spokenBody:
            'Say yes to enable hands-free mode, or no to keep tap to talk.',
        shouldSpeak: true,
      );
      _listenAfterSpeech = true;
      unawaited(speak(_lastResponse!.spokenBody ?? _lastResponse!.body));
      notifyListeners();
      return true;
    }

    if (_raidCompanionMode || _handsFreeEnabled) {
      final hasWakePhrase = _hasWakePhrase(commandText);

      if (hasWakePhrase) {
        commandText = _stripWakePhrase(commandText);

        if (commandText.isEmpty) {
          return _handleWakePhraseOnly();
        }

        _clearWakeCommandMode();
      } else if (_wakeCommandMode) {
        _clearWakeCommandMode();
      } else if (_pendingIntelReport == null) {
        return false;
      }
    }

    if (_handleIntelReportTranscript(commandText)) {
      return true;
    }

    if (_isAffirmative(commandText) && _pendingSuggestionName != null) {
      confirmSuggestedItem();
      return true;
    }

    final intent = _parser.parse(commandText);
    final response = _responseBuilder.build(
      intent,
      blueprintStates: _blueprintStates,
    );

    _pendingSuggestionName = response.suggestedItemName;
    _lastResponse = response;

    if (response.shouldSpeak) {
      unawaited(speak(response.spokenBody ?? response.body));
      return true;
    }

    return false;
  }

  bool _handleIntelReportTranscript(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return false;
    }

    final activeDraft = _pendingIntelReport;

    if (activeDraft != null) {
      final lower = trimmed.toLowerCase();

      if (lower.contains('cancel report') ||
          lower.contains('stop report') ||
          lower == 'cancel' ||
          lower == 'stop') {
        _pendingIntelReport = null;
        _pendingSuggestionName = null;
        _lastResponse = const UagVoiceResponse(
          title: 'Intel report cancelled',
          body: 'Intel report cancelled. No report was saved.',
          spokenBody: 'Intel report cancelled. No report was saved.',
          shouldSpeak: true,
        );

        unawaited(speak(_lastResponse!.spokenBody ?? _lastResponse!.body));
        notifyListeners();
        return true;
      }

      if (lower.contains('start over') || lower.contains('restart report')) {
        activeDraft.reset();
        _lastResponse = activeDraft.startResponse();

        unawaited(speak(_lastResponse!.spokenBody ?? _lastResponse!.body));
        notifyListeners();
        return true;
      }

      if (lower == 'repeat' ||
          lower.contains('repeat question') ||
          lower.contains('say that again')) {
        _lastResponse = activeDraft.currentPromptResponse();

        unawaited(speak(_lastResponse!.spokenBody ?? _lastResponse!.body));
        notifyListeners();
        return true;
      }

      if (lower.contains('summary') ||
          lower.contains('read it back') ||
          lower.contains('what have you got')) {
        _lastResponse = activeDraft.summaryResponse();

        unawaited(speak(_lastResponse!.spokenBody ?? _lastResponse!.body));
        notifyListeners();
        return true;
      }

      final completed = activeDraft.answer(trimmed);
      final response = completed
          ? activeDraft.completedResponse()
          : activeDraft.nextPromptResponse();

      _lastResponse = response;
      _pendingSuggestionName = null;

      if (completed) {
        _pendingIntelReport = null;
      }

      if (response.shouldSpeak) {
        unawaited(speak(response.spokenBody ?? response.body));
      }

      notifyListeners();
      return response.shouldSpeak;
    }

    final blueprint = _resolveFoundBlueprint(trimmed);

    if (blueprint == null) {
      return false;
    }

    final draft = _VoiceIntelReportDraft(blueprintName: blueprint.name)
      ..prefillFromSpeech(trimmed);
    _pendingIntelReport = draft;
    _pendingSuggestionName = null;
    _lastResponse = draft.startResponse();

    unawaited(speak(_lastResponse!.spokenBody ?? _lastResponse!.body));
    notifyListeners();

    return true;
  }

  ArcBlueprint? _resolveFoundBlueprint(String text) {
    final normalized = text.toLowerCase();

    final looksLikeReport =
        normalized.contains('i found') ||
        normalized.contains('just found') ||
        normalized.contains('found a') ||
        normalized.contains('found the') ||
        normalized.startsWith('found ') ||
        normalized.contains('report ') ||
        normalized.contains('add intel') ||
        normalized.contains('log intel') ||
        normalized.contains('create intel') ||
        normalized.contains('intel on') ||
        normalized.contains('intel for') ||
        normalized.contains('dupe blueprint') ||
        normalized.contains('duplicate blueprint') ||
        normalized.contains('blueprint on') ||
        normalized.contains('blueprint in');

    if (!looksLikeReport) {
      return null;
    }

    var bestScore = 0;
    ArcBlueprint? best;

    for (final blueprint in ArcBlueprintSeedData.blueprints) {
      final name = blueprint.name.toLowerCase();
      final compactName = name.replaceAll(RegExp(r'[^a-z0-9]+'), ' ');
      final query = normalized.replaceAll(RegExp(r'[^a-z0-9]+'), ' ');

      var score = 0;

      if (query.contains(name)) {
        score = 100;
      } else if (query.contains(compactName)) {
        score = 96;
      } else {
        final nameTokens = compactName
            .split(' ')
            .where((token) => token.trim().isNotEmpty)
            .toSet();
        final queryTokens = query
            .split(' ')
            .where((token) => token.trim().isNotEmpty)
            .toSet();

        score = nameTokens.intersection(queryTokens).length * 20;
      }

      if (score > bestScore) {
        bestScore = score;
        best = blueprint;
      }
    }

    return bestScore >= 20 ? best : null;
  }

  bool _isAffirmative(String text) {
    final normalized = text.toLowerCase().trim();

    return normalized == 'yes' ||
        normalized == 'yeah' ||
        normalized == 'yep' ||
        normalized == 'confirm' ||
        normalized == 'correct' ||
        normalized == 'that one' ||
        normalized == 'open it' ||
        normalized == 'show me' ||
        normalized.contains('turn it on') ||
        normalized.contains('enable') ||
        normalized.contains('do it');
  }

  bool _isNegative(String text) {
    final normalized = text.toLowerCase().trim();

    return normalized == 'no' ||
        normalized == 'nope' ||
        normalized == 'not now' ||
        normalized.contains('leave it') ||
        normalized.contains('skip');
  }

  void _startBlueprintStateListener() {
    _blueprintSubscription ??= _blueprintRepository
        .watchMyBlueprintStates()
        .listen(
          (states) {
            _blueprintStates = states;
            notifyListeners();
          },
          onError: (error) {
            debugPrint('UAG voice blueprint state listener failed: $error');
          },
        );
  }

  void _startEntitlementListener() {
    _entitlementSubscription ??= _entitlementService
        .watchMyEntitlement()
        .listen(
          (entitlement) {
            _tier = entitlement.tier;
            _adminBypass = entitlement.hasAdminBypass;

            final selected = _selectedVoice;
            if (selected != null &&
                !selected.profile.isUnlockedFor(
                  _tier,
                  adminBypass: _adminBypass,
                )) {
              final fallback = _voiceProfiles
                  .where(
                    (voice) => voice.profile.isUnlockedFor(
                      _tier,
                      adminBypass: _adminBypass,
                    ),
                  )
                  .toList(growable: false);

              if (fallback.isNotEmpty) {
                _selectedVoice = fallback.first;
                unawaited(_applyVoice(_selectedVoice!));
              }
            }

            notifyListeners();
          },
          onError: (error) {
            debugPrint('UAG voice entitlement listener failed: $error');
            _tier = UagSubscriptionTier.free;
            _adminBypass = false;
            notifyListeners();
          },
        );
  }

  void _queueHandsFreeWakeRearm({
    Duration delay = const Duration(milliseconds: 900),
  }) {
    if (!_handsFreeEnabled ||
        !_raidCompanionMode ||
        _awaitingHandsFreeConsent ||
        _wakeCommandMode ||
        _pendingIntelReport != null ||
        _listening ||
        _speaking ||
        _handsFreeWakeRearmQueued) {
      return;
    }

    _handsFreeWakeRearmQueued = true;
    _handsFreeWakeRearmTimer?.cancel();
    _handsFreeWakeRearmTimer = Timer(delay, () {
      _handsFreeWakeRearmQueued = false;

      if (!_handsFreeEnabled ||
          !_raidCompanionMode ||
          _awaitingHandsFreeConsent ||
          _wakeCommandMode ||
          _pendingIntelReport != null ||
          _listening ||
          _speaking) {
        return;
      }

      unawaited(startListening());
    });
  }

  @override
  void dispose() {
    _wakeCommandTimer?.cancel();
    _blueprintSubscription?.cancel();
    _entitlementSubscription?.cancel();
    WakelockPlus.disable();
    _speech.cancel();
    _tts.stop();
    super.dispose();
  }
}

enum _VoiceIntelReportStep {
  map,
  area,
  source,
  raidRound,
  condition,
  raiderTimeOfDay,
  notes,
  complete,
}

class _VoiceIntelReportDraft {
  _VoiceIntelReportDraft({required this.blueprintName});

  final String blueprintName;
  _VoiceIntelReportStep step = _VoiceIntelReportStep.map;

  String? map;
  String? area;
  String? source;
  String? raidRound;
  String? condition;
  String? raiderTimeOfDay;
  String? notes;

  bool answer(String value) {
    final cleaned = _cleanAnswer(value);

    switch (step) {
      case _VoiceIntelReportStep.map:
        map = cleaned;
        step = _VoiceIntelReportStep.area;
        return false;
      case _VoiceIntelReportStep.area:
        area = cleaned;
        step = _VoiceIntelReportStep.source;
        return false;
      case _VoiceIntelReportStep.source:
        source = cleaned;
        step = _VoiceIntelReportStep.raidRound;
        return false;
      case _VoiceIntelReportStep.raidRound:
        raidRound = _normaliseRaidRound(cleaned);
        step = _VoiceIntelReportStep.condition;
        return false;
      case _VoiceIntelReportStep.condition:
        condition = cleaned;
        step = _VoiceIntelReportStep.raiderTimeOfDay;
        return false;
      case _VoiceIntelReportStep.raiderTimeOfDay:
        raiderTimeOfDay = _normaliseRaiderTimeOfDay(cleaned);
        step = _VoiceIntelReportStep.notes;
        return false;
      case _VoiceIntelReportStep.notes:
        notes =
            cleaned.toLowerCase() == 'no notes' ||
                cleaned.toLowerCase() == 'skip'
            ? ''
            : cleaned;
        step = _VoiceIntelReportStep.complete;
        return true;
      case _VoiceIntelReportStep.complete:
        return true;
    }
  }

  UagVoiceResponse startResponse() {
    return UagVoiceResponse(
      title: 'Intel report started',
      body:
          'Blueprint: $blueprintName\n\nQuestion 1 of 7: Which map did you find it on?',
      spokenBody:
          'Intel report started for $blueprintName. Which map did you find it on?',
      shouldSpeak: true,
    );
  }

  UagVoiceResponse nextPromptResponse() {
    switch (step) {
      case _VoiceIntelReportStep.area:
        return UagVoiceResponse(
          title: 'Intel report - Area',
          body:
              'Blueprint: $blueprintName\nMap: $map\n\nQuestion 2 of 7: Which area or POI?',
          spokenBody: 'Got it. Which area or P O I?',
          shouldSpeak: true,
        );
      case _VoiceIntelReportStep.source:
        return UagVoiceResponse(
          title: 'Intel report - How obtained',
          body:
              'Blueprint: $blueprintName\nMap: $map\nArea: $area\n\nQuestion 3 of 7: How was it obtained? For example loot drop, quest reward, trial reward, trading, raider cache, weapon crate, locked room, or enemy.',
          spokenBody:
              'How was it obtained? For example, loot drop, quest reward, trial reward, trading, raider cache, weapon crate, locked room, or enemy.',
          shouldSpeak: true,
        );
      case _VoiceIntelReportStep.raidRound:
        return UagVoiceResponse(
          title: 'Intel report - Raid round',
          body:
              'Blueprint: $blueprintName\nMap: $map\nArea: $area\nHow obtained: $source\n\nQuestion 4 of 7: Which raid round? Full Raid, Mid Raid, or Late Raid?',
          spokenBody: 'Which raid round? Full raid, mid raid, or late raid?',
          shouldSpeak: true,
        );
      case _VoiceIntelReportStep.condition:
        return UagVoiceResponse(
          title: 'Intel report - Condition',
          body:
              'Blueprint: $blueprintName\nMap: $map\nArea: $area\nHow obtained: $source\nRaid Round: $raidRound\n\nQuestion 5 of 7: What was the condition or event?',
          spokenBody: 'What was the map condition or event?',
          shouldSpeak: true,
        );
      case _VoiceIntelReportStep.raiderTimeOfDay:
        return UagVoiceResponse(
          title: 'Intel report - Raider time',
          body:
              'Blueprint: $blueprintName\nMap: $map\nArea: $area\nHow obtained: $source\nRaid Round: $raidRound\nCondition: $condition\n\nQuestion 6 of 7: What Raider time of day? Early Morning, Mid-Morning, Midday, Mid-Afternoon, Night, or Late Night?',
          spokenBody:
              'What Raider time of day? Early morning, mid morning, midday, mid afternoon, night, or late night?',
          shouldSpeak: true,
        );
      case _VoiceIntelReportStep.notes:
        return UagVoiceResponse(
          title: 'Intel report - Notes',
          body:
              'Blueprint: $blueprintName\nMap: $map\nArea: $area\nHow obtained: $source\nRaid Round: $raidRound\nCondition: $condition\nRaider Time: $raiderTimeOfDay\n\nQuestion 7 of 7: Any notes? Say skip or no notes if not.',
          spokenBody: 'Any notes? Say skip or no notes if not.',
          shouldSpeak: true,
        );
      case _VoiceIntelReportStep.map:
      case _VoiceIntelReportStep.complete:
        return startResponse();
    }
  }

  void reset() {
    step = _VoiceIntelReportStep.map;
    map = null;
    area = null;
    source = null;
    raidRound = null;
    condition = null;
    raiderTimeOfDay = null;
    notes = null;
  }

  UagVoiceResponse currentPromptResponse() {
    if (step == _VoiceIntelReportStep.complete) {
      return completedResponse();
    }

    return step == _VoiceIntelReportStep.map
        ? startResponse()
        : nextPromptResponse();
  }

  UagVoiceResponse summaryResponse() {
    return UagVoiceResponse(
      title: 'Current Intel report summary',
      body:
          'Blueprint: $blueprintName\nMap: ${map ?? 'Not set'}\nArea / POI: ${area ?? 'Not set'}\nHow Obtained: ${source ?? 'Not set'}\nRaid Round: ${raidRound ?? 'Not set'}\nCondition / Event: ${condition ?? 'Not set'}\nRaider Time of Day: ${raiderTimeOfDay ?? 'Not set'}\nNotes: ${notes == null || notes!.trim().isEmpty ? 'None' : notes}',
      spokenBody:
          'Current report. Blueprint, $blueprintName. Map, ${map ?? 'not set'}. Area, ${area ?? 'not set'}. Source, ${source ?? 'not set'}. Raid round, ${raidRound ?? 'not set'}. Condition, ${condition ?? 'not set'}. Raider time, ${raiderTimeOfDay ?? 'not set'}.',
      shouldSpeak: true,
    );
  }

  UagVoiceResponse completedResponse() {
    return UagVoiceResponse(
      title: 'Intel report ready',
      body:
          'Blueprint: $blueprintName\nMap: $map\nArea / POI: $area\nHow Obtained: $source\nRaid Round: $raidRound\nCondition / Event: $condition\nRaider Time of Day: $raiderTimeOfDay\nNotes: ${notes == null || notes!.trim().isEmpty ? 'None' : notes}\n\nOpen the Intel report sheet and save this report using the same details.',
      spokenBody:
          'Intel report ready for $blueprintName. Open the Intel report sheet and save it with these details.',
      shouldSpeak: true,
    );
  }

  void prefillFromSpeech(String rawText) {
    final lower = rawText.toLowerCase();

    final mapAliases = <String, String>{
      'buried city': 'Buried City',
      'beret city': 'Buried City',
      'bird city': 'Buried City',
      'dam battlegrounds': 'Dam Battlegrounds',
      'spaceport': 'Spaceport',
      'blue gate': 'Blue Gate',
      'stella montis': 'Stella Montis',
    };

    for (final entry in mapAliases.entries) {
      if (lower.contains(entry.key)) {
        map ??= entry.value;
      }
    }

    final areaMatch = RegExp(
      r'\b(?:in|at|near) the ([a-z0-9 \-]+?)(?: on | from | during |\.|$)',
    ).firstMatch(lower);
    final areaValue = areaMatch?.group(1)?.trim();
    if (areaValue != null && areaValue.isNotEmpty) {
      area ??= _titleCase(areaValue);
    }

    final sourceAliases = <String, String>{
      'raider cache': 'Raider Cache',
      'weapon crate': 'Weapon Crate',
      'weapon cache': 'Weapon Cache',
      'locker': 'Locker',
      'locked room': 'Locked Room',
      'breach room': 'Breach Room',
      'hidden cache': 'Hidden Cache',
      'quest reward': 'Quest Reward',
      'trial reward': 'Trial Reward',
      'enemy': 'Enemy Drop',
      'assessor': 'Enemy Drop',
      'trade': 'Trade',
    };

    for (final entry in sourceAliases.entries) {
      if (lower.contains(entry.key)) {
        source ??= entry.value;
      }
    }

    if (lower.contains('full raid')) {
      raidRound ??= 'Full Raid';
    } else if (lower.contains('mid raid') || lower.contains('middle raid')) {
      raidRound ??= 'Mid Raid';
    } else if (lower.contains('late raid')) {
      raidRound ??= 'Late Raid';
    }

    final conditionAliases = <String, String>{
      'electromagnetic storm': 'Electromagnetic Storm',
      'em storm': 'Electromagnetic Storm',
      'hurricane': 'Hurricane',
      'close scrutiny': 'Close Scrutiny',
      'hidden bunker': 'Hidden Bunker',
      'lockgate': 'Lockgate',
      'bird city': 'Bird City',
    };

    for (final entry in conditionAliases.entries) {
      if (lower.contains(entry.key)) {
        condition ??= entry.value;
      }
    }

    if (lower.contains('early morning')) {
      raiderTimeOfDay ??= 'Early Morning';
    } else if (lower.contains('mid morning') || lower.contains('mid-morning')) {
      raiderTimeOfDay ??= 'Mid-Morning';
    } else if (lower.contains('midday')) {
      raiderTimeOfDay ??= 'Midday';
    } else if (lower.contains('afternoon')) {
      raiderTimeOfDay ??= 'Mid-Afternoon';
    } else if (lower.contains('late night')) {
      raiderTimeOfDay ??= 'Late Night';
    } else if (lower.contains('night')) {
      raiderTimeOfDay ??= 'Night';
      condition ??= 'Night Raid';
    }
  }

  String _titleCase(String value) {
    return value
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .map((part) {
          final clean = part.trim();
          if (clean.length == 1) {
            return clean.toUpperCase();
          }
          return clean[0].toUpperCase() + clean.substring(1);
        })
        .join(' ');
  }

  String _cleanAnswer(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _normaliseRaidRound(String value) {
    final lower = value.toLowerCase();

    if (lower.contains('mid')) {
      return 'Mid Raid';
    }

    if (lower.contains('late')) {
      return 'Late Raid';
    }

    return 'Full Raid';
  }

  String _normaliseRaiderTimeOfDay(String value) {
    final lower = value.toLowerCase();

    if (lower.contains('early') && lower.contains('morning')) {
      return 'Early Morning';
    }

    if (lower.contains('mid') && lower.contains('morning')) {
      return 'Mid-Morning';
    }

    if (lower.contains('midday') || lower.contains('middle of the day')) {
      return 'Midday';
    }

    if (lower.contains('afternoon')) {
      return 'Mid-Afternoon';
    }

    if (lower.contains('late') && lower.contains('night')) {
      return 'Late Night';
    }

    if (lower.contains('night')) {
      return 'Night';
    }

    return value;
  }
}
