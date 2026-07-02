CREATE TABLE schedule_blocks (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    start_time    TIME          NOT NULL,
    label         VARCHAR(150)  NOT NULL,
    block_type    VARCHAR(20)   NOT NULL
                  CHECK (block_type IN (
                      'Personal', 'Family', 'Work', 'Break', 'PROTECTED'
                  )),
    is_protected  BOOLEAN       NOT NULL DEFAULT FALSE,
    sort_order    INTEGER       NOT NULL DEFAULT 0,
    notes         TEXT,
    is_active     BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);
