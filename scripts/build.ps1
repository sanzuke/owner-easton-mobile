# Build dengan nomor build otomatis naik (menit sejak 1 Jan 2026 UTC) -> android versionCode / iOS CFBundleVersion.
# Pemakaian:  .\scripts\build.ps1 [apk|appbundle|ios] [argumen flutter lain...]
#   contoh:   .\scripts\build.ps1 apk --debug
#             .\scripts\build.ps1 appbundle --release
# Nama versi (1.0.0) tetap dari `version:` di pubspec.yaml; hanya angka build yang diganti.
param(
    [string]$Target = 'apk',
    [Parameter(ValueFromRemainingArguments = $true)][string[]]$Rest
)
$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')
$epoch = [DateTimeOffset]::new(2026, 1, 1, 0, 0, 0, [TimeSpan]::Zero)
$buildNumber = [int][math]::Floor(([DateTimeOffset]::UtcNow - $epoch).TotalMinutes)
Write-Host "Nomor build: $buildNumber"
flutter build $Target --build-number=$buildNumber @Rest
