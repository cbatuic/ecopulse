class SensorSnapshot {
  final double temperature;
  final String temperatureUnit;
  final double dissolvedOxygen;
  final String oxygenUnit;
  final int oxygenRaw;
  final double oxygenVoltage;
  final int red;
  final int green;
  final int blue;
  final int clear;
  final double greenIndex;
  final String algaeStatus;
  final bool aeratorOn;
  final bool temperatureHighAlert;
  final bool temperatureLowAlert;
  final String smsAlert;
  final String smsTimestamp;
  final bool lowDoSmsAlert;
  final bool highAlgaeSmsAlert;

  const SensorSnapshot({
    required this.temperature,
    required this.temperatureUnit,
    required this.dissolvedOxygen,
    required this.oxygenUnit,
    required this.oxygenRaw,
    required this.oxygenVoltage,
    required this.red,
    required this.green,
    required this.blue,
    required this.clear,
    required this.greenIndex,
    required this.algaeStatus,
    required this.aeratorOn,
    required this.temperatureHighAlert,
    required this.temperatureLowAlert,
    this.smsAlert = '',
    this.smsTimestamp = '',
    this.lowDoSmsAlert = false,
    this.highAlgaeSmsAlert = false,
  });
}
