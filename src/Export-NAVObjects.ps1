param (
	[Parameter(Mandatory=$true)] [string] $dbServerName,
	[Parameter(Mandatory=$true)] [string] $dbName,
	[Parameter(Mandatory=$true)] [string] $targetFolder,
	[Parameter(Mandatory=$true)] [string] $tempExportPath,
	[Parameter(Mandatory=$true)] [string[]] $objFilterList
)

# About
# - script creates subfolder in $targetFolder for each object type
# - You have to have NAV 2018 Development Shell installed


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