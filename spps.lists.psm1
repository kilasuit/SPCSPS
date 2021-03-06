#----------------------------------------------------------------------------- 
# Filename : spps.lists.ps1 
#----------------------------------------------------------------------------- 
# Original Author : Jeffrey Paarhuis @Jpaarhuis
# Updated by : Ryan Yates @ryanyates1990
#----------------------------------------------------------------------------- 
# Contains methods to manage lists, document libraries and list items.

###################
#    Retrieval 
###################

function Get-List {
<#
.Synopsis
   This function will get the object for the SharePoint List that you specify
.DESCRIPTION
   This is really in internally used Function for ensuring that there is a full Cycle to update any Variables created for
   lists as we are performing any CRUD functions with Lists and Librarys 
.EXAMPLE
   Get-List -ListTitle Tasks
    Will get the object for the SharePoint List called Tasks and stores this in a list variable 
.NOTES
   Requires there to have a connection to a SharePoint Site using the Initialize-SPPS function 
#>
[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
		[string] $ListTitle
	)

Get-Lists

    if($ListTitles.Title -contains $ListTitle)
        {
        $listid = ($listTitles| Where-Object {$_.Title -eq $listTitle} | Select-Object ID).ID.GUID
        $Global:list = $lists.GetByID($ListId)
        $spps.Load($list)
        $spps.ExecuteQuery()
        Write-Verbose "Variable List is now in use for the list $ListTitle"
        }
        else
            {
            Write-Verbose "List $listTitle Doesn't Exist"
            }
}

function Get-Lists {
<#
.Synopsis
   This function will get the object for all of the SharePoint Lists and Libraries in the Current Site
.DESCRIPTION
   This is really in internally used Function for ensuring that there is an update to any Variables 
   created that are created and used for lists as we are performing any CRUD functions with Lists and Librarys 
.EXAMPLE
   Get-Lists
    Will get the object for All the SharePoint Lists and Libraries in the current site and store this in a lists variable 
.NOTES
   Requires there to have a connection to a SharePoint Site using the Initialize-SPPS function 
#>
Get-Web
$Global:lists = $web.lists
$spps.Load($lists)
$spps.ExecuteQuery()
$Global:listtitles = $lists | select Title,ID
}
 
Function Get-ListView {
<#
.Synopsis
   Simple function to Get a specified view for a List
.DESCRIPTION
   Used to get a list view and then outputs this to a variable to be further referenced by other functions in further use
   Also loads and outputs the ViewFields so that the Listview variable will not throw a uninitialized error
.EXAMPLE
   Get-ListView -ListTitle Tasks -ListViewName MyTasks
.NOTES
   Requires there to have a connection to a SharePoint Site using the Initialize-SPPS function
   
#>
[CmdletBinding()]
	
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
		[string] $ListTitle,

        [Parameter(Mandatory=$true, Position=2)]
		[string] $ListViewName        
	)

       
    Get-listviews -ListTitle $ListTitle
        $ListViewID = ($ListViewIDs | Where-Object { $_.Title -eq $ListViewname } | Select-Object -ExpandProperty ID).Guid
        $Global:ListView = $listViews.GetById($listViewID)
        $spps.Load($ListView)
        $global:listviewFields = $ListView.ViewFields
        $spps.Load($listviewFields)
        $spps.ExecuteQuery()
        }
        
function Get-Listviews {
<#
.Synopsis
   Simple function to Get All views for a List - This is really an internal function
.DESCRIPTION
   Used to get all list views and then outputs them to a variable to be further referenced by other functions in further use
.EXAMPLE
   Get-ListViews -ListTitle Tasks 
.NOTES
   Requires there to have a connection to a SharePoint Site using the Initialize-SPPS function
   
#>
[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
		[string] $ListTitle
	)

    Get-list -ListTitle $ListTitle
    $global:listviews = $list.Views
    $spps.Load($listviews)
    $spps.ExecuteQuery()
    $global:ListViewIDs = $listViews | Select-Object Title,ID | Sort-Object -Property Title
}         
  
function Get-AllListItems {
<#
.Synopsis
   Simple function get all the list items back into an Items variable
.DESCRIPTION
   See Synopsis
.EXAMPLE
   Get-AllListItems -ListName Tasks
    Will return all the items from the SharePoint List called Tasks into an items variable to allow further manipulation
.EXAMPLE
   Get-AllListItems -ListName Tasks -IncludeLookupFields $false
    Will return all the items from the SharePoint List called Tasks into an items variable to allow further manipulation but without getting any fields
    that return as Lookup, Computed, User or UserMulti as not to pass the default 8 (2010) List Lookup threashold     
.NOTES
   Requires there to have a connection to a SharePoint Site using the Initialize-SPPS function 
#>

[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
		[string] $ListTitle,
        
        [Parameter(Mandatory=$true, Position=1)]
		[Bool] $IncludeLookupFields

	)
Get-List -ListTitle $listTitle
Get-ListFields -ListTitle $ListTitle
Write-Verbose 'Loaded all the Fields available for the list requested'
    $names = New-Object System.Collections.ArrayList
    $columns = New-Object System.Collections.ArrayList
Write-Verbose 'Created 2 New Arraylists for the Internal Field names and the the replacing components for the CAML Query'
    if ( $IncludeLookupFields -eq $false)
    {
    $listfields | Select ID,InternalName,TypeAsString,FromBaseType | 
                  Where-Object { $_.TypeAsString -notlike "Lookup" `
                  -and $_.TypeAsString -notlike "Computed" `
                  -and $_.TypeAsString -notlike "User" `
                  -and $_.TypeAsString -notlike "UserMulti" `
                  -and $_.FromBaseType -notlike 'True' } |
                  Select-Object InternalName | 
              ForEach-Object { $name = $_.InternalName ; $columns += "<FieldRef Name='$Name' />" ; $names += $name }

              # Need this for Getting the Title Field Which typically gets renamed in UI
              $add = '<FieldRef Name="Title" />'   
              $columns += $add
    }
    elseif ( $IncludeLookupFields -eq $true)
     {
            $listfields | 
                    Select-Object InternalName | 
                    ForEach-Object { $name = $_.InternalName ; $columns += "<FieldRef Name='$Name' />" ; $names += $name }
         }   
$global:items = @()

Write-verbose 'Now iterating through all the items in the list until the returned Items Count is equal to the List Item Count'
    do
    {
    $query = [Microsoft.SharePoint.Client.CamlQuery]::CreateAllItemsQuery(5000, "ID")
    $replace = '<FieldRef Name="ID" />'    
    $query.ViewXml = $query.ViewXml.Replace($replace,$columns)
    $query.ViewXml = $query.ViewXml.Replace("> <","><")
    $query.ListItemCollectionPosition = $listItems.ListItemCollectionPosition 
    $listItems = $List.getItems($query)
    $spps.Load($listItems)
    $spps.ExecuteQuery()
        
        foreach($item in $listItems)
        {
              $Global:items += $item.FieldValues
               
        }
            
     }
     until($items.count -eq $list.ItemCount)
Write-Verbose 'All Items have been returned into the Items Variable'
}

