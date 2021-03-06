#----------------------------------------------------------------------------- 
# Filename : spps.ps1 
#----------------------------------------------------------------------------- 
# Original Author : Jeffrey Paarhuis @Jpaarhuis
#
# Amended by Ryan Yates @ryanyates1990
#----------------------------------------------------------------------------- 
# Includes links to CSOM dlls from Microsoft Download Centre 
#
# 
#


# global vars
$spps
$rootSiteUrl

#the $PSScriptRoot variable changes over time so let's stick the value to our own variable
$scriptdir = $PSScriptRoot
<# This isnt needed with the NestedModule Array in the psd1 file
# include other modules
Import-Module "$scriptdir\spps.global.psm1"
Import-Module "$scriptdir\spps.lists.psm1"
Import-Module "$scriptdir\spps.webparts.psm1"
Import-Module "$scriptdir\spps.masterpages.psm1"
Import-Module "$scriptdir\spps.usersandgroups.psm1"
Import-Module "$scriptdir\spps.features.psm1"
Import-Module "$scriptdir\spps.subsites.psm1"
Import-Module "$scriptdir\spps.solutions.psm1"
Import-Module "$scriptdir\spps.SiteColumns.psm1"
Import-Module "$scriptdir\spps.ContentTypes.psm1"
Import-Module "$scriptdir\spps.other.psm1"
#>
Function Test-SPPS
{
[CmdletBinding()]
	param
	(
	    [Parameter(Mandatory=$true, Position=1)]
	    [ValidateSet("2010", "2013", "Online","All")]
        [string]$Version
    )

$clientOnline = Test-Path "$env:CommonProgramFiles\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.dll"
$client2010 = test-path "$env:CommonProgramFiles\Microsoft Shared\SharePoint Client\Microsoft.SharePoint.Client.Dll"
$client2013 = Test-Path "$env:CommonProgramFiles\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll"

$2010dlls = "http://www.microsoft.com/en-gb/download/details.aspx?id=21786"
$2013dlls = "http://www.microsoft.com/en-us/download/details.aspx?id=35585"
$onlinedlls = "http://www.microsoft.com/en-us/download/details.aspx?id=42038"


if ($version -eq '2010' -or 'All' -and $client2010 -eq $true)
    {
    Write-Verbose "Ready to Connect to SharePoint 2010" 
    }
    elseif ($version -eq '2010' -or 'All' -and $client2010 -eq $false)
    {
    Write-Verbose 'Opening Internet Explorer to the download link for SharePoint 2010 components' 
    start iexplore $2010dlls -WindowStyle Maximized
    }

if (($version -eq '2013' -or 'All') -and $client2013 -eq $true)
    {
    Write-Verbose "Ready to Connect to SharePoint 2013" 
    }
    elseif ($version -eq '2013' -or 'All' -and $client2013 -eq $false)
    {
    Write-Verbose 'Opening Internet Explorer to the download link for SharePoint 2013 components' 
    start iexplore $2013dlls -WindowStyle Maximized
    }

 if ($version -eq 'Online' -or 'All' -and $clientonline -eq $true)
    {
    Write-Verbose "Ready to Connect to SharePoint Online" 
    }
    elseif ($version -eq 'Online' -or 'All' -and $clientOnline -eq $false)
    {
    Write-Verbose 'Opening Internet Explorer to the download link for SharePoint Online components' 
    start iexplore $onlinedlls -WindowStyle Maximized
    }   
    
}


