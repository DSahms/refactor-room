param([string]$Version = "1.1.0")

$releaseDir = Join-Path $PSScriptRoot "build\windows\x64\runner\Release"
$exePath = Join-Path $releaseDir "refactor_room.exe"
if (-not (Test-Path $exePath)) {
    Write-Error "No Windows build - run: flutter build windows --release"
    exit 1
}

$destRoot = "D:\Beta Apps\Refactor-Room\Windows"
$portableDir = Join-Path $destRoot "Refactor-Room-Portable-v$Version"
$zipPath = Join-Path $destRoot "Refactor-Room-Windows-v$Version.zip"

if (Test-Path $portableDir) { Remove-Item -Recurse -Force $portableDir }
New-Item -ItemType Directory -Force -Path $portableDir | Out-Null

Copy-Item -Recurse -Force (Join-Path $releaseDir "*") $portableDir

if (Test-Path $zipPath) { Remove-Item -Force $zipPath }
Compress-Archive -Path (Join-Path $portableDir "*") -DestinationPath $zipPath -Force

Write-Host "Portable folder: $portableDir"
Write-Host "Zip archive:     $zipPath"
Write-Host "Run: $portableDir\refactor_room.exe"
