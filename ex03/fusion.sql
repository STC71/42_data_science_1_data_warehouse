-- =============================================================================
-- EX03 – fusion.sql
-- Module 1 – Data Warehouse – Piscine Data Science
--
-- Qué pide el subject:
--   Fusionar la tabla "customers" con la tabla "items".
--   La fusión debe hacerse de forma que NO se pierda información.
--
-- Interpretación práctica:
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
-- Si existe de una ejecución previa, la borramos para no tener conflictos.

CREATE TABLE customers_fused AS         -- Creamos la tabla de trabajo.
SELECT                                  
-- Seleccionamos todas las columnas de customers e items que nos interesan.
    c.event_time,                       
    c.event_type,
    c.product_id,
    c.price,
    c.user_id,
    c.user_session,
    -- c.* sería otra opción, pero explícito (uno por uno) es mejor que implícito.
    -- c. indica que la columna viene de la tabla customers (alias c). 
    -- El alias c  se define más abajo en FROM customers AS c.
    i.category_id,
    i.category_code,
    i.brand
    -- i. indica que la columna viene de la tabla items (alias i).
    -- El alias i se define más abajo en LEFT JOIN (...) AS i.
FROM customers AS c
-- Alias c para la tabla customers, para no escribir el nombre completo cada vez.
LEFT JOIN (
-- LEFT JOIN para unir la tabla customers (izquierda) con la tabla items (derecha).
-- Además con LEFT JOIN, si un product_id de customers no está en items, 
-- la fila del evento SE CONSERVA y los campos de items quedan NULL.
    SELECT DISTINCT ON (product_id)
    -- SELECT es para elegir qué columnas queremos de la tabla items.
    -- DISTINCT ON es para que no haya duplicados de product_id en la tabla items.
    -- Si hubiese más de una fila con el mismo product_id, se queda con la primera que encuentre.
    -- un JOIN directo multiplicaría filas de customers, así que nos quedamos con UNA fila por 
    -- product_id para no inventar eventos ni perder los que ya hay.
        product_id,
        category_id,
        category_code,
        brand
    FROM items
    -- FROM indica de qué tabla queremos seleccionar los datos, en este caso de items.
    ORDER BY product_id
    -- Ordenamos por product_id para que DISTINCT ON funcione correctamente.
    -- Si no, DISTINCT ON podría quedarse con una fila aleatoria de cada grupo de product_id.
) AS i
-- Alias i para la tabla items, para no escribir el nombre completo cada vez.
  ON c.product_id = i.product_id;
  -- ON indica la condición de unión entre las dos tablas, en este caso que el product_id de 
  -- customers (c.product_id) sea igual al product_id de items (i.product_id).

-- -----------------------------------------------------------------------------
-- 2) Sustituir customers por la versión fusionada
-- -----------------------------------------------------------------------------
-- Mismo nombre de tabla que espera el resto del módulo / la evaluación.
-- -----------------------------------------------------------------------------

DROP TABLE customers;
-- Borramos la tabla original customers para poder renombrar la tabla fusionada.
ALTER TABLE customers_fused RENAME TO customers;
-- ALTER es este caso sirve para cambiar el nombre de la tabla fusionada a customers, 
-- sustituyendo la original.

-- Opcional: verificar
-- SELECT COUNT(*) AS customers_despues FROM customers;
-- SELECT * FROM customers WHERE category_id IS NOT NULL LIMIT 5;
-- SELECT COUNT(*) FILTER (WHERE category_id IS NULL) AS sin_match_en_items FROM customers;

-- =============================================================================
-- Fin de fusion.sql
-- =============================================================================
