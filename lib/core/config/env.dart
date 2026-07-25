/// AWS ECS production API — default for all builds (debug + release).
///
/// Override only for local backend development:
/// `--dart-define=API_BASE_URL=http://10.0.2.2:3000` (Android emulator)
/// `--dart-define=API_BASE_URL=http://192.168.1.5:3000` (physical device on LAN)
const String productionApiBaseUrl =
    'https://1s-89e678997d014bf3bd82bf5c6d3e78ba.ecs.ap-south-1.on.aws';

/// Compile-time override; wins over [productionApiBaseUrl] when non-empty.
const String _apiBaseUrlFromEnv = String.fromEnvironment('API_BASE_URL');

/// Base URL for the HTTP API — always ECS unless [API_BASE_URL] is passed at build time.
String get apiBaseUrl {
  if (_apiBaseUrlFromEnv.isNotEmpty) return _apiBaseUrlFromEnv;
  return productionApiBaseUrl;
}

/// True when using the deployed AWS API (not a local override).
bool get isProductionApi =>
    apiBaseUrl == productionApiBaseUrl ||
    apiBaseUrl.contains('.ecs.') ||
    apiBaseUrl.contains('.on.aws');
