import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/sensor_snapshot.dart';

class TemperatureApi {
  TemperatureApi({http.Client? client, String endpoint = 'http://192.168.8.34/sensors'})
      : _client = client ?? http.Client(),
        _endpoint = Uri.parse(endpoint);

  final http.Client _client;
  Uri _endpoint;

  String get endpoint => _endpoint.toString();

  void setEndpoint(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw const FormatException('Enter a valid HTTP API URL');
    }
    _endpoint = uri;
  }

  Future<SensorSnapshot> fetchSensors() async {
    final response = await _client.get(_endpoint).timeout(const Duration(seconds: 4));
    if (response.statusCode != 200) {
      throw Exception('Sensors API returned ${response.statusCode}');
    }

    final payload = jsonDecode(response.body);
    if (payload is! Map<String, dynamic> ||
        payload['temperature'] is! num ||
        payload['dissolved_oxygen'] is! num ||
        payload['oxygen_raw'] is! num ||
        payload['oxygen_voltage'] is! num ||
        payload['red'] is! num ||
        payload['green'] is! num ||
        payload['blue'] is! num ||
        payload['clear'] is! num ||
        payload['green_index'] is! num ||
        payload['aerator_on'] is! bool ||
        payload['temperature_high_alert'] is! bool ||
        payload['temperature_low_alert'] is! bool) {
      throw const FormatException('Sensors API returned an invalid payload');
    }

    return SensorSnapshot(
      temperature: (payload['temperature'] as num).toDouble(),
      temperatureUnit: payload['temperature_unit'] as String? ?? 'C',
      dissolvedOxygen: (payload['dissolved_oxygen'] as num).toDouble(),
      oxygenUnit: payload['oxygen_unit'] as String? ?? 'mg/L',
      oxygenRaw: (payload['oxygen_raw'] as num).toInt(),
      oxygenVoltage: (payload['oxygen_voltage'] as num).toDouble(),
      red: (payload['red'] as num).toInt(),
      green: (payload['green'] as num).toInt(),
      blue: (payload['blue'] as num).toInt(),
      clear: (payload['clear'] as num).toInt(),
      greenIndex: (payload['green_index'] as num).toDouble(),
      algaeStatus: payload['algae_status'] as String? ?? 'UNKNOWN',
      aeratorOn: payload['aerator_on'] as bool,
      temperatureHighAlert: payload['temperature_high_alert'] as bool,
      temperatureLowAlert: payload['temperature_low_alert'] as bool,
      smsAlert: payload['sms_alert'] as String? ?? '',
      smsTimestamp: payload['sms_timestamp'] as String? ?? '',
      lowDoSmsAlert: payload['low_do_sms_alert'] as bool? ?? false,
      highAlgaeSmsAlert: payload['high_algae_sms_alert'] as bool? ?? false,
    );
  }

  void dispose() => _client.close();
}
