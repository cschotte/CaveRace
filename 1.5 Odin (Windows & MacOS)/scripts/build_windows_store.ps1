param(
    [ValidateSet("debug", "release")]
    [string]$Mode = "release"
)

$ErrorActionPreference = "Stop"
$ProjectDirectory = Split-Path -Parent $PSScriptRoot
$SourceDirectory = Join-Path $ProjectDirectory "source"
$PackagingDirectory = Join-Path $ProjectDirectory "packaging/windows-store"
$DistDirectory = Join-Path $ProjectDirectory "dist/windows-store"
$StagingDirectory = Join-Path $DistDirectory "staging"
$ExecutablePath = Join-Path $StagingDirectory "CaveRace.exe"
$MsixPath = Join-Path $DistDirectory "CaveRace.msix"
# Keep the resource path relative to the source working directory. Odin's
# -resource path validation rejects some absolute paths containing spaces.
$RcSource = "../packaging/windows/caverace.rc"
# The output path has the same restriction. The build runs from source/, so
# use a relative path here and retain $ExecutablePath for subsequent checks.
$OdinOutputPath = "../dist/windows-store/staging/CaveRace.exe"

if (Test-Path $DistDirectory) {
    Remove-Item -Recurse -Force $DistDirectory
}
New-Item -ItemType Directory -Force $StagingDirectory | Out-Null

# Unlike build_windows.ps1 (direct distribution, where an unsigned .exe is a
# valid local test build), a Store package is worthless without a real
# package identity, so this is required rather than silently building with
# placeholder values that would fail certification.
$Manifest = Get-Content (Join-Path $PackagingDirectory "AppxManifest.xml") -Raw
if ($Manifest -match "TODO-PARTNER-CENTER") {
    Write-Error "packaging/windows-store/AppxManifest.xml still has placeholder Identity Name/Publisher values. Reserve the app name in Partner Center, then fill in the real values from the app's 'App identity' page before building."
    exit 2
}

$BuildFlags = @("-vet", "-vet-cast", "-vet-style", "-vet-tabs", "-warnings-as-errors")
$BuildFlags += "-resource:$RcSource"
if ($Mode -eq "debug") {
    $BuildFlags += "-debug"
} else {
    $BuildFlags += "-o:speed"
    $BuildFlags += "-extra-linker-flags:/SUBSYSTEM:WINDOWS /ENTRY:mainCRTStartup"
}

Push-Location $SourceDirectory
try {
    & odin build . @BuildFlags "-out:$OdinOutputPath"
} finally {
    Pop-Location
}
if ($LASTEXITCODE -ne 0) {
    throw "Odin build failed with exit code $LASTEXITCODE."
}

Copy-Item -Recurse -Exclude ".DS_Store" (Join-Path $SourceDirectory "media") (Join-Path $StagingDirectory "media")
Copy-Item -Recurse (Join-Path $SourceDirectory "levels") (Join-Path $StagingDirectory "levels")
Copy-Item (Join-Path $PackagingDirectory "AppxManifest.xml") (Join-Path $StagingDirectory "AppxManifest.xml")
Copy-Item -Recurse (Join-Path $PackagingDirectory "Assets") (Join-Path $StagingDirectory "Assets")

$RequiredFiles = @(
    $ExecutablePath,
    (Join-Path $StagingDirectory "AppxManifest.xml"),
    (Join-Path $StagingDirectory "Assets/Square44x44Logo.png"),
    (Join-Path $StagingDirectory "Assets/Square150x150Logo.png"),
    (Join-Path $StagingDirectory "Assets/StoreLogo.png"),
    (Join-Path $StagingDirectory "media/screens/border.png"),
    (Join-Path $StagingDirectory "media/intro/00_branding.png"),
    (Join-Path $StagingDirectory "media/intro/00_branding.ogg"),
    (Join-Path $StagingDirectory "levels/10.bin")
)
foreach ($RequiredFile in $RequiredFiles) {
    if (-not (Test-Path $RequiredFile -PathType Leaf)) {
        throw "Package is missing required file: $RequiredFile"
    }
}

# makeappx.exe ships with the Windows SDK, not necessarily on PATH -- prefer
# PATH if it's already resolvable (e.g. a Developer Command Prompt), else
# search the standard SDK install location for the newest version present.
# Version folders are sorted as [version], not as strings, so e.g. 10.0.9200.0
# never outranks 10.0.19041.0 the way a plain string sort would.
$MakeAppx = Get-Command "makeappx.exe" -ErrorAction SilentlyContinue
$MakeAppxPath = $null
if ($MakeAppx) {
    $MakeAppxPath = $MakeAppx.Source
} else {
    $SdkBinRoot = "C:\Program Files (x86)\Windows Kits\10\bin"
    if (Test-Path $SdkBinRoot) {
        $VersionDirectories = Get-ChildItem $SdkBinRoot -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match '^\d+\.\d+\.\d+\.\d+$' } |
            Sort-Object { [version]$_.Name } -Descending
        foreach ($VersionDirectory in $VersionDirectories) {
            $Candidate = Join-Path $VersionDirectory.FullName "x64\makeappx.exe"
            if (Test-Path $Candidate -PathType Leaf) {
                $MakeAppxPath = $Candidate
                break
            }
        }
    }
}
if (-not $MakeAppxPath) {
    throw "makeappx.exe not found on PATH or under the Windows Kits SDK directory. Install the Windows SDK (or the Windows App Certification Kit, which bundles it)."
}

# No signing step here: unlike build_macos_appstore.sh (which must sign with
# real Store certificates before upload) or build_windows.ps1's optional
# Authenticode signing, the Microsoft Store re-signs MSIX packages itself
# during certification -- a self-/un-signed .msix is the correct submission
# artifact.
& $MakeAppxPath pack /d $StagingDirectory /p $MsixPath /o
if ($LASTEXITCODE -ne 0) {
    throw "makeappx pack failed with exit code $LASTEXITCODE."
}

Write-Host "Built $Mode Microsoft Store package: $MsixPath"
Write-Host "Test locally with: Add-AppxPackage `"$MsixPath`""
Write-Host "Then upload via Partner Center (partner.microsoft.com/dashboard)."
