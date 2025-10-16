class Habit {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String frequency;
  final String? icon; // new
  final bool notificationEnabled; // new
  final DateTime createdAt;

  Habit({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.frequency,
    this.icon,
    this.notificationEnabled = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty) 'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'frequency': frequency,
      'icon': icon,
      'notification_enabled': notificationEnabled,
      'created_at': createdAt.toIso8601String(),
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
    );
  }
}
