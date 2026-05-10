import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/community_comment.dart';
import '../../domain/place_safety_summary.dart';
import '../../domain/place_suggestion.dart';
import '../../domain/route_preference.dart';

class MapBottomSheet extends StatelessWidget {
  const MapBottomSheet({
    super.key,
    this.place,
    required this.routePreference,
    this.placeSafetySummary,
    this.roadSafetySummary,
    required this.comments,
    required this.isFavorite,
    required this.isSubmitting,
    required this.onFavoriteTap,
    this.onRatePlaceTap,
    this.onRateAreaTap,
    required this.onCommentTap,
    this.onDirectionsTap,
    this.onClose,
    this.tappedCoordinates,
    this.tappedLocationComments = const [],
  });

  static const suppressedHeight = 100.0;
  static const defaultHeight = 280.0;
  static const expandedHeight = 520.0;

  final PlaceSuggestion? place;
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
  final VoidCallback? onClose;
  final LatLng? tappedCoordinates;
  final List<CommunityComment> tappedLocationComments;

  bool get isTappedLocation => tappedCoordinates != null && place == null;
  bool get hasTappedLocationComments => tappedLocationComments.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPlace = place != null;
    final hasRoute = roadSafetySummary != null;
    final hasComments = comments.isNotEmpty;
    final hasNearbyComments = tappedLocationComments.isNotEmpty;

    return _DraggableBottomSheet(
      suppressedHeight: suppressedHeight,
      defaultHeight: defaultHeight,
      expandedHeight: (hasComments || hasNearbyComments) ? expandedHeight : defaultHeight,
      builder: (context, sheetHeight, isExpanded, isSuppressed) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                _buildHandle(theme),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeader(theme, hasPlace, hasRoute, hasNearbyComments, isSuppressed),
                        if (!isSuppressed) ...[
                          _buildActions(),
                          if (isExpanded && (hasComments || hasNearbyComments)) ...[
                            const SizedBox(height: 8),
                            _buildComments(theme, hasComments, hasNearbyComments),
                          ],
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHandle(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool hasPlace, bool hasRoute, bool hasNearbyComments, bool isSuppressed) {
    if (isSuppressed) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                hasPlace 
                    ? place!.name 
                    : isTappedLocation 
                        ? _formatCoordinates(tappedCoordinates!)
                        : 'Selected Location',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasPlace 
                          ? place!.name 
                          : isTappedLocation 
                              ? _formatCoordinates(tappedCoordinates!)
                              : 'Selected Location',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (hasPlace) ...[
                      const SizedBox(height: 2),
                      Text(
                        place!.address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                    if (isTappedLocation) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.touch_app_rounded,
                            size: 14,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Tap location',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (hasPlace && placeSafetySummary != null)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _SafetyChip(
                  label: placeSafetySummary!.safetyBadge,
                  color: _badgeColor(placeSafetySummary!.safetyBadge),
                ),
                _MetricChip(label: placeSafetySummary!.normalizedScore.toStringAsFixed(2)),
                _MetricChip(label: '${placeSafetySummary!.totalRatingsCount}'),
              ],
            ),
          if (hasRoute) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _MetricChip(
                  label: routePreference == RoutePreference.safest ? 'Safest' : 'Shortest',
                ),
                _MetricChip(label: roadSafetySummary!.normalizedScore.toStringAsFixed(2)),
              ],
            ),
          ],
          if (isTappedLocation && tappedLocationComments.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${tappedLocationComments.length} comments in this area',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildActions() {
    final isTapped = tappedCoordinates != null && place == null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (onRateAreaTap != null && !isTapped)
            _ActionButton(
              onPressed: isSubmitting ? null : onRateAreaTap!,
              icon: Icons.alt_route_rounded,
              label: 'Rate Area',
              outlined: true,
            ),
          if (onRatePlaceTap != null)
            _ActionButton(
              onPressed: isSubmitting ? null : onRatePlaceTap!,
              icon: Icons.shield_outlined,
              label: 'Rate Place',
              outlined: true,
            ),
          _ActionButton(
            onPressed: isSubmitting ? null : onCommentTap,
            icon: Icons.comment_outlined,
            label: 'Comment',
            outlined: true,
          ),
          if (onDirectionsTap != null)
            _ActionButton(
              onPressed: isSubmitting ? null : onDirectionsTap!,
              icon: Icons.directions_rounded,
              label: 'Directions',
              filled: true,
            ),
        ],
      ),
    );
  }

  Widget _buildComments(ThemeData theme, bool hasPlaceComments, bool hasNearbyComments) {
    final commentsToShow = hasPlaceComments ? comments : tappedLocationComments;
    final isNearby = !hasPlaceComments && hasNearbyComments;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isNearby ? 'Nearby comments' : 'Recent comments',
            style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          ...commentsToShow.take(5).map((comment) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        comment.userName.isNotEmpty ? comment.userName[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(comment.userName, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
                              if (comment.placeName != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '@ ${comment.placeName}',
                                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(comment.comment, maxLines: 3, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  String _formatCoordinates(LatLng point) {
    return '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    this.outlined = false,
    this.filled = false,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final bool outlined;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (filled) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: FilledButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        foregroundColor: theme.colorScheme.onSurface,
        side: BorderSide(color: theme.colorScheme.outline),
      ),
    );
  }
}

class _SafetyChip extends StatelessWidget {
  const _SafetyChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11)),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: theme.textTheme.labelSmall),
    );
  }
}

