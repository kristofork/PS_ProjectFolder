#--------------------------------------------
# Declare Global Variables and Functions here
#--------------------------------------------
function Get-SubDirectories
{
	$Folders = Get-ChildItem -Path $rootFolder -Directory | select FullName, Name, CreationTime, LastWriteTime
	return Get-ChildItem -Path $rootFolder -Directory | select Name, CreationTime, LastWriteTime

			#Size		  = [math]::Round(((Get-ChildItem -Path $Folder.fullname -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum /1MB), 2)
			#Files		  = (Get-ChildItem -Path $Folder.fullname -File | Measure-Object -Property Length -Sum).Count

}
function Load-ListView-Columns
{
	#TODO: Initialize Form Controls here
	[void]$listView1.Columns.Add("Folder", 338);
	[void]$listView1.Columns.Add("DateCreated", 200);
	[void]$listView1.Columns.Add("LastModified", 200);
}
function Load-ListView-SubDirectories
{
	Load-ListView-Columns
	# fill the listbox with subfolder names and Last Modified dates
	$subfolders | ForEach-Object {
		$row = New-Object System.Windows.Forms.ListViewItem($_.Name) # the folder path goes into the first column
		[void]$row.SubItems.Add($_.CreationTime.Tostring())
		[void]$row.SubItems.Add($_.LastWriteTime.Tostring()) # the LastWriteTime goes into the second column
		[void]$listView1.Items.Add($row)
		$listView1.Sorting = 'Ascending'
	}
}
function Update-ListView-SubDirectories
{
	[CmdletBinding()]
	param (
		[Parameter()]
		[array]$subdirArray
	)
	Load-ListView-Columns
	# fill the listbox with subfolder names and Last Modified dates
	$subdirArray | ForEach-Object {
		$row = New-Object System.Windows.Forms.ListViewItem($_.Name) # the folder path goes into the first column
		[void]$row.SubItems.Add($_.CreationTime.Tostring())
		[void]$row.SubItems.Add($_.LastWriteTime.Tostring())
		[void]$listView1.Items.Add($row)
	}
}


#--------------------------------------------
# Directory Paths
#--------------------------------------------
#$rootFolder = "C:\Projects\"
#$rootDir = "C:\Projects\"
$rootDir = "\\IPADDRESS\Server\Share\"
$rootFolder = '\\IPADDRESS\Server\Share\'
# get an array of subfolder objects in the $rootFolder
$subfolders = Get-SubDirectories
#$projectName = Read-Host "Enter the name of the project"
$adminDir = "\Admin\"
$projMgmtDir = "\Proj Mgmt\"
$techDir = "\Tech\"

#--------------------------------------------
# Sub-Directory Paths
#--------------------------------------------
$subDir = 'Admin', 'Proj Mgmt', 'Tech'
$subDirAdmin = 'Closeout', 'Contacts', 'Corresp', 'Guide', 'Mtg Min', 'Permits-Approvals', 'Reports', 'Reviews', 'Schedule', 'Submissions'
$subDirProjMgmt = 'Budget', 'Contract', 'Invoices', 'Proposals', 'Subc Agreements'

#--------------------------------------------
# Groups and Permissions
#--------------------------------------------

#Root folder
$AccessRule_PrjAccAll = New-Object System.Security.AccessControl.FileSystemAccessRule('Contoso\Group', 'ReadAndExecute', "None", "None", 'Allow')
$AccessRule_ITAdminsFull = New-Object System.Security.AccessControl.FileSystemAccessRule('Contoso\Group', 'FullControl', "ContainerInherit,ObjectInherit", 'none', 'Allow')
$AccessRule_IT = New-Object System.Security.AccessControl.FileSystemAccessRule('Contoso\Group', 'DeleteSubdirectoriesAndFiles, Write, ReadAndExecute ', "ContainerInherit,ObjectInherit", 'none', 'Allow')
$AccessRule_Administrator = New-Object System.Security.AccessControl.FileSystemAccessRule('Contoso\Group', 'FullControl', "ContainerInherit,ObjectInherit", 'none', 'Allow')
$AccessRule_BuiltInAdministrators = New-Object System.Security.AccessControl.FileSystemAccessRule('BUILTIN\ADMINISTRATORS', 'FullControl', "ContainerInherit,ObjectInherit", 'none', 'Allow')

#Admin Folder
$AccessRule_DomainUsers = New-Object System.Security.AccessControl.FileSystemAccessRule('Contoso\Group', 'DeleteSubdirectoriesAndFiles, Write, ReadAndExecute', "ContainerInherit,ObjectInherit", 'none', 'Allow')
$AccessRule_DomainUsers_folderOnly = New-Object System.Security.AccessControl.FileSystemAccessRule('Contoso\Group', 'ReadAndExecute', "none", 'none', 'Allow')

#ProjMgmt Folder
$AccessRule_ProjMgmtFolder = New-Object System.Security.AccessControl.FileSystemAccessRule('Contoso\Group', 'DeleteSubdirectoriesAndFiles, Write, ReadAndExecute', "ContainerInherit,ObjectInherit", 'none', 'Allow')
$AccessRule_ProjMgmtFolder_folderOnly = New-Object System.Security.AccessControl.FileSystemAccessRule('Contoso\Group', 'ReadAndExecute', "none", 'none', 'Allow')






#Sample function that provides the location of the script
function Get-ScriptDirectory
{
<#
	.SYNOPSIS
		Get-ScriptDirectory returns the proper location of the script.

	.OUTPUTS
		System.String
	
	.NOTES
		Returns the correct path within a packaged executable.
#>
	[OutputType([string])]
	param ()
	if ($null -ne $hostinvocation)
	{
		Split-Path $hostinvocation.MyCommand.path
	}
	else
	{
		Split-Path $script:MyInvocation.MyCommand.Path
	}
}


#Sample variable that provides the location of the script
[string]$ScriptDirectory = Get-ScriptDirectory


