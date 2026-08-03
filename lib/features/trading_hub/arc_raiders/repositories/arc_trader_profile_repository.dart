import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/arc_player_archetype_catalog.dart';
import '../data/arc_player_session_catalog.dart';
import '../data/arc_profile_completion_evaluator.dart';
import '../models/arc_availability.dart';
import '../models/arc_away_status.dart';
import '../models/arc_profile_social_models.dart';
import '../models/arc_trader_profile.dart';
import 'arc_operations_repository.dart';

class ArcTraderProfileRepository {
  ArcTraderProfileRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const String _referralCodeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const int _referralCodeLength = 8;
  static const int _maxReferralAttempts = 20;
  static const int _maxUagNumericId = 400000000;
  static const int _uagNumericPadding = 9;
  static const String _uagPrefix = 'UAG';

  String? get currentUid => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection('users').doc(uid);

  DocumentReference<Map<String, dynamic>> profileDoc(String uid) =>
      _userDoc(uid).collection('trading_activity').doc('profile');

  DocumentReference<Map<String, dynamic>> publicProfileDoc(String uid) =>
      _firestore.collection('public_profiles').doc(uid);

  DocumentReference<Map<String, dynamic>> availabilityDoc(String uid) =>
      _userDoc(uid).collection('trading_activity').doc('availability');

  DocumentReference<Map<String, dynamic>> awayDoc(String uid) =>
      _userDoc(uid).collection('trading_activity').doc('away');

  DocumentReference<Map<String, dynamic>> _referralCodeDoc(String code) =>
      _firestore.collection('referral_codes').doc(code);

  DocumentReference<Map<String, dynamic>> _uagIdDoc(String uagId) =>
      _firestore.collection('uag_ids').doc(uagId);

  DocumentReference<Map<String, dynamic>> get _uagCounterDoc =>
      _firestore.collection('system_counters').doc('arc_trader_ids');

  String _string(dynamic value, [String fallback = '']) {
    if (value == null) return fallback;
    if (value is String) return value.trim();
    return value.toString().trim();
  }

