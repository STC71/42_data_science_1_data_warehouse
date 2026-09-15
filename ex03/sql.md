# 📘 Guía SQL – EX03 Fusion

[← README EX03](./README.md) · [← Module 1](../README.md)

---

<a id="indice"></a>
## 📑 Índice

1. [Para quién es esta guía](#para-quien)
2. [Objetivo del subject](#objetivo)
3. [JOIN en una frase](#join)
4. [LEFT JOIN vs INNER JOIN](#left)
5. [Clave de unión: product_id](#clave)
6. [DISTINCT ON en items](#distinct)
7. [El script completo, bloque a bloque](#completo)
8. [Por qué DROP + RENAME](#rename)
9. [Cómo ejecutarlo](#ejecutar)
10. [Comprobar](#comprobar)
11. [Glosario](#glosario)

---

<a id="para-quien"></a>
## 👋 Para quién es esta guía

Para quien ya tiene **`customers`** (limpia) e **`items`** y debe **fusionarlas** sin haber profundizado en JOINs.

[↑ Volver al índice](#indice)

---

<a id="objetivo"></a>
## 🎯 Objetivo del subject

Pegar en cada fila de **customers** la información de catálogo de **items**, sin eliminar ningún evento.

Columnas nuevas típicas:

- `category_id`
- `category_code`
- `brand`

[↑ Volver al índice](#indice)

---

<a id="join"></a>
## 🔗 JOIN en una frase

Un **JOIN** combina filas de dos tablas cuando se cumple una condición (aquí: mismo `product_id`).

Analogía: dos listados de Excel; la columna común es el “código de producto”.

[↑ Volver al índice](#indice)

---

<a id="left"></a>
## 📐 LEFT JOIN vs INNER JOIN

```text
customers (izquierda)          items (derecha)
     ●──── match ────●
     ●──── match ────●
     ●  (sin match)      →  con LEFT JOIN esta fila SE QUEDA (NULL a la derecha)
```

| JOIN | ¿Conserva todos los customers? |
|------|--------------------------------|
| `INNER JOIN` | No |
| `LEFT JOIN` | **Sí** ← lo que pide el subject |

[↑ Volver al índice](#indice)

---

<a id="clave"></a>
## 🔑 Clave de unión: product_id

```sql
ON c.product_id = i.product_id
```

Es el puente natural entre el evento y la ficha del producto (Module 0 y subject de items).

[↑ Volver al índice](#indice)

---

<a id="distinct"></a>
## 🧩 DISTINCT ON en items

```sql
SELECT DISTINCT ON (product_id)
    product_id, category_id, category_code, brand
FROM items
ORDER BY product_id
```

Si hubiera **dos fichas** para el mismo producto, un JOIN simple **duplicaría** cada evento de ese producto.  
`DISTINCT ON` deja **una** ficha por `product_id` y evita inflar `customers`.

[↑ Volver al índice](#indice)

---

<a id="completo"></a>
## 📜 El script completo, bloque a bloque

```sql
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
LEFT JOIN ( ... items deduplicado ... ) AS i
  ON c.product_id = i.product_id;

DROP TABLE customers;
ALTER TABLE customers_fused RENAME TO customers;
```

| Paso | Para qué |
|------|----------|
| `CREATE ... AS SELECT` | Materializa la fusión |
| `LEFT JOIN` | No pierde eventos |
| `DROP` + `RENAME` | Deja el nombre final `customers` |

[↑ Volver al índice](#indice)

---

<a id="rename"></a>
## 🏷️ Por qué DROP + RENAME

PostgreSQL no tiene un “REPLACE TABLE” simple y portable aquí.  
Crear → borrar la vieja → renombrar es el patrón habitual y deja el **mismo nombre** que espera la evaluación.

[↑ Volver al índice](#indice)

---

<a id="ejecutar"></a>
## ▶️ Cómo ejecutarlo

```bash
docker cp fusion.sql postgres_piscineds:/tmp/fusion.sql
docker exec -it postgres_piscineds \
  psql -U "$(whoami)" -d piscineds -W -f /tmp/fusion.sql
```

[↑ Volver al índice](#indice)

---

<a id="comprobar"></a>
## ✅ Comprobar

```sql
\d customers
SELECT COUNT(*) FROM customers;
SELECT COUNT(*) FILTER (WHERE brand IS NULL) AS sin_marca FROM customers;
```

[↑ Volver al índice](#indice)

---

<a id="glosario"></a>
## 📖 Glosario

| Término | Significado |
|---------|-------------|
| JOIN | Combinar tablas por una condición |
| LEFT JOIN | Conserva todas las filas de la tabla izquierda |
| DISTINCT ON | Una fila por valor de una columna (PostgreSQL) |
| NULL | “Sin dato” (evento sin ficha en items) |

[↑ Volver al índice](#indice)

---

*Module 1 – EX03 – Guía SQL – sternero – 42 Málaga – 2026*
