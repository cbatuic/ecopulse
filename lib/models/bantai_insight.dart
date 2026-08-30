import 'dart:math';

import 'pond_reading.dart';
import 'reading_history_point.dart';

enum BantAIRegressionMethod {
  linear,
  polynomial,
  ridge,
}

enum BantAIWindowUnit {
  hours,
  days,
  weeks,
}

class BantAIForecastPoint {
  final DateTime timestamp;
  final double healthScore;

  const BantAIForecastPoint({
    required this.timestamp,
    required this.healthScore,
  });
}

class BantAIForecast {
  final String title;
  final List<BantAIForecastPoint> points;
  final double projectedHealthScore;
  final String summary;

  const BantAIForecast({
    required this.title,
    required this.points,
    required this.projectedHealthScore,
    required this.summary,
  });
}

class BantAIInsight {
  final String riskLabel;
  final String prediction;
  final String summary;
  final String recommendedAction;
  final double confidence;
  final String predictedIssue;

  const BantAIInsight({
    required this.riskLabel,
    required this.prediction,
    required this.summary,
    required this.recommendedAction,
    required this.confidence,
    required this.predictedIssue,
  });

  static BantAIInsight analyze({
    required PondReading current,
    required List<ReadingHistoryPoint> history,
  }) {
    final oxygenHistory = history.map((point) => point.dissolvedOxygen).toList();
    final tempHistory = history.map((point) => point.temperature).toList();
    final avgOxygen = oxygenHistory.isEmpty ? current.dissolvedOxygen : oxygenHistory.reduce((a, b) => a + b) / oxygenHistory.length;
    final avgTemp = tempHistory.isEmpty ? current.temperature : tempHistory.reduce((a, b) => a + b) / tempHistory.length;
    final oxygenTrend = oxygenHistory.length >= 2 ? oxygenHistory.last - oxygenHistory.first : 0;
    final tempTrend = tempHistory.length >= 2 ? tempHistory.last - tempHistory.first : 0;

    double score = 0;
    if (current.lowOxygen) score += 0.45;
    if (current.algaeRisk) score += 0.25;
    if (current.highTemperature) score += 0.25;
    if (avgOxygen < 5.5) score += 0.15;
    if (avgTemp > 29.0) score += 0.15;
    if (oxygenTrend < 0) score += 0.2;
    if (tempTrend > 0) score += 0.2;

    if (score >= 0.9) {
      return const BantAIInsight(
        riskLabel: 'Critical',
        prediction: 'High probability of a rapid pond health decline within the next few hours.',
        summary: 'Dissolved oxygen is falling, the algae indicator is elevated, and recent conditions indicate the pond may become unstable soon.',
        recommendedAction: 'Increase aeration, reduce feeding, and inspect the pond immediately for oxygen stress or bloom conditions.',
        confidence: 0.92,
        predictedIssue: 'Oxygen crash and algae-driven stress',
      );
    }
    if (score >= 0.6) {
      return const BantAIInsight(
        riskLabel: 'High',
        prediction: 'A likely deterioration pattern is forming over the next day.',
        summary: 'Recent readings and historical trend data show worsening oxygen and temperature conditions, even though the current threshold has not yet fully crossed the critical line.',
        recommendedAction: 'Increase aeration and check temperature and algae trends before the pond becomes unstable.',
        confidence: 0.81,
        predictedIssue: 'Worsening oxygen stress and thermal imbalance',
      );
    }
    if (score >= 0.3) {
      return const BantAIInsight(
        riskLabel: 'Moderate',
        prediction: 'Conditions are trending toward an unhealthy pond state over the next few days.',
        summary: 'The environment is stable for now, but combined temperature, oxygen, and algae trends suggest a higher risk if the pattern continues.',
        recommendedAction: 'Monitor the pond closely and prepare a preventive aeration or water-quality response.',
        confidence: 0.71,
        predictedIssue: 'Slow deterioration in pond health',
      );
    }

    return const BantAIInsight(
      riskLabel: 'Low',
      prediction: 'Pond conditions appear stable in the near term.',
      summary: 'Current values and historical trends remain within the expected operating range for the pond environment.',
      recommendedAction: 'Continue routine monitoring and keep the current aeration and maintenance schedule.',
      confidence: 0.75,
      predictedIssue: 'No imminent health risk expected',
    );
  }

