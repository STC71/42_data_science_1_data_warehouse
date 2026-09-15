-- =============================================================================
-- EX03 – fusion.sql
-- Module 1 – Data Warehouse – Piscine Data Science
--
-- Qué pide el subject:
--   Fusionar la tabla "customers" con la tabla "items".
--   La fusión debe hacerse de forma que NO se pierda información.
--
-- Interpretación práctica (alineada con el PDF):
--   - Partimos de "customers" (eventos de usuario, ya limpia en EX02).
--   - Enriquecemos cada evento con datos del catálogo "items"
--     (category_id, category_code, brand) usando product_id.
--   - Usamos LEFT JOIN: si un product_id de customers no está en items,
--     la fila del evento SE CONSERVA y los campos de items quedan NULL.
--     Un INNER JOIN perdería esos eventos → incumpliría el subject.
--
-- Resultado:
--   La tabla sigue llamándose "customers", pero con columnas extra de items.
--
-- NOTA: con ~19 millones de filas puede tardar varios minutos. Es normal.
-- =============================================================================

-- Opcional: conteo antes de fusionar
-- SELECT COUNT(*) AS customers_antes FROM customers;
-- SELECT COUNT(*) AS items_filas FROM items;

-- -----------------------------------------------------------------------------
-- 1) Construir una versión enriquecida en una tabla temporal de trabajo
-- -----------------------------------------------------------------------------
-- DISTINCT ON (product_id) en items:
--   Si el catálogo tuviera más de una fila por producto, un JOIN directo
--   multiplicaría filas de customers. Nos quedamos con UNA fila por product_id
--   para no inventar eventos ni perder los que ya hay.
-- -----------------------------------------------------------------------------

DROP TABLE IF EXISTS customers_fused;

CREATE TABLE customers_fused AS
SELECT
    c.event_time,
    c.event_type,
    c.product_id,
    c.price,
    c.user_id,
    c.user_session,
    i.category_id,
    i.category_code,
    i.brand
FROM customers AS c
LEFT JOIN (
    SELECT DISTINCT ON (product_id)
        product_id,
        category_id,
        category_code,
        brand
    FROM items
    ORDER BY product_id
) AS i
  ON c.product_id = i.product_id;

-- -----------------------------------------------------------------------------
-- 2) Sustituir customers por la versión fusionada
-- -----------------------------------------------------------------------------
-- Mismo nombre de tabla que espera el resto del módulo / la evaluación.
-- -----------------------------------------------------------------------------

DROP TABLE customers;
ALTER TABLE customers_fused RENAME TO customers;

-- Opcional: verificar
-- SELECT COUNT(*) AS customers_despues FROM customers;
-- SELECT * FROM customers WHERE category_id IS NOT NULL LIMIT 5;
-- SELECT COUNT(*) FILTER (WHERE category_id IS NULL) AS sin_match_en_items FROM customers;

-- =============================================================================
-- Fin de fusion.sql
-- =============================================================================
