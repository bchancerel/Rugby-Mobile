import 'package:rugby_jam_mobile/core/network/api_client.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_api_client.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_session_manager.dart';
import 'package:rugby_jam_mobile/features/dashboard/data/dashboard_models.dart';
import 'package:rugby_jam_mobile/features/matches/data/match_odds_models.dart';

class MatchesRepository {
  MatchesRepository({ApiClient? apiClient, AuthSessionManager? sessionManager})
    : _apiClient = apiClient ?? ApiClient(),
      _sessionManager = sessionManager ?? AuthSessionManager.instance;

  final ApiClient _apiClient;
  final AuthSessionManager _sessionManager;

  void close() {
    _apiClient.close(force: true);
  }

  Future<List<RugbyFixture>> fetchFixturesForDate(DateTime date) {
    return _sessionManager.runAuthenticated((accessToken) async {
      final json = await _apiClient.getJsonList(
        '/rugby/fixtures',
        accessToken: accessToken,
        queryParameters: {
          'date': _formatApiDate(date),
          'timezone': 'Europe/Paris',
        },
      );

      return json.map(RugbyFixture.fromJson).whereType<RugbyFixture>().toList()
        ..sort((a, b) => a.sortTime.compareTo(b.sortTime));
    });
  }

  Future<RugbyFixture> fetchFixtureById(int fixtureId, {bool live = false}) {
    return _sessionManager.runAuthenticated((accessToken) async {
      final json = await _apiClient.getJson(
        '/rugby/fixtures/$fixtureId',
        accessToken: accessToken,
        queryParameters: live
            ? {
                'live': '1',
                't': DateTime.now().millisecondsSinceEpoch.toString(),
              }
            : null,
      );
      final fixture = RugbyFixture.fromJson(json);

      if (fixture == null) {
        throw const AuthApiException(message: 'Match indisponible.');
      }

      return fixture;
    });
  }

  Future<RugbyMatchOdds> fetchFixtureOdds(int fixtureId) {
    return _sessionManager.runAuthenticated((accessToken) async {
      final json = await _apiClient.getJson(
        '/rugby/fixtures/$fixtureId/odds',
        accessToken: accessToken,
      );
      final odds = RugbyMatchOdds.fromJson(json);

      if (odds == null) {
        throw const AuthApiException(message: 'Cotes indisponibles.');
      }

      return odds;
    });
  }
}

String _formatApiDate(DateTime date) {
  final local = date.toLocal();
  final year = local.year.toString().padLeft(4, '0');
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
