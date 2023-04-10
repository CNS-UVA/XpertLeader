cd C:\
$ProgressPreference = "SilentlyContinue"
[Net.ServicePointManager]::SecurityProtocol = "tls12"
iwr("tinyurl.com/uvaccdcwinlogbeat") -OutFile wb.zip
Add-Type -AssemblyName System.IO.Compression.FileSystem
spsv winlogbeat
[System.IO.Compression.ZipFile]::ExtractToDirectory("C:\wb.zip","C:\wb\")
cd C:\wb
ls | cd
.\install-service-winlogbeat.ps1
# Get wb
.\winlogbeat.exe setup -e
sasv winlogbeat
Restart-Service winlogbeat
netstat -aon | findstr 9200
