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
		[System.Windows.Forms.ListBox]$ListBox,
		[Parameter(Mandatory = $true)]
		[ValidateNotNull()]
		$Items,
		[Parameter(Mandatory = $false)]
		[string]$DisplayMember,
		[Parameter(Mandatory = $false)]
		[string]$ValueMember,
		[switch]$Append
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

function Validate-IsName ([string]$Name, [int]$MaxLength)
{
	<#
		.SYNOPSIS
			Validates if input is english name
	
		.DESCRIPTION
			Validates if input is english name
	
		.PARAMETER  Name
			A string containing a name 
	
		.INPUTS
			System.String
	
		.OUTPUTS
			System.Boolean
	#>
	
	if ($MaxLength -eq $null -or $MaxLength -le 0)
	{
		#Set default length to 40
		$MaxLength = 40
	}
	
	return $Name -match "^[a-zA-Z''-'\s]{1,$MaxLength}$"
}

function Validate-IsEmptyTrim ([string]$field)
{
	if ($field -eq $null -or $field.Trim().Length -eq 0)
	{
		return $true
	}
	
	return $false
}
function Validate-IsEmpty ([string]$Text)
{
	<#
		.SYNOPSIS
			Validates if input is empty.
	
		.DESCRIPTION
			Validates if input is empty.
	
		.PARAMETER  Text
			A string containing an IP address
	
		.INPUTS
			System.String
	
		.OUTPUTS
			System.Boolean
	#>
	return [string]::IsNullOrEmpty($Text)
}
#endregion

function create-Directory ([string]$Text)
{
	# Creates the Project Root Directory
	New-Item -Path $rootDir -Name $Text -ItemType Directory -Confirm -ErrorAction Stop
	
	$subDir |
	ForEach-Object {
		New-Item (Join-Path $rootDir$Text $_) -ItemType Directory -force
	}
	
	$subDirAdmin |
	ForEach-Object {
		New-Item (Join-Path $rootDir$Text$adminDir $_) -ItemType Directory -Force
	}
	
	$subDirProjMgmt |
	ForEach-Object {
		New-Item (Join-Path $rootDir$Text$projMgmtDir $_) -ItemType Directory -Force
	}
}

function create-Permissions ([string]$NewDirectory, [array]$Groups)
{

	#################################
	# Root directory
	##################################
	
	$rootAcl = Get-Acl $NewDirectory
	$rootAcl.SetAccessRule($AccessRule_PrjAccAll)
	$rootAcl.SetAccessRule($AccessRule_ITAdminsFull)
	$rootAcl.SetAccessRule($AccessRule_IT)
	$rootAcl.SetAccessRule($AccessRule_Administrator)
	$rootAcl.SetAccessRule($AccessRule_BuiltInAdministrators)
	
	foreach ($Group in $Groups)
	{
		$groupName = 'URBANENGINEERS\' + $Group.ToString()
		$groupTemp = New-Object System.Security.AccessControl.FileSystemAccessRule($groupName, 'ReadAndExecute', "None", "None", 'Allow')
		$rootAcl.SetAccessRule($groupTemp)
	}
	
	# Set true, false to disable inheritance on the root directory
	$rootAcl.SetAccessRuleProtection($true, $false)
	$rootAcl | Set-Acl $NewDirectory
	
	#################################
	# Admin
	##################################
	
	$adminAcl = Get-Acl $adminPath
	$adminAcl.SetAccessRule($AccessRule_DomainUsers_folderOnly)
	# Set true,true to inherit permissions set at root level
	$adminAcl.SetAccessRuleProtection($true, $true)
	$adminAcl | Set-Acl $adminPath
	
	#Set Permissions for subdirectory
	foreach ($subDirA in $subDirAdmin)
	{
		$subAdminPath = Join-Path $adminPath $subDirA
		$subadminACL = Get-Acl $subAdminPath
		$subadminACL.SetAccessRule($AccessRule_DomainUsers)
		$subadminACL.SetAccessRuleProtection($true, $true)
		$subadminACL | Set-Acl $subAdminPath
	}
	
	##################################
	# Project Management
	##################################
	$projMgmtAcl = Get-Acl $projMgmtPath
	$projMgmtAcl.SetAccessRule($AccessRule_ProjMgmtFolder_folderOnly)
	# Set true,true to inherit permissions set at root level
	$projMgmtAcl.SetAccessRuleProtection($true, $true)
	$projMgmtAcl | Set-Acl $projMgmtPath
	
	#Set Permissions for subdirectory
	foreach ($subDirP in $subDirProjMgmt)
	{
		$subProMgmtPath = Join-Path $projMgmtPath $subDirP
		$subProMgmtACL = Get-Acl $subProMgmtPath
		$subProMgmtACL.SetAccessRule($AccessRule_ProjMgmtFolder)
		$subProMgmtACL.SetAccessRuleProtection($true, $true)
		$subProMgmtACL | Set-Acl $subProMgmtPath
	}
	
	##################################
	# Tech
	##################################
	$techAcl = Get-Acl $techPath
	$techAcl.SetAccessRule($AccessRule_DomainUsers)
	# Set true,true to inherit permissions set at root level
	$techAcl.SetAccessRuleProtection($true, $true)
	$techAcl | Set-Acl $techPath
}



