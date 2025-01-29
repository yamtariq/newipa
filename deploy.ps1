# Deployment Script for NayifatAPI
$ErrorActionPreference = "Stop"
$deploymentPath = "C:\Deployment\ProjectName"
$projectPath = ".\NayifatAPI"

Write-Host "1. Cleaning Environment..." -ForegroundColor Green
# Remove existing deployment folder
if (Test-Path $deploymentPath) {
    Remove-Item -Path $deploymentPath -Recurse -Force
}

# Clean build artifacts
Get-ChildItem -Path $projectPath -Include bin,obj -Directory -Recurse | Remove-Item -Recurse -Force
if (Test-Path ".\node_modules") { Remove-Item ".\node_modules" -Recurse -Force }
if (Test-Path ".\.vs") { Remove-Item ".\.vs" -Recurse -Force }

Write-Host "2. Restoring Dependencies..." -ForegroundColor Green
dotnet restore $projectPath

Write-Host "3. Building Project (Release)..." -ForegroundColor Green
dotnet build $projectPath -c Release --no-restore

Write-Host "4. Publishing Project..." -ForegroundColor Green
dotnet publish $projectPath -c Release -o $deploymentPath --no-build

Write-Host "5. Verifying Deployment..." -ForegroundColor Green
if (Test-Path "$deploymentPath\NayifatAPI.dll") {
    Write-Host "Deployment completed successfully!" -ForegroundColor Green
    Write-Host "Files deployed to: $deploymentPath" -ForegroundColor Green
} else {
    Write-Host "Deployment verification failed!" -ForegroundColor Red
    exit 1
}
