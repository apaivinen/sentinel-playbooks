# Block-EntraIDUser WORK IN PROGRESS
- Original source: https://github.com/Azure/Azure-Sentinel/tree/master/Solutions/Microsoft%20Entra%20ID/Playbooks/Block-AADUser
- Original author: Nicholas DiCola

Modification by: Anssi Päivinen

# Description
Update user, accountEnabled property https://learn.microsoft.com/en-us/graph/api/user-update

 A global administrator assigned the Directory.AccessAsUser.All delegated permission can update the accountEnabled status of all administrators in the tenant.

## ToDo
1. Change all entra id connectors to graph api
2. Create Graph powershell script to assign permissions for managed identity
3. Create a bicep template 
4. use unified email connector

## Files
- Block-EntraIDUser.bicep

# Prequisites

# Post-deployment

1. Add sentinel responder role to Block-EntraIdUser managed identity/identities
2. Assign User Administartor role to managed identity
2. assign permissions to managed identity - OBSOLETE - needs more investigation
```powershell
# Add the 'Object (principal) ID' for the Managed Identity
$ObjectId = "<Enter your managed identity guid here>"

# Add the Graph scope to grant
$graphScope = "User.ManageIdentities.All"

Connect-MgGraph -Scope AppRoleAssignment.ReadWrite.All
$graph = Get-MgServicePrincipal -Filter "AppId eq '00000003-0000-0000-c000-000000000000'"
$graphAppRole = $graph.AppRoles | ? Value -eq $graphScope

$appRoleAssignment = @{
    "principalId" = $ObjectId
    "resourceId"  = $graph.Id
    "appRoleId"   = $graphAppRole.Id
}

New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $ObjectID -BodyParameter $appRoleAssignment | Format-List
```

## Powershell for grating permissions for Managed identity

```powershell
# ~~ Insert script here ~~
```

# Changes
|Date|Description|
|--|--|
|2023-12-21|Initial development|
|2024-04-11|Created bicep files|