function Get-ListItemsFromView {
<#
.Synopsis
   Simple function get all the list items back into a ViewItems variable depending on the View Name passed to the Function
.DESCRIPTION
   See Synopsis
.EXAMPLE
   Get-ListItemsFromView -ListName Tasks -ViewName MyTasks
    Will return all the items from the SharePoint List called Tasks with the ViewName of MyTasks into an ViewItems variable to allow further manipulation or reporting 
.NOTES
   Requires there to have a connection to a SharePoint Site using the Initialize-SPPS function
   Also needs to add in a check to see if the View exists or is slightly differently called (as SharePoint is a funny beast like that)
#>
[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
		[string] $ListName,

        [Parameter(Mandatory=$true, Position=1)]
		[string] $viewName
	)

Get-List -listTitle $listname
$view = $list.Views.GetByTitle($viewname)
$spps.Load($view)
$spps.ExecuteQuery()
Write-Verbose 'Have got the View that was specified and can now use this to build our required CAML Query'

$query = New-object Microsoft.SharePoint.Client.CamlQuery
Write-Verbose 'Created new CAML Query object with the variable name Query'
$query.ViewXml = "<View><Query>"+$view.ViewQuery.ToString()+"</Query></View>"
Write-Verbose 'Have pulled the View Query from the existing View and implanted this into the ViewXML property of the Query Object to return the required Items'
$global:viewitems = $list.GetItems( $query )
$spps.Load($viewitems)
$spps.ExecuteQuery()
Write-Verbose 'Executed and returned the query and have returned the items into the ViewItems variable'
}

function Get-ListFields {
<#
.Synopsis
   Simple function to get All fields for a List - Used as internal function
.DESCRIPTION
   Use case is for ensuring that a field doesnt already exist in a List or Library 
.EXAMPLE
   Get-ListFields -ListTitle Tasks 
    Will get all the Fields within a List called Tasks and output to ListFieldIDs variable
.NOTES
   Requires there to have a connection to a SharePoint Site using the Initialize-SPPS function
   Also needs to add in a check to see if the View exists or is slightly differently called (as SharePoint is a funny beast like that)
#>
[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
		[string] $ListTitle
	)

    Get-list -ListTitle $ListTitle
    $global:listfields = $list.Fields
    $spps.Load($listfields)
    $spps.ExecuteQuery()
    $global:ListFieldsIDs = $listfields | Select Title,InternalName,ID,TypeAsString,FromBaseType
}

Function Get-ListField {
<#
.Synopsis
   Simple function to get a specifed field for a List
.DESCRIPTION
   Use case is for initally returning a field that already exists in a List or Library 
.EXAMPLE
   Get-ListField -ListTitle Tasks -ListFieldName Title 
    Will get the Field Title from the List called Tasks and output to ListField variable
.NOTES
   Requires there to have a connection to a SharePoint Site using the Initialize-SPPS function
   Also needs to add in a check to see if the View exists or is slightly differently called (as SharePoint is a funny beast like that)
#>
[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
		[string] $ListTitle,

        [Parameter(Mandatory=$true, Position=2)]
		[string] $ListfieldName        
	)
    Get-listfields -ListTitle $ListTitle
        $ListFieldID = ($ListFieldsIDs | Where-Object { $_.InternalName -eq $Listfieldname } | Select-Object -ExpandProperty ID).guid
        $Global:ListField = $listFields.GetById($listfieldID)
        $spps.Load($ListField)
        $spps.ExecuteQuery()
        }

function Get-CreatedListFields {
$Global:CreatedListFields = $listfields | Select ID,InternalName,TypeAsString,FromBaseType | 
              Where-Object { $_.FromBaseType -notlike 'True' } |
              Select-Object InternalName -ExpandProperty InternalName
              }

###################
#     Additions
###################

function New-ListItem {
<#
.Synopsis
   Simple function to Create A Item in a List
.DESCRIPTION
   Use case could be for Creating a new Item in a List or Library 
.EXAMPLE
   New-ListItem -ListTitle 'User Request' -ItemValues @{Request Number = '1';First Name ='2'}
    Will Create a New Item with request number 1 and first name 2
.NOTES
   Requires there to have a connection to a SharePoint Site using the Initialize-SPPS function
#>
[CmdletBinding()]
	param
	(
    [Parameter(Mandatory=$true, Position=1)]
	[string] $ListTitle,

    [Parameter(Mandatory=$true, Position=2)]
    [Hashtable]$ItemValues
    )
    
Get-List -ListTitle $ListTitle    
$itemCreateInfo                 = new-object Microsoft.SharePoint.Client.ListItemCreationInformation
$listItem                       = $list.AddItem($itemCreateInfo)

foreach ($itemvalue in $ItemValues.keys) { 
$internalname = Find-FieldName -listTitle $ListTitle -displayName $ItemValue

Get-ListField -ListTitle $ListTitle -ListfieldName $internalname
If($listfield.TypeAsString -eq 'User' -or $listfield.TypeAsString -eq 'UserMulti')
    {
     if( $($ItemValues.Item($ItemValue)).contains('@') )
        {
        If ($($ItemValues.Item($ItemValue)).contains(';') )
         { 
         $users = $($ItemValues.Item($ItemValue)).Split(';')
         $ID = @() 
         foreach ($user in $users)
            {
                $userID =  $web.EnsureUser($user) 
                $spps.load($userID)
                $Spps.executeQuery()
                $ID += $userID
            }
         } else  {

                $userID =  $web.EnsureUser($($itemvalues.Item($itemvalue))) 
                $spps.load($userID)
                $Spps.executeQuery()
                $ID = $userID.ID
            }        
        
        } else {
        
        Get-Group -name $($ItemValues.Item($ItemValue))
        $ID = $group.Id  

        }
            $listitem[$internalname] = $ID
    
    }
    else
        {
        $listitem[$internalname] = $($itemvalues.Item($itemvalue))
        }
    $listItem.Update()
    }
$Spps.ExecuteQuery()
}

