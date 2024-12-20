# Azure AI Foundry Hub Environment

This [Azure AI Foundry Hub Environment](./ai-hub-environment.bicep) template demonstrates how to set up a workspace in the Azure AI Foundry for building, testing, and deploying AI solutions with AI models from the Azure AI model catalog. This example provides a public internet access enabled environment secured by Microsoft Entra ID authentication via Azure Managed Identity with least-privilege Role-Based Access Control (RBAC) for secure access to the dependent resources.

This deployment can be accessed via the [Azure AI Foundry portal](https://ai.azure.com/build/).

## Resources

| Provider                                           | Description                                                                                                                            |
| -------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| `Microsoft.Resources/resourceGroups`               | The resource group all resources are deployed into                                                                                     |
| `Microsoft.ManagedIdentity/userAssignedIdentities` | An Azure user-assigned managed identity to secure access to the deployed resources from the Azure AI Foundry Hub environment           |
| `Microsoft.MachineLearningServices/workspaces`     | An Azure AI Hub and associated Project instance to act as the workspace for building out AI solutions                                  |
| `Microsoft.CognitiveServices/accounts`             | An Azure AI Services instance associated with the AI Hub environment for accessing Azure AI capabilities, including OpenAI GPT models. |
| `Microsoft.Storage/storageAccounts`                | An Azure Storage account associated with the AI Hub environment for data storage                                                       |
| `Microsoft.KeyVault/vaults`                        | An Azure Key Vault associated with the AI Hub environment for secret storage                                                           |
| `Microsoft.ContainerRegistry/registries`           | An Azure Container Registry associated with the AI Hub environment for storing AI model container images                               |
| `Microsoft.OperationalInsights/workspaces`         | An Azure Log Analytics workspace associated with the AI Hub environment for storing logs and metrics                                   |
| `Microsoft.Insights/components`                    | An Azure Application Insights component associated with the AI Hub environment for observability                                       |

### AI Capabilities

The following AI models are deployed to the Azure AI Foundry Hub Environment:

- [OpenAI GPT-4o - Global Standard (2024-11-20) - 10K TPM](https://ai.azure.com/explore/models/gpt-4o/version/2024-11-20/registry/azure-openai)
- [Phi-3.5-MoE-instruct - Serverless Endpoint](https://ai.azure.com/explore/models/Phi-3.5-MoE-instruct/version/4/registry/azureml)

The following [AI Content Filters](https://learn.microsoft.com/en-us/azure/ai-studio/concepts/content-filtering) are deployed for each model:

- Prompt
  - Violence - High
  - Hate - High
  - Sexual - High
  - Self-Harm - High
  - Jailbreak - Enabled (Blocking)
- Completion
  - Violence - High
  - Hate - High
  - Sexual - High
  - Self-Harm - High
  - Protected Material Text - Enabled (Blocking)
  - Protected Material Code - Enabled (Non-Blocking)

### Role Assignments

The following Azure role assignments are created for the managed identity:

- `Microsoft.Resources/resourceGroups`:
  - [Contributor](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/privileged#contributor)
- `Microsoft.Storage/storageAccounts`:
  - [Storage Account Contributor](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/storage#storage-account-contributor)
  - [Storage Blob Data Contributor](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/storage#storage-blob-data-contributor)
  - [Storage File Data Privileged Contributor](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/storage#storage-file-data-privileged-contributor)
  - [Storage Table Data Contributor](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/storage#storage-table-data-contributor)
- `Microsoft.KeyVault/vaults`:
  - [Key Vault Administrator](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/security#key-vault-administrator)
- `Microsoft.ContainerRegistry/registries`:
  - [AcrPull](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/containers#acrpull)
  - [AcrPush](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/containers#acrpush)
- `Microsoft.CognitiveServices/accounts`:
  - [Cognitive Services Contributor](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/ai-machine-learning#cognitive-services-contributor)
  - [Cognitive Services OpenAI Contributor](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/ai-machine-learning#cognitive-services-openai-contributor)
  - [Cognitive Services OpenAI User](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/ai-machine-learning#cognitive-services-openai-user)
- `Microsoft.MachineLearningServices/workspaces`:
  - [AzureML Data Scientist](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/ai-machine-learning#azureml-data-scientist)

## Learn more

If you are new to Azure AI Foundry, see:

- [Azure AI Foundry documentation](https://learn.microsoft.com/en-gb/azure/ai-studio/what-is-ai-studio)
