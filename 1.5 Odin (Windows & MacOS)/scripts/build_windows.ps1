param(
    [ValidateSet("debug", "release")]
    [string]$Mode = "release"
)

$ErrorActionPreference = "Stop"
$ProjectDirectory = Split-Path -Parent $PSScriptRoot
$SourceDirectory = Join-Path $ProjectDirectory "source"
$DistDirectory = Join-Path $ProjectDirectory "dist/windows"
$ExecutablePath = Join-Path $DistDirectory "CaveRace.exe"

if (Test-Path $DistDirectory) {
    Remove-Item -Recurse -Force $DistDirectory
}
New-Item -ItemType Directory -Force $DistDirectory | Out-Null

$BuildFlags = @()
if ($Mode -eq "debug") {
    $BuildFlags += "-debug"
} else {
    $BuildFlags += "-o:speed"
}

Push-Location $SourceDirectory
try {
    & odin build . @BuildFlags "-out:../dist/windows/CaveRace.exe"
} finally {
    Pop-Location
}
if ($LASTEXITCODE -ne 0) {
    throw "Odin build failed with exit code $LASTEXITCODE."
}

Copy-Item -Recurse (Join-Path $SourceDirectory "media") (Join-Path $DistDirectory "media")
Copy-Item -Recurse (Join-Path $SourceDirectory "levels") (Join-Path $DistDirectory "levels")

$RequiredFiles = @(
    $ExecutablePath,
    (Join-Path $DistDirectory "media/screens/game_border.png"),
    (Join-Path $DistDirectory "levels/10.bin")
)
foreach ($RequiredFile in $RequiredFiles) {
    if (-not (Test-Path $RequiredFile -PathType Leaf)) {
        throw "Package is missing required file: $RequiredFile"
    }
}

Write-Host "Built $Mode Windows package: $DistDirectory"
