import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_commercial_economy.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/services/uag_checkout_service.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_tactical_page.dart';

class UagCommercialOffersPanel extends StatefulWidget {
  const UagCommercialOffersPanel({
    super.key,
    required this.onPromotionCodeChanged,
  });

  final ValueChanged<String> onPromotionCodeChanged;

  @override
  State<UagCommercialOffersPanel> createState() =>
      _UagCommercialOffersPanelState();
}

class _UagCommercialOffersPanelState extends State<UagCommercialOffersPanel> {
  final _promotionController = TextEditingController();
  final _giftController = TextEditingController();
  final _checkout = UagCheckoutService();

  bool _giftBusy = false;
  String _message = '';
  bool _messageIsError = false;

  @override
  void dispose() {
    _promotionController.dispose();
    _giftController.dispose();
    super.dispose();
  }

  String _normaliseCode(String value) => value
      .trim()
      .toUpperCase()
      .replaceAll(RegExp(r'[^A-Z0-9]'), '');

  void _promotionChanged(String value) {
    widget.onPromotionCodeChanged(_normaliseCode(value));
  }

  Future<void> _buyGift() async {
    if (_giftBusy) return;
    setState(() {
      _giftBusy = true;
      _message = '';
    });
    try {
      await _checkout.startCheckout(planId: 'gift_premium_month');
    } on UagCheckoutException catch (error) {
      _setMessage(error.message, error: true);
    } catch (_) {
      _setMessage('Gift checkout could not be opened.', error: true);
    } finally {
      if (mounted) setState(() => _giftBusy = false);
    }
  }

  Future<void> _redeemGift() async {
    if (_giftBusy) return;
    final code = _normaliseCode(_giftController.text);
    if (code.isEmpty) {
      _setMessage('Enter the Premium gift code first.', error: true);
      return;
    }
    setState(() {
      _giftBusy = true;
      _message = '';
    });
    try {
      final result = await _checkout.redeemGift(code);
      if (!mounted) return;
      _giftController.clear();
      final expiry = result.expiresAt;
      final expiryText = expiry == null
          ? ''
          : ' Premium is active until ${_dateLabel(expiry.toLocal())}.';
      _setMessage(
        result.alreadyRedeemed
            ? 'This gift was already redeemed on your account.$expiryText'
            : 'Premium gift activated.$expiryText',
        error: false,
      );
    } on UagCheckoutException catch (error) {
      _setMessage(error.message, error: true);
    } catch (_) {
      _setMessage('Gift could not be redeemed. Try again.', error: true);
    } finally {
      if (mounted) setState(() => _giftBusy = false);
    }
  }

  void _setMessage(String value, {required bool error}) {
    if (!mounted) return;
    setState(() {
      _message = value;
      _messageIsError = error;
    });
  }

