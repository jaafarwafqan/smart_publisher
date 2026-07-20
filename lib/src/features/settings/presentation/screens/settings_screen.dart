import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/storage_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const _keyPushNotifications = 'settings.push_notifications';
  static const _keyAutoSchedule = 'settings.auto_schedule';
  static const _keyCanaryRelease = 'settings.canary_release';
  static const _keyPreferredTheme = 'settings.preferred_theme';

  bool _pushNotifications = true;
  bool _autoSchedule = true;
  bool _canaryRelease = false;
  String _preferredTheme = 'system';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final storage = ref.read(storageServiceProvider);

    final push = await storage.readString(_keyPushNotifications);
    final auto = await storage.readString(_keyAutoSchedule);
    final canary = await storage.readString(_keyCanaryRelease);
    final theme = await storage.readString(_keyPreferredTheme);

    if (!mounted) {
      return;
    }

    setState(() {
      _pushNotifications = push != 'false';
      _autoSchedule = auto != 'false';
      _canaryRelease = canary == 'true';
      _preferredTheme = theme ?? 'system';
      _loading = false;
    });
  }

  Future<void> _persist() async {
    final storage = ref.read(storageServiceProvider);

    await storage.writeString(_keyPushNotifications, '$_pushNotifications');
    await storage.writeString(_keyAutoSchedule, '$_autoSchedule');
    await storage.writeString(_keyCanaryRelease, '$_canaryRelease');
    await storage.writeString(_keyPreferredTheme, _preferredTheme);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved successfully.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: <Widget>[
          Card(
            child: SwitchListTile(
              title: const Text('Push Notifications'),
              subtitle: const Text('Receive delivery and publishing alerts.'),
              value: _pushNotifications,
              onChanged: (value) => setState(() => _pushNotifications = value),
            ),
          ),
          Card(
            child: SwitchListTile(
              title: const Text('Auto Scheduling Suggestions'),
              subtitle: const Text('Enable smart recommendations for best publish times.'),
              value: _autoSchedule,
              onChanged: (value) => setState(() => _autoSchedule = value),
            ),
          ),
          Card(
            child: SwitchListTile(
              title: const Text('Canary Release Mode'),
              subtitle: const Text('Route a controlled percentage of traffic to canary builds.'),
              value: _canaryRelease,
              onChanged: (value) => setState(() => _canaryRelease = value),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('Preferred Theme'),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const <ButtonSegment<String>>[
                      ButtonSegment<String>(value: 'system', label: Text('System')),
                      ButtonSegment<String>(value: 'light', label: Text('Light')),
                      ButtonSegment<String>(value: 'dark', label: Text('Dark')),
                    ],
                    selected: <String>{_preferredTheme},
                    onSelectionChanged: (value) {
                      setState(() {
                        _preferredTheme = value.first;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _persist,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save Settings'),
          ),
        ],
      ),
    );
  }
}
