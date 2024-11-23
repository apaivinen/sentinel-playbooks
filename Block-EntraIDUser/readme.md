# Block-EntraIDUser

# Description
Just a simple playbook for blocking entra id account from signin-in.  
Here's bicep templates for Entity and Incident triggers

Remember to update following params in bicep file:
- servicePrefix
- createdBy
### Outline for incident trigger
1. Logic app triggered from incident
2. Gets accounts
3. Initializes Arrays for reply (Success & Error)
4. Loops through accounts
5. Users are blocked by using [Update user](https://learn.microsoft.com/en-us/graph/api/user-update) endpoint property `accountEnabled`
    - If `HTTP - Block user` is successful append success text to success array
    - If `HTTP - Block user` failes then append error text to error array
6. Comment to incident with success & error array results


![Logic App Outline](.\img\Incident-outline-1.png)
![Logic App Outline](.\img\Incident-outline-2.png)

### Outline for entity trigger
1. Logic app triggered from entity
2. User is blocked by using [Update user](https://learn.microsoft.com/en-us/graph/api/user-update) endpoint property `accountEnabled`
3. ???
4. yeah it's done. (or atleast should be...)

![Logic App Outline](.\img\Entity-outline.png)


## Files
- Entity
    - main.bicep
- Incident
    - main.bicep


# Prequisites
- Azure Subscription with resource group for logic app
- User.ManageIdentities.All permission (or global admin)
- Powershell with [MicrosoftGraph Powershell SDK](https://learn.microsoft.com/en-us/powershell/microsoftgraph/installation?view=graph-powershell-1.0)


# Post-deployment

1. Add sentinel responder role to Block-EntraIdUser-Incident managed identity
2. Assign permissions to managed identity, see powershell bellow
```powershell
# Add the correct 'Object (principal) ID' for the Managed Identity
$ObjectId = "OBJECTID"

# Add the correct Graph scopes to grant (multiple scopes)
$graphScopes = @(
    "User.ManageIdentities.All", 
    "User.EnableDisableAccount.All"
)

# Connect to Microsoft Graph
Connect-MgGraph -Scope AppRoleAssignment.ReadWrite.All

# Get the Graph Service Principal
$graph = Get-MgServicePrincipal -Filter "AppId eq '00000003-0000-0000-c000-000000000000'"

# Loop through each scope and assign the role
foreach ($graphScope in $graphScopes) {
    # Find the corresponding AppRole for the current scope
    $graphAppRole = $graph.AppRoles | Where-Object { $_.Value -eq $graphScope }

    if ($graphAppRole) {
        # Prepare the AppRole Assignment
        $appRoleAssignment = @{
            "principalId" = $ObjectId
            "resourceId"  = $graph.Id
            "appRoleId"   = $graphAppRole.Id
        }

        # Assign the role
        New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $ObjectId -BodyParameter $appRoleAssignment | Format-List
        Write-Host "Assigned $graphScope to Managed Identity $ObjectId"
    } else {
        Write-Warning "AppRole for scope '$graphScope' not found."
    }
}


```


# Changes
|Date|Description|
|--|--|
|2023-12-21|Initial development|
|2024-04-11|Created bicep files|
|2024-04-15|Initial readme|
|2024-11-24|Created incident and entity playbooks & updated bicep files|