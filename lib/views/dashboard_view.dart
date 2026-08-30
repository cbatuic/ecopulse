import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../controllers/dashboard_controller.dart';
import '../models/bantai_insight.dart';
import '../models/pond_reading.dart';
import '../models/reading_history_point.dart';
import '../models/settings.dart';

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
          drawer: _MobileDrawer(controller: controller),
          backgroundColor: const Color(0xFFF5F7F6),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 960;
                final isMobile = constraints.maxWidth < 700;
                return Row(
                  children: [
                    if (isDesktop) _NavigationRail(controller: controller),
                    Expanded(
                      child: Column(
                        children: [
                          _TopBar(controller: controller, isMobile: isMobile),
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
                          if (!isMobile && !isDesktop) _BottomNavigation(controller: controller),
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
        _HeroHeader(reading: reading, welcomeMessage: controller.welcomeMessage, profileImageUrl: controller.profileImageUrl),
        const SizedBox(height: 24),
        _MetricGrid(reading: reading, aeratorOn: controller.aeratorOn),
        const SizedBox(height: 24),
        _LowerGrid(controller: controller),
      ];
    }
    if (controller.selectedTab == 5) return [_PageHeader(title: 'Alerts', subtitle: 'Review pond events and sensor warnings.'), const SizedBox(height: 24), _AlertsPanel(alerts: controller.alerts, smsAlerts: controller.smsAlerts)];
    if (controller.selectedTab == 6) return [_PageHeader(title: 'Settings', subtitle: 'Tune how EcoPulse watches your pond.'), const SizedBox(height: 24), _SettingsPanel(controller: controller)];
    if (controller.selectedTab == 8) return [_PageHeader(title: 'BantAI', subtitle: 'Predict pond health issues before they become critical.'), const SizedBox(height: 24), _BantAIPanel(controller: controller, insight: controller.bantaiInsight, reading: reading, history: controller.bantaiHistory)];
    return [_SensorDetail(controller: controller, sensor: controller.selectedTab), const SizedBox(height: 24), _MetricGrid(reading: reading, aeratorOn: controller.aeratorOn)];
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.controller, required this.isMobile});
  final DashboardController controller;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Color(0xFFE3E9E6)))),
      child: Row(
        children: [
          if (isMobile) ...[
            Builder(builder: (context) => IconButton(tooltip: 'Open navigation', onPressed: () => Scaffold.of(context).openDrawer(), icon: const Icon(Icons.menu_rounded))),
            const SizedBox(width: 4),
            const _BrandMark(),
          ] else if (MediaQuery.sizeOf(context).width < 960) ...[
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
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFE0F2EC),
            backgroundImage: NetworkImage(controller.profileImageUrl),
          ),
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
          _NavItem(icon: Icons.psychology_outlined, label: 'BantAI', selected: controller.selectedTab == 8, onTap: () => controller.selectTab(8)),
          const Spacer(),
          _NavItem(icon: Icons.settings_outlined, label: 'Settings', selected: controller.selectedTab == 6, onTap: () => controller.selectTab(6)),
          const SizedBox(height: 14),
          const Padding(padding: EdgeInsets.only(left: 12), child: Text('ECOPULSE v1.0.0', style: TextStyle(color: Color(0xFF668A83), fontSize: 10, letterSpacing: 1))),
        ],
      ),
    );
  }
}

class _MobileDrawer extends StatelessWidget {
  const _MobileDrawer({required this.controller});
  final DashboardController controller;

