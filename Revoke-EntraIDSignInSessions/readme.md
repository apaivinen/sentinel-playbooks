# Revoke-EntraIDSignInSessions WORK IN PROGRESS
- Original source: https://github.com/Azure/Azure-Sentinel/tree/master/Solutions/Microsoft%20Entra%20ID/Playbooks/Revoke-AADSignInSessions
- Original author: Nicholas DiCola

Modification by: Anssi Päivinen

# MODIFICATION 2024
Original revoke sessions not used. Incident trigger was broken.
Re-did the logic app. Need to write the documentation and do alert & entity trigger logic apps. 


# Description

## ToDo
1. Create Graph powershell script to assign permissions for managed identity
2. Create a bicep template 

## Files
- Revoke-EntraIDSignInSessions.json
- Revoke-EntraIDSignInSessions.bicep
- Revoke-EntraIDSignInSessions.ps1

# Prequisites
1. Sentinel workspace
2. AzureAD Powershell module

# Post-deployment
1. Assign Sentinel Responder role to Managed identity created by Logic App.
2. Assign `User.ReadWrite.All` Graph API permission to managed Identity

## Powershell for grating permissions for Managed identity

```powershell
$MIGuid = "<Enter your managed identity guid here>"
$MI = Get-AzureADServicePrincipal -ObjectId $MIGuid

$GraphAppId = "00000003-0000-0000-c000-000000000000"
$PermissionName = "User.ReadWrite.All" 

$GraphServicePrincipal = Get-AzureADServicePrincipal -Filter "appId eq '$GraphAppId'"
$AppRole = $GraphServicePrincipal.AppRoles | Where-Object {$_.Value -eq $PermissionName -and $_.AllowedMemberTypes -contains "Application"}
New-AzureAdServiceAppRoleAssignment -ObjectId $MI.ObjectId -PrincipalId $MI.ObjectId `
-ResourceId $GraphServicePrincipal.ObjectId -Id $AppRole.Id
```

# Changes
|Date|Description|
|--|--|
|2023-12-21|Initial development|
|2024-01-13|Creating playbooks|