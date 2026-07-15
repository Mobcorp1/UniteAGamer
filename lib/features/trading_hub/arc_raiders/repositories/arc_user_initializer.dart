import 'package:firebase_auth/firebase_auth.dart';

import 'arc_operations_repository.dart';
import 'arc_season_reset_repository.dart';
import 'arc_trader_profile_repository.dart';

class ArcUserInitializer {
  ArcUserInitializer({
    ArcTraderProfileRepository? repository,
    ArcOperationsRepository? operationsRepository,
    ArcSeasonResetRepository? seasonResetRepository,
    FirebaseAuth? auth,
  }) : _repository = repository ?? ArcTraderProfileRepository(auth: auth),
       _operationsRepository =
           operationsRepository ?? ArcOperationsRepository(auth: auth),
       _seasonResetRepository =
           seasonResetRepository ?? ArcSeasonResetRepository(auth: auth),
       _auth = auth ?? FirebaseAuth.instance;

  final ArcTraderProfileRepository _repository;
  final ArcOperationsRepository _operationsRepository;
  final ArcSeasonResetRepository _seasonResetRepository;
  final FirebaseAuth _auth;

  Future<void> initialize() async {
    if (_auth.currentUser == null) return;
    await _repository.ensureDocsExist();
    try {
      await _seasonResetRepository.ensureSeasonStateExists();
      await _seasonResetRepository.reconcileInterruptedReset();
      await _repository.refreshProfileCompletion();
      await _operationsRepository.reconcileCurrentUserRewardsAndProgress();
      await _operationsRepository.recordLogin();
    } catch (_) {
      // Startup reconciliation should not prevent the user from entering Hub.
    }
  }
}
