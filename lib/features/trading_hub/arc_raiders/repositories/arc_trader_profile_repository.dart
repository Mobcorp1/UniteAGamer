import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/arc_availability.dart';
import '../models/arc_away_status.dart';
import '../models/arc_trader_profile.dart';

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

    final createdAt = (profileData['createdAt'] as Timestamp?)?.toDate();
    final updatedAt = (profileData['updatedAt'] as Timestamp?)?.toDate();
    final lastActiveAt = (profileData['lastActiveAt'] as Timestamp?)?.toDate();

    return ArcTraderProfile.empty(uid).copyWith(
      uid: uid,
      uagId: uagId,
      uagName: uagName,
      embarkId: _string(profileData['embarkId']),
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
      'referralCode': profile.referralCode.trim(),
      'referredByCode': profile.referredByCode.trim(),
      'affiliateEnabled': profile.affiliateEnabled,
      'payoutMethod': profile.payoutMethod.trim(),
      'subscriptionStatus': profile.subscriptionStatus.trim(),
      'displayName': profile.uagName.trim().isEmpty
          ? 'New Trader'
          : profile.uagName.trim(),
      'gamerTag': profile.uagId.trim(),
      'preferredPlatform': profile.platform.trim(),
      'completedTrades': 0,
      'noShows': 0,
      'betrayalFlags': 0,
      'cancelledTrades': 0,
      'successfulTradeStreak': 0,
      'totalOffersSent': 0,
      'totalOffersReceived': 0,
      'foundingTrader': false,
      'updatedAt': serverNow,
      'lastActiveAt': serverNow,
      'createdAt': profile.createdAt == null
          ? serverNow
          : Timestamp.fromDate(profile.createdAt!),
    };
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

    await profileDoc(profile.uid).set(
      _arcProfileToUnifiedMap(
        profile.copyWith(
          uagId: uagId,
          referralCode: referralCode,
          isProfileComplete: profile.hasCoreDetails,
          updatedAt: DateTime.now(),
          lastActiveAt: DateTime.now(),
        ),
        serverNow: serverNow,
      ),
      SetOptions(merge: true),
    );

    await _syncUagIdAcrossUserDocs(profile.uid, uagId);
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
    await availabilityDoc(
      uid,
    ).set(availability.toMap(), SetOptions(merge: true));
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
