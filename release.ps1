param(
    [string]$Version = '2.1.1'
)

$ErrorActionPreference = 'Stop'

$Root = $PSScriptRoot
$Dist = Join-Path $Root 'dist'
$Stage = Join-Path $Dist 'pd3lib-vendor'
$LibDir = Join-Path $Stage 'pd3lib'
$Zip = Join-Path $Dist "pd3lib-$Version.zip"

$RootFiles = @('pd3lib.lua', 'README.md', 'CHANGELOG.md')
$LibFiles = @('selftest.lua', 'LICENSE.md')
$LibDirs = @('core', 'game')

foreach ($File in ($RootFiles + $LibFiles)) {
    if (-not (Test-Path -LiteralPath (Join-Path $Root $File))) {
        Write-Error "missing required file: $File"
        exit 1
    }
}
foreach ($Dir in $LibDirs) {
    if (-not (Test-Path -LiteralPath (Join-Path $Root $Dir))) {
        Write-Error "missing required directory: $Dir"
        exit 1
    }
}

if (Test-Path -LiteralPath $Stage) {
    Remove-Item -LiteralPath $Stage -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $LibDir | Out-Null

# Vendor-ready layout: authors copy pd3lib.lua + pd3lib/ into their mod's scripts folder.
foreach ($File in $RootFiles) {
    Copy-Item -Force -LiteralPath (Join-Path $Root $File) -Destination $Stage
}
foreach ($File in $LibFiles) {
    Copy-Item -Force -LiteralPath (Join-Path $Root $File) -Destination $LibDir
}
foreach ($Dir in $LibDirs) {
    Copy-Item -Recurse -Force -LiteralPath (Join-Path $Root $Dir) -Destination $LibDir
}

if (Test-Path -LiteralPath $Zip) {
    Remove-Item -Force -LiteralPath $Zip
}

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

# Build the archive manually with forward-slash entry names (Compress-Archive
# writes backslashes on Windows PowerShell 5.1, which is not zip-spec).
$Archive = [System.IO.Compression.ZipFile]::Open($Zip, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($File in (Get-ChildItem -LiteralPath $Stage -Recurse -File)) {
        $EntryName = $File.FullName.Substring($Stage.Length + 1) -replace '\\', '/'
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($Archive, $File.FullName, $EntryName) | Out-Null
    }
} finally {
    $Archive.Dispose()
}

$Archive = [System.IO.Compression.ZipFile]::OpenRead($Zip)
try {
    $Entries = $Archive.Entries | ForEach-Object { $_.FullName }
} finally {
    $Archive.Dispose()
}

$Expected = @(
    'pd3lib.lua',
    'README.md',
    'CHANGELOG.md',
    'pd3lib/selftest.lua',
    'pd3lib/LICENSE.md',
    'pd3lib/core/log.lua',
    'pd3lib/core/safe.lua',
    'pd3lib/game/heist.lua',
    'pd3lib/game/mission.lua'
)
foreach ($Entry in $Expected) {
    if ($Entries -notcontains $Entry) {
        Write-Error "zip is missing expected entry: $Entry"
        exit 1
    }
}

Write-Host "built: $Zip ($($Entries.Count) entries)"
$Entries | Sort-Object | ForEach-Object { Write-Host "  $_" }
