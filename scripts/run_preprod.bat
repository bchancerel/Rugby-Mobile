@echo off
if "%RUGBY_JAM_PREPROD_API_BASE_URL%"=="" (
  flutter run --dart-define=RUGBY_JAM_API_ENV=preprod %*
  exit /b %ERRORLEVEL%
)

flutter run --dart-define=RUGBY_JAM_API_ENV=preprod --dart-define=RUGBY_JAM_PREPROD_API_BASE_URL=%RUGBY_JAM_PREPROD_API_BASE_URL% %*
