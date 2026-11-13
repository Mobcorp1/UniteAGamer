import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/feature_access_gate.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_compact_navigation_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/uag_avatar_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_match_rider_invite.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_trader_profile.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_user_personalisation_profile.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/trading_notification.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_match_rider_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_user_personalisation_repository.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_user_entitlement.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/services/uag_entitlement_service.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/trading_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_notifications_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_profile_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/screens/build/auth/auth_landing_screen.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';
import 'package:uag_arc_raiders_hub/widgets/uag_drawer_nav_tile.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key, this.drawerWidth = 244});

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
  final ArcTraderProfileRepository _traderProfileRepository =
      ArcTraderProfileRepository();
  final ArcUserPersonalisationRepository _personalisationRepository =
      ArcUserPersonalisationRepository();
  final UagEntitlementService _entitlementService = UagEntitlementService();

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
      bottom: false,
      minimum: const EdgeInsets.only(top: 2),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compactBrand = constraints.maxWidth < 340;
            final brandStyle = ArcUiTokens.pageTitle(
              fontSize: compactBrand ? 13.5 : 16,
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
                      'assets/icon/uag_traders_header_mark.png',
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
                            const SizedBox(height: 2),
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
        final orderedNavigationGroups =
            List<ArcCompactNavigationGroup>.from(navigationGroups)..sort(
              (a, b) => _drawerGroupPriority(
                a.label,
              ).compareTo(_drawerGroupPriority(b.label)),
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
                            for (final group in orderedNavigationGroups.where(
                              (group) => _drawerGroupPriority(group.label) < 20,
                            ))
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
                            for (final group in orderedNavigationGroups.where(
                              (group) =>
                                  _drawerGroupPriority(group.label) >= 20,
                            ))
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

  int _drawerGroupPriority(String label) {
    switch (label) {
      case 'ACCOUNT & UAG':
        return 0;
      case 'DISCOVER & RUN':
        return 10;
      case 'RAID & INTELLIGENCE':
        return 30;
      case 'PROGRESSION & TRACKING':
        return 40;
      case 'TRADE & INVENTORY':
        return 50;
      case 'SQUAD & COMMUNITY':
        return 60;
      case 'IMPROVE':
        return 70;
      case 'FUTURE HUB':
        return 80;
      default:
        return 90;
    }
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

  String _displayNameForUser(User? user) {
    final displayName = (user?.displayName ?? '').trim();
    if (displayName.isNotEmpty) return displayName;
    final email = (user?.email ?? '').trim();
    if (email.contains('@')) {
      return email.split('@').first.replaceAll('.', ' ').replaceAll('_', ' ');
    }
    return 'Raider';
  }

  String _identityInitials(String value) {
    final parts = value
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return 'R';
    if (parts.length == 1) {
      final token = parts.first.trim();
      return token.length >= 2
          ? token.substring(0, 2).toUpperCase()
          : token.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  Widget _buildStatusChip({
    required String label,
    required Color color,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: ArcUiTokens.label(color: color).copyWith(fontSize: 10.5),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar({
    required ArcTraderProfile? profile,
    required User user,
    required String displayName,
    required Color tierColor,
  }) {
    final avatarId = (profile?.avatarId ?? '').trim();
    final avatarType = (profile?.avatarType ?? '').trim().toLowerCase();
    final photoUrl = (user.photoURL ?? '').trim();
    final initials = _identityInitials(displayName);

    Widget initialsFallback() {
      return Center(
        child: Text(
          initials,
          style: ArcUiTokens.cardTitle(
            color: ArcUiTokens.textPrimary,
            fontSize: 13,
          ),
        ),
      );
    }

    Widget authPhotoOrInitials() {
      if (photoUrl.isEmpty) return initialsFallback();
      return Image.network(
        photoUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => initialsFallback(),
      );
    }

    final Widget avatar;
    if (avatarType == 'preset' &&
        avatarId.isNotEmpty &&
        UagAvatarCatalog.contains(avatarId)) {
      avatar = Image.asset(
        UagAvatarCatalog.byId(avatarId).assetPath,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => authPhotoOrInitials(),
      );
    } else {
      avatar = authPhotoOrInitials();
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: tierColor.withValues(alpha: 0.52),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(color: tierColor.withValues(alpha: 0.16), blurRadius: 12),
        ],
      ),
      child: ClipOval(child: avatar),
    );
  }

  Widget _buildDrawerProfileHeader(
    BuildContext context,
    Color dynamicColor,
    User user,
  ) {
    return StreamBuilder<ArcTraderProfile>(
      stream: _traderProfileRepository.watchProfile(),
      builder: (context, profileSnapshot) {
        final profile = profileSnapshot.data;
        final profileName = (profile?.uagName ?? '').trim();
        final displayName = profileName.isNotEmpty
            ? profileName
            : _displayNameForUser(user);
        final profileReady =
            profile?.isProfileComplete == true ||
            _cachedPersonalisation.completed;

        return StreamBuilder<UagUserEntitlement>(
          stream: _entitlementService.watchMyEntitlement(),
          builder: (context, entitlementSnapshot) {
            final entitlement = entitlementSnapshot.data;
            final tierLabel = entitlement?.hasFoundingRaiderRate == true
                ? 'FOUNDER'
                : entitlement?.hasBetaPricing == true
                ? 'BETA'
                : (entitlement?.effectiveTier.label ?? 'Free').toUpperCase();
            final tierColor = entitlement?.hasFoundingRaiderRate == true
                ? const Color(0xFFFFD36A)
                : entitlement?.effectiveTier.isPaid == true
                ? AppTheme.neonPink
                : AppTheme.neonCyan;
            final uagId = (profile?.uagId ?? '').trim();
            final networkLine = uagId.isNotEmpty
                ? '$uagId // ONLINE'
                : 'UAG NETWORK // ONLINE';

            return Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 7),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(ArcUiTokens.radiusL),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(
                      context,
                    ).pushNamed(TradingProfileScreen.routeName);
                  },
                  child: Ink(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(ArcUiTokens.radiusL),
                      border: Border.all(
                        color: dynamicColor.withValues(alpha: 0.28),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          ArcUiTokens.surfacePanel.withValues(alpha: 0.97),
                          ArcUiTokens.surfaceOverlay.withValues(alpha: 0.90),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _buildProfileAvatar(
                                profile: profile,
                                user: user,
                                displayName: displayName,
                                tierColor: tierColor,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayName.toUpperCase(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: ArcUiTokens.cardTitle(
                                        color: ArcUiTokens.textPrimary,
                                        fontSize: 13.2,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      networkLine,
                                      maxLines: 1,
                                      overflow: TextOverflow.fade,
                                      softWrap: false,
                                      style: ArcUiTokens.bodySmall(
                                        color: ArcUiTokens.textTertiary,
                                      ).copyWith(fontSize: 10.4),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 19,
                                color: AppTheme.neonPink,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _buildStatusChip(
                                label: tierLabel,
                                color: tierColor,
                                icon: Icons.verified_outlined,
                              ),
                              _buildStatusChip(
                                label: profileReady
                                    ? 'PROFILE READY'
                                    : 'PROFILE SETUP',
                                color: AppTheme.neonCyan,
                                icon: profileReady
                                    ? Icons.radar_rounded
                                    : Icons.tune_rounded,
                              ),
                              if (_isAdmin)
                                _buildStatusChip(
                                  label: 'ADMIN',
                                  color: const Color(0xFFFFA347),
                                  icon: Icons.shield_outlined,
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.person_search_rounded,
                                size: 14,
                                color: AppTheme.neonPink.withValues(
                                  alpha: 0.92,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'PROFILE & REPUTATION',
                                  style: ArcUiTokens.label(
                                    color: AppTheme.neonPink,
                                  ).copyWith(fontSize: 10.8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null;
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final showAdminLoading = user != null && !_isAdminResolved;
    final screenWidth = MediaQuery.sizeOf(context).width;
    // Size the drawer around the longest navigation group instead of
    // allowing it to dominate the mobile viewport. The default 244px width
    // comfortably fits PROGRESSION & TRACKING plus its chevron.
    var drawerWidth = widget.drawerWidth.clamp(228.0, 244.0);
    if (screenWidth < drawerWidth + 44) {
      final constrainedWidth = screenWidth - 36;
      drawerWidth = constrainedWidth < 228
          ? screenWidth * 0.72
          : constrainedWidth.clamp(228.0, 244.0);
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
                    height: 1,
                    color: dynamicColor.withValues(alpha: 0.22),
                    thickness: 1,
                  ),
                  if (user != null)
                    _buildDrawerProfileHeader(context, dynamicColor, user),
                  Divider(
                    height: 1,
                    color: dynamicColor.withValues(alpha: 0.14),
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
                      minimum: const EdgeInsets.fromLTRB(8, 2, 8, 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _logout(context),
                          icon: const Icon(Icons.logout, size: 18),
                          label: const Text('Logout'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.neonPink,
                            side: const BorderSide(color: AppTheme.neonPink),
                            minimumSize: const Size.fromHeight(40),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            textStyle: ArcUiTokens.buttonLabel(
                              color: AppTheme.neonPink,
                            ),
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
          margin: const EdgeInsets.fromLTRB(8, 1, 8, 0),
          padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
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
              Flexible(
                fit: FlexFit.loose,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: ArcUiTokens.label(
                    color: expanded
                        ? ArcUiTokens.secondaryAccent
                        : ArcUiTokens.primaryAccent,
                  ).copyWith(fontSize: 12),
                ),
              ),
              const SizedBox(width: 4),
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
      const SizedBox(height: 1),
    ],
  );
}
