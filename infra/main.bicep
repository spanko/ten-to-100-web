// ============================================================================
//  TenTo100 — Azure Static Web App (production)
//  Deploys an SWA configured for token/CI deployment (no repo connection).
//  The GitHub Actions workflow pushes the built site using the deployment
//  token; this template only provisions the resource.
// ============================================================================

@description('Name of the Static Web App resource.')
param name string = 'swa-tento100-web'

@description('''Region for the Static Web App. Free tier is only available in a
subset of regions: westus2, centralus, eastus2, westeurope, eastasia.''')
@allowed([
  'westus2'
  'centralus'
  'eastus2'
  'westeurope'
  'eastasia'
])
param location string = 'eastus2'

@description('SKU tier. Free is sufficient for a marketing site (includes custom domains + managed TLS).')
@allowed([
  'Free'
  'Standard'
])
param sku string = 'Free'

@description('Resource tags.')
param tags object = {
  project: 'tento100-web'
  environment: 'production'
  managedBy: 'bicep'
}

resource swa 'Microsoft.Web/staticSites@2024-04-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: sku
    tier: sku
  }
  properties: {
    // No source-control connection — we deploy via the GitHub Actions workflow
    // using the deployment token, so leave repo fields unset.
    allowConfigFileUpdates: true
    // PR preview environments (the workflow opens/closes these per PR).
    stagingEnvironmentPolicy: 'Enabled'
    enterpriseGradeCdnStatus: 'Disabled'
  }
}

@description('Auto-generated default hostname, e.g. <name>.azurestaticapps.net. Point the www CNAME at this.')
output defaultHostname string = swa.properties.defaultHostname

@description('The Static Web App resource name.')
output name string = swa.name

@description('The Static Web App resource id.')
output resourceId string = swa.id
