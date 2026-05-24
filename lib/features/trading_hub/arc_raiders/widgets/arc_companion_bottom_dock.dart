import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/voice/voice_assistant_service.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/voice/voice_assistant_sheet.dart';
import 'package:uag_traders_hub/widgets/electric_charge_border.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class ArcCompanionBottomDock extends StatefulWidget {
  final String activeLabel;

  const ArcCompanionBottomDock({super.key, required this.activeLabel});

  @override
  State<ArcCompanionBottomDock> createState() => _ArcCompanionBottomDockState();
}

class _ArcCompanionBottomDockState extends State<ArcCompanionBottomDock> {
  late final UagVoiceArcAssistantService _service;
  bool _ready = false;

  @override
  void initState() {
    super.initState();

    _service = UagVoiceArcAssistantService();
    _service.addListener(_handleServiceChange);
    unawaited(_armCompanion());
  }

  Future<void> _armCompanion() async {
    await _service.initialize();

    if (!mounted) {
      return;
    }

    await _service.setRaidCompanionMode(true);
    await Future<void>.delayed(const Duration(milliseconds: 75));

    if (!mounted) {
      return;
    }

    await _service.startListening();

    if (!mounted) {
      return;
    }

    setState(() => _ready = true);
  }

  void _handleServiceChange() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _handleMicTap() async {
    if (_service.speaking) {
      await _service.stopSpeakingForUser();
      return;
    }

    if (_service.listening) {
      await _service.stopListening();
      await _service.startListening();
      return;
    }

    await _service.startListening();
  }

  @override
  void dispose() {
    _service.removeListener(_handleServiceChange);
    unawaited(_service.setRaidCompanionMode(false));
    unawaited(_service.stopListening());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listening = _service.listening;
    final speaking = _service.speaking;
    final active = listening || speaking || _ready;

    final status = speaking
        ? 'ARC speaking - tap mic to interrupt'
        : listening
        ? 'ARC listening'
        : _ready
        ? 'ARC ready'
        : 'ARC waking';

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppTheme.neonCyan.withValues(alpha: active ? 0.42 : 0.22),
          ),
          boxShadow: [
            BoxShadow(
              color: (active ? AppTheme.neonCyan : Colors.black).withValues(
                alpha: active ? 0.16 : 0.18,
              ),
              blurRadius: 24,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            _DockButton(
              icon: Icons.arrow_back_rounded,
              label: 'Back',
              onTap: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DockStatus(
                label: widget.activeLabel,
                status: status,
                active: active,
              ),
            ),
            const SizedBox(width: 8),
            ElectricChargeBorder(
              active: active,
              radius: 999,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: _handleMicTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (speaking ? AppTheme.neonPink : AppTheme.neonCyan)
                        .withValues(alpha: active ? 0.18 : 0.08),
                    border: Border.all(
                      color: (speaking ? AppTheme.neonPink : AppTheme.neonCyan)
                          .withValues(alpha: active ? 0.78 : 0.36),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (speaking ? AppTheme.neonPink : AppTheme.neonCyan)
                                .withValues(alpha: active ? 0.28 : 0.1),
                        blurRadius: active ? 24 : 12,
                        spreadRadius: active ? 1 : 0,
                      ),
                    ],
                  ),
                  child: Icon(
                    speaking
                        ? Icons.record_voice_over_rounded
                        : listening
                        ? Icons.hearing_rounded
                        : Icons.mic_rounded,
                    color: speaking ? AppTheme.neonPink : AppTheme.neonCyan,
                    size: 30,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DockStatus extends StatelessWidget {
  final String label;
  final String status;
  final bool active;

  const _DockStatus({
    required this.label,
    required this.status,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppTheme.neonCyan.withValues(alpha: active ? 0.32 : 0.18),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTheme.neonTextStyle(
              fontSize: 14,
              color: AppTheme.neonCyan,
              isBold: true,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            status,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTheme.bodyTextStyle(
              fontSize: 10,
              color: active ? Colors.white70 : AppTheme.tradingMutedText,
            ),
          ),
        ],
      ),
    );
  }
}

class _DockButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DockButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.neonCyan.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.26)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.neonCyan, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTheme.bodyTextStyle(
                fontSize: 12,
                color: AppTheme.neonCyan,
                isBold: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
