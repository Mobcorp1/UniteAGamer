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
class ArcTradeBundleTerms {
  const ArcTradeBundleTerms({
    this.acceptedCategories = const <ArcTradeBundleComponentType>[],
    this.minimumRequiredComponents = 0,
    this.minimumRequiredQuantity = 0,
    this.allowFlexibleAlternatives = false,
    this.allowEquivalentSubstitutions = false,
    this.requiresFinalConfirmation = true,
    this.notes = '',
  });

  final List<ArcTradeBundleComponentType> acceptedCategories;
  final int minimumRequiredComponents;
  final int minimumRequiredQuantity;
  final bool allowFlexibleAlternatives;
  final bool allowEquivalentSubstitutions;
  final bool requiresFinalConfirmation;
  final String notes;

  bool acceptsCategory(ArcTradeBundleComponentType type) =>
      acceptedCategories.isEmpty || acceptedCategories.contains(type);

  ArcTradeBundleTerms normalisedFor(List<ArcTradeBundleComponent> components) {
    final requiredComponents = components
        .where((component) => component.required)
        .toList(growable: false);
    final categories = acceptedCategories.isEmpty
        ? components.map((component) => component.type).toSet().toList()
        : acceptedCategories;
    final componentMinimum = minimumRequiredComponents <= 0
        ? requiredComponents.length
        : minimumRequiredComponents;
    final quantityMinimum = minimumRequiredQuantity <= 0
        ? requiredComponents.fold<int>(
            0,
            (total, component) => total + component.quantity,
          )
        : minimumRequiredQuantity;
    return ArcTradeBundleTerms(
      acceptedCategories: categories,
      minimumRequiredComponents: componentMinimum < 0 ? 0 : componentMinimum,
      minimumRequiredQuantity: quantityMinimum < 0 ? 0 : quantityMinimum,
      allowFlexibleAlternatives: allowFlexibleAlternatives,
      allowEquivalentSubstitutions: allowEquivalentSubstitutions,
      requiresFinalConfirmation: requiresFinalConfirmation,
      notes: notes,
    );
  }

  String get summary {
    final categoryText = acceptedCategories.isEmpty
        ? 'listed categories'
        : acceptedCategories.map((category) => category.label).join(', ');
    final minimumText = minimumRequiredComponents <= 0
        ? 'exact requested components'
        : '$minimumRequiredComponents component minimum';
    final flexibility = allowFlexibleAlternatives
        ? 'flexible alternatives allowed'
        : 'exact components preferred';
    return '$categoryText - $minimumText - $flexibility';
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'acceptedCategories': acceptedCategories
        .map((category) => category.name)
        .toList(),
    'minimumRequiredComponents': minimumRequiredComponents,
    'minimumRequiredQuantity': minimumRequiredQuantity,
    'allowFlexibleAlternatives': allowFlexibleAlternatives,
    'allowEquivalentSubstitutions': allowEquivalentSubstitutions,
    'requiresFinalConfirmation': requiresFinalConfirmation,
    'notes': notes,
  };

  factory ArcTradeBundleTerms.fromMap(Map<String, dynamic> map) {
    return ArcTradeBundleTerms(
      acceptedCategories: _readCategories(map['acceptedCategories']),
      minimumRequiredComponents: _readNonNegativeInt(
        map['minimumRequiredComponents'],
      ),
      minimumRequiredQuantity: _readNonNegativeInt(
        map['minimumRequiredQuantity'],
      ),
      allowFlexibleAlternatives: map['allowFlexibleAlternatives'] is bool
          ? map['allowFlexibleAlternatives'] as bool
          : false,
      allowEquivalentSubstitutions: map['allowEquivalentSubstitutions'] is bool
          ? map['allowEquivalentSubstitutions'] as bool
          : false,
      requiresFinalConfirmation: map['requiresFinalConfirmation'] is bool
          ? map['requiresFinalConfirmation'] as bool
          : true,
      notes: map['notes']?.toString().trim() ?? '',
    );
  }

  static int _readNonNegativeInt(dynamic value) {
    final parsed = value is num
        ? value.toInt()
        : int.tryParse(value?.toString() ?? '') ?? 0;
    return parsed < 0 ? 0 : parsed;
  }

  static List<ArcTradeBundleComponentType> _readCategories(dynamic value) {
    if (value is! List) return const <ArcTradeBundleComponentType>[];
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .map(
          (item) => ArcTradeBundleComponentType.values.firstWhere(
            (type) => type.name == item,
            orElse: () => ArcTradeBundleComponentType.tradeItem,
          ),
        )
        .toSet()
        .toList(growable: false);
  }
}

extension ArcTradeBundleComponentTypeLabel on ArcTradeBundleComponentType {
  String get label {
    switch (this) {
      case ArcTradeBundleComponentType.blueprint:
        return 'Blueprints';
      case ArcTradeBundleComponentType.resource:
        return 'Resources';
      case ArcTradeBundleComponentType.attachment:
        return 'Attachments';
      case ArcTradeBundleComponentType.weapon:
        return 'Weapons';
      case ArcTradeBundleComponentType.fittedWeapon:
        return 'Fitted Weapons';
      case ArcTradeBundleComponentType.key:
        return 'Keys';
      case ArcTradeBundleComponentType.currency:
        return 'Currency';
      case ArcTradeBundleComponentType.tradeItem:
        return 'Trade Items';
    }
  }
}

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
    this.terms = const ArcTradeBundleTerms(),
    this.notes = '',
  });

  final String id;
  final String name;
  final List<ArcTradeBundleComponent> components;
  final bool active;
  final bool allowEquivalentOffers;
  final ArcTradeBundleTerms terms;
  final String notes;

  ArcTradeBundleTerms get effectiveTerms => terms.normalisedFor(components);

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
    'terms': effectiveTerms.toMap(),
    'acceptedCategories': effectiveTerms.acceptedCategories
        .map((category) => category.name)
        .toList(),
    'minimumRequiredComponents': effectiveTerms.minimumRequiredComponents,
    'minimumRequiredQuantity': effectiveTerms.minimumRequiredQuantity,
    'allowFlexibleAlternatives': effectiveTerms.allowFlexibleAlternatives,
    'allowEquivalentSubstitutions': effectiveTerms.allowEquivalentSubstitutions,
    'requiresFinalConfirmation': effectiveTerms.requiresFinalConfirmation,
    'notes': notes,
  };

  factory ArcTradeBundleTemplate.fromMap(Map<String, dynamic> map) {
    final rawComponents = map['components'];
    final rawTerms = map['terms'];
    final terms = rawTerms is Map
        ? ArcTradeBundleTerms.fromMap(
            rawTerms.map((key, value) => MapEntry(key.toString(), value)),
          )
        : ArcTradeBundleTerms.fromMap(map);
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
      terms: terms,
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
    this.completionConfirmed = false,
  });

  final String templateId;
  final List<ArcTradeBundleComponent> components;
  final bool preparing;
  final String preparationNote;
  final bool completionConfirmed;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'templateId': templateId,
    'components': components.map((item) => item.toMap()).toList(),
    'preparing': preparing,
    'preparationNote': preparationNote,
    'completionConfirmed': completionConfirmed,
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
      completionConfirmed: map['completionConfirmed'] is bool
          ? map['completionConfirmed'] as bool
          : false,
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
    this.equivalentSubstitutions = const <String>[],
  });

  final ArcTradeBundleMatchStatus status;
  final List<String> missing;
  final List<String> incorrect;
  final List<String> unexpected;
  final List<String> equivalentSubstitutions;

  bool get isExact => status == ArcTradeBundleMatchStatus.exact;
}
