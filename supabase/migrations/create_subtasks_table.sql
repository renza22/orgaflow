-- Create subtasks table for member personal task breakdown
-- Sub-tasks are automatically assigned to the member who creates them
-- They don't add to organizational workload (already counted in parent task)

CREATE TABLE IF NOT EXISTS subtasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parent_task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT DEFAULT '',
    assigned_to_email TEXT NOT NULL,
    assigned_to_name TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'todo' CHECK (status IN ('todo', 'in_progress', 'done')),
    created_by TEXT NOT NULL, -- Email of member who created it
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_subtasks_parent_task_id ON subtasks(parent_task_id);
CREATE INDEX IF NOT EXISTS idx_subtasks_assigned_to_email ON subtasks(assigned_to_email);
CREATE INDEX IF NOT EXISTS idx_subtasks_status ON subtasks(status);

-- Enable RLS
ALTER TABLE subtasks ENABLE ROW LEVEL SECURITY;

-- Policy: Members can view subtasks of tasks they're assigned to or if they're admin
CREATE POLICY "Members can view subtasks of their tasks"
    ON subtasks FOR SELECT
    USING (
        -- Can see if they created it
        created_by = auth.jwt() ->> 'email'
        OR
        -- Can see if they're assigned to it
        assigned_to_email = auth.jwt() ->> 'email'
        OR
        -- Admins can see all subtasks in their organization
        EXISTS (
            SELECT 1 FROM organization_members om
            WHERE om.profile_id = auth.uid()
            AND om.role IN ('owner', 'admin')
            AND om.status = 'active'
        )
    );

-- Policy: Only the assigned member can create subtasks for their own tasks
CREATE POLICY "Members can create subtasks for their tasks"
    ON subtasks FOR INSERT
    WITH CHECK (
        -- Must be assigned to themselves
        assigned_to_email = auth.jwt() ->> 'email'
        AND created_by = auth.jwt() ->> 'email'
        AND
        -- Must be assigned to the parent task
        EXISTS (
            SELECT 1 FROM tasks t
            WHERE t.id = parent_task_id
            AND t.assigned_to_email = auth.jwt() ->> 'email'
        )
    );

-- Policy: Only the assigned member can update their subtasks
CREATE POLICY "Members can update their own subtasks"
    ON subtasks FOR UPDATE
    USING (
        assigned_to_email = auth.jwt() ->> 'email'
        AND created_by = auth.jwt() ->> 'email'
    )
    WITH CHECK (
        assigned_to_email = auth.jwt() ->> 'email'
        AND created_by = auth.jwt() ->> 'email'
    );

-- Policy: Only the assigned member can delete their subtasks
CREATE POLICY "Members can delete their own subtasks"
    ON subtasks FOR DELETE
    USING (
        assigned_to_email = auth.jwt() ->> 'email'
        AND created_by = auth.jwt() ->> 'email'
    );

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_subtasks_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update updated_at
CREATE TRIGGER update_subtasks_updated_at_trigger
    BEFORE UPDATE ON subtasks
    FOR EACH ROW
    EXECUTE FUNCTION update_subtasks_updated_at();

-- Comments for documentation
COMMENT ON TABLE subtasks IS 'Personal task breakdown for members. Sub-tasks are automatically assigned to the member who creates them and do not add to organizational workload calculations.';
COMMENT ON COLUMN subtasks.parent_task_id IS 'Reference to the main task assigned by admin';
COMMENT ON COLUMN subtasks.assigned_to_email IS 'Always the same as created_by - members can only create subtasks for themselves';
COMMENT ON COLUMN subtasks.created_by IS 'Email of the member who created this subtask';
COMMENT ON COLUMN subtasks.status IS 'Status of subtask: todo, in_progress, or done';
