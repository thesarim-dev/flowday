INSERT INTO schedule_blocks
    (start_time, label, block_type, is_protected, sort_order, notes)
VALUES
    ('07:30', 'Wake up — check WhatsApp for updates',  'Personal',  FALSE, 1,  'Check for new assignments only — do not start working yet'),
    ('08:07', 'Baby school drop-off',                   'Family',    TRUE,  2,  'Non-negotiable. Do not schedule anything here.'),
    ('08:30', 'Freshen up + skincare routine',          'Personal',  FALSE, 3,  'Your transition time. Keep it.'),
    ('09:30', 'READING BLOCK',                          'PROTECTED', TRUE,  4,  'Your mental reset. 60 minutes minimum.'),
    ('10:30', 'LEARNING BLOCK — coding',               'PROTECTED', TRUE,  5,  '30 minutes every day. One lesson. No skipping.'),
    ('11:00', 'Chores + Breakfast',                     'Personal',  FALSE, 6,  'Eat properly. You are working overnight.'),
    ('11:30', 'Work session 1',                         'Work',      FALSE, 7,  'Highest urgency assignment first.'),
    ('13:30', 'Short break (15 min)',                   'Break',     FALSE, 8,  'Stand up, step away from the screen.'),
    ('13:45', 'Work session 2',                         'Work',      FALSE, 9,  'Second most urgent assignment.'),
    ('16:00', 'Light personal time',                    'Personal',  FALSE, 10, 'Avoid screens if possible.'),
    ('17:00', 'EVENING NAP',                            'PROTECTED', TRUE,  11, '90 to 120 minutes. Fuels your overnight session.'),
    ('19:00', 'Work session 3',                         'Work',      FALSE, 12, 'Any remaining daytime deadlines.'),
    ('21:00', 'Break + meal',                           'Break',     FALSE, 13, 'Eat before the overnight push.'),
    ('22:00', 'OVERNIGHT MAIN WORK SESSION',            'Work',      FALSE, 14, 'Longest and most intensive session.'),
    ('02:00', 'Wind down',                              'Personal',  FALSE, 15, 'Stop adding new tasks. Wrap up what you are on.'),
    ('03:00', 'Sleep',                                  'PROTECTED', TRUE,  16, 'Minimum 4 hours. Non-negotiable.');
