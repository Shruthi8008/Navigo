import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final themeNotifier = ref.read(themeModeProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark Mode'),
            trailing: Switch(
              value: themeMode == ThemeMode.dark,
              onChanged: (value) {
                themeNotifier.toggleTheme(value);
              },
            ),
          ),
        ],
      ),
    );
  }
}
