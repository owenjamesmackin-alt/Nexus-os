# NEXUS OS image builder for Windows (PowerShell + Docker Desktop).
# Usage:  .\build.ps1
#         $env:NEXUS_DESKTOP = "0"; .\build.ps1
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error "Docker Desktop is required: https://docs.docker.com/get-docker/"
}

$platform = if ($env:ARCH -in @("arm64", "aarch64")) { "linux/arm64" }
            elseif ($env:ARCH) { "linux/amd64" }
            elseif ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { "linux/arm64" }
            else { "linux/amd64" }

New-Item -ItemType Directory -Force -Path out | Out-Null

$envArgs = @()
foreach ($v in "DISK_MB","NEXUS_DESKTOP","NEXUS_USER","NEXUS_PASSWORD","NEXUS_AUTOLOGIN",
               "NEXUS_KEYMAP","NEXUS_TZ","NEXUS_HOSTNAME","ALPINE_BRANCH","FORMATS") {
    $envArgs += @("-e", $v)
}

Write-Host ">> Building NEXUS OS for $platform ..."
docker run --rm --privileged --platform $platform -v "${PWD}:/work" @envArgs alpine:latest sh /work/inner/build-image.sh
Write-Host ">> Done. Images are in .\out"
Get-ChildItem out
