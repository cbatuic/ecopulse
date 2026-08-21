class PondReading {
  final double dissolvedOxygen;
  final double temperature;
  final int red;
  final int green;
  final int blue;
  final int clear;
  final double greenIndex;
  final int oxygenRaw;
  final double oxygenVoltage;
  final String algaeStatus;
  final bool aeratorOn;
  final bool temperatureHighAlert;
  final bool temperatureLowAlert;
  final DateTime recordedAt;

  const PondReading({
    required this.dissolvedOxygen,
    required this.temperature,
    required this.red,
    required this.green,
    required this.blue,
    required this.clear,
    required this.greenIndex,
    this.oxygenRaw = 0,
    this.oxygenVoltage = 0,
    this.algaeStatus = 'NORMAL',
    this.aeratorOn = false,
    this.temperatureHighAlert = false,
    this.temperatureLowAlert = false,
    required this.recordedAt,
  });

  bool get lowOxygen => dissolvedOxygen < 5.0;
  bool get algaeRisk => greenIndex >= 0.40;
  bool get highTemperature => temperature >= 32.0;
  bool get lowTemperature => temperature <= 20.0;

  PondReading copyWith({
    double? dissolvedOxygen,
    double? temperature,
    int? red,
    int? green,
    int? blue,
    int? clear,
    double? greenIndex,
    int? oxygenRaw,
    double? oxygenVoltage,
    String? algaeStatus,
    bool? aeratorOn,
    bool? temperatureHighAlert,
    bool? temperatureLowAlert,
    DateTime? recordedAt,
  }) {
    return PondReading(
      dissolvedOxygen: dissolvedOxygen ?? this.dissolvedOxygen,
      temperature: temperature ?? this.temperature,
      red: red ?? this.red,
      green: green ?? this.green,
      blue: blue ?? this.blue,
      clear: clear ?? this.clear,
      greenIndex: greenIndex ?? this.greenIndex,
      oxygenRaw: oxygenRaw ?? this.oxygenRaw,
      oxygenVoltage: oxygenVoltage ?? this.oxygenVoltage,
      algaeStatus: algaeStatus ?? this.algaeStatus,
      aeratorOn: aeratorOn ?? this.aeratorOn,
      temperatureHighAlert: temperatureHighAlert ?? this.temperatureHighAlert,
      temperatureLowAlert: temperatureLowAlert ?? this.temperatureLowAlert,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }
}

class PondAlert {
  final String title;
  final String detail;
  final AlertLevel level;
  final String time;

  const PondAlert({
    required this.title,
    required this.detail,
    required this.level,
    required this.time,
  });
}

enum AlertLevel { warning, critical, info }
