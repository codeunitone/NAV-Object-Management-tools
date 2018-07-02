<#
.SYNOPSIS

This script export Objects as TXT.

.Description

Exports objects from a NAV database as TXT into a givin target folder. The script creates subfolders for each object type inside the target folder.

.PARAMETER dbServerName

Server name where the NAV database is located

.PARAMETER dbName

Name of the NAV database

.PARAMETER targetFolder

The exported objects will be stored at this location

.PARAMETER tempExportPath

Filtered Objects will be exported into one big txt file and afterwards splited and moved into Subfolders. This parameter defines the location of that export file.

.PARAMETER objFilterList

Text Array of Objects to export. 

.EXAMPLE

Following example exports from the database NAV2018-DEV (located on GWS-NAV-2018QA) all tables within the range of 50000 till 50005 and all pages within the range of 40 and 50.

.\src\Export-NAVObjects.ps1 -dbServerName "GWS-NAV-2018QA" -dbName "NAV2018-DEV" -targetFolder "C:\Temp\NAV-6694\split\" -objFilterList "Type=Table;Id=50000..50005","Type=Page;Id=40..50"

.NOTES

You have to have NAV 2018 Development Shell installed

#>

param (
	[Parameter(Mandatory=$true)] [string] $dbServerName,
	[Parameter(Mandatory=$true)] [string] $dbName,
	[Parameter(Mandatory=$true)] [string] $targetFolder,
	[Parameter(Mandatory=$true)] [string] $tempExportPath,
	[Parameter(Mandatory=$true)] [string[]] $objFilterList
)

&'C:\Program Files (x86)\Microsoft Dynamics NAV\110\RoleTailored Client\NavModelTools.ps1'

# create temp. export folder
if ((Test-Path -Path $tempExportPath)) {
	remove-item -Path $tempExportPath -Recurse
}
New-Item $tempExportPath -ItemType Directory -Force

# export filtered objects to temp. path
$i = 0
foreach ($filter in $objFilterList) {
	$i++
	$exportFile = Join-Path $tempExportPath -ChildPath "temp$i.txt"
	Export-NAVApplicationObject -DatabaseServer $dbServerName -DatabaseName $dbName -Path $exportFile -Filter $filter -Force
	Split-NAVApplicationObjectFile -Source $exportFile -Destination $tempExportPath -Force
	Remove-Item $exportFile	
}

# Move exported object to target folder
foreach ($file in $(Get-ChildItem $tempExportPath -Filter "*.TXT")) {
	# define subfolders name
	$objType = $file.Name.Substring(0,3)
	switch ($objType) {
		"TAB" { $objTypeFull = "Table" }
		"PAG" { $objTypeFull = "Page" }
		"COD" { $objTypeFull = "Codeunit" }
		"QUE" { $objTypeFull = "Queue" }
		"XML" { $objTypeFull = "XMLport" }
		"REP" { $objTypeFull = "Report" }
		"MEN" { $objTypeFull = "MenuSuite" }
	}

	# create target folder if does not exist yet
	$destinationFolder = Join-Path $targetFolder -ChildPath "$objTypeFull"

	if (!$(Test-Path -Path $destinationFolder)) {
		New-Item $destinationFolder -ItemType Directory
	}

	# copy files from temp export folder to target folder
	$destinationFile = Join-Path $destinationFolder -ChildPath $File.Name
	Move-Item $file.FullName -Destination $destinationFile -Force
}