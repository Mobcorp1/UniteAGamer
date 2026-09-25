import 'package:flutter/material.dart';

import '../data/uag_avatar_catalog.dart';
import 'foundation/arc_ui_tokens.dart';

/// Canonical UAG Raider avatar renderer.
///
/// Every consumer surface should resolve the saved preset through the same
/// catalogue and fall back to readable initials (or a generic Raider glyph)
/// when an asset cannot be rendered. This keeps profile identity stable across
/// the Hub, profile forms and avatar locker without duplicating fallback logic.
class UagRaiderAvatar extends StatelessWidget {
  const UagRaiderAvatar({
    super.key,
    required this.avatarId,
    this.displayName = '',
    this.size = 44,
    this.accent = ArcUiTokens.primaryAccent,
    this.onTap,
    this.showEditBadge = false,
    this.tooltip,
  });

  final String avatarId;
  final String displayName;
  final double size;
  final Color accent;
  final VoidCallback? onTap;
  final bool showEditBadge;
  final String? tooltip;

  static String initialsFor(String displayName) {
    final words = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (words.isEmpty) return '';
    if (words.length == 1) {
      final value = words.first;
      return value.substring(0, value.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final option = UagAvatarCatalog.byId(avatarId);
    final initials = initialsFor(displayName);
    final label = displayName.trim().isEmpty
        ? 'Raider avatar'
        : '${displayName.trim()} avatar';
    final resolvedTooltip = tooltip ?? 'Open Raider profile';

    Widget fallback() {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.10),
          shape: BoxShape.circle,
        ),
        child: initials.isNotEmpty
            ? Text(
                initials,
                style: ArcUiTokens.cardTitle(
                  fontSize: size * 0.30,
                  color: ArcUiTokens.textPrimary,
                ),
              )
            : Icon(
                Icons.person_rounded,
                size: size * 0.48,
                color: ArcUiTokens.textSecondary,
              ),
      );
    }

    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = (size * pixelRatio).ceil().clamp(32, 512).toInt();

    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: accent.withValues(alpha: 0.52)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.12),
            blurRadius: size * 0.28,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          fallback(),
          Image.asset(
            option.assetPath,
            width: size,
            height: size,
            fit: BoxFit.cover,
            cacheWidth: cacheWidth,
            filterQuality: FilterQuality.medium,
            gaplessPlayback: true,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded) return child;
              return AnimatedOpacity(
                opacity: frame == null ? 0 : 1,
                duration: const Duration(milliseconds: 90),
                child: child,
              );
            },
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );

    final content = Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        if (showEditBadge && onTap != null)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: size * 0.34,
              height: size * 0.34,
              decoration: BoxDecoration(
                color: ArcUiTokens.surfaceOverlay,
                shape: BoxShape.circle,
                border: Border.all(color: accent.withValues(alpha: 0.72)),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.edit_rounded, size: size * 0.18, color: accent),
            ),
          ),
      ],
    );

    final interactive = onTap == null
        ? content
        : Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: content,
            ),
          );

    return Semantics(
      button: onTap != null,
      label: label,
      child: onTap == null
          ? interactive
          : Tooltip(message: resolvedTooltip, child: interactive),
    );
  }
}

/// Compact canonical identity summary used by Profile setup/edit surfaces.
class UagRaiderIdentityStrip extends StatelessWidget {
  const UagRaiderIdentityStrip({
    super.key,
    required this.avatarId,
    required this.displayName,
    required this.uagId,
    required this.onChangeAvatar,
    this.accent = ArcUiTokens.primaryAccent,
  });

  final String avatarId;
  final String displayName;
  final String uagId;
  final VoidCallback onChangeAvatar;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final resolvedName = displayName.trim().isEmpty
        ? 'Your Raider'
        : displayName.trim();
    final resolvedId = uagId.trim().isEmpty ? 'UAG ID pending' : uagId.trim();

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.sizeOf(context).width;
        final compact = screenWidth < 390;
        final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final stackAction = constraints.maxWidth < 330 || textScale > 1.35;

        final avatar = UagRaiderAvatar(
          avatarId: avatarId,
          displayName: resolvedName,
          size: compact ? 48 : 54,
          accent: accent,
          onTap: onChangeAvatar,
          showEditBadge: true,
          tooltip: 'Change avatar',
        );

        final identity = Row(
          children: [
            avatar,
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    resolvedName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ArcUiTokens.cardTitle(
                      fontSize: compact ? 15 : 16,
                      color: ArcUiTokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    resolvedId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ArcUiTokens.metadata(
                      color: ArcUiTokens.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        final action = TextButton.icon(
          style: ArcUiTokens.textButtonStyle(primary: false),
          onPressed: onChangeAvatar,
          icon: const Icon(Icons.face_retouching_natural_rounded, size: 17),
          label: Text(compact ? 'AVATAR' : 'CHANGE AVATAR'),
        );

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 10 : 11,
          ),
          decoration: ArcUiTokens.surfaceDecoration(
            role: ArcSurfaceRole.interactive,
            accent: accent,
            borderOpacity: 0.22,
            radius: ArcUiTokens.radiusL,
          ),
          child: stackAction
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    identity,
                    const SizedBox(height: 8),
                    Align(alignment: Alignment.centerLeft, child: action),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: identity),
                    const SizedBox(width: 8),
                    action,
                  ],
                ),
        );
      },
    );
  }
}