$formChildForm_Load={
	#TODO: Initialize Form Controls here
	#get groups
	$projgroups = Get-ADGroup -SearchBase "OU=Security,OU=Groups,OU=Org,DC=Contoso,DC=LOCAL" -Filter { name -like "SearchFilter" } | select name -ExpandProperty name
	# Load AD Groups
	$checkedlistbox1.Items.AddRange($projgroups)
	
	# Remove Groups that are default added
	$checkedlistbox1.Items.Remove("ProjectRemove1")
	$checkedlistbox1.Items.Remove("ProjectRemove2")
	

}

$textbox1_Validating = [System.ComponentModel.CancelEventHandler]{
	#Init to False in case Validate Fails
	$_.Cancel = $false
	#Check if the Name field is empty
	$result = Validate-IsEmpty $textbox1.Text
	if ($result -eq $true)
	{
		$_.Cancel = $true
		#Display an error message
		$errorprovider1.SetError($textbox1, "Please enter a project name");
	}
	else
	{
	    
		#Clear the error message
		$errorprovider1.SetError($textbox1, "");
	}
}


$control_Validated = {
	#Pass the calling control and clear error message
	$errorprovider1.SetError($this, "");

}

$formChildForm_FormClosing = [System.Windows.Forms.FormClosingEventHandler]{
	#Event Argument: $_ = [System.Windows.Forms.FormClosingEventArgs]
	#Validate only on OK Button
	if ($formChildForm.DialogResult -eq "OK")
	{
		$progressbaroverlay1.Maximum = 4
		$progressbaroverlay1.Step = 1
		$progressbaroverlay1.Value = 0
		$progressbaroverlay1.Visible = $true
		$progressbaroverlay1.TextOverlay = "Processing...";
		$progressbaroverlay1.PerformStep();
		Start-Sleep -Seconds 1;
		$projectName = $textbox1.Text
		$projectDir = Join-Path $rootDir $projectName
		$projMgmtPath = Join-Path $projectDir $projMgmtDir
		$adminPath = Join-Path $projectDir $adminDir
		$techPath = Join-Path $projectDir  $techDir
		#Validate the Child Control and Cancel if any fail
		$_.Cancel = -not $formChildForm.ValidateChildren()
		
		# Validation passed
		if ($_.Cancel -eq $false)
		{
			
			try
				{
				$progressbaroverlay1.TextOverlay = "Creating New Directory...";
				create-Directory ($projectName)
				$progressbaroverlay1.PerformStep();
				Start-Sleep -Seconds 1;
				
				#Set Permissions
				$progressbaroverlay1.TextOverlay = "Setting Permissions...";
				$GroupItems =  $checkedlistbox1.CheckedItems
				create-Permissions $projectDir $GroupItems
				$progressbaroverlay1.PerformStep();
				Start-Sleep -Seconds 1;
				
				$progressbaroverlay1.TextOverlay = "Project Folder Created!";
				$progressbaroverlay1.PerformStep();
				Start-Sleep -Seconds 1;
				
				$progressbaroverlay1.Hide()
				}
			catch [System.IO.IOException]
				{
					[System.Windows.Forms.MessageBox]::Show("ErrorMessage: " + $Error[0])
					Write-Host "Error caught"
				}
		}
	}
}
