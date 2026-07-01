# Flowday — Database Schema

**Version:** 1.0  
**Author:** Fredrick Nyangau  
**Date:** July 2026  
**Status:** Draft  

---

## 1. Design Decisions

- Raw SQL via asyncpg — no ORM
- PostgreSQL 16+
- All timestamps stored in UTC, converted to user local time on the frontend
- Work day boundary is 08:00 to 07:59 the following day — enforced in
  query logic, not in the database
- Estimated hours calculated at the application layer, stored in the database
  so it can be overridden manually by the user in Phase 2
- All tables use UUID primary keys for future multi-user support
- Soft deletes via is_active flag — nothing is hard deleted

---

## 2. Entity Relationship Overview
clients
└── assignments (many assignments belong to one client)
└── assignment_status_log (history of every status change)
schedule_blocks (the user's fixed daily routine template)
---

## 3. Tables

---

### 3.1 clients

Stores the people the user writes for. Names are whatever the user
calls them — not formal names.

```sql
CREATE TABLE clients (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name          VARCHAR(100)  NOT NULL,
    platform      VARCHAR(50)   NOT NULL DEFAULT 'WhatsApp',
    priority      VARCHAR(10)   NOT NULL DEFAULT 'Medium'
                  CHECK (priority IN ('High', 'Medium', 'Low')),
    notes         TEXT,
    is_active     BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);
```

**Column notes:**

| Column | Notes |
|--------|-------|
| name | What the user calls this client e.g. Lorah, Adriele |
| platform | How the client sends work. Default WhatsApp. |
| priority | High, Medium, or Low. Used to break ties in sorting. |
| is_active | False means the user archived this client. Not deleted. |

---

### 3.2 assignments

The core table. Every piece of work the user receives goes here.

```sql
CREATE TABLE assignments (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id        UUID          NOT NULL
                     REFERENCES clients(id) ON DELETE RESTRICT,
    assignment_type  VARCHAR(50)   NOT NULL
                     CHECK (assignment_type IN (
                         'Discussion post', 'Essay', 'Assignment',
                         'Module response', 'Knowledge quiz',
                         'Research paper', 'Exam', 'Simulation', 'Other'
                     )),
    course           VARCHAR(150),
    word_count       INTEGER       CHECK (word_count > 0),
    estimated_hours  NUMERIC(4,1)  CHECK (estimated_hours > 0),
    deadline         TIMESTAMPTZ   NOT NULL,
    status           VARCHAR(20)   NOT NULL DEFAULT 'Not started'
                     CHECK (status IN (
                         'Not started', 'In progress',
                         'Submitted', 'Overdue', 'Cancelled'
                     )),
    payment_kes      NUMERIC(10,2) CHECK (payment_kes >= 0),
    notes            TEXT,
    is_active        BOOLEAN       NOT NULL DEFAULT TRUE,
    received_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    submitted_at     TIMESTAMPTZ,
    created_at       TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);
```

**Column notes:**

| Column | Notes |
|--------|-------|
| client_id | Foreign key to clients. Cannot delete a client who has assignments. |
| assignment_type | Controlled list matching the intake form options. |
| course | Optional. The subject or class this assignment is for. |
| word_count | Used to calculate estimated_hours at the app layer. |
| estimated_hours | Stored result of CEILING(word_count / 300, 0.5). User can override in Phase 2. |
| deadline | Full timestamp with timezone. The single source of truth for urgency. |
| status | Drives the colour coding on the Today view. |
| payment_kes | Optional. Income tracking starts Phase 2 but column exists from day one. |
| received_at | When the assignment came in. Separate from created_at for audit purposes. |
| submitted_at | Set automatically when status changes to Submitted. |

---

### 3.3 assignment_status_log

Every time an assignment status changes, a row is inserted here.
This gives a full audit trail and enables the burnout indicator in Phase 3.

```sql
CREATE TABLE assignment_status_log (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assignment_id   UUID          NOT NULL
                    REFERENCES assignments(id) ON DELETE CASCADE,
    previous_status VARCHAR(20),
    new_status      VARCHAR(20)   NOT NULL,
    changed_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    note            TEXT
);
```

**Column notes:**

| Column | Notes |
|--------|-------|
| previous_status | NULL on the first log entry when the assignment is created. |
| new_status | The status it changed to. |
| note | Optional context e.g. "Client extended deadline". |

---

### 3.4 schedule_blocks

The user's fixed daily routine. Each row is one time block.
This table is seeded at setup and can be edited in Phase 2.

```sql
CREATE TABLE schedule_blocks (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    start_time    TIME          NOT NULL,
    label         VARCHAR(150)  NOT NULL,
    block_type    VARCHAR(20)   NOT NULL
                  CHECK (block_type IN (
                      'Personal', 'Family', 'Work',
                      'Break', 'PROTECTED'
                  )),
    is_protected  BOOLEAN       NOT NULL DEFAULT FALSE,
    sort_order    INTEGER       NOT NULL DEFAULT 0,
    notes         TEXT,
    is_active     BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);
```

**Column notes:**

| Column | Notes |
|--------|-------|
| start_time | Time only, no date. Applied to the current work day on render. |
| is_protected | TRUE blocks cannot be removed or moved by the user. |
| sort_order | Controls display order when two blocks share the same start time. |

---

## 4. Indexes

```sql
-- Most common query: assignments due today sorted by deadline
CREATE INDEX idx_assignments_deadline
    ON assignments(deadline)
    WHERE is_active = TRUE AND status NOT IN ('Submitted', 'Cancelled');

-- Client lookup from assignments tab
CREATE INDEX idx_assignments_client_id
    ON assignments(client_id);

-- Status filter used on Today view and weekly view
CREATE INDEX idx_assignments_status
    ON assignments(status)
    WHERE is_active = TRUE;

-- Audit log lookup per assignment
CREATE INDEX idx_status_log_assignment_id
    ON assignment_status_log(assignment_id);

-- Schedule display order
CREATE INDEX idx_schedule_blocks_sort
    ON schedule_blocks(start_time, sort_order)
    WHERE is_active = TRUE;
```

---

## 5. Seed Data

The schedule blocks table is pre-loaded with her routine at setup.

```sql
INSERT INTO schedule_blocks
    (start_time, label, block_type, is_protected, sort_order, notes)
VALUES
    ('07:30', 'Wake up — check WhatsApp for updates',    'Personal',  FALSE, 1,  'Check for new assignments only — do not start working yet'),
    ('08:07', 'Baby school drop-off',                     'Family',    TRUE,  2,  'Non-negotiable. Do not schedule anything here.'),
    ('08:30', 'Freshen up + skincare routine',            'Personal',  FALSE, 3,  'Your transition time. Keep it.'),
    ('09:30', 'READING BLOCK',                            'PROTECTED', TRUE,  4,  'Your mental reset. 60 minutes minimum.'),
    ('10:30', 'LEARNING BLOCK — coding',                  'PROTECTED', TRUE,  5,  '30 minutes every day. One lesson. No skipping.'),
    ('11:00', 'Chores + Breakfast',                       'Personal',  FALSE, 6,  'Eat properly. You are working overnight.'),
    ('11:30', 'Work session 1',                           'Work',      FALSE, 7,  'Highest urgency assignment first.'),
    ('13:30', 'Short break (15 min)',                     'Break',     FALSE, 8,  'Stand up, step away from the screen.'),
    ('13:45', 'Work session 2',                           'Work',      FALSE, 9,  'Second most urgent assignment.'),
    ('16:00', 'Light personal time',                      'Personal',  FALSE, 10, 'Avoid screens if possible.'),
    ('17:00', 'EVENING NAP',                              'PROTECTED', TRUE,  11, '90 to 120 minutes. Fuels your overnight session.'),
    ('19:00', 'Work session 3',                           'Work',      FALSE, 12, 'Any remaining daytime deadlines.'),
    ('21:00', 'Break + meal',                             'Break',     FALSE, 13, 'Eat before the overnight push.'),
    ('22:00', 'OVERNIGHT MAIN WORK SESSION',              'Work',      FALSE, 14, 'Longest and most intensive session.'),
    ('02:00', 'Wind down',                                'Personal',  FALSE, 15, 'Stop adding new tasks. Wrap up what you are on.'),
    ('03:00', 'Sleep',                                    'PROTECTED', TRUE,  16, 'Minimum 4 hours. Non-negotiable.');
```

---

## 6. Key Queries

### Today view — assignments due in the current work day

```sql
-- Work day = 08:00 today to 07:59 tomorrow (UTC adjusted at app layer)
SELECT
    a.id,
    c.name          AS client_name,
    a.assignment_type,
    a.course,
    a.word_count,
    a.estimated_hours,
    a.deadline,
    a.status,
    a.payment_kes,
    a.notes,
    (a.deadline - NOW()) AS time_remaining
FROM assignments a
JOIN clients c ON c.id = a.client_id
WHERE
    a.is_active = TRUE
    AND a.status NOT IN ('Submitted', 'Cancelled')
    AND a.deadline >= :day_start   -- 08:00 today UTC
    AND a.deadline <  :day_end     -- 08:00 tomorrow UTC
ORDER BY
    a.deadline ASC,
    c.priority DESC;
```

### Client tracker — active and submitted counts

```sql
SELECT
    c.id,
    c.name,
    c.platform,
    c.priority,
    COUNT(a.id) FILTER (
        WHERE a.status IN ('Not started', 'In progress')
    )                              AS active_count,
    COUNT(a.id) FILTER (
        WHERE a.status = 'Submitted'
        AND a.submitted_at >= date_trunc('week', NOW())
    )                              AS submitted_this_week,
    COUNT(a.id) FILTER (
        WHERE a.status = 'Overdue'
    )                              AS overdue_count,
    COALESCE(SUM(a.payment_kes) FILTER (
        WHERE a.status = 'Submitted'
    ), 0)                          AS total_earned_kes
FROM clients c
LEFT JOIN assignments a
    ON a.client_id = c.id AND a.is_active = TRUE
WHERE c.is_active = TRUE
GROUP BY c.id, c.name, c.platform, c.priority
ORDER BY c.priority DESC, c.name ASC;
```

### Weekly overload check — assignments per day this week

```sql
SELECT
    DATE(a.deadline AT TIME ZONE 'Africa/Nairobi')  AS due_date,
    COUNT(*)                                         AS assignment_count,
    SUM(a.estimated_hours)                           AS total_hours,
    CASE
        WHEN COUNT(*) > 3
          OR SUM(a.estimated_hours) > 9
        THEN TRUE
        ELSE FALSE
    END                                              AS is_overloaded
FROM assignments a
WHERE
    a.is_active = TRUE
    AND a.status NOT IN ('Submitted', 'Cancelled')
    AND a.deadline >= date_trunc('week', NOW() AT TIME ZONE 'Africa/Nairobi')
    AND a.deadline <  date_trunc('week', NOW() AT TIME ZONE 'Africa/Nairobi')
                      + INTERVAL '7 days'
GROUP BY due_date
ORDER BY due_date ASC;
```

---

## 7. Migration File Naming Convention
migrations/
001_create_clients.sql
002_create_assignments.sql
003_create_assignment_status_log.sql
004_create_schedule_blocks.sql
005_create_indexes.sql
006_seed_schedule_blocks.sql
Each file runs once in order. No migration framework for MVP —
plain SQL files executed manually or via a setup script.

---

*Schema version 1.0 — updates committed with message: docs: update schema vX.X*