  @override
  Widget build(BuildContext context) => Drawer(
        backgroundColor: const Color(0xFF102E2B),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 22),
            children: [
              const Padding(padding: EdgeInsets.only(left: 10, bottom: 38), child: _BrandMark(dark: true)),
              const Padding(padding: EdgeInsets.only(left: 12, bottom: 12), child: Text('WORKSPACE', style: TextStyle(color: Color(0xFF83A9A1), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5))),
              _drawerItem(context, Icons.grid_view_rounded, 'Overview', 0),
              const Padding(padding: EdgeInsets.only(left: 12, top: 13, bottom: 7), child: Text('SENSORS', style: TextStyle(color: Color(0xFF83A9A1), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5))),
              _drawerItem(context, Icons.bubble_chart_rounded, 'Dissolved oxygen', 1),
              _drawerItem(context, Icons.thermostat_rounded, 'Temperature', 2),
              _drawerItem(context, Icons.palette_outlined, 'Color sensor', 3),
              _drawerItem(context, Icons.air_rounded, 'Aerator relay', 4),
              _drawerItem(context, Icons.notifications_none_rounded, 'Alerts', 5),
              _drawerItem(context, Icons.psychology_outlined, 'BantAI', 8),
              const SizedBox(height: 18),
              _drawerItem(context, Icons.settings_outlined, 'Settings', 6),
            ],
          ),
        ),
      );

  Widget _drawerItem(BuildContext context, IconData icon, String label, int tab) => _NavItem(icon: icon, label: label, selected: controller.selectedTab == tab, onTap: () { controller.selectTab(tab); Navigator.of(context).pop(); });
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({this.dark = false});
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final primary = dark ? Colors.white : const Color(0xFF143B35);
    return Row(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network('icons/Icon-192.png', width: 32, height: 32, fit: BoxFit.cover),
      ),
      const SizedBox(width: 10),
      Text('EcoPulse', style: TextStyle(color: primary, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.4))
    ]);
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
  Widget build(BuildContext context) => NavigationBar(
        height: 70,
        selectedIndex: controller.selectedTab == 0
            ? 0
            : controller.selectedTab == 5
                ? 2
                : controller.selectedTab == 6
                    ? 3
                    : controller.selectedTab == 8
                        ? 4
                        : 1,
        onDestinationSelected: (index) => controller.selectTab(index == 1
            ? 1
            : index == 2
                ? 5
                : index == 3
                    ? 6
                    : index == 4
                        ? 8
                        : 0),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'Overview'),
          NavigationDestination(icon: Icon(Icons.sensors_rounded), label: 'Sensors'),
          NavigationDestination(icon: Icon(Icons.notifications_none_rounded), label: 'Alerts'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
          NavigationDestination(icon: Icon(Icons.psychology_outlined), label: 'BantAI'),
        ],
      );
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

class _SettingsPanel extends StatefulWidget {
  const _SettingsPanel({required this.controller});
  final DashboardController controller;

  @override
  State<_SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<_SettingsPanel> {
  late final TextEditingController endpointController;
  late final TextEditingController welcomeController;
  late final TextEditingController profileUrlController;
  late final TextEditingController smsController;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    endpointController = TextEditingController(text: widget.controller.apiEndpoint);
    welcomeController = TextEditingController(text: widget.controller.settings.welcomeMessage);
    profileUrlController = TextEditingController(text: widget.controller.settings.profileImageUrl);
    smsController = TextEditingController(text: widget.controller.settings.smsAlert ?? '');
  }

