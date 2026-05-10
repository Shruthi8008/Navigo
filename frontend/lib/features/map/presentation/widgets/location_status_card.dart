import 'dart:ui';

import 'package:flutter/material.dart';

class LocationStatusCard extends StatelessWidget {
  const LocationStatusCard({
    super.key,
    this.title = 'Location access',
    required this.message,
    this.primaryActionLabel,
    this.onPrimaryAction,
  });

  final String title;
  final String message;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Positioned(
      left: 16,
      right: 16,
      bottom: 32,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(message, style: theme.textTheme.bodyMedium),
                if (primaryActionLabel != null && onPrimaryAction != null) ...[
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: onPrimaryAction,
                    child: Text(primaryActionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
