import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/build/app_drawer.dart';
import 'package:uag_arc_raiders_hub/features/legal/screens/privacy_policy_screen.dart';
import 'package:uag_arc_raiders_hub/features/legal/screens/terms_of_use_screen.dart';
import 'package:uag_arc_raiders_hub/features/legal/screens/trader_code_of_conduct_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_help_centre_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_account_support_workspace_bar.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_companion_bottom_dock.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_section_header.dart';
import 'package:uag_arc_raiders_hub/screens/build/app_bar.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcHelpCentreArgs {
  const ArcHelpCentreArgs({this.initialCategoryId});

  final String? initialCategoryId;
}

class ArcHelpCentreScreen extends StatefulWidget {
  static const routeName = '/trading-hub/arc-raiders/help';

  const ArcHelpCentreScreen({super.key, this.initialCategoryId});

  final String? initialCategoryId;

  @override
  State<ArcHelpCentreScreen> createState() => _ArcHelpCentreScreenState();
}

class _ArcHelpCentreScreenState extends State<ArcHelpCentreScreen> {
  late ArcHelpCategory _selected = ArcHelpCentreCatalog.resolve(
    widget.initialCategoryId,
  );
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }

  List<ArcHelpCategory> get _filteredCategories {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return ArcHelpCentreCatalog.categories;

    return ArcHelpCentreCatalog.categories
        .where((category) {
          final haystack = [
            category.title,
            category.summary,
            for (final answer in category.answers) answer.question,
            for (final answer in category.answers) answer.answer,
          ].join(' ').toLowerCase();
          return haystack.contains(query);
        })
        .toList(growable: false);
  }

  void _openRoute(String? routeName) {
    if (routeName == null || routeName.isEmpty) return;
    Navigator.of(context).pushNamed(routeName);
  }

  void _openLegal(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final categories = _filteredCategories;
    final selectedInFilter = categories.any(
      (category) => category.id == _selected.id,
    );
    final active = selectedInFilter
        ? _selected
        : (categories.isEmpty ? _selected : categories.first);

    return Scaffold(
      backgroundColor: Colors.transparent,
      drawer: const AppDrawer(),
      bottomNavigationBar: const ArcCompanionBottomDock(activeLabel: 'profile'),
      appBar: const UagAppBar(
        title: 'Help Centre',
        subtitle: 'Support, safety and account guidance',
        showLogout: false,
      ),
      body: ArcRaidersScreenShell(
        useSafeArea: true,
        showAdBanner: false,
        child: ArcRaidersPageList(
          maxWidth: 1180,
          bottomPadding: 96,
          children: [
            const ArcAccountSupportWorkspaceBar(
              current: ArcAccountSupportWorkspace.help,
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: AppTheme.spaceS),
            _buildSearch(),
            const SizedBox(height: AppTheme.spaceM),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide =
                    constraints.maxWidth >= 860 &&
                    MediaQuery.textScalerOf(context).scale(16) <= 24;
                final categoryPanel = _buildCategoryGrid(categories, active);
                if (categories.isEmpty) return categoryPanel;
                final answerPanel = _buildAnswers(active);

                if (!wide) {
                  return Column(
                    children: [
                      categoryPanel,
                      const SizedBox(height: AppTheme.spaceM),
                      answerPanel,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 390, child: categoryPanel),
                    const SizedBox(width: AppTheme.spaceM),
                    Expanded(child: answerPanel),
                  ],
                );
              },
            ),
            _buildLegalStrip(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _query = value),
      style: ArcUiTokens.body(color: ArcUiTokens.textPrimary),
      decoration:
          ArcUiTokens.inputDecoration(
            labelText: 'Search Help Centre',
            hintText: 'Try “trade”, “report”, “account” or “privacy”',
            prefixIcon: Icons.search_rounded,
          ).copyWith(
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: _clearSearch,
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
    );
  }

  Widget _buildCategoryGrid(
    List<ArcHelpCategory> categories,
    ArcHelpCategory active,
  ) {
    if (categories.isEmpty) {
      return const ArcRaidersStatePanel(
        title: 'No matching topics',
        message: 'Try another keyword or clear the search.',
        icon: Icons.manage_search_rounded,
        compact: true,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 680 ? 2 : 1;
        const spacing = 8.0;
        final width =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final category in categories)
              SizedBox(
                width: width,
                child: _HelpCategoryCard(
                  category: category,
                  selected: category.id == active.id,
                  onTap: () => setState(() => _selected = category),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildAnswers(ArcHelpCategory category) {
    return _helpPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ArcSectionHeader(title: category.title, subtitle: category.summary),
          const SizedBox(height: AppTheme.spaceM),
          for (final answer in category.answers)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ExpansionTile(
                key: ValueKey('${category.id}:${answer.question}'),
                tilePadding: const EdgeInsets.symmetric(horizontal: 10),
                childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                collapsedShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ArcUiTokens.radiusM),
                  side: BorderSide(color: ArcUiTokens.borderSubtle),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ArcUiTokens.radiusM),
                  side: BorderSide(
                    color: ArcUiTokens.primaryAccent.withValues(alpha: 0.20),
                  ),
                ),
                iconColor: ArcUiTokens.primaryAccent,
                collapsedIconColor: ArcUiTokens.textTertiary,
                title: Text(
                  answer.question,
                  style: ArcUiTokens.body(
                    fontSize: 14,
                    weight: FontWeight.w600,
                  ),
                ),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      answer.answer,
                      style: ArcUiTokens.body(
                        color: ArcUiTokens.textSecondary,
                      ).copyWith(height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          if (category.routeName != null)
            Align(
              alignment: Alignment.centerLeft,
              child: _textAction(
                label: 'Open ${category.title}',
                icon: Icons.open_in_new_rounded,
                onTap: () => _openRoute(category.routeName),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegalStrip() {
    return _helpPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LEGAL & SAFETY',
            style: ArcUiTokens.label(color: ArcUiTokens.textTertiary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _textAction(
                label: 'Terms',
                icon: Icons.description_outlined,
                onTap: () => _openLegal(const TermsOfUseScreen()),
              ),
              _textAction(
                label: 'Privacy',
                icon: Icons.privacy_tip_outlined,
                onTap: () => _openLegal(const PrivacyPolicyScreen()),
              ),
              _textAction(
                label: 'Code of Conduct',
                icon: Icons.verified_user_outlined,
                onTap: () => _openLegal(const TraderCodeOfConductScreen()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _helpPanel({required Widget child}) {
    return ArcRaidersSectionCard(
      padding: const EdgeInsets.all(ArcUiTokens.gapM),
      child: child,
    );
  }

  Widget _textAction({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ArcUiTokens.textButtonStyle(),
    );
  }
}

class _HelpCategoryCard extends StatelessWidget {
  const _HelpCategoryCard({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final ArcHelpCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? ArcUiTokens.secondaryAccent
        : ArcUiTokens.primaryAccent;

    return ArcRaidersSectionCard(
      accent: color,
      padding: const EdgeInsets.all(ArcUiTokens.gapM),
      selected: selected,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline_rounded, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category.title,
                  style: ArcUiTokens.cardTitle(fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            category.summary,
            style: ArcUiTokens.bodySmall(color: ArcUiTokens.textSecondary),
          ),
        ],
      ),
    );
  }
}
