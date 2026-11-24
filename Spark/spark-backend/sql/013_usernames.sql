ALTER TABLE users ADD COLUMN IF NOT EXISTS username VARCHAR(32);
CREATE UNIQUE INDEX IF NOT EXISTS ix_users_username ON users (username);
