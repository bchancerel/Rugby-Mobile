part of '../league_detail_screen.dart';

class _FixtureRound {
  const _FixtureRound({
    required this.name,
    required this.label,
    required this.fixtures,
  });

  final String name;
  final String label;
  final List<RugbyFixture> fixtures;
}

class _RoundKickoff {
  const _RoundKickoff({
    required this.index,
    required this.kickoff,
  });

  final int index;
  final int kickoff;
}

List<_FixtureRound> _buildMatchRounds(
  List<RugbyFixture> fixtures,
  List<String> orderedRounds,
) {
  final groupedFixtures = <String, List<RugbyFixture>>{};

  for (final fixture in fixtures) {
    final roundName = fixture.league.round ?? 'Matchs';
    groupedFixtures.putIfAbsent(roundName, () => []).add(fixture);
  }

  final roundNames = [
    ...orderedRounds.where((roundName) => groupedFixtures.containsKey(roundName)),
    ...groupedFixtures.keys
        .where((roundName) => !orderedRounds.contains(roundName)),
  ];

  return roundNames.map((roundName) {
    final fixturesForRound = groupedFixtures[roundName] ?? const <RugbyFixture>[];
    final roundFixtures = [...fixturesForRound]
      ..sort((a, b) => a.sortTime.compareTo(b.sortTime));

    return _FixtureRound(
      name: roundName,
      label: _formatRoundLabel(roundName),
      fixtures: roundFixtures,
    );
  }).toList();
}

List<_FixtureRound> _buildBracketRounds(
  List<RugbyFixture> fixtures,
  List<String> orderedRounds,
) {
  return _buildMatchRounds(fixtures, orderedRounds)
      .where((round) => _isKnockoutRound(round.name))
      .toList();
}

List<_LeagueDetailTab> _availableLeagueDetailTabs(RugbyLeagueOverview overview) {
  return [
    _LeagueDetailTab.standings,
    _LeagueDetailTab.matches,
    if (_hasBracketRounds(overview.fixtures, overview.rounds))
      _LeagueDetailTab.bracket,
  ];
}

bool _hasBracketRounds(
  List<RugbyFixture> fixtures,
  List<String> orderedRounds,
) {
  return _buildBracketRounds(fixtures, orderedRounds).isNotEmpty;
}

String _formatRoundLabel(String round) {
  final value = round.toLowerCase();
  final regularSeasonMatch =
      RegExp(r'regular season\s*-\s*(\d+)', caseSensitive: false)
              .firstMatch(round) ??
          RegExp(r'(?:round|journ.e|matchday)\s*[- ]\s*(\d+)',
                  caseSensitive: false)
              .firstMatch(round);

  if (regularSeasonMatch != null) {
    return 'Journee ${regularSeasonMatch.group(1)}';
  }

  if (value.contains('round of 16')) {
    return 'Huitiemes de finale';
  }

  if (value.contains('round of 8') || value.contains('quarter')) {
    return 'Quarts de finale';
  }

  if (value.contains('semi')) {
    return 'Demi-finales';
  }

  if (value.contains('final')) {
    return 'Finale';
  }

  if (value.contains('playoff') ||
      value.contains('play-off') ||
      value.contains('barrage')) {
    return 'Barrages';
  }

  return round;
}

bool _isKnockoutRound(String round) {
  final value = round.toLowerCase();
  const keywords = [
    'final',
    'semi',
    'quarter',
    'round of',
    'knockout',
    'playoff',
    'play-off',
    'barrage',
    'accession',
  ];

  return keywords.any((keyword) => value.contains(keyword));
}