function New-ListView {
<#
.Synopsis
   Simple function to Create A view for a List
.DESCRIPTION
   Use case could be for Creating a new view in a List or Library 
.EXAMPLE
   New-ListView -ListTitle Tasks -ViewTitle NewTasks -ViewRowLimit 500 -ViewQuery '<Where><Eq><FieldRef Name="Completed" /><Value Type="Boolean">0</Value></Eq></Where>' -ViewFields @("Title","Completed","Task Status","Description")
    Will Create a View called NewTasks with a limit of 500 items and a query of Where Completed is false and with the Fields Title, Completed, Task Status, Description
.EXAMPLE
    $vq = '<Where><Eq><FieldRef Name="Completed" /><Value Type="Boolean">0</Value></Eq></Where>'
    $vf =  @("Title","Completed","Task Status","Description")   
    $vrl = 100


   Set-ListView -ListTitle Tasks -ViewTitle MyTasks -ViewRowLimit $vrl -ViewQuery $Vq -ViewFields $VF
   
   This will use variables pre created (possibly from another list view) and used these in the setting of the List View
   Will Create a View called NewTasks with a limit of 500 items and a query of Where Completed is False and with the Fields Title, Completed, Task Status, Description
.NOTES
   Requires there to have a connection to a SharePoint Site using the Initialize-SPPS function
   Also needs to add in a check to see if the View exists or is slightly differently called (as SharePoint is a funny beast like that)
#>
[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
		[string] $ListTitle,

        [Parameter(Mandatory=$true, Position=1)]
		[string] $ViewTitle,

        [Parameter(Mandatory=$true, Position=1)]
		[string] $ViewRowLimit,

        [Parameter(Mandatory=$true, Position=1)]
		[string] $ViewQuery,

        [Parameter(Mandatory=$true, Position=1)]
		$ViewFields
	)


Get-Listviews -ListTitle $ListTitle

if ($ListViewIDs.Title -contains $ViewTitle)
    {
    Write-Warning -Message "$viewTitle already exists - Please provide a different name for the view"
    }
    else
        {
        $LvCI = New-object Microsoft.SharePoint.Client.ViewCreationInformation
        $LvCI.Query = $viewquery
        $LvCI.RowLimit = $ViewRowLimit
        $LvCI.Title = $ViewTitle
        $LvCI.ViewFields = $ViewFields

        $lvc = $list.Views.Add($LVCI)
        $Spps.Load($lvc)
        $Spps.ExecuteQuery()
        Write-Verbose "Created $ViewTitle in $ListTitle "
        Write-Verbose "with a Row limit of $ViewRowLimit "
        Write-Verbose "a Query of $ViewQuery "
        Write-Verbose "and showing the fields $ViewFields"
        }
}

function Add-List {
<#
.Synopsis
   This function will Create a new SharePoint List or Library as specified by the parameters passed
.DESCRIPTION
   This will check if the List Name already exists (as there cannot be 2 lists or libraries with the same name) 
   and will create a new List/library based on the passed parameters 
.PARAMETER ListTitle
   Provide the Title of the list 
.PARAMETER templateType 
   Uses the SharePoint List Template object type to provide all available list templates to 
   choose from as determined by their internal name - So Custom List in the UI is genericList in this case 
.PARAMETER Description
   This should be a brief description of what the list purpose is
.PARAMETER QuickLaunch  
    This sets whether the List should show on the Quick Launch or not
    Can be useful to set to Off for a functional list used for other purposes within other lists so
    perhaps has static data that you wouldnt and user editing and therefore destorying your data
.EXAMPLE
   Add-List -ListTitle CSOMTest -TemplateType GenericList -Description 'New Tester CSOM List' -QuickLaunch On
    Will get the object for All the SharePoint Lists and Libraries in the current site and store this in a lists variable 
.NOTES
   Requires there to have a connection to a SharePoint Site using the Initialize-SPPS function 
#>
    [CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
		[string]$listTitle,
		
		[Parameter(Mandatory=$false, Position=1)]
		[Microsoft.SharePoint.Client.ListTemplateType]$templateType = "genericList",

        [Parameter(Mandatory=$false, Position=1)]
		[String]$Description,

        [Parameter(Mandatory=$false, Position=1)]
		[ValidateSet("Off", "On", "DefaultValue")]
        [Microsoft.SharePoint.Client.QuickLaunchOptions]$QuickLaunch = "DefaultValue",

        [Parameter(Mandatory=$false, Position=1)]
		[Bool]$EnableModeration
      
	)
	     Get-Lists
    if(!($listTitles.Title -contains $listTitle))
    {
        $listCreationInfo = new-object Microsoft.SharePoint.Client.ListCreationInformation
        $listCreationInfo.TemplateType = $templateType
        $listCreationInfo.Title = $listTitle
        $listCreationInfo.QuickLaunchOption = $QuickLaunch
        $listCreationInfo.Description = $Description
        $list = $web.Lists.Add($listCreationInfo)
        $list.EnableModeration = $EnableModeration
        $list.Update()
        
        $spps.ExecuteQuery()
         
		Write-Host "List '$listTitle' is created succesfully" -foregroundcolor black -backgroundcolor green
    }
    else
    {
		Write-Host "List '$listTitle' already exists" -foregroundcolor black -backgroundcolor yellow
    }

   
    Get-lists #This is force an Update to the variables created under that function
}

function Add-DocumentLibrary{
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
		[string]$listTitle
	)
	
    Add-List -listTitle $listTitle -templateType "DocumentLibrary"
}

function Add-PictureLibrary {
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
		[string]$listTitle
	)
	
	Add-List -listTitle $listTitle -templateType "PictureLibrary"
}

function Add-FieldsToList {
	<#
	.SYNOPSIS
		Adds custom fields to the list
	.DESCRIPTION
		Fill the $fields property using an array of array (<fieldname>,<fieldtype>,<optional>)
		where fieldtypes are:
			Text
            Note
            DateTime
            Currency
            Number
            Choice (add choices comma-seperated to optional field)
            Person or Group
            Calculated (add expression to optional field)
	.PARAMETER fields
		Use an array of array (<fieldname>,<fieldtype>,<optional>)
		where fieldtypes are:
			Text
            Note
            DateTime
            Currency
            Number
            Choice (add choices comma-seperated to optional field)
            Person or Group
            Calculated (add expression to optional field)
	.PARAMETER listTitle
		Title of the list
	.EXAMPLE
		[string[][]]$fields = ("MyChoices","Choice","Left;Right"),
                              ("MyNumber","Number","")
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
		[string[][]]$fields,
		
		[Parameter(Mandatory=$true, Position=2)]
		[string]$listTitle
	)
	
    foreach($field in $fields)
    {
        $fieldName = $field[0]
        $fieldType = $field[1]
        $fieldValue = $field[2]
        
        switch ($fieldType)
        {
            "Text" { Add-TextFieldtoList $listTitle $fieldName
            }
            "Note"
            {
                Add-NoteFieldtoList $listTitle $fieldName
            }
            "DateTime"
            {
                Add-DateTimeFieldtoList $listTitle $fieldName
            }
            "Currency"
            {
                Add-CurrencyFieldtoList $listTitle $fieldName
            }
            "Number"
            {
                Add-CurrencyFieldtoList $listTitle $fieldName
            }
            "Choice"
            {
                Add-ChoiceFieldtoList $listTitle $fieldName $fieldValue
            }
            "Person or Group"
            {
                Add-UserFieldtoList $listTitle $fieldName
            }
            "Calculated"
            {
                Add-CalculatedFieldtoList $listTitle $fieldName $fieldValue
            }
        }
    }
}

