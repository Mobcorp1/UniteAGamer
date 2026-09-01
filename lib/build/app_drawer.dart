import 'dart:async';

import 'package:animated_text_kit/animated_text_kit.dart';
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
  const AppDrawer({super.key, this.drawerWidth = 300});

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
        padding: const EdgeInsets.all(8),
        child: Row(
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
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedTextKit(
                animatedTexts: [
                  AppTheme.animatedText(
                    'UAG Arc Raiders Hub',
                    AppTheme.heroTextStyle(
                      fontSize: 24,
                      color: AppTheme.neonCyan,
                    ),
                  ),
                ],
                isRepeatingAnimation: false,
              ),
            ),
          ],
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
                            _DrawerGroupLabel(label: 'COMMUNICATIONS'),
                            UagDrawerNavTile(
                              title: 'Communications Centre',
                              icon: Icons.notifications_active_outlined,
                              selected:
                                  currentRoute ==
                                  TradingNotificationsScreen.routeName,
                              badgeCount: counts.tradingHub,
                              onTap: () {
                                Navigator.of(context).pop();
                                if (currentRoute ==
                                    TradingNotificationsScreen.routeName) {
                                  return;
                                }
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  TradingNotificationsScreen.routeName,
                                  (route) => route.isFirst,
                                );
                              },
                            ),
                            const SizedBox(height: 6),
                            for (final group in navigationGroups) ...[
                              if (group.label == 'PROFILE') ...[
                                _DrawerGroupLabel(label: group.label),
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
                                if (_isAdminResolved && _isAdmin) ...[
                                  _DrawerGroupLabel(label: 'ADMIN'),
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
                                const SizedBox(height: 6),
                              ] else ...[
                                _DrawerGroupLabel(label: group.label),
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
                                const SizedBox(height: 6),
                              ],
                            ],
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

    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        final dynamicColor = _colorAnimation.value ?? Colors.white;
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: widget.drawerWidth,
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
                        'Resolving access…',
                        style: AppTheme.bodyTextStyle(
                          fontSize: 12,
                          color: AppTheme.tradingMutedText,
                        ),
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

class _DrawerGroupLabel extends StatelessWidget {
  const _DrawerGroupLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Text(
        label,
        style: AppTheme.bodyTextStyle(
          fontSize: 10,
          color: AppTheme.neonCyan.withValues(alpha: 0.72),
          isBold: true,
        ),
      ),
    );
  }
}
