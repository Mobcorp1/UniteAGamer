import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:uag_traders_hub/features/monetisation/models/uag_subscription_tier.dart';
import 'package:uag_traders_hub/features/monetisation/services/uag_entitlement_service.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/voice/voice_intent_parser.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/voice/voice_pronunciation.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/voice/voice_profiles.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/voice/voice_response_builder.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class UagVoiceAssistantService extends ChangeNotifier {
  UagVoiceAssistantService({
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
  bool _speakingPreview = false;
  bool _adminBypass = false;
  bool _raidCompanionMode = false;
  UagSubscriptionTier _tier = UagSubscriptionTier.free;
  String _transcript = '';
  String? _lastError;
  UagVoiceResponse? _lastResponse;
  String? _pendingSuggestionName;
  Map<String, ArcBlueprintState> _blueprintStates =
      const <String, ArcBlueprintState>{};
  List<UagResolvedVoiceProfile> _voiceProfiles =
      const <UagResolvedVoiceProfile>[];
  UagResolvedVoiceProfile? _selectedVoice;
  StreamSubscription<Map<String, ArcBlueprintState>>? _blueprintSubscription;
  StreamSubscription<dynamic>? _entitlementSubscription;

  bool get available => _available;
  bool get initialised => _initialised;
  bool get initialising => _initialising;
  bool get listening => _listening;
  bool get thinking => _initialising;
  bool get speakingPreview => _speakingPreview;
  bool get adminBypass => _adminBypass;
  bool get raidCompanionMode => _raidCompanionMode;
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
    if (_initialised || _initialising) return;

    _initialising = true;
    _lastError = null;
    notifyListeners();

    try {
      _startBlueprintStateListener();
      _startEntitlementListener();
      await _loadCompanionModePreference();

      _available = await _speech.initialize(
        onError: (error) {
          _lastError = error.errorMsg;
          _listening = false;
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

  Future<void> startListening() async {
    if (!_initialised) await initialize();

    if (!_available) {
      _lastError ??=
          'Microphone permission is blocked or speech recognition is not available.';
      notifyListeners();
      return;
    }

    if (_listening) return;

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
            _handleTranscript(_transcript);
          }

          notifyListeners();
        },
        listenFor: const Duration(seconds: 20),
        pauseFor: const Duration(seconds: 4),
        localeId: 'en_GB',
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.confirmation,
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

  Future<void> setRaidCompanionMode(bool enabled) async {
    _raidCompanionMode = enabled;
    _lastError = null;
    notifyListeners();

    try {
      await WakelockPlus.toggle(enable: enabled);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_companionModePreferenceKey, enabled);
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
    await _tts.speak(spokenText);
  }

  void submitText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _transcript = trimmed;
    _lastError = null;
    _handleTranscript(trimmed);
    notifyListeners();
  }

  void confirmSuggestedItem() {
    final suggestion = _pendingSuggestionName;
    if (suggestion == null || suggestion.trim().isEmpty) return;

    final response = _responseBuilder.buildConfirmedSuggestion(
      suggestion,
      blueprintStates: _blueprintStates,
    );
    _pendingSuggestionName = null;
    _lastResponse = response;
    _transcript = suggestion;
    if (response.shouldSpeak) {
      speak(response.spokenBody ?? response.body);
    }
    notifyListeners();
  }

  Future<void> _loadCompanionModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_companionModePreferenceKey) ?? false;
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

  void _handleTranscript(String text) {
    if (_isAffirmative(text) && _pendingSuggestionName != null) {
      confirmSuggestedItem();
      return;
    }

    final intent = _parser.parse(text);
    final response = _responseBuilder.build(
      intent,
      blueprintStates: _blueprintStates,
    );

    _pendingSuggestionName = response.suggestedItemName;
    _lastResponse = response;

    if (response.shouldSpeak) {
      speak(response.spokenBody ?? response.body);
    }
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
        normalized == 'show me';
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
                _applyVoice(_selectedVoice!);
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

  @override
  void dispose() {
    _blueprintSubscription?.cancel();
    _entitlementSubscription?.cancel();
    WakelockPlus.disable();
    _speech.cancel();
    _tts.stop();
    super.dispose();
  }
}
