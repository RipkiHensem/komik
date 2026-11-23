$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$apkDirectory = Join-Path $projectRoot 'build\app\outputs\flutter-apk'
$releaseApk = Join-Path $apkDirectory 'app-release.apk'
$demoApk = Join-Path $apkDirectory 'yomu-release-demo.apk'
$debugKeystore = Join-Path $env:USERPROFILE '.android\debug.keystore'

$androidSdk = $env:ANDROID_SDK_ROOT
if (-not $androidSdk) { $androidSdk = $env:ANDROID_HOME }
if (-not $androidSdk) { $androidSdk = Join-Path $env:LOCALAPPDATA 'Android\Sdk' }

$buildTools = Join-Path $androidSdk 'build-tools'
$apksigner = Get-ChildItem -LiteralPath $buildTools -Directory |
    Sort-Object { [version]$_.Name } -Descending |
    ForEach-Object { Join-Path $_.FullName 'apksigner.bat' } |
    Where-Object { Test-Path -LiteralPath $_ } |
    Select-Object -First 1

if (-not $apksigner) { throw "apksigner tidak ditemukan di $buildTools. Pasang Android SDK Build-Tools terlebih dahulu." }
if (-not (Test-Path -LiteralPath $debugKeystore)) {
    throw "Debug keystore lokal tidak ditemukan: $debugKeystore. Jalankan build Android debug sekali untuk membuatnya."
}

Push-Location $projectRoot
try {
    & flutter build apk --release
    if ($LASTEXITCODE -ne 0) { throw "flutter build apk --release gagal dengan exit code $LASTEXITCODE" }

    if (Test-Path -LiteralPath $demoApk) { Remove-Item -LiteralPath $demoApk -Force }
    & $apksigner sign --ks $debugKeystore --ks-pass pass:android --key-pass pass:android --out $demoApk $releaseApk
    if ($LASTEXITCODE -ne 0) { throw "Penandatanganan APK gagal dengan exit code $LASTEXITCODE" }

    & $apksigner verify --verbose $demoApk
    if ($LASTEXITCODE -ne 0) { throw "Verifikasi tanda tangan APK gagal dengan exit code $LASTEXITCODE" }

    Write-Host "APK demo Release siap: $demoApk"
}
finally {
    Pop-Location
}
