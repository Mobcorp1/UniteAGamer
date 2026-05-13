import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/voice/voice_intent_parser.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/voice/voice_response_builder.dart';

class UagVoiceAssistantService extends ChangeNotifier {
  UagVoiceAssistantService({stt.SpeechToText? speech, FlutterTts? tts})
    : _speech = speech ?? stt.SpeechToText(),
      _tts = tts ?? FlutterTts();

  final stt.SpeechToText _speech;
  final FlutterTts _tts;

  final UagVoiceIntentParser _parser = const UagVoiceIntentParser();
  final UagVoiceResponseBuilder _responseBuilder =
      const UagVoiceResponseBuilder();

  bool _available = false;
  bool _listening = false;
  String _transcript = '';
  UagVoiceResponse? _lastResponse;

  bool get available => _available;
  bool get listening => _listening;
  String get transcript => _transcript;
  UagVoiceResponse? get lastResponse => _lastResponse;

  Future<void> initialize() async {
    _available = await _speech.initialize(
      onError: (error) => debugPrint('UAG voice error: $error'),
      onStatus: (status) => debugPrint('UAG voice status: $status'),
    );

    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);

    notifyListeners();
  }

  Future<void> startListening() async {
    if (!_available) {
      await initialize();
    }

    if (!_available || _listening) {
      return;
    }

    _transcript = '';
    _lastResponse = null;
    _listening = true;

    notifyListeners();

    await _speech.listen(
      onResult: (result) {
        _transcript = result.recognizedWords;

        if (result.finalResult) {
          _listening = false;
          _handleTranscript(_transcript);
        }

        notifyListeners();
      },
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.confirmation,
      ),
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();

    _listening = false;

    if (_transcript.trim().isNotEmpty) {
      _handleTranscript(_transcript);
    }

    notifyListeners();
  }

  Future<void> speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  void submitText(String text) {
    _transcript = text;
    _handleTranscript(text);
    notifyListeners();
  }

  void _handleTranscript(String text) {
    final intent = _parser.parse(text);
    final response = _responseBuilder.build(intent);

    _lastResponse = response;

    if (response.shouldSpeak) {
      speak(response.body);
    }
  }

  @override
  void dispose() {
    _speech.cancel();
    _tts.stop();
    super.dispose();
  }
}
