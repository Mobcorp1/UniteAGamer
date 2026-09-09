import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/uag_creator_commercial_policy.dart';

class UagCreatorAdminPanel extends StatefulWidget {
  const UagCreatorAdminPanel({super.key});

  @override
  State<UagCreatorAdminPanel> createState() => _UagCreatorAdminPanelState();
}

class _UagCreatorAdminPanelState extends State<UagCreatorAdminPanel> {
  final _uid = TextEditingController();
  final _essential = TextEditingController(text: '0');
  final _premium = TextEditingController(text: '0');
  bool _busy = false;
  String _message = '';

  @override
  void dispose() {
    _uid.dispose();
    _essential.dispose();
    _premium.dispose();
    super.dispose();
  }

  Future<void> _recalculate() async {
    final uid = _uid.text.trim();
    if (uid.isEmpty) return;
    final essential = int.tryParse(_essential.text.trim()) ?? 0;
    final premium = int.tryParse(_premium.text.trim()) ?? 0;
    final points = UagCreatorCommercialPolicy.pointsFor(
      essential: essential < 0
          ? 0
          : (essential > 1000000 ? 1000000 : essential),
      premium: premium < 0 ? 0 : (premium > 1000000 ? 1000000 : premium),
    );
    final level = UagCreatorCommercialPolicy.levelForPoints(points);
    final now = DateTime.now().toUtc();
    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final allocation = level?.allocation;

    setState(() {
      _busy = true;
      _message = '';
    });
    try {
      await FirebaseFirestore.instance
          .collection('uag_creator_dashboard_aggregates')
          .doc(uid)
          .set(<String, dynamic>{
            'uid': uid,
            'essentialSubscribers': essential,
            'premiumSubscribers': premium,
            'creatorPoints': points,
            'creatorLevel': level?.name ?? 'Unranked',
            'commissionBasisPoints': level?.commissionBasisPoints ?? 0,
            'communityArsenal': <String, dynamic>{
              'monthKey': monthKey,
              'essential7DayGranted': allocation?.essential7Day ?? 0,
              'essential7DayUsed': 0,
              'essentialMonthGranted': allocation?.essentialMonth ?? 0,
              'essentialMonthUsed': 0,
              'premium7DayGranted': allocation?.premium7Day ?? 0,
              'premium7DayUsed': 0,
              'premiumMonthGranted': allocation?.premiumMonth ?? 0,
              'premiumMonthUsed': 0,
              'annualPremiumGranted': _quarterlyAnnualGrant(
                now,
                allocation?.annualPremiumPerQuarter ?? 0,
              ),
              'annualPremiumUsed': 0,
              'seasonalCampaignAccess':
                  allocation?.seasonalCampaignAccess ?? false,
            },
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      if (!mounted) return;
      setState(
        () => _message =
            'Creator dashboard + $monthKey Community Arsenal refreshed.',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _message = 'Refresh failed. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static int _quarterlyAnnualGrant(DateTime now, int perQuarter) {
    if (perQuarter <= 0) return 0;
    return const <int>{1, 4, 7, 10}.contains(now.month) ? perQuarter : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: .28),
        ),
        color: Colors.black.withValues(alpha: .16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Creator Programme Control',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Admin/dev tool: refresh active paid counts, Creator Points, commission level and the current monthly Community Arsenal. No payouts are moved here.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _uid,
            decoration: const InputDecoration(labelText: 'Creator UID'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _essential,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Active Essential',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _premium,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Active Premium',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _busy ? null : _recalculate,
            icon: const Icon(Icons.refresh),
            label: Text(_busy ? 'REFRESHING…' : 'REFRESH CREATOR MONTH'),
          ),
          if (_message.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(_message),
          ],
        ],
      ),
    );
  }
}