function Add-CalculatedFieldtoList {
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
		[string] $listTitle,
		
		[Parameter(Mandatory=$true, Position=2)]
		[string] $fieldName,
		
		[Parameter(Mandatory=$true, Position=3)]
		[string] $value,

		[Parameter(Mandatory=$false, Position=3)]
		[string] $InternalName        
	)
if(!$internalname) {
    $internalname = $fieldName
    }	
    $refField = $value.Split(";")[1]
    $formula = $value.Split(";")[0]
    
    $internalName = Find-FieldName $listTitle $refField
    
    $newField = '<Field Type="Calculated" DisplayName="$fieldName" ResultType="DateTime" ReadOnly="TRUE" Name="$fieldName"><Formula>$formula</Formula><FieldRefs><FieldRef StaticName="$internalName" /></FieldRefs></Field>'
    
    Add-Field $listTitle $fieldName $newField          
}

function Add-UserFieldtoList {
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
		[string] $listTitle, 
		
		[Parameter(Mandatory=$true, Position=2)]
		[string] $fieldName,
        
        [Parameter(Mandatory=$true, Position=2)]
		[ValidateSet("Single","Multi")]
        [string] $Usertype,
        
        [Parameter(Mandatory=$true, Position=2)]
		[string] $UserSelectionScope = "0",

        [Parameter(Mandatory=$true, Position=2)]
		[ValidateSet("PeopleOnly","PeopleAndGroups")]
        [string] $UserSelectionMode,

        [Parameter(Mandatory=$false, Position=5)]
		[ValidateSet("TRUE","FALSE")]
        [String] $Required,

        [Parameter(Mandatory=$false, Position=6)]
		[ValidateSet("TRUE","FALSE")]
        [String] $enforceUniqueValues = "FALSE",

        [Parameter(Mandatory=$false, Position=7)]
		[ValidateSet("TRUE","FALSE")]
        [String] $indexed,

        [Parameter(Mandatory=$false, Position=3)]
		[string] $InternalName  
	)
if(!$internalname) {
    $internalname = $fieldName
    }	
if($Usertype -eq "Single")
{
$fieldtype = "User"
$Mult = $null
}
Elseif($Usertype -eq "Multi")
{
$fieldtype = "UserMulti" 
$Mult= "Mult='TRUE'"
$indexed = "FALSE"
Write-host "Indexing on Multi User Fields Isn't Supported"
}

    $global:newField = "<Field Type='$fieldtype' DisplayName='$fieldName' Name='$fieldName' StaticName='$fieldName' UserSelectionScope='$userSelectionScope' UserSelectionMode='$userSelectionMode' $mult Sortable='FALSE' Required='$Required' EnforceUniqueValues='$enforceUniqueValues' Indexed='$indexed'/>"
    Add-Field $listTitle $fieldName $newField  
}

function Add-TextFieldtoList {
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
		[string] $listTitle, 
		
		[Parameter(Mandatory=$true, Position=2)]
		[string] $fieldName,

        [Parameter(Mandatory=$false, Position=2)]
		[int] $MaxNumberofChars,

        [Parameter(Mandatory=$false, Position=5)]
		[String] $Required,

        [Parameter(Mandatory=$false, Position=6)]
		[ValidateSet("TRUE","FALSE")]
        [String] $enforceUniqueValues,

        [Parameter(Mandatory=$false, Position=7)]
		[ValidateSet("TRUE","FALSE")]
        [String] $indexed,

        [Parameter(Mandatory=$false, Position=3)]
		[string] $internalname
	)

if(!$internalname) {
    $internalname = $fieldName
    }
	
if(!$MaxNumberofChars)
{
$MaxNumberofChars = "255"
}
    $newField = "<Field Type='Text' DisplayName='$fieldName' StaticName='$internalname' MaxLength='$MaxNumberofChars' Required='$Required' EnforceUniqueValues='$enforceUniqueValues' Indexed='$indexed' />"
    Add-Field $listTitle $fieldName $newField  
}

function Add-NoteFieldtoList {
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
		[string] $listTitle, 
		
		[Parameter(Mandatory=$true, Position=2)]
		[string] $fieldName,

        [Parameter(Mandatory=$false, Position=3)]
		[string] $internalname,

        [Parameter(Mandatory=$true, Position=2)]
		[INT] $NumberOfLines,

        [Parameter(Mandatory=$true, Position=2)]
		[ValidateSet("RichText","EnhancedRichText","PlainText")]
        [string] $TextType,
        
        [Parameter(Mandatory=$false, Position=5)]
		[ValidateSet("TRUE","FALSE")]
        [String] $Required,

        [Parameter(Mandatory=$false, Position=6)]
		[ValidateSet("TRUE","FALSE")]
        [String] $enforceUniqueValues
    
	)

if(!$internalname) {
    $internalname = $fieldName
    }

if($TextType -eq "RichText")
{
$ttype = 'RichText="TRUE" RichTextMode="Compatible"'
}
elseif($TextType -eq "EnhancedRichText")
{
$ttype = 'RichText="TRUE" RichTextMode="FullHtml"'
}
Elseif($TextType -eq "PlainText")
{
$ttype = 'RichText="False"'
}
	
    $newField = "<Field Type='Note' DisplayName='$fieldName' StaticName='$internalName' NumLines='$NumberofLines' $ttype Sortable='FALSE' Required='$Required' EnforceUniqueValues='$enforceUniqueValues' />"
    Add-Field $listTitle $fieldName $newField  
}

function Add-DateTimeFieldtoList {
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
		[string] $listTitle, 
		
		[Parameter(Mandatory=$true, Position=2)]
		[string] $fieldName,

        [Parameter(Mandatory=$false, Position=3)]
		[string] $internalname,

        [Parameter(Mandatory=$false, Position=5)]
		[ValidateSet("TRUE","FALSE")]
        [String] $Required,

        [Parameter(Mandatory=$false, Position=6)]
		[ValidateSet("TRUE","FALSE")]
        [String] $enforceUniqueValues,

        [Parameter(Mandatory=$false, Position=7)]
		[ValidateSet("TRUE","FALSE")]
        [String] $indexed
	)
if(!$internalname) {
    $internalname = $fieldName
    }	
    $newField = "<Field Type='DateTime' DisplayName='$fieldName' StaticName='$internalname' Required='$Required' EnforceUniqueValues='$enforceUniqueValues' Indexed='$indexed'/>"
    Add-Field $listTitle $fieldName $newField  
}

