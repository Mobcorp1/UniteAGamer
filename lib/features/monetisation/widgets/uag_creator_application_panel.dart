import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_creator_application_policy.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_creator_programme_models.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/repositories/uag_creator_front_door_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_tactical_page.dart';

class UagCreatorApplicationPanel extends StatefulWidget {
  const UagCreatorApplicationPanel({super.key});

  @override
  State<UagCreatorApplicationPanel> createState() =>
      _UagCreatorApplicationPanelState();
}

class _UagCreatorApplicationPanelState
    extends State<UagCreatorApplicationPanel> {
  final _repository = UagCreatorFrontDoorRepository();
  final _nameController = TextEditingController();
  final _handleController = TextEditingController();
  final _audienceController = TextEditingController();
  final Set<String> _platforms = <String>{};
  bool _termsAccepted = false;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _handleController.dispose();
    _audienceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final handle = _handleController.text.trim();
      final audience = int.tryParse(_audienceController.text.trim());
      final handles = <String, String>{
        for (final platform in _platforms)
          if (handle.isNotEmpty) platform: handle,
      };
      await _repository.submitApplication(
        displayName: _nameController.text,
        platforms: _platforms.toList(growable: false),
        socialHandles: handles,
        termsAccepted: _termsAccepted,
        audienceSize: audience,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Creator application submitted for review.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not submit creator application. Try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UagCreatorProgrammeApplication?>(
      stream: _repository.watchMyApplication(),
      builder: (context, snapshot) {
        final application = snapshot.data;
        if (application != null) {
          return _ExistingApplicationPanel(application: application);
        }

        return ArcTacticalPanel(
          icon: Icons.campaign_outlined,
          title: 'APPLY TO CREATOR PROGRAMME',
          subtitle:
              'For creators who want campaign tools, tracked referrals and the enhanced commission ladder.',
          accent: ArcUiTokens.secondaryAccent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController,
                style: ArcUiTokens.body(color: ArcUiTokens.textPrimary),
                decoration: ArcUiTokens.inputDecoration(
                  labelText: 'Creator / channel name',
                  prefixIcon: Icons.badge_outlined,
                ),
              ),
              const SizedBox(height: ArcUiTokens.gapM),
              Text(
                'PLATFORMS',
                style: ArcUiTokens.label(color: ArcUiTokens.secondaryAccent),
              ),
              const SizedBox(height: ArcUiTokens.gapS),
              Wrap(
                spacing: ArcUiTokens.gapS,
                runSpacing: ArcUiTokens.gapS,
                children: [
                  for (final platform
                      in UagCreatorApplicationPolicy.supportedPlatforms)
                    _PlatformChip(
                      label: platform,
                      selected: _platforms.contains(platform),
                      onTap: () {
                        setState(() {
                          if (_platforms.contains(platform)) {
                            _platforms.remove(platform);
                          } else {
                            _platforms.add(platform);
                          }
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: ArcUiTokens.gapM),
              TextField(
                controller: _handleController,
                style: ArcUiTokens.body(color: ArcUiTokens.textPrimary),
                decoration: ArcUiTokens.inputDecoration(
                  labelText: 'Primary social handle / channel',
                  hintText: '@yourhandle',
                  prefixIcon: Icons.alternate_email_rounded,
                ),
              ),
              const SizedBox(height: ArcUiTokens.gapM),
              TextField(
                controller: _audienceController,
                keyboardType: TextInputType.number,
                style: ArcUiTokens.body(color: ArcUiTokens.textPrimary),
                decoration: ArcUiTokens.inputDecoration(
                  labelText: 'Approx. audience size (optional)',
                  prefixIcon: Icons.groups_outlined,
                ),
              ),
              const SizedBox(height: ArcUiTokens.gapS),
              InkWell(
                borderRadius: BorderRadius.circular(ArcUiTokens.radiusM),
                onTap: () => setState(() => _termsAccepted = !_termsAccepted),
                child: Container(
                  padding: ArcUiTokens.compactPanelPadding,
                  decoration: ArcUiTokens.surfaceDecoration(
                    role: ArcSurfaceRole.interactive,
                    accent: _termsAccepted
                        ? ArcUiTokens.secondaryAccent
                        : ArcUiTokens.primaryAccent,
                    selected: _termsAccepted,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _termsAccepted,
                        activeColor: ArcUiTokens.secondaryAccent,
                        onChanged: (value) => setState(
                          () => _termsAccepted = value ?? false,
                        ),
                      ),
                      const SizedBox(width: ArcUiTokens.gapXS),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 9),
                          child: Text(
                            'I agree to the UAG Creator Programme terms and understand rewards and commission require validation.',
                            style: ArcUiTokens.bodySmall(
                              color: ArcUiTokens.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: ArcUiTokens.gapM),
              FilledButton.icon(
                style: ArcUiTokens.textButtonStyle(
                  accent: ArcUiTokens.secondaryAccent,
                  primary: true,
                ),
                onPressed: _submitting ? null : _submit,
                icon: const Icon(Icons.send_outlined, size: 18),
                label: Text(
                  _submitting ? 'SUBMITTING...' : 'APPLY TO CREATOR PROGRAMME',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PlatformChip extends StatelessWidget {
  const _PlatformChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: ArcUiTokens.chipPadding,
        decoration: ArcUiTokens.chipDecoration(
          color: ArcUiTokens.secondaryAccent,
          selected: selected,
        ),
        child: Text(
          label.toUpperCase(),
          style: ArcUiTokens.label(
            color: selected
                ? ArcUiTokens.secondaryAccent
                : ArcUiTokens.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _ExistingApplicationPanel extends StatelessWidget {
  const _ExistingApplicationPanel({required this.application});

  final UagCreatorProgrammeApplication application;

  @override
  Widget build(BuildContext context) {
    final approved = application.status == UagCreatorApplicationStatus.approved;
    final accent = approved
        ? ArcUiTokens.secondaryAccent
        : ArcUiTokens.primaryAccent;

    return ArcTacticalPanel(
      icon: approved ? Icons.verified_outlined : Icons.hourglass_top_rounded,
      title: approved ? 'CREATOR PROGRAMME ACTIVE' : 'CREATOR APPLICATION',
      subtitle: approved
          ? 'Your creator tools and commercial benefits are active.'
          : 'Your application is in the UAG review flow.',
      accent: accent,
      child: Wrap(
        spacing: ArcUiTokens.gapS,
        runSpacing: ArcUiTokens.gapS,
        children: [
          _StatusChip(label: application.status.label, accent: accent),
          if (application.creatorId.trim().isNotEmpty)
            _StatusChip(
              label: 'ID ${application.creatorId}',
              accent: ArcUiTokens.primaryAccent,
            ),
          _StatusChip(
            label: application.displayName,
            accent: ArcUiTokens.textTertiary,
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ArcUiTokens.chipPadding,
      decoration: ArcUiTokens.chipDecoration(color: accent, selected: true),
      child: Text(label.toUpperCase(), style: ArcUiTokens.label(color: accent)),
    );
  }
}
