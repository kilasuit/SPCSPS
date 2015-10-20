#----------------------------------------------------------------------------- 
# Filename : spps.lists.ps1 
#----------------------------------------------------------------------------- 
# Original Author : Ryan Yates @ryanyates1990
#----------------------------------------------------------------------------- 
# A collection of functions for attaining Site Columns

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
	

    $newSiteColumn = "<Field DisplayName='$fieldname' Type='Lookup' Required='TRUE' List='$lookuplistid' WebId='$LookupWebid' Name='$fieldname' ShowField='$LookupField' Group='$SiteColumnGroup'  />"
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

Get-SiteColumns
Get-ContentTypes
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
Write-Verbose "Site Column "$SiteColumnName" Added to "$ContentTypeToAddTo""
}
catch
{
Write-Verbose "Site Column "$SiteColumnName" Could not be Added to "$ContentTypeToAddTo"" 
Write-Verbose "Check that Site Column is Correct and Content Type to Add to Is Correct" 
}

}

function Add-BulkSiteColumns
{
<#
.Synopsis
   This function will Check in a file 
    
.DESCRIPTION
   This can be used to check in a file in a library that requires files to be checked in before beinf published
.EXAMPLE
   Clear-ListContent -ListTitle Tasks
   Will get the object for the SharePoint List called Tasks and then delete this from the Site 
.NOTES
   Requires there to have a connection to a SharePoint Site using the Initialize-SPPS function 
#>
[CmdletBinding()]
	param
	(
	    [Parameter(Mandatory=$true, Position=1)]
	    [string]$ListTitle,
		
        [Parameter(Mandatory=$false,HelpMessage="Csv File Location", Position=2)]
	    $CSVFile 
    )
$csv = import-csv $CSVFile
foreach($row in $csv)
{
if($row.type -eq "Choice")
{
Add-ChoiceSiteColumn -listTitle $list.Title -fieldName $Row.Name -values $row.Choicevalues -ChoiceType $row.ChoiceType
}
if($row.type -eq "Text")
{
Add-textFieldtoList -listTitle $list.Title -fieldName $row.Name -MaxNumberofChars $row.TextMaxChars
}
if($row.type -eq "Note")
{
Add-NoteFieldtoList -listTitle $list.Title -fieldName $row.Name -NumberOfLines $row.NoteLines -TextType $row.NoteType
}
if($row.type -eq "User")
{
Add-UserFieldtoList -listTitle $list.title -fieldName $row.Name -Usertype $row.UserType -UserSelectionScope $row.UserSelectionScope -UserSelectionMode $row.UserSelectionMode
}
if($row.type -eq "Calculated")
{
Add-CalculatedFieldtoList -listTitle $list.Title -fieldName $row.name -value $row.CalcValue
}
if($row.type -eq "DateTime")
{
Add-DateTimeFieldtoList -listTitle $list.title -fieldName $row.Name
}
if ($row.type -eq "Currency")
{
Add-CurrencyFieldtoList -listTitle $list.Title -fieldName $row.name 
}
if ($row.type -eq "Number")
{
Add-NumberFieldtoList -listTitle $list.Title -fieldName $row.name
}
if ($row.type -eq "Boolean")
{
Add-BooleanFieldtoList -listTitle $list.Title -fieldName $row.name 
}
}
}