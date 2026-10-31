param(
    [Parameter(Mandatory=$true)][string]$TemplateZip,
    [Parameter(Mandatory=$true)][string]$GodotVersion,
    [string]$BuildTools = '36.0.0',
    [string]$Project = ''
)
$ErrorActionPreference = 'Stop'
if (-not $Project) { $Project = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path) }
$androidRoot = Join-Path ([System.IO.Path]::GetFullPath($Project)) 'android'
$buildRoot = Join-Path $androidRoot 'build'
New-Item -ItemType Directory -Force $buildRoot | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem
if (-not (Test-Path -LiteralPath (Join-Path $buildRoot 'build.gradle'))) {
    [System.IO.Compression.ZipFile]::ExtractToDirectory((Resolve-Path $TemplateZip).Path, $buildRoot)
}
$utf8 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText((Join-Path $androidRoot '.build_version'), $GodotVersion + "`n", $utf8)
[System.IO.File]::WriteAllText((Join-Path $buildRoot '.gdignore'), '', $utf8)
$gradleConfig = Join-Path $buildRoot 'config.gradle'
$configText = [System.IO.File]::ReadAllText($gradleConfig)
$configText = [regex]::Replace($configText, "buildTools\s*:\s*'[^']+'", ("buildTools         : '" + $BuildTools + "'"))
[System.IO.File]::WriteAllText($gradleConfig, $configText, $utf8)
$manifestPath = Join-Path $buildRoot 'src/main/AndroidManifest.xml'
$manifest = New-Object System.Xml.XmlDocument
$manifest.Load($manifestPath)
$androidNamespace = 'http://schemas.android.com/apk/res/android'
$namespaces = New-Object System.Xml.XmlNamespaceManager($manifest.NameTable)
$namespaces.AddNamespace('android', $androidNamespace)
foreach ($featureName in @('android.hardware.touchscreen', 'android.software.leanback')) {
    $feature = $manifest.SelectSingleNode("/manifest/uses-feature[@android:name='" + $featureName + "']", $namespaces)
    if ($null -eq $feature) {
        $feature = $manifest.CreateElement('uses-feature')
        $nameAttribute = $manifest.CreateAttribute('android', 'name', $androidNamespace)
        $nameAttribute.Value = $featureName
        $null = $feature.Attributes.Append($nameAttribute)
        $null = $manifest.DocumentElement.PrependChild($feature)
    }
    $requiredAttribute = $manifest.CreateAttribute('android', 'required', $androidNamespace)
    $requiredAttribute.Value = 'false'
    $null = $feature.Attributes.SetNamedItem($requiredAttribute)
}
$bannerAttribute = $manifest.CreateAttribute('android', 'banner', $androidNamespace)
$bannerAttribute.Value = '@drawable/tv_banner'
$application = $manifest.SelectSingleNode('/manifest/application')
$null = $application.Attributes.SetNamedItem($bannerAttribute)
$manifest.Save($manifestPath)
$drawables = Join-Path $buildRoot 'res/drawable-nodpi'
New-Item -ItemType Directory -Force $drawables | Out-Null
Copy-Item -LiteralPath (Join-Path $Project 'assets/ui/tv-banner.png') -Destination (Join-Path $drawables 'tv_banner.png')
Write-Output ('Android TV template ready: ' + $buildRoot)
