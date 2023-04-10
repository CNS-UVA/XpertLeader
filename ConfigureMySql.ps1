# Credit to https://www.powershellgallery.com/packages/AppVeyorBYOC/1.0.107-beta/Content/scripts%5CWindows%5Cinstall_mysql.ps1
function Configure-MySQL {
  param (
    $MySqlTemp = "C:\MySqlTemp",
    $MySqlRoot = "$($env:ProgramFiles)\MySQL",
    $MySqlPath = "$mySqlRoot\MySQL Server 8.0",
    $MySqlIniPath = "$mySqlPath\my.ini",
    $MySqlDataPath = "$mySqlPath\data",
    $MySqlServiceName = "MySQL81",
    $MySqlRootPassword = "Chiapet1"
  )

  Set-ExecutionPolicy Bypass -Scope Process -Force; 
  [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;
  iex ((New-Object System.Net.WebClient).DownloadString('https://vcredist.com/install.ps1'))

  
  Write-Host "Installing MySQL Server 8.0" -ForegroundColor Cyan

  $zipPath = "C:\mysql.zip"
  Write-Host "Unpacking..."
  Expand-Archive "C:\mysql.zip" -DestinationPath $mySqlTemp -Force
  New-Item $mySqlRoot -ItemType Directory -Force | Out-Null
  [IO.Directory]::Move("$mySqlTemp\mysql-8.0.32-winx64", $mySqlPath)
  
  Remove-Item $mySqlTemp -Recurse -Force
  del $zipPath

  Write-Host "Installing MySQL..."
  New-Item $mySqlDataPath -ItemType Directory -Force | Out-Null

@"
[mysqld]
basedir=$($mySqlPath.Replace("\","\\"))
datadir=$($mySqlDataPath.Replace("\","\\"))
"@ | Out-File $mySqlIniPath -Force -Encoding ASCII

  Write-Host "Initializing MySQL..."
  cmd /c "`"$mySqlPath\bin\mysqld`" --defaults-file=`"$mySqlIniPath`" --initialize-insecure"

  Write-Host "Installing MySQL as a service..."
  cmd /c "`"$mySqlPath\bin\mysqld`" --install $mySqlServiceName"
  Start-Service $mySqlServiceName
  sc.exe config $mySqlServiceName start=auto

  Write-Host "Setting root password..."
  cmd /c  "`"$mySqlPath\bin\mysql`" -u root --skip-password -e `"CREATE USER 'root'@'%' identified by 'Chiapet1';`""
  cmd /c  "`"$mySqlPath\bin\mysql`" -u root --skip-password -e `"GRANT ALL ON *.* to 'root'@'%';`""
  
  
  cmd /c "`"$mySqlPath\bin\mysql`" -u root --skip-password -e `"ALTER USER 'root'@'localhost' IDENTIFIED BY 'Chiapet1';`""
  
  Restart-Service $mySqlServiceName
  Write-Host "Verifying connection..."
  (cmd /c "`"$mySqlPath\bin\mysql`" -u root --password=`"$mySqlRootPassword`" -e `"SHOW DATABASES;`" 2>&1")

  Write-Host "MySQL Server installed" -ForegroundColor Green
}
