import 'package:rugby_jam_mobile/core/network/api_client.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_api_client.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_session_manager.dart';
import 'package:rugby_jam_mobile/features/favorites/data/favorites_models.dart';

class FavoritesRepository {
  FavoritesRepository({
    ApiClient? apiClient,
    AuthSessionManager? sessionManager,
  })  : _apiClient = apiClient ?? ApiClient(),
        _sessionManager = sessionManager ?? AuthSessionManager.instance;

  final ApiClient _apiClient;
  final AuthSessionManager _sessionManager;

  void close() {
    _apiClient.close(force: true);
  }

  Future<FavoritesResponse> fetchFavorites() {
    return _sessionManager.runAuthenticated(
      (accessToken) async {
        final json = await _apiClient.getJson(
          '/favorites',
          accessToken: accessToken,
        );

        return FavoritesResponse.fromJson(json);
      },
    );
  }

  Future<Favorite> addCompetitionFavorite({
    required int leagueId,
    required String leagueName,
  }) {
    return _sessionManager.runAuthenticated(
      (accessToken) async {
        final json = await _apiClient.postJson(
          '/favorites',
          accessToken: accessToken,
          body: {
            'entityType': 'competition',
            'entityId': leagueId.toString(),
            'entityName': leagueName,
          },
        );
        final favorite = Favorite.fromJson(json);

        if (favorite == null) {
          throw const AuthApiException(message: 'Reponse favori invalide.');
        }

        return favorite;
      },
    );
  }

  Future<Favorite> addTeamFavorite({
    required int teamId,
    required String teamName,
  }) {
    return _sessionManager.runAuthenticated(
      (accessToken) async {
        final json = await _apiClient.postJson(
          '/favorites',
          accessToken: accessToken,
          body: {
            'entityType': 'team',
            'entityId': teamId.toString(),
            'entityName': teamName,
          },
        );
        final favorite = Favorite.fromJson(json);

        if (favorite == null) {
          throw const AuthApiException(message: 'Reponse favori invalide.');
        }

        return favorite;
      },
    );
  }

  Future<void> removeFavorite(String favoriteId) {
    return _sessionManager.runAuthenticated(
      (accessToken) async {
        await _apiClient.deleteJson(
          '/favorites/$favoriteId',
          accessToken: accessToken,
        );
      },
    );
  }
}
