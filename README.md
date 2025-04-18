# SharePoint Preservation Hold Library Deletion Script

## Overview
This PowerShell script helps you clean up files from the SharePoint "Preservation Hold Library" that are older than a specified retention period.

> **Warning:**
> This script will permanently delete files from your SharePoint Preservation Hold Library if run in deletion mode. Use at your own risk. The author takes NO responsibility for any data loss or consequences!

## Prerequisites
- Windows PowerShell (pwsh)
- [PnP PowerShell Module](https://pnp.github.io/powershell/)
    - You must install it before running this script. See [PnP PowerShell Installation Guide](https://pnp.github.io/powershell/index.html)
    - Install via: `Install-Module -Name PnP.PowerShell -Scope CurrentUser`
- Azure App Registration with appropriate permissions to access SharePoint

## Important Limitations
- **This script will NOT be able to delete files if any of the following are active on the target SharePoint site:**
    - Data Loss Prevention (DLP) Policies
    - Retention Policies (including Microsoft Purview retention labels or policies)
    - eDiscovery cases
    - Locked site status (read-only, no access, or other locks)
- **All such restrictions must be fully removed or disabled before running this script, otherwise deletions will fail.**
    - For more information on site lock status, see: [Manage locked sites in SharePoint](https://learn.microsoft.com/en-us/sharepoint/manage-lock-status)
    - For more information on retention policies, see: [Overview of retention policies](https://learn.microsoft.com/en-us/microsoft-365/compliance/retention-policies)

## How to Run
1. **Open PowerShell** and navigate to the folder containing `deletion.ps1`.

2. **Run the script:**
   ```powershell
   pwsh -File .\deletion.ps1
   ```

3. **Follow the prompts:**
   - Type `YES` to accept the warning and continue.
   - **Choose mode:**
     - Enter `deletion` to actually delete files.
     - Enter `monitoring` to only list files that would be deleted (no files will be deleted).
   - Enter the retention period in months (default is 6).
     - This is the age threshold: files older than this number of months will be selected for deletion (or listed in monitoring mode).
   - Enter your Azure App Client ID.
   - Enter your SharePoint domain (the part before `.sharepoint.com`). I.e. if your SharePoint URL is https://contoso.sharepoint.com only enter contoso
   - Enter your client site (the part after `/`).

4. **The script will:**
   - Connect to your SharePoint site using the provided credentials.
   - Identify items from the Preservation Hold Library older than the specified retention period.
   - In **deletion mode**: delete those items and log them to `C:\Reports\PHL_Deletion_Report.csv`.
   - In **monitoring mode**: only log the items that would be deleted to `C:\Reports\PHL_Deletion_Report.csv` (no deletions performed).

## Notes
- You must have sufficient permissions on SharePoint and the Azure App must be properly configured.
- The script will create a `C:\Reports` folder if it does not exist.
- Always review the script and test in a non-production environment before using on live data.

## Troubleshooting
- If you encounter authentication errors, double-check your Azure App permissions and Client ID.
- Ensure the PnP PowerShell module is installed and updated. See the [PnP PowerShell Installation Guide](https://pnp.github.io/powershell/index.html).
- For more information, see the [PnP PowerShell Documentation](https://pnp.github.io/powershell/).

---

**Use with caution!**
