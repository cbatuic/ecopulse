import 'dart:math';

import 'package:flutter/material.dart';

import '../controllers/dashboard_controller.dart';
import '../models/pond_reading.dart';
import '../models/reading_history_point.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key, required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final reading = controller.reading;
        return Scaffold(
          backgroundColor: const Color(0xFFF5F7F6),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 960;
                return Row(
                  children: [
                    if (isDesktop) _NavigationRail(controller: controller),
                    Expanded(
                      child: Column(
                        children: [
                          _TopBar(controller: controller),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: EdgeInsets.fromLTRB(isDesktop ? 40 : 20, 18, isDesktop ? 40 : 20, 32),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 1240),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: _contentForTab(controller, reading),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (!isDesktop) _BottomNavigation(controller: controller),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  List<Widget> _contentForTab(DashboardController controller, PondReading reading) {
    if (controller.selectedTab == 0) {
      return [
        _HeroHeader(reading: reading),
        const SizedBox(height: 24),
        _MetricGrid(reading: reading, aeratorOn: controller.aeratorOn),
        const SizedBox(height: 24),
        _LowerGrid(controller: controller),
      ];
    }
    if (controller.selectedTab == 5) return [_PageHeader(title: 'Alerts', subtitle: 'Review pond events and sensor warnings.'), const SizedBox(height: 24), _AlertsPanel(alerts: controller.alerts)];
    if (controller.selectedTab == 6) return [_PageHeader(title: 'Settings', subtitle: 'Tune how EcoPulse watches your pond.'), const SizedBox(height: 24), _SettingsPanel(controller: controller)];
    if (controller.selectedTab == 7) return [_PageHeader(title: 'Raw JSON', subtitle: 'Formatted payload from the live ESP32 sensors endpoint.'), const SizedBox(height: 24), _RawJsonPanel(json: controller.formattedSensorJson)];
    return [_SensorDetail(controller: controller, sensor: controller.selectedTab), const SizedBox(height: 24), _MetricGrid(reading: reading, aeratorOn: controller.aeratorOn)];
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.controller});
  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Color(0xFFE3E9E6)))),
      child: Row(
        children: [
          if (MediaQuery.sizeOf(context).width < 960) ...[
            const _BrandMark(),
            const SizedBox(width: 12),
          ],
          const Spacer(),
          _ConnectionPill(temperatureApiOnline: controller.temperatureApiOnline),
          const SizedBox(width: 14),
          IconButton(
            tooltip: 'Refresh readings',
            onPressed: controller.isRefreshing ? null : controller.refresh,
            icon: AnimatedRotation(
              turns: controller.isRefreshing ? 1 : 0,
              duration: const Duration(milliseconds: 700),
              child: const Icon(Icons.refresh_rounded),
            ),
          ),
          const SizedBox(width: 6),
          const CircleAvatar(radius: 18, backgroundColor: Color(0xFFE0F2EC), child: Icon(Icons.person_outline_rounded, color: Color(0xFF126B58), size: 20)),
        ],
      ),
    );
  }
}

