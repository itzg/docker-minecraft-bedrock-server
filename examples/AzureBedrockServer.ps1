#you need the Azure cli https://docs.microsoft.com/es-es/cli/azure/

#Login to Azure portal
az login

#defaults to southcentralus but you can change it to one of the following list locations
#az account list-locations --query "[].{Region:name}" --out table
 
#create a new resource group "mineResGroup"
az group create --name mineResGroup --location southcentralus

#put the storage account "acismineacc" into that group
az storage account create --resource-group mineResGroup --name acismineacc --location southcentralus --sku Standard_LRS --kind StorageV2

#create the volume share "acismineshare" into the storage account
az storage share create --name acismineshare --account-name acismineacc

#obtain the key from the account "acismineacc" in the resource group "mineResGroup"
$STORAGE_KEY=$(az storage account keys list --resource-group mineResGroup --account-name acismineacc --query "[0].value" --output tsv)
echo $STORAGE_KEY

#to actually create the minecraft server int the dns name "minesvrbedrock"
#the server will be running into server "minesvrbedrock.southcentralus.azurecontainer.io" port "19132", this take some time be patient.
az container create --resource-group mineResGroup --name minecotainer --image itzg/minecraft-bedrock-server --dns-name-label minesvrbedrock --ports 19132 19133 --protocol udp --restart-policy OnFailure --environment-variables EULA=TRUE --azure-file-volume-account-name acismineacc --azure-file-volume-account-key $STORAGE_KEY --azure-file-volume-share-name acismineshare --azure-file-volume-mount-path /data

#connect to fileshare drive "M" to edit server.properties and everything else
#you need to restart the container after each change.
cmd.exe /C "cmdkey /add:`"acismineacc.file.core.windows.net`" /user:`"Azure\acismineacc`" /pass:`"$STORAGE_KEY`""
New-PSDrive -Name M -PSProvider FileSystem -Root "\\acismineacc.file.core.windows.net\acismineshare" -Persist
