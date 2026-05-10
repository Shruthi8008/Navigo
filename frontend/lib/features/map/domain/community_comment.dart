class CommunityComment {
  const CommunityComment({
    required this.id,
    required this.userName,
    required this.targetType,
    required this.targetKey,
    required this.comment,
    required this.createdAt,
    this.placeName,
    this.address,
    this.latitude,
    this.longitude,
  });

  final int id;
  final String userName;
  final String targetType;
  final String targetKey;
  final String comment;
  final DateTime createdAt;
  final String? placeName;
  final String? address;
  final double? latitude;
  final double? longitude;

  factory CommunityComment.fromJson(Map<String, dynamic> json) {
    DateTime createdAt;
    final createdAtValue = json['createdAt'];
    if (createdAtValue is String) {
      createdAt = DateTime.tryParse(createdAtValue) ?? DateTime.now();
    } else if (createdAtValue is DateTime) {
      createdAt = createdAtValue;
    } else {
      createdAt = DateTime.now();
    }

    return CommunityComment(
      id: (json['id'] as num).toInt(),
      userName: json['userName'] as String,
      targetType: json['targetType'] as String,
      targetKey: json['targetKey'] as String,
      comment: json['comment'] as String,
      createdAt: createdAt,
      placeName: json['placeName'] as String?,
      address: json['address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}
