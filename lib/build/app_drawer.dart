import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/feature_access_gate.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_compact_navigation_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_match_rider_invite.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_user_personalisation_profile.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/trading_notification.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_match_rider_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_user_personalisation_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/trading_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_notifications_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/screens/build/auth/auth_landing_screen.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';
import 'package:uag_arc_raiders_hub/widgets/uag_drawer_nav_tile.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key, this.drawerWidth = 276});

  final double drawerWidth;

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer>
    with SingleTickerProviderStateMixin {
  final ArcBlueprintRepository _blueprintRepository = ArcBlueprintRepository();
  final TradingRepository _tradingRepository = TradingRepository();
  final ArcMatchRiderRepository _matchRiderRepository =
      ArcMatchRiderRepository();
  final ArcUserPersonalisationRepository _personalisationRepository =
      ArcUserPersonalisationRepository();

  late final AnimationController _controller;
  late final Animation<Color?> _colorAnimation;
  late final Stream<Map<String, ArcBlueprintState>> _blueprintStatesStream =
      _blueprintRepository.watchMyBlueprintStates();
  late final Stream<List<TradingNotification>> _notificationsStream =
      _tradingRepository.watchNotifications();
  late final Stream<List<ArcMatchRiderInvite>> _incomingInvitesStream =
      _matchRiderRepository.watchIncomingInvites();
  late final Stream<ArcUserPersonalisationProfile> _personalisationStream =
      _personalisationRepository.watchProfile();
  StreamSubscription<User?>? _authSubscription;
  bool _isAdmin = false;
  bool _isAdminResolved = false;
  String? _expandedGroup;
  ArcUserPersonalisationProfile _cachedPersonalisation =
      ArcUserPersonalisationProfile.defaults;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    _colorAnimation = ColorTween(
      begin: AppTheme.neonCyan,
      end: AppTheme.neonPink,
    ).animate(_controller);
    unawaited(_personalisationRepository.migrateLegacyIfNeeded());

    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;
      setState(() {
        _isAdminResolved = false;
        _isAdmin = false;
      });
      if (user?.uid == null || user!.uid.isEmpty) return;
      _resolveAdminStatus(user.uid);
    });
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _resolveAdminStatus(currentUser.uid);
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _resolveAdminStatus(String uid) async {
    if (!mounted) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (!mounted) return;
    final data = snapshot.data() ?? const <String, dynamic>{};
    setState(() {
      _isAdminResolved = true;
      _isAdmin = data['isAdmin'] == true || data['isDev'] == true;
    });
  }

  Future<void> _logout(BuildContext context) async {
    Navigator.of(context).pop();
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AuthLandingScreen.routeName, (_) => false);
  }

  Future<void> _openItem(
    BuildContext context,
    ArcCompactNavigationItem item,
  ) async {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    Navigator.of(context).pop();

    if (item.accessFlag != null) {
      final availability = await FeatureAccess.getAvailability(
        item.accessFlag!,
      );
      if (!context.mounted) return;
      if (availability.isComingSoon) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => FeatureComingSoonScreen(title: item.label),
          ),
        );
        return;
      }
      if (!availability.isLive) {
        await FeatureAccess.showLockedDialog(context, title: item.label);
        return;
      }
    }

    if (!context.mounted || item.isSelected(currentRoute)) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(item.routeName, (route) => route.isFirst);
  }

  Widget _buildDrawerHeader(Color dynamicColor) {
    return SafeArea(
      minimum: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compactBrand = constraints.maxWidth < 340;
            final brandStyle = ArcUiTokens.pageTitle(
              fontSize: compactBrand ? 14.5 : 17,
              color: ArcUiTokens.primaryAccent,
            ).copyWith(height: 1.0);

            return Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: dynamicColor.withValues(alpha: 0.18),
                        blurRadius: 12,
                      ),
                    ],
                    borderRadius: BorderRadius.circular(ArcUiTokens.radiusM),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(ArcUiTokens.radiusM),
                    child: Image.asset(
                      'assets/icon/uag_traders_icon_transparent.webp',
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: compactBrand
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'UAG ARC',
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              softWrap: false,
                              style: brandStyle,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'RAIDERS HUB',
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              softWrap: false,
                              style: brandStyle.copyWith(
                                color: ArcUiTokens.textPrimary,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'UAG ARC RAIDERS HUB',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: brandStyle,
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNavigationList(String? currentRoute) {
    return StreamBuilder<ArcUserPersonalisationProfile>(
      stream: _personalisationStream,
      builder: (context, personalisationSnapshot) {
        if (personalisationSnapshot.hasData) {
          _cachedPersonalisation = personalisationSnapshot.data!;
        }
        final navigationGroups =
            ArcCompactNavigationCatalog.groupsForPersonalisation(
              _cachedPersonalisation,
            );
        final activeGroup = _activeGroupLabel(navigationGroups, currentRoute);
        final expandedGroup = _expandedGroup ?? activeGroup ?? 'DISCOVER & RUN';
        final accessFlags = <String>{
          for (final group in navigationGroups)
            for (final item in group.items)
              if (item.accessFlag != null) item.accessFlag!,
          for (final group in navigationGroups)
            for (final item in group.items) ...item.visibilityAccessFlags,
        };
        return StreamBuilder<Map<String, FeatureAvailability>>(
          stream: FeatureAccess.watchAvailabilityMap(accessFlags),
          builder: (context, availabilitySnapshot) {
            final availabilityByFlag =
                availabilitySnapshot.data ??
                const <String, FeatureAvailability>{};
            return StreamBuilder<Map<String, ArcBlueprintState>>(
              stream: _blueprintStatesStream,
              builder: (context, blueprintSnapshot) {
                return StreamBuilder<List<TradingNotification>>(
                  stream: _notificationsStream,
                  builder: (context, notificationSnapshot) {
                    return StreamBuilder<List<ArcMatchRiderInvite>>(
                      stream: _incomingInvitesStream,
                      builder: (context, inviteSnapshot) {
                        final counts = ArcDrawerBadgeEngine.fromLiveData(
                          blueprintStates:
                              blueprintSnapshot.data?.values ??
                              const <ArcBlueprintState>[],
                          notifications:
                              notificationSnapshot.data ??
                              const <TradingNotification>[],
                          incomingInvites:
                              inviteSnapshot.data ??
                              const <ArcMatchRiderInvite>[],
                        );

                        return ListView(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.paddingOf(context).bottom + 12,
                          ),
                          children: [
                            _CollapsibleDrawerGroup(
                              label: 'COMMUNICATIONS',
                              expanded: expandedGroup == 'COMMUNICATIONS',
                              onToggle: () => setState(
                                () => _expandedGroup =
                                    _expandedGroup == 'COMMUNICATIONS'
                                    ? null
                                    : 'COMMUNICATIONS',
                              ),
                              children: [
                                UagDrawerNavTile(
                                  title: 'Communications Centre',
                                  icon: Icons.notifications_active_outlined,
                                  selected:
                                      currentRoute ==
                                      TradingNotificationsScreen.routeName,
                                  badgeCount: counts.tradingHub,
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    if (currentRoute !=
                                        TradingNotificationsScreen.routeName) {
                                      Navigator.of(
                                        context,
                                      ).pushNamedAndRemoveUntil(
                                        TradingNotificationsScreen.routeName,
                                        (route) => route.isFirst,
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                            for (final group in navigationGroups)
                              _CollapsibleDrawerGroup(
                                label: group.label,
                                expanded: expandedGroup == group.label,
                                onToggle: () => setState(
                                  () => _expandedGroup =
                                      _expandedGroup == group.label
                                      ? null
                                      : group.label,
                                ),
                                children: [
                                  for (final item in group.items.where(
                                    (item) => !_availabilityForItem(
                                      item,
                                      availabilityByFlag,
                                    ).isHidden,
                                  ))
                                    UagDrawerNavTile(
                                      title: item.label,
                                      icon: item.icon,
                                      selected: item.isSelected(currentRoute),
                                      badgeCount: counts.countFor(
                                        item.badgeTarget,
                                      ),
                                      onTap: () => _openItem(context, item),
                                    ),
                                ],
                              ),
                            if (_isAdminResolved && _isAdmin)
                              _CollapsibleDrawerGroup(
                                label: 'ADMIN',
                                expanded: expandedGroup == 'ADMIN',
                                onToggle: () => setState(
                                  () =>
                                      _expandedGroup = _expandedGroup == 'ADMIN'
                                      ? null
                                      : 'ADMIN',
                                ),
                                children: [
                                  UagDrawerNavTile(
                                    title: 'Admin Console',
                                    icon: Icons.admin_panel_settings_outlined,
                                    selected: currentRoute == '/admin-console',
                                    onTap: () {
                                      Navigator.of(context).pop();
                                      Navigator.of(
                                        context,
                                      ).pushNamed('/admin-console');
                                    },
                                  ),
                                ],
                              ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  String? _activeGroupLabel(
    List<ArcCompactNavigationGroup> groups,
    String? currentRoute,
  ) {
    if (currentRoute == null || currentRoute.isEmpty) return null;
    if (currentRoute == TradingNotificationsScreen.routeName) {
      return 'COMMUNICATIONS';
    }
    if (currentRoute == '/admin-console') return 'ADMIN';
    for (final group in groups) {
      if (group.items.any((item) => item.isSelected(currentRoute))) {
        return group.label;
      }
    }
    return null;
  }

  FeatureAvailability _availabilityForItem(
    ArcCompactNavigationItem item,
    Map<String, FeatureAvailability> availabilityByFlag,
  ) {
    final flag = item.accessFlag;
    if (flag == null && item.visibilityAccessFlags.isEmpty) {
      return FeatureAvailability.live;
    }
    if (flag == null) {
      final visibleStates = item.visibilityAccessFlags
          .map(
            (visibilityFlag) =>
                availabilityByFlag[visibilityFlag] ??
                FeatureAvailability.hidden,
          )
          .toList(growable: false);
      if (visibleStates.any((availability) => availability.isLive)) {
        return FeatureAvailability.live;
      }
      if (visibleStates.any((availability) => availability.isComingSoon)) {
        return FeatureAvailability.comingSoon;
      }
      return FeatureAvailability.hidden;
    }
    return availabilityByFlag[flag] ?? FeatureAvailability.live;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null;
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final showAdminLoading = user != null && !_isAdminResolved;
    final screenWidth = MediaQuery.sizeOf(context).width;
    // Keep the mobile drawer compact and content-led instead of allowing it
    // to dominate the Sony-width layout. 276px comfortably fits the longest
    // production navigation labels while preserving useful page context.
    var drawerWidth = widget.drawerWidth.clamp(248.0, 276.0);
    if (screenWidth < drawerWidth + 64) {
      final constrainedWidth = screenWidth - 48;
      drawerWidth = constrainedWidth < 248
          ? screenWidth * 0.82
          : constrainedWidth.clamp(248.0, 276.0);
    }

    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        final dynamicColor = _colorAnimation.value ?? Colors.white;
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: drawerWidth,
            decoration: BoxDecoration(
              color: ArcUiTokens.background.withValues(alpha: 0.96),
              border: Border(
                right: BorderSide(color: dynamicColor.withValues(alpha: 0.32)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.34),
                  blurRadius: 18,
                  offset: const Offset(10, 0),
                ),
              ],
            ),
            child: Drawer(
              child: Column(
                children: [
                  _buildDrawerHeader(dynamicColor),
                  Divider(
                    color: dynamicColor.withValues(alpha: 0.22),
                    thickness: 1,
                  ),
                  Expanded(child: _buildNavigationList(currentRoute)),
                  if (showAdminLoading)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      child: Text(
                        'Resolving access...',
                        style: ArcUiTokens.bodySmall(
                          color: ArcUiTokens.textTertiary,
                        ).copyWith(fontSize: 12),
                      ),
                    ),
                  if (isLoggedIn)
                    SafeArea(
                      top: false,
                      minimum: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _logout(context),
                          icon: const Icon(Icons.logout),
                          label: const Text('Logout'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.neonPink,
                            side: const BorderSide(color: AppTheme.neonPink),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CollapsibleDrawerGroup extends StatelessWidget {
  const _CollapsibleDrawerGroup({
    required this.label,
    required this.expanded,
    required this.onToggle,
    required this.children,
  });
  final String label;
  final bool expanded;
  final VoidCallback onToggle;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(ArcUiTokens.radiusS),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          margin: const EdgeInsets.fromLTRB(8, 2, 8, 1),
          padding: const EdgeInsets.fromLTRB(10, 8, 8, 7),
          decoration: BoxDecoration(
            color: expanded
                ? ArcUiTokens.surfacePanel.withValues(alpha: 0.72)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(ArcUiTokens.radiusS),
            border: Border.all(
              color: expanded
                  ? ArcUiTokens.secondaryAccent.withValues(alpha: 0.26)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: ArcUiTokens.label(
                    color: expanded
                        ? ArcUiTokens.secondaryAccent
                        : ArcUiTokens.primaryAccent,
                  ).copyWith(fontSize: 11),
                ),
              ),
              AnimatedRotation(
                turns: expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: ArcUiTokens.primaryAccent,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
      AnimatedCrossFade(
        firstChild: const SizedBox(width: double.infinity),
        secondChild: Column(children: children),
        crossFadeState: expanded
            ? CrossFadeState.showSecond
            : CrossFadeState.showFirst,
        duration: const Duration(milliseconds: 180),
      ),
      const SizedBox(height: 2),
    ],
  );
}
