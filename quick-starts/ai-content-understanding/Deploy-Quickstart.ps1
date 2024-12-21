param(
    [Parameter(Mandatory = $true)]
    [string]$DeploymentName,
    [Parameter(Mandatory = $true)]
    [string]$Location,
    [switch]$WhatIf,
    [switch]$Force
)

function Deploy-AzureInfrastructure($deploymentName, $location, $whatIf) {
    $principalId = (az ad signed-in-user show --query id -o tsv)
    $identity = @{ 
        "principalId"   = "$principalId"
        "principalType" = "User" 
    } 
    $identityArray = ConvertTo-Json @($identity) -Depth 5 -Compress
    $identityArray = $identityArray -replace '"', '\"'
     
    if ($whatIf) {
        Write-Host "Previewing Azure infrastructure deployment. No changes will be made."
    
        $result = (az deployment sub what-if `
                --name $deploymentName `
                --location $location `
                --template-file './ai-content-understanding.bicep' `
                --parameters './ai-content-understanding.bicepparam' `
                --parameters workloadName=$deploymentName `
                --parameters location=$location `
                --parameters identities=$identityArray `
                --no-pretty-print) | ConvertFrom-Json
    
        if (-not $result) {
            Write-Error "Azure infrastructure deployment preview failed."
            exit 1
        }
    
        Write-Host "Azure infrastructure deployment preview succeeded."
        $result.changes | Format-List
        exit
    }
    
    $deploymentOutputs = (az deployment sub create `
            --name $deploymentName `
            --location $location `
            --template-file './ai-content-understanding.bicep' `
            --parameters './ai-content-understanding.bicepparam' `
            --parameters workloadName=$deploymentName `
            --parameters location=$location `
            --parameters identities=$identityArray `
            --query properties.outputs -o json) | ConvertFrom-Json
    
    if (-not $deploymentOutputs) {
        Write-Error "Azure infrastructure deployment failed."
        exit 1
    }
    
    Write-Host "Azure infrastructure deployment succeeded."
    $deploymentOutputs | Format-List
    
    return $deploymentOutputs
}

function Get-AIHubWorkspaceId($subscriptionId, $resourceGroupName, $workspaceName) {
    try {
        Write-Host "Retrieving AI Hub workspace ID for project '$workspaceName'..."

        $token = az account get-access-token --query accessToken --output tsv
        if (-not $token) {
            Throw "Unable to retrieve the access token."
        }

        $url = "https://management.azure.com/subscriptions/${subscriptionId}/resourceGroups/${resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/${workspaceName}?api-version=2023-04-01"

        $headers = @{
            Authorization  = "Bearer $token"
            "Content-Type" = "application/json"
        }

        $response = Invoke-RestMethod -Uri $url -Method Get -Headers $headers -ErrorAction Stop

        if ($response -and $response.properties) {
            return $response.properties.workspaceId
        }

        Write-Error "Failed to retrieve the AI Hub workspace ID."
        exit 1
    }
    catch {
        if ($_.Exception.Response) {
            $errorResponse = $_.Exception.Response
            $statusCode = $errorResponse.StatusCode.value__
            Write-Error "Failed to retrieve the AI Hub workspace ID. Status code: $statusCode"
        }
        else {
            Write-Error "An unexpected error occurred: $_"
        }
        exit 1
    }
}

function Get-AIHubProjectDetails($subscriptionId, $resourceGroupName, $location, $aiHubProjectName) {
    try {
        Write-Host "Retrieving AI Hub project details for project '$aiHubProjectName'..."

        $token = az account get-access-token --query accessToken --output tsv
        if (-not $token) {
            Throw "Unable to retrieve the access token."
        }

        $url = "https://ai.azure.com/api/${location}/report/v2.0/subscriptions/${subscriptionId}/resourceGroups/$resourceGroupName/providers/Microsoft.MachineLearningServices/workspaces/${aiHubProjectName}/reports:query"

        $payload = @{
            count                 = 500
            reportsV2FilterParams = @{
                scope = "projectTools"
            }
        } | ConvertTo-Json -Depth 5

        $headers = @{
            Authorization  = "Bearer $token"
            "Content-Type" = "application/json"
            Accept         = "application/json"
        }

        $response = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $payload -ErrorAction Stop

        if ($response -and $response.value) {
            return $response.value
        }

        Write-Warning "No AI Hub project details were found."    
    }
    catch {
        if ($_.Exception.Response) {
            $errorResponse = $_.Exception.Response
            $statusCode = $errorResponse.StatusCode.value__
            Write-Error "Failed to retrieve the AI Hub project details. Status code: $statusCode"
        }
        else {
            Write-Error "An unexpected error occurred: $_"
        }
        exit 1
    }
}

