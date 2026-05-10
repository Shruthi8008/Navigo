class PlaceSafetySummary {
  const PlaceSafetySummary({
    required this.normalizedScore,
    required this.safetyBadge,
    required this.totalRatingsCount,
    required this.averageLabel,
  });

  final double normalizedScore;
  final String safetyBadge;
  final int totalRatingsCount;
  final String averageLabel;

  factory PlaceSafetySummary.fromJson(Map<String, dynamic> json) {
    return PlaceSafetySummary(
      normalizedScore: (json['normalizedScore'] as num).toDouble(),
      safetyBadge: json['safetyBadge'] as String,
      totalRatingsCount: (json['totalRatingsCount'] as num).toInt(),
      averageLabel: json['averageLabel'] as String,
    );
  }
}
