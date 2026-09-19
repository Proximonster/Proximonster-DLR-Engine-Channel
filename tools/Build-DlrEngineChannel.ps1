[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$GitHubOwner,

    [string]$RepositoryName = "Proximonster-DLR-Engine-Channel",
    [string]$EngineVersion = "1.1.1",
    [string]$UpstreamRelease = "v4.0.7",
    [string]$UpstreamCommit = "fec734a",
    [int]$AdapterVersion = 2,
    [string]$Compatibility = "net8.0-windows; Phase DLR-2: Douyin + Bilibili + Huya recording",
    [string]$DllPath = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptRoot
$siteRoot = $repoRoot

if ([string]::IsNullOrWhiteSpace($DllPath)) {
    $candidates = Get-ChildItem -Path $repoRoot -Recurse -File -Filter "Proximonster.Dlr.Engine.dll" -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch "\\packages\\|\\publish\\" } |
        Sort-Object LastWriteTimeUtc -Descending
    if ($candidates.Count -eq 0) {
        throw "Proximonster.Dlr.Engine.dll was not found. Build the Proximonster solution in Visual Studio first, then rerun this script or pass -DllPath explicitly."
    }
    $DllPath = $candidates[0].FullName
}

$DllPath = (Resolve-Path $DllPath).Path
if (-not (Test-Path $DllPath -PathType Leaf)) {
    throw "DLR engine DLL does not exist: $DllPath"
}

$packageName = "Proximonster-DLR-Engine-$EngineVersion-win-x64"
$packageDir = Join-Path $siteRoot "packages\$packageName"
$archivePath = Join-Path $siteRoot "packages\$packageName.zip"
$channelPath = Join-Path $siteRoot "channel.json"
$manifestPath = Join-Path $packageDir "engine.manifest.json"

if (Test-Path $packageDir) { Remove-Item -Recurse -Force $packageDir }
if (Test-Path $archivePath) { Remove-Item -Force $archivePath }
New-Item -ItemType Directory -Force -Path $packageDir | Out-Null

Copy-Item -LiteralPath $DllPath -Destination (Join-Path $packageDir "Proximonster.Dlr.Engine.dll") -Force

function Get-PayloadSha256([string]$Root) {
    $files = Get-ChildItem -Path $Root -Recurse -File |
        Where-Object { $_.Name -ine "engine.manifest.json" } |
        ForEach-Object {
            $relative = $_.FullName.Substring($Root.Length).TrimStart('\','/') -replace '\\','/'
            [PSCustomObject]@{ Relative = $relative; File = $_.FullName }
        } |
        Sort-Object Relative

    if ($files.Count -eq 0) { throw "Package contains no payload files." }

    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $builder = New-Object System.Text.StringBuilder
    foreach ($item in $files) {
        $bytes = [System.IO.File]::ReadAllBytes($item.File)
        $hash = $sha256.ComputeHash($bytes)
        $hex = ([System.BitConverter]::ToString($hash) -replace '-','').ToLowerInvariant()
        [void]$builder.Append($item.Relative).Append("`n").Append($hex).Append("`n")
    }
    $data = [System.Text.Encoding]::UTF8.GetBytes($builder.ToString())
    $final = $sha256.ComputeHash($data)
    return ([System.BitConverter]::ToString($final) -replace '-','').ToLowerInvariant()
}

$payloadSha256 = Get-PayloadSha256 $packageDir

$distributionRelease = "dlr-engine-$EngineVersion"
$distributionAsset = "$packageName.zip"
$distributionRepository = "github.com/$GitHubOwner/$RepositoryName"
$siteBase = "https://$GitHubOwner.github.io/$RepositoryName"
$downloadUrl = "$siteBase/packages/$distributionAsset"

$packageManifest = [ordered]@{
    PackageFormatVersion = 1
    EngineId = "dlr"
    DisplayName = "Proximonster DLR"
    EngineVersion = $EngineVersion
    UpstreamRepository = "ihmily/DouyinLiveRecorder"
    UpstreamRelease = $UpstreamRelease
    UpstreamCommit = $UpstreamCommit
    AdapterVersion = $AdapterVersion
    Compatibility = $Compatibility
    PayloadSha256 = $payloadSha256
    DistributionRepository = $distributionRepository
    DistributionRelease = $distributionRelease
    DistributionAsset = $distributionAsset
}
$packageManifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $manifestPath -Encoding utf8

Compress-Archive -Path (Join-Path $packageDir '*') -DestinationPath $archivePath -CompressionLevel Optimal
$archiveSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $archivePath).Hash.ToLowerInvariant()

$channel = [ordered]@{
    schemaVersion = 1
    engineId = "dlr"
    displayName = "Proximonster DLR"
    engineVersion = $EngineVersion
    targetRuntime = "win-x64"
    upstreamRepository = "ihmily/DouyinLiveRecorder"
    upstreamRelease = $UpstreamRelease
    upstreamCommit = $UpstreamCommit
    adapterVersion = $AdapterVersion
    compatibility = $Compatibility
    distributionRepository = $distributionRepository
    distributionRelease = $distributionRelease
    distributionAsset = $distributionAsset
    downloadUrl = $downloadUrl
    archiveSha256 = $archiveSha256
    publishedAtUtc = [DateTime]::UtcNow.ToString("o")
}
$channel | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $channelPath -Encoding utf8

Write-Host ""
Write-Host "DLR CHANNEL PACKAGE READY" -ForegroundColor Green
Write-Host "Engine version : $EngineVersion"
Write-Host "Upstream       : $UpstreamRelease ($UpstreamCommit)"
Write-Host "DLL source     : $DllPath"
Write-Host "Payload SHA256  : $payloadSha256"
Write-Host "Archive SHA256  : $archiveSha256"
Write-Host "Package         : $archivePath"
Write-Host "Channel         : $channelPath"
Write-Host "Download URL    : $downloadUrl"
Write-Host ""
