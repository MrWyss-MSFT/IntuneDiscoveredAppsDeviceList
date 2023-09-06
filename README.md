# Intune Discovered Appss Device List

This is a fork of [pstakuu/intunedetectedapps](https://github.com/pstakuu/intunedetectedapps)

Some minor changes were made to the script to make it work with MGGraph, some modification to the progress output and the addition of a filter to only get the apps you want.

## How to use

modify the following lines in the script to match your environment and your goals

```powershell
# Changes Here
Connect-MgGraph -Scopes "DeviceManagementApps.Read.All" -Verbose -TenantId "yourtenant.onmicrosoft.com"
$AppFilter = "contains(displayName, 'Your App Name')"
$outputFile = "C:\temp\IntuneDetectedAppsManagedDevices.csv"
```
