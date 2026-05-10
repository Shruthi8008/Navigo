import 'dart:ui';

import 'package:flutter/material.dart';

class MapControls extends StatelessWidget {
  const MapControls({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onRecenter,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onRecenter;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 32,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _GlassActionButton(icon: Icons.add_rounded, onPressed: onZoomIn),
          const SizedBox(height: 12),
          _GlassActionButton(icon: Icons.remove_rounded, onPressed: onZoomOut),
          const SizedBox(height: 12),
          _GlassActionButton(
            icon: Icons.my_location_rounded,
            onPressed: onRecenter,
          ),
        ],
      ),
    );
  }
}

class _GlassActionButton extends StatelessWidget {
  const _GlassActionButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: IconButton(onPressed: onPressed, icon: Icon(icon)),
        ),
      ),
    );
  }
}