function Add-CurrencyFieldtoList {
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
		[string] $listTitle, 
		
		[Parameter(Mandatory=$true, Position=2)]
		[string] $fieldName,

        [Parameter(Mandatory=$false, Position=5)]
		[ValidateSet("TRUE","FALSE")]
        [String] $Required,

        [Parameter(Mandatory=$false, Position=6)]
		[ValidateSet("TRUE","FALSE")]
        [String] $enforceUniqueValues,

        [Parameter(Mandatory=$false, Position=7)]
		[ValidateSet("TRUE","FALSE")]
        [String] $indexed,

        [Parameter(Mandatory=$false, Position=3)]
		[string] $internalname
	)

if(!$internalname) {
    $internalname = $fieldName
    }	
    $newField = "<Field Type='Currency' DisplayName='$fieldName' StaticName='$internalname' Required='$Required' EnforceUniqueValues='$enforceUniqueValues' Indexed='$indexed'/>"
    Add-Field $listTitle $fieldName $newField  
}

function Add-NumberFieldtoList {
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
		[string] $listTitle, 
		
		[Parameter(Mandatory=$true, Position=2)]
		[string] $fieldName,

        [Parameter(Mandatory=$false, Position=5)]
		[ValidateSet("TRUE","FALSE")]
        [String] $Required,

        [Parameter(Mandatory=$false, Position=6)]
		[ValidateSet("TRUE","FALSE")]
        [String] $enforceUniqueValues,

        [Parameter(Mandatory=$false, Position=7)]
		[ValidateSet("TRUE","FALSE")]
        [String] $indexed,

        [Parameter(Mandatory=$false, Position=3)]
		[string] $internalname
	)
if(!$internalname) {
    $internalname = $fieldName
    }

    $newField = "<Field Type='Number' DisplayName='$fieldName' StaticName='$internalname' Required='$Required' EnforceUniqueValues='$enforceUniqueValues' Indexed='$indexed'/>"
    Add-Field $listTitle $fieldName $newField  
}

function Add-BooleanFieldtoList {
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
		[string] $listTitle, 
		
		[Parameter(Mandatory=$true, Position=2)]
		[string] $fieldName,

        [Parameter(Mandatory=$false, Position=5)]
		[ValidateSet("TRUE","FALSE")]
        [String] $Required,

        [Parameter(Mandatory=$false, Position=7)]
		[ValidateSet("TRUE","FALSE")]
        [String] $indexed,

        [Parameter(Mandatory=$false, Position=3)]
		[string] $internalname
	)

if(!$internalname) {
    $internalname = $fieldName
    }

    $newField = "<Field Type='Boolean' DisplayName='$fieldName' StaticName='$internalname' Required='$Required' Indexed='$indexed' />"
    Add-Field $listTitle $fieldName $newField  
}

function Add-ChoiceFieldtoList {
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
		[string] $listTitle, 
		
		[Parameter(Mandatory=$true, Position=2)]
		[string] $fieldName,
		
		[Parameter(Mandatory=$true, Position=3)]
		[string] $values,
        
        [Parameter(Mandatory=$true, Position=4)]
		[ValidateSet("Dropdown","MultiChoice","RadioButtons")]
        [string] $ChoiceType,
        
        [Parameter(Mandatory=$false, Position=5)]
		[ValidateSet("TRUE","FALSE")]
        [String] $Required,

        [Parameter(Mandatory=$false, Position=6)]
		[ValidateSet("TRUE","FALSE")]
        [String] $enforceUniqueValues,

        [Parameter(Mandatory=$false, Position=7)]
		[ValidateSet("TRUE","FALSE")]
        [String] $indexed,

        [Parameter(Mandatory=$false, Position=3)]
		[string] $internalname

	)
	

if(!$internalname) {
    $internalname = $fieldName
    }

if($ChoiceType -eq "MultiChoice")
{
$ftype = "MultiChoice"
$cType = $null
}
else
{
$ftype = "Choice"
$ctype = $ChoiceType
}

    $options = ""
    $valArray = $values.Split(";")
    foreach ($s in $valArray)
    {
        $options = $options + "<CHOICE>$s</CHOICE>"
    }
    
    $newField = "<Field Type='$fType' DisplayName='$fieldName' StaticName='$internalname' Format='$cType' Required='$Required' EnforceUniqueValues='$enforceUniqueValues' Indexed='$indexed' ><CHOICES>$options</CHOICES></Field>"
    
    Add-Field $listTitle $fieldName $newField  
}

### Come back too ###
function Add-ChoicesToField {
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
		[string[]] $choices, 
		
		[Parameter(Mandatory=$true, Position=2)]
		[string] $fieldName, 
		
		[Parameter(Mandatory=$true, Position=3)]
		[string] $listTitle
	)

	Write-Host "Adding choices to field $fieldName" -foregroundcolor black -backgroundcolor yellow
    $web = $spps.Web
    $list = $web.Lists.GetByTitle($listTitle)
    $fields = $list.Fields
    $spps.Load($fields)
    $spps.ExecuteQuery()

    if (Test-Field $list $fields $fieldName)
    {
        $field = $fields.GetByInternalNameOrTitle($fieldName)
        $spps.Load($field)
        $spps.ExecuteQuery()
        
        # calling nongeneric method public T CastTo<T>(ClientObject object)
        $method = [Microsoft.Sharepoint.Client.ClientContext].GetMethod("CastTo")
        $castToMethod = $method.MakeGenericMethod([Microsoft.Sharepoint.Client.FieldChoice])
        $fieldChoice = $castToMethod.Invoke($spps, $field)
        
        $currentChoices = $fieldChoice.Choices
        
        # add new choices to the existing choices
        $allChoices = $currentChoices + $choices
        
        # write choices back to the field
        $fieldChoice.Choices = $allChoices
        $fieldChoice.Update()
        
        $list.Update()
        $spps.ExecuteQuery()
		Write-Host "Choices added to field $fieldName" -foregroundcolor black -backgroundcolor yellow
    }
    else
    {
		Write-Host "Field $fieldName doesn't exists in list $listTitle" -foregroundcolor black -backgroundcolor red
    }
}
### Come back to ###
function Add-BulkFieldstoList {
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
get-list -ListTitle $ListTitle
foreach($row in $csv)
{
if($row.type -eq "Choice")
{
Add-ChoiceFieldtoList -listTitle $list.Title -fieldName $Row.Name -values $row.Choicevalues -ChoiceType $row.ChoiceType
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
  
### Come back to ###        
function Add-Field {
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
		[string] $listTitle, 
		
		[Parameter(Mandatory=$true, Position=2)]
		[string] $fieldName, 
		
		[Parameter(Mandatory=$true, Position=3)]
		[string] $fieldXML
	)

    $web = $spps.Web
    $list = $web.Lists.GetByTitle($listTitle)
    $fields = $list.Fields
    $spps.Load($fields)
    $spps.ExecuteQuery()

    if (!(Test-Field $list $fields $fieldName))
    {
        $field = $list.Fields.AddFieldAsXml($fieldXML, $true, [Microsoft.SharePoint.Client.AddFieldOptions]::AddToAllContentTypes);
        $list.Update()
        $spps.ExecuteQuery()
        
		Write-Host "Field $fieldName added to list $listTitle" -foregroundcolor black -backgroundcolor yellow
    }
    else
    {
		Write-Host "Field $fieldName already exists in list $listTitle" -foregroundcolor black -backgroundcolor yellow
    }
}

### Come back to ###
function Find-FieldName {
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
		[string] $listTitle, 
		
		[Parameter(Mandatory=$true, Position=2)]
		[string] $displayName
	)

    Get-List -ListTitle $listTitle
    $fields = $list.Fields
    $spps.Load($fields)
    $spps.ExecuteQuery()

    $fieldValues = $fields | select Title, InternalName
    foreach($f in $fieldValues)
    {
        if ($f.Title -eq $displayName)
        {
            return $f.InternalName
        }
    }
    
    return $displayName;
}
  
### Come back to ###
function Test-Field {
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
		[Microsoft.SharePoint.Client.List] $list, 
		
		[Parameter(Mandatory=$true, Position=2)]
		[Microsoft.SharePoint.Client.FieldCollection] $fields, 
		
		[Parameter(Mandatory=$true, Position=3)]
		[string] $fieldName
	)
	
    $fieldNames = $fields | select Title
    $exists = ($fieldNames -contains $fieldName)
    return $exists
}


