
write-host "Deploying Azure resources..."
az deployment group create --name "keskiviikon-testausta-1" --resource-group "DEV-mitmbusting" --template-file main.bicep --parameters main.bicepparam

write-host "Deploying Azure function code..."
az functionapp deployment source config-zip --resource-group "DEV-mitmbusting" --name  "Leikkikentta-MitM-FuncApp-dev" --src .\FunctionApp.zip