  static BantAIForecast generateForecast(
    List<ReadingHistoryPoint> history, {
    required int windowValue,
    required BantAIWindowUnit windowUnit,
    required BantAIRegressionMethod method,
  }) {
    if (history.isEmpty) {
      return BantAIForecast(
        title: 'No pond history available',
        points: const [],
        projectedHealthScore: 0.0,
        summary: 'No persisted SQLite readings are available for this date range.',
      );
    }

    final normalized = history.length > 40 ? history.sublist(history.length - 40) : history;
    final featureRows = <List<double>>[];
    final targets = <double>[];

    for (final point in normalized) {
      final score = _healthScoreFromReading(point);
      targets.add(score);
      featureRows.add(_featureVector(point, method));
    }

    final coefficients = _solveRegression(featureRows, targets, method);
    final stepCount = max(6, min(12, windowValue * 2));
    final horizonMultiplier = switch (windowUnit) {
      BantAIWindowUnit.hours => 1,
      BantAIWindowUnit.days => 24,
      BantAIWindowUnit.weeks => 168,
    };
    final totalHours = windowValue * horizonMultiplier;

    final forecastPoints = <BantAIForecastPoint>[];
    final last = normalized.last;
    final oxygenSlope = normalized.length > 1 ? (last.dissolvedOxygen - normalized.first.dissolvedOxygen) / normalized.length : 0.0;
    final tempSlope = normalized.length > 1 ? (last.temperature - normalized.first.temperature) / normalized.length : 0.0;
    final greenSlope = normalized.length > 1 ? (last.greenIndex - normalized.first.greenIndex) / normalized.length : 0.0;

    for (var i = 0; i <= stepCount; i++) {
      final progress = i / stepCount;
      final futureOxygen = (last.dissolvedOxygen + oxygenSlope * (totalHours / 24) * progress).clamp(1.0, 12.0);
      final futureTemp = (last.temperature + tempSlope * (totalHours / 24) * progress).clamp(15.0, 40.0);
      final futureGreen = (last.greenIndex + greenSlope * (totalHours / 24) * progress).clamp(0.1, 0.8);
      final futureAerator = (last.aeratorOn || futureOxygen < 5.0) ? true : false;
      final vector = _featureVector(
        ReadingHistoryPoint(
          recordedAt: DateTime.now().add(Duration(hours: (totalHours * progress).round())),
          temperature: futureTemp,
          dissolvedOxygen: futureOxygen,
          greenIndex: futureGreen,
          aeratorOn: futureAerator,
        ),
        method,
      );
      var prediction = 0.0;
      for (var index = 0; index < vector.length; index++) {
        prediction += coefficients[index] * vector[index];
      }
      final healthScore = prediction.clamp(0.0, 100.0);
      forecastPoints.add(BantAIForecastPoint(
        timestamp: DateTime.now().add(Duration(hours: (totalHours * progress).round())),
        healthScore: healthScore,
      ));
    }

    final projected = forecastPoints.isNotEmpty ? forecastPoints.last.healthScore : 0.0;
    return BantAIForecast(
      title: 'Forecast using ${_methodLabel(method)} over ${windowValue.toString()} ${_windowLabel(windowUnit)}',
      points: forecastPoints,
      projectedHealthScore: projected,
      summary: _buildSummary(projected, method, windowValue, windowUnit),
    );
  }

  static double _healthScoreFromReading(ReadingHistoryPoint point) {
    double score = 100.0;
    score -= (point.temperature - 27.0).abs() * 2.2;
    score -= max(0.0, 5.0 - point.dissolvedOxygen) * 13.0;
    score -= max(0.0, point.greenIndex - 0.25) * 180.0;
    if (point.aeratorOn) {
      score += 8.0;
    }
    return score.clamp(0.0, 100.0);
  }

