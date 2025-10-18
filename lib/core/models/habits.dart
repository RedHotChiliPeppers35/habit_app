class Habit {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String frequency;
  final String? icon;
  final bool notificationEnabled;
  final DateTime createdAt;
  DateTime? lastCompletedAt;

  Habit({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.frequency,
    this.icon,
    this.notificationEnabled = false,
    required this.createdAt,
    this.lastCompletedAt,
  });

  bool isCompletedOn(DateTime date) {
    if (lastCompletedAt == null) return false;
    return lastCompletedAt!.year == date.year &&
        lastCompletedAt!.month == date.month &&
        lastCompletedAt!.day == date.day;
  }

  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty) 'id': id, // ✅ Keep for updates, skip for inserts
      'user_id': userId,
      'name': name,
      'description': description,
      'frequency': frequency,
      'icon': icon,
      'notification_enabled': notificationEnabled,
      'created_at': createdAt.toIso8601String(),
      'last_completed_at': lastCompletedAt?.toIso8601String(),
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'],
      userId: map['user_id'],
      name: map['name'],
      description: map['description'],
      frequency: map['frequency'],
      icon: map['icon'],
      notificationEnabled: map['notification_enabled'] ?? false,
      createdAt: DateTime.parse(map['created_at']),
      lastCompletedAt:
          map['last_completed_at'] != null
              ? DateTime.parse(map['last_completed_at'])
              : null, // ✅ renamed
    );
  }
}
