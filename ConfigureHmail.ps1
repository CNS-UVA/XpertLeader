

function Configure-Hmail() {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls -bor [Net.SecurityProtocolType]::Ssl3
    Install-WindowsFeature NET-Framework-Core
    C:\hmail.exe /verysilent
    setx /M PATH "$env:PATH;C:\Program Files (x86)\hMailServer\Bin"

}


function Configure-Hmail-Users() {
param (

    $EmailDomain="goose.com",
    $Usernames=@(""), 
    $DefaultPassword="Chiapet1"
)

    $HMS = New-Object -ComObject HMailServer.Application
    $HMS.Authenticate("Administrator", "")
    $NewDomain = $HMS.Domains.Add()
    $NewDomain.Name = $EmailDomain
    $NewDomain.Save()
    
    foreach ($username in $Usernames) {
        $NewAddress = $NewDomain.Accounts.Add()
        $NewAddress.Address = $username + "@" + $EmailDomain
        $NewAddress.Password = $DefaultPassword
        $NewAddress.Active=$true
    }
    $NewDomain.Active = $true
    $NewDomain.Save()
    Restart-Service HmailServer
}
