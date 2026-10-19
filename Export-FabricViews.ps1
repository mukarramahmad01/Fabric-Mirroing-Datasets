<#
.SYNOPSIS
  Exports every view from a Fabric SQL analytics endpoint to one .sql file per view
  in your local Git repo, then commits and pushes.
  - Strips WITH SCHEMABINDING
  - Rewrites CREATE VIEW to CREATE OR ALTER VIEW
  - Writes _schemas.sql for any non-dbo schemas

  No modules needed. Uses .NET's built-in SqlClient plus an Entra token.

  AUTHENTICATION
  - Service principal (default when -ClientId is given): token is requested directly from
    Microsoft Entra with the client-credentials flow (plain REST call, no MSAL/Az modules).
    The secret is read from env var FABRIC_SP_SECRET, or prompted for securely.
    It is never written to disk or printed.
  - Without -ClientId: signs in as YOU with a browser device code (no modules needed).
    Add -TenantId "<your-tenant-domain-or-guid>" if you belong to more than one tenant.

.EXAMPLE
  $env:FABRIC_SP_SECRET = "<client secret>"     # or omit it and you'll be prompted
  .\Export-FabricViews.ps1 -Server "xxxx.datawarehouse.fabric.microsoft.com" -Database "nov-qa.App" `
      -RepoPath "C:\Repos\Fabric-Mirroing-Datasets" `
      -TenantId "<tenant-guid>" -ClientId "<app-client-id>"

.PREREQS for the service principal
  1. Fabric Admin portal > Tenant settings > "Service principals can use Fabric APIs" = Enabled
     (for the SP or a security group that contains it).
  2. Add the SP to the workspace (Viewer is enough to read view definitions).
#>
param(
    [Parameter(Mandatory)] [string] $Server,
    [Parameter(Mandatory)] [string] $Database,
    [Parameter(Mandatory)] [string] $RepoPath,
    [string] $Folder = "$Database.Views",
    [string] $TenantId,
    [string] $ClientId,
    [string] $CommitMessage = "Export views from $Database",
    [switch] $NoGit
)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ---------- 1. Get an Entra access token for SQL ----------
$token = $null
if ($ClientId) {
    if (-not $TenantId) { throw "-TenantId is required with -ClientId." }
    $secret = $env:FABRIC_SP_SECRET
    if (-not $secret) {
        $sec = Read-Host "Client secret for $ClientId" -AsSecureString
        $secret = [System.Net.NetworkCredential]::new('', $sec).Password
    }
    $body = @{
        grant_type    = 'client_credentials'
        client_id     = $ClientId
        client_secret = $secret
        scope         = 'https://database.windows.net/.default'
    }
    try {
        $resp = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" `
                    -Body $body -ContentType 'application/x-www-form-urlencoded'
    } catch {
        $detail = $_.ErrorDetails.Message
        throw "Service principal sign-in failed. Check tenant ID, client ID and secret. $detail"
    } finally { $secret = $null; $body = $null }
    $token = $resp.access_token
    Write-Host "Signed in as service principal $ClientId"
}
else {
    # Your own account via device-code sign-in (plain REST, no modules, no MSAL).
    # Uses the public Azure CLI client ID, the same one 'az login' uses.
    $tenantForUser = if ($TenantId) { $TenantId } else { 'organizations' }
    $pubClient = '04b07795-8ddb-461a-bbee-02f9e1bf7b46'
    $scope     = 'https://database.windows.net/.default'
    $dc = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$tenantForUser/oauth2/v2.0/devicecode" `
              -ContentType 'application/x-www-form-urlencoded' -Body @{ client_id = $pubClient; scope = $scope }
    Write-Host ""
    Write-Host $dc.message -ForegroundColor Yellow
    try { Set-Clipboard -Value $dc.user_code; Write-Host "(Code copied to clipboard.)" } catch {}
    try { Start-Process $dc.verification_uri } catch {}

    $deadline = (Get-Date).AddSeconds([int]$dc.expires_in)
    while (-not $token -and (Get-Date) -lt $deadline) {
        Start-Sleep -Seconds ([int]$dc.interval)
        try {
            $r = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$tenantForUser/oauth2/v2.0/token" `
                     -ContentType 'application/x-www-form-urlencoded' -Body @{
                         grant_type  = 'urn:ietf:params:oauth:grant-type:device_code'
                         client_id   = $pubClient
                         device_code = $dc.device_code }
            $token = $r.access_token
        } catch {
            $err = try { ($_.ErrorDetails.Message | ConvertFrom-Json).error } catch { 'unknown' }
            if ($err -notin 'authorization_pending', 'slow_down') { throw "Sign-in failed: $($_.ErrorDetails.Message)" }
        }
    }
    if ($token) { Write-Host "Signed in." } else { throw "Sign-in timed out. Run the script again." }
}
if (-not $token) { throw "Could not get an access token." }

