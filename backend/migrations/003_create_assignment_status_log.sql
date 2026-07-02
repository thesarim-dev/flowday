CREATE TABLE assignment_status_log (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assignment_id   UUID          NOT NULL
                    REFERENCES assignments(id) ON DELETE CASCADE,
    previous_status VARCHAR(20),
    new_status      VARCHAR(20)   NOT NULL,
    changed_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    note            TEXT
);
