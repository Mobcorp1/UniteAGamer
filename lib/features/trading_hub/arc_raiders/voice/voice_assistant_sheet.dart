import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/voice/voice_assistant_service.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class UagVoiceArcAssistantSheet extends StatefulWidget {
  const UagVoiceArcAssistantSheet({super.key, this.autoStart = false});

  final bool autoStart;

  static Future<void> show(BuildContext context, {bool autoStart = false}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ArcUiTokens.surfaceOverlay,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ArcUiTokens.radiusXL),
        ),
      ),
      builder: (_) => UagVoiceArcAssistantSheet(autoStart: autoStart),
    );
  }

  @override
  State<UagVoiceArcAssistantSheet> createState() =>
      _UagVoiceArcAssistantSheetState();
}

class _UagVoiceArcAssistantSheetState extends State<UagVoiceArcAssistantSheet> {
  late final UagVoiceArcAssistantService _service;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _service = UagVoiceArcAssistantService();
    _service.addListener(_handleServiceUpdate);
    unawaited(_initialiseAssistant());
  }

  Future<void> _initialiseAssistant() async {
    await _service.initialize();

    if (!mounted) {
      return;
    }

    if (widget.autoStart) {
      await _service.setRaidCompanionMode(true);
      await Future<void>.delayed(const Duration(milliseconds: 75));

      if (mounted) {
        await _service.startListening();
      }
    }
  }

  void _handleServiceUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _service.removeListener(_handleServiceUpdate);
    _textController.dispose();
    super.dispose();
  }

  Future<void> _toggleCompanionMode(bool enabled) async {
    await _service.setRaidCompanionMode(enabled);

    if (enabled) {
      await _service.startListening();
    }
  }

  void _submitText() {
    final value = _textController.text.trim();

    if (value.isEmpty) {
      return;
    }

    _service.submitText(value);
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final response = _service.lastResponse;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppTheme.spaceM,
          right: AppTheme.spaceM,
          top: AppTheme.spaceM,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spaceM,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: AppTheme.spaceM),
            _buildCompanionSwitch(),
            const SizedBox(height: AppTheme.spaceM),
            _buildMicButton(),
            if (_service.transcript.trim().isNotEmpty) ...[
              const SizedBox(height: AppTheme.spaceS),
              _InfoPanel(title: 'Heard', body: _service.transcript),
            ],
            if (response != null) ...[
              const SizedBox(height: AppTheme.spaceS),
              _InfoPanel(title: response.title, body: response.body),
            ],
            if (_service.lastError != null) ...[
              const SizedBox(height: AppTheme.spaceS),
              _InfoPanel(
                title: 'Voice issue',
                body: _service.lastError!,
                warning: true,
              ),
            ],
            const SizedBox(height: AppTheme.spaceM),
            _buildTextFallback(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final status = _service.speaking
        ? 'Speaking - tap mic to interrupt'
        : _service.listening
        ? 'Listening'
        : _service.raidCompanionMode
        ? 'Companion armed'
        : 'Assistant ready';

    return Row(
      children: [
        const Icon(
          Icons.mic_rounded,
          color: ArcUiTokens.secondaryAccent,
          size: 30,
        ),
        const SizedBox(width: AppTheme.spaceS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ARC Assistant',
                style: ArcUiTokens.sectionTitle(
                  fontSize: 18,
                  color: ArcUiTokens.primaryAccent,
                ),
              ),
              Text(
                status,
                style: ArcUiTokens.bodySmall(color: ArcUiTokens.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompanionSwitch() {
    return SwitchListTile.adaptive(
      value: _service.raidCompanionMode,
      onChanged: _service.initialising ? null : _toggleCompanionMode,
      activeThumbColor: ArcUiTokens.primaryAccent,
      activeTrackColor: ArcUiTokens.primaryAccent.withValues(alpha: 0.32),
      title: Text(
        'Raid Companion Mode',
        style: ArcUiTokens.body(
          color: ArcUiTokens.textPrimary,
          weight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        'Keeps the mic ready while this assistant is open.',
        style: ArcUiTokens.bodySmall(color: ArcUiTokens.textSecondary),
      ),
    );
  }

  Widget _buildMicButton() {
    final label = _service.speaking
        ? 'Assistant speaking...\ntap to speak'
        : _service.listening
        ? 'Listening...\ntap to stop'
        : _service.initialising
        ? 'Starting voice system...'
        : 'Tap to speak';

    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        style: ArcUiTokens.textButtonStyle(
          accent: ArcUiTokens.primaryAccent,
          primary: true,
        ),
        onPressed: _service.initialising
            ? null
            : _service.speaking
            ? _service.stopSpeakingForUser
            : _service.listening
            ? _service.stopListening
            : _service.startListening,
        icon: Icon(
          _service.speaking
              ? Icons.record_voice_over_rounded
              : _service.listening
              ? Icons.hearing_rounded
              : Icons.mic_rounded,
        ),
        label: Text(label, textAlign: TextAlign.center),
      ),
    );
  }

  Widget _buildTextFallback() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _textController,
            style: ArcUiTokens.body(color: ArcUiTokens.textPrimary),
            decoration: ArcUiTokens.inputDecoration(
              labelText: 'Command',
              hintText: 'Type a command if voice misses it...',
            ),
            onSubmitted: (_) => _submitText(),
          ),
        ),
        const SizedBox(width: AppTheme.spaceS),
        IconButton(
          onPressed: _submitText,
          icon: const Icon(
            Icons.send_rounded,
            color: ArcUiTokens.primaryAccent,
          ),
        ),
      ],
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final String title;
  final String body;
  final bool warning;

  const _InfoPanel({
    required this.title,
    required this.body,
    this.warning = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = warning
        ? ArcUiTokens.secondaryAccent
        : ArcUiTokens.primaryAccent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.raised,
        accent: color,
        borderOpacity: 0.28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: ArcUiTokens.sectionTitle(fontSize: 15, color: color),
          ),
          const SizedBox(height: 6),
          Text(body, style: ArcUiTokens.body(color: ArcUiTokens.textSecondary)),
        ],
      ),
    );
  }
}
