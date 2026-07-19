import 'package:rugby_jam_mobile/core/network/api_client.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_session_manager.dart';
import 'package:rugby_jam_mobile/features/news/data/news_models.dart';

class NewsRepository {
  NewsRepository({
    ApiClient? apiClient,
    AuthSessionManager? sessionManager,
  })  : _apiClient = apiClient ?? ApiClient(),
        _sessionManager = sessionManager ?? AuthSessionManager.instance;

  final ApiClient _apiClient;
  final AuthSessionManager _sessionManager;

  void close() {
    _apiClient.close(force: true);
  }

  Future<NewsResponse> fetchNews({
    String? source,
    bool transfersOnly = false,
    int limit = 24,
    int offset = 0,
  }) {
    return _sessionManager.runAuthenticated((accessToken) async {
      final json = await _apiClient.getJson(
        '/news',
        accessToken: accessToken,
        queryParameters: {
          'limit': limit.toString(),
          'offset': offset.toString(),
          if (source != null && source.isNotEmpty) 'source': source,
          if (transfersOnly) 'topic': 'transfers',
        },
      );

      return NewsResponse.fromJson(json);
    });
  }
}