class _NavigationRail extends StatelessWidget {
  const _NavigationRail({required this.controller});
  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 246,
      color: const Color(0xFF102E2B),
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(padding: EdgeInsets.only(left: 10, bottom: 44), child: _BrandMark(dark: true)),
          const Padding(padding: EdgeInsets.only(left: 12, bottom: 12), child: Text('WORKSPACE', style: TextStyle(color: Color(0xFF83A9A1), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5))),
          _NavItem(icon: Icons.grid_view_rounded, label: 'Overview', selected: controller.selectedTab == 0, onTap: () => controller.selectTab(0)),
          const Padding(padding: EdgeInsets.only(left: 12, top: 13, bottom: 7), child: Text('SENSORS', style: TextStyle(color: Color(0xFF83A9A1), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5))),
          _NavItem(icon: Icons.bubble_chart_rounded, label: 'Dissolved oxygen', selected: controller.selectedTab == 1, onTap: () => controller.selectTab(1)),
          _NavItem(icon: Icons.thermostat_rounded, label: 'Temperature', selected: controller.selectedTab == 2, onTap: () => controller.selectTab(2)),
          _NavItem(icon: Icons.palette_outlined, label: 'Color sensor', selected: controller.selectedTab == 3, onTap: () => controller.selectTab(3)),
          _NavItem(icon: Icons.air_rounded, label: 'Aerator relay', selected: controller.selectedTab == 4, onTap: () => controller.selectTab(4)),
          _NavItem(icon: Icons.notifications_none_rounded, label: 'Alerts', selected: controller.selectedTab == 5, onTap: () => controller.selectTab(5)),
          _NavItem(icon: Icons.data_object_rounded, label: 'Raw JSON', selected: controller.selectedTab == 7, onTap: () => controller.selectTab(7)),
          const Spacer(),
          _NavItem(icon: Icons.settings_outlined, label: 'Settings', selected: controller.selectedTab == 6, onTap: () => controller.selectTab(6)),
          const SizedBox(height: 14),
          const Padding(padding: EdgeInsets.only(left: 12), child: Text('ECOPULSE v1.0.0', style: TextStyle(color: Color(0xFF668A83), fontSize: 10, letterSpacing: 1))),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({this.dark = false});
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final primary = dark ? Colors.white : const Color(0xFF143B35);
    return Row(children: [Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFF8DE1C8), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.water_drop_rounded, color: Color(0xFF103E35), size: 19)), const SizedBox(width: 10), Text('EcoPulse', style: TextStyle(color: primary, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.4))]);
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 5), child: ListTile(onTap: onTap, dense: true, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), selected: selected, selectedTileColor: const Color(0xFF27574F), leading: Icon(icon, color: selected ? const Color(0xFF9CE8D2) : const Color(0xFF91AAA5), size: 21), title: Text(label, style: TextStyle(color: selected ? Colors.white : const Color(0xFFB1C5C0), fontWeight: selected ? FontWeight.w700 : FontWeight.w500, fontSize: 13))));
  }
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({required this.controller});
  final DashboardController controller;
  @override
  Widget build(BuildContext context) => NavigationBar(height: 70, selectedIndex: controller.selectedTab == 0 ? 0 : controller.selectedTab == 5 ? 2 : controller.selectedTab == 6 ? 3 : controller.selectedTab == 7 ? 4 : 1, onDestinationSelected: (index) => controller.selectTab(index == 1 ? 1 : index == 2 ? 5 : index == 3 ? 6 : index == 4 ? 7 : 0), destinations: const [NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'Overview'), NavigationDestination(icon: Icon(Icons.sensors_rounded), label: 'Sensors'), NavigationDestination(icon: Icon(Icons.notifications_none_rounded), label: 'Alerts'), NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'), NavigationDestination(icon: Icon(Icons.data_object_rounded), label: 'JSON')]);
}

class _ConnectionPill extends StatelessWidget {
  const _ConnectionPill({required this.temperatureApiOnline});
  final bool temperatureApiOnline;

  @override
  Widget build(BuildContext context) {
    final color = temperatureApiOnline ? const Color(0xFF19735C) : const Color(0xFFB4772E);
    return Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7), decoration: BoxDecoration(color: temperatureApiOnline ? const Color(0xFFE7F7F0) : const Color(0xFFFFF3DF), borderRadius: BorderRadius.circular(20)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(temperatureApiOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded, size: 15, color: color), const SizedBox(width: 6), Text(temperatureApiOnline ? 'Sensors API online' : 'Sensors API offline', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700))]));
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Color(0xFF143B35), fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -1)), const SizedBox(height: 7), Text(subtitle, style: TextStyle(color: Colors.blueGrey.shade500, fontSize: 14))]);
}

