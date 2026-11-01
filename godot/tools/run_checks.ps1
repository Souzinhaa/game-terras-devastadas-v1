[CmdletBinding()]
param([string]$Godot = '', [switch]$HeadlessOnly, [string[]]$OnlySuites = @())
$ErrorActionPreference = 'Stop'
$project = Split-Path -Parent $PSScriptRoot
$repo = Split-Path -Parent $project
if (-not $Godot) {
    $localEngine = Join-Path $repo '.tools/godot/Godot_v4.7.2-stable_win64_console.exe'
    if (Test-Path -LiteralPath $localEngine) { $Godot = $localEngine }
    else { $Godot = (Get-Command godot -ErrorAction Stop).Source }
}
$logRoot = Join-Path $repo '.tools/campaign-checks'
New-Item -ItemType Directory -Force -Path $logRoot | Out-Null
$headlessSuites = @('data_validation', 'smoke', 'combat_smoke', 'campaign_smoke', 'campaign_edges', 'shared_contracts', 'pvp_rewards', 'balance_smoke', 'lan_session_smoke', 'lan_campaign_smoke')
$suites = $headlessSuites
if (-not $HeadlessOnly) { $suites += @('ui_smoke', 'reveal_smoke', 'combat_ui_smoke', 'transfers_smoke', 'modern_ui_smoke', 'exploration_ui_smoke', 'campaign_ui_smoke', 'onboarding_ui_smoke', 'start_screen_ui_smoke', 'mobile_layout_smoke', 'mobile_layout_large', 'lan_mobile_layout', 'lan_mobile_compact', 'lan_mobile_s23', 'lan_ui_smoke', 'tv_remote_smoke', 'tv_dashboard_smoke') }
if ($OnlySuites.Count) { $suites = @($suites | Where-Object { $_ -in $OnlySuites }) }
$oldAppData = $env:APPDATA
$oldLocalData = $env:LOCALAPPDATA
$results = @()
try {
    foreach ($suite in $suites) {
        $profile = Join-Path ([System.IO.Path]::GetTempPath()) ('td-' + [guid]::NewGuid().ToString('N').Substring(0,8))
        New-Item -ItemType Directory -Force -Path $profile | Out-Null
        $env:APPDATA = $profile
        $env:LOCALAPPDATA = $profile
        $scriptSuite = if ($suite -eq 'mobile_layout_large') { 'mobile_layout_smoke' } elseif ($suite -in @('lan_mobile_compact', 'lan_mobile_s23')) { 'lan_mobile_layout' } else { $suite }
        $arguments = @('--debug', '--ignore-error-breaks', '--path', $project, '--script', ('res://tests/' + $scriptSuite + '.gd'))
        if ($suite -notin $headlessSuites) { $arguments += @('--position', '-10000,-10000') }
        if ($suite -eq 'mobile_layout_large') { $arguments += @('--', '--text-large') }
        if ($suite -eq 'lan_mobile_compact') { $arguments += @('--', '--compact') }
        if ($suite -eq 'lan_mobile_s23') { $arguments += @('--', '--s23') }
        if ($suite -in $headlessSuites) { $arguments = @('--headless') + $arguments }
        $log = Join-Path $logRoot ($suite + '.log')
        $outputLog = Join-Path $logRoot ($suite + '.out.log')
        $errorLog = Join-Path $logRoot ($suite + '.err.log')
        $quotedArguments = $arguments | ForEach-Object { '"' + $_.Replace('"', '\"') + '"' }
        $process = Start-Process -FilePath $Godot -ArgumentList $quotedArguments -WindowStyle Hidden -PassThru -RedirectStandardOutput $outputLog -RedirectStandardError $errorLog
        $null = $process.Handle
        $finished = $process.WaitForExit(45000)
        if (-not $finished) { $process.Kill(); $process.WaitForExit() }
        $process.Refresh()
        $code = if ($finished) { $process.ExitCode } else { 124 }
        @(Get-Content -LiteralPath $outputLog; Get-Content -LiteralPath $errorLog) | Set-Content -LiteralPath $log -Encoding UTF8
        $parseFailure = Select-String -LiteralPath $log -Pattern 'SCRIPT ERROR:|Parse Error:|Failed to load script|^ERROR:' -Quiet
        $ok = ($code -eq 0 -and -not $parseFailure)
        $results += [pscustomobject]@{ suite = $suite; passed = $ok; exit_code = $code; log = $log }
        Write-Output ($suite + ': ' + $(if ($ok) { 'PASS' } else { 'FAIL - ' + $log }))
    }
} finally {
    $env:APPDATA = $oldAppData
    $env:LOCALAPPDATA = $oldLocalData
}
$results | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $logRoot 'results.json') -Encoding UTF8
if ($results.Where({ -not $_.passed }).Count -gt 0) { exit 1 }
exit 0
