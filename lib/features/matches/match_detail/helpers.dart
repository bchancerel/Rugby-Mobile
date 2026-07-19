part of '../match_detail_screen.dart';

bool _shouldAutoRefreshFixture(RugbyFixture fixture) {
  final status = rugbyFixtureStatus(fixture);
  if (status.isLive) {
    return true;
  }

  if (status.label == 'Termine') {
    return false;
  }

  return isRugbyFixtureInRefreshWindow(fixture);
}

bool _shouldShowFixtureOdds(RugbyFixture fixture) {
  final status = rugbyFixtureStatus(fixture);
  if (status.label == 'Termine') {
    return false;
  }

  final shortStatus = fixture.status.short?.toUpperCase();
  return status.isLive ||
      shortStatus == 'NS' ||
      shortStatus == 'TBD' ||
      !_hasFixtureScore(fixture);
}

bool _hasFixtureScore(RugbyFixture fixture) {
  return fixture.score.home != null && fixture.score.away != null;
}

bool _hasPeriodScore(RugbyFixturePeriodScore period) {
  return period.home != null || period.away != null;
}

bool _hasOvertime(RugbyFixture fixture) {
  return _hasPeriodScore(fixture.periods.overtime) ||
      _hasPeriodScore(fixture.periods.secondOvertime);
}

String _matchStatusLabel(RugbyFixture fixture) {
  final status = rugbyFixtureStatus(fixture);
  if (status.isLive || status.label == 'Termine') {
    return status.label;
  }

  return fixture.status.long ?? fixture.status.short ?? status.label;
}

String _teamRoleLabel(bool away) {
  return away ? 'Exterieur' : 'Domicile';
}

String _formatLongKickoffDate(String? value) {
  if (value == null || value.isEmpty) {
    return 'Date a venir';
  }

  final kickoff = DateTime.tryParse(value);
  if (kickoff == null) {
    return 'Date a venir';
  }

  final local = kickoff.toLocal();
  final weekday = _longWeekdays[local.weekday - 1];
  final day = local.day.toString().padLeft(2, '0');
  final month = _longMonths[local.month - 1];
  return '$weekday $day $month';
}

String _formatKickoffTime(String? value) {
  if (value == null || value.isEmpty) {
    return '--:--';
  }

  final kickoff = DateTime.tryParse(value);
  if (kickoff == null) {
    return '--:--';
  }

  final local = kickoff.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _formatFullKickoff(String? value) {
  if (value == null || value.isEmpty) {
    return 'Date a venir';
  }

  final kickoff = DateTime.tryParse(value);
  if (kickoff == null) {
    return 'Date a venir';
  }

  final local = kickoff.toLocal();
  final year = local.year.toString().padLeft(4, '0');
  return '${_formatLongKickoffDate(value)} $year - ${_formatKickoffTime(value)}';
}

String? _formatLiveLastUpdated(DateTime? value) {
  if (value == null) {
    return null;
  }

  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  final second = value.second.toString().padLeft(2, '0');
  return '$hour:$minute:$second';
}

String _formatTimestamp(int? value) {
  return value == null ? 'Non renseigne' : value.toString();
}

String _formatNullableText(Object? value) {
  if (value == null) {
    return 'Non renseigne';
  }

  final text = value.toString();
  return text.isEmpty ? 'Non renseigne' : text;
}

String _formatWinner(bool? winner) {
  if (winner == true) {
    return 'Victoire';
  }

  if (winner == false) {
    return 'Defaite';
  }

  return 'Non renseigne';
}

String _formatOdd(double? value) {
  if (value == null) {
    return '-';
  }

  return value.toStringAsFixed(2).replaceAll('.', ',');
}

String _confidenceLabel(String confidence) {
  return switch (confidence) {
    'clear' => 'tendance nette',
    'close' => 'tendance serree',
    _ => 'tendance incertaine',
  };
}

String _oddsSideLabel(RugbyFixture fixture, String side) {
  return switch (side) {
    'home' => fixture.teams.home.name ?? 'Domicile',
    'away' => fixture.teams.away.name ?? 'Exterieur',
    'draw' => 'Match nul',
    _ => 'Selection',
  };
}

double? _bookmakerOdd(RugbyOddsBookmaker bookmaker, String side) {
  for (final value in bookmaker.values) {
    if (value.side == side) {
      return value.odd;
    }
  }

  return null;
}

String? _leagueDetailRoute(RugbyFixture fixture) {
  final leagueId = fixture.league.id;
  if (leagueId == null) {
    return null;
  }

  final season = fixture.league.season;
  if (season == null) {
    return '${AppRoutes.leagues}/$leagueId';
  }

  return '${AppRoutes.leagues}/$leagueId?season=$season';
}

String? _teamDetailRoute(RugbyFixture fixture, RugbyFixtureTeam team) {
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
