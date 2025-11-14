#  Download the latest version of WAC
$parameters = @{
      Source = "https://aka.ms/WACdownload"
      Destination = ".\WindowsAdminCenter.exe"
 }
 Start-BitsTransfer @parameters

# Starts WAC installer in silent mode
Start-Process -FilePath '.\WindowsAdminCenter.exe' -ArgumentList '/VERYSILENT' -Wait