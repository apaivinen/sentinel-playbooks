# Block-EntraIDUser

# Description

### Outline for incident trigger

### Outline for entity trigger

## Files
- Entity
    - main.bicep
- Incident
    - main.bicep

# Prequisites

# Deployment
1. In powershell navigate to entity or incident folder
2. Modify following az deployment command
3. Run the modified az deployment command in powershell
```powershell
 az deployment group create --name "Block-resources" --resource-group "YourRGHere" --template-file main.bicep
```

# Post-deployment - Assign permissions to managed identity

```powershell

# Add the correct 'Object (principal) ID' for the Managed Identity
$ObjectId = "OBJECTID"

# Add the correct Graph scope to grant
$graphScope = "GroupMember.ReadWrite.All"

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
|2024-11-24|Initial project folder|
