class SupporterProfile {
  const SupporterProfile({
    required this.totalXp,
    required this.level,
    required this.badges,
    required this.recentEvents,
  });

  final int totalXp;
  final SupporterLevel level;
  final List<SupporterBadge> badges;
  final List<SupporterEvent> recentEvents;

  factory SupporterProfile.fromJson(Map<String, dynamic> json) {
    return SupporterProfile(
      totalXp: _readInt(json['totalXp']),
      level: SupporterLevel.fromJson(json['level']),
      badges: _readList(json['badges'], SupporterBadge.fromJson),
      recentEvents: _readList(json['recentEvents'], SupporterEvent.fromJson),
    );
  }

  int get unlockedBadgeCount {
    return badges.where((badge) => badge.unlocked).length;
  }
}

class SupporterLevel {
  const SupporterLevel({
    required this.value,
    required this.label,
    required this.currentLevelXp,
    required this.progress,
    this.nextLevelXp,
    this.nextLevelLabel,
  });

  final int value;
  final String label;
  final int currentLevelXp;
  final int? nextLevelXp;
  final String? nextLevelLabel;
  final int progress;

  factory SupporterLevel.fromJson(Object? json) {
    final map = json is Map<String, dynamic> ? json : const <String, dynamic>{};

    return SupporterLevel(
      value: _readInt(map['value'], fallback: 1),
      label: _readString(map['label'], fallback: 'Supporter'),
      currentLevelXp: _readInt(map['currentLevelXp']),
      nextLevelXp: _readNullableInt(map['nextLevelXp']),
      nextLevelLabel: _readNullableString(map['nextLevelLabel']),
      progress: _readInt(map['progress']).clamp(0, 100).toInt(),
    );
  }
}

class SupporterBadge {
  const SupporterBadge({
    required this.key,
    required this.label,
    required this.description,
    required this.xp,
    required this.unlocked,
    this.unlockedAt,
  });

  final String key;
  final String label;
  final String description;
  final int xp;
  final bool unlocked;
  final DateTime? unlockedAt;

  static SupporterBadge? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      return null;
    }

    final key = _readString(json['key']);
    if (key.isEmpty) {
      return null;
    }

    return SupporterBadge(
      key: key,
      label: _readString(json['label'], fallback: key),
      description: _readString(json['description']),
      xp: _readInt(json['xp']),
      unlocked: json['unlocked'] == true,
      unlockedAt: _readDate(json['unlockedAt']),
    );
  }
}

class SupporterEvent {
  const SupporterEvent({
    required this.id,
    required this.type,
    required this.xp,
    required this.createdAt,
    this.userId,
    this.entityType,
    this.entityId,
    this.dedupeKey,
    this.metadata,
  });

  final String id;
  final String? userId;
  final String type;
  final String? entityType;
  final String? entityId;
  final String? dedupeKey;
  final int xp;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  static SupporterEvent? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      return null;
    }

    final id = _readString(json['id']);
    final type = _readString(json['type']);

    if (id.isEmpty || type.isEmpty) {
      return null;
    }

    final metadata = json['metadata'];

    return SupporterEvent(
      id: id,
      userId: _readNullableString(json['userId']),
      type: type,
      entityType: _readNullableString(json['entityType']),
      entityId: _readNullableString(json['entityId']),
      dedupeKey: _readNullableString(json['dedupeKey']),
      xp: _readInt(json['xp']),
      metadata: metadata is Map<String, dynamic> ? metadata : null,
      createdAt: _readDate(json['createdAt']) ?? DateTime.now(),
    );
  }
}

List<T> _readList<T>(Object? value, T? Function(Object? json) mapper) {
  if (value is! List) {
    return const [];
  }

  return value.map(mapper).whereType<T>().toList();
}

String _readString(Object? value, {String fallback = ''}) {
  if (value is String) {
    return value;
  }

  if (value is num) {
    return value.toString();
  }

  return fallback;
}

String? _readNullableString(Object? value) {
  final string = _readString(value);
  return string.isEmpty ? null : string;
}

int _readInt(Object? value, {int fallback = 0}) {
  return _readNullableInt(value) ?? fallback;
}

int? _readNullableInt(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    return int.tryParse(value);
  }

  return null;
}

DateTime? _readDate(Object? value) {
  if (value is! String || value.isEmpty) {
    return null;
  }

  return DateTime.tryParse(value);
}
