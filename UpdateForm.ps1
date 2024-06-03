#Define Parameters
param (
	[string]$ProjectName
)

#Variables
$currentGroups = New-Object -TypeName System.Collections.ArrayList
$addGroups = New-Object -TypeName System.Collections.ArrayList
$removeGroups = New-Object -TypeName System.Collections.ArrayList

#Functions
function update-Permissions ([string]$Directory, [array]$AddGroups, [array]$RemoveGroups)
{
	#################################
	# Root directory
	##################################
	
	$rootAcl = Get-Acl $Directory

	foreach ($Group in $AddGroups)
	{
		Write-Host $Group
		$groupName = 'Contoso\' + $Group.ToString()
		#Write-Host $groupName
		$groupTemp = New-Object System.Security.AccessControl.FileSystemAccessRule($groupName, 'ReadAndExecute', "None", "None", 'Allow')
		$rootAcl.SetAccessRule($groupTemp)
	}
	foreach ($rGroup in $RemoveGroups)
	{
		$fqdnGroup = 'Contoso\' + $rGroup
		#Loop through Access Rules for the ACLs matching any that match the Domain Users object, and tell the ACL object to remove that rule
		$rootAcl | Select -ExpandProperty Access |
		Where{ $_.IdentityReference -eq $fqdnGroup } |
		ForEach{ $rootAcl.RemoveAccessRule($_) }
	}
	
	# Set true, false to disable inheritance on the root directory
	#$rootAcl.SetAccessRuleProtection($true, $false)
	#$rootAcl | Set-Acl $Directory
	(Get-Item $Directory).SetAccessControl($rootAcl)
}


$formUpdateForm_Load={
	#TODO: Initialize Form Controls here
	
	$fileCount = (Get-ChildItem -Path $rootDir$ProjectName -Recurse -File -Force | Measure-Object).Count
	#$fileCount = Get-ChildItem -Path $rootDir$ProjectName -Recurse | measure | % Count
	$projectSize = [math]::Round(((Get-ChildItem -Path $rootDir$ProjectName -Recurse -File -Force | Measure-Object -Property Length -Sum).Sum /1MB), 2)
	Write-Host $fileCount
	$label1.Text = $ProjectName
	$label2.Text = "Total Files: " + $fileCount
	$label3.Text = "Project Size (MB): " + $projectSize
	
	#get groups
	$projgroups = Get-ADGroup -SearchBase "OU=Security,OU=Groups,OU=Org,DC=Contoso,DC=LOCAL" -Filter { name -like "SearchFilter" } | select name -ExpandProperty name
	# Load AD Groups
	$checkedlistbox2.Items.AddRange($projgroups)
	
	# Remove Groups that are default added
	$checkedlistbox2.Items.Remove("RemoveProject1")
	$checkedlistbox2.Items.Remove("RemoveProject2")
	
	$accessListNames = Get-Acl -Path $rootDir$ProjectName | select -expand access | select IdentityReference

	
	for ($count = 0; $count -lt $checkedlistbox2.items.Count; $count++)
	{
		foreach ($accessName in $accessListNames)
		{
			if ($accessName.IdentityReference.Value.Split("\")[1] -eq $checkedlistbox2.Items[$count].Name)
			{
				$checkedlistbox2.SetItemChecked($count, 'Checked');
				# Add pre-exsisting checked items to the updategroups array
				$currentGroups.Add($checkedlistbox2.Items[$count].Name)
				Write-Host "Current groups "$currentGroups
			}
		}
	}
}

$checkedlistbox2_ItemCheck = [System.Windows.Forms.ItemCheckEventHandler]{
	#Event Argument: $_ = [System.Windows.Forms.ItemCheckEventArgs]
	
	if ($_.NewValue -eq 'Checked')
	{
		if ($currentGroups.Contains($checkedlistbox2.SelectedItem))
		{
			$removeGroups.Remove($checkedlistbox2.SelectedItem)
		}
		else
		{
			$addGroups.Add($checkedlistbox2.SelectedItem)
		}
		
		
	}
	#remove group from array on uncheck
	else
	{
		if ($currentGroups.Contains($checkedlistbox2.SelectedItem))
		{
			$removeGroups.Add($checkedlistbox2.SelectedItem)
		}
		else
		{
			$addGroups.Remove($checkedlistbox2.SelectedItem)
		}
		
	}
	
	#Write-Host "Add groups "$addGroups
	#Write-Host "Current groups "$currentGroups
	#Write-Host "Remove groups "$removeGroups
	
}

$formUpdateForm_FormClosing = [System.Windows.Forms.FormClosingEventHandler]{
	#Event Argument: $_ = [System.Windows.Forms.FormClosingEventArgs]
	if ($formUpdateForm.DialogResult -eq 'Yes')
	{
		$projectName = $label1.Text
		$projectDir = Join-Path $rootDir $projectName
		#Write-Host "Event"
		#Write-Host $ProjectName
		#Write-Host $projectDir
		$grCheckedItems = $checkedlistbox2.CheckedItems
		#Write-Host "CheckedItemsList" $grCheckedItems.GetType()
		update-Permissions $projectDir $grCheckedItems $removeGroups
		
	}
}

#region Control Helper Functions
function Update-ListBox
{
<#
	.SYNOPSIS
		This functions helps you load items into a ListBox or CheckedListBox.
	
	.DESCRIPTION
		Use this function to dynamically load items into the ListBox control.
	
	.PARAMETER ListBox
		The ListBox control you want to add items to.
	
	.PARAMETER Items
		The object or objects you wish to load into the ListBox's Items collection.
	
	.PARAMETER DisplayMember
		Indicates the property to display for the items in this control.
	
	.PARAMETER Append
		Adds the item(s) to the ListBox without clearing the Items collection.
	
	.EXAMPLE
		Update-ListBox $ListBox1 "Red", "White", "Blue"
	
	.EXAMPLE
		Update-ListBox $listBox1 "Red" -Append
		Update-ListBox $listBox1 "White" -Append
		Update-ListBox $listBox1 "Blue" -Append
	
	.EXAMPLE
		Update-ListBox $listBox1 (Get-Process) "ProcessName"
	
	.NOTES
		Additional information about the function.
#>
	
	param
	(
		[Parameter(Mandatory = $true)]
		[ValidateNotNull()]
		[System.Windows.Forms.ListBox]
		$ListBox,
		[Parameter(Mandatory = $true)]
		[ValidateNotNull()]
		$Items,
		[Parameter(Mandatory = $false)]
		[string]
		$DisplayMember,
		[Parameter(Mandatory = $false)]
		[string]$ValueMember,
		[switch]
		$Append
	)
	
	if (-not $Append)
	{
		$listBox.Items.Clear()
	}
	
	if ($Items -is [System.Windows.Forms.ListBox+ObjectCollection])
	{
		$listBox.Items.AddRange($Items)
	}
	elseif ($Items -is [Array])
	{
		$listBox.BeginUpdate()
		foreach ($obj in $Items)
		{
			$listBox.Items.Add($obj)
		}
		$listBox.EndUpdate()
	}
	else
	{
		$listBox.Items.Add($Items)
	}
	
	if ($DisplayMember) 
	{
		$listBox.DisplayMember = $DisplayMember
	}
	if ($ValueMember)
	{
		$ListBox.ValueMember = $ValueMember
	}
}


#endregion

$label1_Click={
	#TODO: Place custom script here
	
}