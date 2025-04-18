# ================= WARNING =================
Write-Host "WARNING: This script deletes files from the SharePoint Preservation Hold Library. Use at your own risk. I take NO responsibility for any data loss or consequences!"
$confirmation = Read-Host "Type 'YES' to continue, or anything else to exit"
if ($confirmation -ne 'YES') {
    Write-Host "Exiting script."
    exit
}
# ==========================================

# Prompt for mode
$mode = Read-Host "Enter mode: 'deletion' to delete files, 'monitoring' to only list files that would be deleted (no deletion)"
if ($mode -ne 'deletion' -and $mode -ne 'monitoring') {
    Write-Host "Invalid mode. Exiting."
    exit
}

# Prompt for retention period
$defaultMonths = 6
$retentionInput = Read-Host "Enter the retention period in months (default: 6)"
if ([string]::IsNullOrWhiteSpace($retentionInput)) {
    $retentionMonths = $defaultMonths
} elseif ($retentionInput -match '^[0-9]+$') {
    $retentionMonths = [int]$retentionInput
} else {
    Write-Host "Invalid input. Using default retention period: 6 months."
    $retentionMonths = $defaultMonths
}

# Prompt for Azure App Client ID
$ClientId = Read-Host "Enter your Azure App Client ID"

# Prompt for SharePoint domain
$domain = Read-Host "Enter your SharePoint domain (before .sharepoint.com)"

# Prompt for client site
$site = Read-Host "Enter your client site (after /)"

# Build the Site URL
$SiteURL = "https://$domain.sharepoint.com/sites/$site"

$ListName = "Preservation Hold Library"
$ReportPath = "C:\\Reports\\PHL_Deletion_Report.csv"

# Ensure the Reports folder exists
if (!(Test-Path -Path "C:\\Reports")) {
    New-Item -ItemType Directory -Path "C:\\Reports"
}

# Authenticate using client ID interactively
Connect-PnPOnline -Url $SiteURL -Interactive -ClientId $ClientId

# Initialize the CSV report for deleted/monitored items
if ($mode -eq 'deletion') {
    Write-Host "Initializing CSV report for deleted items..."
} else {
    Write-Host "Initializing CSV report for monitoring (items that would be deleted)..."
}
@() | Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8

# Define the date threshold
$thresholdDate = (Get-Date).AddMonths(-$retentionMonths)

# Retrieve items in batches
$batchSize = 250
Write-Host "Starting to retrieve items from the Preservation Hold Library..."

$skipTo = 0
do {
    Write-Host "Fetching batch starting from item $skipTo..."
    $items = Get-PnPListItem -List $ListName -PageSize $batchSize -Fields "FileLeafRef", "Created", "Modified", "FileRef" | Select-Object Id, FieldValues
    foreach ($item in $items) {
        $createdDate = $item.FieldValues["Created"]
        $modifiedDate = $item.FieldValues["Modified"]
        if ($createdDate -lt $thresholdDate -or $modifiedDate -lt $thresholdDate) {
            $logItem = @{
                "File Name" = $item.FieldValues["FileLeafRef"]
                "Created"   = $createdDate
                "Modified"  = $modifiedDate
                "Path"      = $item.FieldValues["FileRef"]
            }
            $logItem | Export-Csv -Path $ReportPath -Append -NoTypeInformation -Encoding UTF8
            if ($mode -eq 'deletion') {
                Write-Host "Deleting item: $($item.FieldValues['FileLeafRef']), Created: $createdDate, Modified: $modifiedDate"
                Remove-PnPListItem -List $ListName -Identity $item.Id -Force
            } else {
                Write-Host "[MONITOR] Would delete: $($item.FieldValues['FileLeafRef']), Created: $createdDate, Modified: $modifiedDate"
            }
        }
    }
    $skipTo += $batchSize
} while ($items.Count -eq $batchSize)

if ($mode -eq 'deletion') {
    Write-Host "Cleanup complete. Deleted files older than $retentionMonths months."
    Write-Host "Deleted items report saved at: $ReportPath"
} else {
    Write-Host "Monitoring complete. The following files would be deleted if run in deletion mode."
    Write-Host "Report saved at: $ReportPath"
}
