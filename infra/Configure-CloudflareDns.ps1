#requires -Version 7.0
<#
.SYNOPSIS
    Configure Cloudflare DNS for www.tento100.com (Azure SWA) + apex redirect.

.DESCRIPTION
    Creates / updates (idempotent):
      1. www  CNAME  -> <SWA default hostname>   [DNS only / grey cloud]
         DNS-only is REQUIRED so Azure can validate the domain and issue its
         managed TLS certificate. If proxied, Azure validation/cert will fail.
      2. apex CNAME  -> www.<domain>             [Proxied / orange cloud]
         (Cloudflare flattens the apex CNAME. Proxied so the redirect rule
         below can fire at Cloudflare's edge.)
      3. A "Single Redirect" (Dynamic Redirect) rule: 301 tento100.com/*  ->
         https://www.tento100.com/* (path + query preserved).

.PREREQUISITES
    A Cloudflare API token (scoped to the tento100.com zone) with:
      - Zone : DNS : Edit
      - Zone : Dynamic Redirect : Edit
      - Zone : Zone : Read
    Provide it via -ApiToken or the CLOUDFLARE_API_TOKEN environment variable.

.EXAMPLE
    $env:CLOUDFLARE_API_TOKEN = '<token>'
    ./Configure-CloudflareDns.ps1 -SwaHostname 'happy-sea-123.azurestaticapps.net'
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    # The Azure SWA default hostname (output of Deploy-Azure.ps1).
    [Parameter(Mandatory)]
    [string] $SwaHostname,

    [string] $Domain = 'tento100.com',
    [string] $WwwSubdomain = 'www',

    [string] $ApiToken = $env:CLOUDFLARE_API_TOKEN,

    # Skip the apex->www redirect rule (use when the token lacks the
    # Zone:Dynamic Redirect scope, or you'll create the rule by hand).
    [switch] $SkipRedirect
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ApiToken)) {
    throw "No Cloudflare API token. Pass -ApiToken or set CLOUDFLARE_API_TOKEN."
}

$apiBase = 'https://api.cloudflare.com/client/v4'
$headers = @{ Authorization = "Bearer $ApiToken" }
$wwwFqdn = "$WwwSubdomain.$Domain"

function Invoke-Cf {
    param(
        [Parameter(Mandatory)][string] $Method,
        [Parameter(Mandatory)][string] $Path,
        [object] $Body
    )
    $params = @{
        Method      = $Method
        Uri         = "$apiBase$Path"
        Headers     = $headers
        ContentType = 'application/json'
    }
    if ($PSBoundParameters.ContainsKey('Body') -and $null -ne $Body) {
        $params.Body = ($Body | ConvertTo-Json -Depth 12)
    }
    $resp = Invoke-RestMethod @params
    if (-not $resp.success) {
        $msg = ($resp.errors | ConvertTo-Json -Depth 6)
        throw "Cloudflare API error ($Method $Path): $msg"
    }
    return $resp
}

# --- resolve zone -----------------------------------------------------------
Write-Host "==> Resolving Cloudflare zone for $Domain" -ForegroundColor Cyan
$zone = (Invoke-Cf -Method GET -Path "/zones?name=$Domain&status=active").result
if (-not $zone -or $zone.Count -eq 0) {
    throw "Zone '$Domain' not found on this Cloudflare account (or token lacks Zone:Read)."
}
$zoneId = $zone[0].id
Write-Host "    Zone id: $zoneId"

# --- DNS record upsert -------------------------------------------------------
function Set-CfDnsRecord {
    param(
        [Parameter(Mandatory)][string] $Type,
        [Parameter(Mandatory)][string] $Name,     # full FQDN
        [Parameter(Mandatory)][string] $Content,
        [bool] $Proxied = $false
    )
    $existing = (Invoke-Cf -Method GET -Path "/zones/$zoneId/dns_records?type=$Type&name=$Name").result
    $body = @{
        type    = $Type
        name    = $Name
        content = $Content
        ttl     = 1          # 1 = automatic
        proxied = $Proxied
    }
    $cloud = if ($Proxied) { 'proxied' } else { 'DNS-only' }
    if ($existing -and $existing.Count -gt 0) {
        $id = $existing[0].id
        if ($PSCmdlet.ShouldProcess($Name, "Update $Type -> $Content ($cloud)")) {
            Invoke-Cf -Method PUT -Path "/zones/$zoneId/dns_records/$id" -Body $body | Out-Null
            Write-Host "    Updated $Type $Name -> $Content [$cloud]" -ForegroundColor Green
        }
    }
    else {
        if ($PSCmdlet.ShouldProcess($Name, "Create $Type -> $Content ($cloud)")) {
            Invoke-Cf -Method POST -Path "/zones/$zoneId/dns_records" -Body $body | Out-Null
            Write-Host "    Created $Type $Name -> $Content [$cloud]" -ForegroundColor Green
        }
    }
}

Write-Host "==> Upserting DNS records" -ForegroundColor Cyan
# www -> SWA host, DNS only so Azure validation + managed cert work.
Set-CfDnsRecord -Type 'CNAME' -Name $wwwFqdn -Content $SwaHostname -Proxied $false
# apex -> www (flattened), proxied so the redirect rule can fire at the edge.
Set-CfDnsRecord -Type 'CNAME' -Name $Domain -Content $wwwFqdn -Proxied $true

# --- apex -> www redirect (Dynamic Redirect ruleset) -------------------------
if ($SkipRedirect) {
    Write-Host "==> Skipping apex -> www redirect rule (-SkipRedirect)" -ForegroundColor Yellow
    Write-Host "    Create it manually: Cloudflare > Rules > Redirect Rules > Create rule" -ForegroundColor Yellow
    Write-Host "      When incoming requests match: hostname equals '$Domain'" -ForegroundColor Yellow
    Write-Host "      Then: Dynamic redirect -> concat(\"https://$wwwFqdn\", http.request.uri.path)" -ForegroundColor Yellow
    Write-Host "      Status 301, Preserve query string: on" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "DNS records configured (redirect skipped)." -ForegroundColor Green
    return
}

Write-Host "==> Configuring apex -> www 301 redirect rule" -ForegroundColor Cyan
$phasePath = "/zones/$zoneId/rulesets/phases/http_request_dynamic_redirect/entrypoint"
$ruleDescription = 'TenTo100 apex to www redirect'

# Fetch any existing rules in this phase so we don't clobber unrelated ones.
$existingRules = @()
try {
    $entry = Invoke-Cf -Method GET -Path $phasePath
    if ($entry.result.rules) {
        $existingRules = @($entry.result.rules | Where-Object { $_.description -ne $ruleDescription })
    }
}
catch {
    # No entrypoint ruleset yet for this phase — that's fine, we'll create it.
    Write-Verbose "No existing dynamic_redirect entrypoint ($_)."
}

$redirectRule = @{
    action      = 'redirect'
    description = $ruleDescription
    enabled     = $true
    expression  = "(http.host eq `"$Domain`")"
    action_parameters = @{
        from_value = @{
            status_code           = 301
            preserve_query_string = $true
            target_url            = @{
                expression = "concat(`"https://$wwwFqdn`", http.request.uri.path)"
            }
        }
    }
}

$body = @{ rules = @($existingRules + $redirectRule) }
if ($PSCmdlet.ShouldProcess($Domain, "Set apex->www 301 redirect rule")) {
    Invoke-Cf -Method PUT -Path $phasePath -Body $body | Out-Null
    Write-Host "    Redirect rule active: https://$Domain/* -> https://$wwwFqdn/*" -ForegroundColor Green
}

Write-Host ""
Write-Host "DNS configured." -ForegroundColor Green
Write-Host "Note: DNS-only (grey) on '$wwwFqdn' is intentional — leave it un-proxied" -ForegroundColor Yellow
Write-Host "      so Azure can validate the domain and issue its managed certificate." -ForegroundColor Yellow
Write-Host "Next: once '$wwwFqdn' resolves, run Add-CustomDomain.ps1 to register it in Azure."
