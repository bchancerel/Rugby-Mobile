part of '../matches_screen.dart';

class _LeagueFixtureGroup {
  const _LeagueFixtureGroup({
    required this.name,
    required this.logo,
    required this.fixtures,
  });

  final String name;
  final String? logo;
  final List<RugbyFixture> fixtures;
}

List<_LeagueFixtureGroup> _groupFixturesByLeague(List<RugbyFixture> fixtures) {
  final groups = <String, List<RugbyFixture>>{};

  for (final fixture in fixtures) {
    final key =
        fixture.league.id?.toString() ?? fixture.league.name ?? 'competition';
    groups.putIfAbsent(key, () => []).add(fixture);
  }

  return groups.values.map((fixtures) {
    final first = fixtures.first;
    return _LeagueFixtureGroup(
      name: first.league.name ?? 'Competition',
      logo: first.league.logo,
      fixtures: fixtures,
    );
  }).toList();
}

List<RugbyFixture> _filterFixtures(
  List<RugbyFixture> fixtures,
  _MatchFilter filter,
) {
  return fixtures.where((fixture) {
    final status = rugbyFixtureStatus(fixture);

    return switch (filter) {
      _MatchFilter.all => true,
      _MatchFilter.live => status.isLive,
      _MatchFilter.upcoming =>
        !status.isLive &&
            fixture.score.home == null &&
            fixture.score.away == null,
      _MatchFilter.finished =>
        fixture.score.home != null && fixture.score.away != null,
    };
  }).toList();
}

String? _teamRouteForFixture(RugbyFixture fixture, RugbyFixtureTeam team) {
  final teamId = team.id;
  if (teamId == null) {
    return null;
  }

  final leagueId = fixture.league.id;
  final season = fixture.league.season;
  if (leagueId == null || season == null) {
    return '${AppRoutes.teams}/$teamId';
  }

  return '${AppRoutes.teams}/$teamId?league=$leagueId&season=$season';
}

String _formatMatchTime(RugbyFixture fixture) {
  final kickoffTime = rugbyFixtureKickoffTime(fixture);
  if (kickoffTime == null) {
    return '--:--';
  }

  final kickoff = DateTime.fromMillisecondsSinceEpoch(kickoffTime).toLocal();
  final hour = kickoff.hour.toString().padLeft(2, '0');
  final minute = kickoff.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _filterLabel(_MatchFilter filter) {
  return switch (filter) {
    _MatchFilter.all => 'Tous',
    _MatchFilter.live => 'Live',
    _MatchFilter.upcoming => 'A venir',
    _MatchFilter.finished => 'Termines',
  };
}

String _formatDateChipLabel(DateTime date) {
  final today = _dateOnly(DateTime.now());
  final selected = _dateOnly(date);

  if (_isSameDay(selected, today)) {
    return 'Auj.';
  }

  if (_isSameDay(selected, today.subtract(const Duration(days: 1)))) {
    return 'Hier';
  }

  if (_isSameDay(selected, today.add(const Duration(days: 1)))) {
    return 'Dem.';
  }

  return _shortWeekdays[selected.weekday - 1];
}

String _formatLongDate(DateTime date) {
  final today = _dateOnly(DateTime.now());
  if (_isSameDay(date, today)) {
    return "Aujourd'hui";
  }

  final weekday = _longWeekdays[date.weekday - 1];
  final day = date.day.toString().padLeft(2, '0');
  final month = _longMonths[date.month - 1];
  return '$weekday $day $month';
}

List<DateTime> _buildDateRange(DateTime now) {
  final today = _dateOnly(now);
  return List.generate(11, (index) => today.add(Duration(days: index - 3)));
}

DateTime _dateOnly(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

const _shortWeekdays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

const _longWeekdays = [
  'Lundi',
  'Mardi',
  'Mercredi',
  'Jeudi',
  'Vendredi',
  'Samedi',
  'Dimanche',
];

const _longMonths = [
  'janvier',
  'fevrier',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'aout',
  'septembre',
  'octobre',
  'novembre',
  'decembre',
];
