# Block-EntraIDUser WORK IN PROGRESS

# Description
Just a simple Block entra id user from signin in playbook for Microsoft Sentinel.  
This playbook utilizes Microsoft Graph via managed identity.

 A global administrator assigned the Directory.AccessAsUser.All delegated permission can update the accountEnabled status of all administrators in the tenant.

res folder contains [Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/) for Azure resources. Rest of the files are by author.

### Outline for entity trigger
1. Logic app triggered from entity
2. User is blocked by using [Update user](https://learn.microsoft.com/en-us/graph/api/user-update) endpoint property `accountEnabled`
3. Check if incident ID is null. If yes terminate the logic app run
4. If incident ID is present then get users manager by using [List Manager](https://learn.microsoft.com/en-us/graph/api/user-list-manager) endpoint
5. Parse the results and respond to incident with comment

![Logic App Outline](.\img\LogicAppOutline.png)

### Outline for incident trigger
1. Logic app triggered from incident
2. Loop through users
2. Users are blocked by using [Update user](https://learn.microsoft.com/en-us/graph/api/user-update) endpoint property `accountEnabled`
4. Get managers for indivinidual users by using [List Manager](https://learn.microsoft.com/en-us/graph/api/user-list-manager) endpoint
5. Parse the results and respond to incident with comment, one comment for each user

## ToDo
3. Create a bicep template 

## Files
- main.bicep
- entity.bicepparam
- incident.bicepparam

# Prequisites
- Azure Subscription with resource group for logic app
- User.ManageIdentities.All permission (or global admin)
- Powershell with [MicrosoftGraph Powershell SDK](https://learn.microsoft.com/en-us/powershell/microsoftgraph/installation?view=graph-powershell-1.0)


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


# Changes
|Date|Description|
|--|--|
|2023-12-21|Initial development|
|2024-04-11|Created bicep files|
|2024-04-15|Initial readme|