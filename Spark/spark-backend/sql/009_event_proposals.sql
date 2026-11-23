CREATE TABLE IF NOT EXISTS event_proposals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    author_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    event_data JSONB NOT NULL,
    message TEXT NOT NULL,
    status VARCHAR(24) NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ix_event_proposals_author_id ON event_proposals(author_id);
CREATE INDEX IF NOT EXISTS ix_event_proposals_status ON event_proposals(status);
