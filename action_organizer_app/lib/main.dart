import 'package:flutter/material.dart';
import 'screens/main_screen.dart';

void main() {
  runApp(const ActionOrganizerApp());
}

class ActionOrganizerApp extends StatelessWidget {
  const ActionOrganizerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '行動整理',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}
