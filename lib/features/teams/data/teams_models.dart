import 'package:rugby_jam_mobile/features/dashboard/data/dashboard_models.dart';
import 'package:rugby_jam_mobile/features/leagues/data/leagues_models.dart';

class RugbyTeamContext {
  const RugbyTeamContext({
    required this.team,
    required this.league,
    required this.fixturesCount,
    required this.lastFixtureTimestamp,
  });

  final RugbyStandingTeam team;
  final RugbyTeamLeague league;
  final int fixturesCount;
  final int? lastFixtureTimestamp;

  static RugbyTeamContext? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      return null;
    }

    final league = RugbyTeamLeague.fromJson(json['league']);
    if (league.id == null || league.season == null) {
      return null;
    }

    return RugbyTeamContext(
      team: RugbyStandingTeam.fromJson(json['team']),
      league: league,
      fixturesCount: _readInt(json['fixturesCount']),
      lastFixtureTimestamp: _readNullableInt(json['lastFixtureTimestamp']),
    );
  }

  String get key => '${league.id}:${league.season}';
}

class RugbyTeamStatistics {
  const RugbyTeamStatistics({
    required this.team,
    required this.league,
    required this.form,
    required this.all,
    required this.home,
    required this.away,
  });

  final RugbyStandingTeam team;
  final RugbyTeamLeague league;
  final String? form;
  final RugbyTeamStatisticsRecord all;
  final RugbyTeamStatisticsRecord home;
  final RugbyTeamStatisticsRecord away;

  static RugbyTeamStatistics? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      return null;
    }

    return RugbyTeamStatistics(
      team: RugbyStandingTeam.fromJson(json['team']),
      league: RugbyTeamLeague.fromJson(json['league']),
      form: _readNullableString(json['form']),
      all: RugbyTeamStatisticsRecord.fromJson(json['all']),
      home: RugbyTeamStatisticsRecord.fromJson(json['home']),
      away: RugbyTeamStatisticsRecord.fromJson(json['away']),
    );
  }
}

class RugbyTeamStatisticsRecord {
  const RugbyTeamStatisticsRecord({
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

  factory RugbyTeamStatisticsRecord.fromJson(Object? json) {
    final map = json is Map<String, dynamic> ? json : const <String, dynamic>{};

    return RugbyTeamStatisticsRecord(
      played: _readNullableInt(map['played']),
      win: _readNullableInt(map['win']),
      draw: _readNullableInt(map['draw']),
      loss: _readNullableInt(map['loss']),
      pointsFor: _readNullableInt(map['pointsFor']),
      pointsAgainst: _readNullableInt(map['pointsAgainst']),
    );
  }

  int? get pointsDiff {
    if (pointsFor == null || pointsAgainst == null) {
      return null;
    }

    return pointsFor! - pointsAgainst!;
  }

  int? get winRate {
    if (played == null || played == 0 || win == null) {
      return null;
    }

    return ((win! / played!) * 100).round();
  }
}

class RugbyTeamLeague {
  const RugbyTeamLeague({
    required this.id,
    required this.name,
    required this.season,
    required this.logo,
  });

  final int? id;
  final String? name;
  final int? season;
  final String? logo;

  factory RugbyTeamLeague.fromJson(Object? json) {
    final map = json is Map<String, dynamic> ? json : const <String, dynamic>{};

    return RugbyTeamLeague(
      id: _readNullableInt(map['id']),
      name: _readNullableString(map['name']),
      season: _readNullableInt(map['season']),
      logo: _readNullableString(map['logo']),
    );
  }

  String get displayName => name ?? 'Championnat';
}

class RugbyTeamDetailData {
  const RugbyTeamDetailData({
    required this.contexts,
    required this.statistics,
    required this.fixtures,
  });

  final List<RugbyTeamContext> contexts;
  final RugbyTeamStatistics? statistics;
  final List<RugbyFixture> fixtures;
}

List<RugbyTeamContext> sortTeamContexts(List<RugbyTeamContext> contexts) {
  return [...contexts]
    ..sort((a, b) {
      final seasonCompare = (b.league.season ?? 0).compareTo(
        a.league.season ?? 0,
      );
      if (seasonCompare != 0) {
        return seasonCompare;
      }

      final timestampCompare = (b.lastFixtureTimestamp ?? 0).compareTo(
        a.lastFixtureTimestamp ?? 0,
      );
      if (timestampCompare != 0) {
        return timestampCompare;
      }

      return a.league.displayName.compareTo(b.league.displayName);
    });
}

List<RugbyFixture> sortTeamFixtures(List<RugbyFixture> fixtures) {
  return [...fixtures]..sort((a, b) => a.sortTime.compareTo(b.sortTime));
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
