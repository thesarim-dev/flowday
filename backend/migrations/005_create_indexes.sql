CREATE INDEX idx_assignments_deadline
    ON assignments(deadline)
    WHERE is_active = TRUE AND status NOT IN ('Submitted', 'Cancelled');

CREATE INDEX idx_assignments_client_id
    ON assignments(client_id);

CREATE INDEX idx_assignments_status
    ON assignments(status)
    WHERE is_active = TRUE;

CREATE INDEX idx_status_log_assignment_id
    ON assignment_status_log(assignment_id);

CREATE INDEX idx_schedule_blocks_sort
    ON schedule_blocks(start_time, sort_order)
    WHERE is_active = TRUE;
