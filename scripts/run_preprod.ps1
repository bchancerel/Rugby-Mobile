param(
    [string]$ApiBaseUrl = $env:RUGBY_JAM_PREPROD_API_BASE_URL
)

$flutterArgs = @(
    'run',
    '--dart-define=RUGBY_JAM_API_ENV=preprod'
)

if (-not [string]::IsNullOrWhiteSpace($ApiBaseUrl)) {
    $flutterArgs += "--dart-define=RUGBY_JAM_PREPROD_API_BASE_URL=$ApiBaseUrl"
}

$flutterArgs += $args

flutter @flutterArgs
