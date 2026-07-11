import 'package:rugby_jam_mobile/core/network/api_client.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_session_manager.dart';
import 'package:rugby_jam_mobile/features/leagues/data/leagues_models.dart';

class LeaguesRepository {
  LeaguesRepository({
    ApiClient? apiClient,
    AuthSessionManager? sessionManager,
  })  : _apiClient = apiClient ?? ApiClient(),
        _sessionManager = sessionManager ?? AuthSessionManager.instance;

  final ApiClient _apiClient;
  final AuthSessionManager _sessionManager;

  void close() {
    _apiClient.close(force: true);
  }

  Future<List<RugbyLeague>> fetchLeagues() {
    return _sessionManager.runAuthenticated(
      (accessToken) async {
        final json = await _apiClient.getJsonList(
          '/rugby/leagues',
          accessToken: accessToken,
        );

        return json.map(RugbyLeague.fromJson).whereType<RugbyLeague>().toList();
      },
    );
  }

  Future<RugbyLeagueOverview?> fetchLeagueOverview(
    int leagueId, {
    int? season,
  }) {
    return _sessionManager.runAuthenticated(
      (accessToken) async {
        final json = await _apiClient.getJson(
          '/rugby/leagues/$leagueId/overview',
          accessToken: accessToken,
          queryParameters: season == null
              ? null
              : {
                  'season': season.toString(),
                },
        );

        return RugbyLeagueOverview.fromJson(json);
      },
    );
  }
}
