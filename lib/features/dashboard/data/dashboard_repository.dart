import 'package:rugby_jam_mobile/core/network/api_client.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_session_manager.dart';
import 'package:rugby_jam_mobile/features/dashboard/data/dashboard_models.dart';

class DashboardRepository {
  DashboardRepository({
    ApiClient? apiClient,
    AuthSessionManager? sessionManager,
  })  : _apiClient = apiClient ?? ApiClient(),
        _sessionManager = sessionManager ?? AuthSessionManager.instance;

  final ApiClient _apiClient;
  final AuthSessionManager _sessionManager;

  void close() {
    _apiClient.close(force: true);
  }

  Future<DashboardData> fetchDashboard() async {
    return _sessionManager.runAuthenticated(
      (accessToken) async {
        final favoritesJson = await _apiClient.getJson(
          '/favorites',
          accessToken: accessToken,
        );
        final matchesJson = await _apiClient.getJson(
          '/rugby/matches/home',
          accessToken: accessToken,
          queryParameters: const {'includeGlobalFixtures': '0'},
        );

        return DashboardData(
          favorites: FavoritesResponse.fromJson(favoritesJson),
          matchesHome: RugbyMatchesHome.fromJson(matchesJson),
        );
      },
    );
  }
}