# ---------- 2. Read all views (built-in .NET SqlClient, no module) ----------
$conn = New-Object System.Data.SqlClient.SqlConnection
$conn.ConnectionString = "Server=tcp:$Server,1433;Database=$Database;Encrypt=True;TrustServerCertificate=False;Connect Timeout=60;"
$conn.AccessToken = $token
$conn.Open()
try {
    $cmd = $conn.CreateCommand()
    $cmd.CommandTimeout = 300
    $cmd.CommandText = @"
SELECT s.name AS SchemaName, v.name AS ViewName, m.definition AS Definition
FROM sys.views v
JOIN sys.schemas s     ON s.schema_id = v.schema_id
JOIN sys.sql_modules m ON m.object_id = v.object_id
WHERE v.is_ms_shipped = 0
  AND s.name NOT IN ('sys','INFORMATION_SCHEMA','queryinsights')
ORDER BY s.name, v.name;
"@
    $table = New-Object System.Data.DataTable
    $table.Load($cmd.ExecuteReader())
} finally { $conn.Close() }

$views = @($table.Rows | Where-Object { $_.ViewName })
if ($views.Count -eq 0) { Write-Warning "No views found in $Database. Nothing exported."; return }

# ---------- 3. Write files ----------
$outDir = Join-Path $RepoPath $Folder
if (Test-Path $outDir) { Get-ChildItem $outDir -Filter *.sql | Remove-Item }
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$schemas = $views | ForEach-Object { $_.SchemaName } | Sort-Object -Unique | Where-Object { $_ -ne 'dbo' }
if ($schemas) {
    ($schemas | ForEach-Object { "IF SCHEMA_ID('$_') IS NULL EXEC('CREATE SCHEMA [$_]');" }) -join "`r`n" |
        Set-Content (Join-Path $outDir '_schemas.sql') -Encoding UTF8
}

foreach ($v in $views) {
    $sql = [string]$v.Definition
    $sql = $sql -replace '(?i)WITH\s+SCHEMABINDING\s*,\s*', 'WITH '
    $sql = $sql -replace '(?i),\s*SCHEMABINDING\b', ''
    $sql = $sql -replace '(?i)WITH\s+SCHEMABINDING\b', ''
    $sql = ([regex]'(?i)\bCREATE\s+VIEW\b').Replace($sql, 'CREATE OR ALTER VIEW', 1)
    $file = Join-Path $outDir ("{0}.{1}.sql" -f $v.SchemaName, $v.ViewName)
    $sql.Trim() | Set-Content $file -Encoding UTF8
}
Write-Host "Exported $($views.Count) views to $outDir"

# ---------- 4. Commit and push ----------
if ($NoGit) { return }
Push-Location $RepoPath
try {
    git add -- "$Folder"
    if (git status --porcelain -- "$Folder") {
        git commit -m $CommitMessage
        if ($LASTEXITCODE -ne 0) { throw "git commit failed" }
        git push
        if ($LASTEXITCODE -ne 0) { throw "git push failed. Check your GitHub sign-in or branch upstream." }
        Write-Host "Committed and pushed to $(git rev-parse --abbrev-ref HEAD)."
    } else {
        Write-Host "No changes since the last export. Nothing to commit."
    }
} finally { Pop-Location }