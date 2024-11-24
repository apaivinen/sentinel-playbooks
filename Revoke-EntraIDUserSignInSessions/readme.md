# Revoke-EntraIDUserSignInSessions

This is just a simple revoke user sign in sessions playbook for incident and entity triggers.  
More detailed description can be found [here](https://www.anssipaivinen.fi/posts/Revoke-User-Sign-In-Sessions-by-Logic-App-Sentinel-Playbook/)

# Description

Both of the playbook templates creates following Azure resources:
- Logic App
- Managed identity for Logic App
- Microsoft Sentinel API connection for Managed Identity



## Incident Trigger
1. Trigger: When incident is triggered
2. Get account entities from incident
3. Loop through accounts
4. Compose UPN
5. Revoke user session
6. Add comment to sentinel incident

![](./images/Revoke-EntraIDUserSignInSessions-Incident-outline.png)

## Entity Trigger
1. Trigger: Microsoft Sentinel entity
2. Compose - concat UPN
3. HTTP - Revoke sessions
4. Add comment to incident (V3)

![](./images/Entity-trigger-revoke-sessions.png)

# Prequisites
1. Sentinel workspace
3. Resource group for playbooks
2. [MgGraph powershell module](https://learn.microsoft.com/en-us/powershell/microsoftgraph/get-started?view=graph-powershell-1.0)

Deploy bicep files depending on which trigger you want to check out
- incident.bicep
- entity.bicep

Deployment commmands
```powershell
az deployment group create --name "Revoke-Session-INC-1" --resource-group "YOU-RG-HERE" --template-file incident.bicep
az deployment group create --name "Revoke-Session-ENT-1" --resource-group "YOU-RG-HERE" --template-file incident.bicep
```

# Post-deployment
1. Assign Sentinel Responder role to Managed identity created by Logic App.
    - Required for both logic apps
2. Assign `User.ReadWrite.All` Graph API permission to managed Identity

## Powershell for grating permissions for Managed identity

```powershell

# Add the correct 'Object (principal) ID' for the Managed Identity
$ObjectId = "OBJECTID"

# Add the correct Graph scope to grant
$graphScope = "User.ReadWrite.All"

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
|2024-01-13|Creating playbooks and readme|