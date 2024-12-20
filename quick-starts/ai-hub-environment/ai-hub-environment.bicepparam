using './ai-hub-environment.bicep'

param workloadName = 'ai-hub-environment'
param location = 'swedencentral'
param tags = {}
param raiPolicies = [
  {
    name: workloadName
    mode: 'Blocking'
    prompt: {}
    completion: {}
  }
]
param aiServiceModelDeployments = [
  {
    name: 'gpt-4o'
    model: { format: 'OpenAI', name: 'gpt-4o', version: '2024-11-20' }
    sku: { name: 'GlobalStandard', capacity: 10 }
    raiPolicyName: workloadName
    versionUpgradeOption: 'OnceCurrentVersionExpired'
  }
]
param serverlessModelDeployments = [
  {
    name: 'Phi-35-moe-instruct'
  }
]
