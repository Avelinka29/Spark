CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TYPE applicationstatus AS ENUM ('pending', 'accepted', 'rejected');

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(320) UNIQUE NOT NULL,
    password_hash TEXT,
    google_sub VARCHAR(255) UNIQUE,
    email_verified BOOLEAN NOT NULL DEFAULT FALSE,
    name VARCHAR(120) NOT NULL,
    username VARCHAR(32) UNIQUE,
    birth_date DATE,
    region VARCHAR(120) NOT NULL DEFAULT '',
    bio TEXT NOT NULL DEFAULT '',
    skills VARCHAR[] NOT NULL DEFAULT '{}',
    interests VARCHAR[] NOT NULL DEFAULT '{}',
    avatar_data BYTEA,
    avatar_content_type VARCHAR(32),
    account_type VARCHAR(24) NOT NULL DEFAULT 'user',
    organization_name VARCHAR(160),
    organization_status VARCHAR(24),
    portfolio_public BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TYPE authcodepurpose AS ENUM ('verify_email', 'password_reset');

CREATE TABLE content_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    kind VARCHAR(20) NOT NULL CHECK (kind IN ('user', 'project', 'opportunity')),
    target_id UUID NOT NULL,
    reason VARCHAR(1000) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'dismissed')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_content_reports_reporter_id ON content_reports (reporter_id);

CREATE TABLE auth_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    purpose authcodepurpose NOT NULL,
    code_hash VARCHAR(64) NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX ix_auth_codes_user_id ON auth_codes(user_id);
CREATE INDEX ix_auth_codes_purpose ON auth_codes(purpose);

CREATE TABLE opportunities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID REFERENCES users(id) ON DELETE SET NULL,
    category VARCHAR(50) NOT NULL,
    title VARCHAR(200) NOT NULL,
    summary TEXT NOT NULL,
    details TEXT NOT NULL,
    organizer VARCHAR(160) NOT NULL,
    source_url VARCHAR(2048),
    registration_url VARCHAR(2048),
    accepts_registrations BOOLEAN NOT NULL DEFAULT FALSE,
    image_url TEXT,
    location_name VARCHAR(160) NOT NULL,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    starts_at DATE,
    ends_at DATE,
    deadline DATE,
    reward INTEGER,
    published BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX ix_opportunities_category ON opportunities(category);
CREATE INDEX ix_opportunities_published ON opportunities(published);
CREATE INDEX ix_opportunities_owner_id ON opportunities(owner_id);

CREATE TABLE projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category VARCHAR(80) NOT NULL,
    title VARCHAR(200) NOT NULL,
    summary TEXT NOT NULL,
    owner_role VARCHAR(120) NOT NULL,
    result_url VARCHAR(2048),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE follows (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    kind VARCHAR(20) NOT NULL CHECK (kind IN ('topic', 'organizer', 'organization', 'project')),
    value VARCHAR(160) NOT NULL,
    label VARCHAR(160) NOT NULL,
    project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
    organization_id UUID REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE (user_id, kind, value)
);
CREATE INDEX ix_follows_user_id ON follows (user_id);

CREATE TABLE recommendation_feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    helpful BOOLEAN NOT NULL,
    UNIQUE (user_id, project_id)
);

CREATE TABLE project_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    title VARCHAR(120) NOT NULL,
    skills TEXT NOT NULL DEFAULT '',
    is_open BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE event_registrations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    opportunity_id UUID NOT NULL REFERENCES opportunities(id) ON DELETE CASCADE,
    name VARCHAR(120) NOT NULL,
    email VARCHAR(320) NOT NULL,
    message VARCHAR(1000) NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, opportunity_id)
);

CREATE TABLE bookmarks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    opportunity_id UUID NOT NULL REFERENCES opportunities(id) ON DELETE CASCADE,
    UNIQUE(user_id, opportunity_id)
);

CREATE TABLE opportunity_attendance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    opportunity_id UUID NOT NULL REFERENCES opportunities(id) ON DELETE CASCADE,
    attended BOOLEAN NOT NULL DEFAULT FALSE,
    verified_by UUID REFERENCES users(id) ON DELETE SET NULL,
    UNIQUE(user_id, opportunity_id)
);
CREATE INDEX ix_opportunity_attendance_user_id ON opportunity_attendance(user_id);
CREATE INDEX ix_opportunity_attendance_opportunity_id ON opportunity_attendance(opportunity_id);

CREATE TABLE applications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    project_role_id UUID NOT NULL REFERENCES project_roles(id) ON DELETE CASCADE,
    status applicationstatus NOT NULL DEFAULT 'pending',
    UNIQUE(user_id, project_role_id)
);

CREATE TABLE achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    issuer VARCHAR(160) NOT NULL,
    issued_at DATE NOT NULL
);

CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(160) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX ix_notifications_user_id ON notifications(user_id);
CREATE INDEX ix_notifications_is_read ON notifications(is_read);

CREATE TABLE event_proposals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    author_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    event_data JSONB NOT NULL,
    message TEXT NOT NULL,
    status VARCHAR(24) NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_event_proposals_author_id ON event_proposals(author_id);
CREATE INDEX ix_event_proposals_status ON event_proposals(status);

CREATE TYPE friendshipstatus AS ENUM ('pending', 'accepted');

CREATE TABLE friendships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    requester_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    addressee_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status friendshipstatus NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(requester_id, addressee_id),
    CHECK(requester_id <> addressee_id)
);
CREATE INDEX ix_friendships_requester_id ON friendships(requester_id);
CREATE INDEX ix_friendships_addressee_id ON friendships(addressee_id);

CREATE TABLE project_chats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL UNIQUE REFERENCES projects(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_project_chats_project_id ON project_chats(project_id);

CREATE TABLE team_workspaces (
    chat_id UUID PRIMARY KEY REFERENCES project_chats(id) ON DELETE CASCADE,
    links TEXT NOT NULL DEFAULT '',
    meeting VARCHAR(300) NOT NULL DEFAULT ''
);
CREATE TABLE team_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chat_id UUID NOT NULL REFERENCES project_chats(id) ON DELETE CASCADE,
    title VARCHAR(300) NOT NULL,
    done BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_team_tasks_chat_id ON team_tasks(chat_id);

CREATE TABLE chat_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chat_id UUID NOT NULL REFERENCES project_chats(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(chat_id, user_id)
);
CREATE INDEX ix_chat_members_chat_id ON chat_members(chat_id);
CREATE INDEX ix_chat_members_user_id ON chat_members(user_id);

CREATE TABLE chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chat_id UUID NOT NULL REFERENCES project_chats(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    text TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_chat_messages_chat_id ON chat_messages(chat_id);
CREATE INDEX ix_chat_messages_sender_id ON chat_messages(sender_id);
CREATE INDEX ix_chat_messages_created_at ON chat_messages(created_at);
