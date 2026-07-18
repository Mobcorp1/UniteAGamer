import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/build/app_drawer.dart';
import 'package:uag_arc_raiders_hub/features/legal/screens/privacy_policy_screen.dart';
import 'package:uag_arc_raiders_hub/features/legal/screens/terms_of_use_screen.dart';
import 'package:uag_arc_raiders_hub/features/legal/screens/trader_code_of_conduct_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_help_centre_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
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
  String _query = '';

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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(
          'Help Centre',
          style: AppTheme.tradingHeading(
            fontSize: 24,
            color: AppTheme.neonCyan,
          ),
        ),
      ),
      body: ArcRaidersScreenShell(
        useSafeArea: true,
        showAdBanner: false,
        child: ArcRaidersPageList(
          maxWidth: 1180,
          bottomPadding: 96,
          children: [
            _buildSearch(),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 860;
                final categoryPanel = _buildCategoryGrid(categories, active);
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
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: AppTheme.tradingCardDecoration(
        borderColor: AppTheme.neonCyan.withValues(alpha: 0.24),
      ),
      child: TextField(
        onChanged: (value) => setState(() => _query = value),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded),
          hintText: 'Search Help Centre',
          hintStyle: const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: Colors.black.withValues(alpha: 0.22),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppTheme.neonCyan.withValues(alpha: 0.18),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppTheme.neonCyan.withValues(alpha: 0.18),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppTheme.neonCyan),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(
    List<ArcHelpCategory> categories,
    ArcHelpCategory active,
  ) {
    if (categories.isEmpty) {
      return _helpPanel(
        child: const Text(
          'No help topics match that search.',
          style: TextStyle(color: Colors.white70, height: 1.35),
        ),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  category.title,
                  style: AppTheme.tradingHeading(
                    fontSize: 24,
                    color: AppTheme.neonCyan,
                  ),
                ),
              ),
              if (category.routeName != null)
                IconButton(
                  tooltip: 'Open ${category.title}',
                  onPressed: () => _openRoute(category.routeName),
                  icon: const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppTheme.neonCyan,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            category.summary,
            style: const TextStyle(color: Colors.white70, height: 1.35),
          ),
          const SizedBox(height: AppTheme.spaceM),
          for (final answer in category.answers)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 10),
                childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                collapsedShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: AppTheme.neonCyan.withValues(alpha: 0.20),
                  ),
                ),
                iconColor: AppTheme.neonCyan,
                collapsedIconColor: Colors.white54,
                title: Text(
                  answer.question,
                  style: AppTheme.bodyTextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    isBold: true,
                  ),
                ),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      answer.answer,
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.4,
                      ),
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
      child: Wrap(
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
    );
  }

  Widget _helpPanel({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: AppTheme.tradingCardDecoration(
        borderColor: AppTheme.neonCyan.withValues(alpha: 0.18),
      ),
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
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.neonCyan,
        side: BorderSide(color: AppTheme.neonCyan.withValues(alpha: 0.42)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
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
    final color = selected ? AppTheme.neonPink : AppTheme.neonCyan;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: AppTheme.tradingCardDecoration(
          radius: 16,
          borderColor: color.withValues(alpha: selected ? 0.48 : 0.18),
          backgroundColor: selected
              ? color.withValues(alpha: 0.10)
              : AppTheme.cardBackgroundDeep.withValues(alpha: 0.88),
        ),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodyTextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      isBold: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              category.summary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
