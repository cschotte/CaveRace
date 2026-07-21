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

$BuildFlags = @("-vet", "-vet-cast", "-vet-style", "-vet-tabs", "-warnings-as-errors")
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
    (Join-Path $DistDirectory "media/screens/border.png"),
    (Join-Path $DistDirectory "media/intro/00_branding.png"),
    (Join-Path $DistDirectory "media/intro/00_branding.ogg"),
    (Join-Path $DistDirectory "levels/10.bin")
)
foreach ($RequiredFile in $RequiredFiles) {
    if (-not (Test-Path $RequiredFile -PathType Leaf)) {
        throw "Package is missing required file: $RequiredFile"
    }
}

if ($env:CAVERACE_WINDOWS_CERT_SHA1) {
    & signtool sign /sha1 $env:CAVERACE_WINDOWS_CERT_SHA1 /fd SHA256 `
        /tr "http://timestamp.digicert.com" /td SHA256 $ExecutablePath
    if ($LASTEXITCODE -ne 0) {
        throw "Authenticode signing failed with exit code $LASTEXITCODE."
    }
    & signtool verify /pa /v $ExecutablePath
    if ($LASTEXITCODE -ne 0) {
        throw "Authenticode verification failed with exit code $LASTEXITCODE."
    }
}

Write-Host "Built $Mode Windows package: $DistDirectory"
