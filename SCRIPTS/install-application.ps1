<#
Connection String:
BlobEndpoint=https://sts3rus.blob.core.windows.net/;QueueEndpoint=https://sts3rus.queue.core.windows.net/;FileEndpoint=https://sts3rus.file.core.windows.net/;TableEndpoint=https://sts3rus.table.core.windows.net/;SharedAccessSignature=sv=2019-12-12&ss=b&srt=o&sp=rwx&se=2021-03-29T22:48:02Z&st=2020-10-29T14:48:02Z&spr=https&sig=1p5NWV1NTj8jKy2X0ssDTEfAuSUI1KsuL753N9ixm0g%3D

SAS token: good through 03/29/2021
?sv=2019-12-12&ss=b&srt=o&sp=rwx&se=2021-03-29T22:48:02Z&st=2020-10-29T14:48:02Z&spr=https&sig=1p5NWV1NTj8jKy2X0ssDTEfAuSUI1KsuL753N9ixm0g%3D

Blob service SAS URL:
https://sts3rus.blob.core.windows.net/?sv=2019-12-12&ss=b&srt=o&sp=rwx&se=2021-03-29T22:48:02Z&st=2020-10-29T14:48:02Z&spr=https&sig=1p5NWV1NTj8jKy2X0ssDTEfAuSUI1KsuL753N9ixm0g%3D

#>

$saskey = '?sv=2019-12-12&ss=b&srt=o&sp=rwx&se=2021-03-29T22:48:02Z&st=2020-10-29T14:48:02Z&spr=https&sig=1p5NWV1NTj8jKy2X0ssDTEfAuSUI1KsuL753N9ixm0g%3D'

New-Item -Path "c:\" -Name "installs" -ItemType "directory"

$installers = @()

#source files for installations
$filelist = @()
$filelist += "https://sts3rus.blob.core.windows.net/artifacts/npp.7.9.Installer.exe"
#$filelist += "https://sts3rus.blob.core.windows.net/artifacts/CrewPlanning20200912/S3RUSCrewPlanningSystemSetup.msi"
$filelist += "https://sts3rus.blob.core.windows.net/artifacts/CrewPlanning20201023/S3RUSCrewPlanningSystemSetup.msi"
$filelist += "https://sts3rus.blob.core.windows.net/artifacts/PairingEditor20200726/S3RUSPairingEditorSetup.msi"
#$filelist += "https://sts3rus.blob.core.windows.net/artifacts/CrewPlanningUpdates/2020_09%20S3RUS%20System%20Update_mt.exe"
$filelist += "https://sts3rus.blob.core.windows.net/artifacts/CrewPlanningUpdates/2020_10%20S3RUS%20System%20Update_NoBidlines.exe"
$filelist += "https://sts3rus.blob.core.windows.net/artifacts/FreeCommanderXE-32-public_810a.msi"
$filelist += "https://sts3rus.blob.core.windows.net/artifacts/OneDriveSetup.exe"
$filelist += "https://sts3rus.blob.core.windows.net/artifacts/TableauReader-64bit-2020-3-1.exe"
$filelist += "https://sts3rus.blob.core.windows.net/artifacts/ComparePlugin_v2.0.1_x86.zip"

#source files for app setting updates
$appfiles = @()
$appfiles += "https://sts3rus.blob.core.windows.net/artifacts/New%20Files/addparms.txt"
$appfiles += "https://sts3rus.blob.core.windows.net/artifacts/New%20Files/PairingCategories.txt"
$appfiles += "https://sts3rus.blob.core.windows.net/artifacts/New%20Files/RunEngineOutputFiles.xml"
$appfiles += "https://sts3rus.blob.core.windows.net/artifacts/New%20Files/S3RUSMasterRule.txt"
$appfiles += "https://sts3rus.blob.core.windows.net/artifacts/New%20Files/S3RUSMasterRule.xml"

function Get-Installer {
    param (
        $url
    )

    $filename =  split-path $url -leaf
    $output = "c:\installs\$filename"
    $script:installers += $output
    $url = $url + $script:saskey
    Invoke-WebRequest -Uri $url -OutFile $output
}

foreach ($file in $filelist){
    Get-Installer $file
}

foreach ($msi in $installers) {
    $file = split-path $msi -leaf
    if ($file.split('.')[-1] -eq "msi" ){
        msiexec /i $msi /q /l+iwearmo c:\installs\install.log AllUsers=1
    }

}

#fire off the non-msi installers
start-process -FilePath "c:\installs\npp.7.9.Installer.exe" -ArgumentList '/S' -Verb runas
#start-process -FilePath "c:\installs\2020_09%20S3RUS%20System%20Update_mt.exe" -ArgumentList '-silent' -Verb runas
start-process -FilePath "c:\installs\2020_10%20S3RUS%20System%20Update_NoBidlines.exe" -ArgumentList '-silent' -Verb runas
start-process -FilePath "c:\installs\OneDriveSetup.exe" -ArgumentList '/allusers' -Verb runas
start-process -FilePath "c:\installs\TableauReader-64bit-2020-3-1.exe" -ArgumentList '/quiet /norestart ACCEPTEULA=1' -Verb runas

Expand-Archive -LiteralPath "c:\installs\ComparePlugin_v2.0.1_x86.zip" -DestinationPath "C:\Program Files (x86)\Notepad++\plugins\ComparePlugin"

#update the application files after installation
function update-appfiles {
    param (
        $url
    )

    $filename =  split-path $url -leaf
    $output = "C:\Program Files (x86)\S3RUS\S3RUS Crew Planning System\DataFiles\$filename"
    $url = $url + $script:saskey
    Invoke-WebRequest -Uri $url -OutFile $output
}

foreach ($app in $appfiles){
    update-appfiles $app    
}

#this file needs to overwrite the default file
$users = "https://sts3rus.blob.core.windows.net/artifacts/CrewPlanningUpdates/Users.txt"
$uri = $users + $saskey
Invoke-WebRequest -Uri $uri `
    -OutFile "C:\Program Files (x86)\S3RUS\S3RUS Crew Planning System\Users\Users.txt"

#adds registry key allowing multiple sessions to session host.
$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server"
$Name = "fSingleSessionPerUser"
$value = "0"

Set-ItemProperty -Path $registryPath -Name $name -Value $value | Out-Null

# Create a Desktop Shortcut to the File Share
$TargetPath = "\\azuse2prodinfrafile1.file.core.windows.net\crewoptimization"
$ShortcutFile = "$env:Public\Desktop\crewoptimization.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = $TargetPath
$Shortcut.Save()

Set-TimeZone -Id "Eastern Standard Time" -PassThru

