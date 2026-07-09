param([string]$Version = "1.1.0")

$src = Join-Path $PSScriptRoot "build\app\outputs\flutter-apk\app-debug.apk"
if (-not (Test-Path $src)) {
    Write-Error "No APK - run: flutter build apk --debug"
    exit 1
}

$destDir = "D:\Beta Apps\Refactor-Room"
New-Item -ItemType Directory -Force -Path $destDir | Out-Null

$destName = "Refactor-Room-Venice-No-Lenses-debug-v$Version.apk"
$dest = Join-Path $destDir $destName
$latest = "D:\Beta Apps\Refactor-Room-LATEST.apk"

Copy-Item -Force $src $dest
Copy-Item -Force $src $latest
Write-Host "Copied to $dest"
Write-Host "Updated $latest"
