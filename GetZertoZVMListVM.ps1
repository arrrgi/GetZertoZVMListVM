# Begin script block

## Fetch information needed to attach to Zerto ZVM API endpoint
## Set default values if none are passed
### validate IP address entered in correct format using system library otherwise default to localhost
try {
    $zertoZVMIP = Read-Host "Please enter the IP address of the ZVM to connect to"
    if ([string]::IsNullOrWhiteSpace($zertoZVMIP)) {
        $zertoZVMIP = 'localhost'
    }
    else {
        [IPAddress] $zertoZVMIP 
    }
}
catch {
    # Send message to console that IP address was entered incorrectly
    Write-Output "An invalid IP address was entered, exiting."
}

$zertoZVMPort = Read-Host "Please enter the Zerto ZVM API TCP port to connect to (default: '9669')"
### if no port was entered, use the default
if ([string]::IsNullOrWhiteSpace($zertoZVMPort))
{
    $zertoZVMPort = '9669'
}

$credentialType = [System.Management.Automation.PSCredentialTypes]::Domain
$validateOption = [System.Management.Automation.PSCredentialUIOptions]::ValidateUserNameSyntax
$zertoCredentials = $host.ui.PromptForCredential("Zerto access credentials", "Please enter your domain credentials", "", "", $CredentialType, $ValidateOption)

## CSV Output folder location helper
### Create Folder browser model
Add-Type -AssemblyName System.Windows.Forms
$folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog -Property @{
    RootFolder = "MyComputer"
    Description = "Select a location for CSV output"    
}
### Set model properties to force dialog to foreground 
$windowProps = New-Object System.Windows.Forms.Form -Property @{
    Topmost = $true
    MinimizeBox = $true
}
$folderBrowser.ShowDialog($windowProps) | Out-Null


## Setting Certificate Policy to accept self-signed certificates from the ZVM
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

## Build Zerto ZVM API connection string
$baseURL = "https://" + $zertoZVMIP + ":" + $zertoZVMPort + "/v1/"
$authURL = $baseURL + "session/add"
$vmListURL = $baseURL + "vms"
$zertoAuthInfo = ("{0}:{1}" -f $zertoCredentials.UserName, $zertoCredentials.Password)
$zertoAuthInfo = [System.Text.Encoding]::UTF8.GetBytes($zertoAuthInfo)
$zertoAuthInfo = [System.Convert]::ToBase64String($zertoAuthInfo)
$requestHeaders = @{Authorization=("Basic {0}" -f $zertoAuthInfo)}
$sessionBody = '{AuthenticationMethod: "1"}'
$contentType = "application/json"

## Invoke API Request for authentication token
$getZertoSessionResponse = Invoke-WebRequest -Uri $authURL -Headers $requestHeaders -Method POST -Body $sessionBody -ContentType $contentType

## Store Zerto session ID
$zertoSessionID = $getZertoSessionResponse.headers.get_item("x-zerto-session")
$zertoSessionHeader = @{"x-zerto-session"=$zertoSessionID}

## Query API for VM list
$vmListResponse = Invoke-RestMethod -Uri $vmListURL -TimeoutSec 100 -Headers $zertoSessionHeader -ContentType $contentType
$vmListData = $vmListResponse | Select-Object VmName, VpgName, UsedStorageInMB, SourceSite, TargetSite, Priority
$vmListData | Export-Csv -Path $folderBrowser.SelectedPath + "\VM-List.csv" -UseQuotes AsNeeded  
