[](https://learn.microsoft.com/en-us/azure/azure-functions/functions-infrastructure-as-code?tabs=json%2Cwindows%2Cdevops&pivots=consumption-plan)


https://raw.githubusercontent.com/Azure/bicep-registry-modules/main/modules/storage/storage-account/main.bicep


https://azure.github.io/bicep-registry-modules/

https://azure.github.io/Azure-Verified-Modules/indexes/bicep/

```powershell
git clone https://github.com/Azure/bicep-registry-modules.git
```


## Steps to deploy
Deployment tested successfully with:  
- powershell version 7.4.1 
- Azure cli version 11.4.0  
- Bicep version v0.26.54  


```powershell
Connect-AzAccount

az deployment group create --name "keskiviikon-testausta-1" --resource-group "DEV-mitmbusting" --template-file main.bicep

# Testing
az deployment group create --name "keskiviikon-testausta-1" --resource-group "DEV-mitmbusting" --parameters main.bicepparam

```


1. In azure portal navigate to MitM Function App  
2. Create new function with HTTP Trigger  
    - Name the function as Resolve-Domain
    - Leave Authorization level: Function

3. Go to Code + Test in Resolve-Domain function
    - Copy run.csx content from this repository to Resolve-Domain run.csx
    - Save the function.

4. In Azure portal navigate to log analytics workspace where you want to send data for sentinel.  
5. Go to Agents (under Settings)  
6. Expand "Log Analytics agent instructions  
7. Take note (copy and paste) of Workspace ID and Primary OR secondary key.

8. Navigate to logic app and edit it
    1. Go to last action (Azure Log Analytics Data Collector) and update credentials for it
    2. Enter name, workspace key and ID which you got previously.
    3. Add a new action after Condition check - REFERER
    4. search for "Azure Functions" and select it
    5. Select the function app you just deployd
    6. Select the function you just created
    7. Enter following json to request body 
    ```json
    {
        "url":"@{body('Parse_JSON_HTTP_Headers')?['Referer']}"
    }
    ```
    8. Add REFERER as url value
    9. Add Resolve-Domain body to DNSQueryResult's value in "Initialize variable - JsonBodyLogs"
    10. Save the logic app

## Further development actions
1. Create restrictions who can call the function app
2. Create restrictions where the function app can be called
3. Maybe modify function app code to parse out www if it's present. We want only https://name.tld and not https://www.name.tld
4. update logic app to include new condition for "https://management.azure.com/", does not starts with 
5. Make the deployment more automated
    - Deploy function in to the function app
    - Deploy code to the function
    - Attach function app action automatically to logic app
    - Add workspace id & key during deployment



## If logic app needs to be changed to trigger conditions instead of condition
Trigger condition expressions
```ex
@or(equals(equals(triggerOutputs()?['headers']?['Referer'],'https://login.microsoftonline.com/'), false))
@or(equals(equals(triggerOutputs()?['headers']?['Referer'],'https://login.microsoft.com/'), false))
@or(equals(startsWith(triggerOutputs()?['headers']?['Referer'],'https://management.azure.com/'), false))
@or(equals(endsWith(triggerOutputs()?['headers']?['Referer'],'.logic.azure.com/'), false))
@or(equals(equals(triggerOutputs()?['headers']?['Referer'],null), false))
```