# Infrastructure & deployment scripts

Automated provisioning for the TenTo100 site: an **Azure Static Web App**
(Free tier) plus **Cloudflare DNS** for `www.tento100.com` with an apex →
`www` redirect.

> ⚠️ These scripts create real cloud resources and change live DNS. Read the
> run order below. Each step is idempotent and safe to re-run.

## Files

| File | What it does |
| --- | --- |
| `main.bicep` | Declares the Static Web App resource (Free, token-deployed, PR previews on). |
| `Deploy-Azure.ps1` | Creates the resource group, deploys the Bicep, reads the deployment token, and stores it as the `AZURE_STATIC_WEB_APPS_API_TOKEN` GitHub secret. |
| `Configure-CloudflareDns.ps1` | Creates the `www` CNAME (DNS-only), the apex CNAME (proxied), and the apex → `www` 301 redirect rule. |
| `Add-CustomDomain.ps1` | Registers `www.tento100.com` on the SWA (CNAME-delegation) and triggers managed-cert issuance. |

## Prerequisites

- **PowerShell 7+** (`pwsh`)
- **Azure CLI** (`az`), logged in: `az login`
- **GitHub CLI** (`gh`), logged in with repo admin: `gh auth login`
  (needed only for the auto-secret step; the repo must already exist on GitHub)
- A **Cloudflare API token** scoped to the `tento100.com` zone with:
  - `Zone : DNS : Edit`
  - `Zone : Dynamic Redirect : Edit`
  - `Zone : Zone : Read`

  Create at **Cloudflare → My Profile → API Tokens → Create Token → Custom
  token**. Then expose it to the DNS script:

  ```powershell
  $env:CLOUDFLARE_API_TOKEN = '<your-token>'
  ```

## Run order

```powershell
# from the infra/ directory

# 1. Provision Azure + wire the deploy token into GitHub Actions.
./Deploy-Azure.ps1 -Repo 'your-org/ten-to-100-web'
#    -> prints the SWA default hostname, e.g. happy-sea-123.azurestaticapps.net

# 2. Configure Cloudflare DNS + apex redirect (use the hostname from step 1).
$env:CLOUDFLARE_API_TOKEN = '<your-token>'
./Configure-CloudflareDns.ps1 -SwaHostname 'happy-sea-123.azurestaticapps.net'

# 3. Wait for the www CNAME to propagate, then register it in Azure.
#    (Resolve-DnsName www.tento100.com  should return the SWA host.)
./Add-CustomDomain.ps1

# 4. Deploy the site: push to main (or run the GitHub Actions workflow).
#    The workflow uses the secret set in step 1.
```

You can preview the DNS changes without applying them:

```powershell
./Configure-CloudflareDns.ps1 -SwaHostname '...' -WhatIf
```

## Why these specific DNS settings

- **`www` is DNS-only (grey cloud).** Azure validates the custom domain by
  checking the CNAME and then issues its own managed TLS certificate. If the
  record were proxied, the CNAME would resolve to Cloudflare's IPs and Azure
  validation / cert issuance would fail.
- **Apex is proxied (orange cloud).** A redirect rule only fires for traffic
  that passes through Cloudflare's edge, so the apex record must be proxied.
  Cloudflare's Universal SSL covers `tento100.com`, so the 301 is served over
  HTTPS. The apex is never registered in Azure — it only redirects.
- **Canonical host is `www`.** The site's `<link rel="canonical">` and sitemap
  already point at `https://www.tento100.com`, matching this setup.

## Customizing names / region

Defaults: resource group `rg-tento100-web`, app `swa-tento100-web`, region
`eastus2`. Override via parameters, e.g.:

```powershell
./Deploy-Azure.ps1 -ResourceGroup 'rg-foo' -AppName 'swa-foo' -Location 'westus2'
```

Free-tier SWA is only available in: `westus2`, `centralus`, `eastus2`,
`westeurope`, `eastasia`.

## Tear down

```powershell
az group delete --name rg-tento100-web --yes --no-wait
```

(Then remove the Cloudflare records / redirect rule in the dashboard, and delete
the `AZURE_STATIC_WEB_APPS_API_TOKEN` GitHub secret if no longer needed.)