  @override
  void dispose() {
    endpointController.dispose();
    welcomeController.dispose();
    profileUrlController.dispose();
    smsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E9E6))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _SettingsTabButton(label: 'Profile', selected: _selectedTab == 0, onTap: () => setState(() => _selectedTab = 0)),
                const SizedBox(width: 8),
                _SettingsTabButton(label: 'Device', selected: _selectedTab == 1, onTap: () => setState(() => _selectedTab = 1)),
                const SizedBox(width: 8),
                _SettingsTabButton(label: 'Alerts', selected: _selectedTab == 2, onTap: () => setState(() => _selectedTab = 2)),
                const SizedBox(width: 8),
                _SettingsTabButton(label: 'Advanced', selected: _selectedTab == 3, onTap: () => setState(() => _selectedTab = 3)),
              ],
            ),
            const SizedBox(height: 22),
            if (_selectedTab == 0) ...[
              const Text('Profile settings', style: TextStyle(color: Color(0xFF173F38), fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('User display details for the app shell and welcome area.', style: TextStyle(color: Color(0xFF71847F), fontSize: 13)),
              const SizedBox(height: 16),
              TextField(
                controller: welcomeController,
                decoration: InputDecoration(labelText: 'Welcome message', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: profileUrlController,
                decoration: InputDecoration(labelText: 'Profile image URL', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  widget.controller.updateProfile(
                    welcomeMessage: welcomeController.text.trim().isNotEmpty ? welcomeController.text.trim() : 'Good day, Beij',
                    profileImageUrl: profileUrlController.text.trim().isNotEmpty ? profileUrlController.text.trim() : 'profile/profile.png',
                  );
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save profile'),
              ),
            ] else if (_selectedTab == 1) ...[
              const Text('Device settings', style: TextStyle(color: Color(0xFF173F38), fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('Set the ESP32 endpoint used for live readings.', style: TextStyle(color: Color(0xFF71847F), fontSize: 13)),
              const SizedBox(height: 14),
              TextField(
                controller: endpointController,
                keyboardType: TextInputType.url,
                onSubmitted: _saveEndpoint,
                decoration: InputDecoration(prefixIcon: const Icon(Icons.link_rounded), hintText: 'http://192.168.254.160/sensors', suffixIcon: IconButton(tooltip: 'Save API route', onPressed: () => _saveEndpoint(endpointController.text), icon: const Icon(Icons.save_outlined)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(height: 28),
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
                    value: widget.controller.refreshSeconds,
                    icon: const Icon(Icons.expand_more_rounded),
                    items: const [
                      DropdownMenuItem(value: 2, child: Text('Every 2 seconds')),
                      DropdownMenuItem(value: 5, child: Text('Every 5 seconds')),
                      DropdownMenuItem(value: 10, child: Text('Every 10 seconds')),
                      DropdownMenuItem(value: 30, child: Text('Every 30 seconds')),
                    ],
                    onChanged: (value) {
                      if (value != null) widget.controller.setRefreshRate(value);
                    },
                  ),
                ),
              ),
            ] else if (_selectedTab == 2) ...[
              const Text('Alert preferences', style: TextStyle(color: Color(0xFF173F38), fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('Store the latest source SMS alert and timestamp for the alert feed.', style: TextStyle(color: Color(0xFF71847F), fontSize: 13)),
              const SizedBox(height: 16),
              TextField(
                controller: smsController,
                maxLines: 3,
                decoration: InputDecoration(labelText: 'sms_alert', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () {
                  widget.controller.setSmsAlert(
                    message: smsController.text.trim(),
                    timestamp: DateTime.now(),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SMS alert saved')));
                },
                icon: const Icon(Icons.sms_outlined),
                label: const Text('Save SMS alert'),
              ),
            ] else ...[
              const Text('Advanced diagnostics', style: TextStyle(color: Color(0xFF173F38), fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('Complete sensor API payload, including SMS alert data and timestamps.', style: TextStyle(color: Color(0xFF71847F), fontSize: 13)),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFF102E2B), borderRadius: BorderRadius.circular(10)),
                child: SelectableText(
                  widget.controller.formattedSensorJson,
                  style: const TextStyle(color: Color(0xFFD1EEE5), fontSize: 12, height: 1.5, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  widget.controller.setRawJson(widget.controller.formattedSensorJson);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Raw JSON stored in settings')));
                },
                icon: const Icon(Icons.data_object_rounded),
                label: const Text('Save raw JSON'),
              ),
            ],
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
                      Text('Live readings update ${widget.controller.refreshLabel.toLowerCase()}.', style: const TextStyle(color: Color(0xFF71847F), fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  void _saveEndpoint(String value) {
    try {
      widget.controller.setApiEndpoint(value);
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sensor API route saved')));
    } on FormatException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

class _SettingsTabButton extends StatelessWidget {
  const _SettingsTabButton({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE7F7F0) : const Color(0xFFF5F8F6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? const Color(0xFF8DE1C8) : const Color(0xFFE2E9E6)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF173F38) : const Color(0xFF6B7C77),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.reading, required this.welcomeMessage, required this.profileImageUrl});
  final PondReading reading;
  final String welcomeMessage;
  final String profileImageUrl;
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(welcomeMessage, style: const TextStyle(color: Color(0xFF6A7D78), fontSize: 13, fontWeight: FontWeight.w600)), const SizedBox(height: 6), const Text('Pond overview', style: TextStyle(color: Color(0xFF143B35), fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -1)), const SizedBox(height: 7), Text('Live environmental readings from your freshwater pond.', style: TextStyle(color: Colors.blueGrey.shade500, fontSize: 14))])), Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE0E8E4))), child: Row(children: [const Icon(Icons.schedule_rounded, size: 16, color: Color(0xFF75908A)), const SizedBox(width: 7), Text('Updated ${_timeAgo(reading.recordedAt)}', style: const TextStyle(color: Color(0xFF60756F), fontSize: 12, fontWeight: FontWeight.w600))]))]);

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
  Widget build(BuildContext context) { final narrow = MediaQuery.sizeOf(context).width < 780; final left = _OverviewPanel(controller: controller); final right = _AlertsPanel(alerts: controller.alerts, smsAlerts: controller.smsAlerts); return narrow ? Column(children: [left, const SizedBox(height: 18), right]) : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 3, child: left), const SizedBox(width: 18), Expanded(flex: 2, child: right)]); }
}

