import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/uag_creator_reward_models.dart';
import '../repositories/uag_creator_reward_repository.dart';
import '../repositories/uag_creator_reward_activation_repository.dart';

class UagCreatorRewardAdminPanel extends StatefulWidget {
  const UagCreatorRewardAdminPanel({super.key});

  @override
  State<UagCreatorRewardAdminPanel> createState() =>
      _UagCreatorRewardAdminPanelState();
}

class _UagCreatorRewardAdminPanelState
    extends State<UagCreatorRewardAdminPanel> {
  final _repository = UagCreatorRewardAdminRepository();
  final _activationRepository = UagCreatorRewardActivationRepository();
  bool _busy = false;
  String _message = '';

  Future<void> _run(Future<void> Function() action, String success) async {
    setState(() {
      _busy = true;
      _message = '';
    });
    try {
      await action();
      if (!mounted) return;
      setState(() => _message = success);
    } catch (_) {
      if (!mounted) return;
      setState(() => _message = 'Could not update creator reward. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.secondary.withValues(alpha: .28),
        ),
        color: Colors.black.withValues(alpha: .16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Creator Validation & Redemption',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Admin/dev control for creator code approval, referral validation and single-use Community Arsenal redemption. Validated Community Arsenal rewards activate access atomically. The entitlement bridge remains available only for legacy/backfill claims.',
          ),
          const SizedBox(height: 14),
          _codeRequests(),
          const Divider(height: 28),
          _usageClaims(),
          if (_message.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(_message),
          ],
        ],
      ),
    );
  }

  Widget _codeRequests() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _repository.watchGiveawayCodeRequests(),
      builder: (context, snapshot) {
        final docs =
            snapshot.data?.docs ??
            const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        final pending = docs
            .where((doc) => doc.data()['status'] == 'pending_admin_approval')
            .take(30)
            .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PENDING CREATOR CODES',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            if (pending.isEmpty)
              const Text('No creator codes awaiting approval.'),
            for (final doc in pending) _codeRow(doc),
          ],
        );
      },
    );
  }

  Widget _codeRow(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final isGiveaway = data['requestType'] == 'community_giveaway';
    final reward = UagCreatorRewardType.fromValue(
      data['rewardType']?.toString(),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${doc.id} • ${isGiveaway ? (reward?.label ?? 'Giveaway') : 'Referral code'} • ${data['uid'] ?? ''}',
            ),
          ),
          TextButton(
            onPressed: _busy
                ? null
                : () => _run(
                    () => isGiveaway
                        ? _repository.issueGiveawayCode(doc.id)
                        : _repository.approveCreatorReferralCode(doc.id),
                    isGiveaway
                        ? 'Giveaway code issued.'
                        : 'Creator referral code activated.',
                  ),
            child: const Text('APPROVE'),
          ),
          TextButton(
            onPressed: _busy
                ? null
                : () => _run(
                    () => isGiveaway
                        ? _repository.rejectGiveawayCode(doc.id)
                        : doc.reference.update(<String, dynamic>{
                            'status': 'rejected',
                            'updatedAt': FieldValue.serverTimestamp(),
                          }),
                    'Creator code rejected.',
                  ),
            child: const Text('REJECT'),
          ),
        ],
      ),
    );
  }

  Widget _usageClaims() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _repository.watchUsageClaims(),
      builder: (context, snapshot) {
        final docs =
            snapshot.data?.docs ??
            const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        final referrals = docs
            .where(
              (doc) =>
                  doc.id == 'creator_attribution' &&
                  doc.data()['status'] == 'pending_validation',
            )
            .take(20)
            .toList();
        final redemptions = docs
            .where(
              (doc) =>
                  doc.data()['recordType'] == 'creator_giveaway_redemption' &&
                  doc.data()['status'] == 'pending_validation',
            )
            .take(20)
            .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PENDING REFERRAL ATTRIBUTION',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            if (referrals.isEmpty)
              const Text('No referral claims awaiting validation.'),
            for (final doc in referrals) _claimRow(doc, referral: true),
            const SizedBox(height: 14),
            const Text(
              'PENDING GIVEAWAY REDEMPTIONS',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            if (redemptions.isEmpty)
              const Text('No giveaway redemptions awaiting validation.'),
            for (final doc in redemptions) _claimRow(doc, referral: false),
          ],
        );
      },
    );
  }

  Widget _claimRow(
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    required bool referral,
  }) {
    final data = doc.data();
    final userUid = doc.reference.parent.parent?.id ?? '';
    final label = referral
        ? '${data['creatorCode'] ?? ''} • creator ${data['creatorUid'] ?? ''} • user $userUid'
        : '${data['code'] ?? ''} • user $userUid';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          TextButton(
            onPressed: _busy
                ? null
                : () => _run(
                    () => referral
                        ? _repository.validateReferralClaim(doc.reference)
                        : _activationRepository
                              .validateAndActivate(doc.reference)
                              .then((_) {}),
                    referral
                        ? 'Referral attribution validated.'
                        : 'Giveaway validated and reward access activated.',
                  ),
            child: const Text('VALIDATE'),
          ),
          TextButton(
            onPressed: _busy
                ? null
                : () => _run(
                    () => referral
                        ? _repository.rejectReferralClaim(doc.reference)
                        : _repository.rejectGiveawayRedemption(doc.reference),
                    'Claim rejected.',
                  ),
            child: const Text('REJECT'),
          ),
        ],
      ),
    );
  }
}
