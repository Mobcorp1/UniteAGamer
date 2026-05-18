import 'package:firebase_auth/firebase_auth.dart';

import 'arc_trader_profile_repository.dart';

class ArcUserInitializer {
  ArcUserInitializer({
    ArcTraderProfileRepository? repository,
    FirebaseAuth? auth,
  }) : _repository = repository ?? ArcTraderProfileRepository(auth: auth),
       _auth = auth ?? FirebaseAuth.instance;

  final ArcTraderProfileRepository _repository;
  final FirebaseAuth _auth;

  Future<void> initialize() async {
    if (_auth.currentUser == null) return;
    await _repository.ensureDocsExist();
  }
}
