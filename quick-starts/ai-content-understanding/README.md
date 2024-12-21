# Azure AI Content Understanding Project

This [Azure AI Content Understanding Project](./ai-content-understanding.bicep) template demonstrates how to automate the deployment of the new multi-modal AI content understanding service in the Azure AI Foundry. This example provides an AI Foundry environment, secured with Microsoft Entra ID authentication via Azure Managed Identity.

This deployment automates the process driven by the [Azure AI Foundry portal experience](https://ai.azure.com/explore/aiservices/vision/contentunderstanding).

## Resources

| Provider                                       | Description                                                                                                                                             |
| ---------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Microsoft.Resources/resourceGroups`           | The resource group all resources are deployed into                                                                                                      |
| `Microsoft.MachineLearningServices/workspaces` | An Azure AI Foundry Hub and associated AI Content Understanding Project instance to act as the workspace for using the AI Content Understanding service |
| `Microsoft.CognitiveServices/accounts`         | An Azure AI Services instance associated with the AI Content Understanding project for accessing Azure AI capabilities                                  |

| `Microsoft.Storage/storageAccounts` | An Azure Storage account associated with the AI Content Understanding project for data storage |
| `Microsoft.Storage/storageAccounts/blobServices/containers` | An Azure Blob Storage container associated with the AI Content Understanding project for storing training and labeling data |
| `Microsoft.KeyVault/vaults` | An Azure Key Vault associated with the AI Content Understanding project for secret storage |
| `Microsoft.OperationalInsights/workspaces` | An Azure Log Analytics workspace associated with the AI Content Understanding project for storing logs and metrics |
| `Microsoft.Insights/components` | An Azure Application Insights component associated with the AI Content Understanding project for observability |

### Deployment Script

There are additional steps beyond the Bicep template that are required to configure and register the Azure AI Content Understanding service. The provided [`Deploy-Quickstart.ps1`](./Deploy-Quickstart.ps1) script automates the deployment of both the Bicep template and the additional steps.

To deploy the Azure AI Content Understanding project, run the following command:

```powershell
.\Deploy-Quickstart.ps1 -DeploymentName <unique-deployment-name> -Location <westus|swedencentral|australiaeast> -ResourceGroupName <resource-group-name>
```

> [!NOTE]
> The script has an additional `-WhatIf` flag that can be used to preview the deployment without actually executing it.

The deployment script runs the following actions:

1. Deploys the Bicep template to create the Azure AI Content Understanding project resources in your Azure subscription.
2. Updates the deployed default Azure AI Hub Project (`Microsoft.MachineLearningServices/workspaces` kind='project') to enable the Azure AI Content Understanding user experience in the Azure AI Foundry portal.
3. Registers the Azure AI Hub Project with the Azure AI Services instance (`Microsoft.CognitiveServices/accounts` kind='AIServices') to enable the AI Content Understanding service for this project.

Once complete, you can access the Azure AI Content Understanding project in the [Azure AI Foundry portal](https://ai.azure.com/build/).

### Role Assignments

To successfully deploy and register the Azure AI Content Understanding service to be used by you, the following Azure role assignments are created for your identity:

- `Microsoft.Resources/resourceGroups`:
  - [Contributor](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/privileged#contributor)
- `Microsoft.KeyVault/vaults`:
  - [Key Vault Contributor](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/security#key-vault-contributor)
- `Microsoft.CognitiveServices/accounts`:
  - [Cognitive Services User](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/ai-machine-learning#cognitive-services-user)
  - [Cognitive Services Contributor](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/ai-machine-learning#cognitive-services-contributor)
  - [Cognitive Services OpenAI User](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/ai-machine-learning#cognitive-services-openai-user)
  - [Cognitive Services OpenAI Contributor](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/ai-machine-learning#cognitive-services-openai-contributor)
- `Microsoft.Storage/storageAccounts`:
  - [Storage Account Contributor](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/storage#storage-account-contributor)
  - [Storage Blob Data Contributor](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/storage#storage-blob-data-contributor)
  - [Storage File Data Privileged Contributor](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/storage#storage-file-data-privileged-contributor)
  - [Storage Table Data Contributor](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/storage#storage-table-data-contributor)
- `Microsoft.MachineLearningServices/workspaces`:
  - [AzureML Data Scientist](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/ai-machine-learning#azureml-data-scientist)

## Learn more

If you are new to Azure AI Content Understanding, see:

- [Azure AI Content Understanding documentation](https://learn.microsoft.com/en-us/azure/ai-services/content-understanding/overview)