class _BantAIPanel extends StatefulWidget {
  const _BantAIPanel({required this.controller, required this.insight, required this.reading, required this.history});
  final DashboardController controller;
  final BantAIInsight insight;
  final PondReading reading;
  final List<ReadingHistoryPoint> history;

  @override
  State<_BantAIPanel> createState() => _BantAIPanelState();
}

class _BantAIPanelState extends State<_BantAIPanel> {
  int _windowValue = 3;
  BantAIWindowUnit _windowUnit = BantAIWindowUnit.days;
  BantAIRegressionMethod _method = BantAIRegressionMethod.linear;
  double _healthThreshold = 70;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  bool _dateRangeInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.history.isNotEmpty) {
      _startDate = widget.history.first.recordedAt;
      _endDate = widget.history.last.recordedAt;
      _dateRangeInitialized = true;
      unawaited(widget.controller.loadBantAIReferenceRange(_startDate, _endDate));
    }
  }

  @override
  void didUpdateWidget(covariant _BantAIPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dateRangeInitialized && widget.history.isNotEmpty) {
      _startDate = widget.history.first.recordedAt;
      _endDate = widget.history.last.recordedAt;
      _dateRangeInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredHistory = widget.history.where((point) {
      return !point.recordedAt.isBefore(_startDate) && !point.recordedAt.isAfter(_endDate);
    }).toList();
    final forecast = BantAIInsight.generateForecast(
      filteredHistory,
      windowValue: _windowValue,
      windowUnit: _windowUnit,
      method: _method,
    );
    final riskColor = switch (forecast.projectedHealthScore) {
      > 75 => const Color(0xFF1C9A79),
      > 50 => const Color(0xFFD99438),
      _ => const Color(0xFFD95D56),
    };

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E9E6))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('BantAI pond forecast', style: TextStyle(color: Color(0xFF173F38), fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text('Predict pond condition using SQLite history, dissolved oxygen, temperature, algae index, and aerator state.', style: TextStyle(color: Colors.blueGrey.shade500, fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: riskColor.withValues(alpha: .12), borderRadius: BorderRadius.circular(16)),
                child: Text('${forecast.projectedHealthScore.round()}%', style: TextStyle(color: riskColor, fontSize: 11, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 130,
                child: DropdownButtonFormField<int>(
                  initialValue: _windowValue,
                  decoration: const InputDecoration(labelText: 'Period', border: OutlineInputBorder()),
                  items: const [1, 3, 7, 14].map((value) => DropdownMenuItem(value: value, child: Text('$value'))).toList(),
                  onChanged: (value) => setState(() => _windowValue = value ?? _windowValue),
                ),
              ),
              SizedBox(
                width: 150,
                child: DropdownButtonFormField<BantAIWindowUnit>(
                  initialValue: _windowUnit,
                  decoration: const InputDecoration(labelText: 'Unit', border: OutlineInputBorder()),
                  items: BantAIWindowUnit.values.map((unit) => DropdownMenuItem(value: unit, child: Text(unit.name))).toList(),
                  onChanged: (value) => setState(() => _windowUnit = value ?? _windowUnit),
                ),
              ),
              SizedBox(
                width: 190,
                child: DropdownButtonFormField<BantAIRegressionMethod>(
                  initialValue: _method,
                  decoration: const InputDecoration(labelText: 'Regression', border: OutlineInputBorder()),
                  items: BantAIRegressionMethod.values.map((method) => DropdownMenuItem(value: method, child: Text(_methodDisplay(method)))).toList(),
                  onChanged: (value) => setState(() => _method = value ?? _method),
                ),
              ),
              SizedBox(
                width: 190,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final start = await showDatePicker(
                      context: context,
                      initialDate: _startDate,
                      firstDate: DateTime(2024),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (start == null) return;
                    if (!context.mounted) return;
                    final end = await showDatePicker(
                      context: context,
                      initialDate: _endDate,
                      firstDate: start,
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (end == null) return;
                    if (!mounted) return;
                    setState(() {
                      _startDate = start;
                      _endDate = end;
                    });
                    await widget.controller.loadBantAIReferenceRange(start, end);
                  },
                  icon: const Icon(Icons.date_range_rounded),
                  label: Text('${_formatDate(_startDate)} - ${_formatDate(_endDate)}'),
                ),
              ),
              SizedBox(
                width: 220,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Health threshold', border: OutlineInputBorder()),
                  child: Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _healthThreshold,
                          min: 0,
                          max: 100,
                          divisions: 20,
                          label: '${_healthThreshold.round()}%',
                          onChanged: (value) => setState(() => _healthThreshold = value),
                        ),
                      ),
                      Text('${_healthThreshold.round()}%', style: const TextStyle(color: Color(0xFF173F38), fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: const Color(0xFFF5F8F6), borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(forecast.title, style: const TextStyle(color: Color(0xFF173F38), fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(forecast.summary, style: const TextStyle(color: Color(0xFF5F736E), fontSize: 13, height: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 220,
            child: _ForecastChart(points: forecast.points, history: filteredHistory, forecast: forecast.points, threshold: _healthThreshold),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFF7F9F8), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE1E9E5))),
            child: const Text(
              'Pond health score formula\n'
              'Score = 100 - (|temperature - 27| x 2.2) - (max(0, 5 - dissolved oxygen) x 13)\n'
              '        - (max(0, green index - 0.25) x 180) + (aerator ON ? 8 : 0)\n'
              'The score is clamped to 0-100. Predictions below the threshold are highlighted red; predictions at or above it are green.',
              style: TextStyle(color: Color(0xFF5F736E), fontSize: 12, height: 1.5),
            ),
          ),
          const SizedBox(height: 18),
          Text('Recommended action', style: TextStyle(color: Colors.blueGrey.shade700, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(widget.insight.recommendedAction, style: const TextStyle(color: Color(0xFF173F38), fontSize: 13, height: 1.6)),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _BantAIStat(label: 'Dissolved oxygen', value: widget.reading.dissolvedOxygen.toStringAsFixed(1), unit: 'mg/L'),
              _BantAIStat(label: 'Temperature', value: widget.reading.temperature.toStringAsFixed(1), unit: '°C'),
              _BantAIStat(label: 'Green index', value: widget.reading.greenIndex.toStringAsFixed(2), unit: 'index'),
              _BantAIStat(label: 'Confidence', value: '${(widget.insight.confidence * 100).round()}%', unit: ''),
            ],
          ),
        ],
      ),
    );
  }

  String _methodDisplay(BantAIRegressionMethod method) => switch (method) {
        BantAIRegressionMethod.linear => 'Linear',
        BantAIRegressionMethod.polynomial => 'Polynomial',
        BantAIRegressionMethod.ridge => 'Ridge',
      };

  String _formatDate(DateTime date) => '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
}

