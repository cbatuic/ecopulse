import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../models/bantai_insight.dart';
import '../models/pond_reading.dart';
import '../models/reading_history_point.dart';
import '../models/settings.dart';
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
  AppSettings _settings = const AppSettings();
  final TemperatureApi _temperatureApi = TemperatureApi();
  final ReadingHistoryDatabase _historyDatabase = ReadingHistoryDatabase();
  List<ReadingHistoryPoint> _history = const [];
  List<ReadingHistoryPoint> _bantaiHistory = const [];
  DateTime? _historyRangeStart;
  DateTime? _historyRangeEnd;

  PondReading get reading => _reading;
  bool get aeratorOn => _aeratorOn;
  int get selectedTab => _selectedTab;
  bool get isRefreshing => _isRefreshing;
  int get refreshSeconds => _refreshSeconds;
  bool get temperatureApiOnline => _temperatureApiOnline;
  bool get sensorsApiOnline => _temperatureApiOnline;
  List<ReadingHistoryPoint> get history => _history;
  List<ReadingHistoryPoint> get bantaiHistory => _bantaiHistory;
  AppSettings get settings => _settings;
  String get welcomeMessage => _settings.welcomeMessage;
  String get profileImageUrl => _settings.profileImageUrl;
  List<SmsAlertEntry> get smsAlerts => _settings.smsAlerts;
  BantAIInsight get bantaiInsight => BantAIInsight.analyze(current: _reading, history: _bantaiHistory);

  String get formattedSensorJson => _settings.rawJson.isNotEmpty
      ? _settings.rawJson
      : const JsonEncoder.withIndent('  ').convert({
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
          'sms_alert': _settings.smsAlert ?? '',
          'sms_timestamp': _settings.smsTimestamp?.toIso8601String() ?? '',
          'low_do_sms_alert': false,
          'high_algae_sms_alert': false,
        });

  String get refreshLabel => 'Every $_refreshSeconds seconds';
  String get apiEndpoint => _temperatureApi.endpoint;
  String _lastApiSmsTimestamp = '';

  void updateSettings(AppSettings settings) {
    _settings = settings;
    notifyListeners();
  }

  void updateProfile({String? welcomeMessage, String? profileImageUrl}) {
    _settings = _settings.copyWith(
      welcomeMessage: welcomeMessage,
      profileImageUrl: profileImageUrl,
    );
    notifyListeners();
  }

  void setRawJson(String rawJson) {
    _settings = _settings.copyWith(rawJson: rawJson);
    notifyListeners();
  }

  void setSmsAlert({required String message, DateTime? timestamp}) {
    final entry = SmsAlertEntry(
      message: message.trim(),
      timestamp: timestamp ?? DateTime.now(),
    );

    final updatedAlerts = [entry, ..._settings.smsAlerts].take(20).toList();
    _settings = _settings.copyWith(
      smsAlert: entry.message,
      smsTimestamp: entry.timestamp,
      smsAlerts: updatedAlerts,
    );
    notifyListeners();
  }

  void setApiEndpoint(String value) {
    _temperatureApi.setEndpoint(value);
    notifyListeners();
    unawaited(_pollSensors());
  }

  List<PondAlert> get alerts => [
        if (_settings.smsAlert != null && _settings.smsAlert!.trim().isNotEmpty)
          PondAlert(
            title: 'SMS alert received',
            detail: _settings.smsAlert!,
            level: _reading.lowOxygen || _reading.algaeRisk ? AlertLevel.critical : AlertLevel.warning,
            time: _settings.smsTimestamp != null ? _formatTimestamp(_settings.smsTimestamp!) : 'Source API',
          ),
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
    if (index == 8) {
      unawaited(_loadBantAIHistory());
    }
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
      final rawMap = {
        'temperature': sensors.temperature,
        'temperature_unit': sensors.temperatureUnit,
        'dissolved_oxygen': sensors.dissolvedOxygen,
        'oxygen_unit': sensors.oxygenUnit,
        'oxygen_raw': sensors.oxygenRaw,
        'oxygen_voltage': sensors.oxygenVoltage,
        'red': sensors.red,
        'green': sensors.green,
        'blue': sensors.blue,
        'clear': sensors.clear,
        'green_index': sensors.greenIndex,
        'algae_status': sensors.algaeStatus,
        'aerator_on': sensors.aeratorOn,
        'temperature_high_alert': sensors.temperatureHighAlert,
        'temperature_low_alert': sensors.temperatureLowAlert,
        'sms_alert': sensors.smsAlert,
        'sms_timestamp': sensors.smsTimestamp,
        'low_do_sms_alert': sensors.lowDoSmsAlert,
        'high_algae_sms_alert': sensors.highAlgaeSmsAlert,
      };
      _settings = _settings.copyWith(rawJson: const JsonEncoder.withIndent('  ').convert(rawMap));
      if (sensors.smsAlert.isNotEmpty && sensors.smsTimestamp != _lastApiSmsTimestamp) {
        _lastApiSmsTimestamp = sensors.smsTimestamp;
        setSmsAlert(
          message: sensors.smsAlert,
          timestamp: DateTime.tryParse(sensors.smsTimestamp) ?? DateTime.now(),
        );
      }
      await _historyDatabase.add(_reading);
        _history = _historyRangeStart == null || _historyRangeEnd == null
          ? await _historyDatabase.all()
          : await _historyDatabase.range(start: _historyRangeStart!, end: _historyRangeEnd!);
    } catch (_) {
      _temperatureApiOnline = false;
    }
    notifyListeners();
  }

  Future<void> _loadHistory() async {
    _history = _historyRangeStart == null || _historyRangeEnd == null
        ? await _historyDatabase.all()
        : await _historyDatabase.range(start: _historyRangeStart!, end: _historyRangeEnd!);
    notifyListeners();
  }

  Future<void> loadHistoryRange(DateTime start, DateTime end) async {
    final rangeEnd = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
    _historyRangeStart = start;
    _historyRangeEnd = rangeEnd;
    _history = await _historyDatabase.range(start: start, end: rangeEnd);
    notifyListeners();
  }

  Future<void> _loadBantAIHistory() async {
    _bantaiHistory = await _historyDatabase.referenceRange(
      start: DateTime(2026, 7, 1),
      end: DateTime(2026, 8, 28, 23, 59, 59, 999),
    );
    notifyListeners();
  }

  Future<void> loadBantAIReferenceRange(DateTime start, DateTime end) async {
    final rangeEnd = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
    _bantaiHistory = await _historyDatabase.referenceRange(start: start, end: rangeEnd);
    notifyListeners();
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inMinutes < 1) {
      return 'Just now';
    }
    if (diff.inHours < 1) {
      return '${diff.inMinutes} min ago';
    }
    return '${diff.inHours} hr ago';
  }

  @override
  void dispose() {
    _timer.cancel();
    _temperatureApi.dispose();
    unawaited(_historyDatabase.close());
    super.dispose();
  }
}
