import 'package:flutter_test/flutter_test.dart';
import 'package:rugby_jam_mobile/features/dashboard/data/dashboard_models.dart';
import 'package:rugby_jam_mobile/features/rugby/rugby_fixture_utils.dart';

void main() {
  group('rugbyFixtureStatus', () {
    test('keeps a not-started fixture upcoming inside the refresh window', () {
      final fixture = _fixture(
        date: DateTime.now()
            .subtract(const Duration(minutes: 1))
            .toIso8601String(),
        status: const RugbyFixtureStatus(
          long: 'Not Started',
          short: 'NS',
          elapsed: null,
        ),
      );

      final status = rugbyFixtureStatus(fixture);

      expect(status.label, 'A venir');
      expect(status.isLive, isFalse);
      expect(isRugbyFixtureInRefreshWindow(fixture), isTrue);
    });

    test('marks explicit live status as live', () {
      final fixture = _fixture(
        status: const RugbyFixtureStatus(
          long: 'First Half',
          short: '1H',
          elapsed: 12,
        ),
      );

      final status = rugbyFixtureStatus(fixture);

      expect(status.label, 'Live');
      expect(status.isLive, isTrue);
    });

    test('keeps elapsed zero scheduled fixtures upcoming', () {
      final fixture = _fixture(
        status: const RugbyFixtureStatus(
          long: 'Not Started',
          short: 'NS',
          elapsed: 0,
        ),
      );

      final status = rugbyFixtureStatus(fixture);

      expect(status.label, 'A venir');
      expect(status.isLive, isFalse);
    });
  });
}

RugbyFixture _fixture({
  String? date,
  RugbyFixtureStatus status = const RugbyFixtureStatus(
    long: 'Not Started',
    short: 'NS',
    elapsed: null,
  ),
}) {
  final kickoff =
      date ?? DateTime.now().add(const Duration(hours: 2)).toIso8601String();
  final parsedKickoff = DateTime.tryParse(kickoff);

  return RugbyFixture(
    id: 1,
    date: kickoff,
    timestamp: parsedKickoff == null
        ? null
        : parsedKickoff.millisecondsSinceEpoch ~/ 1000,
    timezone: 'Europe/Paris',
    status: status,
    league: const RugbyFixtureLeague(
      id: 10,
      name: 'Top 14',
      season: 2026,
      logo: null,
      round: 'Round 1',
    ),
    teams: const RugbyFixtureTeams(
      home: RugbyFixtureTeam(id: 1, name: 'Home', logo: null, winner: null),
      away: RugbyFixtureTeam(id: 2, name: 'Away', logo: null, winner: null),
    ),
    score: const RugbyFixtureScore(home: null, away: null),
    periods: const RugbyFixturePeriods(
      first: RugbyFixturePeriodScore(home: null, away: null),
      second: RugbyFixturePeriodScore(home: null, away: null),
      overtime: RugbyFixturePeriodScore(home: null, away: null),
      secondOvertime: RugbyFixturePeriodScore(home: null, away: null),
    ),
  );
}
