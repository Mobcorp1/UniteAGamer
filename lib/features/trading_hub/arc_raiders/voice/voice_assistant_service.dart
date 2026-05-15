import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/voice/voice_intent_parser.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/voice/voice_response_builder.dart';

class UagVoiceOption {
  const UagVoiceOption({
    required this.id,
    required this.name,
    required this.locale,
    required this.label,
  });

  final String id;
  final String name;
  final String locale;
  final String label;

  Map<String, String> get ttsVoice => <String, String>{
        'name': name,
        'locale': locale,
      };
}

class UagVoiceAssistantService extends ChangeNotifier {
  UagVoiceAssistantService({
    stt.SpeechToText? speech,
    FlutterTts? tts,
    ArcBlueprintRepository? blueprintRepository,
  })  : _speech = speech ?? stt.SpeechToText(),
        _tts = tts ?? FlutterTts(),
        _blueprintRepository = blueprintRepository ?? ArcBlueprintRepository();

  static const String _voicePreferenceKey = 'uag_voice_assistant_voice_id';

  final stt.SpeechToText _speech;
  final FlutterTts _tts;
  final ArcBlueprintRepository _blueprintRepository;

  final UagVoiceIntentParser _parser = const UagVoiceIntentParser();
  final UagVoiceResponseBuilder _responseBuilder = const UagVoiceResponseBuilder();

  bool _available = false;
  bool _initialised = false;
  bool _initialising = false;
  bool _listening = false;
  String _transcript = '';
  String? _lastError;
  UagVoiceResponse? _lastResponse;
  Map<String, ArcBlueprintState> _blueprintStates = const <String, ArcBlueprintState>{};
  StreamSubscription<Map<String, ArcBlueprintState>>? _blueprintSubscription;
  List<UagVoiceOption> _voiceOptions = const <UagVoiceOption>[];
  UagVoiceOption? _selectedVoice;

  bool get available => _available;
  bool get initialised => _initialised;
  bool get initialising => _initialising;
  bool get listening => _listening;
  bool get thinking => _initialising;
  String get transcript => _transcript;
  String? get lastError => _lastError;
  UagVoiceResponse? get lastResponse => _lastResponse;
  Map<String, ArcBlueprintState> get blueprintStates => Map.unmodifiable(_blueprintStates);
  List<UagVoiceOption> get voiceOptions => List.unmodifiable(_voiceOptions);
  UagVoiceOption? get selectedVoice => _selectedVoice;

  Future<void> initialize() async {
    if (_initialised || _initialising) {
      return;
    }

    _initialising = true;
    _lastError = null;
    notifyListeners();

    try {
      _startBlueprintStateListener();

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

      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _loadVoiceOptions();

      if (!_available) {
        _lastError = 'Microphone permission is blocked or speech recognition is not available on this device/browser.';
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
    if (!_initialised) {
      await initialize();
    }

    if (!_available) {
      _lastError ??= 'Microphone permission is blocked or speech recognition is not available.';
      notifyListeners();
      return;
    }

    if (_listening) {
      return;
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

  Future<void> selectVoice(UagVoiceOption option) async {
    _selectedVoice = option;
    await _tts.setVoice(option.ttsVoice);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_voicePreferenceKey, option.id);

    notifyListeners();
  }

  Future<void> speak(String text) async {
    await _tts.stop();
    if (_selectedVoice != null) {
      await _tts.setVoice(_selectedVoice!.ttsVoice);
    }
    await _tts.speak(text);
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

  Future<void> _loadVoiceOptions() async {
    final rawVoices = await _tts.getVoices;
    final options = <UagVoiceOption>[];

    if (rawVoices is List) {
      for (final voice in rawVoices) {
        if (voice is! Map) {
          continue;
        }

        final name = voice['name']?.toString() ?? '';
        final locale = voice['locale']?.toString() ?? '';

        if (name.isEmpty || locale.isEmpty) {
          continue;
        }

        final normalisedLocale = locale.replaceAll('_', '-').toLowerCase();
        if (!normalisedLocale.startsWith('en')) {
          continue;
        }

        final lowerName = name.toLowerCase();
        final isMale = lowerName.contains('male') ||
            lowerName.contains('daniel') ||
            lowerName.contains('george') ||
            lowerName.contains('arthur') ||
            lowerName.contains('ryan');
        final isFemale = lowerName.contains('female') ||
            lowerName.contains('samantha') ||
            lowerName.contains('karen') ||
            lowerName.contains('serena') ||
            lowerName.contains('susan') ||
            lowerName.contains('victoria') ||
            lowerName.contains('moira');
        final voiceType = isMale
            ? 'Male'
            : isFemale
                ? 'Female'
                : 'Voice';

        options.add(
          UagVoiceOption(
            id: '$name|$locale',
            name: name,
            locale: locale,
            label: '$voiceType · $name · $locale',
          ),
        );
      }
    }

    options.sort((a, b) {
      final aGb = a.locale.toLowerCase().contains('gb') ? 0 : 1;
      final bGb = b.locale.toLowerCase().contains('gb') ? 0 : 1;
      final localeCompare = aGb.compareTo(bGb);
      if (localeCompare != 0) {
        return localeCompare;
      }
      return a.label.compareTo(b.label);
    });

    _voiceOptions = options;

    if (_voiceOptions.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final savedVoiceId = prefs.getString(_voicePreferenceKey);

    _selectedVoice = _voiceOptions.firstWhere(
      (voice) => voice.id == savedVoiceId,
      orElse: () => _voiceOptions.first,
    );

    await _tts.setVoice(_selectedVoice!.ttsVoice);
  }

  void _handleTranscript(String text) {
    final intent = _parser.parse(text);
    final response = _responseBuilder.build(
      intent,
      blueprintStates: _blueprintStates,
    );

    _lastResponse = response;

    if (response.shouldSpeak) {
      speak(response.spokenBody ?? response.body);
    }
  }

  void _startBlueprintStateListener() {
    _blueprintSubscription ??= _blueprintRepository.watchMyBlueprintStates().listen(
      (states) {
        _blueprintStates = states;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('UAG voice blueprint state listener failed: $error');
      },
    );
  }

  @override
  void dispose() {
    _blueprintSubscription?.cancel();
    _speech.cancel();
    _tts.stop();
    super.dispose();
  }
}
