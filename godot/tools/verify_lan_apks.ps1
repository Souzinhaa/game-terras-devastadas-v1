param(
    [Parameter(Mandatory=$true)][string]$Aapt,
    [string]$Project = ''
)
$ErrorActionPreference = 'Stop'
if (-not $Project) { $Project = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path) }
$phone = Join-Path $Project 'builds/terras-devastadas-lan.apk'
$tv = Join-Path $Project 'builds/terras-devastadas-tabuleiro.apk'
$phoneManifest = (& $Aapt dump badging $phone) -join "`n"
$tvManifest = (& $Aapt dump badging $tv) -join "`n"
$tvTree = (& $Aapt dump xmltree $tv AndroidManifest.xml) -join "`n"
if ($phoneManifest -notmatch "package: name='com.bhsp.terrasdevastadas'" -or $phoneManifest -notmatch 'android.permission.INTERNET') { throw 'Manifest do celular inválido.' }
if ($tvManifest -notmatch "package: name='com.bhsp.terrasdevastadas.tabuleiro'" -or $tvManifest -notmatch 'android.permission.INTERNET') { throw 'Manifest da TV inválido.' }
foreach ($required in @('LEANBACK_LAUNCHER','android.hardware.touchscreen','android.software.leanback','android:banner')) {
    if (-not $tvTree.Contains($required)) { throw ('TV sem requisito: ' + $required) }
}
if ($tvManifest -notmatch "uses-feature-not-required: name='android.hardware.touchscreen'") { throw 'TV exige touchscreen.' }
if ($tvManifest -notmatch "native-code:.*'arm64-v8a'.*'armeabi-v7a'") { throw 'TV sem as duas ABIs.' }
Add-Type -AssemblyName System.IO.Compression.FileSystem
$fingerprints = @()
foreach ($apkPath in @($phone, $tv)) {
    $archive = [System.IO.Compression.ZipFile]::OpenRead($apkPath)
    try {
        if (@($archive.Entries | Where-Object { $_.FullName -match '^assets/(tests|tools|docs)/' }).Count -gt 0) { throw ('Conteúdo de desenvolvimento no APK: ' + $apkPath) }
        if ($null -eq $archive.GetEntry('assets/project.binary')) { throw 'APK sem projeto Godot.' }
        $stamp = $archive.GetEntry('assets/data/network-build.json')
        if ($null -eq $stamp) { throw 'APK sem identificação de compatibilidade LAN.' }
        $reader = New-Object System.IO.StreamReader($stamp.Open())
        try { $metadata = $reader.ReadToEnd() | ConvertFrom-Json } finally { $reader.Dispose() }
        $fingerprints += $metadata.fingerprint
    } finally { $archive.Dispose() }
    $file = Get-Item -LiteralPath $apkPath
    [pscustomobject]@{ APK = $file.Name; MiB = [math]::Round($file.Length / 1MB, 1); SHA256 = (Get-FileHash -LiteralPath $apkPath -Algorithm SHA256).Hash }
}
if ($fingerprints[0] -ne $fingerprints[1]) { throw 'Os APKs têm regras/protocolos incompatíveis.' }
Write-Output 'LAN APK verification: OK (package metadata; not physical validation)'
