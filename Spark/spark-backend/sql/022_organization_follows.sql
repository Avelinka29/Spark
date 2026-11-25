ALTER TABLE follows DROP CONSTRAINT IF EXISTS follows_kind_check;
ALTER TABLE follows ADD CONSTRAINT follows_kind_check CHECK (kind IN ('topic', 'organizer', 'organization', 'project'));
ALTER TABLE follows ADD COLUMN IF NOT EXISTS organization_id UUID REFERENCES users(id) ON DELETE CASCADE;
