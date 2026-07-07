class DashboardData {
  const DashboardData({
    required this.favorites,
    required this.matchesHome,
  });

  final FavoritesResponse favorites;
  final RugbyMatchesHome matchesHome;

  bool get hasFavorites =>
      favorites.teams.total > 0 || favorites.competitions.total > 0;

  List<RugbyFavoriteMatch> get teamUpcomingMatches {
    final matches = matchesHome.favoriteMatches
        .where((match) => match.type == 'team' && match.nextFixture != null)
        .toList()
      ..sort(
        (a, b) => a.nextFixture!.sortTime.compareTo(b.nextFixture!.sortTime),
      );

    return matches.take(4).toList();
  }
}

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
  });

  final List<Favorite> data;
  final int total;

  factory FavoriteCollection.fromJson(Object? json) {
    final map = json is Map<String, dynamic> ? json : const <String, dynamic>{};
    final rawData = map['data'];

    return FavoriteCollection(
      data: rawData is List
          ? rawData.map(Favorite.fromJson).whereType<Favorite>().toList()
          : const [],
      total: _readInt(map['total']),
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

class RugbyMatchesHome {
  const RugbyMatchesHome({
    required this.favoriteMatches,
    required this.liveFixtures,
    required this.upcomingFixtures,
  });

  final List<RugbyFavoriteMatch> favoriteMatches;
  final List<RugbyFixture> liveFixtures;
  final List<RugbyFixture> upcomingFixtures;

  factory RugbyMatchesHome.fromJson(Map<String, dynamic> json) {
    return RugbyMatchesHome(
      favoriteMatches: _readList(
        json['favoriteMatches'],
        RugbyFavoriteMatch.fromJson,
      ),
      liveFixtures: _readList(json['liveFixtures'], RugbyFixture.fromJson),
      upcomingFixtures: _readList(
        json['upcomingFixtures'],
        RugbyFixture.fromJson,
      ),
    );
  }
}

class RugbyFavoriteMatch {
  const RugbyFavoriteMatch({
    required this.key,
    required this.label,
    required this.type,
    required this.entityId,
    this.logo,
    this.lastFixture,
    this.nextFixture,
  });

  final String key;
  final String label;
  final String type;
  final String entityId;
  final String? logo;
  final RugbyFixture? lastFixture;
  final RugbyFixture? nextFixture;

  static RugbyFavoriteMatch? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      return null;
    }

    return RugbyFavoriteMatch(
      key: _readString(json['key']),
      label: _readString(json['label'], fallback: 'Equipe favorite'),
      type: _readString(json['type']),
      entityId: _readString(json['entityId']),
      logo: _readNullableString(json['logo']),
      lastFixture: RugbyFixture.fromJson(json['lastFixture']),
      nextFixture: RugbyFixture.fromJson(json['nextFixture']),
    );
  }
}

class RugbyFixture {
  const RugbyFixture({
    this.id,
    this.date,
    this.timestamp,
    required this.league,
    required this.teams,
    required this.score,
  });

  final int? id;
  final String? date;
  final int? timestamp;
  final RugbyFixtureLeague league;
  final RugbyFixtureTeams teams;
  final RugbyFixtureScore score;

  int get sortTime {
    if (timestamp != null) {
      return timestamp! * 1000;
    }

    final parsedDate = date == null ? null : DateTime.tryParse(date!);
    return parsedDate?.millisecondsSinceEpoch ?? 9223372036854775807;
  }

  static RugbyFixture? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      return null;
    }

    return RugbyFixture(
      id: _readNullableInt(json['id']),
      date: _readNullableString(json['date']),
      timestamp: _readNullableInt(json['timestamp']),
      league: RugbyFixtureLeague.fromJson(json['league']),
      teams: RugbyFixtureTeams.fromJson(json['teams']),
      score: RugbyFixtureScore.fromJson(json['score']),
    );
  }
}

class RugbyFixtureLeague {
  const RugbyFixtureLeague({
    this.id,
    this.name,
    this.season,
    this.logo,
    this.round,
  });

  final int? id;
  final String? name;
  final int? season;
  final String? logo;
  final String? round;

  factory RugbyFixtureLeague.fromJson(Object? json) {
    final map = json is Map<String, dynamic> ? json : const <String, dynamic>{};

    return RugbyFixtureLeague(
      id: _readNullableInt(map['id']),
      name: _readNullableString(map['name']),
      season: _readNullableInt(map['season']),
      logo: _readNullableString(map['logo']),
      round: _readNullableString(map['round']),
    );
  }
}

class RugbyFixtureTeams {
  const RugbyFixtureTeams({
    required this.home,
    required this.away,
  });

  final RugbyFixtureTeam home;
  final RugbyFixtureTeam away;

  factory RugbyFixtureTeams.fromJson(Object? json) {
    final map = json is Map<String, dynamic> ? json : const <String, dynamic>{};

    return RugbyFixtureTeams(
      home: RugbyFixtureTeam.fromJson(map['home']),
      away: RugbyFixtureTeam.fromJson(map['away']),
    );
  }
}

class RugbyFixtureTeam {
  const RugbyFixtureTeam({
    this.id,
    this.name,
    this.logo,
  });

  final int? id;
  final String? name;
  final String? logo;

  factory RugbyFixtureTeam.fromJson(Object? json) {
    final map = json is Map<String, dynamic> ? json : const <String, dynamic>{};

    return RugbyFixtureTeam(
      id: _readNullableInt(map['id']),
      name: _readNullableString(map['name']),
      logo: _readNullableString(map['logo']),
    );
  }
}

class RugbyFixtureScore {
  const RugbyFixtureScore({
    this.home,
    this.away,
  });

  final int? home;
  final int? away;

  factory RugbyFixtureScore.fromJson(Object? json) {
    final map = json is Map<String, dynamic> ? json : const <String, dynamic>{};

    return RugbyFixtureScore(
      home: _readNullableInt(map['home']),
      away: _readNullableInt(map['away']),
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

int _readInt(Object? value) => _readNullableInt(value) ?? 0;

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
