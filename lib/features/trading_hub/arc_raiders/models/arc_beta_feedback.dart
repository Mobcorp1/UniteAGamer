import 'package:cloud_firestore/cloud_firestore.dart';

enum ArcBetaFeedbackCategory {
  bug,
  userExperience,
  incorrectData,
  trade,
  blueprint,
  matchmaking,
  performance,
  suggestion,
}

extension ArcBetaFeedbackCategoryX on ArcBetaFeedbackCategory {
  String get label => switch (this) {
    ArcBetaFeedbackCategory.bug => 'Bug',
    ArcBetaFeedbackCategory.userExperience => 'UI / UX',
    ArcBetaFeedbackCategory.incorrectData => 'Incorrect data',
    ArcBetaFeedbackCategory.trade => 'Trade issue',
    ArcBetaFeedbackCategory.blueprint => 'Blueprint issue',
    ArcBetaFeedbackCategory.matchmaking => 'Matchmaking',
    ArcBetaFeedbackCategory.performance => 'Performance',
    ArcBetaFeedbackCategory.suggestion => 'Suggestion',
  };
}

enum ArcBetaFeedbackSeverity { low, medium, high, blocker }

extension ArcBetaFeedbackSeverityX on ArcBetaFeedbackSeverity {
  String get label => switch (this) {
    ArcBetaFeedbackSeverity.low => 'Low',
    ArcBetaFeedbackSeverity.medium => 'Medium',
    ArcBetaFeedbackSeverity.high => 'High',
    ArcBetaFeedbackSeverity.blocker => 'Blocker',
  };
}

enum ArcBetaFeedbackReproducibility { once, sometimes, always, notApplicable }

extension ArcBetaFeedbackReproducibilityX on ArcBetaFeedbackReproducibility {
  String get label => switch (this) {
    ArcBetaFeedbackReproducibility.once => 'Happened once',
    ArcBetaFeedbackReproducibility.sometimes => 'Sometimes',
    ArcBetaFeedbackReproducibility.always => 'Every time',
    ArcBetaFeedbackReproducibility.notApplicable => 'Not applicable',
  };
}

class ArcBetaFeedbackSubmission {
  const ArcBetaFeedbackSubmission({
    required this.uid,
    required this.category,
    required this.severity,
    required this.reproducibility,
    required this.description,
    required this.currentRoute,
    required this.platform,
    required this.screenWidth,
    required this.screenHeight,
    required this.locale,
    this.expectedOutcome = '',
  });

  final String uid;
  final ArcBetaFeedbackCategory category;
  final ArcBetaFeedbackSeverity severity;
  final ArcBetaFeedbackReproducibility reproducibility;
  final String description;
  final String expectedOutcome;
  final String currentRoute;
  final String platform;
  final double screenWidth;
  final double screenHeight;
  final String locale;

  Map<String, dynamic> toFirestore() => {
    'uid': uid,
    'category': category.name,
    'categoryLabel': category.label,
    'severity': severity.name,
    'reproducibility': reproducibility.name,
    'description': description.trim(),
    'expectedOutcome': expectedOutcome.trim(),
    'currentRoute': currentRoute,
    'platform': platform,
    'screenWidth': screenWidth,
    'screenHeight': screenHeight,
    'locale': locale,
    'appVersion': const String.fromEnvironment(
      'FLUTTER_BUILD_NAME',
      defaultValue: 'development',
    ),
    'buildNumber': const String.fromEnvironment(
      'FLUTTER_BUILD_NUMBER',
      defaultValue: 'development',
    ),
    'status': 'new',
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
