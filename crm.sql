CREATE OR REPLACE PROCEDURE crm_sync_employee_memberships(
    p_user_id text,
    p_role_ids text[],
    p_team_ids text[]
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_now timestamptz := now();
BEGIN
    PERFORM pg_advisory_xact_lock(hashtext('crm_sync_employee_memberships:' || p_user_id));

    INSERT INTO employee_roles (user_id, role_id, created_at, updated_at)
    SELECT p_user_id, x.role_id, v_now, v_now
    FROM unnest(COALESCE(p_role_ids, ARRAY[]::text[])) AS x(role_id)
    ON CONFLICT (user_id, role_id) DO UPDATE
    SET updated_at = EXCLUDED.updated_at;

    DELETE FROM employee_roles er
    WHERE er.user_id = p_user_id
      AND er.role_id <> ALL(COALESCE(p_role_ids, ARRAY[]::text[]));

    INSERT INTO employee_teams (user_id, team_id, created_at, updated_at)
    SELECT p_user_id, x.team_id, v_now, v_now
    FROM unnest(COALESCE(p_team_ids, ARRAY[]::text[])) AS x(team_id)
    ON CONFLICT (user_id, team_id) DO UPDATE
    SET updated_at = EXCLUDED.updated_at;

    DELETE FROM employee_teams et
    WHERE et.user_id = p_user_id
      AND et.team_id <> ALL(COALESCE(p_team_ids, ARRAY[]::text[]));

    UPDATE employees
    SET
        team_id = (
            SELECT x.team_id
            FROM unnest(COALESCE(p_team_ids, ARRAY[]::text[])) AS x(team_id)
            LIMIT 1
        ),
        updated_at = v_now
    WHERE user_id = p_user_id;
END;
$$;

CREATE OR REPLACE PROCEDURE crm_sync_employee_memberships(
    p_user_id text,
    p_role_ids text[],
    p_team_ids text[]
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_now timestamptz := now();
BEGIN
    PERFORM pg_advisory_xact_lock(hashtext('crm_sync_employee_memberships:' || p_user_id));

    INSERT INTO employee_roles (user_id, role_id, created_at, updated_at)
    SELECT p_user_id, x.role_id, v_now, v_now
    FROM unnest(COALESCE(p_role_ids, ARRAY[]::text[])) AS x(role_id)
    ON CONFLICT (user_id, role_id) DO UPDATE
    SET updated_at = EXCLUDED.updated_at;

    DELETE FROM employee_roles er
    WHERE er.user_id = p_user_id
      AND er.role_id <> ALL(COALESCE(p_role_ids, ARRAY[]::text[]));

    INSERT INTO employee_teams (user_id, team_id, created_at, updated_at)
    SELECT p_user_id, x.team_id, v_now, v_now
    FROM unnest(COALESCE(p_team_ids, ARRAY[]::text[])) AS x(team_id)
    ON CONFLICT (user_id, team_id) DO UPDATE
    SET updated_at = EXCLUDED.updated_at;

    DELETE FROM employee_teams et
    WHERE et.user_id = p_user_id
      AND et.team_id <> ALL(COALESCE(p_team_ids, ARRAY[]::text[]));

    UPDATE employees
    SET
        team_id = (
            SELECT x.team_id
            FROM unnest(COALESCE(p_team_ids, ARRAY[]::text[])) AS x(team_id)
            LIMIT 1
        ),
        updated_at = v_now
    WHERE user_id = p_user_id;
END;
$$;


CREATE INDEX IF NOT EXISTS ix_employees_status_user_id ON employees (status, user_id);
CREATE INDEX IF NOT EXISTS ix_employees_team_id_status ON employees (team_id, status);
CREATE INDEX IF NOT EXISTS ix_employee_roles_user_role ON employee_roles (user_id, role_id);
CREATE INDEX IF NOT EXISTS ix_employee_roles_role_user ON employee_roles (role_id, user_id);
CREATE INDEX IF NOT EXISTS ix_employee_teams_user_team ON employee_teams (user_id, team_id);
CREATE INDEX IF NOT EXISTS ix_employee_teams_team_user ON employee_teams (team_id, user_id);
CREATE INDEX IF NOT EXISTS ix_user_email ON "user" (email);
CREATE INDEX IF NOT EXISTS ix_user_name ON "user" (name);

