import 'package:flutter/foundation.dart';

enum ArcTradeBundleComponentType {
  blueprint,
  resource,
  attachment,
  weapon,
  fittedWeapon,
  key,
  currency,
  tradeItem,
}

enum ArcTradeBundleMatchStatus { exact, partial, mismatch }

@immutable
class ArcFittedWeaponConfiguration {
  const ArcFittedWeaponConfiguration({
    required this.weaponId,
    required this.weaponName,
    this.attachmentsBySlot = const <String, String>{},
  });

  final String weaponId;
  final String weaponName;
  final Map<String, String> attachmentsBySlot;

  static const String anyCompatibleAttachment = '*';

  bool requiresAnyCompatible(String slotLabel) =>
      attachmentsBySlot[slotLabel] == anyCompatibleAttachment;

  String? exactAttachmentFor(String slotLabel) {
    final value = attachmentsBySlot[slotLabel];
    if (value == null || value.isEmpty || value == anyCompatibleAttachment) {
      return null;
    }
    return value;
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'weaponId': weaponId,
    'weaponName': weaponName,
    'attachmentsBySlot': attachmentsBySlot,
  };

  factory ArcFittedWeaponConfiguration.fromMap(Map<String, dynamic> map) {
    final raw = map['attachmentsBySlot'];
    return ArcFittedWeaponConfiguration(
      weaponId: map['weaponId']?.toString().trim() ?? '',
      weaponName: map['weaponName']?.toString().trim() ?? '',
      attachmentsBySlot: raw is Map
          ? raw.map(
              (key, value) => MapEntry(
                key.toString().trim(),
                value?.toString().trim() ?? '',
              ),
            )
          : const <String, String>{},
    );
  }
}

@immutable
class ArcTradeBundleComponent {
  const ArcTradeBundleComponent({
    required this.id,
    required this.type,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    this.required = true,
    this.notes = '',
    this.fittedWeapon,
  });

  final String id;
  final ArcTradeBundleComponentType type;
  final String itemId;
  final String itemName;
  final int quantity;
  final bool required;
  final String notes;
  final ArcFittedWeaponConfiguration? fittedWeapon;

  String get comparisonKey {
    final config = fittedWeapon;
    if (config == null) return '${type.name}:$itemId';
    final slots = config.attachmentsBySlot.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return '${type.name}:$itemId:${slots.map((e) => '${e.key}=${e.value}').join('|')}';
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'type': type.name,
    'itemId': itemId,
    'itemName': itemName,
    'quantity': quantity,
    'required': required,
    'notes': notes,
    if (fittedWeapon != null) 'fittedWeapon': fittedWeapon!.toMap(),
  };

  factory ArcTradeBundleComponent.fromMap(Map<String, dynamic> map) {
    final fittedRaw = map['fittedWeapon'];
    return ArcTradeBundleComponent(
      id: map['id']?.toString().trim() ?? '',
      type: ArcTradeBundleComponentType.values.firstWhere(
        (value) => value.name == map['type']?.toString(),
        orElse: () => ArcTradeBundleComponentType.tradeItem,
      ),
      itemId: map['itemId']?.toString().trim() ?? '',
      itemName: map['itemName']?.toString().trim() ?? '',
      quantity: _readPositiveInt(map['quantity']),
      required: map['required'] is bool ? map['required'] as bool : true,
      notes: map['notes']?.toString().trim() ?? '',
      fittedWeapon: fittedRaw is Map
          ? ArcFittedWeaponConfiguration.fromMap(
              fittedRaw.map((key, value) => MapEntry(key.toString(), value)),
            )
          : null,
    );
  }

  static int _readPositiveInt(dynamic value) {
    final parsed = value is num
        ? value.toInt()
        : int.tryParse(value?.toString() ?? '') ?? 1;
    return parsed < 1 ? 1 : parsed;
  }
}

@immutable
class ArcTradeBundleTemplate {
  const ArcTradeBundleTemplate({
    required this.id,
    required this.name,
    required this.components,
    this.active = true,
    this.allowEquivalentOffers = false,
    this.notes = '',
  });

  final String id;
  final String name;
  final List<ArcTradeBundleComponent> components;
  final bool active;
  final bool allowEquivalentOffers;
  final String notes;

  bool get isValid =>
      id.trim().isNotEmpty &&
      name.trim().isNotEmpty &&
      components.isNotEmpty &&
      components.every(
        (component) =>
            component.id.trim().isNotEmpty &&
            component.itemId.trim().isNotEmpty &&
            component.itemName.trim().isNotEmpty &&
            component.quantity > 0,
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'name': name,
    'components': components.map((item) => item.toMap()).toList(),
    'active': active,
    'allowEquivalentOffers': allowEquivalentOffers,
    'notes': notes,
  };

  factory ArcTradeBundleTemplate.fromMap(Map<String, dynamic> map) {
    final rawComponents = map['components'];
    return ArcTradeBundleTemplate(
      id: map['id']?.toString().trim() ?? '',
      name: map['name']?.toString().trim() ?? '',
      components: rawComponents is List
          ? rawComponents
                .whereType<Map>()
                .map(
                  (item) => ArcTradeBundleComponent.fromMap(
                    item.map((key, value) => MapEntry(key.toString(), value)),
                  ),
                )
                .toList(growable: false)
          : const <ArcTradeBundleComponent>[],
      active: map['active'] is bool ? map['active'] as bool : true,
      allowEquivalentOffers: map['allowEquivalentOffers'] is bool
          ? map['allowEquivalentOffers'] as bool
          : false,
      notes: map['notes']?.toString().trim() ?? '',
    );
  }
}

@immutable
class ArcExactTradeBundleOffer {
  const ArcExactTradeBundleOffer({
    required this.templateId,
    required this.components,
    this.preparing = false,
    this.preparationNote = '',
  });

  final String templateId;
  final List<ArcTradeBundleComponent> components;
  final bool preparing;
  final String preparationNote;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'templateId': templateId,
    'components': components.map((item) => item.toMap()).toList(),
    'preparing': preparing,
    'preparationNote': preparationNote,
  };

  factory ArcExactTradeBundleOffer.fromMap(Map<String, dynamic> map) {
    final rawComponents = map['components'];
    return ArcExactTradeBundleOffer(
      templateId: map['templateId']?.toString().trim() ?? '',
      components: rawComponents is List
          ? rawComponents
                .whereType<Map>()
                .map(
                  (item) => ArcTradeBundleComponent.fromMap(
                    item.map((key, value) => MapEntry(key.toString(), value)),
                  ),
                )
                .toList(growable: false)
          : const <ArcTradeBundleComponent>[],
      preparing: map['preparing'] is bool ? map['preparing'] as bool : false,
      preparationNote: map['preparationNote']?.toString().trim() ?? '',
    );
  }
}

@immutable
class ArcTradeBundleMatchResult {
  const ArcTradeBundleMatchResult({
    required this.status,
    required this.missing,
    required this.incorrect,
    required this.unexpected,
  });

  final ArcTradeBundleMatchStatus status;
  final List<String> missing;
  final List<String> incorrect;
  final List<String> unexpected;

  bool get isExact => status == ArcTradeBundleMatchStatus.exact;
}
