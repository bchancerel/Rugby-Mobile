class RugbyMatchOdds {
  const RugbyMatchOdds({
    this.gameId,
    required this.favorite,
    required this.averages,
    required this.markets,
    required this.bookmakersCount,
    this.updatedAt,
  });

  final int? gameId;
  final RugbyOddsFavorite favorite;
  final RugbyOddsAverages averages;
  final List<RugbyOddsMarket> markets;
  final int bookmakersCount;
  final String? updatedAt;

  static RugbyMatchOdds? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      return null;
    }

    return RugbyMatchOdds(
      gameId: _readNullableInt(json['gameId']),
      favorite: RugbyOddsFavorite.fromJson(json['favorite']),
      averages: RugbyOddsAverages.fromJson(json['averages']),
      markets: _readList(json['markets'], RugbyOddsMarket.fromJson),
      bookmakersCount: _readNullableInt(json['bookmakersCount']) ?? 0,
      updatedAt: _readNullableString(json['updatedAt']),
    );
  }
}

class RugbyOddsFavorite {
  const RugbyOddsFavorite({
    this.side,
    this.teamName,
    this.odd,
    required this.confidence,
  });

  final String? side;
  final String? teamName;
  final double? odd;
  final String confidence;

  factory RugbyOddsFavorite.fromJson(Object? json) {
    final map = json is Map<String, dynamic> ? json : const <String, dynamic>{};

    return RugbyOddsFavorite(
      side: _readNullableString(map['side']),
      teamName: _readNullableString(map['teamName']),
      odd: _readNullableDouble(map['odd']),
      confidence: _readNullableString(map['confidence']) ?? 'unknown',
    );
  }
}

class RugbyOddsAverages {
  const RugbyOddsAverages({this.home, this.away, this.draw});

  final double? home;
  final double? away;
  final double? draw;

  factory RugbyOddsAverages.fromJson(Object? json) {
    final map = json is Map<String, dynamic> ? json : const <String, dynamic>{};

    return RugbyOddsAverages(
      home: _readNullableDouble(map['home']),
      away: _readNullableDouble(map['away']),
      draw: _readNullableDouble(map['draw']),
    );
  }
}

class RugbyOddsMarket {
  const RugbyOddsMarket({this.id, this.name, required this.bookmakers});

  final int? id;
  final String? name;
  final List<RugbyOddsBookmaker> bookmakers;

  static RugbyOddsMarket? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      return null;
    }

    return RugbyOddsMarket(
      id: _readNullableInt(json['id']),
      name: _readNullableString(json['name']),
      bookmakers: _readList(json['bookmakers'], RugbyOddsBookmaker.fromJson),
    );
  }
}

class RugbyOddsBookmaker {
  const RugbyOddsBookmaker({this.id, this.name, required this.values});

  final int? id;
  final String? name;
  final List<RugbyOddsValue> values;

  static RugbyOddsBookmaker? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      return null;
    }

    return RugbyOddsBookmaker(
      id: _readNullableInt(json['id']),
      name: _readNullableString(json['name']),
      values: _readList(json['values'], RugbyOddsValue.fromJson),
    );
  }
}

class RugbyOddsValue {
  const RugbyOddsValue({required this.label, this.odd, this.side});

  final String label;
  final double? odd;
  final String? side;

  static RugbyOddsValue? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      return null;
    }

    return RugbyOddsValue(
      label: _readString(json['label']),
      odd: _readNullableDouble(json['odd']),
      side: _readNullableString(json['side']),
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

double? _readNullableDouble(Object? value) {
  if (value is double) {
    return value;
  }

  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    return double.tryParse(value.replaceAll(',', '.'));
  }

  return null;
}
