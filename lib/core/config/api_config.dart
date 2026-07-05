class ApiConfig {
  const ApiConfig._();

  static const baseUrl = String.fromEnvironment(
    'RUGBY_JAM_API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );
}
