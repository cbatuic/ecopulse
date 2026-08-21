import 'package:flutter/material.dart';

import 'controllers/dashboard_controller.dart';
import 'views/dashboard_view.dart';

void main() {
  runApp(const EcoPulseApp());
}

class EcoPulseApp extends StatefulWidget {
  const EcoPulseApp({super.key});

  @override
  State<EcoPulseApp> createState() => _EcoPulseAppState();
}

class _EcoPulseAppState extends State<EcoPulseApp> {
  late final DashboardController controller;

  @override
  void initState() {
    super.initState();
    controller = DashboardController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoPulse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1C9A79),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7F6),
      ),
      home: DashboardView(controller: controller),
    );
  }
}