### FOLDER COPYING FUNCTIONS ###
### Come back too ###
function Copy-Folder {
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
		[string]$folderPath, 
		
		[Parameter(Mandatory=$true, Position=2)]
		[string]$doclib, 
		
		[Parameter(Mandatory=$false, Position=3)]
		[bool]$checkoutNecessary = $false
	)

    # for each file in folder Copy-File()
    $files = Get-ChildItem -Path $folderPath -Recurse
    foreach ($file in $files)
    {
        $folder = $file.FullName.Replace($folderPath,'')
        $targetPath = $doclib + $folder
        $targetPath = $targetPath.Replace('\','/')
        Copy-File $file $targetPath $checkoutNecessary
    }
}
### Come back too ###
function Copy-File {
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
		[System.IO.FileSystemInfo]$file, 
		
		[Parameter(Mandatory=$true, Position=2)]
		[string]$targetPath, 
		
		[Parameter(Mandatory=$true, Position=3)]
		[bool]$checkoutNecessary
	)

    if ($file.PsIsContainer)
    {
        Add-Folder $targetPath
    }
    else
    {
        $filePath = $file.FullName
        
		Write-Host "Copying file $filePath to $targetPath" -foregroundcolor black -backgroundcolor yellow
		
        
        if ($checkoutNecessary)
        {
            # Set the error action to silent to try to check out the file if it exists
            $ErrorActionPreference = "SilentlyContinue"
            Submit-CheckOut $targetPath
            $ErrorActionPreference = "Stop"
        }
        
		$arrExtensions = ".html", ".js", ".master", ".txt", ".css", ".aspx"
		
		if ($arrExtensions -contains $file.Extension)
		{
			$tempFile = Convert-FileVariablesToValues -file $file
	        Save-File $targetPath $tempFile
		} 
		else
		{
			Save-File $targetPath $file
		}
        
        if ($checkoutNecessary)
        {
            Submit-CheckOut $targetPath
            Submit-CheckIn $targetPath
        }
    }
}
### Come back too ###
function Save-File {
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
		[string]$targetPath, 
	
		[Parameter(Mandatory=$true, Position=2)]
		[System.IO.FileInfo]$file
	)
	
	$targetPath = Join-Parts -Separator '/' -Parts $spps.Web.ServerRelativeUrl, $targetPath
	
    $fs = $file.OpenRead()
    [Microsoft.SharePoint.Client.File]::SaveBinaryDirect($spps, $targetPath, $fs, $true)
    $fs.Close()
}
### Come back to ###
function Add-Folder {
<#
.Synopsis
   This function will add a folder to a List or Library
    
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
		[string]$folderUrl
	)
	
    # folder name
    $folderNameArr = $folderurl.Split('/')
    $folderName = $folderNameArr[$folderNameArr.length-1]
	# get server relative path of the sitecollection in there and remove the folder, cause thats being created right now
    $folderUrl = Join-Parts -Separator '/' -Parts $spps.Web.ServerRelativeUrl, $folderUrl
	$parentFolderUrl = $folderUrl.Replace('/' + $folderName,'')
    
 	
 
    # load the folder
    $web = $spps.Web
    $folder = $web.GetFolderByServerRelativeUrl($folderUrl)
    $spps.Load($folder)
    $alreadyExists = $false
 
    # check if the folder exists
    try
    {
        $spps.ExecuteQuery();
        # test if the folder already exists by checking its Path property
        if ($folder.Path)
        {
            $alreadyExists = $true;
        }
    }
    catch { }
 
    if (!$alreadyExists)
    {
        # folder doesn't exists so create it
		Write-Host "Create folder $folderName at $parentFolderUrl" -foregroundcolor black -backgroundcolor yellow
        
        # create the folder item
        $newItemInfo = new-object Microsoft.SharePoint.Client.ListItemCreationInformation
        $newItemInfo.UnderlyingObjectType = [Microsoft.SharePoint.Client.FileSystemObjectType]::Folder
        $newItemInfo.LeafName = $folderName
        $newItemInfo.FolderUrl = $parentFolderUrl
        
        # add the folder to the list
        $listUrl = Join-Parts -Separator '/' -Parts $spps.Web.ServerRelativeUrl, $folderNameArr[1]
		
		
		#$spps.LoadQuery($web.Lists.Where(list => list.RootFolder.ServerRelativeUrl -eq $listUrl))
		
		$method = [Microsoft.SharePoint.Client.ClientContext].GetMethod("Load")
		$loadMethod = $method.MakeGenericMethod([Microsoft.SharePoint.Client.List])

		$parameter = [System.Linq.Expressions.Expression]::Parameter(([Microsoft.SharePoint.Client.List]), "list")
		$expression = [System.Linq.Expressions.Expression]::Lambda(
			[System.Linq.Expressions.Expression]::Convert(
				[System.Linq.Expressions.Expression]::PropertyOrField(
					[System.Linq.Expressions.Expression]::PropertyOrField($parameter, "RootFolder"),
					"ServerRelativeUrl"
				),
				[System.Object]
			),
			$($parameter)
		)
		$expressionArray = [System.Array]::CreateInstance($expression.GetType(), 1)
		$expressionArray.SetValue($expression, 0)
		
		$lists = $web.Lists
		
		$spps.Load($lists)
		$spps.ExecuteQuery()
		
		$list = $null
		
		foreach	($listfinder in $lists) {
			$loadMethod.Invoke($spps, @($listfinder, $expressionArray))
			
			$spps.ExecuteQuery()
			
			if ($listfinder.RootFolder.ServerRelativeUrl -eq $listUrl)
			{
				$list = $listfinder
			}
		}
		
        $newListItem = $list.AddItem($newItemInfo)
 
        # item update
        $newListItem.Update()
 
        # execute it
        $spps.Load($list);
        $spps.ExecuteQuery();
    }
}



