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



$ordinals = @("first", "second", "third", "fourth", "fifth", "sixth", "seventh", "eighth")
Write-Host @"
`n
--TODO--COMPANYNAME--TODO-- controls several subnets. These networks and their constituent machines are described below.
"@
Foreach ($i in 0..($subnets.Length-1)) {
    $cidr = $subnets[$i][0] -replace "\d+$","0/24" # TODO extend to more than /24 networks
    Write-Host ("`nThe " + $ordinals[$i] + " subnet is $cidr. It contains the following machines:")
    Foreach ($ip in $subnets[$i]) {
        Write-Host "    $ip"
    }
}
