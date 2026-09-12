# 📊 Piscine Data Science – Module 1 – Data Warehouse

<p align="center">
  <em>ETL · customers · deduplicación · fusión con items</em>
</p>

---

<a id="indice"></a>
## 📑 Índice

1. [¿De qué trata?](#proyecto)
2. [Estructura](#estructura)
3. [Prerrequisito: Module 0](#prereq)
4. [Orden de trabajo](#orden)
5. [Checklist](#checklist)

---

<a id="proyecto"></a>
## 🎯 ¿De qué trata?

El subject introduce el **Data Warehouse** y el proceso **ETL** (Extract, Transform, Load): integrar fuentes en un almacén coherente.

Trabajas sobre la base **`piscineds`** creada en Module 0.

[↑ Volver al índice](#indice)

---

<a id="estructura"></a>
## 📋 Estructura (subject)

| Carpeta | Ejercicio | Entrega |
|---------|-----------|---------|
| [`ex00/`](ex00/README.md) | Show me your DB | GUI (pgAdmin / DBeaver / …) |
| [`ex01/`](ex01/README.md) | customers table | `customers_table.*` |
| [`ex02/`](ex02/README.md) | remove duplicates | `remove_duplicates.*` |
| [`ex03/`](ex03/README.md) | fusion | `fusion.*` |

[↑ Volver al índice](#indice)

---

<a id="prereq"></a>
## 🔗 Prerrequisito: Module 0

Antes de EX01–EX03 deben existir en PostgreSQL, como mínimo:

- Tablas `data_2022_*` / `data_2023_*` (eventos)
- Tabla `items` (catálogo)

Y un contenedor accesible en `localhost:5432` con usuario = login, password `mysecretpassword`, BD `piscineds`.

[↑ Volver al índice](#indice)

---

<a id="orden"></a>
## 🚀 Orden de trabajo

1. **[EX00](ex00/README.md)** — Ver la BD con una GUI  
2. **EX01** — Unir todos los `data_202*` en **`customers`**  
3. **EX02** — Eliminar duplicados (incl. ~1 s)  
4. **EX03** — Fusionar `customers` + `items` sin perder información  

[↑ Volver al índice](#indice)

---

<a id="checklist"></a>
## ✅ Checklist subject

| Ítem | ☐ |
|------|---|
| EX00: GUI conectada y búsqueda por ID | ☐ |
| EX01: tabla `customers` | ☐ |
| EX02: sin duplicados según subject | ☐ |
| EX03: fusión sin pérdida de info | ☐ |
| Nombres de carpetas/ficheros exactos | ☐ |

---

*sternero – 42 Málaga – Module 1 – Data Warehouse*
