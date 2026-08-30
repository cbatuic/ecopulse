import 'package:ecopulse/models/bantai_insight.dart';
import 'package:ecopulse/models/reading_history_point.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generateForecast computes a visible horizon for all regression methods', () {
    final history = List.generate(24, (index) {
      final time = DateTime.now().subtract(Duration(hours: 24 - index));
      final oxygen = 6.4 - (index * 0.06);
      final temperature = 27.1 + (index * 0.04);
      final green = 0.32 + (index * 0.008);
      final aerator = index % 4 == 0 ? 1 : 0;
      return ReadingHistoryPoint(
        recordedAt: time,
        temperature: temperature,
        dissolvedOxygen: oxygen,
        greenIndex: green,
        aeratorOn: aerator == 1,
      );
    });

    for (final method in BantAIRegressionMethod.values) {
      final forecast = BantAIInsight.generateForecast(
        history,
        windowValue: 3,
        windowUnit: BantAIWindowUnit.days,
        method: method,
      );

      expect(forecast.points, isNotEmpty);
      expect(forecast.points.length, greaterThanOrEqualTo(6));
      expect(forecast.points.every((point) => point.healthScore >= 0 && point.healthScore <= 100), isTrue);
    }
  });
}
