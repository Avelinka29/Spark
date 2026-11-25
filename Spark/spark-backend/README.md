# Spark Backend

FastAPI API with PostgreSQL for Spark.

## Local launch

1. Copy `.env.example` to `.env` and replace `JWT_SECRET`.
2. Start PostgreSQL: `docker compose up -d postgres`.
3. Seed opportunities: `docker compose exec -T postgres psql -U spark -d spark < sql/002_seed.sql`.
4. Create a virtual environment and install: `pip install -e '.[test]'`.
5. Start the API: `uvicorn app.main:app --reload`.
6. Open `http://127.0.0.1:8000/docs`.

For an iPhone, start the API in Docker so port 8000 is reachable on the local
network, connect the phone and Mac to the same Wi-Fi, and allow Spark access to
the local network in iOS Settings. The current device default is
`http://MacBook-Air-AVELINA.local:8000/api/v1/`; if the Mac's local hostname
changes, set `SPARK_API_BASE_URL` in the Xcode scheme to the new API URL.
The iOS Simulator uses `http://127.0.0.1:8000/api/v1/` by default.
Local HTTP is intended for development; use HTTPS for a deployed API.

The initial SQL schema is applied by PostgreSQL only when its Docker volume is first created.
For deployed environments, add Alembic migrations before changing the schema.

### Existing databases and administrators

Back up the database before applying schema changes. For a database that already has
the social/chat schema (`007_social_and_chat.sql`), apply the following once, in order:

```sh
docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U spark -d spark < sql/008_organization_accounts.sql
docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U spark -d spark < sql/009_event_proposals.sql
docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U spark -d spark < sql/010_organization_approval.sql
docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U spark -d spark < sql/011_opportunity_attendance.sql
docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U spark -d spark < sql/012_team_workspace.sql
docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U spark -d spark < sql/013_usernames.sql
docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U spark -d spark < sql/014_follows.sql
docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U spark -d spark < sql/015_recommendation_feedback.sql
docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U spark -d spark < sql/016_attendance_verification.sql
docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U spark -d spark < sql/017_opportunity_sources.sql
docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U spark -d spark < sql/018_content_reports.sql
docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U spark -d spark < sql/019_portfolio_visibility.sql
docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U spark -d spark < sql/020_project_result_url.sql
docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U spark -d spark < sql/021_event_registration.sql
docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U spark -d spark < sql/022_organization_follows.sql
```

For older databases, inspect the schema and apply the missing numbered SQL files in
order first. These scripts are not an automatic migration system. Fresh databases
already receive the current schema from `001_initial.sql`; do not rerun seed data
on an existing database without reviewing it.

### Follows and personalized feed

Apply `sql/014_follows.sql` to existing databases before starting the updated API.
Authenticated users can follow topics, organizers and projects. Topic matching
uses case-insensitive literal matches in event category, title and summary;
organizers match by name, not by a verified organization account. The feed hides
events whose known dates and deadlines are all past, and includes followed
projects. Follows are private and removed with the account; project follows are
removed when the project is deleted. This version does not send push notifications.
The organization directory also supports following a verified organization by
its stable account ID; those matches use event ownership rather than names.

For participation verification apply `sql/016_attendance_verification.sql` first.
Only the approved organization or administrator that owns the event can verify
another user's self-reported participation after the event starts. The organizer
can revoke confirmation. A self-reported event is distinct from a verified one;
seeded events without an owning organization cannot be verified this way.

Event authors may provide an HTTPS source URL; it is displayed as a link, not as
proof that the information has been independently verified. Existing events may
have no source. The Space Media calendar integration is not enabled: access or an
official feed/API must be agreed before importing and refreshing its content.

Authenticated users may report a profile, project or event. Administrators can
review or dismiss reports; those statuses do not automatically remove content or
block accounts. Users can hide project and event portfolio entries from other
users; other profile information and existing friend event plans remain visible
according to their existing rules. Blocking and comprehensive moderation tools
are not implemented yet and are required before public launch.
Project owners can add or remove an HTTPS result link, which appears in project
details and in the portfolios of the owner and accepted participants when those
portfolios are visible. The link is supplied by the owner and is not verified.

The directory lists approved, verified organization accounts and their published
events, including past events. The event owner can optionally enable registrations
in Spark or provide an HTTPS external registration URL. The in-app form prefills
the user's profile name and email, lets them edit both, and explicitly asks for
submission to the organizer. Only that event's approved owner can retrieve the
registration list; users can cancel their own registration. This is a submitted
application, not a confirmation of acceptance. Before production, review retention,
moderation, consent wording and personal-data protection with the organization.

