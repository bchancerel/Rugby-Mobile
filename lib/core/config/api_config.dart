class ApiConfig {
  const ApiConfig._();

  static const environment = String.fromEnvironment(
    'RUGBY_JAM_API_ENV',
    defaultValue: 'local',
  );

  static const overrideBaseUrl = String.fromEnvironment(
    'RUGBY_JAM_API_BASE_URL',
    defaultValue: '',
  );

  static const localBaseUrl = String.fromEnvironment(
    'RUGBY_JAM_LOCAL_API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  static const preprodBaseUrl = String.fromEnvironment(
    'RUGBY_JAM_PREPROD_API_BASE_URL',
    defaultValue: 'https://rugby-api-preprod.up.railway.app/api',
  );

  static String get baseUrl {
    if (overrideBaseUrl.isNotEmpty) {
      return overrideBaseUrl;
    }

    if (environment == 'preprod') {
      return preprodBaseUrl;
    }

    return localBaseUrl;
  }
}
