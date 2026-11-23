CREATE TABLE IF NOT EXISTS opportunity_attendance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    opportunity_id UUID NOT NULL REFERENCES opportunities(id) ON DELETE CASCADE,
    attended BOOLEAN NOT NULL DEFAULT FALSE,
    UNIQUE(user_id, opportunity_id)
);
ALTER TABLE opportunity_attendance ADD COLUMN IF NOT EXISTS attended BOOLEAN NOT NULL DEFAULT FALSE;
CREATE INDEX IF NOT EXISTS ix_opportunity_attendance_user_id ON opportunity_attendance(user_id);
CREATE INDEX IF NOT EXISTS ix_opportunity_attendance_opportunity_id ON opportunity_attendance(opportunity_id);
