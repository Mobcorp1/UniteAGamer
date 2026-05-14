import 'package:flutter/material.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/voice/voice_assistant_service.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class UagVoiceAssistantSheet extends StatefulWidget {
  const UagVoiceAssistantSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.cardBackgroundDeep,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const UagVoiceAssistantSheet(),
  );

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
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final response = _service.lastResponse;
    final viewInsets = MediaQuery.of(context).viewInsets;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: AppTheme.spaceL,
          right: AppTheme.spaceL,
          top: AppTheme.spaceL,
          bottom: viewInsets.bottom + AppTheme.spaceL,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.88,
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
                  'Ask: “Who wants Anvil?”, “Any trade sessions today?”, or “Find blueprint Canto”.',
                  style: AppTheme.bodyTextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceL),
                _buildVoiceSelector(),
                const SizedBox(height: AppTheme.spaceM),
                ElevatedButton.icon(
                  onPressed: (_service.initialising || _service.thinking)
                      ? null
                      : _service.listening
                      ? _service.stopListening
                      : _service.startListening,
                  icon: Icon(
                    _service.listening ? Icons.stop_rounded : Icons.mic_rounded,
                  ),
                  label: Text(
                    _service.thinking
                        ? 'Checking live UAG data…'
                        : _service.initialising
                        ? 'Starting voice assistant…'
                        : _service.listening
                        ? 'Listening… tap to stop'
                        : 'Tap and ask UAG Raider',
                  ),
                ),

                if (_service.thinking) ...[
                  const SizedBox(height: AppTheme.spaceM),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spaceM),
                    decoration: AppTheme.tradingCardDecoration(
                      borderColor: AppTheme.neonPink.withValues(alpha: 0.28),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: AppTheme.spaceM),
                        Expanded(
                          child: Text(
                            'Checking live trades, sessions and tracker state…',
                            style: AppTheme.bodyTextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_service.lastError != null) ...[
                  const SizedBox(height: AppTheme.spaceM),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spaceM),
                    decoration: AppTheme.tradingCardDecoration(
                      borderColor: AppTheme.warningAmber.withValues(
                        alpha: 0.55,
                      ),
                      backgroundColor: AppTheme.warningAmber.withValues(
                        alpha: 0.08,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppTheme.warningAmber,
                          size: 20,
                        ),
                        const SizedBox(width: AppTheme.spaceS),
                        Expanded(
                          child: Text(
                            _service.lastError!,
                            style: AppTheme.bodyTextStyle(
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppTheme.spaceM),
                TextField(
                  controller: _textController,
                  style: const TextStyle(color: Colors.white),
                  decoration: AppTheme.tradingInputDecoration(
                    label: 'Type instead',
                  ),
                  onSubmitted: (value) {
                    _service.submitText(value);
                  },
                ),
                const SizedBox(height: AppTheme.spaceS),
                OutlinedButton.icon(
                  onPressed: _service.thinking
                      ? null
                      : () {
                          _service.submitText(_textController.text);
                        },
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
      ),
    );
  }

  Widget _buildVoiceSelector() {
    if (_service.voiceOptions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.spaceM),
        decoration: AppTheme.tradingCardDecoration(
          borderColor: AppTheme.neonCyan.withValues(alpha: 0.22),
        ),
        child: Text(
          'Voice output will use the default system voice on this device.',
          style: AppTheme.bodyTextStyle(fontSize: 13, color: Colors.white70),
        ),
      );
    }

    return DropdownButtonFormField<UagVoiceOption>(
      initialValue: _service.selectedVoice,
      dropdownColor: AppTheme.cardBackgroundDeep,
      iconEnabledColor: AppTheme.neonPink,
      style: AppTheme.bodyTextStyle(fontSize: 13, color: Colors.white),
      decoration: AppTheme.tradingInputDecoration(label: 'Assistant voice'),
      items: _service.voiceOptions
          .map(
            (voice) => DropdownMenuItem<UagVoiceOption>(
              value: voice,
              child: Text(voice.label, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (voice) {
        if (voice == null) {
          return;
        }
        _service.selectVoice(voice);
      },
    );
  }
}