  String _dateLabel(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';

  @override
  Widget build(BuildContext context) {
    return ArcTacticalPanel(
      icon: Icons.card_giftcard_rounded,
      title: 'PROMOS // GIFT PREMIUM',
      subtitle:
          'Use one UAG, creator or referral code at checkout, or gift 30 days of Premium to another Raider.',
      accent: ArcUiTokens.secondaryAccent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 820;
          final children = <Widget>[
            _promotionCard(),
            _giftCard(),
          ];
          if (!wide) {
            return Column(
              children: [
                children.first,
                const SizedBox(height: ArcUiTokens.gapM),
                children.last,
                if (_message.isNotEmpty) ...[
                  const SizedBox(height: ArcUiTokens.gapM),
                  _messagePanel(),
                ],
                const SizedBox(height: ArcUiTokens.gapM),
                _purchasedGiftCodes(),
              ],
            );
          }
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: children.first),
                  const SizedBox(width: ArcUiTokens.gapM),
                  Expanded(child: children.last),
                ],
              ),
              if (_message.isNotEmpty) ...[
                const SizedBox(height: ArcUiTokens.gapM),
                _messagePanel(),
              ],
              const SizedBox(height: ArcUiTokens.gapM),
              _purchasedGiftCodes(),
            ],
          );
        },
      ),
    );
  }

  Widget _promotionCard() {
    return _innerCard(
      title: 'PROMO / CREATOR CODE',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _promotionController,
            textCapitalization: TextCapitalization.characters,
            onChanged: _promotionChanged,
            decoration: const InputDecoration(
              labelText: 'Code',
              hintText: 'e.g. CREATOR20',
              prefixIcon: Icon(Icons.local_offer_outlined),
            ),
          ),
          const SizedBox(height: ArcUiTokens.gapS),
          Text(
            'The code is verified by UAG when you select a paid plan. Only one promotion can apply to a purchase; discounts never stack.',
            style: ArcUiTokens.bodySmall(color: ArcUiTokens.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _giftCard() {
    return _innerCard(
      title: 'GIFT 30 DAYS PREMIUM',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '£${(UagCommercialEconomy.premiumGiftPricePence / 100).toStringAsFixed(2)} one-off',
            style: ArcUiTokens.numeric(
              fontSize: 24,
              color: ArcUiTokens.secondaryAccent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'No auto-renewal. The buyer cannot redeem their own gift. The recipient must be Free/lapsed and has 30 days to claim it.',
            style: ArcUiTokens.bodySmall(color: ArcUiTokens.textSecondary),
          ),
          const SizedBox(height: ArcUiTokens.gapM),
          FilledButton.icon(
            onPressed: _giftBusy ? null : _buyGift,
            icon: const Icon(Icons.card_giftcard_rounded),
            label: const Text('BUY A PREMIUM GIFT'),
          ),
          const SizedBox(height: ArcUiTokens.gapM),
          TextField(
            controller: _giftController,
            enabled: !_giftBusy,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Redeem gift code',
              prefixIcon: Icon(Icons.redeem_rounded),
            ),
          ),
          const SizedBox(height: ArcUiTokens.gapS),
          OutlinedButton.icon(
            onPressed: _giftBusy ? null : _redeemGift,
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: const Text('REDEEM'),
          ),
        ],
      ),
    );
  }

  Widget _purchasedGiftCodes() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('uag_gift_codes')
          .where('purchaserUid', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs.toList(growable: true) ??
            <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        docs.sort((a, b) {
          final aMillis = _timestampMillis(a.data()['paidAt']);
          final bMillis = _timestampMillis(b.data()['paidAt']);
          return bMillis.compareTo(aMillis);
        });
        if (docs.isEmpty) return const SizedBox.shrink();

        return _innerCard(
          title: 'YOUR PURCHASED GIFTS',
          child: Column(
            children: docs.take(10).map((doc) {
              final data = doc.data();
              final code = data['code']?.toString() ?? doc.id;
              final status = data['status']?.toString() ?? 'active';
              final active = status == 'active';
              return Padding(
                padding: const EdgeInsets.only(bottom: ArcUiTokens.gapS),
                child: Row(
                  children: [
                    Icon(
                      active
                          ? Icons.card_giftcard_rounded
                          : Icons.check_circle_outline_rounded,
                      color: active
                          ? ArcUiTokens.secondaryAccent
                          : ArcUiTokens.textTertiary,
                    ),
                    const SizedBox(width: ArcUiTokens.gapS),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(
                            code,
                            style: ArcUiTokens.body(
                              weight: FontWeight.w700,
                              color: ArcUiTokens.textPrimary,
                            ),
                          ),
                          Text(
                            active
                                ? 'Ready to send — recipient claims the code'
                                : 'Redeemed',
                            style: ArcUiTokens.bodySmall(
                              color: ArcUiTokens.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (active)
                      IconButton(
                        tooltip: 'Copy gift code',
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: code));
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Gift code copied.'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded),
                      ),
                  ],
                ),
              );
            }).toList(growable: false),
          ),
        );
      },
    );
  }

  Widget _innerCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: ArcUiTokens.panelPadding,
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.base,
        accent: ArcUiTokens.secondaryAccent,
        borderOpacity: 0.2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: ArcUiTokens.cardTitle(color: ArcUiTokens.textPrimary),
          ),
          const SizedBox(height: ArcUiTokens.gapM),
          child,
        ],
      ),
    );
  }

  Widget _messagePanel() {
    final accent =
        _messageIsError ? ArcUiTokens.danger : ArcUiTokens.success;
    return Container(
      width: double.infinity,
      padding: ArcUiTokens.panelPadding,
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.base,
        accent: accent,
        borderOpacity: 0.3,
      ),
      child: Text(_message, style: ArcUiTokens.bodySmall(color: accent)),
    );
  }

  int _timestampMillis(dynamic value) {
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    if (value is DateTime) return value.millisecondsSinceEpoch;
    return DateTime.tryParse(value?.toString() ?? '')
            ?.millisecondsSinceEpoch ??
        0;
  }
}