class _RawJsonPanel extends StatelessWidget {
  const _RawJsonPanel({required this.json});
  final String json;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: const Color(0xFF102E2B), borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [Icon(Icons.data_object_rounded, color: Color(0xFF8DE1C8), size: 20), SizedBox(width: 9), Text('Latest sensor payload', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800))]),
          const SizedBox(height: 7),
          const Text('GET /sensors  ·  formatted for inspection', style: TextStyle(color: Color(0xFF8FB4AC), fontSize: 12)),
          const SizedBox(height: 20),
          Container(width: double.infinity, padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: const Color(0xFF173F38), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF2B5B51))), child: SelectableText(json, style: const TextStyle(color: Color(0xFFD1EEE5), fontSize: 13, height: 1.55, fontFamily: 'monospace'))),
        ]),
      );
}

class _SensorDetail extends StatelessWidget {
  const _SensorDetail({required this.controller, required this.sensor});
  final DashboardController controller;
  final int sensor;

  @override
  Widget build(BuildContext context) {
    final reading = controller.reading;
    final data = switch (sensor) {
      1 => (title: 'Dissolved oxygen', subtitle: 'Gravity analog DO sensor · GPIO 34', icon: Icons.bubble_chart_rounded, value: reading.dissolvedOxygen.toStringAsFixed(1), unit: 'mg/L', status: reading.lowOxygen ? 'Needs attention' : 'Healthy', threshold: 'Healthy above 5.0 mg/L', color: const Color(0xFF267FA6)),
      2 => (title: 'Water temperature', subtitle: 'DS18B20 waterproof probe · GPIO 4', icon: Icons.thermostat_rounded, value: reading.temperature.toStringAsFixed(1), unit: '°C', status: reading.temperatureHighAlert || reading.temperatureLowAlert ? 'Outside range' : 'Optimal', threshold: 'Target range 20 - 32 °C', color: const Color(0xFFD07C36)),
      3 => (title: 'Color sensor', subtitle: 'Adafruit TCS34725 · I2C 21 / 22', icon: Icons.palette_outlined, value: reading.greenIndex.toStringAsFixed(2), unit: 'green index', status: reading.algaeRisk ? 'Elevated' : 'Clear', threshold: 'Algae indicator at 0.40', color: const Color(0xFF218C70)),
      _ => (title: 'Aerator relay', subtitle: '5V relay output · GPIO 26', icon: Icons.air_rounded, value: controller.aeratorOn ? 'ON' : 'OFF', unit: 'relay state', status: controller.aeratorOn ? 'Running now' : 'Standby', threshold: 'Automatic hysteresis control', color: const Color(0xFF218C70)),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageHeader(title: data.title, subtitle: data.subtitle),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E9E6))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(width: 48, height: 48, decoration: BoxDecoration(color: data.color.withValues(alpha: .12), borderRadius: BorderRadius.circular(13)), child: Icon(data.icon, color: data.color, size: 25)),
                const Spacer(),
                _LiveTag(),
              ]),
              const SizedBox(height: 24),
              Text(data.value, style: const TextStyle(color: Color(0xFF143B35), fontSize: 48, fontWeight: FontWeight.w800, letterSpacing: -2)),
              const SizedBox(height: 3),
              Text(data.unit, style: TextStyle(color: data.color, fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 18),
              _SensorFacts(reading: reading, sensor: sensor),
              const SizedBox(height: 18),
              Row(children: [
                Container(width: 9, height: 9, decoration: BoxDecoration(color: data.color, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(data.status, style: TextStyle(color: data.color, fontSize: 13, fontWeight: FontWeight.w800)),
                const Spacer(),
                Text(data.threshold, style: const TextStyle(color: Color(0xFF71847F), fontSize: 12)),
              ]),
              const SizedBox(height: 26),
              _ReadingChart(color: data.color, points: controller.history, sensor: sensor),
            ],
          ),
        ),
      ],
    );
  }
}

class _SensorFacts extends StatelessWidget {
  const _SensorFacts({required this.reading, required this.sensor});
  final PondReading reading;
  final int sensor;

