ALTER TABLE opportunities ADD COLUMN IF NOT EXISTS registration_url VARCHAR(2048);
ALTER TABLE opportunities ADD COLUMN IF NOT EXISTS accepts_registrations BOOLEAN NOT NULL DEFAULT FALSE;
CREATE TABLE IF NOT EXISTS event_registrations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    opportunity_id UUID NOT NULL REFERENCES opportunities(id) ON DELETE CASCADE,
    name VARCHAR(120) NOT NULL,
    email VARCHAR(320) NOT NULL,
    message VARCHAR(1000) NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, opportunity_id)
);