For the current local database, apply `sql/013_usernames.sql` before restarting the
updated API. Existing users can choose a username in their profile. Friend search
uses an exact username; only verified profiles are returned.

To add five clearly labelled sample projects for AI matching in development, run
`docker compose exec api python -m app.seed_demo_projects`. The command is
idempotent and refuses to run outside development. For example, add `Swift`,
`SwiftUI`, and `Figma` to profile skills and `EdTech`, `FinTech` to interests.
Demo teams and projects are test data and are not real organizations.

### Email codes in local development

The running API needs its own SMTP settings; a Google Sign-In client ID does not
configure email delivery. Set `SMTP_HOST`, `SMTP_PORT`, `SMTP_USERNAME`,
`SMTP_PASSWORD`, and `SMTP_SENDER` in the backend `.env`, set
`ALLOW_DEVELOPMENT_CODES=false`, and recreate the API with
`docker compose up -d --no-deps api`. For Gmail on port 587, use a Google app
password for an account with two-step verification. Never commit credentials.
Without SMTP, local development may instead display the test code in the app.
The verification window can be closed; an unverified account can later request
another code from the login screen after entering its email and password.

Set `ADMIN_EMAILS` to a comma-separated list of administrator email addresses before
creating their accounts. Existing accounts are not promoted by changing this setting;
an operator must explicitly update `users.account_type` to `admin` after verifying
the account. Remove access explicitly if an administrator leaves. Organization
applications require an administrator decision before publishing. Migration 010
returns pre-existing organization accounts to pending review.

For local development only, `docker compose exec api python -m app.create_dev_admin`
creates the administrator with login `admin` and password `admin`. It refuses to
overwrite an existing account and cannot run outside development. These credentials
are publicly known and must never be used for a public deployment. Development Compose
mounts the local `app` directory; restart the API container after Python changes.

Project chats are created after every project role has an accepted applicant. Closing
a role without accepting an applicant does not complete the team. Decisions for a
project are serialized to prevent simultaneous approvals from filling one role twice.

Event plans are private to the user and their accepted friends. Invitations are sent
as in-app notifications to friends only. A plan is not event registration. A user may
separately add an event to their shareable profile after its start date; this is
self-reported, not verified attendance. Accepted project roles and owned projects are
also visible through the existing authenticated profile/QR flow. Deleting the plan
removes its self-reported event entry. Chat members can manage shared tasks, links and
meeting notes; progress is the fraction of completed tasks. The shared text fields use
last-write-wins, so concurrent edits may overwrite each other.

### Optional AI project recommendations

The ProjectHub AI button is opt-in. The backend can call a self-hosted Ollama
`/api/chat` endpoint with structured JSON output. It sends the user's skills and
interests and at most 12 open project descriptions, but not the user's name or email.
These fields and project descriptions may still contain personal information. It
does not send data until the user confirms the action in the app. Model output is
untrusted: the API accepts only candidate project IDs, discards the model's
explanations and builds reasons from literal matches with profile skills, interests
and open roles. Candidates without such evidence are excluded; this conservative
check can miss relevant synonyms. Exact-match recommendations continue to work if AI is off.
Users can record whether an AI match was helpful; feedback is stored per user and
project but does not yet change recommendation ranking.

To try locally, install and run Ollama separately and choose a multilingual model
appropriate for the machine, for example `ollama pull qwen2.5:1.5b`. This downloads
model data; quality and performance must be evaluated. Set both variables in the
Compose `.env` file and recreate the API container:

```dotenv
AI_OLLAMA_URL=http://host.docker.internal:11434
AI_OLLAMA_MODEL=qwen2.5:1.5b
```

`docker compose up -d --no-deps api` applies the settings. An absent model or service
returns an unavailable response; it never silently falls back to another provider.
Ollama should remain private. Production requires an HTTPS endpoint and appropriate
access controls; do not expose an unauthenticated model server to the public Internet.
The current adapter targets local Ollama structured output, not a generic cloud API.

For the user-local macOS installation, start the model service in a separate terminal
with `sh start-local-ai.sh`. The script uses CPU mode to work when Metal access is
unavailable, and keeps running until stopped with Ctrl-C. After restarting the Mac,
start it again before using AI matching. If Ollama is installed elsewhere, set the
`OLLAMA_BINARY` environment variable. The service listens only on localhost by default.

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
