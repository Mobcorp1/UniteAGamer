import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/widgets/theme.dart';

Future<T?> showArcDropReportCarouselPicker<T>({
  required BuildContext context,
  required String title,
  required List<T> items,
  required String Function(T item) labelBuilder,
  String Function(T item)? subtitleBuilder,
  T? initialValue,
  bool searchable = false,
}) {
  if (items.isEmpty) return Future<T?>.value(null);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppTheme.cardBackgroundDeep,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _ArcDropReportCarouselSheet<T>(
      title: title,
      items: items,
      labelBuilder: labelBuilder,
      subtitleBuilder: subtitleBuilder,
      initialValue: initialValue,
      searchable: searchable,
    ),
  );
}

class _ArcDropReportCarouselSheet<T> extends StatefulWidget {
  const _ArcDropReportCarouselSheet({
    required this.title,
    required this.items,
    required this.labelBuilder,
    required this.subtitleBuilder,
    required this.initialValue,
    required this.searchable,
  });

  final String title;
  final List<T> items;
  final String Function(T item) labelBuilder;
  final String Function(T item)? subtitleBuilder;
  final T? initialValue;
  final bool searchable;

  @override
  State<_ArcDropReportCarouselSheet<T>> createState() =>
      _ArcDropReportCarouselSheetState<T>();
}

class _ArcDropReportCarouselSheetState<T>
    extends State<_ArcDropReportCarouselSheet<T>> {
  late final PageController _pageController;
  late final TextEditingController _searchController;
  late List<T> _filteredItems;
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _filteredItems = List<T>.from(widget.items);
    _selectedIndex = widget.initialValue == null
        ? 0
        : widget.items.indexOf(widget.initialValue as T);
    if (_selectedIndex < 0) _selectedIndex = 0;
    _pageController = PageController(
      initialPage: _selectedIndex,
      viewportFraction: 0.78,
    );
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  T? get _selected => _filteredItems.isEmpty
      ? null
      : _filteredItems[_selectedIndex
            .clamp(0, _filteredItems.length - 1)
            .toInt()];

  void _updateFilter(String query) {
    final normalized = query.trim().toLowerCase();
    setState(() {
      _filteredItems = normalized.isEmpty
          ? List<T>.from(widget.items)
          : widget.items
                .where(
                  (item) => widget
                      .labelBuilder(item)
                      .toLowerCase()
                      .contains(normalized),
                )
                .toList(growable: false);
      _selectedIndex = 0;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients || _filteredItems.isEmpty) {
        return;
      }
      _pageController.jumpToPage(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    final height = (MediaQuery.sizeOf(context).height * .62)
        .clamp(430.0, 690.0)
        .toDouble();

    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: AppTheme.tradingHeading(
                      fontSize: 22,
                      color: AppTheme.neonPink,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  color: Colors.white70,
                ),
              ],
            ),
            if (widget.searchable && widget.items.length > 10) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                autofocus: false,
                style: const TextStyle(color: Colors.white),
                onChanged: _updateFilter,
                decoration:
                    AppTheme.tradingInputDecoration(
                      label: 'Search ${widget.title}',
                    ).copyWith(
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Colors.white70,
                      ),
                    ),
              ),
            ],
            const SizedBox(height: 10),
            Expanded(
              child: _filteredItems.isEmpty
                  ? const Center(
                      child: Text(
                        'No matches found.',
                        style: TextStyle(color: Colors.white60),
                      ),
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          itemCount: _filteredItems.length,
                          onPageChanged: (index) {
                            if (mounted) setState(() => _selectedIndex = index);
                          },
                          itemBuilder: (context, index) {
                            final item = _filteredItems[index];
                            final subtitle = widget.subtitleBuilder?.call(item);
                            return AnimatedBuilder(
                              animation: _pageController,
                              builder: (context, child) {
                                var distance = 0.0;
                                if (_pageController.hasClients &&
                                    _pageController.position.haveDimensions) {
                                  distance =
                                      ((_pageController.page ??
                                                  _selectedIndex.toDouble()) -
                                              index)
                                          .abs()
                                          .clamp(0.0, 1.0)
                                          .toDouble();
                                }
                                return Transform.scale(
                                  scale: 1 - (distance * .08),
                                  child: Opacity(
                                    opacity: 1 - (distance * .35),
                                    child: child,
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 12,
                                ),
                                padding: const EdgeInsets.all(18),
                                decoration: AppTheme.tradingCardDecoration(
                                  borderColor: index == _selectedIndex
                                      ? AppTheme.neonCyan
                                      : Colors.white.withValues(alpha: .12),
                                  radius: 20,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.view_carousel_rounded,
                                      color: AppTheme.neonCyan,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      widget.labelBuilder(item),
                                      textAlign: TextAlign.center,
                                      style: AppTheme.tradingHeading(
                                        fontSize: 22,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (subtitle != null &&
                                        subtitle.trim().isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        subtitle,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white60,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        Positioned(
                          left: 0,
                          child: IconButton.filledTonal(
                            tooltip: 'Previous',
                            onPressed: _selectedIndex <= 0
                                ? null
                                : () => _pageController.previousPage(
                                    duration: const Duration(milliseconds: 180),
                                    curve: Curves.easeOutCubic,
                                  ),
                            icon: const Icon(Icons.chevron_left_rounded),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          child: IconButton.filledTonal(
                            tooltip: 'Next',
                            onPressed:
                                _selectedIndex >= _filteredItems.length - 1
                                ? null
                                : () => _pageController.nextPage(
                                    duration: const Duration(milliseconds: 180),
                                    curve: Curves.easeOutCubic,
                                  ),
                            icon: const Icon(Icons.chevron_right_rounded),
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: selected == null
                    ? null
                    : () => Navigator.of(context).pop(selected),
                icon: const Icon(Icons.check_rounded),
                label: Text(
                  selected == null
                      ? 'Select'
                      : 'Use ${widget.labelBuilder(selected)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonCyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
