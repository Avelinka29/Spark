CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TYPE applicationstatus AS ENUM ('pending', 'accepted', 'rejected');

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(320) UNIQUE NOT NULL,
    password_hash TEXT,
    google_sub VARCHAR(255) UNIQUE,
    name VARCHAR(120) NOT NULL,
    region VARCHAR(120) NOT NULL DEFAULT '',
    bio TEXT NOT NULL DEFAULT '',
    skills VARCHAR[] NOT NULL DEFAULT '{}',
    interests VARCHAR[] NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

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
