# 🐍 Guía Python – EX03 Fusion

<p align="center">
  <img src="./imgs/python_02.jpg" alt="Module 1 – EX03 – Fusion – python.md" width="100%">
</p>

[← README EX03](./README.md)

---

<a id="indice"></a>
## 📑 Índice

1. [Para quién es esta guía](#para-quien)
2. [Qué hace el script](#que-hace)
3. [Estructura del archivo](#estructura)
4. [Dependencias y .env](#deps)
5. [Comprobaciones previas](#previas)
6. [Ejecución del SQL de fusión](#sql)
7. [Conteos y control de calidad](#conteos)
8. [Cómo ejecutarlo](#ejecutar)
9. [Errores habituales](#errores)
10. [Glosario](#glosario)

---

<a id="para-quien"></a>
## 👋 Para quién es esta guía

Para lanzar la fusión con:

```bash
python3 fusion.py
```

y entender el código sin ser experto en Python.  
La lógica pesada es **SQL** (LEFT JOIN); Python conecta, ejecuta y muestra resultados.

[↑ Volver al índice](#indice)

---

<a id="que-hace"></a>
## 🎯 Qué hace el script

```text
1. Instalar dependencias si faltan
2. Cargar .env de Module 0
3. Verificar que existen customers e items
4. COUNT de ambas tablas
5. Ejecutar FUSION_SQL (LEFT JOIN + renombrado)
6. COUNT de customers (debe coincidir con el anterior)
7. Contar filas con/sin match en items
```

<p align="center">
  <img src="./imgs/diagrama_py_fusion.png" alt="Module 1 – EX03 – Fusion – Diagrama de flujo fusion.py" width="100%">
</p>

[↑ Volver al índice](#indice)

---

<a id="estructura"></a>
## 🧱 Estructura del archivo

| Bloque | Rol |
|--------|-----|
| `ensure_dependencies` | pip --user si hace falta |
| `find_env_file` | Localizar `.env` |
| `FUSION_SQL` | Mismo contenido conceptual que `fusion.sql` |
| `table_exists` / `count_rows` | Comprobaciones seguras |
| `main` | Orquestación y mensajes |

[↑ Volver al índice](#indice)

---

<a id="deps"></a>
## 📦 Dependencias y .env

Igual que en EX02: `psycopg2-binary`, `python-dotenv`, credenciales del subject vía Module 0.

[↑ Volver al índice](#indice)

---

<a id="previas"></a>
## 🔍 Comprobaciones previas

Si falta `customers` → hay que hacer EX01/EX02.  
Si falta `items` → hay que cargar el catálogo en Module 0 EX04.

El script **sale con error claro** en esos casos en lugar de fallar a mitad del JOIN.

[↑ Volver al índice](#indice)

---

<a id="sql"></a>
## 🗑️ Ejecución del SQL de fusión

```python
cur.execute(FUSION_SQL)
conn.commit()
```

No se hace el JOIN fila a fila en Python (sería inviable con ~19 M filas).

[↑ Volver al índice](#indice)

---

<a id="conteos"></a>
## 🔢 Conteos y control de calidad

- **Mismo COUNT de customers** antes y después → no se perdieron eventos.  
- Conteo con `category_id IS NULL` → eventos sin ficha en el catálogo (válidos).

[↑ Volver al índice](#indice)

---

<a id="ejecutar"></a>
## ▶️ Cómo ejecutarlo

```bash
cd ruta/a/ex03
python3 fusion.py
```
O con...
```bash
chmod +x fusion.py; ./fusion.py
```

O mediante el script [`start.sh`](./start.sh).
```bash
chmod +x start.sh; ./start.sh
```

[↑ Volver al índice](#indice)

---

<a id="errores"></a>
## 🛠️ Errores habituales

| Síntoma | Qué hacer |
|---------|-----------|
| Tabla items inexistente | Module 0 – crear/cargar `items` |
| connection refused | Levantar Docker de Module 0 |
| COUNT distinto tras fusionar | Revisar duplicados en items; el SQL usa DISTINCT ON |

[↑ Volver al índice](#indice)

---

<a id="glosario"></a>
## 📖 Glosario

| Término | Significado |
|---------|-------------|
| LEFT JOIN | Conserva la tabla izquierda |
| commit | Confirmar transacción |
| FILTER (WHERE …) | Contar solo filas que cumplen una condición |

[↑ Volver al índice](#indice)

---

*Module 1 – EX03 – Guía Python – sternero – 42 Málaga – Octubre 2026*
