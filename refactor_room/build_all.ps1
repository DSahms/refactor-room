param([string]$Version = "1.1.0")

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

Write-Host "=== Refactor Room build all (v$Version) ==="

flutter pub get
flutter analyze
flutter test

Write-Host "`n--- Windows release ---"
flutter build windows --release
powershell -ExecutionPolicy Bypass -File .\copy_to_windows_release.ps1 -Version $Version

Write-Host "`n--- Android debug ---"
if ($env:JAVA_HOME -and (Test-Path (Join-Path $env:JAVA_HOME "bin\java.exe"))) {
    flutter build apk --debug
    powershell -ExecutionPolicy Bypass -File .\copy_to_beta_apps.ps1 -Version $Version
} else {
    Write-Warning "JAVA_HOME invalid or missing - skipping Android build."
    Write-Warning "Fix JDK (e.g. install Eclipse Temurin 17), then run: flutter build apk --debug; .\copy_to_beta_apps.ps1"
}

Write-Host "`nDone."
