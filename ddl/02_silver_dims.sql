-- Teams directory
CREATE TABLE IF NOT EXISTS silver.dim_team (
    team_id VARCHAR,
    team_name VARCHAR,
    department VARCHAR
)
WITH (
    format = 'PARQUET'
);

-- Users and service accounts
CREATE TABLE IF NOT EXISTS silver.dim_user (
    user_name VARCHAR,
    email VARCHAR,
    user_type VARCHAR
)
WITH (
    format = 'PARQUET'
);

-- User team affiliations with validity date range
CREATE TABLE IF NOT EXISTS silver.dim_user_team_history (
    user_name VARCHAR,
    team_id VARCHAR,
    valid_from DATE,
    valid_to DATE
)
WITH (
    format = 'PARQUET'
);

-- Tables registry
CREATE TABLE IF NOT EXISTS silver.dim_table (
    table_name VARCHAR,
    catalog_name VARCHAR,
    schema_name VARCHAR,
    owner_team_id VARCHAR
)
WITH (
    format = 'PARQUET'
);
