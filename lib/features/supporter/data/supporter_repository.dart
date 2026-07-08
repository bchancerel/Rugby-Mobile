import 'package:rugby_jam_mobile/core/network/api_client.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_session_manager.dart';
import 'package:rugby_jam_mobile/features/supporter/data/supporter_models.dart';

class SupporterRepository {
  SupporterRepository({
    ApiClient? apiClient,
    AuthSessionManager? sessionManager,
  })  : _apiClient = apiClient ?? ApiClient(),
        _sessionManager = sessionManager ?? AuthSessionManager.instance;

  final ApiClient _apiClient;
  final AuthSessionManager _sessionManager;

  void close() {
    _apiClient.close(force: true);
  }

  Future<SupporterProfile> fetchProfile() {
    return _sessionManager.runAuthenticated(
      (accessToken) async {
        final json = await _apiClient.getJson(
          '/supporter/me',
          accessToken: accessToken,
        );

        return SupporterProfile.fromJson(json);
      },
    );
  }
}
