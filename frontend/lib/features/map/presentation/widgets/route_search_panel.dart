import 'dart:ui';

import 'package:flutter/material.dart';

import '../../domain/place_suggestion.dart';
import '../../domain/route_state.dart';

class RouteSearchPanel extends StatelessWidget {
  const RouteSearchPanel({
    super.key,
    required this.sourceController,
    required this.destinationController,
    required this.sourceFocusNode,
    required this.destinationFocusNode,
    required this.routeState,
    required this.onFieldTap,
    required this.onFieldChanged,
    required this.onSuggestionSelected,
    required this.onUseCurrentLocation,
    required this.onClearDestination,
  });

  final TextEditingController sourceController;
  final TextEditingController destinationController;
  final FocusNode sourceFocusNode;
  final FocusNode destinationFocusNode;
  final RouteState routeState;
  final ValueChanged<RouteField> onFieldTap;
  final void Function(RouteField field, String value) onFieldChanged;
  final void Function(RouteField field, PlaceSuggestion suggestion)
  onSuggestionSelected;
  final VoidCallback onUseCurrentLocation;
  final VoidCallback onClearDestination;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor.withValues(alpha: 0.76),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SearchInput(
                  controller: destinationController,
                  focusNode: destinationFocusNode,
                  label: 'To',
                  hintText: 'Search destination',
                  icon: Icons.place_rounded,
                  iconColor: Colors.redAccent,
                  suffix: destinationController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: onClearDestination,
                          icon: const Icon(Icons.close_rounded),
                          tooltip: 'Clear destination',
                        ),
                  onTap: () => onFieldTap(RouteField.destination),
                  onChanged: (value) =>
                      onFieldChanged(RouteField.destination, value),
                ),
                if (routeState.isSearching) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ],
                if (routeState.suggestions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: routeState.suggestions.length,
                      separatorBuilder: (_, _) => Divider(
                        color: theme.dividerColor.withValues(alpha: 0.4),
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final suggestion = routeState.suggestions[index];
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            routeState.activeField == RouteField.source
                                ? Icons.radio_button_checked_rounded
                                : Icons.place_rounded,
                          ),
                          title: Text(
                            suggestion.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            suggestion.address,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => onSuggestionSelected(
                            routeState.activeField,
                            suggestion,
                          ),
                        );
                      },
                    ),
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

class _SearchInput extends StatelessWidget {
  const _SearchInput({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hintText,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    required this.onChanged,
    this.suffix,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hintText;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final ValueChanged<String> onChanged;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: controller,
      focusNode: focusNode,
      onTap: onTap,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        filled: true,
        fillColor: theme.colorScheme.surface.withValues(alpha: 0.82),
        prefixIcon: Icon(icon, color: iconColor),
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}