class _DraggableBottomSheet extends StatefulWidget {
  const _DraggableBottomSheet({
    required this.suppressedHeight,
    required this.defaultHeight,
    required this.expandedHeight,
    required this.builder,
  });

  final double suppressedHeight;
  final double defaultHeight;
  final double expandedHeight;
  final Widget Function(BuildContext context, double height, bool isExpanded, bool isSuppressed) builder;

  @override
  State<_DraggableBottomSheet> createState() => _DraggableBottomSheetState();
}

class _DraggableBottomSheetState extends State<_DraggableBottomSheet>
    with SingleTickerProviderStateMixin {
  double _currentHeight = 0;
  bool _isInitialized = false;
  late AnimationController _animationController;
  Animation<double>? _heightAnimation;

  double get _minHeight => widget.suppressedHeight;
  double get _defaultHeight => widget.defaultHeight;
  double get _maxHeight => widget.expandedHeight;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.addListener(() {
      if (_heightAnimation != null) {
        setState(() {
          _currentHeight = _heightAnimation!.value;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _currentHeight = _defaultHeight;
      _isInitialized = true;
    }
  }

  void _snapToHeight(double target) {
    final screenHeight = MediaQuery.of(context).size.height;
    final clampedTarget = target.clamp(_minHeight, screenHeight * 0.85);

    _heightAnimation = Tween<double>(
      begin: _currentHeight,
      end: clampedTarget,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxAllowed = screenHeight * 0.85;

    final isSuppressed = _currentHeight <= _minHeight + 10;
    final isExpanded = _currentHeight >= _maxHeight - 10;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: _currentHeight.clamp(_minHeight, maxAllowed),
      child: GestureDetector(
        onVerticalDragStart: (_) {
          _animationController.stop();
        },
        onVerticalDragUpdate: (details) {
          setState(() {
            _currentHeight -= details.delta.dy;
            _currentHeight = _currentHeight.clamp(_minHeight, maxAllowed);
          });
        },
        onVerticalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;

          if (velocity < -200) {
            if (_currentHeight >= _defaultHeight - 20) {
              _snapToHeight(_maxHeight);
            } else {
              _snapToHeight(_defaultHeight);
            }
          } else if (velocity > 200) {
            if (_currentHeight <= _defaultHeight + 20) {
              _snapToHeight(_minHeight);
            } else {
              _snapToHeight(_defaultHeight);
            }
          } else {
            final lowerMid = (_minHeight + _defaultHeight) / 2;
            final upperMid = (_defaultHeight + _maxHeight) / 2;

            if (_currentHeight < lowerMid) {
              _snapToHeight(_minHeight);
            } else if (_currentHeight > upperMid) {
              _snapToHeight(_maxHeight);
            } else {
              _snapToHeight(_defaultHeight);
            }
          }
        },
        child: widget.builder(context, _currentHeight, isExpanded, isSuppressed),
      ),
    );
  }
}