function Initialize-SPPS
{
	[CmdletBinding()]
	param
	(
	    [Parameter(Mandatory=$true, Position=1)]
	    [string]$siteURL,

        [Parameter(Mandatory=$false,Position=2)]
	    [System.Management.Automation.PSCredential]$UserCredential,
        
        [Parameter(Mandatory=$false,Position=3)]
	    [Bool]$IsOnline = $false,

        [Parameter(Mandatory=$false,Position=4)]
	    [Bool]$Is2010 = $false,

        [Parameter(Mandatory=$false,Position=5)]
	    [String]$OnlineUsername,

        [Parameter(Mandatory=$false,Position=6)]
	    [String]$OnlinePassword        

     )
                  
        $Online = $IsOnline
        $version = $Is2010
        
    Write-verbose "Loading the CSOM library dependant on the Version of SharePoint that you are working with"     
   if($Online -eq $true)   
    { 
       $onlineDlls = Get-ChildItem "$env:CommonProgramFiles\Microsoft Shared\Web Server Extensions\16\ISAPI\*.dll"
       foreach ($dll in $onlineDlls) 
        {
	    [void][Reflection.Assembly]::LoadFrom($dll.FullName)
    	    Write-Verbose "Succesfully loaded $($dll.name) from the CSOM library for SharePoint Online"
        }
    }
    elseif($version -eq $false)
    {
       $2013Dlls = Get-ChildItem "$env:CommonProgramFiles\Microsoft Shared\Web Server Extensions\15\ISAPI\*.dll"
       foreach ($dll in $2013Dlls) 
        {
	    [void][Reflection.Assembly]::LoadFrom($dll.FullName)
    	    Write-Verbose "Succesfully loaded $($dll.name) from the CSOM library for SharePoint 2013"
        }
    }
    elseif($version -eq $true)
    {
        $2010Dlls = Get-ChildItem "$env:CommonProgramFiles\Microsoft Shared\SharePoint Client\*.dll"
        foreach ($dll in $2010Dlls) 
            {
	        [void][Reflection.Assembly]::LoadFrom($dll.FullName)
    	        Write-Verbose "Succesfully loaded $($dll.name) from the CSOM library for SharePoint 2010"
            }
            Write-Warning "SharePoint 2010 has a much smaller implementation of CSOM than SharePoint 2013 or SharePoint Online - think about upgrading If you can!"
    }
    
    $Global:Spps = New-Object Microsoft.SharePoint.Client.ClientContext($siteURL)
	$Spps.RequestTimeOut = 1000 * 60 * 10;
    
    if($UserCredential -and ($online -eq $false))
    {
    $Spps.Credentials = $UserCredential
    $username = $UserCredential.UserName
    }
    elseif($Online -eq $true -and $UserCredential)
    {
    $SpoCreds = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($UserCredential.UserName,$UserCredential.Password)
    $spps.Credentials = $SpoCreds
    $username = $SpoCreds.UserName
    }
    elseif($online -eq $true -and (!$OnlineUsername -and !$OnlinePassword))
	{
     $username = Read-Host "Provide Username"
     $password = Read-Host "Provide Password" -AsSecureString
	 Write-Verbose "Setting SharePoint Online credentials"
     $Spps.AuthenticationMode = [Microsoft.SharePoint.Client.ClientAuthenticationMode]::Default
	 $credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($username,$Password)
	 $Spps.Credentials = $credentials
	 }
    Elseif($online -eq $true -and $OnlineUsername -and $OnlinePassword)
    {
    $Password = ConvertTo-SecureString $OnlinePassword -AsPlainText -Force
     Write-Verbose "Setting SharePoint Online credentials" 
     $Spps.AuthenticationMode = [Microsoft.SharePoint.Client.ClientAuthenticationMode]::Default
	 $credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($onlineusername,$Password)
	 $Spps.Credentials = $credentials
     $username = $OnlineUsername
    }
    else
    {    
    $username = "$env:USERDOMAIN\$env:USERNAME"
    }
       
	$global:web = $Spps.Web;
	$global:site = $Spps.Site;
	$Spps.Load($web);
	$Spps.Load($site);
	$Spps.ExecuteQuery()
	
	Set-Variable -Name "rootSiteUrl" -Value $siteURL -Scope Global
	
    Write-Verbose "Succesfully connected to $siteurl as $username"
    Write-Verbose 'Variable $Spps is now in use for the Client Context Use this for when you need to execute querys in form of $Spps.ExecuteQuery()' 
    Write-Verbose 'Variable $Site is now in use for the Site Context Use this for when you need to get data from the site in the form of $site.Url' 
    Write-Verbose 'Variable $web is now in use for the Web Context Use this for when you need to get data from the web objects in form of $web.title' 

}

