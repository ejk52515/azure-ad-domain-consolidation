$ErrorActionPreference = "Stop"

$ProjectRoot = "C:\Users\ejk52\azure-ad-domain-consolidation"
$PackageRoot = Read-Host "Enter the extracted README package path"

if (-not (Test-Path $ProjectRoot)) {
    throw "Project folder not found: $ProjectRoot"
}

if (-not (Test-Path (Join-Path $PackageRoot "README.md"))) {
    throw "README package not found at the supplied path."
}

Copy-Item (Join-Path $PackageRoot "README.md") $ProjectRoot -Force

foreach ($Folder in @("docs", "screenshots", "scripts")) {
    $SourceFolder = Join-Path $PackageRoot $Folder
    $DestinationFolder = Join-Path $ProjectRoot $Folder

    New-Item -Path $DestinationFolder -ItemType Directory -Force | Out-Null
    Copy-Item (Join-Path $SourceFolder "*") $DestinationFolder -Recurse -Force
}

Write-Host ""
Write-Host "README package copied to:"
Write-Host $ProjectRoot
Write-Host ""
Write-Host "Review with:"
Write-Host "code $ProjectRoot"
Write-Host "git -C `"$ProjectRoot`" status --short"
