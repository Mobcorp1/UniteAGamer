class UserProfile {
  final String serverPreference;
  final bool crossplayEnabled;

  const UserProfile({
    this.serverPreference = 'Automatic',
    this.crossplayEnabled = true,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      serverPreference: (map['serverPreference'] ?? 'Automatic').toString(),
      crossplayEnabled: map['crossplayEnabled'] is bool
          ? map['crossplayEnabled'] as bool
          : true,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'serverPreference': serverPreference,
        'crossplayEnabled': crossplayEnabled,
      };
}
