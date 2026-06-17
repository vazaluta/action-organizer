import 'package:flutter/material.dart';
import 'models/item.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/storage_service.dart';

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
      home: const _AppEntry(),
    );
  }
}

class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  final StorageService _storage = StorageService();
  bool? _onboardingDone;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final done = await _storage.isOnboardingDone();
    setState(() => _onboardingDone = done);
  }

  Future<void> _completeOnboarding(List<Item> items) async {
    await _storage.setOnboardingDone();
    if (items.isNotEmpty) {
      await _storage.saveItems(items);
    }
    if (mounted) setState(() => _onboardingDone = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_onboardingDone == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_onboardingDone!) {
      return OnboardingScreen(onComplete: _completeOnboarding);
    }
    return const MainScreen();
  }
}
