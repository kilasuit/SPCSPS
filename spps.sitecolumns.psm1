<#
        .SYNOPSIS
		Created by: Ryan Yates
		Created: 22/01/2015
		

	.DESCRIPTION
		Site Column Functions
#>
#----------------------------------------------------------------------------- 
# Filename : spps.sitecolumns.ps1 
#----------------------------------------------------------------------------- 
#----------------------------------------------------------------------------- 
# SPPS Site Column Functions
#----------------------------------------------------------------------------- 


Function Get-SiteColumns
{
$Global:fields = $web.Fields
$Spps.Load($fields)
$Spps.ExecuteQuery()
}


function Add-LookupSiteColumn
{
	[CmdletBinding()]
	param
	(
			
		[Parameter(Mandatory=$true, Position=2)]
		[string] $fieldName,

        [Parameter(Mandatory=$true, Position=2)]
		[string] $LookupListID,

        [Parameter(Mandatory=$true, Position=2)]
		[string] $LookupWebID,

        [Parameter(Mandatory=$true, Position=2)]
		[string] $LookupField,

        [Parameter(Mandatory=$false, Position=2)]
		[string] $LookupaddtionalField,

        [Parameter(Mandatory=$True, Position=7)]
		[string] $SiteColumnGroup
	)
	

    $newSiteColumn = "<Field DisplayName='$fieldname' Type='Lookup' Required='TRUE' List='$lookuplistid' WebId='$LookupWebid' Name='LookupField' ShowField='$LookupField' Group='$SiteColumnGroup'  />"
    Add-SiteColumn $fieldName $NewSiteColumn  
}

function Add-TextSiteColumn
{
	[CmdletBinding()]
	param
	(
			
		[Parameter(Mandatory=$true, Position=2)]
		[string] $fieldName,
        
        [Parameter(Mandatory=$True, Position=7)]
		[string] $SiteColumnGroup
	)
	
    $newField = "<Field Type='Text' DisplayName='$fieldName' Name='$fieldName' required='FALSE' Group='$SiteColumnGroup'/>"
    Add-SiteColumn  $fieldName $newField  
}
#function Add-CalculatedSiteColumn
{
	[CmdletBinding()]
	param
	(
				
		[Parameter(Mandatory=$true, Position=1)]
		[string] $fieldName,
		
		[Parameter(Mandatory=$true, Position=2)]
		[string] $value
	)
	
    $refField = $value.Split(";")[1]
    $formula = $value.Split(";")[0]
    
    $internalName = Find-FieldName $listTitle $refField
    
    $newField = '<Field Type="Calculated" DisplayName="$fieldName" ResultType="DateTime" ReadOnly="TRUE" Name="$fieldName"><Formula>$formula</Formula><FieldRefs><FieldRef Name="$internalName" /></FieldRefs></Field>'
    
    Add-SiteColumn $listTitle $fieldName $newField          
}


function Add-UserSiteColumn
{
	[CmdletBinding()]
	param
	(
				
		[Parameter(Mandatory=$true, Position=2)]
		[string] $fieldName,

        [Parameter(Mandatory=$true, Position=3)]
		[int] $SelectionMode,

        [Parameter(Mandatory=$true, Position=3)]
		[string] $Multi,
        
        [Parameter(Mandatory=$True, Position=7)]
		[string] $SiteColumnGroup
	)
	
    $newField = "<Field Type='UserMulti' DisplayName='$fieldName' Name='$fieldName' StaticName='$fieldName' UserSelectionScope='0' UserSelectionMode='$selectionMode' Sortable='FALSE' Required='FALSE' Mult='$multi' Group='$SiteColumnGroup'/>"
    Add-SiteColumn  $fieldName $newField  
}


function Add-NoteSiteColumn
{
	[CmdletBinding()]
	param
	(
			
		[Parameter(Mandatory=$true, Position=2)]
		[string] $fieldName,

        [Parameter(Mandatory=$true, Position=3)]
		[string] $NumberofLines,

        [Parameter(Mandatory=$true, Position=3)]
		[string] $RichText,

        [Parameter(Mandatory=$True, Position=7)]
		[string] $SiteColumnGroup
	)
	
    $newField = "<Field Type='Note' DisplayName='$fieldName' Name='$fieldName' required='FALSE' NumLines='$numberoflines' RichText='$richtext' Sortable='FALSE' Group='$SiteColumnGroup' />"
    Add-SiteColumn $fieldName $newField  
}

