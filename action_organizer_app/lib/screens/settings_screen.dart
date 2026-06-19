import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storage = StorageService();
  bool _enabled = false;
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final time = await _storage.loadNotificationTime();
    setState(() {
      _enabled = time != null;
      if (time != null) _time = time;
      _loading = false;
    });
  }

  Future<void> _toggleEnabled(bool value) async {
    if (value) {
      final granted = await NotificationService.instance.requestPermission();
      if (!granted || !mounted) return;
      await NotificationService.instance.scheduleDaily(_time);
      await _storage.saveNotificationTime(_time);
    } else {
      await NotificationService.instance.cancel();
      await _storage.saveNotificationTime(null);
    }
    if (mounted) setState(() => _enabled = value);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked == null || !mounted) return;
    setState(() => _time = picked);
    if (_enabled) {
      await NotificationService.instance.scheduleDaily(picked);
      await _storage.saveNotificationTime(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        backgroundColor: colorScheme.inversePrimary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    '通知',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colorScheme.primary,
                        ),
                  ),
                ),
                SwitchListTile(
                  title: const Text('毎日リマインダー'),
                  subtitle: const Text('心がけを思い出させる通知を毎日届けます'),
                  value: _enabled,
                  onChanged: _toggleEnabled,
                ),
                if (_enabled)
                  ListTile(
                    leading: const Icon(Icons.access_time_outlined),
                    title: const Text('通知時刻'),
                    trailing: Text(
                      _time.format(context),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    onTap: _pickTime,
                  ),
              ],
            ),
    );
  }
}
