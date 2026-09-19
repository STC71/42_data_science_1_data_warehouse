-- =============================================================================
-- EX01 – customers_table.sql
-- Module 1 – Data Warehouse – Piscine Data Science
--
-- Qué pide el subject:
--   Unir todas las tablas data_202*_*** en una tabla llamada exactamente
--   "customers". Entrega: customers_table.*
--
-- Qué significa "unir" aquí:
--   Apilar (verticalmente) las tablas mensuales de eventos, que tienen las
--   MISMAS columnas. NO es un JOIN relacional por user_id entre meses.
--
--   Analogía: varios cuadernos de caja idénticos (uno por mes) → un solo
--   archivador llamado "customers".
--
-- Por qué UNION ALL y no UNION:
--   UNION ALL conserva TODAS las filas (incluso repetidas).
--   UNION (sin ALL) eliminaría duplicados exactos; eso es trabajo de EX02.
--
-- Lista fija de meses:
--   Incluye data_2023_feb si existe en tu BD (CSV del subject / carga Module 0).
--   Si falta algún mes, este script fallará: usa customers_table.py, que
--   descubre solo las tablas public.data_202% que existan.
-- =============================================================================

-- Si customers ya existía (reintento), la borramos para recrearla limpia.
-- IF EXISTS evita el error "table does not exist" la primera vez.
DROP TABLE IF EXISTS customers;

-- CREATE TABLE … AS SELECT materializa el resultado de la consulta
-- en una tabla nueva. Las columnas y tipos se heredan de los data_202*.
CREATE TABLE customers AS
SELECT * FROM data_2022_oct
UNION ALL
SELECT * FROM data_2022_nov
UNION ALL
SELECT * FROM data_2022_dec
UNION ALL
SELECT * FROM data_2023_jan
UNION ALL
SELECT * FROM data_2023_feb;

-- Comprobación opcional (ejecutar a mano después):
--   SELECT COUNT(*) FROM customers;
-- Debe ser ≈ la SUMA de COUNT(*) de cada tabla de origen.
-- =============================================================================
-- Fin de customers_table.sql
-- =============================================================================
