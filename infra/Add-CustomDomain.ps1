#requires -Version 7.0
<#
.SYNOPSIS
    Register www.tento100.com as a custom domain on the Azure Static Web App.

.DESCRIPTION
    Uses CNAME-delegation validation: Azure confirms ownership by checking that
    the www CNAME points at the SWA default hostname, then issues a free managed
    TLS certificate. Run this AFTER Configure-CloudflareDns.ps1 and after the
    www CNAME has propagated (DNS-only / grey cloud in Cloudflare).

    The apex (tento100.com) is intentionally NOT registered here — Cloudflare
    301-redirects it to www, so it never serves from Azure.

.PREREQUISITES
    - Azure CLI logged in (az login).
    - www CNAME already created and resolvable (see Configure-CloudflareDns.ps1).

.EXAMPLE
    ./Add-CustomDomain.ps1
#>
[CmdletBinding()]
param(
    [string] $AppName = 'swa-tento100-web',
    [string] $ResourceGroup = 'rg-tento100-web',
    [string] $Hostname = 'www.tento100.com',

    # Skip the soft DNS pre-check and don't block on validation.
    [switch] $NoWait
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    throw "Azure CLI 'az' not found. Install: https://aka.ms/azure-cli"
}
if (-not (az account show 2>$null)) { throw "Not logged in to Azure. Run: az login" }

# Soft pre-check: warn (don't fail) if the CNAME doesn't resolve yet.
if (-not $NoWait) {
    try {
        $cname = Resolve-DnsName -Name $Hostname -Type CNAME -ErrorAction Stop |
            Where-Object { $_.Type -eq 'CNAME' } | Select-Object -First 1
        if ($cname) {
            Write-Host "    $Hostname -> $($cname.NameHost)" -ForegroundColor DarkGray
        }
    }
    catch {
        Write-Warning "Could not resolve a CNAME for $Hostname yet. DNS may still be propagating; Azure validation will fail until it resolves."
    }
}

Write-Host "==> Registering custom domain '$Hostname' (cname-delegation)" -ForegroundColor Cyan
$azArgs = @(
    'staticwebapp', 'hostname', 'set',
    '--name', $AppName,
    '--resource-group', $ResourceGroup,
    '--hostname', $Hostname,
    '--validation-method', 'cname-delegation'
)
if ($NoWait) { $azArgs += '--no-wait' }

az @azArgs
if ($LASTEXITCODE -ne 0) {
    throw "Failed to register custom domain. Confirm the www CNAME resolves to the SWA host and is DNS-only (not proxied) in Cloudflare."
}

Write-Host ""
Write-Host "Custom domain registered." -ForegroundColor Green
if ($NoWait) {
    Write-Host "Validation + certificate issuance continue in the background." -ForegroundColor Yellow
    Write-Host "Check status: az staticwebapp hostname list -n $AppName -g $ResourceGroup -o table"
}
else {
    Write-Host "Azure has validated the domain and is issuing the managed TLS cert."
    Write-Host "Verify: open https://$Hostname (and https://tento100.com should 301 to it)."
}
