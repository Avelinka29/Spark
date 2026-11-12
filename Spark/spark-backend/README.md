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
