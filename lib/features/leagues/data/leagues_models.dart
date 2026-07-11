import 'package:rugby_jam_mobile/features/dashboard/data/dashboard_models.dart';

class RugbyLeague {
  const RugbyLeague({
    required this.id,
    required this.name,
    required this.type,
    required this.logo,
    required this.country,
    required this.seasons,
  });

  final int? id;
  final String? name;
  final String? type;
  final String? logo;
  final RugbyCountry country;
  final List<RugbyLeagueSeason> seasons;

  static RugbyLeague? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      return null;
    }

    return RugbyLeague(
      id: _readNullableInt(json['id']),
      name: _readNullableString(json['name']),
      type: _readNullableString(json['type']),
      logo: _readNullableString(json['logo']),
      country: RugbyCountry.fromJson(json['country']),
      seasons: _readList(json['seasons'], RugbyLeagueSeason.fromJson),
    );
  }

  bool get hasCurrentSeason {
    return seasons.any((season) => season.current);
  }

  int? get seasonLabel {
    final currentSeason = _firstWhereOrNull(
      seasons,
      (season) => season.current,
    );
    if (currentSeason?.year != null) {
      return currentSeason!.year;
    }

    final years = seasons
        .map((season) => season.year)
        .whereType<int>()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    return years.isEmpty ? null : years.first;
  }

  String get displayName {
    return name ?? 'Competition sans nom';
  }

  String get key {
    return (id ?? name ?? displayName).toString();
  }
}

class RugbyCountry {
  const RugbyCountry({
    required this.name,
    required this.code,
    required this.flag,
  });

  final String? name;
  final String? code;
  final String? flag;

  factory RugbyCountry.fromJson(Object? json) {
    final map = json is Map<String, dynamic> ? json : const <String, dynamic>{};

    return RugbyCountry(
      name: _readNullableString(map['name']),
      code: _readNullableString(map['code']),
      flag: _readNullableString(map['flag']),
    );
  }

  String get displayName {
    return name ?? 'Pays inconnu';
  }
}

class RugbyLeagueSeason {
  const RugbyLeagueSeason({
    required this.year,
    required this.start,
    required this.end,
    required this.current,
  });

  final int? year;
  final String? start;
  final String? end;
  final bool current;

  static RugbyLeagueSeason? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      return null;
    }

    return RugbyLeagueSeason(
      year: _readNullableInt(json['year']),
      start: _readNullableString(json['start']),
      end: _readNullableString(json['end']),
      current: json['current'] == true,
    );
  }
}

class RugbyLeagueOverview {
  const RugbyLeagueOverview({
    required this.league,
    required this.season,
    required this.standings,
    required this.rounds,
    required this.fixtures,
  });

  final RugbyLeague league;
  final int? season;
  final List<RugbyStandingGroup> standings;
  final List<String> rounds;
  final List<RugbyFixture> fixtures;

  static RugbyLeagueOverview? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      return null;
    }

    final league = RugbyLeague.fromJson(json['league']);
    if (league == null) {
      return null;
    }

    return RugbyLeagueOverview(
      league: league,
      season: _readNullableInt(json['season']),
      standings: _readList(json['standings'], RugbyStandingGroup.fromJson),
      rounds: _readStringList(json['rounds']),
      fixtures: _readList(json['fixtures'], RugbyFixture.fromJson),
    );
  }

  bool get hasVisibleContent {
    return standings.any((group) => group.rows.isNotEmpty) ||
        fixtures.isNotEmpty ||
        rounds.isNotEmpty;
  }

  List<int> get seasonOptions {
    final years = league.seasons.map((season) => season.year).whereType<int>();
    return {
      ...years,
      if (season != null) season!,
    }.toList()
      ..sort((a, b) => b.compareTo(a));
  }
}

class RugbyStandingGroup {
  const RugbyStandingGroup({
    required this.name,
    required this.rows,
  });

  final String? name;
  final List<RugbyStanding> rows;

  static RugbyStandingGroup? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      return null;
    }

    return RugbyStandingGroup(
      name: _readNullableString(json['name']),
      rows: _readList(json['rows'], RugbyStanding.fromJson),
    );
  }

  String get displayName {
    return name ?? 'Classement';
  }
}

class RugbyStanding {
  const RugbyStanding({
    required this.rank,
    required this.team,
    required this.group,
    required this.form,
    required this.status,
    required this.description,
    required this.points,
    required this.pointsDiff,
    required this.all,
  });

  final int? rank;
  final RugbyStandingTeam team;
  final String? group;
  final String? form;
  final String? status;
  final String? description;
  final int? points;
  final int? pointsDiff;
  final RugbyStandingRecord all;

  static RugbyStanding? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      return null;
    }

    return RugbyStanding(
      rank: _readNullableInt(json['rank']),
      team: RugbyStandingTeam.fromJson(json['team']),
      group: _readNullableString(json['group']),
      form: _readNullableString(json['form']),
      status: _readNullableString(json['status']),
      description: _readNullableString(json['description']),
      points: _readNullableInt(json['points']),
      pointsDiff: _readNullableInt(json['pointsDiff']),
      all: RugbyStandingRecord.fromJson(json['all']),
    );
  }
}

