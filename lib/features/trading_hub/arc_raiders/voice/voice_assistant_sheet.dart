import 'package:flutter/material.dart';
import 'package:uag_traders_hub/features/monetisation/models/uag_subscription_tier.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/voice/voice_assistant_service.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/voice/voice_profiles.dart';
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
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final response = _service.lastResponse;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.92;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: AppTheme.spaceL,
            right: AppTheme.spaceL,
            top: AppTheme.spaceL,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spaceL,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
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
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'UAG Raider Voice',
                      style: AppTheme.tradingHeading(
                        fontSize: 24,
                        color: AppTheme.neonPink,
                      ),
                    ),
                  ),
                  _TierBadge(tier: _service.tier, adminBypass: _service.adminBypass),
                ],
              ),
              const SizedBox(height: AppTheme.spaceS),
              Text(
                'Ask about blueprints, trades, quests, Scrappy items, or bench materials.',
                style: AppTheme.bodyTextStyle(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: AppTheme.spaceL),
              _buildMicButton(),
              if (_service.lastError != null) ...<Widget>[
                const SizedBox(height: AppTheme.spaceM),
                _ErrorCard(message: _service.lastError!),
              ],
              const SizedBox(height: AppTheme.spaceM),
              TextField(
                controller: _textController,
                style: const TextStyle(color: Colors.white),
                decoration: AppTheme.tradingInputDecoration(label: 'Type instead'),
                onSubmitted: _service.submitText,
              ),
              const SizedBox(height: AppTheme.spaceS),
              OutlinedButton.icon(
                onPressed: () => _service.submitText(_textController.text),
                icon: const Icon(Icons.search_rounded),
                label: const Text('Search'),
              ),
              if (_service.transcript.trim().isNotEmpty) ...<Widget>[
                const SizedBox(height: AppTheme.spaceM),
                Text(
                  'Heard: ${_service.transcript}',
                  style: AppTheme.bodyTextStyle(fontSize: 13, color: AppTheme.neonCyan),
                ),
              ],
              if (response != null) ...<Widget>[
                const SizedBox(height: AppTheme.spaceL),
                Container(
                  padding: const EdgeInsets.all(AppTheme.spaceM),
                  decoration: AppTheme.tradingCardDecoration(
                    borderColor: AppTheme.neonCyan.withValues(alpha: 0.38),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        response.title,
                        style: AppTheme.tradingHeading(fontSize: 20, color: AppTheme.neonCyan),
                      ),
                      const SizedBox(height: AppTheme.spaceS),
                      Text(
                        response.body,
                        style: AppTheme.bodyTextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppTheme.spaceL),
              _buildVoiceProfiles(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMicButton() {
    final label = _service.listening
        ? 'Listening… tap to stop'
        : _service.initialising
            ? 'Starting voice system…'
            : 'Tap and ask UAG Raider';

    return ElevatedButton.icon(
      onPressed: _service.initialising
          ? null
          : _service.listening
              ? _service.stopListening
              : _service.startListening,
      icon: Icon(_service.listening ? Icons.stop_rounded : Icons.mic_rounded),
      label: Text(label),
    );
  }

  Widget _buildVoiceProfiles() {
    final profiles = _service.voiceProfiles;
    if (profiles.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.spaceM),
        decoration: AppTheme.tradingCardDecoration(
          borderColor: AppTheme.neonPink.withValues(alpha: 0.28),
        ),
        child: Text(
          'Voice profiles are loading. If none appear, this device/browser has not exposed English TTS voices yet.',
          style: AppTheme.bodyTextStyle(fontSize: 13, color: Colors.white70),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Voice Profiles',
          style: AppTheme.tradingHeading(fontSize: 20, color: AppTheme.neonCyan),
        ),
        const SizedBox(height: AppTheme.spaceS),
        Text(
          'Preview any voice, then select the one you want. Raw device voice names are hidden to keep this clean.',
          style: AppTheme.bodyTextStyle(fontSize: 13, color: Colors.white60),
        ),
        const SizedBox(height: AppTheme.spaceM),
        for (final tier in UagSubscriptionTier.values) ...<Widget>[
          _TierSectionHeader(tier: tier),
          const SizedBox(height: AppTheme.spaceS),
          ...profiles
              .where((voice) => voice.requiredTier == tier)
              .map((voice) => Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spaceS),
                    child: _VoiceProfileCard(
                      voice: voice,
                      selected: _service.selectedVoice?.id == voice.id,
                      unlocked: voice.profile.isUnlockedFor(
                        _service.tier,
                        adminBypass: _service.adminBypass,
                      ),
                      previewing: _service.speakingPreview,
                      onPreview: () => _service.previewVoice(voice),
                      onSelect: () => _service.selectVoice(voice),
                    ),
                  )),
          const SizedBox(height: AppTheme.spaceM),
        ],
      ],
    );
  }
}

