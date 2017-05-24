<#

This simple script adds a file into the publishing images folder of a SharePoint site.

.EXAMPLE
PS C:\> $creds = Get-Credential
PS C:\> .\simple.ps1 -TargetWebUrl "https://intranet.mydomain.com/sites/targetSite" -Credentials $creds
#>

#===================================================================================
#
# This is the main entry point for the deployment process
#
#===================================================================================

param(
	 [Parameter(Mandatory = $true, HelpMessage="Enter the URL of the target web, e.g. 'https://intranet.mydomain.com/sites/targetWeb'")]
    [String]
    $targetWebUrl,
  [Parameter(Mandatory = $false, HelpMessage="Optional administration credentials")] [PSCredential]$Credentials
)


#===================================================================================
# Func: Get-ScriptDirectory
# Desc: Get the script directory from variable
#===================================================================================
function Get-ScriptDirectory
{
  $Invocation = (Get-Variable MyInvocation -Scope 1).Value
  Split-Path $Invocation.MyCommand.Path
}

#===================================================================================
# Set current script location
#===================================================================================
$currentDir = Get-ScriptDirectory
Set-Location -Path $currentDir


#===================================================================================
# Confirm the environment
#===================================================================================

Write-Host -ForegroundColor Cyan "		SharePoint site collection URL: " -nonewline; Write-Host -ForegroundColor White $targetWebUrl
Write-Host ""

$prompt = 'Please confirm that you want to continue with these settings:'
	
$yes = New-Object System.Management.Automation.Host.ChoiceDescription '&Yes','Continues deployment'
$no = New-Object System.Management.Automation.Host.ChoiceDescription '&No','Aborts the operation'

$options = [System.Management.Automation.Host.ChoiceDescription[]] ($no, $yes)
$choice = $host.ui.PromptForChoice("Environment configuration",$prompt,$options,1)

if ($choice){


    Write-Host -ForegroundColor White "--------------------------------------------------------"
    Write-Host -ForegroundColor White "|               Provisioning Site Structure            |"
    Write-Host -ForegroundColor White "--------------------------------------------------------"

    Write-Host -ForegroundColor Yellow "Target Site URL: $($targetWebUrl)"
    Write-Host -ForegroundColor Yellow "Please wait..."

    try
    {
        Connect-PnPOnline $targetWebUrl -Credentials $Credentials
        Apply-PnPProvisioningTemplate -Path .\templates\simple.xml

        Write-Host -ForegroundColor Green "Site Structure Provisioning succeeded"
    }
    catch
    {
        Write-Host -ForegroundColor Red "Exception occurred!" 
        Write-Host -ForegroundColor Red "Exception Type: $($_.Exception.GetType().FullName)"
        Write-Host -ForegroundColor Red "Exception Message: $($_.Exception.Message)"
    }

} else {
    Write-Host " "
    Write-Host "Script cancelled by user" -foregroundcolor red
    Write-Host " "
}
