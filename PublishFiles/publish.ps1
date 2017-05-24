<#

This script publishes all the files inside of document libraries that you specify.

.EXAMPLE
# Publish files in one document library (skip checked-out files)
PS C:\> $creds = Get-Credential
PS C:\> .\publish2.ps1 -TargetWebUrl "https://intranet.mydomain.com/sites/targetSite" -Credentials $creds -listNames PublishingImages

.EXAMPLE
# Publish files in multiple document libraries (skip checked-out files)
PS C:\> $creds = Get-Credential
PS C:\> .\publish2.ps1 -TargetWebUrl "https://intranet.mydomain.com/sites/targetSite" -Credentials $creds -listNames PublishingImages,_catalogs/masterpage,'Style Library'

.EXAMPLE
# Publish files, including overwriting files which are currently checked out
PS C:\> $creds = Get-Credential
PS C:\> .\publish2.ps1 -TargetWebUrl "https://intranet.mydomain.com/sites/targetSite" -Credentials $creds -listNames PublishingImages -checkIn

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
  [Parameter(Mandatory = $true, HelpMessage ="Enter the lists you want to target for publishing separated by commas, e.g. PublishingImages, _catalogs/masterpage, 'Style Library'")]
    [String[]]
    $listNames,
  [Parameter(Mandatory = $false, HelpMessage="Optional administration credentials")] [PSCredential]$Credentials,
  [switch]$checkIn = $false
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

Write-Host ""
Write-Host -ForegroundColor Cyan "		SharePoint site collection URL: " -nonewline; Write-Host -ForegroundColor White $targetWebUrl
Write-Host -ForegroundColor Cyan "		Lists: " 
    foreach ( $listName in $listNames ){
      Write-Host "		     $listName"
    }
if ( $checkIn -eq $true){
    Write-Host
    Write-Host -ForegroundColor Cyan "		Switch -checkin: TRUE"
    Write-Host -ForegroundColor Red "		This will overwrite and check in any files which are currently checked out."
} else {
    Write-Host
    Write-Host -ForegroundColor Cyan "		Switch -checkin: FALSE"
}
Write-Host ""

$prompt = 'Please confirm that you want to continue with these settings:'
	
$yes = New-Object System.Management.Automation.Host.ChoiceDescription '&Yes','Continues deployment'
$no = New-Object System.Management.Automation.Host.ChoiceDescription '&No','Aborts the operation'

$options = [System.Management.Automation.Host.ChoiceDescription[]] ($no, $yes)
$choice = $host.ui.PromptForChoice("Environment configuration",$prompt,$options,1)

if($choice){


    Write-Host -ForegroundColor White "--------------------------------------------------------"
    Write-Host -ForegroundColor White "|               Provisioning Site Structure            |"
    Write-Host -ForegroundColor White "--------------------------------------------------------"

    Write-Host -ForegroundColor Yellow "Target Site URL: $($targetWebUrl)"
    Write-Host -ForegroundColor Yellow "Lists: " 
    foreach ( $listName in $listNames ){
      Write-Host "  $listName"
    }
    Write-Host -ForegroundColor Yellow "Please wait..."

    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client")
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client.Runtime")

    Write-Host -ForegroundCOlor Green "Connecting to SharePoint"
    Connect-PnPOnline $targetWebUrl -Credentials $Credentials 

    foreach( $listName in $listNames ){

        # connect to SPO and set context to the list
        Write-Host
        Write-Host -ForegroundColor Green "Connecting to client context"
        $ctx = Get-PnPContext
        $list = Get-PnPList -Identity $listName 
        $items = Get-PnPListItem -List $list 
        $ctx.ExecuteQuery()
        Write-Host
        Write-Host "Connected to list: " $list.Title -ForegroundColor Green
        Write-Host

        foreach( $item in $items){
          
          $filePath = "$($item["FileDirRef"])/$($item["FileLeafRef"])" 

          Write-Host "-----------------------------------------------"
          Write-Host "File being worked on: " $filePath


          # Check if file is checked out by checking if the "CheckedOut By" column does not equal empty
          if ($item["CheckoutUser"] -ne $null){
                if ($checkIn -eq $true){
                    # Item is checked out, Check in and publish process is applied
                    # Check in and publish EVERYTHING, for ALL users

                    Write-Host "File: " $item["FileLeafRef"] "is checked out. Checking in and publishing now..." -ForegroundColor Cyan
                    Set-PnPFileCheckedIn -Url $filePath -Comment "Automatically checked in by provisioning"
                    Write-Host "- File Checked in and Published successfully" -ForegroundColor Green
                } else {
                    Write-Host "File: " $item["FileLeafRef"] "is checked out. Skipping this file." -ForegroundColor Yellow
                }
          } else {
              #Item is not checked out
              if ($item["_Level"] -eq 2){
                    # Item  is in pending mode
                    # Write-Host "Level: " $item["_Level"] # 1 = published, 2 = draft mode, 255 = checked out
                    Write-Host "This file is in draft mode. Checking out..."
                    Set-PnPFileCheckedOut -Url $filePath
                    Write-Host "Checking in and publishing now..."
                    Set-PnPFileCheckedIn -Url $filePath -Comment "Automatically checked in by provisioning"                  
                    Write-Host "- File Checked in and Published successfully" -ForegroundColor Green
              } else {
                    #Item does not need to be pubished
                    Write-Host "This file is already published." -ForegroundColor Green 

              }

          }
          
        }
    }

    

} else {
    Write-Host " "
    Write-Host "Script cancelled by user" -foregroundcolor red
    Write-Host " "
}