  @override
  Widget build(BuildContext context) {
    final facts = sensor == 1
        ? [('Raw ADC', '${reading.oxygenRaw}'), ('Voltage', '${reading.oxygenVoltage.toStringAsFixed(3)} V')]
        : sensor == 3
            ? [('RGB', '${reading.red} / ${reading.green} / ${reading.blue}'), ('Clear', '${reading.clear}'), ('Algae', reading.algaeStatus)]
            : <(String, String)>[];
    if (facts.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 10, runSpacing: 10, children: facts.map((fact) => Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8), decoration: BoxDecoration(color: const Color(0xFFF5F8F6), borderRadius: BorderRadius.circular(8)), child: RichText(text: TextSpan(children: [TextSpan(text: '${fact.$1}  ', style: const TextStyle(color: Color(0xFF7A8B86), fontSize: 11)), TextSpan(text: fact.$2, style: const TextStyle(color: Color(0xFF27443E), fontSize: 11, fontWeight: FontWeight.w800))])))).toList());
  }
}

class _LiveTag extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: const Color(0xFFE7F7F0), borderRadius: BorderRadius.circular(18)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.sensors_rounded, size: 14, color: Color(0xFF19735C)), SizedBox(width: 5), Text('LIVE', style: TextStyle(color: Color(0xFF19735C), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1))]));
}

class _ReadingChart extends StatelessWidget {
  const _ReadingChart({required this.color, required this.points, required this.sensor});
  final Color color;
  final List<ReadingHistoryPoint> points;
  final int sensor;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(height: 130, child: Center(child: Text('Waiting for the first persisted reading...', style: TextStyle(color: Color(0xFF8B9A96), fontSize: 12))));
    }
    return SizedBox(height: 142, width: double.infinity, child: CustomPaint(painter: _HistoryChartPainter(color: color, points: points, sensor: sensor)));
  }
}

class _HistoryChartPainter extends CustomPainter {
  const _HistoryChartPainter({required this.color, required this.points, required this.sensor});
  final Color color;
  final List<ReadingHistoryPoint> points;
  final int sensor;

