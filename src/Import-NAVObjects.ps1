param (
	[Parameter(Mandatory=$true)] [string] $dbServerName,
	[Parameter(Mandatory=$true)] [string] $dbName,
	[Parameter(Mandatory=$true)] [string[]] $FilePathList
)

& "$(Join-Path ${env:ProgramFiles(x86)} -ChildPath "Microsoft Dynamics NAV\110\RoleTailored Client\NavModelTools.ps1")"

# create temp. folder for import logfolder
[string]$CurrentDataTime = Get-Date -Format s
$CurrentDataTime = $CurrentDataTime -replace ':',''
$CurrentDataTime = $CurrentDataTime -replace 'T','-'

$ImportLogFolder = ".\ImportLog\$CurrentDataTime"
$ImportLogFile = Join-Path -Path $ImportLogFolder -ChildPath "import.log"

if ((Test-Path -Path $ImportLogFolder)) {
	remove-item -Path $ImportLogFolder -Recurse
}
New-Item $ImportLogFolder -ItemType Directory -Force

foreach ($FilePath in $FilePathList) {
	$objFile = Get-Item $FilePath
	Write-Host ''
	Write-Host ('Importing ' + $objFile.Name )
	Write-Host ''

	$ImportSingleFileLog = Join-Path -Path $ImportLogFolder -ChildPath ($objFile.BaseName + ".log")
	Import-NAVApplicationObject -DatabaseServer $dbServerName -DatabaseName $dbName -Path $objFile.FullName -Confirm:$false -ImportAction Overwrite -LogPath $ImportLogFolder 
	
	while (1 -eq 1) {
		if (Test-Path "$ImportLogFolder\navcommandresult.txt") {
			$objFile.Name >> $ImportLogFile
			
			if ((Test-Path -path $ImportSingleFileLog)) {
				[String]$ImportResult = Get-Content $ImportSingleFileLog
				Remove-Item $ImportSingleFileLog
				Write-Host '	FAILED' -ForegroundColor Red
				Write-Host ('	'	+ $ImportResult) -ForegroundColor Red
				'	FAILED' >> $ImportLogFile
				$ImportResult >> $ImportLogFile
			} else { 
				Write-Host '	SUCCESS' -ForegroundColor Green
				'	SUCCESS' >> $ImportLogFile
			}

			Remove-Item "$ImportLogFolder\navcommandresult.txt"
			break
		}
		Start-Sleep -Milliseconds 1
	}
}