class RugbyStandingTeam {
  const RugbyStandingTeam({
    required this.id,
    required this.name,
    required this.logo,
  });

  final int? id;
  final String? name;
  final String? logo;

  factory RugbyStandingTeam.fromJson(Object? json) {
    final map = json is Map<String, dynamic> ? json : const <String, dynamic>{};

    return RugbyStandingTeam(
      id: _readNullableInt(map['id']),
      name: _readNullableString(map['name']),
      logo: _readNullableString(map['logo']),
    );
  }

  String get displayName {
    return name ?? 'Equipe';
  }
}

class RugbyStandingRecord {
  const RugbyStandingRecord({
    required this.played,
    required this.win,
    required this.draw,
    required this.loss,
    required this.pointsFor,
    required this.pointsAgainst,
  });

  final int? played;
  final int? win;
  final int? draw;
  final int? loss;
  final int? pointsFor;
  final int? pointsAgainst;

  factory RugbyStandingRecord.fromJson(Object? json) {
    final map = json is Map<String, dynamic> ? json : const <String, dynamic>{};

    return RugbyStandingRecord(
      played: _readNullableInt(map['played']),
      win: _readNullableInt(map['win']),
      draw: _readNullableInt(map['draw']),
      loss: _readNullableInt(map['loss']),
      pointsFor: _readNullableInt(map['pointsFor']),
      pointsAgainst: _readNullableInt(map['pointsAgainst']),
    );
  }
}

class RugbyLeagueCountryGroup {
  const RugbyLeagueCountryGroup({
    required this.countryName,
    required this.countryCode,
    required this.flag,
    required this.leagues,
  });

  final String countryName;
  final String? countryCode;
  final String? flag;
  final List<RugbyLeague> leagues;
}

const rugbyMajorLeagueIds = [16, 17, 52, 54, 13, 76, 71, 69, 85, 51];

List<RugbyLeagueCountryGroup> groupLeaguesByCountry(List<RugbyLeague> leagues) {
  final groups = <String, RugbyLeagueCountryGroup>{};

  for (final league in leagues) {
    final countryName = league.country.displayName;
    final existingGroup = groups[countryName];

    if (existingGroup != null) {
      existingGroup.leagues.add(league);
      continue;
    }

    groups[countryName] = RugbyLeagueCountryGroup(
      countryName: countryName,
      countryCode: league.country.code,
      flag: league.country.flag,
      leagues: [league],
    );
  }

  return groups.values.toList()
    ..sort((a, b) => a.countryName.compareTo(b.countryName));
}

List<RugbyLeague> findMajorLeagues(List<RugbyLeague> leagues) {
  return rugbyMajorLeagueIds
      .map(
        (id) => _firstWhereOrNull(leagues, (league) => league.id == id),
      )
      .whereType<RugbyLeague>()
      .toList();
}

List<String> findLeagueCountryOptions(List<RugbyLeague> leagues) {
  return leagues
      .map((league) => league.country.name)
      .whereType<String>()
      .toSet()
      .toList()
    ..sort((a, b) => a.compareTo(b));
}

List<String> findLeagueTypeOptions(List<RugbyLeague> leagues) {
  return leagues
      .map((league) => league.type)
      .whereType<String>()
      .toSet()
      .toList()
    ..sort((a, b) => a.compareTo(b));
}

List<RugbyLeague> filterLeagues({
  required List<RugbyLeague> leagues,
  required String query,
  required String country,
  required String type,
  required bool currentSeasonOnly,
}) {
  final normalizedQuery = query.trim().toLowerCase();

  return leagues.where((league) {
    final matchesQuery = normalizedQuery.isEmpty ||
        (league.name?.toLowerCase().contains(normalizedQuery) ?? false) ||
        (league.country.name?.toLowerCase().contains(normalizedQuery) ??
            false);
    final matchesCountry = country.isEmpty || league.country.name == country;
    final matchesType = type.isEmpty || league.type == type;
    final matchesCurrentSeason =
        !currentSeasonOnly || league.hasCurrentSeason;

    return matchesQuery &&
        matchesCountry &&
        matchesType &&
        matchesCurrentSeason;
  }).toList()
    ..sort((a, b) => a.displayName.compareTo(b.displayName));
}

T? _firstWhereOrNull<T>(Iterable<T> values, bool Function(T value) test) {
  for (final value in values) {
    if (test(value)) {
      return value;
    }
  }

  return null;
}

List<T> _readList<T>(Object? value, T? Function(Object? json) mapper) {
  if (value is! List) {
    return const [];
  }

  return value.map(mapper).whereType<T>().toList();
}

List<String> _readStringList(Object? value) {
  if (value is! List) {
    return const [];
  }

  return value.map(_readNullableString).whereType<String>().toList();
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
