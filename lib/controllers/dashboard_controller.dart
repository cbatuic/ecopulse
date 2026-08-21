import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../models/pond_reading.dart';
import '../models/reading_history_point.dart';
import '../services/reading_history_database.dart';
import '../services/temperature_api.dart';

class DashboardController extends ChangeNotifier {
  DashboardController() {
    _reading = PondReading(
      dissolvedOxygen: 6.8,
      temperature: 27.4,
      red: 112,
      green: 168,
      blue: 84,
      clear: 248,
      greenIndex: 0.46,
      recordedAt: DateTime.now().subtract(const Duration(seconds: 12)),
    );
    unawaited(_loadHistory());
    _timer = Timer.periodic(Duration(seconds: _refreshSeconds), (_) => _pollSensors());
    unawaited(_pollSensors());
  }

  late PondReading _reading;
  late Timer _timer;
  bool _aeratorOn = false;
  int _selectedTab = 0;
  bool _isRefreshing = false;
  bool _temperatureApiOnline = false;
  int _refreshSeconds = 5;
  final TemperatureApi _temperatureApi = TemperatureApi();
  final ReadingHistoryDatabase _historyDatabase = ReadingHistoryDatabase();
  List<ReadingHistoryPoint> _history = const [];

  PondReading get reading => _reading;
  bool get aeratorOn => _aeratorOn;
  int get selectedTab => _selectedTab;
  bool get isRefreshing => _isRefreshing;
  int get refreshSeconds => _refreshSeconds;
  bool get temperatureApiOnline => _temperatureApiOnline;
  bool get sensorsApiOnline => _temperatureApiOnline;
  List<ReadingHistoryPoint> get history => _history;

  String get formattedSensorJson => const JsonEncoder.withIndent('  ').convert({
        'temperature': _reading.temperature,
        'temperature_unit': 'C',
        'dissolved_oxygen': _reading.dissolvedOxygen,
        'oxygen_unit': 'mg/L',
        'oxygen_raw': _reading.oxygenRaw,
        'oxygen_voltage': _reading.oxygenVoltage,
        'red': _reading.red,
        'green': _reading.green,
        'blue': _reading.blue,
        'clear': _reading.clear,
        'green_index': _reading.greenIndex,
        'algae_status': _reading.algaeStatus,
        'aerator_on': _reading.aeratorOn,
        'temperature_high_alert': _reading.temperatureHighAlert,
        'temperature_low_alert': _reading.temperatureLowAlert,
      });

  String get refreshLabel => 'Every $_refreshSeconds seconds';

  List<PondAlert> get alerts => [
        if (_reading.algaeRisk)
          PondAlert(
            title: 'Elevated algae indicator',
            detail: 'Green index is ${_reading.greenIndex.toStringAsFixed(2)}, above the 0.40 threshold.',
            level: AlertLevel.warning,
            time: 'Active now',
          ),
        PondAlert(
          title: _aeratorOn ? 'Aerator is running' : 'Aerator is off',
          detail: _aeratorOn ? 'The ESP32 reports relay GPIO 26 is active.' : 'The ESP32 reports relay GPIO 26 is inactive.',
          level: _aeratorOn ? AlertLevel.warning : AlertLevel.info,
          time: 'Live status',
        ),
        const PondAlert(
          title: 'Temperature in safe range',
          detail: 'Water temperature is stable for pond life.',
          level: AlertLevel.info,
          time: '42 min ago',
        ),
      ];

  void selectTab(int index) {
    _selectedTab = index;
    notifyListeners();
  }

  void setRefreshRate(int seconds) {
    if (_refreshSeconds == seconds) return;
    _refreshSeconds = seconds;
    _timer.cancel();
    _timer = Timer.periodic(Duration(seconds: seconds), (_) => _pollSensors());
    notifyListeners();
  }

  void toggleAerator() {
  }

  Future<void> refresh() async {
    _isRefreshing = true;
    notifyListeners();
    await _pollSensors();
    _isRefreshing = false;
    notifyListeners();
  }

  Future<void> _pollSensors() async {
    try {
      final sensors = await _temperatureApi.fetchSensors();
      _reading = _reading.copyWith(
        temperature: sensors.temperature,
        dissolvedOxygen: sensors.dissolvedOxygen,
        oxygenRaw: sensors.oxygenRaw,
        oxygenVoltage: sensors.oxygenVoltage,
        red: sensors.red,
        green: sensors.green,
        blue: sensors.blue,
        clear: sensors.clear,
        greenIndex: sensors.greenIndex,
        algaeStatus: sensors.algaeStatus,
        aeratorOn: sensors.aeratorOn,
        temperatureHighAlert: sensors.temperatureHighAlert,
        temperatureLowAlert: sensors.temperatureLowAlert,
        recordedAt: DateTime.now(),
      );
      _aeratorOn = sensors.aeratorOn;
      _temperatureApiOnline = true;
      await _historyDatabase.add(_reading);
      _history = await _historyDatabase.recent();
    } catch (_) {
      _temperatureApiOnline = false;
    }
    notifyListeners();
  }

  Future<void> _loadHistory() async {
    _history = await _historyDatabase.recent();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer.cancel();
    _temperatureApi.dispose();
    unawaited(_historyDatabase.close());
    super.dispose();
  }
}
