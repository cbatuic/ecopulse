class ReadingHistoryPoint {
  final DateTime recordedAt;
  final double temperature;
  final double dissolvedOxygen;
  final double greenIndex;
  final bool aeratorOn;

  const ReadingHistoryPoint({
    required this.recordedAt,
    required this.temperature,
    required this.dissolvedOxygen,
    required this.greenIndex,
    this.aeratorOn = false,
  });
}
