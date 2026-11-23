# Spark Backend

FastAPI API with PostgreSQL for Spark.

## Local launch

1. Copy `.env.example` to `.env` and replace `JWT_SECRET`.
2. Start PostgreSQL: `docker compose up -d postgres`.
3. Seed opportunities: `docker compose exec -T postgres psql -U spark -d spark < sql/002_seed.sql`.
4. Create a virtual environment and install: `pip install -e '.[test]'`.
5. Start the API: `uvicorn app.main:app --reload`.
6. Open `http://127.0.0.1:8000/docs`.

The initial SQL schema is applied by PostgreSQL only when its Docker volume is first created.
For deployed environments, add Alembic migrations before changing the schema.

### Existing databases and administrators

Back up the database before applying schema changes. For a database that already has
the social/chat schema (`007_social_and_chat.sql`), apply the following once, in order:

```sh
docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U spark -d spark < sql/008_organization_accounts.sql
docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U spark -d spark < sql/009_event_proposals.sql
```

For older databases, inspect the schema and apply the missing numbered SQL files in
order first. These scripts are not an automatic migration system. Fresh databases
already receive the current schema from `001_initial.sql`; do not rerun seed data
on an existing database without reviewing it.

Set `ADMIN_EMAILS` to a comma-separated list of administrator email addresses before
creating their accounts. Existing accounts are not promoted by changing this setting;
an operator must explicitly update `users.account_type` to `admin` after verifying
the account. Remove access explicitly if an administrator leaves. Users can currently
switch themselves to an organization account and publish directly; this is an open
product policy, not verification of an organization.

## Production preparation

`docker-compose.production.yml` is a hardened starting point for a single server. It does not expose PostgreSQL publicly and refuses to start without the required secrets, Google client ID and SMTP credentials.

1. Point a domain such as `api.example.com` to the server.
2. Install Docker and place this directory on the server.
3. Create `.env` from `.env.example` and set `APP_ENVIRONMENT=production`.
4. Generate independent secrets instead of reusing development credentials:

   ```sh
   openssl rand -hex 32
   openssl rand -base64 32
   ```

5. Start the private HTTP service:

   ```sh
   docker compose --env-file .env -f docker-compose.production.yml up -d --build
   ```

6. Put Caddy, nginx or the hosting provider's HTTPS proxy in front of `127.0.0.1:8000`.
7. Confirm both checks through HTTPS:

   ```sh
   curl https://api.example.com/health/live
   curl https://api.example.com/health
   ```

8. Add the iOS Info.plist string key `SparkAPIBaseURL` with `https://api.example.com/api/v1/`. The `SPARK_API_BASE_URL` process environment remains available for temporary local overrides, but should not be relied on by an archived TestFlight build.
9. Back up the `spark_production_postgres` Docker volume and test restoration before launch.

Never commit `.env`, SMTP passwords, OAuth client secrets, database passwords or JWT secrets. Rotate any credential that has been pasted into chat or published elsewhere.

## Health checks

- `/health/live` confirms that the API process is running.
- `/health` confirms that the API can query PostgreSQL and returns HTTP 503 when the database is unavailable.

## Remaining deployment decision

The repository is provider-neutral. A public deployment still requires choosing and paying for a server or managed platform, configuring DNS/HTTPS, and supplying production credentials. Database schema changes after the first production launch must be delivered as Alembic migrations rather than by editing `001_initial.sql`.
