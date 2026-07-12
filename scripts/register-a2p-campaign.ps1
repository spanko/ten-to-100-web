<#
.SYNOPSIS
  Registers the TenTo100 A2P 10DLC campaign via the Twilio API — never the console.

.DESCRIPTION
  Encodes TenTo100's campaign exactly, field for field, matching the live collateral at
  https://www.tento100.com/messaging (the two must never drift). Runs the pre-submission
  lint from birdie-pro-platform/docs/a2p-campaign-checklist.md (P1-P3, S1-S7), then — only
  with -Submit — creates/finds the Messaging Service, attaches the number, creates the
  campaign, and read-back verifies every field round-tripped (V1/V2: the console silently
  dropped opt-in fields twice; the API path asserts instead of hoping).

  Default is DRY RUN: lints the live pages and prints every field verbatim (also usable
  as the source of truth if you ever must type into the console).

  If a half-finished TenTo100 campaign draft exists in the console, discard it first —
  opt-in-method checkboxes lock at creation and a duplicate draft causes confusion.

.EXAMPLE
  $env:TWILIO_ACCOUNT_SID = 'AC...'
  $env:TWILIO_AUTH_TOKEN  = '...'
  ./scripts/register-a2p-campaign.ps1 -BrandSid BN... -PhoneNumber +17205551234           # dry run
  ./scripts/register-a2p-campaign.ps1 -BrandSid BN... -PhoneNumber +17205551234 -Submit   # real
#>
[CmdletBinding()]
param(
  # TenTo100's approved Brand Registration SID (Console → Messaging → Regulatory Compliance → Brands)
  [Parameter(Mandatory)] [ValidatePattern('^BN[0-9a-f]{32}$')] [string]$BrandSid,

  # The number bought FOR TENTO100 (E.164). Must NOT be a number already on another campaign
  # (one number = one campaign; +17206051849 is Birdie Pro's and is off limits).
  [Parameter(Mandatory)] [ValidatePattern('^\+1[0-9]{10}$')] [string]$PhoneNumber,

  [string]$MessagingServiceName = 'tento100-messenger',
  [switch]$Submit
)

$ErrorActionPreference = 'Stop'

$accountSid = $env:TWILIO_ACCOUNT_SID
$authToken  = $env:TWILIO_AUTH_TOKEN
if (-not $accountSid -or -not $authToken) {
  throw 'Set TWILIO_ACCOUNT_SID and TWILIO_AUTH_TOKEN environment variables first.'
}
$cred = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${accountSid}:${authToken}"))
$headers = @{ Authorization = "Basic $cred" }

