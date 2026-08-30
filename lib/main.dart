import 'package:flutter/material.dart';

import 'pages/dashboard_page.dart';
import 'pages/monthly_page.dart';
import 'pages/settings_page.dart';
import 'pages/visitor_recognition_page.dart';

void main() {
  runApp(const PlaygroundCounterApp());
}

class PlaygroundCounterApp extends StatelessWidget {
  const PlaygroundCounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Playground Counter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Playground Counter'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
              Tab(icon: Icon(Icons.bar_chart), text: 'Monthly'),
              Tab(icon: Icon(Icons.camera_alt), text: 'Visitor'),
              Tab(icon: Icon(Icons.settings), text: 'Settings'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            DashboardPage(),
            MonthlyPage(),
            VisitorRecognitionPage(),
            SettingsPage(),
          ],
        ),
      ),
    );
  }
}
