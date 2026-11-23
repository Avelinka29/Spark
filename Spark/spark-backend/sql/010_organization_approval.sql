ALTER TABLE users ADD COLUMN IF NOT EXISTS organization_status VARCHAR(24);

-- Existing organization accounts must also be reviewed before publishing.
UPDATE users SET account_type = 'user', organization_status = 'pending',
    organization_name = COALESCE(NULLIF(trim(organization_name), ''), name)
WHERE account_type = 'organization' AND organization_status IS NULL;
