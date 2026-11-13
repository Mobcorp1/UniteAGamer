import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_tactical_page.dart';

class UagCreatorCampaignDiscountAdminPanel extends StatefulWidget {
  const UagCreatorCampaignDiscountAdminPanel({super.key});

  @override
  State<UagCreatorCampaignDiscountAdminPanel> createState() =>
      _UagCreatorCampaignDiscountAdminPanelState();
}

class _UagCreatorCampaignDiscountAdminPanelState
    extends State<UagCreatorCampaignDiscountAdminPanel> {
  final _firestore = FirebaseFirestore.instance;
  String? _busyCode;

  Future<void> _setDiscount(String code, int discountPercent) async {
    if (_busyCode != null) return;
    setState(() => _busyCode = code);
    try {
      final ref = _firestore
          .collection('uag_creator_campaign_code_requests')
          .doc(code);
      final snap = await ref.get();
      if (!snap.exists ||
          (snap.data()?['uid']?.toString().trim() ?? '').isEmpty) {
        throw StateError('Creator code is missing its owner.');
      }
      await ref.set(<String, dynamic>{
        'status': 'approved',
        'subscriberDiscountPercent': discountPercent,
        'subscriberDiscountDuration': 'once',
        'commissionEligible': discountPercent <= 25,
        'approvedByUid': FirebaseAuth.instance.currentUser?.uid ?? '',
        'approvedAt':
            snap.data()?['approvedAt'] ?? FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            discountPercent == 50
                ? '$code set to 50% first purchase — no commission.'
                : '$code set to $discountPercent% first purchase.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Creator code could not be updated.')),
      );
    } finally {
      if (mounted) setState(() => _busyCode = null);
    }
  }

  Future<void> _deactivate(String code) async {
    if (_busyCode != null) return;
    setState(() => _busyCode = code);
    try {
      await _firestore
          .collection('uag_creator_campaign_code_requests')
          .doc(code)
          .set(<String, dynamic>{
            'status': 'inactive',
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } finally {
      if (mounted) setState(() => _busyCode = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ArcTacticalPanel(
      icon: Icons.campaign_rounded,
      title: 'CREATOR CODES // ACQUISITION DISCOUNTS',
      subtitle:
          'Approve creator codes at 20% standard or 25% selected. 50% is a no-commission exception only.',
      accent: ArcUiTokens.secondaryAccent,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('uag_creator_campaign_code_requests')
            .snapshots(),
        builder: (context, snapshot) {
          final docs =
              snapshot.data?.docs.toList(growable: true) ??
              <QueryDocumentSnapshot<Map<String, dynamic>>>[];
          docs.sort((a, b) => a.id.compareTo(b.id));
          if (docs.isEmpty) {
            return Text(
              'No creator codes have been requested yet.',
              style: ArcUiTokens.bodySmall(color: ArcUiTokens.textSecondary),
            );
          }
          return Column(
            children: docs.map((doc) => _codeRow(doc)).toList(growable: false),
          );
        },
      ),
    );
  }

  Widget _codeRow(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final status = data['status']?.toString() ?? 'pending_admin_approval';
    final discount = (data['subscriberDiscountPercent'] as num?)?.toInt();
    final creator = data['creatorHandle']?.toString().trim();
    final busy = _busyCode == doc.id;
    return Container(
      margin: const EdgeInsets.only(bottom: ArcUiTokens.gapS),
      padding: ArcUiTokens.panelPadding,
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.base,
        accent: status == 'approved'
            ? ArcUiTokens.secondaryAccent
            : ArcUiTokens.warning,
        borderOpacity: 0.2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  creator == null || creator.isEmpty
                      ? doc.id
                      : '${doc.id} • $creator',
                  style: ArcUiTokens.cardTitle(color: ArcUiTokens.textPrimary),
                ),
              ),
              Text(
                discount == null
                    ? status.toUpperCase()
                    : '$discount% • ${status.toUpperCase()}',
                style: ArcUiTokens.label(color: ArcUiTokens.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: ArcUiTokens.gapS),
          Wrap(
            spacing: ArcUiTokens.gapS,
            runSpacing: ArcUiTokens.gapS,
            children: [
              OutlinedButton(
                onPressed: busy ? null : () => _setDiscount(doc.id, 20),
                child: const Text('20% STANDARD'),
              ),
              OutlinedButton(
                onPressed: busy ? null : () => _setDiscount(doc.id, 25),
                child: const Text('25% SELECTED'),
              ),
              OutlinedButton(
                onPressed: busy ? null : () => _setDiscount(doc.id, 50),
                child: const Text('50% / NO COMMISSION'),
              ),
              TextButton(
                onPressed: busy ? null : () => _deactivate(doc.id),
                child: const Text('DEACTIVATE'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
