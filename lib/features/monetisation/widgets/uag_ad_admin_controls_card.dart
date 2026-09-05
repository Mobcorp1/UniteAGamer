import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/ads/uag_ad_runtime_settings.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class UagAdAdminControlsCard extends StatefulWidget {
  const UagAdAdminControlsCard({super.key});

  @override
  State<UagAdAdminControlsCard> createState() => _UagAdAdminControlsCardState();
}

class _UagAdAdminControlsCardState extends State<UagAdAdminControlsCard> {
  final _repo = UagAdSettingsRepository();
  bool _saving = false;

  Future<void> _save(UagAdRuntimeSettings value) async {
    setState(() => _saving = true);
    try {
      await _repo.save(value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Advertising controls updated.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not update advertising controls: $error'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<UagAdRuntimeSettings>(
    stream: _repo.watch(),
    initialData: UagAdRuntimeSettings.defaults,
    builder: (context, snapshot) {
      final s = snapshot.data ?? UagAdRuntimeSettings.defaults;
      return Container(
        width: double.infinity,
        padding: AppTheme.sectionCardPadding,
        decoration: AppTheme.tradingCardDecoration(
          borderColor: AppTheme.neonCyan.withValues(alpha: 0.28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Advertising Controls',
              style: AppTheme.tradingHeading(
                fontSize: 22,
                color: AppTheme.neonCyan,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Free: banner + App Open + controlled interstitial. Essential: banner only. Premium: ad-free.',
              style: AppTheme.bodyTextStyle(
                fontSize: 13,
                color: AppTheme.tradingMutedText,
              ),
            ),
            const SizedBox(height: 12),
            _toggle(
              'Master advertising',
              s.adsEnabled,
              (v) => _save(s.copyWith(adsEnabled: v)),
            ),
            _toggle(
              'Banner ads',
              s.bannerEnabled,
              (v) => _save(s.copyWith(bannerEnabled: v)),
            ),
            _toggle(
              'App Open ads',
              s.appOpenEnabled,
              (v) => _save(s.copyWith(appOpenEnabled: v)),
            ),
            _toggle(
              'Navigation interstitials',
              s.interstitialEnabled,
              (v) => _save(s.copyWith(interstitialEnabled: v)),
            ),
            _toggle(
              'Force Google test ads',
              s.forceTestAds,
              (v) => _save(s.copyWith(forceTestAds: v)),
            ),
            _toggle(
              'Allow production ad unit IDs',
              s.productionAdsEnabled,
              (v) => _save(s.copyWith(productionAdsEnabled: v)),
            ),
            const Divider(height: 24),
            _numberRow(
              'Interstitial every',
              s.interstitialEveryTransitions,
              2,
              10,
              'eligible transitions',
              (v) => _save(s.copyWith(interstitialEveryTransitions: v)),
            ),
            _numberRow(
              'Interstitial cooldown',
              s.interstitialCooldownSeconds,
              30,
              600,
              'seconds',
              (v) => _save(s.copyWith(interstitialCooldownSeconds: v)),
            ),
            _numberRow(
              'App Open foreground cooldown',
              s.appOpenForegroundCooldownMinutes,
              5,
              120,
              'minutes',
              (v) => _save(s.copyWith(appOpenForegroundCooldownMinutes: v)),
            ),
            _numberRow(
              'App Open starts after',
              s.minimumSessionsBeforeAppOpen,
              1,
              10,
              'app sessions',
              (v) => _save(s.copyWith(minimumSessionsBeforeAppOpen: v)),
            ),
            if (_saving)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      );
    },
  );

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) =>
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(
          label,
          style: AppTheme.bodyTextStyle(fontSize: 14, color: Colors.white),
        ),
        value: value,
        onChanged: _saving ? null : onChanged,
      );

  Widget _numberRow(
    String label,
    int value,
    int min,
    int max,
    String suffix,
    ValueChanged<int> onChanged,
  ) => Row(
    children: [
      Expanded(
        child: Text(
          '$label: $value $suffix',
          style: AppTheme.bodyTextStyle(fontSize: 13, color: Colors.white70),
        ),
      ),
      IconButton(
        onPressed: _saving || value <= min ? null : () => onChanged(value - 1),
        icon: const Icon(Icons.remove_circle_outline),
      ),
      IconButton(
        onPressed: _saving || value >= max ? null : () => onChanged(value + 1),
        icon: const Icon(Icons.add_circle_outline),
      ),
    ],
  );
}
