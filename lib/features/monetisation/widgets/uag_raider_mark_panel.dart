import 'dart:async';
import 'package:flutter/material.dart';
import '../ads/uag_ad_service.dart';
import '../ads/uag_admob_config.dart';
import '../ads/uag_rewarded_ad_service.dart';
import '../models/uag_raider_mark_policy.dart';
import '../services/uag_raider_mark_service.dart';
import '../../trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';

class UagRaiderMarkPanel extends StatefulWidget {
  const UagRaiderMarkPanel({super.key});
  @override
  State<UagRaiderMarkPanel> createState() => _UagRaiderMarkPanelState();
}

class _UagRaiderMarkPanelState extends State<UagRaiderMarkPanel> {
  late final UagRaiderMarkService _marks = UagRaiderMarkService();
  late final UagRewardedAdService _rewarded = UagRewardedAdService(
    marks: _marks,
  );
  Stream<UagRaiderMarkWallet>? _wallet;
  String? _walletUid;
  bool _busy = false;
  String? _message;
  Timer? _clock;
  final Map<UagRaiderMarkRedemptionTarget, String> _retryIds = {};
  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  Future<void> _watch() async {
    setState(() {
      _busy = true;
      _message = 'Loading rewarded ad…';
    });
    try {
      final message = await _rewarded.watchAndEarn();
      if (mounted) {
        setState(() => _message = message);
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _message = error is UagRewardException
              ? error.message
              : 'The reward could not be completed. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _redeem(UagRaiderMarkRedemptionTarget target) async {
    final id = _retryIds.putIfAbsent(target, UagRaiderMarkService.newRequestId);
    setState(() {
      _busy = true;
      _message = 'Redeeming Hub Credits…';
    });
    try {
      await _marks.redeem(target, id);
      _retryIds.remove(target);
      if (mounted) {
        setState(
          () => _message = '${target.label} added to your monthly allowance.',
        );
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _message = error is UagRewardException
              ? error.message
              : 'Redemption could not be confirmed. Retry to check it safely.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: UagAdService.instance,
    builder: (context, _) {
      final ads = UagAdService.instance;
      if (!UagAdMobConfig.isAndroid ||
          !ads.signedIn ||
          !ads.policy.showRewardedAds) {
        return const SizedBox.shrink();
      }
      final uid = _marks.uid;
      if (_wallet == null || uid != _walletUid) {
        _walletUid = uid;
        _wallet = _marks.watchWallet();
        _message = null;
        _retryIds.clear();
      }
      return StreamBuilder<UagRaiderMarkWallet>(
        key: ValueKey(uid),
        stream: _wallet,
        builder: (context, snapshot) {
          final wallet = snapshot.data ?? const UagRaiderMarkWallet();
          final live = UagAdMobConfig.useProductionInventory(
            productionAdsEnabled: ads.settings.productionAdsEnabled,
            forceTestAds: ads.settings.forceTestAds,
          );
          final last = wallet.lastVerifiedAt;
          final wait = last == null
              ? Duration.zero
              : UagRaiderMarkPolicy.minimumAdInterval -
                    DateTime.now().toUtc().difference(last);
          final canEarn =
              wallet.balance < UagRaiderMarkPolicy.walletCap &&
              wallet.adsToday < UagRaiderMarkPolicy.maxRewardedAdsPerDay &&
              wallet.adsThisMonth <
                  UagRaiderMarkPolicy.maxRewardedAdsPerMonth &&
              wait <= Duration.zero;
          final canRedeem =
              snapshot.hasData &&
              !snapshot.hasError &&
              wallet.balance >= UagRaiderMarkPolicy.marksPerBonusAction &&
              wallet.redemptionsThisMonth <
                  UagRaiderMarkPolicy.maxBonusRedemptionsPerMonth;
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ArcUiTokens.surfaceOverlay,
              borderRadius: BorderRadius.circular(ArcUiTokens.radiusXL),
              border: Border.all(
                color: ArcUiTokens.primaryAccent.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HUB CREDITS',
                  style: ArcUiTokens.sectionTitle(fontSize: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  '${wallet.balance} / ${UagRaiderMarkPolicy.walletCap} HC',
                  style: ArcUiTokens.cardTitle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete an optional ad to earn 1 Hub Credit. Spend 5 HC on one extra Trade, Match Raider search, Raid Intelligence unlock or Raid Planner run. Hub Credits carry over. When your 10 HC wallet is full, spend credits before earning more.',
                  style: ArcUiTokens.body(fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text(
                  '${wallet.adsToday}/3 ads today • ${wallet.adsThisMonth}/20 this month • ${wallet.redemptionsThisMonth}/4 redemptions this month',
                  style: ArcUiTokens.bodySmall(),
                ),
                if (wait > Duration.zero)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Next reward in ${(wait.inSeconds / 60).ceil()} minutes.',
                      style: ArcUiTokens.bodySmall(),
                    ),
                  ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed:
                      _busy ||
                          !ads.canUseRewardedAds ||
                          (live &&
                              (!snapshot.hasData ||
                                  snapshot.hasError ||
                                  !canEarn ||
                                  !ads.settings.rewardedSsvReady))
                      ? null
                      : _watch,
                  icon: const Icon(Icons.ondemand_video),
                  label: Text(
                    _busy
                        ? 'Please wait…'
                        : live
                        ? 'Watch ad • earn 1 Hub Credit'
                        : 'Preview Google test ad',
                  ),
                ),
                if (!live)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Test ads do not add Hub Credits.',
                      style: ArcUiTokens.bodySmall(),
                    ),
                  ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final target in UagRaiderMarkRedemptionTarget.values)
                      OutlinedButton(
                        onPressed:
                            !_busy &&
                                (canRedeem || _retryIds.containsKey(target))
                            ? () => _redeem(target)
                            : null,
                        child: Text(
                          _retryIds.containsKey(target)
                              ? 'Retry ${target.label}'
                              : '5 HC • ${target.label}',
                        ),
                      ),
                  ],
                ),
                if (snapshot.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Your wallet could not be loaded. Please try again later.',
                      style: ArcUiTokens.bodySmall(),
                    ),
                  ),
                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _message!,
                      style: ArcUiTokens.body(fontSize: 13),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    },
  );
}
