import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_commercial_economy.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_tactical_page.dart';

class UagCommercialCampaignAdminPanel extends StatefulWidget {
  const UagCommercialCampaignAdminPanel({super.key});

  @override
  State<UagCommercialCampaignAdminPanel> createState() =>
      _UagCommercialCampaignAdminPanelState();
}

class _UagCommercialCampaignAdminPanelState
    extends State<UagCommercialCampaignAdminPanel> {
  final _firestore = FirebaseFirestore.instance;
  final _codeController = TextEditingController();
  final _capController = TextEditingController(text: '100');
  final _daysController = TextEditingController(text: '30');

  UagOwnerCampaignPreset _preset = UagOwnerCampaignPreset.owner20;
  bool _busy = false;
  String _message = '';
  bool _error = false;

  @override
  void dispose() {
    _codeController.dispose();
    _capController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  void _selectPreset(UagOwnerCampaignPreset? value) {
    if (value == null) return;
    setState(() {
      _preset = value;
      _capController.text = value.defaultRedemptionCap.toString();
    });
  }

  Future<void> _save() async {
    if (_busy) return;
    final code = _codeController.text
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (code.length < 4 || code.length > 28) {
      _setMessage('Code must be 4–28 letters/numbers.', error: true);
      return;
    }
    final cap = int.tryParse(_capController.text.trim()) ?? 0;
    final validDays = int.tryParse(_daysController.text.trim()) ?? 0;
    if (cap < 1 || cap > 100000) {
      _setMessage('Redemption cap must be between 1 and 100,000.', error: true);
      return;
    }
    if (validDays < 0 || validDays > 3650) {
      _setMessage('Validity must be 0–3650 days.', error: true);
      return;
    }

    setState(() => _busy = true);
    try {
      final now = DateTime.now().toUtc();
      final adminUid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final ref = _firestore.collection('uag_discount_campaigns').doc(code);
      final existing = await ref.get();
      final redemptions =
          (existing.data()?['redemptions'] as num?)?.toInt() ?? 0;
      await ref.set(<String, dynamic>{
        'id': code,
        'code': code,
        'preset': _preset.value,
        'status': 'active',
        'discountPercent': _preset.discountPercent,
        'commissionEligible': false,
        'nextRenewalFree': _preset.nextRenewalFree,
        'stackable': false,
        'newCustomersOnly': true,
        'allowedPlanIds': _preset.allowedPlanIds,
        'maxRedemptions': cap,
        'redemptions': redemptions,
        'startsAt': Timestamp.fromDate(now),
        'endsAt': validDays == 0
            ? null
            : Timestamp.fromDate(now.add(Duration(days: validDays))),
        'createdByUid': existing.data()?['createdByUid'] ?? adminUid,
        'updatedByUid': adminUid,
        'createdAt': existing.data()?['createdAt'] ??
            FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _codeController.clear();
      _setMessage('Campaign $code is active.', error: false);
    } catch (_) {
      _setMessage('Campaign could not be saved.', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deactivate(String code) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _firestore.collection('uag_discount_campaigns').doc(code).set({
        'status': 'inactive',
        'updatedByUid': FirebaseAuth.instance.currentUser?.uid ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _setMessage('$code deactivated.', error: false);
    } catch (_) {
      _setMessage('Campaign could not be deactivated.', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _setMessage(String text, {required bool error}) {
    if (!mounted) return;
    setState(() {
      _message = text;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ArcTacticalPanel(
      icon: Icons.local_offer_rounded,
      title: 'OWNER PROMOS // DISCOUNT CODES',
      subtitle:
          'Create controlled UAG campaigns. Owner discounts never stack and never earn creator/referral commission.',
      accent: ArcUiTokens.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: ArcUiTokens.gapM,
            runSpacing: ArcUiTokens.gapM,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              SizedBox(
                width: 220,
                child: TextField(
                  controller: _codeController,
                  enabled: !_busy,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Public code',
                    hintText: 'UAGLAUNCH',
                  ),
                ),
              ),
              SizedBox(
                width: 260,
                child: DropdownButtonFormField<UagOwnerCampaignPreset>(
                  initialValue: _preset,
                  decoration: const InputDecoration(labelText: 'Campaign'),
                  items: UagOwnerCampaignPreset.values
                      .map(
                        (preset) => DropdownMenuItem(
                          value: preset,
                          child: Text(preset.label),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: _busy ? null : _selectPreset,
                ),
              ),
              SizedBox(
                width: 150,
                child: TextField(
                  controller: _capController,
                  enabled: !_busy,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Max uses'),
                ),
              ),
              SizedBox(
                width: 170,
                child: TextField(
                  controller: _daysController,
                  enabled: !_busy,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Valid days',
                    helperText: '0 = no expiry',
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: _busy ? null : _save,
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: const Text('CREATE / UPDATE'),
              ),
            ],
          ),
          const SizedBox(height: ArcUiTokens.gapS),
          Text(
            '20% default: 100 uses • 25%: 50 uses • 50%: 25 uses • Christmas: next monthly renewal free. New customers only.',
            style: ArcUiTokens.bodySmall(color: ArcUiTokens.textSecondary),
          ),
          if (_message.isNotEmpty) ...[
            const SizedBox(height: ArcUiTokens.gapM),
            Text(
              _message,
              style: ArcUiTokens.bodySmall(
                color: _error ? ArcUiTokens.danger : ArcUiTokens.success,
              ),
            ),
          ],
          const SizedBox(height: ArcUiTokens.gapM),
          _campaignList(),
        ],
      ),
    );
  }

  Widget _campaignList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore.collection('uag_discount_campaigns').snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs.toList() ??
            const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        docs.sort((a, b) => a.id.compareTo(b.id));
        if (docs.isEmpty) {
          return Text(
            'No owner campaigns created yet.',
            style: ArcUiTokens.bodySmall(color: ArcUiTokens.textSecondary),
          );
        }
        return Column(
          children: docs.map((doc) {
            final data = doc.data();
            final status = data['status']?.toString() ?? 'inactive';
            final uses = (data['redemptions'] as num?)?.toInt() ?? 0;
            final cap = (data['maxRedemptions'] as num?)?.toInt() ?? 0;
            final preset = UagOwnerCampaignPreset.fromValue(
              data['preset']?.toString(),
            );
            return Container(
              margin: const EdgeInsets.only(bottom: ArcUiTokens.gapS),
              padding: ArcUiTokens.panelPadding,
              decoration: ArcUiTokens.surfaceDecoration(
                role: ArcSurfaceRole.base,
                accent: status == 'active'
                    ? ArcUiTokens.warning
                    : ArcUiTokens.textTertiary,
                borderOpacity: 0.2,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.id,
                          style: ArcUiTokens.cardTitle(
                            color: ArcUiTokens.textPrimary,
                          ),
                        ),
                        Text(
                          '${preset.label} • $uses / $cap used • ${status.toUpperCase()}',
                          style: ArcUiTokens.bodySmall(
                            color: ArcUiTokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (status == 'active')
                    OutlinedButton(
                      onPressed: _busy ? null : () => _deactivate(doc.id),
                      child: const Text('DEACTIVATE'),
                    ),
                ],
              ),
            );
          }).toList(growable: false),
        );
      },
    );
  }
}
