# Azure Bicep Templates

These templates are designed to help you [deploy Azure resources using Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview?tabs=bicep). They are easy to use and can be combined to build up a larger deployment of the resources required for your Azure solutions.

If you're looking for inspiration for your solution, check out the [available quick start templates](./quick-starts/README.md).

> [!NOTE]
> The templates in this repository are not a comprehensive collection of all Azure resources. They have been built up from real-world scenarios, when required. If you have a specific requirement for a specific resource, please feel free to raise an issue or submit a pull request.

## Getting Started

To deploy the resources in this repository, you will need to have the following tools installed:

- [**Azure CLI**](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- [**Bicep CLI**](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install#azure-cli)

## What is available in the Azure Bicep Templates?

The templates in this repository are designed to be easy to use and understand. They are broken down into the following categories:

### AI/ML

- [**Azure AI Foundry Hub**](./ai_ml/ai-hub.bicep)
  - Deploys an [Azure AI Foundry Hub](https://learn.microsoft.com/en-us/azure/ai-studio/concepts/ai-resources) that provides a centralized area for teams to govern their AI projects, accessed via the [Azure AI Foundry](https://ai.azure.com/build). Provides support for [Azure AI Foundry Project](./ai_ml/ai-hub-project.bicep) resources which can be used to manage the scope of individual AI projects, including the deployment of AI models, including GPT models.
- [**Azure AI Foundry Serverless Model Endpoints**](./ai_ml/ai-hub-model-serverless-endpoint.bicep)
  - Deploys an [Azure AI Foundry Serverless Model Endpoint](https://learn.microsoft.com/en-us/azure/ai-studio/how-to/deploy-models-serverless?tabs=azure-ai-studio) that can host supported models from the Foundry model catalog. See the [models.json](./ai_ml/models.json) for a list of out-of-the-box models that can be deployed from this repository.
- [**Azure AI Search**](./ai_ml/ai-search.bicep)
  - Deploys an [Azure AI Search service](https://learn.microsoft.com/en-us/azure/search/search-what-is-azure-search), which can be used to index and search over structured and unstructured data, including embeddings for semantic search.
- [**Azure AI Services**](./ai_ml/ai-services.bicep)
  - Deploys a [multi-service Azure AI service](https://learn.microsoft.com/en-us/azure/ai-services/multi-service-resource?tabs=windows&pivots=azportal) that includes a single endpoint to access multiple AI services, including Azure OpenAI, AI Content Safety, and more.
- [**Azure AI Document Intelligence**](./ai_ml/document-intelligence.bicep)
  - Deploys an [Azure AI Document Intelligence service](https://learn.microsoft.com/en-us/azure/ai-services/document-intelligence/overview?view=doc-intel-4.0.0), which can be used to extract information from documents, including forms, receipts, and more.
- [**Azure AI Language**](./ai_ml/text-analytics.bicep)
  - Deploys an [Azure AI Language service](https://learn.microsoft.com/en-us/azure/ai-services/language-service/overview), which can be used to extract insights from text, including sentiment analysis, key phrase extraction, and more.
- [**Azure Machine Learning Workspace**](./ai_ml/machine-learning-workspace.bicep)
  - Deploys an Azure Machine Learning workspace, which can be used to train and deploy machine learning models. Provides support for [workspace connections](./ai_ml/machine-learning-workspace-connection.bicep) with other Azure services.
- [**Azure OpenAI Service**](./ai_ml/openai.bicep)
  - Deploys an Azure OpenAI service, which can be used to generate text, images, and more using OpenAI GPT models.

### Analytics

- [**Azure Event Hub Namespace**](./analytics/event-hub-namespace.bicep)
  - Deploys an [Azure Event Hub Namespace](https://learn.microsoft.com/en-us/azure/event-hubs/event-hubs-about), which can be used to ingest and process large volumes of events. Provides support for [Event Hub](./analytics/event-hub.bicep) resources.
- [**Azure IoT Hub**](./analytics/iot-hub.bicep)
  - Deploys an [Azure IoT Hub](https://learn.microsoft.com/en-us/azure/iot-hub/iot-concepts-and-iot-hub), which can be used to connect, monitor, and manage IoT devices. Provides support for [IoT Hub Device Provisioning Service](./analytics/iot-hub-dps.bicep) resources.

### Compute

- [**Azure App Service Plan**](./compute/app-service-plan.bicep)
  - Deploys an [Azure App Service Plan](https://learn.microsoft.com/en-us/azure/app-service/environment/overview), which can be used to host web applications, APIs, and more.
- [**Azure Function App**](./compute/function-app.bicep)
  - Deploys an [Azure Function App](https://learn.microsoft.com/en-us/azure/azure-functions/functions-overview?pivots=programming-language-csharp), which can be used to run serverless functions in the cloud.
- [**Azure Static Web App**](./compute/static-web-app.bicep)
  - Deploys an [Azure Static Web App](https://learn.microsoft.com/en-us/azure/static-web-apps/overview), which can be used to host static web applications.
- [**Azure Web App**](./compute/web-app.bicep)
  - Deploys an [Azure Web App](https://learn.microsoft.com/en-us/azure/app-service/overview), which can be used to host web applications, APIs, and more.

### Containers

- [**Azure Container Apps Environment**](./containers/container-apps-environment.bicep)
  - Deploys an [Azure Container Apps Environment](https://learn.microsoft.com/en-us/azure/container-apps/environment), which can be used to run containerized applications in the cloud using a managed Kubernetes environment. Provides support for [Azure File Share connections](./containers/container-apps-environment-storage.bicep), and Dapr components including [CRON bindings](./containers/container-apps-environment-dapr-bindings-cron.bicep), [Azure Service Bus Pub/Sub](./containers/container-apps-environment-dapr-pubsub-service-bus.bicep), [Azure Key Vault Secret Store](./containers/container-apps-environment-dapr-secretstores-key-vault.bicep).
- [**Azure Container App**](./containers/container-app.bicep)
  - Deploys an [Azure Container App](https://learn.microsoft.com/en-us/azure/container-apps/overview) to an Azure Container Apps Environment, which can be used to run a containerized application.
- [**Azure Container Apps Dynamic Sessions Pool**](./containers/container-app-dynamic-sessions.bicep)
  - Deploys an [Azure Container Apps Dynamic Sessions Pool](https://learn.microsoft.com/en-us/azure/container-apps/sessions), which can be used to run isolated code or applications in a managed container environment.
  - This resource is ideal for code interpreter sessions to run code generated by large language models (LLMs). For more information on how this works, see the [Azure Container Apps documentation](https://learn.microsoft.com/en-us/azure/container-apps/sessions-code-interpreter).
- [**Azure Container Registry**](./containers/container-registry.bicep)
  - Deploys an [Azure Container Registry](https://learn.microsoft.com/en-us/azure/container-registry/container-registry-intro), which can be used to store and manage container images.

### Databases

- [**Azure SQL Server**](./databases/sql-server.bicep)
  - Deploys an [Azure SQL Server](https://learn.microsoft.com/en-us/azure/azure-sql/azure-sql-iaas-vs-paas-what-is-overview?view=azuresql), which can be used to host SQL databases.
- [**Azure SQL Elastic Pool**](./databases/sql-elastic-pool.bicep)
  - Deploys an [Azure SQL Elastic Pool](https://learn.microsoft.com/en-us/azure/azure-sql/database/elastic-pool-overview?view=azuresql), which can be used to host multiple databases with a shared set of resources.
- [**Azure SQL Database**](./databases/sql-database.bicep)
  - Deploys an [Azure SQL Database](https://learn.microsoft.com/en-us/azure/azure-sql/database/sql-database-paas-overview?view=azuresql), which can be used to store and manage relational data.

### Integration

- [**Azure API Management**](./integration/api-management.bicep)
  - Deploys an [Azure API Management](https://learn.microsoft.com/en-us/azure/api-management/api-management-key-concepts), which can be used to publish, secure, and manage APIs. Provides support for [Backends](./integration/api-management-backend.bicep), [Named Values](./integration/api-management-named-value.bicep), [OpenAPI APIs](./integration/api-management-openapi-api.bicep), [Policies](./integration/api-management-policy.bicep), and [Subscriptions](./integration/api-management-subscription.bicep).
- [**Azure Service Bus Namespace**](./integration/service-bus-namespace.bicep)
  - Deploys an [Azure Service Bus Namespace](https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-messaging-overview), which can be used to build scalable and reliable cloud messaging solutions.

### Management and Governance

- [**Azure Log Analytics Workspace**](./management_governance/log-analytics-workspace.bicep)
  - Deploys an [Azure Log Analytics Workspace](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/log-analytics-overview), which can be used to collect, analyze, and visualize log data. Provides support for [Summary Rules](./management_governance/log-analytics-workspace-summary-log.bicep) which can be deployed to aggregate large volumes of log data into meaningful summary tables.
- [**Azure Application Insights**](./management_governance/application-insights.bicep)
  - Deploys an [Azure Application Insights](https://learn.microsoft.com/en-us/azure/azure-monitor/app/app-insights-overview), which can be used to monitor and analyze the performance of applications that can be linked to a Log Analytics Workspace.

### Networking

- [**Azure Application Gateway**](./networking/application-gateway.bicep)
  - Deploys an [Azure Application Gateway](https://learn.microsoft.com/en-us/azure/application-gateway/overview), which can be used to build scalable and secure web applications.
- [**Azure DNS Zone**](./networking/dns-zone.bicep)
  - Deploys an [Azure DNS Zone](https://learn.microsoft.com/en-us/azure/dns/dns-overview), which can be used to host DNS records for a domain.
- [**Azure Front Door**](./networking/front-door.bicep)
  - Deploys an [Azure Front Door](https://learn.microsoft.com/en-us/azure/frontdoor/front-door-overview), which can be used to build a global web application delivery network. Provides support for [Origin Groups](./networking/front-door-origin-group.bicep) and [Endpoints](./networking/front-door-endpoint.bicep).
- [**Azure Network Security Group**](./networking/network-security-group.bicep)
  - Deploys an [Azure Network Security Group](https://learn.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview), which can be used to filter network traffic to and from Azure resources.
- [**Azure Public IP Address**](./networking/public-ip-address.bicep)
  - Deploys an [Azure Public IP Address](https://learn.microsoft.com/en-us/azure/virtual-network/ip-services/public-ip-addresses), which can be used to assign a public IP address to an Azure resource.
- [**Azure Virtual Network**](./networking/virtual-network.bicep)
  - Deploys an [Azure Virtual Network](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-networks-overview), which can be used to connect Azure resources to each other and to on-premises networks. Provides support for [Subnets](./networking/virtual-network-subnet.bicep).

### Security

- [**Azure Key Vault**](./security/key-vault.bicep)
  - Deploys an [Azure Key Vault](https://learn.microsoft.com/en-us/azure/key-vault/general/overview), which can be used to store and manage secrets, keys, and certificates. Provides support for [Secrets](./security/key-vault-secret.bicep) and [creating environment variables for web applications using Key Vault secret URIs](./security/key-vault-secret-environment-variables.bicep).
- [**Azure Managed Identity**](./security/managed-identity.bicep)
  - Deploys an [Azure Managed Identity](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/overview), which can be used to authenticate to Azure services without storing credentials in code.

### Storage

- [**Azure Storage Account**](./storage/storage-account.bicep)
  - Deploys an [Azure Storage Account](https://learn.microsoft.com/en-us/azure/storage/common/storage-account-overview), which can be used to store and manage data in the cloud, including blobs, tables, files, and queues. Provides support for [Blob Containers](./storage/storage-blob-container.bicep), [File Shares](./storage/storage-file-share.bicep), and [Tables](./storage/storage-table.bicep).

## Contributing 🤝🏻

Contributions, issues and feature requests are welcome!

Feel free to check the [issues page](https://github.com/jamesmcroft/bicep-templates/issues). You can also take a look at the [contributing guide](https://github.com/jamesmcroft/bicep-templates/blob/main/CONTRIBUTING.md).

We actively encourage you to jump in and help with any issues, and if you find one, don't forget to log it!

## Support this project 💗

As many developers know, projects like this are built and maintained in maintainers' spare time. If you find this project useful, please **Star** the repo.

## Author

👤 **James Croft**

- Website: <https://www.jamescroft.co.uk>
- Github: [@jamesmcroft](https://github.com/jamesmcroft)
- LinkedIn: [@jmcroft](https://linkedin.com/in/jmcroft)

## License

This project is made available under the terms and conditions of the [MIT license](LICENSE).
