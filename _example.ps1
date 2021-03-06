# This example supports SharePoint 2013 on-premise and SharePoint Online with 2013 look and feel.
# This script is tested on both root and sub site collections running a Team Site.

# include and setup SPPS
Import-Module "$PSScriptRoot\spps.psm1"

# online:
Initialize-SPPS -siteURL "https://jeffreypaarhuis.sharepoint.com/sites/example/" -online $true -username "example_admin@jeffreypaarhuis.com" -password "Pass1234" 
# on-premise:
#Initialize-SPPS -siteURL "http://example/" -online $false 

$exampledir = "$PSScriptRoot\_example"

if (Request-YesOrNo -message "Enable publishing feature? (Select YES if not already enabled)")
{
	Enable-Feature -featureId "f6924d36-2fa8-4f0b-b16d-06b7250180fa" -force $false -featureDefinitionScope "Site"
	Enable-Feature -featureId "94c94ca6-b32f-4da9-a9e3-1f3d343d7ecb" -force $false -featureDefinitionScope "Web"
}

# Upload Sandboxed WSP to the site
Add-Solution -path "$exampledir\Solutions\AESBTwitterWebpart.wsp"

# Activate the WSP
Install-Solution -solutionName "AESBTwitterWebpart.wsp"

# Create a subsite
Add-Subsite -title "Subsite" -webTemplate "STS#0" -description "Description..." -url "subsite" -language 1033 -useSamePermissionsAsParentSite $true

# Go to the subsite
Open-Subsite -relativeUrl "/subsite" 

# Enable the publishing feature
Enable-Feature -featureId "94c94ca6-b32f-4da9-a9e3-1f3d343d7ecb" -force $false -featureDefinitionScope "Web"

# Create document library on the subsite
Add-DocumentLibrary -listTitle "Testdoclib"

# Copy testfiles to this document library
Copy-Folder "$exampledir\Subsite\Testdoclib" "Testdoclib" $false

# Go back to the root site
Open-Rootsite

# copy contents of local folders to SharePoint
# Style Library vars
$stylelibdir = "$exampledir\Style Library"
$styleliburl = "/Style Library"

Write-Host "Copying $stylelibdir to $styleliburl" -foregroundcolor white -backgroundcolor black
Copy-Folder $stylelibdir $styleliburl $true
Write-Host "Succesfully copied $stylelibdir to $styleliburl" -foregroundcolor green -backgroundcolor black

# Master Pages vars
$masterdir = "$exampledir\Master"
$masterurl = "/_catalogs/masterpage"
Write-Host "Copying $masterdir to $masterurl" -foregroundcolor white -backgroundcolor black
Copy-Folder $masterdir $masterurl $true
Write-Host "Succesfully copied $masterdir to $masterurl" -foregroundcolor green -backgroundcolor black


# Pages vars
$pagesdir = "$exampledir\Pages"
$pagesurl = "/Pages"
Write-Host "Copying $pagesdir to $pagesurl" -foregroundcolor white -backgroundcolor black
Copy-Folder $pagesdir $pagesurl $true
Write-Host "Succesfully copied $pagesdir to $pagesurl" -foregroundcolor green -backgroundcolor black


# Set master page
$masterFile = "seattle_custom.master"
Write-Host "Configuring master page '$masterFile'" -foregroundcolor white -backgroundcolor black
Set-CustomMasterPage $masterFile
Write-Host "Succesfully configured master page '$masterFile'" -foregroundcolor green -backgroundcolor black

# Create news list
$newsListName = "News"
$newsItemsCSV = "$exampledir\News\items.csv"

Write-Host "Creating list '$newsListName'" -foregroundcolor white -backgroundcolor black

Add-List -listTitle $newsListName
[string[][]]$fields =   ("NewsSum","Note",""),
                        ("NewsText","Note","")
Add-FieldsToList $fields $newsListName
    
Add-ListItems $newsItemsCSV $newsListName

Write-Host "Succesfully created list '$newsListName'" -foregroundcolor green -backgroundcolor black

# Add news web part to the page

Write-Host "Adding news web part to the page" -foregroundcolor white -backgroundcolor black

$webpartXml =  '<?xml version="1.0" encoding="utf-8"?>
                <WebPart xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://schemas.microsoft.com/WebPart/v2">
                  <Title>Content Editor Web Part</Title>
                  <FrameType>BorderOnly</FrameType>
                  <Description></Description>
                  <IsIncluded>true</IsIncluded>
                  <ZoneID>Header</ZoneID>
                  <PartOrder>0</PartOrder>
                  <FrameState>Normal</FrameState>
                  <Height />
                  <Width>800px</Width>
                  <AllowRemove>true</AllowRemove>
                  <AllowZoneChange>true</AllowZoneChange>
                  <AllowMinimize>true</AllowMinimize>
                  <AllowConnect>true</AllowConnect>
                  <AllowEdit>true</AllowEdit>
                  <AllowHide>true</AllowHide>
                  <IsVisible>true</IsVisible>
                  <DetailLink />
                  <HelpLink />
                  <HelpMode>Modeless</HelpMode>
                  <Dir>Default</Dir>
                  <PartImageSmall />
                  <MissingAssembly>Cannot import this Web Part.</MissingAssembly>
                  <PartImageLarge>/_layouts/images/mscontl.gif</PartImageLarge>
                  <IsIncludedFilter />
                  <Assembly>Microsoft.SharePoint, Version=15.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c</Assembly>
                  <TypeName>Microsoft.SharePoint.WebPartPages.ContentEditorWebPart</TypeName>
                  <ContentLink xmlns="http://schemas.microsoft.com/WebPart/v2/ContentEditor">~SiteCollection/Style Library/Example/Html/news.html</ContentLink>
                  <Content xmlns="http://schemas.microsoft.com/WebPart/v2/ContentEditor" />
                  <PartStorage xmlns="http://schemas.microsoft.com/WebPart/v2/ContentEditor" />
                </WebPart>'

Add-Webpart "/Pages/default.aspx" "Header" 0 $webpartXml

Write-Host "News web part succesfully added to the page" -foregroundcolor green -backgroundcolor black



# Create SharePoint Groups
Write-Host "Create SharePoint Groups" -foregroundcolor white -backgroundcolor black

Add-Group -name "Example Group"

Write-Host "Succesfully created SharePoint Groups" -foregroundcolor green -backgroundcolor black

#roleTypes are Guest, Reader, Contributor, WebDesigner, Administrator, Editor
Write-Host "Create SharePoint Permissions" -foregroundcolor white -backgroundcolor black

# Web
Set-WebPermissions -groupname "Example Group" -roleType "Reader"

# Pages lib
Set-ListPermissions -groupname "Example Group" -listname "Pages" -roleType "Reader"

# Nieuws list
Set-ListPermissions -groupname "Example Group" -listname "News" -roleType "Reader"

Write-Host "Succesfully created SharePoint Permissions" -foregroundcolor green -backgroundcolor black




### SCRIPT END / READ KEY ###
read-host "Press any key to continue ..."