-- Mock data for the demo

-- 1. Teams
INSERT INTO silver_dim_team VALUES
('product-analytics', 'Product Analytics Team', 'Analytics'),
('billing-de', 'Billing Data Engineering', 'Finance'),
('growth-marketing', 'Growth & Marketing', 'Growth');

-- 2. Users
INSERT INTO silver_dim_user VALUES
('alice.p', 'alice.p@jetbrains.com', 'HUMAN'),
('bob.k', 'bob.k@jetbrains.com', 'HUMAN'),
('charlie.m', 'charlie.m@jetbrains.com', 'HUMAN'),
('diana.v', 'diana.v@jetbrains.com', 'HUMAN');

-- 3. User-Team History
-- Diana moved from product-analytics to growth-marketing on 2026-09-02
INSERT INTO silver_dim_user_team_history VALUES
('alice.p', 'product-analytics', '2026-01-01', '9999-12-31'),
('bob.k', 'product-analytics', '2026-01-01', '9999-12-31'),
('charlie.m', 'billing-de', '2026-01-01', '9999-12-31'),
('diana.v', 'product-analytics', '2026-01-01', '2026-09-02'),
('diana.v', 'growth-marketing', '2026-09-02', '9999-12-31');

-- 4. Tables Catalog
INSERT INTO silver_dim_table VALUES
('iceberg.product_analytics.events_log', 'iceberg', 'product_analytics', 'product-analytics'),
('iceberg.product_analytics.user_profiles', 'iceberg', 'product_analytics', 'product-analytics'),
('iceberg.billing.subscription_orders', 'iceberg', 'billing', 'billing-de');

-- 5. Mock Raw Trino Events
INSERT INTO bronze_trino_query_events VALUES
-- Query 1: Alice queries events_log on 2026-09-01
(
    'q_001',
    'SELECT count(*) FROM events_log',
    'alice.p',
    'DataGrip',
    'FINISHED',
    '2026-09-01 10:15:00',
    '2026-09-01',
    4500,
    18000,
    536870912,
    838860800,
    0,
    '[{"catalogName":"iceberg","schemaName":"product_analytics","tableName":"events_log","physicalInputBytes":838860800,"physicalInputRows":500000}]'
),
-- Query 2: Bob runs a join between events_log and user_profiles on 2026-09-01
(
    'q_002',
    'SELECT u.country, count(*) FROM events_log e JOIN user_profiles u ON e.user_id = u.id GROUP BY 1',
    'bob.k',
    'DataGrip',
    'FINISHED',
    '2026-09-01 11:30:00',
    '2026-09-01',
    12000,
    48000,
    1073741824,
    1258291200,
    0,
    '[{"catalogName":"iceberg","schemaName":"product_analytics","tableName":"events_log","physicalInputBytes":1048576000,"physicalInputRows":700000},{"catalogName":"iceberg","schemaName":"product_analytics","tableName":"user_profiles","physicalInputBytes":209715200,"physicalInputRows":100000}]'
),
-- Query 3: Diana queries events_log on 2026-09-01 (attributed to product-analytics)
(
    'q_003',
    'SELECT user_id FROM events_log LIMIT 100',
    'diana.v',
    'trino-cli',
    'FINISHED',
    '2026-09-01 14:00:00',
    '2026-09-01',
    1500,
    3500,
    134217728,
    52428800,
    0,
    '[{"catalogName":"iceberg","schemaName":"product_analytics","tableName":"events_log","physicalInputBytes":52428800,"physicalInputRows":1000}]'
),
-- Query 4: Charlie (billing-de) queries subscriptions on 2026-09-01
(
    'q_004',
    'SELECT count(*) FROM subscription_orders',
    'charlie.m',
    'Airflow',
    'FINISHED',
    '2026-09-01 16:00:00',
    '2026-09-01',
    6000,
    24000,
    419430400,
    524288000,
    0,
    '[{"catalogName":"iceberg","schemaName":"billing","tableName":"subscription_orders","physicalInputBytes":524288000,"physicalInputRows":250000}]'
),
-- Query 5: Alice queries events_log on 2026-09-02
(
    'q_005',
    'SELECT distinct event_name FROM events_log',
    'alice.p',
    'DataGrip',
    'FINISHED',
    '2026-09-02 09:00:00',
    '2026-09-02',
    3000,
    12000,
    314572800,
    629145600,
    0,
    '[{"catalogName":"iceberg","schemaName":"product_analytics","tableName":"events_log","physicalInputBytes":629145600,"physicalInputRows":400000}]'
),
-- Query 6: Diana queries events_log on 2026-09-02 (attributed to growth-marketing after transfer)
(
    'q_006',
    'SELECT * FROM events_log WHERE event_date = "2026-09-02"',
    'diana.v',
    'DataGrip',
    'FINISHED',
    '2026-09-02 11:00:00',
    '2026-09-02',
    5000,
    20000,
    524288000,
    734003200,
    0,
    '[{"catalogName":"iceberg","schemaName":"product_analytics","tableName":"events_log","physicalInputBytes":734003200,"physicalInputRows":450000}]'
);
