#----------------------------------------------------------------------------- 
# Filename : spps.other.psm1 
#----------------------------------------------------------------------------- 
# Author : Ryan Yates
#----------------------------------------------------------------------------- 
# New additional functions
#

function New-HighDetailedUserView
{
get-list -ListTitle "User Information List"

$ViewName = "HighDetails"
  

   $viewQuery = '<OrderBy><FieldRef Name="Title" /></OrderBy><Where><Eq><FieldRef Name="IsActive" /><Value Type="Boolean">1</Value></Eq></Where>'
   $viewFields = New-Object System.Collections.Specialized.StringCollection
   [Void]$viewFields.Add("ID")
   [Void]$viewFields.Add("UserSelection")
   [Void]$viewFields.Add("LinkTitle")
   [Void]$viewFields.Add("PictureDisp")
   [Void]$viewFields.Add("Notes")
   [Void]$viewFields.Add("JobTitle")
   [Void]$viewFields.Add("Department")
   [Void]$viewFields.Add("Name")
   [Void]$viewFields.Add("IsSiteAdmin")
   [Void]$viewFields.Add("EMail")
   

    $ViewInfo = New-Object Microsoft.SharePoint.Client.ViewCreationInformation
    $ViewInfo.Query = $viewQuery
    $ViewInfo.RowLimit = 50
    $ViewInfo.ViewFields = $viewfields
    $ViewInfo.Title = $ViewName

    $ctReturn =$list.Views.Add($ViewInfo)
    $list.Update()
    $spps.Load($ctReturn)
    $spps.ExecuteQuery()


    Write-host "New HighDetails View Created"
} 

function Get-web
{
$Global:web = $spps.Web
$spps.Load($web)
$spps.ExecuteQuery()
}

function New-SiteAdminView
{
get-list -ListTitle "User Information List"

$ViewName = "SiteAdmins"
  

   $viewQuery = '<OrderBy><FieldRef Name="Title" /></OrderBy><Where><Eq><FieldRef Name="IsSiteAdmin" /><Value Type="Boolean">1</Value></Eq></Where>'
   $viewFields = New-Object System.Collections.Specialized.StringCollection
   [Void]$viewFields.Add("ID")
   [Void]$viewFields.Add("UserSelection")
   [Void]$viewFields.Add("LinkTitle")
   [Void]$viewFields.Add("PictureDisp")
   [Void]$viewFields.Add("Notes")
   [Void]$viewFields.Add("JobTitle")
   [Void]$viewFields.Add("Department")
   [Void]$viewFields.Add("Name")
   [Void]$viewFields.Add("IsSiteAdmin")
   [Void]$viewFields.Add("EMail")
   

    $ViewInfo = New-Object Microsoft.SharePoint.Client.ViewCreationInformation
    $ViewInfo.Query = $viewQuery
    $ViewInfo.RowLimit = 50
    $ViewInfo.ViewFields = $viewfields
    $ViewInfo.Title = $ViewName

    $ctReturn =$list.Views.Add($ViewInfo)
    $list.Update()
    $spps.Load($ctReturn)
    $spps.ExecuteQuery()


    Write-host "New $viewname View Created"
} 