function Register-ContentUnderstandingService($subscriptionId, $resourceGroupName, $aiServicesName, $aiHubProjectName, $storageAccountName, $contentUnderstandingContainerName) {
    $maxRetries = 5
    $retryCount = 0
    $success = $false

    $aiHubProjectWorkspaceId = Get-AIHubWorkspaceId `
        -subscriptionId $subscriptionId `
        -resourceGroupName $resourceGroupName `
        -workspaceName $aiHubProjectName

    $url = "https://${aiServicesName}.cognitiveservices.azure.com/contentunderstanding/labelingProjects/${aiHubProjectWorkspaceId}?api-version=2024-12-01-preview"

    try {
        Write-Host "Checking if the AI Content Understanding service is already registered..."

        $token = az account get-access-token --resource https://cognitiveservices.azure.com --query accessToken --output tsv
        if (-not $token) {
            Throw "Unable to retrieve the access token."
        }

        $headers = @{
            Authorization  = "Bearer $token"
            "Content-Type" = "application/json"
            Accept         = "application/json"
        }

        $response = Invoke-RestMethod -Uri $url -Method Get -Headers $headers -ErrorAction Stop
        Write-Host "AI Content Understanding service is already registered."
        return
    }
    catch {
        if ($_.Exception.Response) {
            $errorResponse = $_.Exception.Response
            $statusCode = $errorResponse.StatusCode.value__

            if ($statusCode -ne 404) {
                Write-Error "Failed to check the AI Content Understanding service. Status code: $statusCode"
                exit 1
            }
        }
        else {
            Write-Error "An unexpected error occurred: $_"
            exit 1
        }
    }

    while (-not $success -and $retryCount -lt $maxRetries) {
        try {
            Write-Host "Registering the AI Content Understanding service..."

            $token = az account get-access-token --resource https://cognitiveservices.azure.com --query accessToken --output tsv
            if (-not $token) {
                Throw "Unable to retrieve the access token."
            }

            $payload = @{
                kind           = "mmiLabeling"
                displayName    = $aiHubProjectName
                description    = ""
                tags           = @{}
                storageAccount = @{
                    containerUrl = "https://${storageAccountName}.blob.core.windows.net/${contentUnderstandingContainerName}"
                }
            } | ConvertTo-Json -Depth 5

            $headers = @{
                Authorization  = "Bearer $token"
                "Content-Type" = "application/json"
                Accept         = "application/json"
            }

            $response = Invoke-RestMethod -Uri $url -Method Put -Headers $headers -Body $payload -ErrorAction Stop

            $success = $true
            Write-Host "Successfully registered the AI Content Understanding service."
            return
        }
        catch {
            if ($_.Exception.Response) {
                $errorResponse = $_.Exception.Response
                $statusCode = $errorResponse.StatusCode.value__

                if ($statusCode -eq 409) {
                    Write-Host "AI Content Understanding service is already registered."
                    $success = $true
                    return
                }

                Write-Error "Failed to register the AI Content Understanding service. Status code: $statusCode"
            }
            else {
                Write-Error "An unexpected error occurred: $_"
            }
        }
        
        $retryCount++
        if (-not $success -and $retryCount -lt $maxRetries) {
            $waitTime = 10 * $retryCount
            Write-Host "Retrying in $waitTime seconds..."
            Start-Sleep -Seconds $waitTime
        }
    }

    if (-not $success) {
        Write-Error "Failed to register the AI Content Understanding service after $maxRetries attempts."
        exit 1
    }
}

function Initialize-ContentUnderstandingProject($subscriptionId, $resourceGroupName, $location, $aiHubProjectName, $aiServicesConnectionName, $force) {
    if (-not $force) {
        $aiHubProjectDetails = Get-AIHubProjectDetails `
            -subscriptionId $subscriptionId `
            -resourceGroupName $resourceGroupName `
            -location $location `
            -aiHubProjectName $aiHubProjectName

        if ($aiHubProjectDetails) {
            $count = if ($aiHubProjectDetails -is [System.Array]) { $aiHubProjectDetails.Count } else { 1 }

            if ($count -eq 1) {
                $enabled = $aiHubProjectDetails.reportContent.uxData.contentUnderstanding
    
                if ($enabled -eq $true) {
                    Write-Warning "$aiHubProjectName is already set up for AI Content Understanding."
                    return
                }
            }
            else {
                foreach ($project in $aiHubProjectDetails) {
                    $isDefaultView = $project.isDefaultView
                    $enabled = $project.reportContent.uxData.contentUnderstanding
    
                    if ($isDefaultView -eq $true -and $enabled -eq $true) {
                        Write-Warning "$aiHubProjectName is already set up for AI Content Understanding."
                        return
                    }
                }
            }
        }
    }

    try {
        $token = az account get-access-token --query accessToken --output tsv
        if (-not $token) {
            Throw "Unable to retrieve the access token."
        }

        $url = "https://ai.azure.com/api/${location}/report/v2.0/subscriptions/${subscriptionId}/resourceGroups/${resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/${aiHubProjectName}/reports?api-version=2023-06-01-preview"
        
        $payload = @{
            name            = "default"
            scope           = "projectTools"
            isUserGenerated = $true
            isDefaultView   = $true
            reportContent   = @{
                uxData = @{
                    speechAnalytics          = $false
                    customSpeech             = $false
                    customNeuralVoice        = $false
                    documentIntelligence     = $false
                    multiModalIntelligence   = $false
                    contentUnderstanding     = $true
                    genAI                    = $false
                    evaluation               = $false
                    fineTuning               = $false
                    playground               = $false
                    promptFlow               = $false
                    trace                    = $false
                    contentUnderstandingData = @{
                        aiServicesConnectionName = $aiServicesConnectionName
                    }
                }
            }
        } | ConvertTo-Json -Depth 5

        $headers = @{
            Authorization  = "Bearer $token"
            "Content-Type" = "application/json"
            Accept         = "application/json"
        }

        $response = Invoke-RestMethod -Uri $url -Method Put -Headers $headers -Body $payload -ErrorAction Stop

        if (-not $response) {
            Write-Error "Failed to initialize the AI Content Understanding project."
            exit 1
        }

        return $response
    }
    catch {
        if ($_.Exception.Response) {
            $errorResponse = $_.Exception.Response
            $statusCode = $errorResponse.StatusCode.value__
            Write-Error "Failed to initialize the AI Content Understanding project. Status code: $statusCode"
        }
        else {
            Write-Error "An unexpected error occurred: $_"
        }
        exit 1
    }
}

$SubscriptionName = (az account show --query name -o tsv)

Write-Host "Starting deployment of Azure AI Content Understanding quickstart in subscription '$SubscriptionName'..."

$DeploymentOutputs = Deploy-AzureInfrastructure `
    -deploymentName $DeploymentName `
    -location $Location `
    -whatIf:$WhatIf

$SubscriptionId = $DeploymentOutputs.subscriptionInfo.value.id
$ResourceGroupName = $DeploymentOutputs.resourceGroupInfo.value.name
$AIContentUnderstandingProjectName = $DeploymentOutputs.aiHubProjectInfo.value.name
$AIServicesName = $DeploymentOutputs.aiServicesInfo.value.name
$StorageAccountName = $DeploymentOutputs.storageAccountInfo.value.name
$ContentUnderstandingContainerName = $DeploymentOutputs.storageAccountInfo.value.contentUnderstandingContainerName
$AIServicesConnectionName = $DeploymentOutputs.aiHubInfo.value.aiServicesConnectionName

Initialize-ContentUnderstandingProject `
    -subscriptionId $SubscriptionId `
    -resourceGroupName $ResourceGroupName `
    -location $Location `
    -aiHubProjectName $AIContentUnderstandingProjectName `
    -aiServicesConnectionName $AIServicesConnectionName `
    -force:$Force

Register-ContentUnderstandingService `
    -subscriptionId $SubscriptionId `
    -resourceGroupName $ResourceGroupName `
    -aiServicesName $AIServicesName `
    -aiHubProjectName $AIContentUnderstandingProjectName `
    -storageAccountName $StorageAccountName `
    -contentUnderstandingContainerName $ContentUnderstandingContainerName

Write-Host "Deployment of Azure AI Content Understanding quickstart completed."

$portalUrl = "https://ai.azure.com/build/visdoc/contentunderstanding/schema?wsid=/subscriptions/${SubscriptionId}/resourceGroups/${ResourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/${AIContentUnderstandingProjectName}"
Write-Host "To start using Azure AI Content Understanding, navigate to the portal: $portalUrl"