function Add-DateTimeSiteColumn
{
	[CmdletBinding()]
	param
	(
				
		[Parameter(Mandatory=$true, Position=2)]
		[string] $fieldName,

        [Parameter(Mandatory=$True, Position=7)]
		[string] $SiteColumnGroup
	)
	
    $newField = "<Field Type='DateTime' DisplayName='$fieldName' Name='$fieldName' required='FALSE' Group='$SiteColumnGroup' />"
    Add-SiteColumn $fieldName $newField  
}

function Add-CurrencySiteColumn
{
	[CmdletBinding()]
	param
	(
			
		[Parameter(Mandatory=$true, Position=2)]
		[string] $fieldName,

        [Parameter(Mandatory=$True, Position=7)]
		[string] $SiteColumnGroup
	)
	
    $newField = "<Field Type='Currency' DisplayName='$fieldName' Name='$fieldName' required='FALSE' Group='$SiteColumnGroup' />"
    Add-SiteColumn $fieldName $newField  
}

function Add-NumberSiteColumn
{
	[CmdletBinding()]
	param
	(
			
		[Parameter(Mandatory=$true, Position=2)]
		[string] $fieldName,

        [Parameter(Mandatory=$True, Position=7)]
		[string] $SiteColumnGroup
	)

    $newField = "<Field Type='Number' DisplayName='$fieldName' Name='$fieldName' required='FALSE' Group='$SiteColumnGroup' />"
    Add-SiteColumn $fieldName $newField  
}

function Add-ChoiceSiteColumn
{
	[CmdletBinding()]
	param
	(
				
		[Parameter(Mandatory=$true, Position=2)]
		[string] $fieldName,
		
		[Parameter(Mandatory=$true, Position=3)]
		[string] $values,

        [Parameter(Mandatory=$True, Position=7)]
		[string] $SiteColumnGroup
	)
	
    $options = ""
    $valArray = $values.Split(";")
    foreach ($s in $valArray)
    {
        $options = $options + "<CHOICE>$s</CHOICE>"
    }
    
    $newField = "<Field Type='Choice' DisplayName='$fieldName' Name='$fieldName'  required='FALSE' Group='$SiteColumnGroup'><CHOICES>$options</CHOICES> </Field>"
    
    Add-SiteColumn $fieldName $newField  
}
    
#function Add-ChoicesToSiteColumn
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
		[string[]] $choices, 
		
		[Parameter(Mandatory=$true, Position=2)]
		[string] $fieldName, 
		
		[Parameter(Mandatory=$true, Position=3)]
		[string] $listTitle
	)

	Write-Host "Adding choices to field $fieldName" -foregroundcolor black -backgroundcolor yellow
    $web = $Spps.Web
    $list = $web.Lists.GetByTitle($listTitle)
    $fields = $list.Fields
    $Spps.Load($fields)
    $Spps.ExecuteQuery()

    if (Test-Field $list $fields $fieldName)
    {
        $field = $fields.GetByInternalNameOrTitle($fieldName)
        $Spps.Load($field)
        $Spps.ExecuteQuery()
        
        # calling nongeneric method public T CastTo<T>(ClientObject object)
        $method = [Microsoft.Sharepoint.Client.ClientContext].GetMethod("CastTo")
        $castToMethod = $method.MakeGenericMethod([Microsoft.Sharepoint.Client.FieldChoice])
        $fieldChoice = $castToMethod.Invoke($Spps, $field)
        
        $currentChoices = $fieldChoice.Choices
        
        # add new choices to the existing choices
        $allChoices = $currentChoices + $choices
        
        # write choices back to the field
        $fieldChoice.Choices = $allChoices
        $fieldChoice.Update()
        
        $list.Update()
        $Spps.ExecuteQuery()
		Write-Host "Choices added to field $fieldName" -foregroundcolor black -backgroundcolor yellow
    }
    else
    {
		Write-Host "Field $fieldName doesn't exists in list $listTitle" -foregroundcolor black -backgroundcolor red
    }
}


