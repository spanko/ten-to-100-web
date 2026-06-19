#requires -Version 7.0
<#
.SYNOPSIS
    Provision the TenTo100 Azure Static Web App and wire up CI deployment.

.DESCRIPTION
    1. Ensures the resource group exists.
    2. Deploys infra/main.bicep (the Static Web App, Free tier, token-deployed).
    3. Reads the deployment token and stores it as the GitHub Actions secret
       AZURE_STATIC_WEB_APPS_API_TOKEN (so .github/workflows can deploy).
    4. Prints the SWA default hostname — feed that into Configure-CloudflareDns.ps1.

    Idempotent: safe to re-run. Nothing here touches DNS.

.PREREQUISITES
    - Azure CLI (`az`) logged in:           az login
    - GitHub CLI (`gh`) logged in:          gh auth login   (needs repo admin to set secrets)
    - The repo must already exist on GitHub if -SetGitHubSecret is used.

.EXAMPLE
    ./Deploy-Azure.ps1 -Repo "your-org/ten-to-100-web"

.EXAMPLE
    # Pick a subscription explicitly and skip the GitHub secret step:
    ./Deploy-Azure.ps1 -SubscriptionId "0000...-...." -SetGitHubSecret:$false
#>
[CmdletBinding()]
param(
    [string] $ResourceGroup = 'rg-tento100-web',
    [ValidateSet('westus2', 'centralus', 'eastus2', 'westeurope', 'eastasia')]
    [string] $Location = 'eastus2',
    [string] $AppName = 'swa-tento100-web',

    # Azure subscription to deploy into. Defaults to the current `az` context.
    [string] $SubscriptionId,

    # GitHub repo (owner/name) to receive the deployment-token secret.
    # Defaults to whatever `gh repo view` resolves for the current directory.
    [string] $Repo,

    # Push the SWA deployment token to GitHub as a repo secret.
    [bool] $SetGitHubSecret = $true
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- helpers ---------------------------------------------------------------
function Assert-Command {
    param([string] $Name, [string] $Hint)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command '$Name' not found. $Hint"
    }
}

function Invoke-Native {
    # Run a native command and throw if it exits non-zero.
    param([scriptblock] $Script)
    & $Script
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed (exit $LASTEXITCODE): $($Script.ToString().Trim())"
    }
}

$bicepFile = Join-Path $PSScriptRoot 'main.bicep'

Write-Host "==> Checking prerequisites" -ForegroundColor Cyan
Assert-Command -Name 'az' -Hint 'Install: https://aka.ms/azure-cli'
if ($SetGitHubSecret) {
    Assert-Command -Name 'gh' -Hint 'Install: https://cli.github.com'
}
if (-not (Test-Path $bicepFile)) { throw "Cannot find $bicepFile" }

# Confirm az is logged in.
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) { throw "Not logged in to Azure. Run: az login" }

if ($SubscriptionId) {
    Write-Host "==> Setting subscription $SubscriptionId" -ForegroundColor Cyan
    Invoke-Native { az account set --subscription $SubscriptionId }
    $account = az account show | ConvertFrom-Json
}
Write-Host "    Subscription: $($account.name) ($($account.id))"

# --- 1. resource group -----------------------------------------------------
Write-Host "==> Ensuring resource group '$ResourceGroup' in $Location" -ForegroundColor Cyan
Invoke-Native { az group create --name $ResourceGroup --location $Location --output none }

# --- 2. deploy bicep --------------------------------------------------------
Write-Host "==> Deploying Static Web App '$AppName' (Bicep)" -ForegroundColor Cyan
$deployName = "tento100-swa-deploy"
$outputsJson = az deployment group create `
    --resource-group $ResourceGroup `
    --name $deployName `
    --template-file $bicepFile `
    --parameters name=$AppName location=$Location `
    --query properties.outputs `
    --output json
if ($LASTEXITCODE -ne 0) { throw "Bicep deployment failed." }

$outputs = $outputsJson | ConvertFrom-Json
$defaultHostname = $outputs.defaultHostname.value
Write-Host "    Default hostname: $defaultHostname" -ForegroundColor Green

# --- 3. deployment token ----------------------------------------------------
Write-Host "==> Retrieving deployment token" -ForegroundColor Cyan
$token = az staticwebapp secrets list --name $AppName --resource-group $ResourceGroup `
    --query "properties.apiKey" --output tsv
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($token)) {
    throw "Failed to read deployment token."
}

if ($SetGitHubSecret) {
    if (-not $Repo) {
        $Repo = (gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>$null)
        if ([string]::IsNullOrWhiteSpace($Repo)) {
            throw "Could not auto-detect the GitHub repo. Pass -Repo 'owner/name' (and ensure the repo exists on GitHub)."
        }
    }
    Write-Host "==> Setting GitHub secret AZURE_STATIC_WEB_APPS_API_TOKEN on $Repo" -ForegroundColor Cyan
    # Pipe the token via stdin so it never appears in process args / history.
    $token | gh secret set AZURE_STATIC_WEB_APPS_API_TOKEN --repo $Repo --app actions
    if ($LASTEXITCODE -ne 0) { throw "gh secret set failed." }
    Write-Host "    Secret set." -ForegroundColor Green
}
else {
    Write-Host "==> Deployment token (store as AZURE_STATIC_WEB_APPS_API_TOKEN):" -ForegroundColor Yellow
    Write-Host "    $token"
}

# --- summary ----------------------------------------------------------------
Write-Host ""
Write-Host "Done. Static Web App is provisioned." -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Configure DNS in Cloudflare (uses the hostname below):"
Write-Host "       ./Configure-CloudflareDns.ps1 -SwaHostname '$defaultHostname'"
Write-Host "  2. Register the www custom domain in Azure (run AFTER DNS propagates):"
Write-Host "       ./Add-CustomDomain.ps1 -AppName '$AppName' -ResourceGroup '$ResourceGroup'"
Write-Host "  3. Push to main (or trigger the workflow) to deploy the site."
