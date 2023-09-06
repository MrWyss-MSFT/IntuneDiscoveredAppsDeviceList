# Install the module from the PowerShell Gallery
# Required only once
Install-Module "Microsoft.Graph.Authentication" -Force

# Import the module
Import-Module "Microsoft.Graph.Authentication"

# Connect to Microsoft Graph
# Authenticate with a popup window, you might need to consent to the application permissions
Select-MgProfile -Name "beta"

# Changes Here
Connect-MgGraph -Scopes "DeviceManagementApps.Read.All" -Verbose -TenantId "yourtenant.onmicrosoft.com"
$AppFilter = "contains(displayName, 'Your App Name')"
$outputFile = "C:\temp\IntuneDetectedAppsManagedDevices.csv"


$uri = "https://graph.microsoft.com/beta/deviceManagement/detectedApps/?`$filter=$AppFilter"

# Fetch all filtered detected apps
$detectedApps = Invoke-MgGraphRequest -Method Get -Uri $Uri

function Get-DetectedApps {
    $detectedApps.value
    if ($detectedApps.'@odata.nextLink') {
        $detectedApps.'@odata.nextLink' -match "skip=(.*)" | out-null
        [int]$skipValue = $Matches[1]

        $totalValue = $detectedApps.'@odata.count' - $detectedApps.'@odata.count' % $skipValue + $skipValue
        for ($i = $skipValue; $i -lt $totalValue; $i += $skipValue) {
            $moreObj = Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/deviceManagement/detectedApps/?`$skip=$i" -Method Get 
            $moreObj.value
        }
    }
}

$allDetectedApps = Get-DetectedApps
function Get-DetectedAppsManagedDevices ($allDetectedApps) {
    $count = 0
    foreach ($app in $allDetectedApps) {
        Write-Progress -Id 0 -PercentComplete ($count / ($AlldetectedApps.Count * 100)) -Status "$count of $($AlldetectedApps.Count) app: $($app.displayname) Version: $($app.version)" -Activity "Retrieving devices for app"
        $count++
        function Get-ManagedDevicesForApp ($app) {
            $appDevices = Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/deviceManagement/detectedApps/$($app.id)/managedDevices" -Method Get 
            $appDevices.value
            if ($appDevices.'@odata.nextLink') {
                $appDevices.'@odata.nextLink' -match "skip=(.*)" | out-null
                [int]$skipValue = $Matches[1]

                $totalValue = $appDevices.'@odata.count' - $appDevices.'@odata.count' % $skipValue + $skipValue
                for ($i = $skipValue; $i -lt $totalValue; $i += $skipValue) {
                    Write-Progress -id 1 -ParentId 0 -PercentComplete ($i / $totalvalue * 100) -Status "$i of $totalvalue device pages" -Activity "Retrieving next page of devices"
                    $moreObj = Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/deviceManagement/detectedApps/$($app.id)/managedDevices/?`$skip=$i" -Method Get
                    $moreObj.value
                }
                Write-Progress -id 1 -ParentId 0 -Activity "Retrieving next page of device" -Completed
            }
        }
        $devices = Get-ManagedDevicesForApp -app $app

      
        foreach ($device in $devices) {
            $props = [ordered]@{
                appid           = $app.id
                appdisplayname  = $app.displayName
                appversion      = $app.version
                id              = $device.id
                devicename      = $device.devicename
                operatingSystem = $device.operatingsystem
                osversion       = $device.osversion
                emailaddress    = $device.emailaddress
                serialnumber    = $device.serialnumber
                phonenumber     = $device.phonenumber
            }
            $obj = new-object -TypeName psobject -Property $props
            $obj
        }
    }
    Write-Progress -Id 0  -Activity "Retrieving devices for apps" -Completed
}
$fulllist = Get-DetectedAppsManagedDevices -allDetectedApps $allDetectedApps
$fulllist | export-csv $outputFile -NoTypeInformation
