import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'package:uag_traders_hub/widgets/theme.dart';

class BlueprintVoiceSearchButton extends StatefulWidget {
  const BlueprintVoiceSearchButton({super.key, required this.onSearchText});

  final ValueChanged<String> onSearchText;

  @override
  State<BlueprintVoiceSearchButton> createState() =>
      _BlueprintVoiceSearchButtonState();
}

class _BlueprintVoiceSearchButtonState
    extends State<BlueprintVoiceSearchButton> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _listening = false;
  bool _initialising = false;
  bool _available = false;

  Future<void> _toggle() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }

    if (!_available) {
      setState(() => _initialising = true);
      _available = await _speech.initialize(
        onError: (_) {
          if (mounted) setState(() => _listening = false);
        },
        onStatus: (status) {
          if ((status == 'done' || status == 'notListening') && mounted) {
            setState(() => _listening = false);
          }
        },
      );
      if (mounted) setState(() => _initialising = false);
    }

    if (!_available) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Microphone permission is blocked or speech recognition is unavailable.',
          ),
        ),
      );
      return;
    }

    setState(() => _listening = true);
    await _speech.listen(
      localeId: 'en_GB',
      listenFor: const Duration(seconds: 8),
      pauseFor: const Duration(seconds: 2),
      listenOptions: stt.SpeechListenOptions(listenMode: stt.ListenMode.search),
      onResult: (result) {
        final words = result.recognizedWords.trim();
        if (words.isEmpty) return;
        if (result.finalResult) {
          widget.onSearchText(_cleanBlueprintSearch(words));
          if (mounted) setState(() => _listening = false);
        }
      },
    );
  }

  String _cleanBlueprintSearch(String text) {
    var cleaned = text.toLowerCase();
    const phrases = <String>[
      'uag raider',
      'search blueprint',
      'find blueprint',
      'show blueprint',
      'open blueprint',
      'blueprint',
      'find me',
      'search',
      'show me',
      'please',
    ];
    for (final phrase in phrases) {
      cleaned = cleaned.replaceAll(phrase, ' ');
    }
    return cleaned
        .replaceAll(RegExp(r'[?!.:,;]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _listening ? AppTheme.neonPink : Colors.white70;
    return IconButton(
      tooltip: _listening
          ? 'Listening… tap to stop'
          : 'Voice search blueprints',
      onPressed: _initialising ? null : _toggle,
      icon: _initialising
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(_listening ? Icons.mic : Icons.mic_none_rounded, color: color),
    );
  }
}