### LIST OPERATIONS ###
### Come back to ###
function Add-ListItems {<#
.Synopsis
   This function will Add List items from a CSV File 
    
.DESCRIPTION
   This can be used to bulk add alot of items into a list
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
		[string]$csvPath, 
		
		[Parameter(Mandatory=$true, Position=2)]
		[string]$listName
	)

    $list = $spps.Web.Lists.GetByTitle($listName)
    
    $csvPathUnicode = $csvPath -replace ".csv", "_unicode.csv"
    Get-Content $csvPath | Out-File $csvPathUnicode
    $csv = Import-Csv $csvPathUnicode -Delimiter ';'
    foreach ($line in $csv)
    {
        $itemCreateInfo = new-object Microsoft.SharePoint.Client.ListItemCreationInformation
        $listItem = $list.AddItem($itemCreateInfo)
        
        foreach ($prop in $line.psobject.properties)
        {
            $listItem[$prop.Name] = $prop.Value
        }
        
        $listItem.Update()
        
        $spps.ExecuteQuery()
    }
}


### CHECKIN CHECKOUT FUNCTIONS ###
### Come back to ###
function Submit-CheckOut {
<#
.Synopsis
   This function will Check out a file 
    
.DESCRIPTION
   This can be used to check out a file in a library that requires files to be checked in before beinf published
.EXAMPLE
   Clear-ListContent -ListTitle Tasks
   Will get the object for the SharePoint List called Tasks and then delete this from the Site 
.NOTES
   Requires there to have a connection to a SharePoint Site using the Initialize-SPPS function 
#>	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
		[string]$targetPath
	)
	
	$targetPath = Join-Parts -Separator '/' -Parts $spps.Web.ServerRelativeUrl, $targetPath

    $remotefile = $spps.Web.GetFileByServerRelativeUrl($targetPath)
    $spps.Load($remotefile)
    $spps.ExecuteQuery()
    
    if ($remotefile.CheckOutType -eq [Microsoft.SharePoint.Client.CheckOutType]::None)
    {
        $remotefile.CheckOut()
    }
    $spps.ExecuteQuery()
}
### Come back to ###
function Submit-CheckIn {<#
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
		[string]$targetPath
	)
	
	$targetPath = Join-Parts -Separator '/' -Parts $spps.Web.ServerRelativeUrl, $targetPath
	
    $remotefile = $spps.Web.GetFileByServerRelativeUrl($targetPath)
    $spps.Load($remotefile)
    $spps.ExecuteQuery()
    
    $remotefile.CheckIn("",[Microsoft.SharePoint.Client.CheckinType]::MajorCheckIn)
    
    $spps.ExecuteQuery()
}


####################
#       Updates    #
####################

Function Set-Listview {
<#
.Synopsis
   Simple function to update A view for a List
.DESCRIPTION
   Use case could be for updating an old view in a List or Library 
.EXAMPLE
   Set-ListView -ListTitle Tasks -ViewTitle MyTasks -ViewRowLimit 500 -ViewQuery '<Where><Eq><FieldRef Name="Completed" /><Value Type="Boolean">1</Value></Eq></Where>' -ViewFields @("Title","Completed","Task Status","Description")
    Will Update a View called MyTasks with a limit of 500 items and a query of Where Completed is True and with the Fields Title, Completed, Task Status, Description
.EXAMPLE
    $vq = '<Where><Eq><FieldRef Name="Completed" /><Value Type="Boolean">0</Value></Eq></Where>'
    $vf =  @("Title","Completed","Task Status","Description")   
    $vrl = 100


   Set-ListView -ListTitle Tasks -ViewTitle MyTasks -ViewRowLimit $vrl -ViewQuery $Vq -ViewFields $VF
   
   This will use variables pre created (possibly from another list view) and used these in the setting of the List View
   Will Update a View called MyTasks with a limit of 500 items and a query of Where Completed is True and with the Fields Title, Completed, Task Status, Description
.NOTES
   Requires there to have a connection to a SharePoint Site using the Initialize-SPPS function
   Also needs to add in a check to see if the View exists or is slightly differently called (as SharePoint is a funny beast like that)
#>
[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
		[string] $ListTitle,

        [Parameter(Mandatory=$true, Position=1)]
		[string] $ViewTitle,

        [Parameter(Mandatory=$false, Position=1)]
		[string] $ViewRowLimit,

        [Parameter(Mandatory=$false, Position=1)]
		[string] $ViewQuery,

        [Parameter(Mandatory=$false, Position=1)]
		$ViewFields
	)

Get-ListView -ListTitle $ListTitle -ListViewName $ViewTitle

if ($ViewRowLimit -eq $null)
    {
        $ViewRowLimit = $listview.RowLimit
    }
if ($ViewQuery -eq $null)
    {
        $ViewQuery = $listview.ViewQuery
    }   
If ($ViewFields -eq $null)
    {
        $ViewFields = $ListViewFields
        
    }
    else
        {
        $listview.ViewFields.RemoveAll() 
        foreach ($viewfield in $ViewFields)
            {
            $ListView.ViewFields.Add($ViewField)
            }
        }

$listview.ViewQuery = $viewquery
$listview.RowLimit = $ViewRowLimit
$listview.Title = $ViewTitle
$listview.Update()
$spps.ExecuteQuery()

}

function Set-ListField {
<#
.Synopsis
   Simple function to update a specifed field for a List
.DESCRIPTION
   Use case is for updating a field that already exists in a List or Library
.EXAMPLE
   Set-ListField -ListTitle Tasks -ListFieldName Title -ListfieldProperty Required -Value $False 
    Will get the Field Title from the List called Tasks and will then set this field as not required on data input
.NOTES
   Requires there to have a connection to a SharePoint Site using the Initialize-SPPS function
   Also needs to add in a check to see if the View exists or is slightly differently called (as SharePoint is a funny beast like that)
#>
[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
		[string] $ListTitle,

        [Parameter(Mandatory=$true, Position=2)]
		[string] $ListfieldName,
         
        [Parameter(Mandatory=$true, Position=3)]
		[string] $ListfieldProperty,
        
        [Parameter(Mandatory=$true, Position=3)]
		$Value

    )
     Get-ListField -ListTitle $ListTitle -ListfieldName $ListfieldName 
     $ListField."$ListfieldProperty" = $Value
     $ListField.Update()
     $Spps.ExecuteQuery()
     }  

