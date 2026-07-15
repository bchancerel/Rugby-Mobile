import 'dart:async';

import 'package:rugby_jam_mobile/features/dashboard/data/dashboard_models.dart';
import 'package:rugby_jam_mobile/features/rugby/rugby_fixture_utils.dart';
import 'package:rugby_jam_mobile/features/supporter/data/supporter_repository.dart';

class SupporterTracking {
  SupporterTracking._();

  static final _repository = SupporterRepository();
  static final _trackedKeys = <String>{};

  static void trackDailyActive() {
    unawaited(_trackEvent(type: 'DAILY_ACTIVE'));
  }

  static void trackTeamViewed(int teamId) {
    unawaited(
      _trackEvent(
        type: 'TEAM_VIEWED',
        entityId: teamId.toString(),
      ),
    );
  }

  static void trackCompetitionViewed(int leagueId) {
    unawaited(
      _trackEvent(
        type: 'COMPETITION_VIEWED',
        entityId: leagueId.toString(),
      ),
    );
  }

  static void trackFixtureOpened(RugbyFixture fixture) {
    final fixtureId = fixture.id;
    if (fixtureId == null) {
      return;
    }

    final entityId = fixtureId.toString();
    unawaited(
      _trackEvent(
        type: 'MATCH_VIEWED',
        entityId: entityId,
      ),
    );

    final status = rugbyFixtureStatus(fixture);
    if (status.isLive) {
      unawaited(
        _trackEvent(
          type: 'LIVE_MATCH_FOLLOWED',
          entityId: entityId,
        ),
      );
      return;
    }

    if (fixture.score.home != null && fixture.score.away != null) {
      unawaited(
        _trackEvent(
          type: 'FINISHED_MATCH_VIEWED',
          entityId: entityId,
        ),
      );
    }
  }

  static void trackMatchViewed(int matchId) {
    if (matchId <= 0) {
      return;
    }

    unawaited(
      _trackEvent(
        type: 'MATCH_VIEWED',
        entityId: matchId.toString(),
      ),
    );
  }

  static Future<void> _trackEvent({
    required String type,
    String? entityId,
  }) async {
    final key = '$type:${entityId ?? ''}';
    if (_trackedKeys.contains(key)) {
      return;
    }

    _trackedKeys.add(key);

    try {
      await _repository.recordEvent(
        type: type,
        entityId: entityId,
      );
    } catch (_) {
      _trackedKeys.remove(key);
    }
  }
}
