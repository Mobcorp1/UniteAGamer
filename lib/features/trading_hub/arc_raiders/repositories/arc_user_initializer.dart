import 'package:firebase_auth/firebase_auth.dart';

import 'arc_operations_repository.dart';
import 'arc_trader_profile_repository.dart';

class ArcUserInitializer {
  ArcUserInitializer({
    ArcTraderProfileRepository? repository,
    ArcOperationsRepository? operationsRepository,
    FirebaseAuth? auth,
  }) : _repository = repository ?? ArcTraderProfileRepository(auth: auth),
       _operationsRepository =
           operationsRepository ?? ArcOperationsRepository(auth: auth),
       _auth = auth ?? FirebaseAuth.instance;

  final ArcTraderProfileRepository _repository;
  final ArcOperationsRepository _operationsRepository;
  final FirebaseAuth _auth;

  Future<void> initialize() async {
    if (_auth.currentUser == null) return;
    await _repository.ensureDocsExist();
    try {
      await _repository.refreshProfileCompletion();
      await _operationsRepository.reconcileCurrentUserRewardsAndProgress();
      await _operationsRepository.recordLogin();
    } catch (_) {
      // Startup reconciliation should not prevent the user from entering Hub.
    }
  }
}
