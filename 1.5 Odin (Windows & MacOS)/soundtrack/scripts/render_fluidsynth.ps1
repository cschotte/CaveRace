param([Parameter(Mandatory=$true)][string]$SoundFont)
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Out = Join-Path $Root "renders\wav"
New-Item -ItemType Directory -Force -Path $Out | Out-Null
Get-ChildItem (Join-Path $Root "midi") -Filter *.mid | ForEach-Object {
  fluidsynth -ni $SoundFont $_.FullName -F (Join-Path $Out ($_.BaseName + ".wav")) -r 48000 -O s16
}
