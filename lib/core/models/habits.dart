class Habit {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String frequency;
  final String? icon;
  final bool notificationEnabled;
  final DateTime startDate; // This was your new field
  final DateTime createdAt;
  DateTime? lastCompletedAt;

  Habit({
    required this.id,
    required this.userId,
    required this.name,
    required this.startDate, // Make sure it's in the constructor
    this.description,
    required this.frequency,
    this.icon,
    this.notificationEnabled = false,
    required this.createdAt,
    this.lastCompletedAt,
  });

  // --- I RECOMMEND YOU REMOVE THIS METHOD ---
  // It conflicts with your app's logic of checking the 'habit_logs' table.
  // bool isCompletedOn(DateTime date) { ... }
  // ---

  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty) 'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'start_date': startDate.toIso8601String(),
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
      startDate: DateTime.parse(map['start_date'] as String),
      frequency: map['frequency'],
      icon: map['icon'],
      notificationEnabled: map['notification_enabled'] ?? false,
      createdAt: DateTime.parse(map['created_at']),
      lastCompletedAt:
          map['last_completed_at'] != null
              ? DateTime.parse(map['last_completed_at'])
              : null,
    );
  }
}