function Add-SiteColumn
{
	[CmdletBinding()]
	param
	(
				
		[Parameter(Mandatory=$true, Position=1)]
		[string] $fieldName, 
		
		[Parameter(Mandatory=$true, Position=2)]
		[string] $fieldXML
               
	)

    $fields = $web.fields
    $Spps.Load($fields)
    $Spps.ExecuteQuery()

    if (!(Test-SiteColumn $fieldName))
    {
        $SiteColumn = $Fields.AddFieldAsXml($fieldXML, $true, [Microsoft.SharePoint.Client.AddFieldOptions]::AddToNoContentType);
        
        $Spps.ExecuteQuery()
        
		Write-Host "Site Column $fieldName added to Site" -foregroundcolor black -backgroundcolor yellow
    }
    else
    {
		Write-Host "Site Column $fieldName already exists " -foregroundcolor black -backgroundcolor yellow
    }
}

function Test-SiteColumn
{
	[CmdletBinding()]
	param
	(
				
		[Parameter(Mandatory=$true, Position=1)]
		[string] $fieldName
	)

	$web = $Spps.Web
    $fields = $web.fields
    $Spps.Load($fields)
    $Spps.ExecuteQuery()


    $fieldNames = $fields| select -ExpandProperty Title
    $exists = ($fieldNames -contains $fieldName)
    return $exists
}

function Remove-SiteColumn
{
	[CmdletBinding()]
	param
	(
				
		[Parameter(Mandatory=$true, Position=1)]
		[string] $fieldName
				       
	)

    $web = $Spps.Web
    $fields = $web.fields
    $Spps.Load($fields)
    $Spps.ExecuteQuery()

    if (Test-SiteColumn $fieldName)
    {
        $SiteColumn = $Fields.GetByTitle("$fieldname");
        $sitecolumn.DeleteObject();
        $Spps.ExecuteQuery()
        
		Write-Host "Site Column $fieldName Deleted" -foregroundcolor black -backgroundcolor yellow
    }
    else
    {
		Write-Host "Site Column $fieldName Didnt exists " -foregroundcolor black -backgroundcolor yellow
    }
}

function Remove-Subsite
{
[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
	    [string]$Subsiteurl
)
if($Subsiteurl)
{
    Try
        {
        $ctx = New-Object Microsoft.SharePoint.Client.ClientContext($subsiteurl)
        $Removalweb = $ctx.Web  
 
        $ctx.Load($removalweb)  
        $ctx.ExecuteQuery() 
 
        $removalweb.DeleteObject() 
        $ctx.ExecuteQuery()
        Write-Host "Subsite $SubsiteUrl succesfully deleted" -foregroundcolor black -backgroundcolor green
        }
    catch
    {
    Write-Host "Subsite $SubsiteUrl Didnt Exist Or is Not a Subsite" -foregroundcolor Yellow -backgroundcolor Red
    }
}
}


function Add-SiteColumnToContentType
{
[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
		[string] $SiteColumnName,
		
		[Parameter(Mandatory=$true, Position=3)]
		[string] $ContentTypeToAddTo

	)

Load-SiteColumns
Load-ContentTypes
$field = $fields.GetByInternalNameOrTitle($SiteColumnName)
$SPPS.Load($field)
$ctName = $CTnIDs.GetEnumerator() | Where-Object {$_.Name -eq $ContentTypeToAddTo}
$CTID = $ctname.id.tostring()
$CT = $web.ContentTypes.GetById($CtID)
$Spps.Load($ct)
$fieldReferenceLink = New-Object Microsoft.SharePoint.Client.FieldLinkCreationInformation
$fieldReferenceLink.Field = $field;
[void]$CT.FieldLinks.Add($fieldReferenceLink);
$CT.Update($true);
try
{
$Spps.ExecuteQuery()
Write-host "Site Column "$SiteColumnName" Added to "$ContentTypeToAddTo"" -ForegroundColor Green
}
catch
{
Write-host "Site Column "$SiteColumnName" Could not be Added to "$ContentTypeToAddTo"" -ForegroundColor Red
Write-Host "Check that Site Column is Correct and Content Type to Add to Is Correct" -ForegroundColor DarkYellow
}

}