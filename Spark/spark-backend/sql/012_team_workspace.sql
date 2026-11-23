CREATE TABLE IF NOT EXISTS team_workspaces (
    chat_id UUID PRIMARY KEY REFERENCES project_chats(id) ON DELETE CASCADE,
    links TEXT NOT NULL DEFAULT '',
    meeting VARCHAR(300) NOT NULL DEFAULT ''
);
CREATE TABLE IF NOT EXISTS team_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chat_id UUID NOT NULL REFERENCES project_chats(id) ON DELETE CASCADE,
    title VARCHAR(300) NOT NULL,
    done BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ix_team_tasks_chat_id ON team_tasks(chat_id);
