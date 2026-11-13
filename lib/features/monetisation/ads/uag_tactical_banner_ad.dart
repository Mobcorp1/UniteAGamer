import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/ads/uag_ad_service.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/ads/uag_admob_config.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class UagTacticalBannerAd extends StatefulWidget {
  const UagTacticalBannerAd({
    super.key,
    this.enabled = true,
    this.placementRoute,
    this.margin = const EdgeInsets.fromLTRB(12, 6, 12, 8),
  });

  final bool enabled;
  final String? placementRoute;
  final EdgeInsetsGeometry margin;

  @override
  State<UagTacticalBannerAd> createState() => _UagTacticalBannerAdState();
}

class _UagTacticalBannerAdState extends State<UagTacticalBannerAd> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _lastEligible = false;
  String? _loadError;

  bool get _eligible {
    final service = UagAdService.instance;
    return widget.enabled && (widget.placementRoute == null
        ? service.canShowBanner
        : service.canShowBannerForPlacement(widget.placementRoute!));
  }

  @override
  void initState() {
    super.initState();
    UagAdService.instance.addListener(_onPolicyChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onPolicyChanged());
  }

  void _onPolicyChanged() {
    if (!mounted) return;
    final eligible = _eligible;
    if (eligible == _lastEligible) return;
    _lastEligible = eligible;
    if (!eligible) {
      _bannerAd?.dispose();
      setState(() {
        _bannerAd = null;
        _isLoaded = false;
        _loadError = null;
      });
      return;
    }
    _loadBanner();
  }

  @override
  void didUpdateWidget(covariant UagTacticalBannerAd oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled ||
        oldWidget.placementRoute != widget.placementRoute) {
      _lastEligible = false;
      _bannerAd?.dispose();
      _bannerAd = null;
      _isLoaded = false;
      _onPolicyChanged();
    }
  }

  void _loadBanner() {
    if (_bannerAd != null || !_eligible) return;
    _loadError = null;
    final settings = UagAdService.instance.settings;
    final banner = BannerAd(
      adUnitId: UagAdMobConfig.bannerAdUnitId(
        productionAdsEnabled: settings.productionAdsEnabled,
        forceTestAds: settings.forceTestAds,
      ),
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoaded = true;
            _loadError = null;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('UAG banner AdMob error ${error.code}: ${error.message}');
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _bannerAd = null;
            _isLoaded = false;
            _loadError = '${error.code}: ${error.message}';
          });
        },
      ),
    );
    banner.load();
  }

  @override
  void dispose() {
    UagAdService.instance.removeListener(_onPolicyChanged);
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_eligible) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: widget.margin,
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            AppTheme.neonCyan.withValues(alpha: 0.72),
            AppTheme.neonPink.withValues(alpha: 0.46),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.neonCyan.withValues(alpha: 0.16),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(15),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: _isLoaded && _bannerAd != null
              ? Center(
                  child: SizedBox(
                    width: _bannerAd!.size.width.toDouble(),
                    height: _bannerAd!.size.height.toDouble(),
                    child: AdWidget(ad: _bannerAd!),
                  ),
                )
              : (kDebugMode && _loadError != null)
                  ? Center(child: Text(
                      'ADMOB LOAD FAILED: $_loadError',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                    ))
                  : const _UagTacticalAdLoadingStrip(),
        ),
      ),
    );
  }
}

class _UagTacticalAdLoadingStrip extends StatelessWidget {
  const _UagTacticalAdLoadingStrip();

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      'TACTICAL SPONSOR LINK INITIALISING',
      style: AppTheme.neonTextStyle(
        fontSize: 13,
        color: AppTheme.neonCyan,
        isBold: true,
      ),
      textAlign: TextAlign.center,
    ),
  );
}

class UagAdAwareBottomDock extends StatelessWidget {
  const UagAdAwareBottomDock({
    super.key,
    required this.child,
    this.showAds = true,
    this.reserveAdSpace = true,
  });

  final Widget child;
  final bool showAds;
  final bool reserveAdSpace;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: UagAdService.instance,
    builder: (context, _) {
      final shouldShowAd = showAds && UagAdService.instance.canShowBanner;
      return SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (shouldShowAd)
              const Padding(
                padding: EdgeInsets.fromLTRB(10, 4, 10, 6),
                child: UagTacticalBannerAd(),
              )
            else if (reserveAdSpace)
              const SizedBox.shrink(),
            child,
          ],
        ),
      );
    },
  );
}

typedef UagEntitledAdAwareBottomDock = UagAdAwareBottomDock;
