-- Demo schema

CREATE TABLE bronze_trino_query_events (
    query_id TEXT PRIMARY KEY,
    query_text TEXT,
    user_name TEXT,
    source TEXT,
    query_state TEXT,
    created_at TEXT,
    event_date TEXT,
    wall_time_ms INTEGER,
    cpu_time_ms INTEGER,
    peak_user_memory_bytes INTEGER,
    physical_input_bytes INTEGER,
    written_bytes INTEGER,
    inputs_metadata_json TEXT
);

CREATE TABLE silver_dim_team (
    team_id TEXT PRIMARY KEY,
    team_name TEXT,
    department TEXT
);

CREATE TABLE silver_dim_user (
    user_name TEXT PRIMARY KEY,
    email TEXT,
    user_type TEXT
);

CREATE TABLE silver_dim_user_team_history (
    user_name TEXT,
    team_id TEXT,
    valid_from TEXT,
    valid_to TEXT
);

CREATE TABLE silver_dim_table (
    table_name TEXT PRIMARY KEY,
    catalog_name TEXT,
    schema_name TEXT,
    owner_team_id TEXT
);

CREATE TABLE silver_fact_query_execution (
    query_id TEXT PRIMARY KEY,
    user_name TEXT,
    team_id TEXT,
    source TEXT,
    query_state TEXT,
    created_at TEXT,
    wall_time_ms INTEGER,
    cpu_time_ms INTEGER,
    cpu_time_hours REAL,
    peak_user_memory_bytes INTEGER,
    physical_input_bytes INTEGER,
    written_bytes INTEGER,
    estimated_cost_usd REAL,
    execution_date TEXT
);

CREATE TABLE silver_fact_query_table_access (
    query_id TEXT,
    table_name TEXT,
    user_name TEXT,
    team_id TEXT,
    physical_bytes_read INTEGER,
    rows_read INTEGER,
    execution_date TEXT
);

CREATE TABLE gold_mart_table_daily_usage (
    execution_date TEXT,
    table_name TEXT,
    distinct_users_count INTEGER,
    distinct_teams_count INTEGER,
    total_queries_count INTEGER,
    total_physical_bytes_read INTEGER,
    total_rows_read INTEGER,
    PRIMARY KEY (execution_date, table_name)
);

CREATE TABLE gold_mart_team_daily_resource_usage (
    execution_date TEXT,
    team_id TEXT,
    total_queries_count INTEGER,
    successful_queries_count INTEGER,
    failed_queries_count INTEGER,
    distinct_active_users INTEGER,
    total_cpu_time_hours REAL,
    peak_memory_bytes INTEGER,
    total_physical_input_bytes INTEGER,
    total_estimated_cost_usd REAL,
    PRIMARY KEY (execution_date, team_id)
);
