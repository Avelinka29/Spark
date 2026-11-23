ALTER TABLE users
    ADD COLUMN IF NOT EXISTS account_type VARCHAR(24) NOT NULL DEFAULT 'user',
    ADD COLUMN IF NOT EXISTS organization_name VARCHAR(160);

CREATE INDEX IF NOT EXISTS ix_users_account_type ON users(account_type);

ALTER TABLE opportunities
    ADD COLUMN IF NOT EXISTS owner_id UUID REFERENCES users(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS ix_opportunities_owner_id ON opportunities(owner_id);
