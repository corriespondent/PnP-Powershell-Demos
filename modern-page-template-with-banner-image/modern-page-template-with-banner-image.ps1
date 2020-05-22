# Set variables
$adminSiteUrl = "" # https://yourtenant-admin.sharepoint.com
$site = "" # https://yourtenant.sharepoint.com/sites/yourSite (where to deploy the page template)
$imageAssetLibraryRootUrl = "" # https://yourtenant.sharepoint.com/sites/assetSite/ 
$imageAssetLibraryFolderUrl =  "" # https://yourtenant.sharepoint.com/sites/assetSite/assetLibrary/assetFolder 

# Set password
$Credentials = Get-Credential

# Create an organization-wide asset library for images
Connect-SPOService -Url $adminSiteUrl -Credential $Credentials
Add-SPOOrgAssetsLibrary -LibraryURL $imageAssetLibraryFolderUrl -OrgAssetType ImageDocumentLibrary

# Update banner.xml with the URL to your image asset folder
# Upload your banner image to the library
Connect-PnPOnline $imageAssetLibraryRootUrl -Credentials $Credentials
Apply-PnPProvisioningTemplate -Path .\banner.xml

# In your site, your page in SharePoint, using your desired layout and page banner image. Save as page template (optional). 

# Export with PnP (update page export location)
Connect-PnPOnline $site -Credentials $Credentials
Get-PnPProvisioningTemplate -Out "C:\your-location\export.xml" -IncludeAllClientSidePages -PersistBrandingFiles -Handlers PageContents

# Look for ClientSidePage section. Modify page-template.xml to match column structure.
# Update page-template.xml with the location to the org asset

# Apply provisioning template
Connect-PnPOnline $site -Credentials $Credentials
Apply-PnPProvisioningTemplate -Path .\page-template.xml


