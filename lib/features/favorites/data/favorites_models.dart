class FavoritesResponse {
  const FavoritesResponse({
    required this.teams,
    required this.competitions,
  });

  final FavoriteCollection teams;
  final FavoriteCollection competitions;

  factory FavoritesResponse.fromJson(Map<String, dynamic> json) {
    return FavoritesResponse(
      teams: FavoriteCollection.fromJson(json['teams']),
      competitions: FavoriteCollection.fromJson(json['competitions']),
    );
  }
}

class FavoriteCollection {
  const FavoriteCollection({
    required this.data,
    required this.total,
    required this.limit,
  });

  const FavoriteCollection.empty()
      : data = const [],
        total = 0,
        limit = 3;

  final List<Favorite> data;
  final int total;
  final int limit;

  factory FavoriteCollection.fromJson(Object? json) {
    final map = json is Map<String, dynamic> ? json : const <String, dynamic>{};
    final rawData = map['data'];

    return FavoriteCollection(
      data: rawData is List
          ? rawData.map(Favorite.fromJson).whereType<Favorite>().toList()
          : const [],
      total: _readInt(map['total']),
      limit: _readInt(map['limit'], fallback: 3),
    );
  }
}

class Favorite {
  const Favorite({
    required this.id,
    required this.entityType,
    required this.entityId,
    this.entityName,
  });

  final String id;
  final String entityType;
  final String entityId;
  final String? entityName;

  static Favorite? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      return null;
    }

    final id = _readString(json['id']);
    final entityType = _readString(json['entityType']);
    final entityId = _readString(json['entityId']);

    if (id.isEmpty || entityType.isEmpty || entityId.isEmpty) {
      return null;
    }

    return Favorite(
      id: id,
      entityType: entityType,
      entityId: entityId,
      entityName: _readNullableString(json['entityName']),
    );
  }
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
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }

  return fallback;
}
