import 'package:flutter/material.dart';

import '../../domain/community_comment.dart';
import '../../domain/place_safety_summary.dart';
import '../../domain/place_suggestion.dart';
import '../../domain/route_preference.dart';

class CommunityPlaceCard extends StatelessWidget {
  const CommunityPlaceCard({
    super.key,
    required this.place,
    required this.routePreference,
    required this.placeSafetySummary,
    required this.roadSafetySummary,
    required this.comments,
    required this.isFavorite,
    required this.isSubmitting,
    required this.onFavoriteTap,
    this.onRatePlaceTap,
    this.onRateAreaTap,
    required this.onCommentTap,
    this.onDirectionsTap,
  });

  final PlaceSuggestion place;
  final RoutePreference routePreference;
  final PlaceSafetySummary? placeSafetySummary;
  final PlaceSafetySummary? roadSafetySummary;
  final List<CommunityComment> comments;
  final bool isFavorite;
  final bool isSubmitting;
  final VoidCallback onFavoriteTap;
  final VoidCallback? onRatePlaceTap;
  final VoidCallback? onRateAreaTap;
  final VoidCallback onCommentTap;
  final VoidCallback? onDirectionsTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final placeSummary = placeSafetySummary;
    final routeSummary = roadSafetySummary;

    return Positioned(
      left: 16,
      right: 16,
      bottom: 32,
      child: Card(
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          place.address,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (onFavoriteTap != null)
                    IconButton(
                      onPressed: isSubmitting ? null : onFavoriteTap,
                      icon: Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border,
                        color: isFavorite ? Colors.redAccent : null,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (onRatePlaceTap != null)
                    OutlinedButton.icon(
                      onPressed: isSubmitting ? null : onRatePlaceTap,
                      icon: const Icon(Icons.shield_outlined),
                      label: const Text('Rate Place'),
                    ),
                  if (onRateAreaTap != null)
                    OutlinedButton.icon(
                      onPressed: isSubmitting ? null : onRateAreaTap,
                      icon: const Icon(Icons.alt_route_rounded),
                      label: const Text('Rate Area'),
                    ),
                  OutlinedButton.icon(
                    onPressed: isSubmitting ? null : onCommentTap,
                    icon: const Icon(Icons.comment_outlined),
                    label: const Text('Comment'),
                  ),
                  if (onDirectionsTap != null)
                    FilledButton.icon(
                      onPressed: isSubmitting ? null : onDirectionsTap,
                      icon: const Icon(Icons.directions_rounded),
                      label: const Text('Directions'),
                    ),
                ],
              ),
              if (comments.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  'Recent comments',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                for (final comment in comments.take(2))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${comment.userName}: ${comment.comment}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _badgeColor(String? badge) {
    switch (badge) {
      case 'Safe':
        return Colors.green;
      case 'Moderate':
        return Colors.orange;
      case 'Unsafe':
        return Colors.redAccent;
      default:
        return Colors.blueGrey;
    }
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.2)),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w700),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(label));
  }
}