class _ForecastChart extends StatelessWidget {
  const _ForecastChart({required this.points, required this.history, required this.forecast, required this.threshold});
  final List<BantAIForecastPoint> points;
  final List<ReadingHistoryPoint> history;
  final List<BantAIForecastPoint> forecast;
  final double threshold;

  @override
  Widget build(BuildContext context) {
    if (forecast.isEmpty) {
      return const Center(child: Text('No forecast available yet.'));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Pond health score', style: TextStyle(color: Color(0xFF27443E), fontSize: 12, fontWeight: FontWeight.w800)),
                const Spacer(),
                _ChartLegend(label: 'History', color: const Color(0xFF3C74B6)),
                const SizedBox(width: 12),
                _ChartLegend(label: 'Prediction', color: forecast.last.healthScore < threshold ? const Color(0xFFD84B4B) : const Color(0xFF1C9A79)),
              ],
            ),
            const SizedBox(height: 6),
            Expanded(
              child: CustomPaint(
                painter: _ForecastChartPainter(points: forecast, history: history, forecast: forecast, threshold: threshold),
                child: const SizedBox.expand(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 18, height: 3, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: Color(0xFF71847F), fontSize: 10, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _ForecastChartPainter extends CustomPainter {
  const _ForecastChartPainter({required this.points, required this.history, required this.forecast, required this.threshold});
  final List<BantAIForecastPoint> points;
  final List<ReadingHistoryPoint> history;
  final List<BantAIForecastPoint> forecast;
  final double threshold;

  @override
  void paint(Canvas canvas, Size size) {
    final chartRect = Rect.fromLTWH(42, 14, max(0, size.width - 56), max(0, size.height - 42));
    if (chartRect.width <= 0 || chartRect.height <= 0) return;

    final grid = Paint()..color = const Color(0xFFE4ECE9)..strokeWidth = 1;
    final historyPaint = Paint()..color = const Color(0xFF3C74B6)..style = PaintingStyle.stroke..strokeWidth = 2.2..strokeCap = StrokeCap.round;
    final forecastColor = forecast.last.healthScore < threshold ? const Color(0xFFD84B4B) : const Color(0xFF1C9A79);
    final forecastPaint = Paint()..color = forecastColor..style = PaintingStyle.stroke..strokeWidth = 2.8..strokeCap = StrokeCap.round;
    final historyPointPaint = Paint()..color = const Color(0xFF3C74B6);
    final forecastPointPaint = Paint()..color = forecastColor;
    final totalPoints = history.length + forecast.length;
    final maxIndex = max(1, totalPoints - 1);

    for (var index = 0; index <= 4; index++) {
      final y = chartRect.top + chartRect.height * index / 4;
      canvas.drawLine(Offset(chartRect.left, y), Offset(chartRect.right, y), grid);
      _drawText(canvas, '${100 - index * 25}', Offset(4, y - 6), const TextStyle(color: Color(0xFF8A9A95), fontSize: 9));
    }

    final predictionStartIndex = history.isEmpty ? 0 : history.length;
    final predictionStartX = chartRect.left + chartRect.width * predictionStartIndex / maxIndex;
    final predictionArea = Rect.fromLTRB(predictionStartX, chartRect.top, chartRect.right, chartRect.bottom);
    canvas.drawRect(predictionArea, Paint()..color = forecastColor.withValues(alpha: .06));
    _drawDashedLine(canvas, Offset(predictionStartX, chartRect.top), Offset(predictionStartX, chartRect.bottom), Paint()..color = forecastColor..strokeWidth = 1.4);
    _drawText(canvas, 'PREDICTION', Offset(min(predictionStartX + 7, chartRect.right - 66), chartRect.top + 5), TextStyle(color: forecastColor, fontSize: 9, fontWeight: FontWeight.w800));
    final thresholdY = _y(chartRect, threshold);
    _drawDashedLine(canvas, Offset(chartRect.left, thresholdY), Offset(chartRect.right, thresholdY), Paint()..color = const Color(0xFFD99438)..strokeWidth = 1);
    _drawText(canvas, 'THRESHOLD ${threshold.round()}%', Offset(chartRect.left + 5, thresholdY - 15), const TextStyle(color: Color(0xFFB4772E), fontSize: 9, fontWeight: FontWeight.w800));

    if (history.isNotEmpty) {
      final path = Path();
      for (var index = 0; index < history.length; index++) {
        final point = history[index];
        final x = chartRect.left + chartRect.width * index / maxIndex;
        final y = _y(chartRect, _healthScoreFromHistory(point));
        index == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
        canvas.drawCircle(Offset(x, y), 2.7, historyPointPaint);
      }
      canvas.drawPath(path, historyPaint);
    }

    if (forecast.isNotEmpty) {
      final path = Path();
      for (var index = 0; index < forecast.length; index++) {
        final point = forecast[index];
        final x = chartRect.left + chartRect.width * (history.length + index) / maxIndex;
        final y = _y(chartRect, point.healthScore);
        index == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
        canvas.drawCircle(Offset(x, y), 3.8, forecastPointPaint);
      }
      canvas.drawPath(path, forecastPaint);
      final last = forecast.last;
      final lastX = chartRect.left + chartRect.width * (history.length + forecast.length - 1) / maxIndex;
      _drawText(canvas, '${last.healthScore.round()}%', Offset(min(lastX + 5, chartRect.right - 30), _y(chartRect, last.healthScore) - 7), TextStyle(color: forecastColor, fontSize: 9, fontWeight: FontWeight.w800));
    }

    final dates = <DateTime>[...history.map((point) => point.recordedAt), ...forecast.map((point) => point.timestamp)];
    for (var index = 0; index < dates.length; index += max(1, dates.length ~/ 4)) {
      final x = chartRect.left + chartRect.width * index / maxIndex;
      _drawText(canvas, _formatShortDate(dates[index]), Offset(x - 15, chartRect.bottom + 8), const TextStyle(color: Color(0xFF7A8B86), fontSize: 9));
    }
  }

  double _y(Rect rect, double value) => rect.bottom - (value.clamp(0.0, 100.0) / 100) * rect.height;

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dash = 5.0;
    const gap = 4.0;
    var y = start.dy;
    while (y < end.dy) {
      canvas.drawLine(Offset(start.dx, y), Offset(start.dx, min(y + dash, end.dy)), paint);
      y += dash + gap;
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final painter = TextPainter(text: TextSpan(text: text, style: style), textDirection: TextDirection.ltr)..layout();
    painter.paint(canvas, offset);
  }

  double _healthScoreFromHistory(ReadingHistoryPoint point) {
    double score = 100.0;
    score -= (point.temperature - 27.0).abs() * 2.2;
    score -= max(0.0, 5.0 - point.dissolvedOxygen) * 13.0;
    score -= max(0.0, point.greenIndex - 0.25) * 180.0;
    if (point.aeratorOn) score += 8.0;
    return score.clamp(0.0, 100.0);
  }

  String _formatShortDate(DateTime time) => '${time.month}/${time.day}';

  @override
  bool shouldRepaint(covariant _ForecastChartPainter oldDelegate) => oldDelegate.points != points || oldDelegate.history != history || oldDelegate.forecast != forecast || oldDelegate.threshold != threshold;
}

class _BantAIStat extends StatelessWidget {
  const _BantAIStat({required this.label, required this.value, required this.unit});
  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFFE7F7F0), borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF6B7C77), fontSize: 10, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: const TextStyle(color: Color(0xFF173F38), fontSize: 18, fontWeight: FontWeight.w800)),
              if (unit.isNotEmpty) const SizedBox(width: 4),
              if (unit.isNotEmpty) Text(unit, style: const TextStyle(color: Color(0xFF6B7C77), fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewPanel extends StatelessWidget {
  const _OverviewPanel({required this.controller});
  final DashboardController controller;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: controller.aeratorOn ? const Color(0xFF173F38) : const Color(0xFF626C6A), borderRadius: BorderRadius.circular(14)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [Text('Aeration control', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)), SizedBox(height: 5), Text('ESP32 relay output - GPIO 26', style: TextStyle(color: Color(0xFFD3DBD9), fontSize: 12))])), Switch(value: controller.aeratorOn, onChanged: null, activeThumbColor: const Color(0xFF8DE1C8), activeTrackColor: const Color(0xFF3E796B), inactiveThumbColor: const Color(0xFFD1D7D5), inactiveTrackColor: const Color(0xFF4C5553))]), const SizedBox(height: 30), Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: controller.aeratorOn ? const Color(0xFF204B43) : const Color(0xFF737C7A), borderRadius: BorderRadius.circular(10)), child: Row(children: [Icon(controller.aeratorOn ? Icons.check_circle_rounded : Icons.pause_circle_filled_rounded, color: controller.aeratorOn ? const Color(0xFF8DE1C8) : const Color(0xFFE0E4E3), size: 22), const SizedBox(width: 11), Expanded(child: Text(controller.aeratorOn ? 'ESP32 reports the aerator is ON.' : 'ESP32 reports the aerator is OFF.', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)))])), const SizedBox(height: 22), Text('AUTOMATION RULE', style: TextStyle(color: controller.aeratorOn ? const Color(0xFF83A9A1) : const Color(0xFFD3DBD9), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.4)), const SizedBox(height: 10), const Text('ON when DO < 5.0 mg/L or Green Index >= 0.40', style: TextStyle(color: Color(0xFFE0E7E4), fontSize: 12)), const SizedBox(height: 6), const Text('OFF when DO >= 5.5 mg/L and Green Index < 0.40', style: TextStyle(color: Color(0xFFE0E7E4), fontSize: 12))]));
}

