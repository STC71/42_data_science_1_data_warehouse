-- =============================================================================
-- EX01 – customers table (Module 1 – Data Warehouse)
-- Subject: join all data_202*_*** tables into a table called "customers"
--
-- "Join together" here means stacking monthly event tables (same columns),
-- not a relational JOIN by key. Use UNION ALL so no rows are dropped.
-- Deduplication is EX02; do NOT filter duplicates here.
-- =============================================================================

DROP TABLE IF EXISTS customers;

-- Explicit UNION ALL of the Module 0 monthly tables.
-- If your BD has different month files, adapt the list or use customers_table.py
-- which discovers every public table matching data_202%.

CREATE TABLE customers AS
SELECT * FROM data_2022_oct
UNION ALL
SELECT * FROM data_2022_nov
UNION ALL
SELECT * FROM data_2022_dec
UNION ALL
SELECT * FROM data_2023_jan;

-- Optional sanity check (run manually after this script):
-- SELECT COUNT(*) FROM customers;
-- Should equal COUNT(oct)+COUNT(nov)+COUNT(dec)+COUNT(jan).