  bool _bool(dynamic value, [bool fallback = false]) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.toLowerCase() == 'true';
    return fallback;
  }

  String _firstStringFromList(dynamic value, [String fallback = '']) {
    if (value is Iterable) {
      for (final item in value) {
        if (item is String && item.trim().isNotEmpty) return item.trim();
      }
    }
    return fallback;
  }

  List<String> _stringList(dynamic value, [List<String> fallback = const []]) {
    if (value == null) return fallback;
    if (value is Iterable) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList(growable: false);
    }
    if (value is String && value.trim().isNotEmpty) {
      return <String>[value.trim()];
    }
    return fallback;
  }

  String _formatUagId(int number) =>
      '$_uagPrefix${number.toString().padLeft(_uagNumericPadding, '0')}';

  int? _extractUagNumber(String rawValue) {
    final normalized = _normalizeUagId(rawValue);
    if (normalized.isEmpty) return null;
    return int.tryParse(normalized.substring(_uagPrefix.length));
  }

  String _normalizeUagId(String rawValue) {
    final cleaned = rawValue.trim().toUpperCase().replaceAll(
      RegExp(r'\s+'),
      '',
    );
    if (cleaned.isEmpty) return '';
    if (!cleaned.startsWith(_uagPrefix)) return '';

    final numericPart = cleaned.substring(_uagPrefix.length);
    if (numericPart.isEmpty || !RegExp(r'^\d+$').hasMatch(numericPart)) {
      return '';
    }

    final numericValue = int.tryParse(numericPart);
    if (numericValue == null ||
        numericValue <= 0 ||
        numericValue > _maxUagNumericId) {
      return '';
    }

    return _formatUagId(numericValue);
  }

  String _candidateUagIdFromUserData(
    Map<String, dynamic> userData,
    Map<String, dynamic> profileData,
  ) {
    final traderProfile = userData['traderProfile'] is Map<String, dynamic>
        ? userData['traderProfile'] as Map<String, dynamic>
        : <String, dynamic>{};

    final candidates = <String>[
      _string(profileData['uagId']),
      _string(traderProfile['uagId']),
      _string(userData['uagId']),
      _string(profileData['gamerTag']),
    ];

    for (final candidate in candidates) {
      final normalized = _normalizeUagId(candidate);
      if (normalized.isNotEmpty) return normalized;
    }

    return '';
  }

  Future<void> _syncUagIdAcrossUserDocs(String uid, String uagId) async {
    final now = FieldValue.serverTimestamp();
    await _userDoc(uid).set({
      'uagId': uagId,
      'updatedAt': now,
      'traderProfile': {'uagId': uagId},
    }, SetOptions(merge: true));

    await profileDoc(uid).set({
      'uagId': uagId,
      'gamerTag': uagId,
      'updatedAt': now,
      'lastActiveAt': now,
    }, SetOptions(merge: true));
  }

  Future<String> _ensureReservedUagIdForUid(
    String uid, {
    String? preferredUagId,
  }) async {
    final existingProfile = await profileDoc(uid).get();
    final existingProfileId = _normalizeUagId(
      _string(existingProfile.data()?['uagId']),
    );

    if (existingProfileId.isNotEmpty) {
      final existingReservation = await _uagIdDoc(existingProfileId).get();
      if (!existingReservation.exists ||
          _string(existingReservation.data()?['uid']) == uid) {
        if (!existingReservation.exists) {
          final number = _extractUagNumber(existingProfileId)!;
          await _uagIdDoc(existingProfileId).set({
            'uagId': existingProfileId,
            'uid': uid,
            'number': number,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
        await _syncUagIdAcrossUserDocs(uid, existingProfileId);
        return existingProfileId;
      }
    }

    final normalizedPreferred = _normalizeUagId(preferredUagId ?? '');
    late final String resolvedUagId;

    await _firestore.runTransaction((transaction) async {
      final counterSnap = await transaction.get(_uagCounterDoc);
      final current =
          ((counterSnap.data() ??
                      const <String, dynamic>{})['lastIssuedNumber'] ??
                  0)
              as num;
      var lastIssuedNumber = current.toInt();

      String candidateId;
      late int candidateNumber;

      if (normalizedPreferred.isNotEmpty) {
        candidateId = normalizedPreferred;
        candidateNumber = _extractUagNumber(candidateId)!;
      } else {
        candidateNumber = lastIssuedNumber + 1;
        if (candidateNumber > _maxUagNumericId) {
          throw StateError('UAG numeric ID limit reached.');
        }
        candidateId = _formatUagId(candidateNumber);
      }

      final uagIdRef = _uagIdDoc(candidateId);
      final uagIdSnap = await transaction.get(uagIdRef);
      if (uagIdSnap.exists) {
        final ownerUid = _string(uagIdSnap.data()?['uid']);
        if (ownerUid != uid) {
          throw StateError('UAG ID $candidateId is already reserved.');
        }
      }

      lastIssuedNumber = max(lastIssuedNumber, candidateNumber);

      transaction.set(_uagCounterDoc, {
        'lastIssuedNumber': lastIssuedNumber,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      transaction.set(uagIdRef, {
        'uagId': candidateId,
        'uid': uid,
        'number': candidateNumber,
        'createdAt': uagIdSnap.exists
            ? (uagIdSnap.data()?['createdAt'] ?? FieldValue.serverTimestamp())
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      resolvedUagId = candidateId;
    });

    await _syncUagIdAcrossUserDocs(uid, resolvedUagId);
    return resolvedUagId;
  }

  String _generateReferralCode() {
    final random = Random.secure();
    return List.generate(
      _referralCodeLength,
      (_) => _referralCodeChars[random.nextInt(_referralCodeChars.length)],
    ).join();
  }

  Future<String> _ensureReferralCodeForUid(String uid) async {
    final profileSnapshot = await profileDoc(uid).get();
    final existingProfileData = profileSnapshot.data() ?? <String, dynamic>{};
    final existingCode = _string(existingProfileData['referralCode']);

    if (existingCode.isNotEmpty) {
      final existingCodeDoc = await _referralCodeDoc(existingCode).get();
      if (existingCodeDoc.exists) {
        final ownerUid = _string(existingCodeDoc.data()?['ownerUid']);
        if (ownerUid == uid) {
          return existingCode;
        }
      } else {
        await _referralCodeDoc(existingCode).set({
          'code': existingCode,
          'ownerUid': uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return existingCode;
      }
    }

    for (var attempt = 0; attempt < _maxReferralAttempts; attempt++) {
      final code = _generateReferralCode();
      final codeDoc = _referralCodeDoc(code);

      try {
        await _firestore.runTransaction((transaction) async {
          final existing = await transaction.get(codeDoc);
          if (existing.exists) {
            throw StateError('Referral code collision');
          }

          transaction.set(codeDoc, {
            'code': code,
            'ownerUid': uid,
            'createdAt': FieldValue.serverTimestamp(),
          });
        });

        return code;
      } catch (_) {
        // Try another code if collision or transaction failure.
      }
    }

    throw StateError(
      'Could not reserve a unique referral code after $_maxReferralAttempts attempts.',
    );
  }

  ArcTraderProfile _profileFromMaps({
    required String uid,
    required Map<String, dynamic> userData,
    required Map<String, dynamic> profileData,
  }) {
    final basicProfile = userData['basicProfile'] is Map<String, dynamic>
        ? userData['basicProfile'] as Map<String, dynamic>
        : <String, dynamic>{};
    final baseProfile = userData['baseProfile'] is Map<String, dynamic>
        ? userData['baseProfile'] as Map<String, dynamic>
        : <String, dynamic>{};
    final traderProfile = userData['traderProfile'] is Map<String, dynamic>
        ? userData['traderProfile'] as Map<String, dynamic>
        : <String, dynamic>{};

    final uagName = _string(
      profileData['uagName'],
      _string(
        profileData['displayName'],
        _string(
          traderProfile['uagName'],
          _string(
            userData['uagName'],
            _string(
              userData['displayName'],
              _string(baseProfile['displayName'], 'New Trader'),
            ),
          ),
        ),
      ),
    );

    final region = _string(
      profileData['region'],
      _string(
        traderProfile['region'],
        _string(userData['region'], _string(basicProfile['country'], 'UK')),
      ),
    );

    final serverPreference = _string(
      profileData['serverPreference'],
      _string(
        traderProfile['serverPreference'],
        _string(userData['serverPreference'], 'Automatic'),
      ),
    );

    final platform = _string(
      profileData['platform'],
      _string(
        profileData['preferredPlatform'],
        _string(
          traderProfile['platform'],
          _string(
            traderProfile['preferredPlatform'],
            _string(
              basicProfile['platform'],
              _firstStringFromList(
                basicProfile['platforms'],
                _firstStringFromList(baseProfile['platforms']),
              ),
            ),
          ),
        ),
      ),
    );

    final timezone = _string(
      profileData['timezone'],
      _string(
        traderProfile['timeZone'],
        _string(basicProfile['timeZone'], 'Europe/London'),
      ),
    );

    final gamerTag = _string(
      profileData['gamerTag'],
      _string(traderProfile['gamerTag'], _string(basicProfile['gamertag'])),
    );

    final uagId = _string(profileData['uagId'], gamerTag);
    final archetypes = ArcPlayerArchetypeCatalog.normalizeLabels(<dynamic>[
      ..._stringList(profileData['archetypes']),
      ..._stringList(traderProfile['archetypes']),
      ..._stringList(basicProfile['archetypes']),
      _string(profileData['playStyle']),
      _string(traderProfile['playStyle']),
      _string(basicProfile['playStyle']),
    ], includeDefaultWhenEmpty: true);
    final playStyles = _stringList(
      profileData['playStyles'],
      _stringList(
        profileData['playStyle'],
        _stringList(
          traderProfile['playStyles'],
          _stringList(
            traderProfile['playStyle'],
            _stringList(basicProfile['playStyle']),
          ),
        ),
      ),
    );

    final createdAt = (profileData['createdAt'] as Timestamp?)?.toDate();
    final updatedAt = (profileData['updatedAt'] as Timestamp?)?.toDate();
    final lastActiveAt = (profileData['lastActiveAt'] as Timestamp?)?.toDate();

    return ArcTraderProfile.empty(uid).copyWith(
      uid: uid,
      uagId: uagId,
      uagName: uagName,
      embarkId: _string(
        profileData['embarkId'],
        _string(traderProfile['embarkId'], _string(basicProfile['embarkId'])),
      ),
      region: region,
      serverPreference: serverPreference,
      platform: platform,
      timezone: timezone,
      visibleInSearch: _bool(profileData['visibleInSearch'], true),
      micOk: _bool(profileData['micOk'], true),
      crossRegionOk: _bool(profileData['crossRegionOk']),
      crossPlatformOk: _bool(profileData['crossPlatformOk'], true),
      isProfileComplete: _bool(
        profileData['isProfileComplete'],
        uagId.isNotEmpty &&
            uagName.isNotEmpty &&
            region.isNotEmpty &&
            platform.isNotEmpty,
      ),
      archetypes: archetypes,
      playStyles: playStyles.isEmpty ? const ['PvE defensive'] : playStyles,
      communicationStyle: _string(
        profileData['communicationStyle'],
        _string(traderProfile['communicationStyle'], 'Flexible'),
      ),
      squadIntent: _string(
        profileData['squadIntent'],
        _string(traderProfile['squadIntent'], 'Flexible'),
      ),
      socialEnergy: _string(
        profileData['socialEnergy'],
        _string(traderProfile['socialEnergy'], 'Depends on the day'),
      ),
      sessionIntent: ArcPlayerSessionCatalog.normalizeIntent(
        _string(
          profileData['sessionIntent'],
          _string(
            traderProfile['sessionIntent'],
            profileData['squadIntent']?.toString() ?? '',
          ),
        ),
      ),
      currentPriority: ArcPlayerSessionCatalog.normalizePriority(
        _string(
          profileData['currentPriority'],
          _string(traderProfile['currentPriority']),
        ),
      ),
      referralCode: _string(profileData['referralCode']),
      referredByCode: _string(
        profileData['referredByCode'],
        _string(userData['referredByCode']),
      ),
      affiliateEnabled: _bool(
        profileData['affiliateEnabled'],
        _bool(userData['affiliateApplied']),
      ),
      payoutMethod: _string(
        profileData['payoutMethod'],
        _string(userData['preferredPayoutMethod'], 'Bank Transfer'),
      ),
      subscriptionStatus: _string(
        profileData['subscriptionStatus'],
        _string(userData['subscriptionStatus'], 'inactive'),
      ),
      socialLinks: ArcProfileSocialLinks.fromProfileMaps(<Map<String, dynamic>>[
        profileData,
        traderProfile,
        basicProfile,
        userData,
      ]),
      creatorProgramme: ArcCreatorProgrammeProfile.fromMap(
        profileData['creatorProgramme'],
        fallbackReferralCode: _string(
          profileData['referralCode'],
          _string(userData['referralCode']),
        ),
        affiliateEnabled: _bool(
          profileData['affiliateEnabled'],
          _bool(userData['affiliateApplied']),
        ),
      ),
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastActiveAt: lastActiveAt,
    );
  }

  Map<String, dynamic> _arcProfileToUnifiedMap(
    ArcTraderProfile profile, {
    required dynamic serverNow,
  }) {
    final isComplete = profile.hasCoreDetails;
    final socialLinks = ArcProfileSocialLinks.merge(profile.socialLinks);
    final creatorProgramme = profile.creatorProgramme.normalised(
      referralCode: profile.referralCode,
      affiliateRequested: profile.affiliateEnabled,
    );

    return {
      'uid': profile.uid,
      'uagId': profile.uagId.trim(),
      'uagName': profile.uagName.trim(),
      'embarkId': profile.embarkId.trim(),
      'region': profile.region.trim(),
      'serverPreference': profile.serverPreference.trim().isEmpty
          ? 'Automatic'
          : profile.serverPreference.trim(),
      'platform': profile.platform.trim(),
      'timezone': profile.timezone.trim(),
      'visibleInSearch': profile.visibleInSearch,
      'micOk': profile.micOk,
      'crossRegionOk': profile.crossRegionOk,
      'crossPlatformOk': profile.crossPlatformOk,
      'crossplayEnabled': profile.crossPlatformOk,
      'isProfileComplete': isComplete,
      'archetypes': ArcPlayerArchetypeCatalog.normalizeLabels(
        profile.archetypes,
        includeDefaultWhenEmpty: true,
      ),
      'playStyles': profile.playStyles,
      'playStyle': profile.playStyles.isNotEmpty
          ? profile.playStyles.first
          : profile.archetypes.isNotEmpty
          ? profile.archetypes.first
          : ArcPlayerArchetypeCatalog.defaultLabel,
      'communicationStyle': profile.communicationStyle.trim().isEmpty
          ? 'Flexible'
          : profile.communicationStyle.trim(),
      'squadIntent': profile.squadIntent.trim().isEmpty
          ? 'Flexible'
          : profile.squadIntent.trim(),
      'socialEnergy': profile.socialEnergy.trim().isEmpty
          ? 'Depends on the day'
          : profile.socialEnergy.trim(),
      'sessionIntent': ArcPlayerSessionCatalog.normalizeIntent(
        profile.sessionIntent,
      ),
      'currentPriority': ArcPlayerSessionCatalog.normalizePriority(
        profile.currentPriority,
      ),
      'referralCode': profile.referralCode.trim(),
      'referredByCode': profile.referredByCode.trim(),
      'affiliateEnabled': profile.affiliateEnabled,
      'payoutMethod': profile.payoutMethod.trim(),
      'subscriptionStatus': profile.subscriptionStatus.trim(),
      'socialLinks': socialLinks
          .map((link) => link.toMap())
          .toList(growable: false),
      'publicSocialLinks': ArcProfileSocialLinks.publicLinks(
        socialLinks,
      ).map((link) => link.toPublicMap()).toList(growable: false),
      'creatorProgramme': creatorProgramme.toMap(),
      'publicCreatorProgramme': creatorProgramme.toPublicMap(),
      'creatorProgrammeStatus': creatorProgramme.status.name,
      'creatorProgrammeApproved': creatorProgramme.adminApproved,
      'displayName': profile.uagName.trim().isEmpty
          ? 'New Trader'
          : profile.uagName.trim(),
      'gamerTag': profile.uagId.trim(),
      'preferredPlatform': profile.platform.trim(),
      'updatedAt': serverNow,
      'lastActiveAt': serverNow,
      'createdAt': profile.createdAt == null
          ? serverNow
          : Timestamp.fromDate(profile.createdAt!),
    };
  }

  Future<void> _syncPublicProfile(
    ArcTraderProfile profile, {
    required Object serverNow,
  }) async {
    await publicProfileDoc(profile.uid).set(
      profile.toPublicProfileMap(updatedAt: serverNow),
      SetOptions(merge: true),
    );
  }

  Future<void> ensureDocsExist() async {
    final uid = currentUid;
    if (uid == null) {
      throw StateError('No authenticated user found.');
    }

    final now = FieldValue.serverTimestamp();
    final userSnap = await _userDoc(uid).get();
    final userData = userSnap.data() ?? <String, dynamic>{};

    final profileSnapshot = await profileDoc(uid).get();
    final profileData = profileSnapshot.data() ?? <String, dynamic>{};
    final preferredUagId = _candidateUagIdFromUserData(userData, profileData);
    final resolvedUagId = await _ensureReservedUagIdForUid(
      uid,
      preferredUagId: preferredUagId,
    );

    if (!profileSnapshot.exists) {
      final referralCode = await _ensureReferralCodeForUid(uid);
      final profile = _profileFromMaps(
        uid: uid,
        userData: userData,
        profileData: const <String, dynamic>{},
      ).copyWith(referralCode: referralCode, uagId: resolvedUagId);

      await profileDoc(uid).set(
        _arcProfileToUnifiedMap(profile, serverNow: now),
        SetOptions(merge: true),
      );
    } else {
      final updates = <String, dynamic>{
        'updatedAt': now,
        'lastActiveAt': now,
        'uagId': resolvedUagId,
        'gamerTag': resolvedUagId,
      };

      if (_string(profileData['referralCode']).isEmpty) {
        updates['referralCode'] = await _ensureReferralCodeForUid(uid);
      }

      if (_string(profileData['displayName']).isEmpty &&
          _string(profileData['uagName']).isNotEmpty) {
        updates['displayName'] = _string(profileData['uagName']);
      }
      if (_string(profileData['preferredPlatform']).isEmpty &&
          _string(profileData['platform']).isNotEmpty) {
        updates['preferredPlatform'] = _string(profileData['platform']);
      }

      await profileDoc(uid).set(updates, SetOptions(merge: true));
    }

    final publicProfileSnapshot = await profileDoc(uid).get();
    await _syncPublicProfile(
      _profileFromMaps(
        uid: uid,
        userData: userData,
        profileData: publicProfileSnapshot.data() ?? <String, dynamic>{},
      ).copyWith(uagId: resolvedUagId),
      serverNow: now,
    );

    final availabilitySnapshot = await availabilityDoc(uid).get();
    if (!availabilitySnapshot.exists) {
      await availabilityDoc(uid).set(ArcAvailability.initial().toMap());
    }

    final awaySnapshot = await awayDoc(uid).get();
    if (!awaySnapshot.exists) {
      await awayDoc(uid).set(ArcAwayStatus.initial().toMap());
    }
  }

  Future<ArcTraderProfile> getProfile() async {
    final uid = currentUid;
    if (uid == null) {
      throw StateError('No authenticated user found.');
    }

    await ensureDocsExist();
    final userSnap = await _userDoc(uid).get();
    final profileSnap = await profileDoc(uid).get();

    return _profileFromMaps(
      uid: uid,
      userData: userSnap.data() ?? <String, dynamic>{},
      profileData: profileSnap.data() ?? <String, dynamic>{},
    );
  }

  Stream<ArcTraderProfile> watchProfile() {
    final uid = currentUid;
    if (uid == null) {
      return const Stream.empty();
    }

    return profileDoc(uid).snapshots().asyncMap((profileSnapshot) async {
      final userSnapshot = await _userDoc(uid).get();
      return _profileFromMaps(
        uid: uid,
        userData: userSnapshot.data() ?? <String, dynamic>{},
        profileData: profileSnapshot.data() ?? <String, dynamic>{},
      );
    });
  }

  Future<void> saveProfile(ArcTraderProfile profile) async {
    final serverNow = FieldValue.serverTimestamp();
    final referralCode = profile.referralCode.trim().isEmpty
        ? await _ensureReferralCodeForUid(profile.uid)
        : profile.referralCode.trim();
    final uagId = await _ensureReservedUagIdForUid(
      profile.uid,
      preferredUagId: profile.uagId.trim(),
    );

    final normalisedProfile = profile.copyWith(
      uagId: uagId,
      referralCode: referralCode,
      isProfileComplete: false,
      updatedAt: DateTime.now(),
      lastActiveAt: DateTime.now(),
    );

    final profileMap = _arcProfileToUnifiedMap(
      normalisedProfile,
      serverNow: serverNow,
    );

    await profileDoc(profile.uid).set(profileMap, SetOptions(merge: true));
    await _syncPublicProfile(normalisedProfile, serverNow: serverNow);
    await _syncUagIdAcrossUserDocs(profile.uid, uagId);
    await _evaluateAndPersistProfileCompletion(
      profile.uid,
      profileDataOverride: profileMap,
    );
  }

  Future<ArcAvailability> getAvailability() async {
    final uid = currentUid;
    if (uid == null) throw StateError('No authenticated user found.');
    await ensureDocsExist();
    final snapshot = await availabilityDoc(uid).get();
    return ArcAvailability.fromMap(snapshot.data() ?? <String, dynamic>{});
  }

  Stream<ArcAvailability> watchAvailability() {
    final uid = currentUid;
    if (uid == null) return const Stream.empty();
    return availabilityDoc(uid).snapshots().map(
      (snapshot) =>
          ArcAvailability.fromMap(snapshot.data() ?? <String, dynamic>{}),
    );
  }

  Future<void> saveAvailability(ArcAvailability availability) async {
    final uid = currentUid;
    if (uid == null) throw StateError('No authenticated user found.');
    final now = FieldValue.serverTimestamp();
    final dayKeys = _activeAvailabilityDayKeys(availability);
    final batch = _firestore.batch();
    batch.set(availabilityDoc(uid), {
      ...availability.toMap(),
      'completed': true,
      'availabilityCompleted': true,
      'availabilityDayKeys': dayKeys,
      'updatedAt': now,
    }, SetOptions(merge: true));
    batch.set(profileDoc(uid), {
      'availabilityCompleted': true,
      'availabilityDayKeys': dayKeys,
      'traderProfile': {'availabilityCompleted': true},
      'updatedAt': now,
    }, SetOptions(merge: true));
    batch.set(_userDoc(uid), {
      'availabilityCompleted': true,
      'availabilityDayKeys': dayKeys,
      'traderProfile': {
        'availabilityCompleted': true,
        'availabilityDayKeys': dayKeys,
      },
      'updatedAt': now,
      'lastActiveAt': now,
    }, SetOptions(merge: true));
    await batch.commit();
    await _evaluateAndPersistProfileCompletion(
      uid,
      availabilityOverride: availability,
      availabilityDataOverride: <String, dynamic>{
        ...availability.toMap(),
        'completed': true,
        'availabilityCompleted': true,
        'availabilityDayKeys': dayKeys,
      },
    );
    await ArcOperationsRepository(
      firestore: _firestore,
      auth: _auth,
    ).recordAvailabilitySaved();
  }

  Future<ArcProfileCompletionResult> getProfileCompletion() async {
    final uid = currentUid;
    if (uid == null) {
      throw StateError('No authenticated user found.');
    }
    await ensureDocsExist();
    return _evaluateAndPersistProfileCompletion(uid);
  }

  Stream<ArcProfileCompletionResult> watchProfileCompletion() {
    final uid = currentUid;
    if (uid == null) {
      return Stream<ArcProfileCompletionResult>.value(
        ArcProfileCompletionResult.completeResult,
      );
    }

    final controller = StreamController<ArcProfileCompletionResult>();
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
    userSubscription;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
    profileSubscription;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
    availabilitySubscription;
    var disposed = false;
    var loadVersion = 0;
    var latestUser = const <String, dynamic>{};
    var latestProfile = const <String, dynamic>{};
    var latestAvailability = const <String, dynamic>{};

    void addError(Object error, StackTrace stackTrace) {
      if (!disposed && !controller.isClosed) {
        controller.addError(error, stackTrace);
      }
    }

    Future<void> emitState() async {
      final version = ++loadVersion;
      try {
        final availability = ArcAvailability.fromMap(latestAvailability);
        final result = const ArcProfileCompletionEvaluator().evaluate(
          userData: latestUser,
          profileData: latestProfile,
          availabilityData: latestAvailability,
          availability: availability,
        );
        if (!disposed && !controller.isClosed && version == loadVersion) {
          controller.add(result);
        }
      } catch (error, stackTrace) {
        addError(error, stackTrace);
      }
    }

    controller.onListen = () {
      userSubscription = _userDoc(uid).snapshots().listen((snapshot) {
        latestUser = snapshot.data() ?? const <String, dynamic>{};
        unawaited(emitState());
      }, onError: addError);
      profileSubscription = profileDoc(uid).snapshots().listen((snapshot) {
        latestProfile = snapshot.data() ?? const <String, dynamic>{};
        unawaited(emitState());
      }, onError: addError);
      availabilitySubscription = availabilityDoc(uid).snapshots().listen((
        snapshot,
      ) {
        latestAvailability = snapshot.data() ?? const <String, dynamic>{};
        unawaited(emitState());
      }, onError: addError);
    };

    controller.onCancel = () async {
      disposed = true;
      await userSubscription?.cancel();
      await profileSubscription?.cancel();
      await availabilitySubscription?.cancel();
    };

    return controller.stream;
  }

  Future<ArcProfileCompletionResult> refreshProfileCompletion() async {
    final uid = currentUid;
    if (uid == null) {
      throw StateError('No authenticated user found.');
    }
    return _evaluateAndPersistProfileCompletion(uid);
  }

  Future<ArcProfileCompletionResult> _evaluateAndPersistProfileCompletion(
    String uid, {
    Map<String, dynamic>? profileDataOverride,
    ArcAvailability? availabilityOverride,
    Map<String, dynamic>? availabilityDataOverride,
  }) async {
    final userSnapshot = await _userDoc(uid).get();
    final profileSnapshot = profileDataOverride == null
        ? await profileDoc(uid).get()
        : null;
    final availabilitySnapshot =
        availabilityOverride == null && availabilityDataOverride == null
        ? await availabilityDoc(uid).get()
        : null;

    final userData = userSnapshot.data() ?? const <String, dynamic>{};
    final profileData =
        profileDataOverride ??
        profileSnapshot?.data() ??
        const <String, dynamic>{};
    final availabilityData =
        availabilityDataOverride ??
        availabilitySnapshot?.data() ??
        const <String, dynamic>{};
    final availability =
        availabilityOverride ??
        ArcAvailability.fromMap(availabilityData);

    final result = const ArcProfileCompletionEvaluator().evaluate(
      userData: userData,
      profileData: profileData,
      availabilityData: availabilityData,
      availability: availability,
    );
    final now = FieldValue.serverTimestamp();
    final completionMap = <String, dynamic>{
      'complete': result.complete,
      'missingFieldIds': result.missingFieldIds,
      'missingFieldLabels': result.missingFieldLabels,
      'resumeRouteName': result.resumeRouteName,
      'resumeSection': result.resumeSection,
      'updatedAt': now,
    };

    final batch = _firestore.batch();
    batch.set(profileDoc(uid), {
      'isProfileComplete': result.complete,
      'profileCompletion': completionMap,
      'updatedAt': now,
    }, SetOptions(merge: true));
    batch.set(_userDoc(uid), {
      'profileCompletion': completionMap,
      'traderProfile': {'isProfileComplete': result.complete},
      'updatedAt': now,
    }, SetOptions(merge: true));
    await batch.commit();

    if (result.complete) {
      await ArcOperationsRepository(
        firestore: _firestore,
        auth: _auth,
      ).recordProfileCompleted();
    }

    return result;
  }

  List<String> _activeAvailabilityDayKeys(ArcAvailability availability) {
    final dayKeys = <String>{};
    for (final week in availability.weeks) {
      for (final slot in week.slots) {
        if (!slot.enabled) continue;
        final key = slot.dayKey.trim().toLowerCase();
        if (key.isNotEmpty) dayKeys.add(key);
      }
    }
    return dayKeys.toList(growable: false)..sort();
  }

  Future<ArcAwayStatus> getAwayStatus() async {
    final uid = currentUid;
    if (uid == null) throw StateError('No authenticated user found.');
    await ensureDocsExist();
    final snapshot = await awayDoc(uid).get();
    return ArcAwayStatus.fromMap(snapshot.data() ?? <String, dynamic>{});
  }

  Stream<ArcAwayStatus> watchAwayStatus() {
    final uid = currentUid;
    if (uid == null) return const Stream.empty();
    return awayDoc(uid).snapshots().map(
      (snapshot) =>
          ArcAwayStatus.fromMap(snapshot.data() ?? <String, dynamic>{}),
    );
  }

  Future<void> saveAwayStatus(ArcAwayStatus awayStatus) async {
    final uid = currentUid;
    if (uid == null) throw StateError('No authenticated user found.');
    await awayDoc(uid).set(awayStatus.toMap(), SetOptions(merge: true));
  }
}
