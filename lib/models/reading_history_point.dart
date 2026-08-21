class ReadingHistoryPoint {
  final DateTime recordedAt;
  final double temperature;
  final double dissolvedOxygen;
  final double greenIndex;

  const ReadingHistoryPoint({
    required this.recordedAt,
    required this.temperature,
    required this.dissolvedOxygen,
    required this.greenIndex,
  });
}
