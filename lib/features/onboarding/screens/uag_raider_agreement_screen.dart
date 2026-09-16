import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/legal/models/uag_policy_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_account_journey_bar.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';

class UagRaiderAgreementScreen extends StatefulWidget {
  const UagRaiderAgreementScreen({super.key});

  static const agreementVersion = 5;
  static const agreementVersionLabel = '2026-09-05-v5';

  @override
  State<UagRaiderAgreementScreen> createState() =>
      _UagRaiderAgreementScreenState();
}

class _UagRaiderAgreementScreenState extends State<UagRaiderAgreementScreen> {
  static const _policyIds = <String>[
    'trader_code_of_conduct',
    'terms_of_use',
    'privacy_policy',
    'subscriptions_ads_policy',
    'referrals_creator_policy',
    'community_intel_policy',
    'moderation_appeals_policy',
    'user_content_policy',
    'fan_project_notice',
  ];

  final ScrollController _scrollController = ScrollController();
  bool _reachedEnd = false;
  bool _confirmedRead = false;

  List<UagPolicyDocument> get _documents =>
      _policyIds.map(UagPolicyCatalog.byId).toList(growable: false);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateReachedEnd);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateReachedEnd());
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_updateReachedEnd)
      ..dispose();
    super.dispose();
  }

  void _updateReachedEnd() {
    if (!mounted || !_scrollController.hasClients || _reachedEnd) return;
    if (_scrollController.position.extentAfter <= 24) {
      setState(() => _reachedEnd = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05090E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF07111A),
        foregroundColor: Colors.white,
        title: const Text('RAIDER AGREEMENT'),
      ),
      body: ArcRaidersScreenShell(
        showAdBanner: false,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                child: const ArcAccountJourneyBar(
                  stage: ArcAccountJourneyStage.onboarding,
                  compact: true,
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF07111A),
                  border: Border(
                    bottom: BorderSide(
                      color: ArcUiTokens.primaryAccent.withValues(alpha: 0.42),
                    ),
                  ),
                ),
                child: Text(
                  'Read the full agreement. The confirmation unlocks only after you reach the bottom.',
                  style: ArcUiTokens.body(
                    fontSize: 13,
                    color: ArcUiTokens.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
                    children: [
                      Text(
                        'UAG RAIDER AGREEMENT',
                        style: ArcUiTokens.sectionTitle(
                          fontSize: 24,
                          color: ArcUiTokens.primaryAccent,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Agreement ${UagRaiderAgreementScreen.agreementVersionLabel}',
                        style: ArcUiTokens.bodySmall(),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        UagPolicyCatalog.legalReviewNotice,
                        style: ArcUiTokens.bodySmall(
                          color: ArcUiTokens.warning,
                        ),
                      ),
                      const SizedBox(height: 18),
                      for (final document in _documents) ...[
                        _AgreementSection(document: document),
                        const SizedBox(height: 12),
                      ],
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF07111A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _reachedEnd
                                ? ArcUiTokens.primaryAccent.withValues(
                                    alpha: 0.55,
                                  )
                                : Colors.white24,
                          ),
                        ),
                        child: CheckboxListTile(
                          value: _confirmedRead,
                          onChanged: _reachedEnd
                              ? (value) => setState(
                                  () => _confirmedRead = value == true,
                                )
                              : null,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: ArcUiTokens.secondaryAccent,
                          title: const Text(
                            'I have read and agree to the UAG Raider Agreement.',
                          ),
                          subtitle: _reachedEnd
                              ? const Text(
                                  'You reached the end of the agreement.',
                                )
                              : const Text(
                                  'Scroll to the bottom before confirming.',
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _reachedEnd && _confirmedRead
                        ? () => Navigator.of(context).pop(true)
                        : null,
                    icon: const Icon(Icons.verified_user_outlined),
                    label: const Text('ACCEPT & RETURN'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgreementSection extends StatelessWidget {
  const _AgreementSection({required this.document});

  final UagPolicyDocument document;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF09131C),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ArcUiTokens.primaryAccent.withValues(alpha: 0.26),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            document.title.toUpperCase(),
            style: ArcUiTokens.sectionTitle(fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Policy v${document.version} - effective ${document.effectiveDate}',
            style: ArcUiTokens.bodySmall(color: ArcUiTokens.textTertiary),
          ),
          const SizedBox(height: 9),
          Text(
            document.body,
            style: ArcUiTokens.body(
              fontSize: 14,
              color: ArcUiTokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
