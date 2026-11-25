CREATE TABLE IF NOT EXISTS follows (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    kind VARCHAR(20) NOT NULL CHECK (kind IN ('topic', 'organizer', 'project')),
    value VARCHAR(160) NOT NULL,
    label VARCHAR(160) NOT NULL,
    project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
    UNIQUE (user_id, kind, value)
);
CREATE INDEX IF NOT EXISTS ix_follows_user_id ON follows (user_id);
