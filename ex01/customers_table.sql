-- =============================================================================
-- EX01 – tabla customers (Módulo 1 – Data Warehouse)
-- Objetivo: unir todas las tablas data_202*_*** en una tabla llamada "customers"
--
-- "Unir" significa apilar las tablas mensuales de eventos (mismas columnas),
-- no realizar un JOIN relacional mediante una clave. Usa UNION ALL para no perder filas.
-- La eliminación de duplicados corresponde a EX02; NO filtres duplicados aquí.
-- =============================================================================

DROP TABLE IF EXISTS customers;

-- UNION ALL explícito de las tablas mensuales del Módulo 0, incluida data_2023_feb.
-- Si tu BD tiene archivos de otros meses, adapta la lista o usa customers_table.py,
-- que detecta todas las tablas públicas cuyo nombre coincide con data_202%.

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

-- Comprobación opcional (ejecutar manualmente después de este script):
-- SELECT COUNT(*) FROM customers;
-- Debe ser igual a la suma de COUNT(*) de oct, nov, dec, jan y feb.
