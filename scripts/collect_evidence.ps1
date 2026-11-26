<#
Evidence collection for the Lindhav Bank AI audit.

What it does
  Gathers the evidence the Access Review Assistant (AI-003) and the audit report work from.
  It only reads. It never changes anything in Entra or Azure.
  1. Runs the first lab's agent inventory script unchanged, with both labs' intake records.
  2. Lists the identities that act for an agent or only exist for one, which the inventory misses.
  3. Lists Lindhav staff with their manager and whether they're enabled.
  4. Pulls agent usage from the Foundry traces in Log Analytics (agent runs, tool calls, Graph URLs).
  5. Pulls the disable approval Logic App's run history.
  6. Pulls the Azure Activity Log for rg-lindhav-ai.
  Every file gets a line in evidence/sources.csv saying where it came from and when.

Inputs
  ..\..\ai-agent-governance-lab\docs\agent-intake.md and ..\docs\agent-intake.md
  ..\..\ai-agent-governance-lab\scripts\agent_inventory.ps1
  Microsoft Graph and Azure CLI, signed in as me with read access

Outputs (all in evidence/)
  agent_inventory.csv, related_identities.csv, staff.csv, usage_traces.csv,
  usage_logicapp_runs.csv, activity_log.csv, sources.csv

How to run
  Run it in its own PowerShell 7 window, not the VS Code terminal (the Graph sign-in popup fails there).
  pwsh -File scripts/collect_evidence.ps1
  pwsh -File scripts/collect_evidence.ps1 -OutDir evidence/after-fixes   (rerun after fixes)
#>

param(
    [string]$TenantId      = 'dd8d5970-0f8f-4b44-87c3-81181e38978b',
    [string]$Subscription  = 'havlund-lab',
    [string]$ResourceGroup = 'rg-lindhav-ai',
    [string]$Workspace     = 'DefaultWorkspace-2042cf89-35e3-4360-9812-6126ae418d63',
    [string]$LogicApp      = 'lindhav-ai001-disable-approval',
    [int]$Days             = 30,
    # Folder under the lab root to write to. A rerun after fixes uses evidence/after-fixes,
    # so the files the answer key points to stay as they were.
    [string]$OutDir        = 'evidence'
)

