class SmsAlertEntry {
  final String message;
  final DateTime timestamp;

  const SmsAlertEntry({required this.message, required this.timestamp});

  factory SmsAlertEntry.fromJson(Map<String, dynamic> json) {
    return SmsAlertEntry(
      message: json['message'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'message': message,
        'timestamp': timestamp.toIso8601String(),
      };
}

class AppSettings {
  final String welcomeMessage;
  final String profileImageUrl;
  final String rawJson;
  final String? smsAlert;
  final DateTime? smsTimestamp;
  final List<SmsAlertEntry> smsAlerts;
  final List<String> tabs;

  const AppSettings({
    this.welcomeMessage = 'Good day, Beij',
    this.profileImageUrl = 'profile/profile.png',
    this.rawJson = '{\n  "status": "ready"\n}',
    this.smsAlert,
    this.smsTimestamp,
    this.smsAlerts = const <SmsAlertEntry>[],
    this.tabs = const ['Profile', 'Device', 'Alerts', 'Advanced'],
  });

  AppSettings copyWith({
    String? welcomeMessage,
    String? profileImageUrl,
    String? rawJson,
    String? smsAlert,
    DateTime? smsTimestamp,
    List<SmsAlertEntry>? smsAlerts,
    List<String>? tabs,
  }) {
    return AppSettings(
      welcomeMessage: welcomeMessage ?? this.welcomeMessage,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      rawJson: rawJson ?? this.rawJson,
      smsAlert: smsAlert ?? this.smsAlert,
      smsTimestamp: smsTimestamp ?? this.smsTimestamp,
      smsAlerts: smsAlerts ?? this.smsAlerts,
      tabs: tabs ?? this.tabs,
    );
  }
}
