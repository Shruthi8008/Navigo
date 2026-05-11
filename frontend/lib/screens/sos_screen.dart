import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SosScreen extends StatelessWidget {
  const SosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final emergencyContacts = [
      {'title': 'Police Department', 'number': '100'},
      {'title': 'Fire and Rescue', 'number': '101'},
      {'title': 'Ambulance', 'number': '108'},
      {'title': 'Medical Help Line', 'number': '104'},
      {'title': 'Disaster Control Room', 'number': '1077'},
    ];

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Text(
              'Emergency',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: emergencyContacts.length,
              separatorBuilder: (context, index) => const Divider(height: 1, indent: 56),
              itemBuilder: (context, index) {
                final contact = emergencyContacts[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  leading: const Icon(Icons.shield_outlined, size: 24),
                  title: Text(
                    contact['title']!,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                  ),
                  subtitle: Text(
                    contact['number']!,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.phone_outlined),
                    onPressed: () {
                      final uri = Uri(scheme: 'tel', path: contact['number']);
                      launchUrl(uri);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