class _AlertsPanel extends StatefulWidget {
  const _AlertsPanel({required this.alerts, required this.smsAlerts});
  final List<PondAlert> alerts;
  final List<SmsAlertEntry> smsAlerts;

  @override
  State<_AlertsPanel> createState() => _AlertsPanelState();
}

class _AlertsPanelState extends State<_AlertsPanel> {
  static const int _pageSize = 5;
  int _pageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final entries = widget.smsAlerts.reversed.toList();
    final totalPages = (entries.length / _pageSize).ceil();
    final safePageIndex = totalPages == 0 ? 0 : _pageIndex.clamp(0, totalPages - 1);
    final start = safePageIndex * _pageSize;
    final pageEntries = entries.skip(start).take(_pageSize).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E9E6))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(child: Text('Recent activity', style: TextStyle(color: Color(0xFF173F38), fontSize: 17, fontWeight: FontWeight.w800))),
                  const Text('View all', style: TextStyle(color: Color(0xFF218C70), fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 8),
              ...widget.alerts.map((alert) => _AlertRow(alert: alert)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E9E6))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(child: Text('SMS alert history', style: TextStyle(color: Color(0xFF173F38), fontSize: 17, fontWeight: FontWeight.w800))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFFE7F7F0), borderRadius: BorderRadius.circular(12)),
                    child: Text('${entries.length} entries', style: const TextStyle(color: Color(0xFF1C9A79), fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _SmsKpiCard(label: 'Total', value: '${widget.smsAlerts.length}', color: const Color(0xFF1C9A79)),
                  const SizedBox(width: 10),
                  _SmsKpiCard(label: 'Last 24h', value: '${widget.smsAlerts.where((entry) => DateTime.now().difference(entry.timestamp).inHours < 24).length}', color: const Color(0xFF3C74B6)),
                  const SizedBox(width: 10),
                  _SmsKpiCard(label: 'Warnings', value: '${widget.smsAlerts.where((entry) => entry.message.toLowerCase().contains('warning')).length}', color: const Color(0xFFD99438)),
                ],
              ),
              const SizedBox(height: 14),
              if (pageEntries.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No SMS alerts available yet.', style: TextStyle(color: Color(0xFF71847F), fontSize: 12)),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingTextStyle: const TextStyle(color: Color(0xFF173F38), fontWeight: FontWeight.w700, fontSize: 12),
                    dataTextStyle: const TextStyle(color: Color(0xFF4A5D59), fontSize: 12),
                    columns: const [
                      DataColumn(label: Text('Message')),
                      DataColumn(label: Text('Date & time')),
                    ],
                    rows: pageEntries.map((entry) => DataRow(cells: [
                      DataCell(Text(entry.message, overflow: TextOverflow.ellipsis)),
                      DataCell(Text(_formatDate(entry.timestamp))),
                    ])).toList(),
                  ),
                ),
              if (totalPages > 1) ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: safePageIndex == 0 ? null : () => setState(() => _pageIndex = safePageIndex - 1),
                      icon: const Icon(Icons.chevron_left_rounded),
                      label: const Text('Prev'),
                    ),
                    const SizedBox(width: 8),
                    Text('Page ${safePageIndex + 1} / $totalPages', style: const TextStyle(color: Color(0xFF4A5D59), fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: safePageIndex >= totalPages - 1 ? null : () => setState(() => _pageIndex = safePageIndex + 1),
                      icon: const Icon(Icons.chevron_right_rounded),
                      label: const Text('Next'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime value) => '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

class _SmsKpiCard extends StatelessWidget {
  const _SmsKpiCard({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.alert});
  final PondAlert alert;
  @override
  Widget build(BuildContext context) { final color = alert.level == AlertLevel.warning ? const Color(0xFFD99438) : const Color(0xFF218C70); return Padding(padding: const EdgeInsets.symmetric(vertical: 11), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 30, height: 30, decoration: BoxDecoration(color: color.withValues(alpha: .12), shape: BoxShape.circle), child: Icon(alert.level == AlertLevel.warning ? Icons.priority_high_rounded : Icons.check_rounded, color: color, size: 17)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(alert.title, style: const TextStyle(color: Color(0xFF27443E), fontSize: 12, fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(alert.detail, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF7D8D89), fontSize: 11, height: 1.3)), const SizedBox(height: 4), Text(alert.time, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700))]))])); }
}
