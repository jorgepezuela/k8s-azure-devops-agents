if (-not (Test-Path Env:AZP_URL)) {
    Write-Error "error: missing AZP_URL environment variable"
    exit 1
}

## Generating access token to access Azure DevOps with federated identity
# $azureAdTokenExchange=Get-Content $Env:AZURE_FEDERATED_TOKEN_FILE -Raw
# Connect-AzAccount -ApplicationId $Env:AZURE_CLIENT_ID -TenantId $Env:AZURE_TENANT_ID -FederatedToken $azureAdTokenExchange
# $azureAccessToken = Get-AzAccessToken -ResourceUrl "499b84ac-1321-427f-aa17-267ca6975798" | ConvertTo-Json | ConvertFrom-Json
# $Env:AZP_TOKEN = $azureAccessToken.Token

if (-not (Test-Path Env:AZP_TOKEN_FILE)) {
    if (-not (Test-Path Env:AZP_TOKEN)) {
        Write-Error "error: missing AZP_TOKEN environment variable"
        exit 1
    }

    $Env:AZP_TOKEN_FILE = "\azp\.token"
    $Env:AZP_TOKEN | Out-File -FilePath $Env:AZP_TOKEN_FILE
}

echo $Env:AZP_TOKEN
echo $Env:AZP_TOKEN_FILE
cat $Env:AZP_TOKEN_FILE

# Remove-Item Env:AZP_TOKEN

if ((Test-Path Env:AZP_WORK) -and -not (Test-Path $Env:AZP_WORK)) {
    New-Item $Env:AZP_WORK -ItemType directory | Out-Null
}

New-Item "\azp\agent" -ItemType directory | Out-Null

# Let the agent ignore the token env variables
$Env:VSO_AGENT_IGNORE = "AZP_TOKEN,AZP_TOKEN_FILE"

Set-Location agent

Write-Host "1. Determining matching Azure Pipelines agent..." -ForegroundColor Cyan

$domains = @(([System.Uri]$(${Env:AZP_URL})).Host)

ForEach ($domain in $domains) {
    Do {
        $resolveDomain = (Resolve-DnsName -Name $domain -Type A -ErrorAction 0 | Where-Object { $_.Strings -ne '' } | Measure-Object).Count

        If ($resolveDomain -eq 0) {
            Write-Host "DNS resolution failed..."
            Start-Sleep -Seconds 10
        }
        Else {
            Write-Host "DNS resolution succeeded..."
        }
    }
    Until ($resolveDomain -gt 0)
}

# Another way to download the devops agent with github repository
$result = ( Invoke-WebRequest -Uri "https://github.com/microsoft/azure-pipelines-agent/releases/latest" -UseBasicParsing -MaximumRedirection 0 -ErrorAction:SilentlyContinue).Headers.Location
$version = split-path $result -leaf
$numberVersion = $version.Replace("v", "")
$packageUrl = "https://download.agent.dev.azure.com/agent/$numberVersion/vsts-agent-win-x64-$numberVersion.zip"

# $URL = "$(${Env:AZP_URL})/_apis/distributedtask/packages/agent?platform=win-x64&`$top=1"
# $HEADER = @{
#     'Authorization' = 'Bearer ' + $Env:AZP_TOKEN
#     'Content-Type' = 'application/json'}
# $package = Invoke-RestMethod -Headers $HEADER -Uri $URL
# $packageUrl = $package[0].Value.downloadUrl

# $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$(Get-Content ${Env:AZP_TOKEN_FILE})"))
# $package = Invoke-RestMethod -Headers @{Authorization = ("Bearer Env:AZP_TOKEN_FILE")} "$(${Env:AZP_URL})/_apis/distributedtask/packages/agent?platform=win-x64&`$top=1"
# $packageUrl = $package[0].Value.downloadUrl

echo $URL
echo $HEADER
echo $package
Write-Host $packageUrl

Write-Host "2. Downloading and installing Azure Pipelines agent..." -ForegroundColor Cyan


echo "$(Get-Location)\agent.zip"

$wc = New-Object System.Net.WebClient
echo $wc
$wc.DownloadFile($packageUrl, "$(Get-Location)\agent.zip")

Expand-Archive -Path "agent.zip" -DestinationPath "\azp\agent"

## This is for the PAT and Managed Identity.
try {
    Write-Host "3. Configuring Azure Pipelines agent..." -ForegroundColor Cyan

    .\config.cmd --unattended `
        --agent "$(if (Test-Path Env:AZP_AGENT_NAME) { ${Env:AZP_AGENT_NAME} } else { ${Env:computername} })" `
        --url "$(${Env:AZP_URL})" `
        --auth PAT `
        --token "$(Get-Content ${Env:AZP_TOKEN_FILE})" `
        --pool "$(if (Test-Path Env:AZP_POOL) { ${Env:AZP_POOL} } else { 'Default' })" `
        --work "$(if (Test-Path Env:AZP_WORK) { ${Env:AZP_WORK} } else { '_work' })" `
        --replace

    Write-Host "4. Running Azure Pipelines agent..." -ForegroundColor Cyan

    .\run.cmd
}
finally {
    Write-Host "Cleanup. Removing Azure Pipelines agent..." -ForegroundColor Cyan

    .\config.cmd remove --unattended `
        --auth PAT `
        --token "$(Get-Content ${Env:AZP_TOKEN_FILE})"
}
























##  This is using the Service Principal for the authentication
# try {
#     Write-Host "3. Configuring Azure Pipelines agent..." -ForegroundColor Cyan

#     .\config.cmd --unattended `
#         --agent "$(if (Test-Path Env:AZP_AGENT_NAME) { ${Env:AZP_AGENT_NAME} } else { ${Env:computername} })" `
#         --url "$(${Env:AZP_URL})" `
#         --auth SP `
#         --clientid "$Env:AZP_CLIENT_ID" `
#         --tenantid "$Env:AZP_TENANT_ID" `
#         --clientsecret "$Env:AZP_SECRET_VALUE" `
#         --pool "$(if (Test-Path Env:AZP_POOL) { ${Env:AZP_POOL} } else { 'Default' })" `
#         --work "$(if (Test-Path Env:AZP_WORK) { ${Env:AZP_WORK} } else { '_work' })" `
#         --replace

#     Write-Host "4. Running Azure Pipelines agent..." -ForegroundColor Cyan

#     .\run.cmd
# }
# finally {
#     Write-Host "Cleanup. Removing Azure Pipelines agent..." -ForegroundColor Cyan

#     .\config.cmd remove --unattended `
#         --auth SP `
#         --clientid "$Env:AZP_CLIENT_ID" `
#         --tenantid "$Env:AZP_TENANT_ID" `
#         --clientsecret "$Env:AZP_SECRET_VALUE"
# }
