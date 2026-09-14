# 📘 Guía SQL – EX02 Remove duplicates

<p align="center">
  <img src="./imgs/sql_01.jpg" alt="Module 1 – EX02 – Remove duplicates – sql.md" width="100%">
</p>

[← README EX02](./README.md) · [← Module 1](../README.md)

---

<a id="indice"></a>
## 📑 Índice

1. [Para quién es esta guía](#para-quien)
2. [Objetivo del subject en SQL](#objetivo)
3. [Repaso: qué es un DELETE](#delete)
4. [Duplicado exacto vs eco a 1 segundo](#dup)
5. [Ventanas: PARTITION BY, ORDER BY, LAG](#ventanas)
6. [Qué es `ctid`](#ctid)
7. [El DELETE completo, frase a frase](#completo)
8. [Por qué no usamos solo DISTINCT](#distinct)
9. [Cómo ejecutarlo](#ejecutar)
10. [Comprobar](#comprobar)
11. [Glosario](#glosario)

---

<a id="para-quien"></a>
## 👋 Para quién es esta guía

Para quien ya tiene la tabla **`customers`** (EX01) y debe **borrar filas de más** sin haber trabajado antes con funciones de ventana.

No hace falta ser experto en SQL: vamos con analogías y el mismo espíritu que `SQL.md` del Module 0.

[↑ Volver al índice](#indice)

---

<a id="objetivo"></a>
## 🎯 Objetivo del subject en SQL

El PDF pide:

1. Eliminar filas **duplicadas** en `customers`.  
2. Eliminar también el caso en que el servidor envía **la misma instrucción** con **1 segundo** de diferencia.

Traducción a reglas técnicas:

- Misma “instrucción de negocio” ≈ mismos `user_id`, `user_session`, `event_type`, `product_id`, `price`.  
- Si dos eventos así están a **0 o ≤ 1 s** de distancia en el tiempo → nos quedamos con **uno**.

[↑ Volver al índice](#indice)

---

<a id="delete"></a>
## 🗑️ Repaso: qué es un DELETE

```sql
DELETE FROM nombre_tabla
WHERE condicion;
```

- **Borra filas** que cumplen la condición.  
- **No** borra la tabla entera (eso sería `DROP TABLE`).  
- Sin `WHERE`, borraría **todas** las filas (peligroso; aquí no lo hacemos).

Analogía: quitar carteles repetidos de un tablón, no tirar el tablón.

[↑ Volver al índice](#indice)

---

<a id="dup"></a>
## 🔁 Duplicado exacto vs eco a 1 segundo

| Tipo | Ejemplo | Tratamiento |
|------|---------|-------------|
| Exacto | Dos filas **idénticas** (mismo tiempo y mismos campos) | Borrar una |
| Eco (subject) | Misma acción / producto / usuario, tiempos `00:00:32` y `00:00:33` | Borrar la posterior |

Una sola estrategia con **`LAG`** cubre **ambos**: si el tiempo anterior está a ≤ 1 s (incluido 0), la fila actual es redundante.

[↑ Volver al índice](#indice)

---

<a id="ventanas"></a>
## 🪟 Ventanas: PARTITION BY, ORDER BY, LAG

Imagina que ordenas todos los eventos de un mismo cliente/sesión/acción/producto en una fila temporal.

```text
tiempo:  10:00:00   10:00:00   10:00:01   10:05:00
         (primera)  (eco 0s)   (eco 1s)   (otra acción, se conserva)
```

- **`PARTITION BY a, b, c...`**  
  Divide el trabajo en grupos independientes (una “cinta” por instrucción de negocio).

- **`ORDER BY event_time, ctid`**  
  Orden cronológico; `ctid` desempata si el tiempo es igual.

- **`LAG(event_time)`**  
  Mira el **reloj de la fila de arriba** (la anterior en ese grupo).

```sql
LAG(event_time) OVER (
    PARTITION BY user_id, user_session, event_type, product_id, price
    ORDER BY event_time, ctid
) AS prev_time
```

Si `prev_time` no es NULL y `event_time - prev_time <= interval '1 second'`, esta fila es un eco.

[↑ Volver al índice](#indice)

---

<a id="ctid"></a>
## 🏷️ Qué es `ctid`

En PostgreSQL, cada fila tiene un identificador físico interno llamado **`ctid`**.

- Sirve para decir: “borra **esta** fila concreta”.  
- **No** es una columna de negocio; no la uses en el modelo final.  
- Cambia si la fila se reescribe; por eso solo lo usamos en la limpieza puntual.

[↑ Volver al índice](#indice)

---

<a id="completo"></a>
## 📜 El DELETE completo, frase a frase

```sql
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
```

| Parte | Significado |
|-------|-------------|
| Subconsulta interna | Calcula `prev_time` para cada fila |
| `WHERE ... <= INTERVAL '1 second'` | Marca ecos (0 s o 1 s) |
| `DELETE ... USING ...` | Borra de `customers` las filas cuyo `ctid` está en esa lista |
| Primera fila de cada grupo | Tiene `prev_time` NULL → **no** se borra |

[↑ Volver al índice](#indice)

---

<a id="distinct"></a>
## ❓ Por qué no usamos solo DISTINCT

`SELECT DISTINCT *` o `UNION` (sin `ALL`) quitan filas **totalmente idénticas**.

El subject exige también el caso **1 segundo después** con la misma instrucción: los timestamps **no** son iguales, así que `DISTINCT *` **no** basta.

Por eso hace falta la lógica temporal (`LAG` + intervalo).

[↑ Volver al índice](#indice)

---

<a id="ejecutar"></a>
## ▶️ Cómo ejecutarlo

```bash
docker cp remove_duplicates.sql postgres_piscineds:/tmp/remove_duplicates.sql

docker exec -it postgres_piscineds \
  psql -U "$(whoami)" -d piscineds -W -f /tmp/remove_duplicates.sql
```

O desde el menú de [`start.sh`](./start.sh) (opción aplicar SQL).

[↑ Volver al índice](#indice)

---

<a id="comprobar"></a>
## ✅ Comprobar

```sql
SELECT COUNT(*) FROM customers;
```

Opcional (antes/después si comentas las líneas en el `.sql`):

```sql
-- SELECT COUNT(*) AS customers_before FROM customers;
-- (ejecutar DELETE)
-- SELECT COUNT(*) AS customers_after FROM customers;
```

[↑ Volver al índice](#indice)

---

<a id="glosario"></a>
## 📖 Glosario

| Término | Significado breve |
|---------|-------------------|
| `DELETE` | Borrar filas |
| `LAG` | Valor de la fila anterior en la ventana |
| `PARTITION BY` | Agrupar para la ventana |
| `INTERVAL '1 second'` | Duración de un segundo |
| `ctid` | Id físico interno de fila en PostgreSQL |
| Duplicado / eco | Misma instrucción repetida (0 s o ≤ 1 s) |

[↑ Volver al índice](#indice)

---

*Module 1 – EX02 – Guía SQL – sternero – 42 Málaga – Octubre 2026*
