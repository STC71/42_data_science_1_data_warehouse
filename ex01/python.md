# 🐍 Guía Python – EX01 Customers table

<p align="center">
  <img src="./imgs/python_00.jpg" alt="Module 1 – EX01 – Customers – Guía Python" width="100%">
</p>

[← README EX01](./README.md) · [← sql.md](./sql.md) · [← Module 1](../README.md)

> Si no existe la imagen en `imgs/`, el resto de la guía sigue siendo válida.

---

<a id="indice"></a>
## 📑 Índice

### Parte A – Python mínimo
1. [¿Para quién?](#para-quien)
2. [Script, `def`, `import`, f-strings](#basico)
3. [Listas y bucles](#listas)

### Parte B – `customers_table.py`
4. [Objetivo del subject](#subject)
5. [Por qué Python además del SQL](#por-que-py)
6. [Flujo del script](#flujo)
7. [Descubrir tablas `data_202%`](#discover)
8. [Armar el `UNION ALL` dinámico](#union)
9. [Ejecutar y comprobar](#ejecutar)
10. [Glosario](#glosario)

---

<a id="para-quien"></a>
## 👋 ¿Para quién?

Para entender `customers_table.py`: apilar **automáticamente** todas las tablas `data_202*` en **`customers`**.

[↑ Volver al índice](#indice)

---

<a id="basico"></a>
## 🧱 Script, `def`, `import`, f-strings

Igual que en EX02/EX03:

- ejecutas con `python3 customers_table.py`
- `def` define funciones
- `import` trae `psycopg2`, `Path`, etc.
- `f"Hola {nombre}"` inserta variables en el texto

[↑ Volver al índice](#indice)

---

<a id="listas"></a>
## 📋 Listas y bucles

```python
tablas = ["data_2022_oct", "data_2022_nov"]
for t in tablas:
    print(t)
```

El script obtiene la lista **preguntando a PostgreSQL** qué tablas públicas coinciden con `data_202%`, no escribiendo los nombres a mano (más fiel a “all the data_202*_*** tables”).

[↑ Volver al índice](#indice)

---

<a id="subject"></a>
## 🎯 Objetivo del subject

Unir todas las `data_202*_***` en una tabla llamada exactamente **`customers`**.  
Entrega: `customers_table.*`.

[↑ Volver al índice](#indice)

---

<a id="por-que-py"></a>
## 💡 Por qué Python además del SQL

| SQL fijo | Python |
|----------|--------|
| Lista de meses escrita a mano | Descubre `data_202%` en el catálogo del sistema |
| Falla si falta un mes de la lista | Solo une las tablas que existen |

Ambos son válidos como entrega; el `.py` es más robusto si el conjunto de meses cambia.

[↑ Volver al índice](#indice)

---

<a id="flujo"></a>
## 🗺️ Flujo del script

```text
deps → .env → conectar
  → listar tablas data_202%
  → DROP customers
  → CREATE customers AS SELECT * FROM t1 UNION ALL SELECT * FROM t2 ...
  → COUNT y mensajes
```

[↑ Volver al índice](#indice)

---

<a id="discover"></a>
## 🔍 Descubrir tablas `data_202%`

Consulta al diccionario de PostgreSQL (`pg_tables` / `information_schema`): nombres públicos que empiezan por `data_202`.  
Así no hardcodeas `oct`, `nov`, `dec`… en el código de descubrimiento.

[↑ Volver al índice](#indice)

---

<a id="union"></a>
## 📚 Armar el UNION ALL dinámico

El script construye un texto SQL del estilo:

```sql
CREATE TABLE customers AS
SELECT * FROM data_2022_oct
UNION ALL
SELECT * FROM data_2022_nov
...
```

y lo ejecuta de una vez con `psycopg2`.  
**No** hace un bucle de millones de `INSERT` en Python.

[↑ Volver al índice](#indice)

---

<a id="ejecutar"></a>
## ▶️ Ejecutar y comprobar

```bash
python3 customers_table.py
```

```sql
SELECT COUNT(*) FROM customers;
-- debe ≈ suma de los COUNT de cada data_202*
```

[↑ Volver al índice](#indice)

---

<a id="glosario"></a>
## 📖 Glosario

| Término | Significado |
|---------|-------------|
| `UNION ALL` | Apilar sin quitar duplicados |
| Catálogo / `pg_tables` | Metadatos: qué tablas existen |
| Hardcodear | Escribir nombres fijos en el código |

[↑ Volver al índice](#indice)

---

*Module 1 – EX01 – Guía Python – sternero – 42 Málaga – 2026*
