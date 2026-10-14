$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot
$project = 'manager-library-empty-check-' + [Guid]::NewGuid().ToString('N')
try {
    $settings = @{}
    Get-Content -LiteralPath '.env' | ForEach-Object {
        if ($_ -match '^([^#=]+)=(.*)$') { $settings[$Matches[1]] = $Matches[2] }
    }
    $user = if ($settings.POSTGRES_USER) { $settings.POSTGRES_USER } else { 'library' }
    $database = if ($settings.POSTGRES_DB) { $settings.POSTGRES_DB } else { 'manager_library' }
    docker compose -p $project up --detach --wait db
    if ($LASTEXITCODE -ne 0) { throw 'The isolated empty engine failed to start.' }
    $count = docker compose -p $project exec -T db psql -U $user -d $database -At -c "SELECT count(*) FROM information_schema.tables WHERE table_schema IN ('public','library');"
    if ($LASTEXITCODE -ne 0 -or "$count".Trim() -ne '0') { throw 'The fresh engine contains application tables.' }
    Write-Output 'Fresh isolated engine: zero public/library tables before application migrations.'
    $port = if ($settings.HTTPS_PORT) { $settings.HTTPS_PORT } else { '8443' }
    $health = curl.exe --silent --show-error --fail --cacert .local/caddy-root.crt --ssl-revoke-best-effort "https://localhost:$port/health"
    if ($LASTEXITCODE -ne 0 -or $health -ne '{"status":"ok"}') { throw 'The HTTPS health response or certificate verification failed.' }
    Write-Output 'Running application: verified local CA and hostname, HTTP 200, exact health body.'
    docker compose ps
    if ($LASTEXITCODE -ne 0) { throw 'Could not inspect the application stack.' }
}
finally {
    # Only the new random verification project is disposable; application volumes remain intact.
    docker compose -p $project down --volumes
    Pop-Location
}
