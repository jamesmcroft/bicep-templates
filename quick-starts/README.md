# Azure Bicep Quick Starts

These quick start templates take advantage of the individual resource templates to demonstrate how to deploy a complete solution to Azure with Bicep.

> [!NOTE]
> These quick start templates are a starting point. Modify them to fit your specific needs.

## Microservices Architecture with Azure Container Apps

The [Microservices Architecture with Azure Container Apps](./container-apps-multi-tenant.bicep) template deploys the infrastructure for a microservices architecture using Azure Container Apps.

The template deploys the following resources:

- Resource Group
  - Used to contain all the deployed resources.
- Managed Identity
  - Used to provide secure, role-based access control to the deployed Container Apps.
- Key Vault
  - Used to store secrets and keys for the deployed resources.
- Container Registry
  - Used to store and manage container images for the deployed microservices.
- Log Analytics + Application Insights
  - Used to monitor and analyze the deployed Container Apps and environment.
- Service Bus Namespace
  - Used to provide pub/sub messaging between the microservices.
- SQL Server + Elastic Pool
  - Used to store data for the microservices.
- Container Apps Environment + Dapr Pub/Sub + Dapr Secret Store
  - Used to host the microservices and provide a unified experience for pub/sub and secret management using Dapr.

## Azure Functions with Azure SQL

The [Azure Functions with Azure SQL](./function-app-with-sql.bicep) template deploys an Azure Functions app that connects to an Azure SQL database.

The template deploys the following resources:

- Resource Group
  - Used to contain all the deployed resources.
- Managed Identity
  - Used to provide secure, role-based access control to the deployed Function App.
- Key Vault
  - Used to store secrets and keys for the deployed resources.
- Log Analytics + Application Insights
  - Used to monitor and analyze the deployed Function App and environment.
- Storage Account
  - Used to store the Function App artifacts.
- SQL Server + SQL Database
  - Used to store data for the Function App.
- App Service Plan
  - Used to host the Function App.
- Function App
  - Used to run the serverless functions that connect to the SQL database.

## Azure Machine Learning Environment

The [Azure Machine Learning Environment](./machine-learning-environment.bicep) template deploys a complete AI solution that can be used to build, train, and deploy machine learning models.

The template deploys the following resources:

- Resource Group
  - Used to contain all the deployed resources.
- Managed Identity
  - Used to provide secure, role-based access control to the deployed Machine Learning Workspace.
- Storage Account
  - Used for training data for the Machine Learning Workspace.
- Key Vault
  - Used to store secrets and keys for access via Machine Learning pipelines.
- Log Analytics + Application Insights
  - Used to monitor and analyze the deployed Machine Learning Workspace and model endpoints.
- Container Registry
  - Used to store and manage container images for the deployed models.
- Machine Learning Workspace
  - Used to provide access to Azure Machine Learning compute, data, and models.

## Azure OpenAI RAG Environment

The [Azure OpenAI RAG Environment](./openai-rag.bicep) template deploys the infrastructure for building a RAG (Retrieval-Augmented Generation) application using Azure OpenAI.

The template deploys the following resources:

- Resource Group
  - Used to contain all the deployed resources.
- Managed Identity
  - Used to provide secure, role-based access control to the deployed resources.
- Key Vault
  - Used to store secrets and keys for the deployed resources.
- OpenAI Service + GPT-3.5 Turbo + Text Embedding ADA
  - Used to provide access to the OpenAI GPT and embedding models for the RAG application.
- Storage Account + Grounding Data Container
  - Used to store grounding data for the RAG application.
- AI Search
  - Used to provide semantic search capabilities over grounding data embeddings for the RAG application.
