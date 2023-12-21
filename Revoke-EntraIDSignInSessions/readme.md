# Revoke-EntraIDSignInSessions WORK IN PROGRESS
- Original source: https://github.com/Azure/Azure-Sentinel/tree/master/Solutions/Microsoft%20Entra%20ID/Playbooks/Revoke-AADSignInSessions
- Original author: Nicholas DiCola

Modification by: Anssi Päivinen

# Description

## ToDo
1. Change Get manager action to use graph api
2. Create Graph powershell script to assign permissions for managed identity
3. Create a bicep template 
4. use unified email connector

## Files
- Revoke-EntraIDSignInSessions.json
- Revoke-EntraIDSignInSessions.bicep
- Revoke-EntraIDSignInSessions.ps1

# Prequisites

# Post-deployment

## Powershell for grating permissions for Managed identity

```powershell
# ~~ Insert script here ~~
```

# Changes
|Date|Description|
|--|--|
|2023-12-21|Initial development|