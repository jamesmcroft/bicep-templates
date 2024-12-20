using './ai-content-understanding.bicep'

param workloadName = 'ai-content-understanding'
param location = 'westus'
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

param identities = [
  { principalId: '72e8f444-489e-4ccd-b79e-9c3d0b706c7c', principalType: 'User' }
]