####################
#       Removals   #
####################

function Clear-ListContent {
<#
.Synopsis
   This function will Delete all items from a SharePoint List that you specify 
    
.DESCRIPTION
   This can be used to delete all items from a list in a Site 
   However be forewarnded this does not delete items to the Recycle Bin
   This will permanently Remove all items from the list
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
		[string]$listTitle,

        [Parameter(Mandatory=$false, Position=1)]
		[Bool] $Recycle = $true

	)
	
   Get-List -ListTitle $listTitle
    
    $count = $list.ItemCount
    $newline = [environment]::newline

    
    Write-Host -NoNewline "Deleting listitems from $listTitle" -foregroundcolor black -backgroundcolor yellow

	$continue = $true
    while($continue)
    {
        Write-Host -NoNewline "." -foregroundcolor black -backgroundcolor yellow
       	$query = [Microsoft.SharePoint.Client.CamlQuery]::CreateAllItemsQuery(100, "ID")
        $listItems = $list.GetItems( $query )

        $spps.Load($listItems)
        $spps.ExecuteQuery()
        
        if ($listItems.Count -gt 0)
        {
            for ($i = $listItems.Count-1; $i -ge 0; $i--)
            {
                if($recycle -eq $true)
                {
                $listItems[$i].Recycle()
                }
                else
                    {
                    $listItems[$i].DeleteObject()
                    }
            } 
            $spps.ExecuteQuery()
        }
        else
        {
			Write-Host "." -foregroundcolor black -backgroundcolor yellow
            $continue = $false;
        }
    }

    Write-Host "All listitems deleted from $listTitle." -foregroundcolor black -backgroundcolor green



} 

function Remove-list {
<#
.Synopsis
   This function will get the object for the SharePoint List that you specify 
   and perform a delete object command on that list object 
.DESCRIPTION
   This can be used to remove a list from a Site - 
   You can use this in a foreach loop to remove multiple lists
   You could call this in the Pipeline (to be added) to remove all the lists from the Site

   However be forewarned this does not delete to the Recycle Bin - This will permanently Remove
   the list
.EXAMPLE
   Remove-List -ListTitle Tasks
    Will get the object for the SharePoint List called Tasks and then delete this from the Site 
.NOTES
   Requires there to have a connection to a SharePoint Site using the Initialize-SPPS function 
#>
[CmdletBinding()]
	param
	(
	    [Parameter(Mandatory=$true, Position=1)]
	    [string]$ListTitle,

        [Parameter(Mandatory=$false, Position=1)]
		[Bool] $Recycle = $true
 
    )
    Get-List -ListTitle $ListTitle
    if ($recycle -eq $true)
    {
        $list.Recycle()
    }
    else
        {
        $list.DeleteObject()
        }
    $spps.ExecuteQuery()
    Write-Verbose "List $ListTitle Sucessfully Removed"
    get-lists
   }

function Remove-ListItemsFromView {
<#
.Synopsis
   Simple function to remove all the list items based on a View of a List/Library
.DESCRIPTION
   Use case could be for removing old uneeded entries in a List or documents that have been moved to another Librar
.EXAMPLE
   Remove-ListItemsFromView -ListName Tasks -ViewName MyTasks
    Will return all the items from the SharePoint List called Tasks with the ViewName of MyTasks and permanenty delete them from the Site
.EXAMPLE
   Remove-ListItemsFromView -ListName Tasks -ViewName MyTasks -Recycle $True
    Will return all the items from the SharePoint List called Tasks with the ViewName of MyTasks and Send them to the Recycle Bin
.NOTES
   Requires there to have a connection to a SharePoint Site using the Initialize-SPPS function
   Also needs to add in a check to see if the View exists or is slightly differently called (as SharePoint is a funny beast like that)
#>
[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
		[string] $ListName,

        [Parameter(Mandatory=$true, Position=1)]
		[string] $viewName,
        
        [Parameter(Mandatory=$false, Position=1)]
		[Bool] $Recycle = $true

	)

Get-ListItemsFromView -ListName $ListName -viewName $viewName
    
if($Recycle -eq $true)
  {    
   foreach ($item in $viewitems)
           { 
             $listitem = $list.GetItemById($item.ID)
             $listitem.Recycle()
             $spps.ExecuteQuery()
           }
    }
            else
                {
                foreach ($item in $viewitems)
                        { 
                          $listitem = $list.GetItemById($item.ID)
                          $listitem.DeleteObject()
                          $spps.ExecuteQuery()
                        }
                 }
    
}

function Remove-ListView {
<#
.Synopsis
   Simple function to remove A view from a List
.DESCRIPTION
   Use case could be for removing old uneeded views in a List or Library 
.EXAMPLE
   Remove-ListView -ListTitle Tasks -ViewTitle MyTasks
    Will remove the View called MyTasks from the SharePoint List called Tasks 
.NOTES
   Requires there to have a connection to a SharePoint Site using the Initialize-SPPS function
   Also needs to add in a check to see if the View exists or is slightly differently called (as SharePoint is a funny beast like that)
#>
[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
		[string] $ListTitle,

        [Parameter(Mandatory=$true, Position=1)]
		[string] $ViewTitle
    )

Get-ListView -ListTitle $ListTitle -ListViewName $ViewTitle
$ListView.DeleteObject()
Write-Verbose "Removed the $viewtitle view from $listTitle"
Get-Listviews -ListTitle $ListTitle
}

function Remove-ListField {
<#
.Synopsis
   Simple function to update a specifed field for a List
.DESCRIPTION
   Use case is for updating a field that already exists in a List or Library
.EXAMPLE
   Set-ListField -ListTitle Tasks -ListFieldName Title -ListfieldProperty Required -Value $False 
    Will get the Field Title from the List called Tasks and will then set this field as not required on data input
.NOTES
   Requires there to have a connection to a SharePoint Site using the Initialize-SPPS function
   Also needs to add in a check to see if the View exists or is slightly differently called (as SharePoint is a funny beast like that)
#>
[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
		[string] $ListTitle,

        [Parameter(Mandatory=$true, Position=2)]
		[string] $ListfieldName
    )
     Get-ListField -ListTitle $ListTitle -ListfieldName $ListfieldName 
     $ListField.DeleteObject()
     $Spps.ExecuteQuery()
     Write-Verbose "Removed $ListfieldName from $listitle"
     }  