  @override
  void paint(Canvas canvas, Size size) {
    final chartHeight = size.height - 24;
    final values = points.map(_value).toList();
    final minValue = values.reduce(min);
    final maxValue = values.reduce(max);
    final range = max(maxValue - minValue, 0.01);
    final gridPaint = Paint()..color = const Color(0xFFE7EEEB)..strokeWidth = 1;
    for (var row = 0; row < 3; row++) {
      final y = chartHeight * row / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final path = Path();
    for (var index = 0; index < values.length; index++) {
      final x = values.length == 1 ? size.width / 2 : size.width * index / (values.length - 1);
      final y = chartHeight - ((values[index] - minValue) / range * (chartHeight - 16)) - 8;
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 3.5, Paint()..color = color);
    }
    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2.5..strokeCap = StrokeCap.round);
    final labelPaint = TextPainter(textDirection: TextDirection.ltr);
    for (var index = 0; index < points.length; index += max(1, points.length ~/ 4)) {
      final x = points.length == 1 ? size.width / 2 : size.width * index / (points.length - 1);
      labelPaint.text = TextSpan(text: _formatTime(points[index].recordedAt), style: const TextStyle(color: Color(0xFF98A6A2), fontSize: 9));
      labelPaint.layout();
      labelPaint.paint(canvas, Offset((x - labelPaint.width / 2).clamp(0, size.width - labelPaint.width), chartHeight + 7));
    }
  }

  double _value(ReadingHistoryPoint point) => switch (sensor) { 1 => point.dissolvedOxygen, 2 => point.temperature, 3 => point.greenIndex, _ => point.dissolvedOxygen };

  String _formatTime(DateTime time) => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  @override
  bool shouldRepaint(covariant _HistoryChartPainter oldDelegate) => oldDelegate.points != points || oldDelegate.color != color || oldDelegate.sensor != sensor;
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({required this.controller});
  final DashboardController controller;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E9E6))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Monitoring frequency', style: TextStyle(color: Color(0xFF173F38), fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('Choose how often EcoPulse requests a new reading from the ESP32.', style: TextStyle(color: Color(0xFF71847F), fontSize: 13)),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: const Color(0xFFF5F8F6), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFDCE7E2))),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  isExpanded: true,
                  value: controller.refreshSeconds,
                  icon: const Icon(Icons.expand_more_rounded),
                  items: const [
                    DropdownMenuItem(value: 2, child: Text('Every 2 seconds')),
                    DropdownMenuItem(value: 5, child: Text('Every 5 seconds')),
                    DropdownMenuItem(value: 10, child: Text('Every 10 seconds')),
                    DropdownMenuItem(value: 30, child: Text('Every 30 seconds')),
                  ],
                  onChanged: (value) {
                    if (value != null) controller.setRefreshRate(value);
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(color: Color(0xFFE7EEEB)),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(width: 38, height: 38, decoration: BoxDecoration(color: const Color(0xFFE7F7F0), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF218C70))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Polling is active', style: TextStyle(color: Color(0xFF27443E), fontSize: 13, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 3),
                      Text('Live readings update ${controller.refreshLabel.toLowerCase()}.', style: const TextStyle(color: Color(0xFF71847F), fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.reading});
  final PondReading reading;
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Good day, Beij', style: TextStyle(color: Color(0xFF6A7D78), fontSize: 13, fontWeight: FontWeight.w600)), const SizedBox(height: 6), const Text('Pond overview', style: TextStyle(color: Color(0xFF143B35), fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -1)), const SizedBox(height: 7), Text('Live environmental readings from your freshwater pond.', style: TextStyle(color: Colors.blueGrey.shade500, fontSize: 14))])), Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE0E8E4))), child: Row(children: [const Icon(Icons.schedule_rounded, size: 16, color: Color(0xFF75908A)), const SizedBox(width: 7), Text('Updated ${_timeAgo(reading.recordedAt)}', style: const TextStyle(color: Color(0xFF60756F), fontSize: 12, fontWeight: FontWeight.w600))]))]);

  String _timeAgo(DateTime time) { final seconds = DateTime.now().difference(time).inSeconds; return seconds < 60 ? '$seconds sec ago' : '${seconds ~/ 60} min ago'; }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.reading, required this.aeratorOn});
  final PondReading reading;
  final bool aeratorOn;
  @override
  Widget build(BuildContext context) => GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: MediaQuery.sizeOf(context).width < 900 ? 2 : 4, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: MediaQuery.sizeOf(context).width < 900 ? 0.9 : 1.35, children: [_MetricCard(icon: Icons.bubble_chart_rounded, label: 'Dissolved oxygen', value: reading.dissolvedOxygen.toStringAsFixed(1), unit: 'mg/L', status: reading.lowOxygen ? 'Critical' : 'Healthy', color: reading.lowOxygen ? const Color(0xFFD95D56) : const Color(0xFF1C9A79), progress: reading.dissolvedOxygen / 8), _MetricCard(icon: Icons.thermostat_rounded, label: 'Water temperature', value: reading.temperature.toStringAsFixed(1), unit: '°C', status: reading.temperatureHighAlert || reading.temperatureLowAlert ? 'Check range' : 'Optimal', color: reading.temperatureHighAlert || reading.temperatureLowAlert ? const Color(0xFFD99438) : const Color(0xFF347FBA), progress: reading.temperature / 40), _MetricCard(icon: Icons.grass_rounded, label: 'Green index', value: reading.greenIndex.toStringAsFixed(2), unit: 'index', status: reading.algaeRisk ? 'Elevated' : 'Clear', color: reading.algaeRisk ? const Color(0xFFD99438) : const Color(0xFF1C9A79), progress: reading.greenIndex), _MetricCard(icon: Icons.air_rounded, label: 'Aerator', value: aeratorOn ? 'ON' : 'OFF', unit: 'relay', status: aeratorOn ? 'Running now' : 'Standby', color: aeratorOn ? const Color(0xFF1C9A79) : const Color(0xFF81938F), progress: aeratorOn ? 1 : 0.08)]);
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.icon, required this.label, required this.value, required this.unit, required this.status, required this.color, required this.progress});
  final IconData icon; final String label; final String value; final String unit; final String status; final Color color; final double progress;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E9E6))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(width: 30, height: 30, decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 17)), const Spacer(), Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800))]), const Spacer(), Text(label, style: const TextStyle(color: Color(0xFF6B7C77), fontSize: 12, fontWeight: FontWeight.w600)), const SizedBox(height: 3), Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [Text(value, style: const TextStyle(color: Color(0xFF173F38), fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -.8)), const SizedBox(width: 5), Text(unit, style: const TextStyle(color: Color(0xFF82938F), fontSize: 11))]), const SizedBox(height: 12), ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: progress.clamp(0, 1), minHeight: 4, backgroundColor: const Color(0xFFEDF1EF), color: color))]));
}

