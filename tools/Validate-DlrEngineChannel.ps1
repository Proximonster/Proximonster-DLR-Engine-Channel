[CmdletBinding()]
param([string]$RepositoryRoot = "")
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
if ([string]::IsNullOrWhiteSpace($RepositoryRoot)) { $RepositoryRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path) }
$channelPath = Join-Path $RepositoryRoot "channel.json"
if (-not (Test-Path $channelPath)) { throw "channel.json not found." }
$channel = Get-Content $channelPath -Raw | ConvertFrom-Json
foreach ($p in @("schemaVersion","engineId","displayName","engineVersion","targetRuntime","upstreamRepository","upstreamRelease","upstreamCommit","adapterVersion","compatibility","distributionRepository","distributionRelease","distributionAsset","downloadUrl","archiveSha256")) {
    if ($null -eq $channel.$p -or [string]::IsNullOrWhiteSpace([string]$channel.$p)) { throw "channel.json is missing '$p'." }
}
if ($channel.engineId -ne "dlr") { throw "Unexpected engineId." }
if ($channel.targetRuntime -ne "win-x64") { throw "Unexpected targetRuntime." }
if ($channel.archiveSha256 -notmatch '^[0-9a-fA-F]{64}$') { throw "archiveSha256 is not valid SHA-256." }
if ($channel.downloadUrl -notmatch '^https://') { throw "downloadUrl must be HTTPS." }
$asset = Join-Path $RepositoryRoot ("packages\" + [string]$channel.distributionAsset)
if (-not (Test-Path $asset)) { throw "Published package asset is missing: $asset" }
$actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $asset).Hash.ToLowerInvariant()
if ($actual -ne $channel.archiveSha256.ToLowerInvariant()) { throw "Archive SHA-256 mismatch. expected=$($channel.archiveSha256) actual=$actual" }
Write-Host "DLR channel validation PASSED" -ForegroundColor Green
Write-Host "Version : $($channel.engineVersion)"
Write-Host "Archive : $asset"
Write-Host "SHA256  : $actual"
