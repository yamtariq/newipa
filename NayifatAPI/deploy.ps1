# Run this script as Administrator
# Set variables
$siteName = "nayifat-api"
$appPoolName = "nayifat-api-pool"
$sitePath = "C:\inetpub\wwwroot\nayifat-api"
$port = "8080"

# Create application pool
Write-Host "Creating application pool..."
New-WebAppPool -Name $appPoolName -Force
Set-ItemProperty IIS:\AppPools\$appPoolName -name "managedRuntimeVersion" -value ""
Set-ItemProperty IIS:\AppPools\$appPoolName -name "startMode" -value "AlwaysRunning"

# Create site directory if it doesn't exist
if(!(Test-Path $sitePath)) {
    New-Item -ItemType Directory -Path $sitePath
}

# Create website
Write-Host "Creating website..."
New-Website -Name $siteName -PhysicalPath $sitePath -ApplicationPool $appPoolName -Port $port -Force

# Set permissions
Write-Host "Setting permissions..."
$acl = Get-Acl $sitePath
$aclRuleArgs = "IIS AppPool\$appPoolName", "Read,Write,Modify", "ContainerInherit,ObjectInherit", "None", "Allow"
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($aclRuleArgs)
$acl.SetAccessRule($accessRule)
Set-Acl $sitePath $acl

Write-Host "IIS setup complete!"
Write-Host "Now copy your published files to: $sitePath"
Write-Host "Your site will be available at: http://localhost:$port" 