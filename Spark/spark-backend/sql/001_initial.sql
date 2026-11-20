CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TYPE applicationstatus AS ENUM ('pending', 'accepted', 'rejected');

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(320) UNIQUE NOT NULL,
    password_hash TEXT,
    google_sub VARCHAR(255) UNIQUE,
    email_verified BOOLEAN NOT NULL DEFAULT FALSE,
    name VARCHAR(120) NOT NULL,
    region VARCHAR(120) NOT NULL DEFAULT '',
    bio TEXT NOT NULL DEFAULT '',
    skills VARCHAR[] NOT NULL DEFAULT '{}',
    interests VARCHAR[] NOT NULL DEFAULT '{}',
    avatar_data BYTEA,
    avatar_content_type VARCHAR(32),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TYPE authcodepurpose AS ENUM ('verify_email', 'password_reset');

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
    category VARCHAR(50) NOT NULL,
    title VARCHAR(200) NOT NULL,
    summary TEXT NOT NULL,
    details TEXT NOT NULL,
    organizer VARCHAR(160) NOT NULL,
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

CREATE TABLE projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category VARCHAR(80) NOT NULL,
    title VARCHAR(200) NOT NULL,
    summary TEXT NOT NULL,
    owner_role VARCHAR(120) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE project_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    title VARCHAR(120) NOT NULL,
    skills TEXT NOT NULL DEFAULT '',
    is_open BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE bookmarks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    opportunity_id UUID NOT NULL REFERENCES opportunities(id) ON DELETE CASCADE,
    UNIQUE(user_id, opportunity_id)
);

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
