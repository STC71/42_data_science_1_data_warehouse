-- =============================================================================
-- EX02 – remove_duplicates.sql
-- Module 1 – Data Warehouse – Piscine Data Science
--
-- Qué pide el subject:
--   Borrar las filas duplicadas de la tabla "customers".
--   A veces el servidor registra la misma instrucción dos veces con 1 segundo
--   de diferencia; esas filas también hay que eliminarlas.
--
-- Ejemplo del subject (misma acción, mismo producto, 1 segundo de diferencia):
--   2022-10-01 00:00:32  remove_from_cart  5779403
--   2022-10-01 00:00:33  remove_from_cart  5779403
--   → debe quedar solo UNA de las dos.
--
-- Estrategia (una sola pasada con función de ventana):
--   1) Agrupar por las claves de negocio de una "instrucción":
--        user_id, user_session, event_type, product_id, price
--   2) Ordenar por event_time (y ctid para un desempate estable)
--   3) Comparar cada fila con la anterior del mismo grupo (LAG)
--   4) Si la diferencia de tiempo es 0 o ≤ 1 segundo → borrar la posterior
--
-- Así cubrimos:
--   • duplicados exactos (mismo instante y mismas claves)
--   • casi-duplicados (intervalo de 1 segundo, como en el subject)
--
-- NOTA: reescribe una tabla muy grande (~20 millones de filas).
--       Puede tardar varios minutos. Es normal.
-- =============================================================================

-- Opcional: ver cuántas filas hay ANTES de limpiar (quita el comentario para usar)
-- SELECT COUNT(*) AS customers_antes FROM customers;

-- -----------------------------------------------------------------------------
-- DELETE de ecos y duplicados exactos usando LAG sobre claves de negocio
-- -----------------------------------------------------------------------------
-- ctid = identificador físico interno de la fila en PostgreSQL
--        (único por versión de fila). No es una columna de negocio;
--        solo nos sirve para decir "borra ESTA fila concreta".
--
-- PARTITION BY = "junta en el mismo grupo las filas que representan
--                 la misma instrucción lógica del cliente"
-- ORDER BY event_time, ctid = orden cronológico; si el tiempo coincide,
--                             ctid decide un orden estable
-- LAG(event_time) = marca de tiempo de la fila ANTERIOR dentro del grupo
-- -----------------------------------------------------------------------------

DELETE FROM customers AS c
USING (
    -- Lista de filas (por ctid) que debemos borrar
    SELECT s.ctid AS rid
    FROM (
        SELECT
            ctid,
            event_time,
            -- Reloj de la fila de arriba en el mismo grupo de negocio
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
      -- Hay una fila anterior en el grupo
      AND s.event_time - s.prev_time <= INTERVAL '1 second'
      -- Y llegó a 0 segundos (duplicado exacto) o como máximo 1 segundo después
) AS d
WHERE c.ctid = d.rid;
-- Solo se eliminan las filas cuyo ctid está en la lista "d"
-- La PRIMERA fila de cada grupo tiene prev_time NULL → no se borra

-- Opcional: filas que quedan DESPUÉS de la limpieza
-- SELECT COUNT(*) AS customers_despues FROM customers;

-- =============================================================================
-- Fin de remove_duplicates.sql
-- =============================================================================