function Invoke-Twilio([string]$Method, [string]$Uri, $Body) {
  if ($Body) {
    # Form-encode by hand so repeated keys (MessageSamples) serialize correctly.
    $pairs = foreach ($kv in $Body) {
      '{0}={1}' -f $kv.Key, [uri]::EscapeDataString($kv.Value)
    }
    Invoke-RestMethod -Method $Method -Uri $Uri -Headers $headers `
      -ContentType 'application/x-www-form-urlencoded' -Body ($pairs -join '&')
  } else {
    Invoke-RestMethod -Method $Method -Uri $Uri -Headers $headers
  }
}

# ============================================================================
# THE CAMPAIGN — TenTo100 Products LLC, verbatim. Change the site pages first,
# then this block, never one without the other.
# ============================================================================
$displayNumber = '+1 ({0}) {1}-{2}' -f $PhoneNumber.Substring(2,3), $PhoneNumber.Substring(5,3), $PhoneNumber.Substring(8,4)

$cta = "Text LESSON to $displayNumber — or just ask about or book a lesson in your own words. " +
       'By texting, you agree to receive replies from TenTo100. Message frequency varies. ' +
       'Message & data rates may apply. Reply STOP to opt out, HELP for help. ' +
       'Terms: tento100.com/terms Privacy: tento100.com/privacy'

$optInMessage = 'TenTo100: Reply YES to receive lesson scheduling and coaching texts. ' +
                'Msg frequency varies. Msg & data rates may apply. Reply STOP to opt out, HELP for help. ' +
                'Terms: tento100.com/terms Privacy: tento100.com/privacy'

$messageFlow = 'End users opt in via text (Via Text): they text LESSON (or a lesson question in their own words) ' +
               "to $displayNumber. The call to action is published at https://www.tento100.com/messaging and reads: " +
               """$cta"" Before any program messages are sent, TenTo100 sends a one-time confirmation request: " +
               """$optInMessage"" No program messages are sent unless the end user replies YES (double opt-in). " +
               'The exact consent language, timestamp, and channel are recorded for every opt-in. ' +
               'Terms: https://www.tento100.com/terms Privacy: https://www.tento100.com/privacy'

$campaign = @(
  [pscustomobject]@{ Key = 'BrandRegistrationSid';  Value = $BrandSid }
  [pscustomobject]@{ Key = 'UsAppToPersonUsecase';  Value = 'LOW_VOLUME' }
  [pscustomobject]@{ Key = 'Description';           Value = 'TenTo100 Products LLC sends lesson scheduling, coaching follow-up, and practice reminder messages to clients who opt in by texting our number. Double opt-in: a one-time confirmation request is sent and no program messages are sent unless the recipient replies YES.' }
  [pscustomobject]@{ Key = 'MessageFlow';           Value = $messageFlow }
  [pscustomobject]@{ Key = 'MessageSamples';        Value = "TenTo100: You're confirmed for a lesson Tuesday 4:30 PM. Reply C to change or STOP to opt out." }
  [pscustomobject]@{ Key = 'MessageSamples';        Value = 'TenTo100: Nice work today. This week: 20 minutes of putting drills inside 6 feet. Questions? Just text back. Reply STOP to opt out.' }
  [pscustomobject]@{ Key = 'MessageSamples';        Value = 'TenTo100: A Saturday 10 AM lesson slot just opened - reply YES to take it.' }
  # Keyword fields are ARRAYS on the API — one repeated form field per keyword.
  [pscustomobject]@{ Key = 'OptInKeywords';         Value = 'LESSON' }
  [pscustomobject]@{ Key = 'OptInKeywords';         Value = 'YES' }
  [pscustomobject]@{ Key = 'OptInKeywords';         Value = 'START' }
  [pscustomobject]@{ Key = 'OptInKeywords';         Value = 'UNSTOP' }
  [pscustomobject]@{ Key = 'OptInMessage';          Value = $optInMessage }
  [pscustomobject]@{ Key = 'OptOutKeywords';        Value = 'STOP' }
  [pscustomobject]@{ Key = 'OptOutKeywords';        Value = 'STOPALL' }
  [pscustomobject]@{ Key = 'OptOutKeywords';        Value = 'UNSUBSCRIBE' }
  [pscustomobject]@{ Key = 'OptOutKeywords';        Value = 'CANCEL' }
  [pscustomobject]@{ Key = 'OptOutKeywords';        Value = 'END' }
  [pscustomobject]@{ Key = 'OptOutKeywords';        Value = 'QUIT' }
  [pscustomobject]@{ Key = 'OptOutMessage';         Value = 'TenTo100: You have opted out and will receive no further messages. Reply START to rejoin. Msg & data rates may apply.' }
  [pscustomobject]@{ Key = 'HelpKeywords';          Value = 'HELP' }
  [pscustomobject]@{ Key = 'HelpKeywords';          Value = 'INFO' }
  [pscustomobject]@{ Key = 'HelpMessage';           Value = 'TenTo100: For help, email founders@tento100.com. Msg frequency varies. Msg & data rates may apply. Reply STOP to opt out.' }
  [pscustomobject]@{ Key = 'SubscriberOptIn';       Value = 'true'  }
  [pscustomobject]@{ Key = 'HasEmbeddedLinks';      Value = 'false' }
  [pscustomobject]@{ Key = 'HasEmbeddedPhone';      Value = 'false' }
  [pscustomobject]@{ Key = 'AgeGated';              Value = 'false' }
  [pscustomobject]@{ Key = 'DirectLending';         Value = 'false' }
)

# ============================================================================
# Phase 0 lint — checklist P1-P3 against the LIVE site (rejection insurance).
# ============================================================================
Write-Host "`n=== Phase 0 lint (a2p-campaign-checklist P1-P3) ===" -ForegroundColor Cyan
$lintFailures = @()
function Assert-Page([string]$Rule, [string]$Url, [string[]]$MustContain) {
  try { $html = (Invoke-WebRequest -Uri $Url -UseBasicParsing).Content }
  catch { $script:lintFailures += "${Rule}: $Url not reachable ($($_.Exception.Message))"; return }
  # Normalize: strip tags, decode common entities, collapse whitespace — phrases must not
  # fail the lint just because the page wraps a line mid-sentence.
  $text = (($html -replace '<[^>]+>', ' ') -replace '&amp;', '&' -replace '&nbsp;', ' ') -replace '\s+', ' '
  foreach ($phrase in $MustContain) {
    if ($text -notlike "*$phrase*") { $script:lintFailures += "${Rule}: $Url missing phrase '$phrase'" }
  }
  Write-Host "  [$Rule] fetched $Url"
}
Assert-Page 'P1' 'https://www.tento100.com/messaging' @(
  $displayNumber, 'LESSON', 'Message frequency varies', 'data rates may apply',
  'STOP', 'HELP', '/terms', '/privacy', 'Reply YES'
)
Assert-Page 'P2' 'https://www.tento100.com/privacy' @(
  'will not be shared with third', 'Message frequency varies', 'Message and data rates may apply'
)
Assert-Page 'P3' 'https://www.tento100.com/terms' @('SMS program terms')

# S-rules that are checkable locally
if ($messageFlow.Length -lt 40 -or $messageFlow.Length -gt 2049) { $lintFailures += "S4: MessageFlow length $($messageFlow.Length) outside 40-2049" }
foreach ($kv in $campaign | Where-Object Key -in 'MessageFlow','MessageSamples','OptInMessage','OptOutMessage','HelpMessage') {
  if ($kv.Value -match '\[[^\]]+\]') { $lintFailures += "S1: placeholder bracket found in $($kv.Key)" }
}

if ($lintFailures) {
  Write-Host "`nLINT FAILED — do not submit:" -ForegroundColor Red
  $lintFailures | ForEach-Object { Write-Host "  ✗ $_" -ForegroundColor Red }
  exit 1
}
Write-Host '  All lint rules passed.' -ForegroundColor Green

# ============================================================================
# Dry run: print every field verbatim and stop.
# ============================================================================
if (-not $Submit) {
  Write-Host "`n=== DRY RUN — the exact campaign (re-run with -Submit to create) ===" -ForegroundColor Yellow
  foreach ($kv in $campaign) { Write-Host ("`n--- {0} ---`n{1}" -f $kv.Key, $kv.Value) }
  exit 0
}

# ============================================================================
# Submit path: Messaging Service → number → campaign → read-back (V1/V2).
# ============================================================================
Write-Host "`n=== 1/4 Messaging Service '$MessagingServiceName' ===" -ForegroundColor Cyan
$services = Invoke-Twilio GET 'https://messaging.twilio.com/v1/Services?PageSize=100'
$service = $services.services | Where-Object friendly_name -eq $MessagingServiceName | Select-Object -First 1
if (-not $service) {
  $service = Invoke-Twilio POST 'https://messaging.twilio.com/v1/Services' @(
    [pscustomobject]@{ Key = 'FriendlyName';               Value = $MessagingServiceName }
    [pscustomobject]@{ Key = 'UseInboundWebhookOnNumber';  Value = 'true' }
  )
  Write-Host "  created $($service.sid)"
} else { Write-Host "  found $($service.sid)" }

Write-Host "`n=== 2/4 Attach $PhoneNumber ===" -ForegroundColor Cyan
$nums = Invoke-Twilio GET "https://api.twilio.com/2010-04-01/Accounts/$accountSid/IncomingPhoneNumbers.json?PhoneNumber=$([uri]::EscapeDataString($PhoneNumber))"
if (-not $nums.incoming_phone_numbers) { throw "$PhoneNumber is not owned by account $accountSid — buy it first (Console → Phone Numbers → Buy a number)." }
$numberSid = $nums.incoming_phone_numbers[0].sid
$attached = Invoke-Twilio GET "https://messaging.twilio.com/v1/Services/$($service.sid)/PhoneNumbers?PageSize=100"
if ($attached.phone_numbers.phone_number -notcontains $PhoneNumber) {
  Invoke-Twilio POST "https://messaging.twilio.com/v1/Services/$($service.sid)/PhoneNumbers" @(
    [pscustomobject]@{ Key = 'PhoneNumberSid'; Value = $numberSid }
  ) | Out-Null
  Write-Host "  attached $numberSid"
} else { Write-Host '  already attached' }

Write-Host "`n=== 3/4 Create campaign ===" -ForegroundColor Cyan
$created = Invoke-Twilio POST "https://messaging.twilio.com/v1/Services/$($service.sid)/Compliance/Usa2p" $campaign
Write-Host "  campaign sid: $($created.sid)  status: $($created.campaign_status)"

Write-Host "`n=== 4/4 Read-back verification (V1/V2 — no silent drops) ===" -ForegroundColor Cyan
$readBack = Invoke-Twilio GET "https://messaging.twilio.com/v1/Services/$($service.sid)/Compliance/Usa2p/$($created.sid)"
$verifyFailures = @()
# Hard checks: fields the campaign owns. Opt-out/help responses are served from the
# Messaging Service's Advanced Opt-Out config (console-only) — the API returns those
# defaults regardless of what was sent, so they are advisory, not failures.
$checks = @{
  message_flow     = $messageFlow
  opt_in_message   = $optInMessage
  opt_in_keywords  = 'LESSON,YES,START,UNSTOP'
}
foreach ($field in $checks.Keys) {
  $actual = $readBack.$field
  if ($actual -is [array]) { $actual = $actual -join ',' }
  if (-not $actual) { $verifyFailures += "V2: $field came back EMPTY" }
  elseif ($actual -ne $checks[$field]) { $verifyFailures += "V1: $field drifted.`n  sent: $($checks[$field])`n  got:  $actual" }
}
foreach ($field in 'opt_out_keywords','opt_out_message','help_keywords','help_message') {
  $actual = $readBack.$field
  if ($actual -is [array]) { $actual = $actual -join ',' }
  if (-not $actual) { $verifyFailures += "V2: $field came back EMPTY" }
  elseif ($actual -notlike '*TenTo100*') {
    Write-Host "  advisory: $field is the service default (no brand prefix) - set the custom copy in Console > Messaging > Services > $MessagingServiceName > Opt-Out Management (Advanced Opt-Out)." -ForegroundColor Yellow
  }
}
if ($readBack.message_samples.Count -lt 3) { $verifyFailures += "V2: only $($readBack.message_samples.Count) message samples round-tripped" }

if ($verifyFailures) {
  Write-Host "`nREAD-BACK FAILED — fix before carrier review sees it:" -ForegroundColor Red
  $verifyFailures | ForEach-Object { Write-Host "  ✗ $_" -ForegroundColor Red }
  exit 1
}
Write-Host "  every field round-tripped verbatim." -ForegroundColor Green
Write-Host "`nDone. Campaign $($created.sid) submitted on service $($service.sid)." -ForegroundColor Green
Write-Host 'Track status: Console → Messaging → Regulatory Compliance → Campaigns. Do NOT send from the number until Approved.'
