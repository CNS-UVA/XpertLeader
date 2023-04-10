Function Build-Subnet {
    
    While ($ipPrefix -notmatch "^(\d{1,3}\.){2}\d{1,3}\.?$") {
        $ipPrefix = Read-Host "What's a subnet?"
        $ipPrefix = $ipPrefix -Replace "\.$",""
        If ($ipPrefix -eq "") {
            Return @()
        }
    }

    $ips = @()
    Do {
        While ($true) {
            While ($true) {
                $machineID = Read-Host "$ipPrefix."
                If ($machineID -match "^(\d{1,3})?$"){
                    Break
                }
                Write-Host "WRONG FORMAT"
            }
            If ($machineID -eq "") {
                Break
            }
            $ips += $ipPrefix + "." + $machineID
        } 
        $confirm = Read-Host "Are you sure about that?"
    } While ($confirm -ne "")
    $ips = $ips | sort -Unique -Property { [int]($_ -Replace "^.*\.(\d{1,3})$","`$1") } 
    Return $ips

}

Function Find-Services {
    param(
        $IPs,
        $IncludeServices= @()
    )
    
    $activeServices = @{} # ip -> services
    $ips | % { $activeServices[$_] = @() }

    $serviceNameToPort.GetEnumerator() | ? {$_.Key -in $IncludeServices} | % { 
        
        New-NetFirewallRule -DisplayName "servicetest" -Name "servicetest" -Protocol TCP -Direction Outbound -Action Allow -RemotePort $_.Value 
        Foreach ($ip in $IPs) {
            $connResult = Test-NetConnection -ComputerName $ip -Port $_.Value
            If ($connResult.TcpTestSucceeded) {
                $activeServices[$ip] += $_.Value
            }
        }

    }
    Return $activeServices
}


Write-Host "To use this, type the prefix for your subnet, then the ips in it. If you can't figure it out, ask Grant."
$ips = @()
$subnets = @()
While ($true) { 
    $subnet = Build-Subnet
    If ($subnet.Length -eq 0) {
        Break
    }
    $subnets+= , $subnet
    $ips += $subnet
} 

$serviceNameToPort = @{
        "smtp" = 25;
        "pop3" = 110;
        "imap" = 143;
        "ftp" = 21;
        "ssh" = 22;
        "smb" = 445;
        "rpc" = 135;
        "winrm" = 5985;
        "winrms" = 5986
        "mysql" = 3306;
        "postgresql" = 5432;
        "nfs" = 111;
        "http" = 80;
        "https" = 443
        "rdp" = 3389;
        "ldap" = 389;
        "dns" = 53;
        }
$servicePortToName = @{}
$serviceNameToPort.GetEnumerator() | % { $servicePortToName[$_.Value] = $_.Key }


Write-Host "Scan Network for services? If your name matches /^[^G]/, this is not recommended."
$scanForServices = Read-Host "y/N"

$services = @()
If ($scanForServices -eq "y") {
    While ($true) {
        $service = Read-Host "Service Name?"
        If ($service -eq "") {
           Break
        }
        If ($service -in $serviceNameToPort.Keys) {
            $services += $service
        } Else {
            Write-Host ("Wrong Service. Valid Services are:`n" + $serviceNameToPort.Keys)
        }
    } 
    $activeServices = Find-Services -IPs $ips -IncludeServices $services
}


$ordinals = @("first", "second", "third", "fourth", "fifth", "sixth", "seventh", "eighth")
Write-Host @"
`n
--TODO--COMPANYNAME--TODO-- controls several subnets. These networks and their constituent machines are described below.
"@
Foreach ($i in 0..($subnets.Length-1)) {
    $cidr = $subnets[$i][0] -replace "\d+$","0/24" # TODO extend to more than /24 networks
    Write-Host ("`nThe " + $ordinals[$i] + " subnet is $cidr. It contains the following machines:")
    Foreach ($ip in $subnets[$i]) {
        Write-Host "    $ip" -NoNewline
        If ($services -ne @()) {
            Write-Host ", which is running the following services:"  
            Foreach ($servicePort in $activeServices[$ip]) {
                Write-Host ("        " + $servicePortToName[$servicePort] +" ($servicePort)")        
            }
        
            
        }
        Write-Host ""
    }
}

