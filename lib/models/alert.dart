class AlertItem {
  final int id;
  final String type;
  final String title;
  final String message;
  final String severity;
  final bool isRead;
  final String? relatedEntityType;
  final int? relatedEntityId;
  final String? recommendedAction;
  final int? branchId;
  final DateTime createdAt;

  AlertItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.severity,
    required this.isRead,
    required this.createdAt,
    this.relatedEntityType,
    this.relatedEntityId,
    this.recommendedAction,
    this.branchId,
  });

  factory AlertItem.fromJson(Map<String, dynamic> json) => AlertItem(
        id: json['id'],
        type: json['type'],
        title: json['title'],
        message: json['message'],
        severity: json['severity'],
        isRead: json['is_read'] ?? false,
        relatedEntityType: json['related_entity_type'],
        relatedEntityId: json['related_entity_id'],
        recommendedAction: json['recommended_action'],
        branchId: json['branch_id'],
        createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      );
}