class _LowerGrid extends StatelessWidget {
  const _LowerGrid({required this.controller});
  final DashboardController controller;
  @override
  Widget build(BuildContext context) { final narrow = MediaQuery.sizeOf(context).width < 780; final left = _OverviewPanel(controller: controller); final right = _AlertsPanel(alerts: controller.alerts); return narrow ? Column(children: [left, const SizedBox(height: 18), right]) : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 3, child: left), const SizedBox(width: 18), Expanded(flex: 2, child: right)]); }
}

class _OverviewPanel extends StatelessWidget {
  const _OverviewPanel({required this.controller});
  final DashboardController controller;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: const Color(0xFF173F38), borderRadius: BorderRadius.circular(14)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [Text('Aeration control', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)), SizedBox(height: 5), Text('ESP32 relay output - GPIO 26', style: TextStyle(color: Color(0xFF9BC1B8), fontSize: 12))])), Switch(value: controller.aeratorOn, onChanged: null, activeThumbColor: const Color(0xFF8DE1C8), activeTrackColor: const Color(0xFF3E796B), inactiveThumbColor: const Color(0xFF92A8A2), inactiveTrackColor: const Color(0xFF355A53))]), const SizedBox(height: 30), Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFF204B43), borderRadius: BorderRadius.circular(10)), child: Row(children: [Icon(controller.aeratorOn ? Icons.check_circle_rounded : Icons.pause_circle_filled_rounded, color: const Color(0xFF8DE1C8), size: 22), const SizedBox(width: 11), Expanded(child: Text(controller.aeratorOn ? 'ESP32 reports the aerator is ON.' : 'ESP32 reports the aerator is OFF.', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)))])), const SizedBox(height: 22), const Text('AUTOMATION RULE', style: TextStyle(color: Color(0xFF83A9A1), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.4)), const SizedBox(height: 10), const Text('ON when DO < 5.0 mg/L or Green Index >= 0.40', style: TextStyle(color: Color(0xFFD0E3DD), fontSize: 12)), const SizedBox(height: 6), const Text('OFF when DO >= 5.5 mg/L and Green Index < 0.40', style: TextStyle(color: Color(0xFFD0E3DD), fontSize: 12))]));
}

class _AlertsPanel extends StatelessWidget {
  const _AlertsPanel({required this.alerts});
  final List<PondAlert> alerts;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E9E6))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Expanded(child: Text('Recent activity', style: TextStyle(color: Color(0xFF173F38), fontSize: 17, fontWeight: FontWeight.w800))), const Text('View all', style: TextStyle(color: Color(0xFF218C70), fontSize: 12, fontWeight: FontWeight.w700))]), const SizedBox(height: 8), ...alerts.map((alert) => _AlertRow(alert: alert))]));
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.alert});
  final PondAlert alert;
  @override
  Widget build(BuildContext context) { final color = alert.level == AlertLevel.warning ? const Color(0xFFD99438) : const Color(0xFF218C70); return Padding(padding: const EdgeInsets.symmetric(vertical: 11), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 30, height: 30, decoration: BoxDecoration(color: color.withValues(alpha: .12), shape: BoxShape.circle), child: Icon(alert.level == AlertLevel.warning ? Icons.priority_high_rounded : Icons.check_rounded, color: color, size: 17)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(alert.title, style: const TextStyle(color: Color(0xFF27443E), fontSize: 12, fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(alert.detail, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF7D8D89), fontSize: 11, height: 1.3)), const SizedBox(height: 4), Text(alert.time, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700))]))])); }
}
