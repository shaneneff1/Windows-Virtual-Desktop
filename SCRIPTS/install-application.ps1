New-Item -Path "c:\" -Name "installs" -ItemType "directory"

$installers = @()

#source files for installations
$filelist = @()
$filelist += "https://stneffwvd.blob.core.windows.net/artifacts/npp.7.9.Installer.exe"
$filelist += "https://stneffwvd.blob.core.windows.net/artifacts/CrewPlanning20200912/neffwvdCrewPlanningSystemSetup.msi"
$filelist += "https://stneffwvd.blob.core.windows.net/artifacts/PairingEditor20200726/neffwvdPairingEditorSetup.msi"
$filelist += "https://stneffwvd.blob.core.windows.net/artifacts/CrewPlanningUpdates/2020_09%20neffwvd%20System%20Update_mt.exe"
$filelist += "https://stneffwvd.blob.core.windows.net/artifacts/FreeCommanderXE-32-public_810a.msi"
$filelist += "https://stneffwvd.blob.core.windows.net/artifacts/OneDriveSetup.exe"
$filelist += "https://stneffwvd.blob.core.windows.net/artifacts/TableauReader-64bit-2020-3-1.exe"

#source files for app setting updates
$appfiles = @()
$appfiles += "https://stneffwvd.blob.core.windows.net/artifacts/New%20Files/addparms.txt"
$appfiles += "https://stneffwvd.blob.core.windows.net/artifacts/New%20Files/PairingCategories.txt"
$appfiles += "https://stneffwvd.blob.core.windows.net/artifacts/New%20Files/RunEngineOutputFiles.xml"
$appfiles += "https://stneffwvd.blob.core.windows.net/artifacts/New%20Files/neffwvdMasterRule.txt"
$appfiles += "https://stneffwvd.blob.core.windows.net/artifacts/New%20Files/neffwvdMasterRule.xml"

function Get-Installer {
    param (
        $url
    )

    $filename =  split-path $url -leaf
    $output = "c:\installs\$filename"
    $script:installers += $output
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
start-process -FilePath "c:\installs\2020_09%20neffwvd%20System%20Update_mt.exe" -ArgumentList '-silent' -Verb runas
start-process -FilePath "c:\installs\OneDriveSetup.exe" -ArgumentList '/allusers' -Verb runas
start-process -FilePath "c:\installs\TableauReader-64bit-2020-3-1.exe" -ArgumentList '/quiet /norestart ACCEPTEULA=1' -Verb runas

#update the application files after installation
function update-appfiles {
    param (
        $url
    )

    $filename =  split-path $url -leaf
    $output = "C:\Program Files (x86)\neffwvd\neffwvd Crew Planning System\DataFiles\$filename"
    Invoke-WebRequest -Uri $url -OutFile $output
}

foreach ($app in $appfiles){
    update-appfiles $app    
}

#this file needs to overwrite the default file - not sure if this command does that.
Invoke-WebRequest -Uri "https://stneffwvd.blob.core.windows.net/artifacts/CrewPlanningUpdates/Users.txt" `
    -OutFile "C:\Program Files (x86)\neffwvd\neffwvd Crew Planning System\Users\Users.txt"

#adds registry key allowing multiple sessions to session host.
$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server"
$Name = "fSingleSessionPerUser"
$value = "0"

Set-ItemProperty -Path $registryPath -Name $name -Value $value | Out-Null