$ErrorActionPreference = 'Stop'
$labRoot   = Split-Path $PSScriptRoot -Parent
$lab1Root  = Join-Path (Split-Path $labRoot -Parent) 'ai-agent-governance-lab'
$outDir    = Join-Path $labRoot $OutDir
New-Item -ItemType Directory -Force $outDir | Out-Null
$sources   = @()
function Format-Utc($Value) {
    # Every date in the evidence files is written as yyyy-MM-dd HH:mm:ss UTC.
    # ConvertFrom-Json turns ISO strings into DateTime (Utc or Local), others stay strings.
    if ($null -eq $Value -or "$Value" -eq '') { return '' }
    if ($Value -is [datetime]) {
        $d = if ($Value.Kind -eq 'Local') { $Value.ToUniversalTime() } else { $Value }
    } else {
        $d = [datetimeoffset]::Parse("$Value", [cultureinfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AssumeUniversal).UtcDateTime
    }
    return $d.ToString('yyyy-MM-dd HH:mm:ss', [cultureinfo]::InvariantCulture) + ' UTC'
}

$stamp     = Format-Utc (Get-Date).ToUniversalTime()

function Add-Source($File, $From, $Note) {
    $script:sources += [pscustomobject]@{ File = $File; CollectedUtc = $stamp; Source = $From; Note = $Note }
}

# ---------- 1. Agent inventory, first lab's script unchanged ----------

$merged = Join-Path $env:TEMP 'lindhav-intake-merged.md'
Get-Content (Join-Path $lab1Root 'docs\agent-intake.md'), (Join-Path $labRoot 'docs\agent-intake.md') | Set-Content $merged
$inventoryOut = Join-Path $outDir 'agent_inventory.csv'
& (Join-Path $lab1Root 'scripts\agent_inventory.ps1') -IntakePath $merged -OutPath $inventoryOut
Remove-Item $merged
Add-Source 'agent_inventory.csv' 'Graph v1.0 agent identities, sponsors, owners, grants, credentials, plus az role assignment list' 'First lab script agent_inventory.ps1, both intake files'

# The inventory script left Graph and Azure CLI signed in. Reuse them.
az account set --subscription $Subscription

function Get-Graph([string]$Uri) {
    $items = @(); $next = $Uri
    while ($next) {
        $page = Invoke-MgGraphRequest -Method GET -Uri $next -OutputType PSObject
        if ($null -ne $page.PSObject.Properties['value']) { $items += $page.value; $next = $page.'@odata.nextLink' }
        else { return $page }
    }
    return $items
}

function Get-AppRoleNames($SpId) {
    # App permissions this service principal holds, as "Resource Permission"
    $out = @()
    foreach ($a in @(Get-Graph "https://graph.microsoft.com/v1.0/servicePrincipals/$SpId/appRoleAssignments")) {
        $res  = Get-Graph "https://graph.microsoft.com/v1.0/servicePrincipals/$($a.resourceId)?`$select=displayName,appRoles"
        $role = $res.appRoles | Where-Object id -eq $a.appRoleId
        $out += "$($res.displayName) $(if ($role) { $role.value } else { $a.appRoleId })"
    }
    return $out
}

function Get-CredText($App) {
    $c = @()
    foreach ($p in @($App.passwordCredentials)) { if ($p) { $c += "secret '$($p.displayName)' ends $(Format-Utc $p.endDateTime)" } }
    foreach ($k in @($App.keyCredentials))      { if ($k) { $c += "certificate ends $(Format-Utc $k.endDateTime)" } }
    if ($c.Count -eq 0) { 'none' } else { $c -join ' | ' }
}

# ---------- 2. Identities that act for an agent or only exist for one ----------

$related = @()

# The Logic App's managed identity. It disables accounts for AI-001 after an approval.
$la = az resource show -g $ResourceGroup -n $LogicApp --resource-type Microsoft.Logic/workflows -o json | ConvertFrom-Json
$laSp = Get-Graph "https://graph.microsoft.com/v1.0/servicePrincipals/$($la.identity.principalId)?`$select=id,displayName,accountEnabled,servicePrincipalType"
$related += [pscustomobject]@{
    ForAgent    = 'AI-001'
    Identity    = "$LogicApp (managed identity)"
    ObjectId    = $laSp.id
    Type        = $laSp.servicePrincipalType
    Enabled     = $laSp.accountEnabled
    Access      = (Get-AppRoleNames $laSp.id) -join ', '
    Credentials = 'managed identity, no secret'
    Note        = 'Acts only after the AI Risk Officer approves a disable request'
}

# The app registration that only exists so AI-001 can file a disable request.
# More than one app registration has this name, so pick the one that defines DisableRequest.Submit
# and list the others in the note instead of reading the wrong one.
$apiAll   = @(Get-Graph "https://graph.microsoft.com/v1.0/applications?`$filter=displayName eq 'lindhav-disable-request-api'")
$api      = @($apiAll | Where-Object { @($_.appRoles | Where-Object value -eq 'DisableRequest.Submit').Count -gt 0 })
if ($api.Count -eq 0) { $api = $apiAll }
$apiOther = @($apiAll | Where-Object { $_.id -ne $api[0].id })
if ($api.Count -gt 0) {
    $apiSp = @(Get-Graph "https://graph.microsoft.com/v1.0/servicePrincipals?`$filter=appId eq '$($api[0].appId)'")
    $assigned = @()
    if ($apiSp.Count -gt 0) {
        $submitRole = @($apiSp[0].appRoles | Where-Object value -eq 'DisableRequest.Submit')
        $submitIds  = @($submitRole | ForEach-Object { $_.id })
        # First ask the API's own service principal who holds the role.
        foreach ($r in @(Get-Graph "https://graph.microsoft.com/v1.0/servicePrincipals/$($apiSp[0].id)/appRoleAssignedTo")) {
            if ($r -and ($submitIds.Count -eq 0 -or $submitIds -contains $r.appRoleId)) {
                $name = $r.principalDisplayName
                if (-not $name -and $r.principalId) { $name = (Get-Graph "https://graph.microsoft.com/v1.0/servicePrincipals/$($r.principalId)?`$select=displayName").displayName }
                if ($name) { $assigned += $name }
            }
        }
        # If that comes back empty, check from the holder side. Every identity this lab knows about
        # (agent identities, the Logic App and the project identity) lists its own app role assignments.
        if ($assigned.Count -eq 0) {
            $projIds    = @(Get-Graph "https://graph.microsoft.com/v1.0/servicePrincipals?`$filter=displayName eq 'lindhav-foundry/projects/lindhav-agents'&`$select=id" | ForEach-Object { $_.id })
            $candidates = @(Import-Csv $inventoryOut | ForEach-Object { $_.ObjectId }) + @($laSp.id) + $projIds
            foreach ($cid in ($candidates | Where-Object { $_ } | Select-Object -Unique)) {
                try { $held = @(Get-Graph "https://graph.microsoft.com/v1.0/servicePrincipals/$cid/appRoleAssignments") } catch { $held = @() }
                foreach ($a in $held) {
                    if ($a -and $a.resourceId -eq $apiSp[0].id -and ($submitIds.Count -eq 0 -or $submitIds -contains $a.appRoleId)) { $assigned += $a.principalDisplayName }
                }
            }
        }
        $assigned = @($assigned | Select-Object -Unique)
    }
    $related += [pscustomobject]@{
        ForAgent    = 'AI-001'
        Identity    = 'lindhav-disable-request-api (app registration)'
        ObjectId    = $api[0].id
        Type        = 'Application'
        Enabled     = if ($apiSp.Count -gt 0) { $apiSp[0].accountEnabled } else { '' }
        Access      = "App role DisableRequest.Submit given to: $($assigned -join ', ')"
        Credentials = Get-CredText $api[0]
        Note        = 'Token audience for the request_disable tool.' + $(if ($apiOther.Count) { " $($apiOther.Count) other app registrations have the same name and no DisableRequest.Submit role: " + (($apiOther | ForEach-Object { "object ID $($_.id) created $(Format-Utc $_.createdDateTime), credentials $(Get-CredText $_)" }) -join ' | ') } else { '' })
    }
}

# The Foundry project's managed identity. Every agent's tool connections run through it.
$proj = @(Get-Graph "https://graph.microsoft.com/v1.0/servicePrincipals?`$filter=displayName eq 'lindhav-foundry/projects/lindhav-agents'")
if ($proj.Count -gt 0) {
    $projRoles = az role assignment list --assignee-object-id $proj[0].id --all --query "[].{r:roleDefinitionName,s:scope}" -o json | ConvertFrom-Json
    $related += [pscustomobject]@{
        ForAgent    = 'all agents'
        Identity    = 'lindhav-foundry/projects/lindhav-agents (project managed identity)'
        ObjectId    = $proj[0].id
        Type        = 'ManagedIdentity'
        Enabled     = $proj[0].accountEnabled
        Access      = ((@(Get-AppRoleNames $proj[0].id) + @($projRoles | ForEach-Object { "$($_.r) on $(($_.s -split '/')[-1])" })) | Where-Object { $_ }) -join ', '
        Credentials = 'managed identity, no secret'
        Note        = 'Owner of every agent identity. Holds DisableRequest.Submit'
    }
}

$related | Export-Csv (Join-Path $outDir 'related_identities.csv') -Encoding utf8
Add-Source 'related_identities.csv' 'Graph v1.0 servicePrincipals, applications, appRoleAssignments, plus az role assignment list' 'Identities the inventory script does not list'

# ---------- 3. Staff, managers and status ----------

$staff = foreach ($u in @(Get-Graph "https://graph.microsoft.com/v1.0/users?`$select=id,displayName,userPrincipalName,jobTitle,department,accountEnabled")) {
    $mgr = $null
    try { $mgr = Get-Graph "https://graph.microsoft.com/v1.0/users/$($u.id)/manager?`$select=displayName,accountEnabled" } catch { }
    [pscustomobject]@{
        Name           = $u.displayName
        JobTitle       = $u.jobTitle
        Department     = $u.department
        Enabled        = $u.accountEnabled
        Manager        = if ($mgr) { $mgr.displayName } else { '' }
        ManagerEnabled = if ($mgr) { $mgr.accountEnabled } else { '' }
    }
}
$staff | Export-Csv (Join-Path $outDir 'staff.csv') -Encoding utf8
Add-Source 'staff.csv' 'Graph v1.0 users and manager' 'No sign-in names or IDs, to keep the file small'

# ---------- 4. Usage from Foundry traces ----------

$wsId = az monitor log-analytics workspace show -g $ResourceGroup -n $Workspace --query customerId -o tsv
$kql = @"
AppDependencies
| where TimeGenerated > ago($($Days)d)
| where Name startswith 'invoke_agent' or Name startswith 'execute_tool'
| extend a = parse_json(tostring(Properties['gen_ai.tool.call.arguments']))
| project TimeUtc = format_datetime(TimeGenerated, 'yyyy-MM-dd HH:mm:ss'), Span = Name,
          GraphUrl = tostring(a.relativeUrl), Success, ResultCode, OperationId
| order by TimeUtc asc
"@
# Query the Log Analytics API directly with az rest, so no preview az extension is needed.
# The body goes in a temp file because az on Windows mangles inline JSON quotes.
$bodyFile = Join-Path $env:TEMP 'lindhav-kql-body.json'
@{ query = $kql } | ConvertTo-Json -Compress | Set-Content $bodyFile -Encoding utf8NoBOM
$result = az rest --method post --uri "https://api.loganalytics.io/v1/workspaces/$wsId/query" --resource 'https://api.loganalytics.io' --headers 'Content-Type=application/json' --body "@$bodyFile" -o json | ConvertFrom-Json
Remove-Item $bodyFile
$cols = @($result.tables[0].columns.name)
$rows = foreach ($row in @($result.tables[0].rows)) {
    $o = [ordered]@{}
    for ($i = 0; $i -lt $cols.Count; $i++) { $o[$cols[$i]] = $row[$i] }
    [pscustomobject]$o
}
$usage = foreach ($r in $rows) {
    $agent = ''; $tool = ''
    if ($r.Span -match '^invoke_agent (.+)$') { $agent = $Matches[1] }
    if ($r.Span -match '^execute_tool (.+)$') { $tool  = $Matches[1] }
    [pscustomobject]@{ TimeUtc = "$($r.TimeUtc) UTC"; Agent = $agent; Tool = $tool; GraphUrl = $r.GraphUrl; Success = $r.Success; ResultCode = $r.ResultCode; OperationId = $r.OperationId }
}
$usage | Export-Csv (Join-Path $outDir 'usage_traces.csv') -Encoding utf8
$firstTrace = ($usage | Select-Object -First 1).TimeUtc
Add-Source 'usage_traces.csv' "Log Analytics $Workspace, table AppDependencies, last $Days days" "Tracing started 2026-11-24 03:17 UTC. Earliest row $firstTrace. Tool calls share an OperationId with their agent run"

# ---------- 5. Logic App run history ----------

$runsUri = "https://management.azure.com$($la.id)/runs?api-version=2016-06-01"
$runs = (az rest --method get --uri $runsUri -o json | ConvertFrom-Json).value
$runRows = foreach ($r in $runs) {
    [pscustomobject]@{ RunId = $r.name; StartUtc = Format-Utc $r.properties.startTime; EndUtc = Format-Utc $r.properties.endTime; Status = $r.properties.status; Trigger = $r.properties.trigger.name }
}
$runRows | Export-Csv (Join-Path $outDir 'usage_logicapp_runs.csv') -Encoding utf8
Add-Source 'usage_logicapp_runs.csv' "ARM workflows/runs for $LogicApp" 'Each run is one disable request. The decision and the disable are in the run details and the Entra audit log'

# ---------- 6. Azure Activity Log ----------

# az returns only 50 events unless told otherwise, which cut the log off before the first lab's build.
$act = az monitor activity-log list -g $ResourceGroup --offset "$($Days)d" --max-events 1000 -o json | ConvertFrom-Json
$actRows = foreach ($e in $act) {
    [pscustomobject]@{
        TimeUtc   = Format-Utc $e.eventTimestamp
        Operation = $e.operationName.localizedValue
        Status    = $e.status.value
        Caller    = $e.caller
        Resource  = ($e.resourceId -split '/')[-1]
    }
}
$actRows | Export-Csv (Join-Path $outDir 'activity_log.csv') -Encoding utf8
Add-Source 'activity_log.csv' "Azure Activity Log, resource group $ResourceGroup, last $Days days" 'Management changes only, not data reads'

# ---------- Sources and summary ----------

# The Entra log CSVs are exported from the portal by hand, so keep their lines from the old sources.csv.
$sourcesPath = Join-Path $outDir 'sources.csv'
$kept = @()
if (Test-Path $sourcesPath) {
    $kept = @(Import-Csv $sourcesPath | Where-Object { $_.File -like 'entra-logs/*' })
}
@($sources) + $kept | Export-Csv $sourcesPath -Encoding utf8
Write-Host ''
Write-Host "Agent inventory rows     $(@(Import-Csv $inventoryOut).Count)"
Write-Host "Related identities       $($related.Count)"
Write-Host "DisableRequest.Submit    $(if ($assigned.Count) { $assigned -join ', ' } else { 'nobody found' })"
Write-Host "Staff                    $(@($staff).Count)"
Write-Host "Trace rows               $(@($usage).Count)  (earliest $firstTrace)"
Write-Host "Logic App runs           $(@($runRows).Count)"
Write-Host "Activity log events      $(@($actRows).Count)"
Write-Host "Hand export lines kept   $($kept.Count)  (entra-logs/ in sources.csv)"
Write-Host "Saved to                 $outDir"
Write-Host ''
Write-Host 'The Entra sign-in and audit logs are exported by hand into evidence/entra-logs/, without IP, location or ASN columns. Their sources.csv lines are kept above.'