class _VoiceProfileCard extends StatelessWidget {
  const _VoiceProfileCard({
    required this.voice,
    required this.selected,
    required this.unlocked,
    required this.previewing,
    required this.onPreview,
    required this.onSelect,
  });

  final UagResolvedVoiceProfile voice;
  final bool selected;
  final bool unlocked;
  final bool previewing;
  final VoidCallback onPreview;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? AppTheme.neonPink.withValues(alpha: 0.72)
        : unlocked
            ? AppTheme.neonCyan.withValues(alpha: 0.34)
            : Colors.white24;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: AppTheme.tradingCardDecoration(borderColor: borderColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  voice.displayName,
                  style: AppTheme.tradingHeading(
                    fontSize: 19,
                    color: selected ? AppTheme.neonPink : AppTheme.neonCyan,
                  ),
                ),
              ),
              _SmallBadge(
                label: selected
                    ? 'Selected'
                    : unlocked
                        ? voice.tierLabel
                        : 'Locked · ${voice.tierLabel}',
                color: selected
                    ? AppTheme.neonPink
                    : unlocked
                        ? AppTheme.neonCyan
                        : Colors.white38,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            voice.subtitle,
            style: AppTheme.bodyTextStyle(fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: AppTheme.spaceS),
          Text(
            voice.description,
            style: AppTheme.bodyTextStyle(fontSize: 13, color: Colors.white60),
          ),
          if (voice.isFallback) ...<Widget>[
            const SizedBox(height: AppTheme.spaceS),
            Text(
              'Uses the closest matching voice available on this device.',
              style: AppTheme.bodyTextStyle(fontSize: 12, color: Colors.white38),
            ),
          ],
          const SizedBox(height: AppTheme.spaceM),
          Wrap(
            spacing: AppTheme.spaceS,
            runSpacing: AppTheme.spaceS,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: previewing ? null : onPreview,
                icon: const Icon(Icons.volume_up_rounded),
                label: const Text('Preview'),
              ),
              ElevatedButton.icon(
                onPressed: unlocked ? onSelect : null,
                icon: Icon(selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded),
                label: Text(selected ? 'Selected' : 'Select'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TierSectionHeader extends StatelessWidget {
  const _TierSectionHeader({required this.tier});

  final UagSubscriptionTier tier;

  @override
  Widget build(BuildContext context) {
    final color = switch (tier) {
      UagSubscriptionTier.free => Colors.white70,
      UagSubscriptionTier.essential => AppTheme.neonCyan,
      UagSubscriptionTier.premium => AppTheme.neonPink,
    };

    return Row(
      children: <Widget>[
        Icon(Icons.graphic_eq_rounded, size: 18, color: color),
        const SizedBox(width: AppTheme.spaceS),
        Text(
          '${tier.label} voices',
          style: AppTheme.tradingHeading(fontSize: 16, color: color),
        ),
      ],
    );
  }
}

class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.tier, required this.adminBypass});

  final UagSubscriptionTier tier;
  final bool adminBypass;

  @override
  Widget build(BuildContext context) {
    return _SmallBadge(
      label: adminBypass ? 'Dev/Admin' : tier.label,
      color: adminBypass ? AppTheme.neonPink : AppTheme.neonCyan,
    );
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.48)),
      ),
      child: Text(
        label,
        style: AppTheme.bodyTextStyle(fontSize: 12, color: color),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: AppTheme.tradingCardDecoration(
        borderColor: AppTheme.neonPink.withValues(alpha: 0.45),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.warning_amber_rounded, color: AppTheme.neonPink),
          const SizedBox(width: AppTheme.spaceS),
          Expanded(
            child: Text(
              message,
              style: AppTheme.bodyTextStyle(fontSize: 13, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
