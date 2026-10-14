# Run Manager Library locally

Keep the six repositories as sibling directories. Docker Desktop must run Linux
containers. From this repository, run:

```powershell
./start.ps1
```

The script generates unique local secrets into the ignored .env file, then runs
`docker compose up --build --detach --wait`. Open https://localhost:8443 and use
ADMIN_USERNAME / ADMIN_PASSWORD from .env. No usable credential is committed.

The local gateway issues a localhost certificate from its own CA. The public CA
certificate is copied to .local/caddy-root.crt. Configure your client/browser to
trust that local CA for certificate verification. Do not disable certificate
verification for a real deployment. Production requires a trusted domain and
certificate, and its configured production storage. Passwords cross the client
connection only through HTTPS; the API and database have no published host ports.

The PostgreSQL image starts an empty engine with a persistent volume. There is no
init SQL or business DDL in this repository. After engine health, the application
init service runs `php artisan library:install`, then the API becomes ready.
All business schema and the fixed seed belong to API migrations.

To observe the initial empty engine separately on a fresh project/volume, start
only `db`, inspect its public/library table inventory, then start the full stack.
Do not delete an existing volume to repeat this check on data you want to keep.

Run `./verify.ps1` for the reproducible empty-engine and verified-CA HTTPS checks.
It uses a new random verification project, then removes only that project's
volume. The application remains running with its data. See evidence/T-20.md.

`docker compose down` stops containers and retains data. API tests use their own
separate disposable Compose project. The demo utility belongs to the tool repo;
it writes business records only through the HTTP API.
