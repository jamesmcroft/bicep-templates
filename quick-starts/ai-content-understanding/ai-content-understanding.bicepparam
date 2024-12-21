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
param aiServiceModelDeployments = []

param identities = [
  // { principalId: '00000000-0000-0000-0000-000000000000', principalType: 'User' }
]
