import 'package:rugby_jam_mobile/core/network/api_client.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_api_client.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_session_manager.dart';
import 'package:rugby_jam_mobile/features/dashboard/data/dashboard_models.dart';
import 'package:rugby_jam_mobile/features/teams/data/teams_models.dart';

class TeamsRepository {
  TeamsRepository({
    ApiClient? apiClient,
    AuthSessionManager? sessionManager,
  })  : _apiClient = apiClient ?? ApiClient(),
        _sessionManager = sessionManager ?? AuthSessionManager.instance;

  final ApiClient _apiClient;
  final AuthSessionManager _sessionManager;

  void close() {
    _apiClient.close(force: true);
  }

  Future<List<RugbyTeamContext>> fetchTeamContexts(int teamId) {
    return _sessionManager.runAuthenticated(
      (accessToken) async {
        final json = await _apiClient.getJsonList(
          '/rugby/teams/$teamId/contexts',
          accessToken: accessToken,
        );

        return sortTeamContexts(
          json
              .map(RugbyTeamContext.fromJson)
              .whereType<RugbyTeamContext>()
              .toList(),
        );
      },
    );
  }

  Future<RugbyTeamDetailData> fetchTeamDetailData(
    int teamId, {
    required int leagueId,
    required int season,
  }) async {
    final contextsFuture = fetchTeamContexts(teamId);
    final statisticsFuture = fetchTeamStatistics(
      teamId,
      leagueId: leagueId,
      season: season,
    );
    final fixturesFuture = fetchTeamFixtures(
      teamId,
      leagueId: leagueId,
      season: season,
    );

    return RugbyTeamDetailData(
      contexts: await contextsFuture,
      statistics: await statisticsFuture,
      fixtures: await fixturesFuture,
    );
  }

  Future<RugbyTeamStatistics> fetchTeamStatistics(
    int teamId, {
    required int leagueId,
    required int season,
  }) {
    return _sessionManager.runAuthenticated(
      (accessToken) async {
        final json = await _apiClient.getJson(
          '/rugby/teams/$teamId/statistics',
          accessToken: accessToken,
          queryParameters: {
            'league': leagueId.toString(),
            'season': season.toString(),
          },
        );
        final statistics = RugbyTeamStatistics.fromJson(json);

        if (statistics == null) {
          throw const AuthApiException(
            message: 'Statistiques equipe indisponibles.',
          );
        }

        return statistics;
      },
    );
  }

  Future<List<RugbyFixture>> fetchTeamFixtures(
    int teamId, {
    required int leagueId,
    required int season,
  }) {
    return _sessionManager.runAuthenticated(
      (accessToken) async {
        final json = await _apiClient.getJsonList(
          '/rugby/fixtures',
          accessToken: accessToken,
          queryParameters: {
            'team': teamId.toString(),
            'league': leagueId.toString(),
            'season': season.toString(),
          },
        );

        return sortTeamFixtures(
          json.map(RugbyFixture.fromJson).whereType<RugbyFixture>().toList(),
        );
      },
    );
  }
}
