param([string]$Godot = "", [string]$Repo = "", [string]$PeerScript = 'res://tests/lan_network_peer.gd')
$ErrorActionPreference = 'Stop'
if (-not $Repo) { $Repo = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)) }
if (-not $Godot) { $Godot = Join-Path $Repo '.tools/godot/Godot_v4.7.2-stable_win64_console.exe' }
$runRoot = Join-Path $Repo ('.tools/lan-network-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $runRoot -Force | Out-Null
$processes = @()
try {
    foreach ($role in @('host', 'P1', 'P2', 'P3', 'tv')) {
        $profile = Join-Path $runRoot $role
        New-Item -ItemType Directory -Path $profile -Force | Out-Null
        $env:APPDATA = $profile
        $env:LOCALAPPDATA = $profile
        $arguments = @('--headless', '--path', ('"' + (Join-Path $Repo 'godot') + '"'), '--script', $PeerScript, '--', $role)
        $process = Start-Process -FilePath $Godot -ArgumentList $arguments -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $runRoot ($role + '.out.log')) -RedirectStandardError (Join-Path $runRoot ($role + '.err.log'))
        $null = $process.Handle
        $processes += [pscustomobject]@{ Role = $role; Process = $process }
        Start-Sleep -Milliseconds 400
    }
    $deadline = [DateTime]::UtcNow.AddSeconds(60)
    while (@($processes | Where-Object { -not $_.Process.HasExited }).Count -gt 0 -and [DateTime]::UtcNow -lt $deadline) { Start-Sleep -Milliseconds 250 }
    $failed = $false
    foreach ($entry in $processes) {
        if (-not $entry.Process.HasExited) { $entry.Process.Kill(); $failed = $true }
        $entry.Process.WaitForExit()
        $output = Get-Content -LiteralPath (Join-Path $runRoot ($entry.Role + '.out.log')) -Raw
        $errors = Get-Content -LiteralPath (Join-Path $runRoot ($entry.Role + '.err.log')) -Raw
        Write-Output ($entry.Role + ': ' + $output.Trim())
        if ($entry.Process.ExitCode -ne 0 -or $output -notmatch 'LAN_NETWORK_.*_OK' -or $errors -match 'SCRIPT ERROR:|ERROR:.*(leak|timeout|identity)') { $failed = $true; Write-Output $errors }
    }
    Write-Output ('Evidence: ' + $runRoot)
    if ($failed) { exit 1 }
} finally {
    foreach ($entry in $processes) { if (-not $entry.Process.HasExited) { $entry.Process.Kill() } }
}
