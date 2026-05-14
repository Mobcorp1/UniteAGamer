import 'package:flutter/material.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/voice/voice_assistant_service.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class UagVoiceAssistantSheet extends StatefulWidget {
  const UagVoiceAssistantSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBackgroundDeep,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const UagVoiceAssistantSheet(),
    );
  }

  @override
  State<UagVoiceAssistantSheet> createState() => _UagVoiceAssistantSheetState();
}

class _UagVoiceAssistantSheetState extends State<UagVoiceAssistantSheet> {
  late final UagVoiceAssistantService _service;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _service = UagVoiceAssistantService()..initialize();
    _service.addListener(_onServiceChanged);
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceChanged);
    _service.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _onServiceChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _submitTypedQuery() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _service.submitText(text);
  }

  @override
  Widget build(BuildContext context) {
    final response = _service.lastResponse;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: AppTheme.spaceL,
          right: AppTheme.spaceL,
          top: AppTheme.spaceL,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spaceL,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spaceL),
              Text(
                'UAG Raider Voice',
                style: AppTheme.tradingHeading(
                  fontSize: 24,
                  color: AppTheme.neonPink,
                ),
              ),
              const SizedBox(height: AppTheme.spaceS),
              Text(
                'Ask: “Do I need ARC Alloy?” or “Can I trade lemons?”',
                style: AppTheme.bodyTextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: AppTheme.spaceL),
              ElevatedButton.icon(
                onPressed: _service.listening
                    ? _service.stopListening
                    : _service.startListening,
                icon: Icon(
                  _service.listening ? Icons.stop_rounded : Icons.mic_rounded,
                ),
                label: Text(
                  _service.listening
                      ? 'Listening… tap to stop'
                      : 'Tap and ask UAG Raider',
                ),
              ),
              const SizedBox(height: AppTheme.spaceM),
              TextField(
                controller: _textController,
                style: const TextStyle(color: Colors.white),
                decoration: AppTheme.tradingInputDecoration(
                  label: 'Type instead',
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _submitTypedQuery(),
              ),
              const SizedBox(height: AppTheme.spaceS),
              OutlinedButton.icon(
                onPressed: _submitTypedQuery,
                icon: const Icon(Icons.search_rounded),
                label: const Text('Search'),
              ),
              if (_service.transcript.trim().isNotEmpty) ...[
                const SizedBox(height: AppTheme.spaceM),
                Text(
                  'Heard: ${_service.transcript}',
                  style: AppTheme.bodyTextStyle(
                    fontSize: 13,
                    color: AppTheme.neonCyan,
                  ),
                ),
              ],
              if (response != null) ...[
                const SizedBox(height: AppTheme.spaceL),
                Container(
                  padding: const EdgeInsets.all(AppTheme.spaceM),
                  decoration: AppTheme.tradingCardDecoration(
                    borderColor: AppTheme.neonCyan.withValues(alpha: 0.38),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        response.title,
                        style: AppTheme.tradingHeading(
                          fontSize: 20,
                          color: AppTheme.neonCyan,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceS),
                      Text(
                        response.body,
                        style: AppTheme.bodyTextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
