$ErrorActionPreference = 'Stop'
$repository = $PSScriptRoot
Push-Location $repository
try {
    if (-not (Test-Path -LiteralPath '.env')) {
        $databasePassword = [Convert]::ToHexString([Security.Cryptography.RandomNumberGenerator]::GetBytes(32))
        $jwtSecret = [Convert]::ToHexString([Security.Cryptography.RandomNumberGenerator]::GetBytes(32))
        $adminPassword = [Convert]::ToHexString([Security.Cryptography.RandomNumberGenerator]::GetBytes(16))
        @(
            'POSTGRES_DB=manager_library'
            'POSTGRES_USER=library'
            "POSTGRES_PASSWORD=$databasePassword"
            "JWT_SECRET=$jwtSecret"
            'ADMIN_USERNAME=admin'
            "ADMIN_PASSWORD=$adminPassword"
            'HTTPS_PORT=8443'
            'FRONTEND_ORIGIN=https://localhost:8443'
            'APP_ENV=demo'
            'DEMO_BUSINESS_TIME='
        ) | Set-Content -LiteralPath '.env' -Encoding utf8
        Write-Output 'Local credentials generated in the ignored .env file. No credential was printed.'
    }
    docker compose up --build --detach --wait
    if ($LASTEXITCODE -ne 0) { throw 'The application stack failed to start.' }
    if (-not (Test-Path -LiteralPath '.local')) { New-Item -ItemType Directory -Path '.local' | Out-Null }
    docker compose cp gateway:/data/caddy/pki/authorities/local/root.crt .local/caddy-root.crt
    if ($LASTEXITCODE -ne 0) { throw 'Could not export the local CA certificate.' }
    Write-Output 'Manager Library is available at https://localhost:8443'
    Write-Output 'Use the admin credentials in .env. The local CA is .local/caddy-root.crt.'
}
finally { Pop-Location }
