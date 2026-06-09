import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

enum ArcAdAccessTier { free, traderPro, elite }

class ArcAdBannerCard extends StatefulWidget {
  const ArcAdBannerCard({
    super.key,
    this.tier = ArcAdAccessTier.free,
    this.showForTraderPro = false,
  });

  final ArcAdAccessTier tier;
  final bool showForTraderPro;

  static bool shouldShowForTier({
    required ArcAdAccessTier tier,
    bool showForTraderPro = false,
  }) {
    switch (tier) {
      case ArcAdAccessTier.free:
        return true;
      case ArcAdAccessTier.traderPro:
        return showForTraderPro;
      case ArcAdAccessTier.elite:
        return false;
    }
  }

  @override
  State<ArcAdBannerCard> createState() => _ArcAdBannerCardState();
}

class _ArcAdBannerCardState extends State<ArcAdBannerCard> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _failed = false;

  bool get _shouldShow => ArcAdBannerCard.shouldShowForTier(
    tier: widget.tier,
    showForTraderPro: widget.showForTraderPro,
  );

  @override
  void initState() {
    super.initState();

    if (_shouldShow && !kIsWeb) {
      _loadBanner();
    }
  }

  @override
  void didUpdateWidget(covariant ArcAdBannerCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.tier == widget.tier &&
        oldWidget.showForTraderPro == widget.showForTraderPro) {
      return;
    }

    _bannerAd?.dispose();
    _bannerAd = null;
    _isLoaded = false;
    _failed = false;

    if (_shouldShow && !kIsWeb) {
      _loadBanner();
    }
  }

  void _loadBanner() {
    final banner = BannerAd(
      size: AdSize.banner,
      adUnitId: _getAdUnitId(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) return;

          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();

          if (!mounted) return;

          setState(() {
            _failed = true;
          });

          debugPrint('UAG Banner failed: $error');
        },
      ),
      request: const AdRequest(),
    );

    banner.load();
  }

  String _getAdUnitId() {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111';
    }

    return 'ca-app-pub-3940256099942544/2934735716';
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShow) {
      return const SizedBox.shrink();
    }

    if (kIsWeb) {
      return const SizedBox.shrink();
    }

    if (_isLoaded && _bannerAd != null) {
      return SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          alignment: Alignment.center,
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
          decoration: BoxDecoration(
            color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.82),
            border: Border(
              top: BorderSide(color: AppTheme.neonCyan.withValues(alpha: 0.26)),
            ),
          ),
          child: SizedBox(
            width: _bannerAd!.size.width.toDouble(),
            height: _bannerAd!.size.height.toDouble(),
            child: AdWidget(ad: _bannerAd!),
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Container(
        height: 56,
        width: double.infinity,
        alignment: Alignment.center,
        margin: const EdgeInsets.fromLTRB(10, 6, 10, 8),
        decoration: AppTheme.tradingCardDecoration(
          radius: 14,
          borderColor: (_failed ? AppTheme.neonPink : AppTheme.neonCyan)
              .withValues(alpha: 0.36),
          backgroundColor: AppTheme.cardBackgroundDeep.withValues(alpha: 0.86),
        ),
        child: Text(
          _failed ? 'AD LOAD FAILED' : 'LOADING AD...',
          style: AppTheme.bodyTextStyle(
            fontSize: 12,
            color: _failed ? AppTheme.neonPink : AppTheme.neonCyan,
            isBold: true,
          ),
        ),
      ),
    );
  }
}
