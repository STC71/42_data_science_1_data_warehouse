-- =============================================================================
-- EX02 – remove_duplicates.sql
-- Module 1 – Data Warehouse – Piscine Data Science
--
-- Subject:
--   Delete the duplicate rows in the "customers" table.
--   Sometimes the server sends the same instruction twice with a 1 second
--   interval — those rows must also be removed.
--
-- Example from the subject (same product_id, same action, 1 second apart):
--   2022-10-01 00:00:32  remove_from_cart  5779403
--   2022-10-01 00:00:33  remove_from_cart  5779403
--   → keep only ONE of them.
--
-- Strategy (single pass with window function):
--   1) Partition by business keys of an "instruction":
--        user_id, user_session, event_type, product_id, price
--   2) Order by event_time (then ctid for stability)
--   3) Compare each row with the previous one (LAG)
--   4) If the time gap is 0 or ≤ 1 second → delete the later row
--
-- This covers:
--   • exact duplicates (same timestamp and same keys)
--   • near-duplicates (1 second interval as in the subject)
--
-- NOTE: This rewrites a large table (~20M rows). It can take several minutes.
--       Run during evaluation only when the container has enough resources.
-- =============================================================================

-- Optional: see how many rows we start with (uncomment to use)
-- SELECT COUNT(*) AS customers_before FROM customers;

-- -----------------------------------------------------------------------------
-- DELETE near-duplicates and exact duplicates using LAG over business keys
-- -----------------------------------------------------------------------------
-- ctid = physical row identifier inside PostgreSQL (unique per row version).
-- We never expose ctid to the application; we only use it to target DELETEs.
--
-- PARTITION BY = "group rows that represent the same logical instruction"
-- ORDER BY event_time, ctid = chronological order; ctid breaks ties
-- LAG(event_time) = timestamp of the previous row in the same partition
-- -----------------------------------------------------------------------------

DELETE FROM customers AS c
USING (
    SELECT s.ctid AS rid
    FROM (
        SELECT
            ctid,
            event_time,
            LAG(event_time) OVER (
                PARTITION BY
                    user_id,
                    user_session,
                    event_type,
                    product_id,
                    price
                ORDER BY
                    event_time,
                    ctid
            ) AS prev_time
        FROM customers
    ) AS s
    WHERE s.prev_time IS NOT NULL
      AND s.event_time - s.prev_time <= INTERVAL '1 second'
) AS d
WHERE c.ctid = d.rid;

-- Optional: rows remaining after cleanup (uncomment to use)
-- SELECT COUNT(*) AS customers_after FROM customers;

-- =============================================================================
-- End of remove_duplicates.sql
-- =============================================================================