  static List<double> _featureVector(ReadingHistoryPoint point, BantAIRegressionMethod method) {
    final oxygen = point.dissolvedOxygen;
    final temperature = point.temperature;
    final green = point.greenIndex;
    final aerator = point.aeratorOn ? 1.0 : 0.0;

    switch (method) {
      case BantAIRegressionMethod.linear:
        return [1.0, oxygen, temperature, green, aerator];
      case BantAIRegressionMethod.polynomial:
        return [
          1.0,
          oxygen,
          temperature,
          green,
          aerator,
          oxygen * oxygen,
          temperature * temperature,
          green * green,
          oxygen * temperature,
          oxygen * green,
          aerator * oxygen,
          aerator * temperature,
        ];
      case BantAIRegressionMethod.ridge:
        return [1.0, oxygen, temperature, green, aerator];
    }
  }

  static List<double> _solveRegression(List<List<double>> rows, List<double> targets, BantAIRegressionMethod method) {
    final n = rows.first.length;
    final xTx = List.generate(n, (_) => List<double>.filled(n, 0.0));
    final xTy = List<double>.filled(n, 0.0);

    for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      for (var i = 0; i < n; i++) {
        xTy[i] += row[i] * targets[rowIndex];
        for (var j = 0; j < n; j++) {
          xTx[i][j] += row[i] * row[j];
        }
      }
    }

    final ridge = method == BantAIRegressionMethod.ridge ? 0.15 : 0.0;
    for (var i = 0; i < n; i++) {
      xTx[i][i] += ridge;
    }

    final coefficients = _solveLinearSystem(xTx, xTy);
    return coefficients;
  }

  static List<double> _solveLinearSystem(List<List<double>> matrix, List<double> rhs) {
    final n = rhs.length;
    final augmented = List.generate(n, (rowIndex) {
      final row = List<double>.from(matrix[rowIndex]);
      row.add(rhs[rowIndex]);
      return row;
    });

    for (var pivot = 0; pivot < n; pivot++) {
      var maxRow = pivot;
      for (var row = pivot + 1; row < n; row++) {
        if ((augmented[row][pivot]).abs() > (augmented[maxRow][pivot]).abs()) {
          maxRow = row;
        }
      }
      if ((augmented[maxRow][pivot]).abs() < 1e-9) {
        continue;
      }
      if (maxRow != pivot) {
        final temp = augmented[pivot];
        augmented[pivot] = augmented[maxRow];
        augmented[maxRow] = temp;
      }
      final pivotValue = augmented[pivot][pivot];
      for (var column = pivot; column <= n; column++) {
        augmented[pivot][column] /= pivotValue;
      }
      for (var row = 0; row < n; row++) {
        if (row == pivot) continue;
        final factor = augmented[row][pivot];
        if (factor == 0) continue;
        for (var column = pivot; column <= n; column++) {
          augmented[row][column] -= factor * augmented[pivot][column];
        }
      }
    }

    return List.generate(n, (index) => augmented[index][n]);
  }

  static String _methodLabel(BantAIRegressionMethod method) => switch (method) {
        BantAIRegressionMethod.linear => 'Linear regression',
        BantAIRegressionMethod.polynomial => 'Polynomial regression',
        BantAIRegressionMethod.ridge => 'Ridge regression',
      };

  static String _windowLabel(BantAIWindowUnit unit) => switch (unit) {
        BantAIWindowUnit.hours => 'hours',
        BantAIWindowUnit.days => 'days',
        BantAIWindowUnit.weeks => 'weeks',
      };

  static String _buildSummary(double projected, BantAIRegressionMethod method, int windowValue, BantAIWindowUnit unit) {
    final label = _methodLabel(method);
    final health = projected.round();
    final horizon = '$windowValue ${_windowLabel(unit)}';
    if (health >= 75) {
      return '$label suggests the pond should remain healthy over the next $horizon.';
    }
    if (health >= 50) {
      return '$label indicates a moderate risk profile over the next $horizon; monitor aeration and algae levels.';
    }
    return '$label projects a deteriorating pond condition over the next $horizon, so preventive action is recommended.';
  }
}
