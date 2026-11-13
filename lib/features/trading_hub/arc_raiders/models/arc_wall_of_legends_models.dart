import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_profile_social_models.dart';

enum ArcWallOfLegendsCategory {
  founders,
  closedBetaRaiders,
  communityHeroes,
  guardians,
  trustedTraders,
  topIntelContributors,
  creators,
  competitionWinners,
}

extension ArcWallOfLegendsCategoryX on ArcWallOfLegendsCategory {
  String get label {
    switch (this) {
      case ArcWallOfLegendsCategory.founders:
        return 'Founders';
      case ArcWallOfLegendsCategory.closedBetaRaiders:
        return 'Closed Beta Raiders';
      case ArcWallOfLegendsCategory.communityHeroes:
        return 'Community Heroes';
      case ArcWallOfLegendsCategory.guardians:
        return 'Guardians';
      case ArcWallOfLegendsCategory.trustedTraders:
        return 'Trusted Traders';
      case ArcWallOfLegendsCategory.topIntelContributors:
        return 'Top Intel Contributors';
      case ArcWallOfLegendsCategory.creators:
        return 'Creators';
      case ArcWallOfLegendsCategory.competitionWinners:
        return 'Competition Winners';
    }
  }

  int get sortOrder => ArcWallOfLegendsCategory.values.indexOf(this);
}

class ArcWallOfLegendsEntry {
  const ArcWallOfLegendsEntry({
    required this.id,
    required this.category,
    required this.displayName,
    this.profileUid = '',
    this.uagId = '',
    this.title = '',
    this.badgeLabel = '',
    this.reason = '',
    this.seasonId = '',
    this.publicSocialLinks = const <ArcProfileSocialLink>[],
    this.approved = false,
    this.sortOrder = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final ArcWallOfLegendsCategory category;
  final String displayName;
  final String profileUid;
  final String uagId;
  final String title;
  final String badgeLabel;
  final String reason;
  final String seasonId;
  final List<ArcProfileSocialLink> publicSocialLinks;
  final bool approved;
  final int sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isVisible => approved && displayName.trim().isNotEmpty;

  String get subtitle {
    if (title.trim().isNotEmpty) return title.trim();
    if (badgeLabel.trim().isNotEmpty) return badgeLabel.trim();
    return category.label;
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'category': category.name,
      'categoryLabel': category.label,
      'displayName': displayName.trim(),
      'profileUid': profileUid.trim(),
      'uagId': uagId.trim(),
      'title': title.trim(),
      'badgeLabel': badgeLabel.trim(),
      'reason': reason.trim(),
      'seasonId': seasonId.trim(),
      'publicSocialLinks': ArcProfileSocialLinks.publicLinks(
        publicSocialLinks,
      ).map((link) => link.toPublicMap()).toList(growable: false),
      'approved': approved,
      'sortOrder': sortOrder,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }

  factory ArcWallOfLegendsEntry.fromMap(
    Map<String, dynamic> map, {
    required String fallbackId,
  }) {
    return ArcWallOfLegendsEntry(
      id: _string(map['id'], fallbackId),
      category: _categoryFromValue(map['category'] ?? map['categoryLabel']),
      displayName: _string(map['displayName'], _string(map['uagName'])),
      profileUid: _string(map['profileUid'], _string(map['uid'])),
      uagId: _string(map['uagId']),
      title: _string(map['title']),
      badgeLabel: _string(map['badgeLabel']),
      reason: _string(map['reason']),
      seasonId: _string(map['seasonId']),
      publicSocialLinks: ArcProfileSocialLinks.publicLinks(
        ArcProfileSocialLinks.fromRaw(map['publicSocialLinks']),
      ),
      approved: _bool(map['approved'], _bool(map['visible'])),
      sortOrder: _int(map['sortOrder']),
      createdAt: _date(map['createdAt']),
      updatedAt: _date(map['updatedAt']),
    );
  }

  static ArcWallOfLegendsCategory _categoryFromValue(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return ArcWallOfLegendsCategory.values.firstWhere(
      (category) =>
          category.name == text ||
          category.label.toLowerCase() == text.toLowerCase(),
      orElse: () => ArcWallOfLegendsCategory.communityHeroes,
    );
  }

  static String _string(dynamic value, [String fallback = '']) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _bool(dynamic value, [bool fallback = false]) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalised = value.toString().trim().toLowerCase();
    if (normalised == 'true') return true;
    if (normalised == 'false') return false;
    return fallback;
  }

  static DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

class ArcWallOfLegendsPermissions {
  const ArcWallOfLegendsPermissions._();

  static bool canManage({required bool isAdmin, required bool isDev}) {
    return isAdmin || isDev;
  }
}
