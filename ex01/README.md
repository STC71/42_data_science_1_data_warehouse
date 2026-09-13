# 📦 Ejercicio 01 – customers table

<p align="center">
  <em>Piscine Data Science – Module 1 – Data Warehouse</em>
</p>

[← Volver al README principal](../README.md)

---

<a id="indice"></a>
## 📑 Índice

1. [¿Qué se pide?](#que-se-pide)
2. [Archivos a entregar](#archivos)
3. [Explicación](#explicacion)
4. [Prerrequisitos](#prereq)
5. [Implementación](#implementacion)
6. [Ejecutar](#ejecutar)
7. [Comprobar](#comprobar)
8. [Checklist](#checklist)
9. [Navegación](#navegacion)

---

<a id="que-se-pide"></a>
## 🎯 ¿Qué se pide?

Subject (texto):

> You have to join all the `data_202*_***` tables together in a table called **`customers`**.

| Requisito | Detalle |
|-----------|---------|
| Directorio | `ex01/` |
| Entrega | `customers_table.*` |
| Tabla final | Exactamente **`customers`** |
| Origen | Todas las tablas `data_202*` de Module 0 |

[↑ Volver al índice](#indice)

---

<a id="archivos"></a>
## 📁 Archivos a entregar

| Archivo | Rol |
|---------|-----|
| [`customers_table.sql`](./customers_table.sql) | `UNION ALL` explícito de los cuatro meses |
| [`customers_table.py`](./customers_table.py) | Descubre `data_202%` y crea `customers` |

Cualquiera de los dos cumple el nombre `customers_table.*`.

[↑ Volver al índice](#indice)

---

<a id="explicacion"></a>
## 🧠 Explicación

En Module 0 cada mes es una tabla (`data_2022_oct`, …). Aquí el almacén necesita **una sola** tabla de eventos: **`customers`**.

“Join together” en este ejercicio = **apilar** filas con la misma estructura:

```text
data_2022_oct  ─┐
data_2022_nov  ─┼─►  customers   (UNION ALL)
data_2022_dec  ─┤
data_2023_jan  ─┘
```

- **`UNION ALL`**: no elimina filas repetidas (eso es **EX02**).
- No es un `JOIN` por `user_id` entre meses.

[↑ Volver al índice](#indice)

---

<a id="prereq"></a>
## ⚙️ Prerrequisitos

1. Contenedor `postgres_piscineds` en marcha  
2. Tablas `data_202*` cargadas (Module 0 EX03)  
3. Credenciales habituales: login / `mysecretpassword` / `piscineds`

```bash
docker exec -it postgres_piscineds \
  psql -U "$(whoami)" -d piscineds -c '\dt'
```

[↑ Volver al índice](#indice)

---

<a id="implementacion"></a>
## 🚀 Implementación

### SQL (`customers_table.sql`)

```sql
DROP TABLE IF EXISTS customers;

CREATE TABLE customers AS
SELECT * FROM data_2022_oct
UNION ALL
SELECT * FROM data_2022_nov
UNION ALL
SELECT * FROM data_2022_dec
UNION ALL
SELECT * FROM data_2023_jan;
```

### Python (`customers_table.py`)

1. Lee `.env` de Module 0 si lo encuentra  
2. Lista tablas `public` con nombre `data_202%`  
3. `CREATE TABLE customers AS … UNION ALL …`  
4. Imprime `COUNT(*)`

[↑ Volver al índice](#indice)

---

<a id="ejecutar"></a>
## ▶️ Ejecutar

### Opción A – Python (recomendada si puede haber más/menos meses)

```bash
cd ex01
python3 customers_table.py
```

### Opción B – SQL dentro del contenedor

```bash
docker cp customers_table.sql postgres_piscineds:/tmp/customers_table.sql
docker exec -it postgres_piscineds \
  psql -U "$(whoami)" -d piscineds -W -f /tmp/customers_table.sql
```

[↑ Volver al índice](#indice)

---

<a id="comprobar"></a>
## ✅ Comprobar

```sql
\d customers
SELECT COUNT(*) FROM customers;

-- Debe coincidir con la suma de los meses:
SELECT 'oct' AS m, COUNT(*) FROM data_2022_oct
UNION ALL SELECT 'nov', COUNT(*) FROM data_2022_nov
UNION ALL SELECT 'dec', COUNT(*) FROM data_2022_dec
UNION ALL SELECT 'jan', COUNT(*) FROM data_2023_jan;
```

`COUNT(*)` de `customers` = suma de los cuatro (con `UNION ALL`).

[↑ Volver al índice](#indice)

---

<a id="checklist"></a>
## ✅ Checklist subject

| Requisito | ☐ |
|-----------|---|
| Tabla se llama exactamente `customers` | ☐ |
| Incluye todos los `data_202*` | ☐ |
| Archivo `customers_table.*` en `ex01/` | ☐ |
| `COUNT(*)` coherente con la suma de orígenes | ☐ |

[↑ Volver al índice](#indice)

---

<a id="navegacion"></a>
## 🔗 Navegación

- [← EX00](../ex00/README.md)
- [← README Module 1](../README.md)
- [Siguiente: EX02 – remove duplicates →](../ex02/README.md)

---

*Module 1 – EX01 – sternero – 42 Málaga*
