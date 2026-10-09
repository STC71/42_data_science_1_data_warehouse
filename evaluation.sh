#!/usr/bin/env bash
###############################################################################
# DATA SCIENCE 1 – Data Warehouse · evaluation.sh
#
# Guía interactiva de defensa basada en evaluation_en.pdf / en.subject.pdf.
# No sustituye la escala oficial ni modifica automáticamente los entregables.
# 
# sternero – 42 Málaga – Octubre 2026
###############################################################################

set -u

readonly RED=$'\033[0;31m'
readonly GREEN=$'\033[0;32m'
readonly YELLOW=$'\033[1;33m'
readonly BLUE=$'\033[0;34m'
readonly CYAN=$'\033[0;36m'
readonly MAGENTA=$'\033[0;35m'
readonly BOLD=$'\033[1m'
readonly DIM=$'\033[2m'
readonly RESET=$'\033[0m'

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

declare -A RESULT
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0
STOP_EVAL=false
PIPELINE_VERIFIED=false
LAST_RESULT_KIND="info"
LAST_RESULT_TEXT="Evaluación iniciada"

CONTAINER_NAME="${DS_CONTAINER_NAME:-postgres_piscineds}"
DB_NAME="${POSTGRES_DB:-piscineds}"
DB_USER="${POSTGRES_USER:-$(id -un 2>/dev/null || whoami)}"

header() {
  clear 2>/dev/null || true
  echo -e "${BOLD}${YELLOW}DATA SCIENCE 1 – Data Warehouse · DEFENSA / EVALUATION${RESET}"
  echo "╔══════════════════════════════════════════════════════════════════╗"
  echo "║  DATA SCIENCE 1 – Data Warehouse · DEFENSA / EVALUATION          ║"
  echo "║  Escala: /PROJECTS/DATA-SCIENCE-1                                ║"
  echo "╚══════════════════════════════════════════════════════════════════╝"
  echo -e "${RESET}"
  echo -e "  ${DIM}Repo: ${SCRIPT_DIR}${RESET}"
  echo -e "  ${DIM}Login: $(id -un 2>/dev/null || whoami) · $(date '+%Y-%m-%d %H:%M')${RESET}"
  echo
}

section() {
  echo
  echo -e "${BOLD}${CYAN}▶ $1${RESET}"
  echo -e "${CYAN}────────────────────────────────────────────────────────────────${RESET}"
  echo
}

subsection() { echo -e "  ${MAGENTA}├─ $1${RESET}"; }
ctx() { echo -e "  ${DIM}$1${RESET}"; }
ctx_blank() { echo; echo; }
info() { echo -e "    ${CYAN}ℹ${RESET} $1"; }
note() { echo -e "    ${DIM}→ $1${RESET}"; }
show_cmd() { echo -e "    ${DIM}${BOLD}\$${RESET} ${YELLOW}$1${RESET}"; }

ok() {
  LAST_RESULT_KIND="success"; LAST_RESULT_TEXT="$1"
  echo -e "    ${GREEN}✓${RESET} $1"; ((PASS_COUNT++)) || true
}

fail() {
  LAST_RESULT_KIND="error"; LAST_RESULT_TEXT="$1"
  echo -e "    ${RED}✗${RESET} $1"; ((FAIL_COUNT++)) || true
}

warn() {
  LAST_RESULT_KIND="warning"; LAST_RESULT_TEXT="$1"
  echo -e "    ${YELLOW}⚠${RESET} $1"; ((WARN_COUNT++)) || true
}

show_last_result() {
  case "$LAST_RESULT_KIND" in
    success) echo -e "  ${GREEN}${BOLD}✅ Último resultado: éxito${RESET}" ;;
    error) echo -e "  ${RED}${BOLD}❌ Último resultado: error${RESET}" ;;
    warning) echo -e "  ${YELLOW}${BOLD}⚠ Último resultado: advertencia${RESET}" ;;
    *) echo -e "  ${CYAN}${BOLD}ℹ Último resultado${RESET}" ;;
  esac
  echo -e "  ${DIM}${LAST_RESULT_TEXT}${RESET}"
  echo -e "  ${DIM}Acumulado: OK=$PASS_COUNT · Errores=$FAIL_COUNT · Avisos=$WARN_COUNT${RESET}"
  echo
}

redraw_after_continue() {
  header
  echo -e "  ${DIM}Continuación de la evaluación; la cabecera se redibuja, el proceso no se reinicia.${RESET}"
  show_last_result
}

pause() {
  echo
  read -r -p "$(echo -e "${CYAN}Pulsa Enter para continuar…${RESET}")"
  redraw_after_continue
}

ask_yes_no() {
  local prompt="$1" default="${2:-n}" answer
  if [[ "$default" == "s" ]]; then
    read -r -p "  ${prompt} [S/n] → " answer
    answer="${answer:-s}"
  else
    read -r -p "  ${prompt} [s/N] → " answer
    answer="${answer:-n}"
  fi
  [[ "$answer" =~ ^[sSyY]$ ]]
}

wait_confirm() {
  local message="${1:-Cuando termine este paso, pulsa Enter}"
  read -r -p "  ${message} → "
  redraw_after_continue
}

find_module0() {
  local candidate
  for candidate in \
    "$SCRIPT_DIR/../data_science_0_creation_db" \
    "$SCRIPT_DIR/../../data_science_0_creation_db" \
    "$HOME/sgoinfre/42_outer_core/piscine_pedago_data_science/data_science_0_creation_db" \
    "$HOME/sgoinfre/students/$(id -un 2>/dev/null || whoami)/42_outer_core/piscine_pedago_data_science/data_science_0_creation_db"
  do
    if [[ -f "$candidate/ex00/docker-compose.yml" ]]; then
      (cd "$candidate" && pwd)
      return 0
    fi
  done
  return 1
}

MODULE0_DIR="$(find_module0 || true)"
if [[ -n "$MODULE0_DIR" && -f "$MODULE0_DIR/ex00/.env" ]]; then
  DB_USER="$(sed -n 's/^POSTGRES_USER=//p' "$MODULE0_DIR/ex00/.env" | head -1)"
  DB_NAME="$(sed -n 's/^POSTGRES_DB=//p' "$MODULE0_DIR/ex00/.env" | head -1)"
fi

docker_psql() {
  docker exec -i "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" -At -v ON_ERROR_STOP=1 -c "$1"
}

check_subject_and_layout() {
  section "0 · Repositorio y adjunto de evaluación"
  ctx "La escala exige evaluar únicamente el repositorio clonado y comprobar sus nombres exactos."
  ctx "El PDF de evaluación adjunta data_2023_feb.csv; el subject del módulo 0 aporta los demás meses y items."
  ctx_blank

  local required=0 f
  for f in README.md start.sh ex00 ex01 ex02 ex03; do
    if [[ -e "$SCRIPT_DIR/$f" ]]; then
      ok "Encontrado: $f"
      ((required++)) || true
    else
      fail "Falta en la raíz: $f"
    fi
  done

  subsection "data_2023_feb.csv"
  if [[ -f "$SCRIPT_DIR/data_2023_feb.csv" ]]; then
    ok "Adjunto encontrado: $SCRIPT_DIR/data_2023_feb.csv"
    RESULT[attachment]=yes
    show_cmd "wc -l \"$SCRIPT_DIR/data_2023_feb.csv\""
    wc -l "$SCRIPT_DIR/data_2023_feb.csv" 2>/dev/null | sed 's/^/      /'
  else
    fail "Falta data_2023_feb.csv en el clon; descárgalo desde Attachments de la evaluación"
    RESULT[attachment]=no
    note "Después, cárgalo como tabla data_2023_feb antes de iniciar la evaluación real"
  fi

  subsection "Ficheros de entrega"
  for f in \
    ex01/customers_table.sql ex01/customers_table.py \
    ex02/remove_duplicates.sql ex02/remove_duplicates.py \
    ex03/fusion.sql ex03/fusion.py
  do
    [[ -f "$SCRIPT_DIR/$f" ]] && ok "$f" || fail "Falta $f"
  done
  [[ "$required" -eq 6 ]] && RESULT[layout]=yes || RESULT[layout]=no
}

check_docker_and_pgadmin() {
  section "1 · Entorno de defensa: PostgreSQL y pgAdmin"
  ctx "EX00 exige demostrar la conexión con la BD; si no funciona, la escala indica que la evaluación se detiene."
  ctx "Este proyecto utiliza pgAdmin como GUI oficial. La evaluación se demostrará con pgAdmin en localhost:5050."
  ctx_blank

  subsection "Contenedor PostgreSQL"
  if ! command -v docker >/dev/null 2>&1; then
    fail "docker no está disponible"
    note "Instala/inicia Docker y vuelve a ejecutar evaluation.sh; el script no puede reparar el motor desde aquí."
    RESULT[ex00]=no
    STOP_EVAL=true
    return 0
  fi
  show_cmd "docker ps -a --filter \"name=^/${CONTAINER_NAME}$\""
  if docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
    ok "$CONTAINER_NAME está ejecutándose"
  else
    fail "$CONTAINER_NAME no está ejecutándose"
    if [[ -n "$MODULE0_DIR" && -f "$MODULE0_DIR/ex00/docker-compose.yml" ]] \
      && ask_yes_no "¿Intentar levantar PostgreSQL ahora desde Module 0?" "s"; then
      local compose_runner="docker compose"
      if ! docker compose version >/dev/null 2>&1 && command -v docker-compose >/dev/null 2>&1; then
        compose_runner="docker-compose"
      fi
      local compose_cmd="$compose_runner -f \"$MODULE0_DIR/ex00/docker-compose.yml\" up -d"
      show_cmd "$compose_cmd"
      if (cd "$MODULE0_DIR/ex00" && $compose_runner up -d); then
        ok "Comando de arranque ejecutado; se vuelve a comprobar el contenedor"
      else
        fail "No se pudo ejecutar el arranque de PostgreSQL"
      fi
    else
      note "Comando manual: cd \"$MODULE0_DIR/ex00\" && docker compose up -d"
    fi
    show_cmd "docker ps --format '{{.Names}}\\t{{.Status}}' | grep '^$CONTAINER_NAME'"
    if docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
      ok "$CONTAINER_NAME está ejecutándose tras la recuperación"
    else
      fail "PostgreSQL sigue sin estar disponible"
      RESULT[ex00]=no
      STOP_EVAL=true
      return 0
    fi
  fi

  subsection "Consulta de conexión"
  show_cmd "docker exec -it $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME -c '\\conninfo'"
  if docker_psql '\conninfo' >/tmp/ds1_conninfo.$$ 2>/dev/null; then
    ok "Conexión a $DB_NAME operativa"
    sed 's/^/      /' /tmp/ds1_conninfo.$$ 
  else
    fail "No se pudo conectar a $DB_NAME"
    note "El contenedor está Up, pero PostgreSQL todavía no acepta esta conexión o faltan credenciales/base de datos."
    note "Comprueba: docker logs $CONTAINER_NAME y el archivo Module 0/ex00/.env."
    if ask_yes_no "¿Reintentar la conexión una vez tras esperar a PostgreSQL?" "s"; then
      sleep 3
      show_cmd "docker exec -it $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME -c '\\conninfo'"
      if docker_psql '\conninfo' >/tmp/ds1_conninfo_retry.$$ 2>/dev/null; then
        ok "Conexión a $DB_NAME operativa tras el reintento"
        sed 's/^/      /' /tmp/ds1_conninfo_retry.$$
      else
        fail "El reintento de conexión también ha fallado"
        STOP_EVAL=true
      fi
      rm -f /tmp/ds1_conninfo_retry.$$
    else
      STOP_EVAL=true
    fi
  fi
  rm -f /tmp/ds1_conninfo.$$

  subsection "pgAdmin / GUI"
  show_cmd "curl -s -o /dev/null -w '%{http_code}\\n' http://localhost:5050"
  if command -v curl >/dev/null 2>&1 && curl -s -o /dev/null -w '%{http_code}' --connect-timeout 2 http://localhost:5050 2>/dev/null | grep -qE '200|301|302|401|403'; then
    ok "pgAdmin responde en http://localhost:5050"
    RESULT[pgadmin]=yes
  else
    warn "pgAdmin no responde en http://localhost:5050"
    note "Arráncalo con el asistente de Module 0 EX01; después vuelve a comprobar http://localhost:5050."
    if [[ -n "$MODULE0_DIR" && -x "$MODULE0_DIR/ex01/start.sh" ]] && ask_yes_no "¿Abrir el asistente de Module 0 para arrancar pgAdmin?" "n"; then
      show_cmd "cd \"$MODULE0_DIR/ex01\" && ./start.sh"
      (cd "$MODULE0_DIR/ex01" && ./start.sh)
    fi
    show_cmd "curl -s -o /dev/null -w '%{http_code}\\n' --connect-timeout 2 http://localhost:5050"
    if command -v curl >/dev/null 2>&1 && curl -s -o /dev/null -w '%{http_code}' --connect-timeout 2 http://localhost:5050 2>/dev/null | grep -qE '200|301|302|401|403'; then
      ok "pgAdmin responde tras la recuperación en http://localhost:5050"
      RESULT[pgadmin]=yes
    else
      fail "pgAdmin sigue sin responder en http://localhost:5050"
      note "Revisa el proceso local, el puerto 5050 y Module 0/ex01/pgAdmin.md."
      RESULT[pgadmin]=no
    fi
  fi
  if [[ "$STOP_EVAL" == true ]]; then
    RESULT[ex00]=no
  else
    RESULT[ex00]=yes
  fi
}

confirm_gui_connection() {
  section "1b · Demostración real de la conexión GUI"
  ctx "La respuesta HTTP confirma únicamente que la interfaz web está disponible."
  ctx "Para EX00 debes demostrar en pgAdmin la conexión real a PostgreSQL y una búsqueda por ID."
  ctx_blank
  show_cmd "xdg-open http://localhost:5050"
  info "1. Abre http://localhost:5050 en el navegador."
  info "2. En pgAdmin, expande Servers → PostgreSQL → Databases → $DB_NAME → Schemas → public → Tables."
  info "3. Haz clic derecho en una tabla data_202* → Query Tool."
  info "4. Ejecuta esta consulta de demostración:"
  show_cmd "SELECT product_id, event_type, event_time FROM data_2022_oct WHERE product_id = 5846774 LIMIT 10;"
  info "5. Muestra que aparecen filas en el panel Data Output y que la consulta se ejecuta correctamente."
  info "6. Repite, si el evaluador lo solicita, buscando por user_id en lugar de product_id."
  echo
  show_cmd "docker exec -it $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME -c \"\\conninfo\""
  note "Comprobación equivalente por terminal: debe indicar database \"$DB_NAME\" y user \"$DB_USER\"."
  if ask_yes_no "¿Se ha mostrado en pgAdmin la conexión a localhost:5432/$DB_NAME y una consulta por ID con filas?" "n"; then
    ok "Conexión GUI demostrada en vivo"
    RESULT[gui]=yes
  else
    fail "No se ha demostrado la conexión GUI exigida por EX00"
    RESULT[gui]=no
    STOP_EVAL=true
  fi
}

show_dynamic_code_points() {
  local file="$1" pattern="$2" description="$3" matches
  echo -e "    ${BOLD}${CYAN}$file${RESET}"
  note "$description"
  if [[ ! -f "$SCRIPT_DIR/$file" ]]; then
    fail "No se encontró $file para explicar el entregable"
    return 0
  fi
  matches="$(grep -nE "$pattern" "$SCRIPT_DIR/$file" | head -8 || true)"
  if [[ -n "$matches" ]]; then
    info "Puntos localizados dinámicamente (no se usan líneas fijas):"
    echo "$matches" | sed 's/^/      /'
  else
    warn "No se localizaron en $file los patrones esperados: $pattern"
  fi
}

explain_exercise() {
  local exercise="$1" file="$2"
  case "$exercise" in
    EX01)
      echo -e "    ${BOLD}Objetivo:${RESET} reunir todos los meses en una tabla llamada customers."
      info "Técnica: descubrimiento dinámico de data_202% + CREATE TABLE AS + UNION ALL."
      info "Por qué: UNION ALL apila los meses y conserva duplicados; EX02 los limpiará después."
      info "Resultado esperado: 20,692,840 filas, una por cada registro de los cinco meses."
      note "Analogía: se juntan cinco archivadores mensuales en uno sin tirar hojas repetidas."
      show_dynamic_code_points "$file" 'data_202%|UNION ALL|CREATE TABLE customers|DROP TABLE IF EXISTS customers' \
        "Busca las tablas origen, prepara una ejecución repetible y materializa el conjunto completo."
      ;;
    EX02)
      echo -e "    ${BOLD}Objetivo:${RESET} eliminar duplicados exactos y ecos de hasta un segundo."
      info "Técnica: LAG(event_time) OVER (PARTITION BY ...) compara cada fila con la anterior del mismo evento."
      info "Por qué: solo se elimina la fila posterior cuando coinciden las claves y la diferencia temporal es ≤ 1 segundo."
      info "Resultado esperado: entre 18,500,000 y 19,200,000 filas; los eventos distintos permanecen."
      note "Analogía: si una caja registra dos veces el mismo ticket casi simultáneamente, se conserva el primero."
      show_dynamic_code_points "$file" 'LAG|PARTITION BY|DELETE FROM customers|1 second|1 segundo' \
        "Localiza la ventana SQL y el DELETE que ejecutan la limpieza en PostgreSQL."
      ;;
    EX03)
      echo -e "    ${BOLD}Objetivo:${RESET} enriquecer customers con el catálogo items sin perder eventos."
      info "Técnica: LEFT JOIN por product_id y selección de la información de catálogo."
      info "Por qué: LEFT JOIN conserva también los eventos cuyo producto no aparece en items."
      info "Resultado esperado: misma cantidad de filas y columnas category_id, category_code y brand."
      note "Analogía: se añade la ficha de producto a cada ticket, pero ningún ticket desaparece si falta la ficha."
      show_dynamic_code_points "$file" 'LEFT JOIN|product_id|CREATE TABLE customers_fused|DROP TABLE customers|category_id|category_code|brand' \
        "Localiza la tabla temporal, la unión y la sustitución final de customers."
      ;;
  esac
}

run_confirmed_deliverable() {
  local exercise="$1" py="$2" sql="$3" expected="$4" explanation="$5"
  local choice command

  subsection "$exercise · explicación y ejecución opcional"
  explain_exercise "$exercise" "$py"
  show_dynamic_code_points "$sql" 'UNION ALL|LAG|LEFT JOIN|CREATE TABLE|DELETE FROM|DROP TABLE' \
    "La alternativa SQL expresa la misma operación directamente en PostgreSQL; sus puntos se localizan en cada ejecución."
  echo
  show_cmd "cd \"$SCRIPT_DIR/$(dirname "$py")\" && python3 \"$(basename "$py")\""
  show_cmd "docker exec -i \"$CONTAINER_NAME\" psql -U \"$DB_USER\" -d \"$DB_NAME\" < \"$SCRIPT_DIR/$sql\""
  note "Resultado esperado: $expected"
  read -r -p "  ¿Qué implementación ejecutar ahora? [P=Python / S=SQL / N=omitir] → " choice
  choice="${choice:-p}"
  case "$choice" in
    [pP])
      command="cd \"$SCRIPT_DIR/$(dirname "$py")\" && python3 \"$(basename "$py")\""
      show_cmd "$command"
      if (cd "$SCRIPT_DIR/$(dirname "$py")" && python3 "$(basename "$py")"); then
        ok "$exercise ejecutado con $py"
      else
        fail "$exercise falló al ejecutar $py"
        return 1
      fi
      ;;
    [sS])
      command="docker exec -i \"$CONTAINER_NAME\" psql -U \"$DB_USER\" -d \"$DB_NAME\" < \"$SCRIPT_DIR/$sql\""
      show_cmd "$command"
      if docker exec -i "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" < "$SCRIPT_DIR/$sql"; then
        ok "$exercise ejecutado con $sql"
      else
        fail "$exercise falló al ejecutar $sql"
        return 1
      fi
      ;;
    *)
      warn "$exercise omitido; se verificará el estado actual sin modificarlo"
      ;;
  esac
}

run_confirmed_pipeline() {
  section "2b · Crear y verificar de nuevo customers"
  ctx "La limpieza deja la base preparada, pero no crea customers por sí sola."
  ctx "Ahora puedes confirmar la ejecución de cada entregable y ver exactamente qué archivo se usa."
  ctx "Cada paso muestra el comando, las líneas principales y el resultado esperado antes de ejecutarse."
  echo
  if ! ask_yes_no "¿Ejecutar ahora EX01, EX02 y EX03 en orden?" "s"; then
    show_pipeline_instructions
    return 0
  fi
  run_confirmed_deliverable "EX01" "ex01/customers_table.py" "ex01/customers_table.sql" \
    "customers con exactamente 20,692,840 filas." \
    "Descubre las tablas data_202%, las apila con UNION ALL y materializa customers."
  pause
  check_ex01
  pause
  run_confirmed_deliverable "EX02" "ex02/remove_duplicates.py" "ex02/remove_duplicates.sql" \
    "customers entre 18,500,000 y 19,200,000 filas." \
    "Calcula la fila anterior con LAG por las claves de la acción y elimina duplicados o ecos de hasta un segundo."
  pause
  check_ex02
  pause
  run_confirmed_deliverable "EX03" "ex03/fusion.py" "ex03/fusion.sql" \
    "el mismo número de filas y category_id, category_code y brand añadidos." \
    "Hace LEFT JOIN con items por product_id, conserva todos los eventos y sustituye customers por la versión enriquecida."
  pause
  check_ex03
  PIPELINE_VERIFIED=true
  ok "Pipeline solicitado terminado; comienzan las comprobaciones cuantitativas"
}

show_pipeline_instructions() {
  info "Si decides ejecutarlo manualmente, usa este orden:"
  show_cmd "cd \"$SCRIPT_DIR/ex01\" && ./start.sh"
  show_cmd "cd \"$SCRIPT_DIR/ex02\" && ./start.sh"
  show_cmd "cd \"$SCRIPT_DIR/ex03\" && ./start.sh"
  note "Los asistentes permiten elegir el .py o aplicar el .sql y muestran COUNT antes/después."
  info "Cuando finalicen los tres pasos, vuelve a ejecutar evaluation.sh para comprobar el resultado."
}

offer_load_february() {
  if [[ -f "$SCRIPT_DIR/data_2023_feb.csv" ]] \
    && printf '%s\n' "$1" | grep -qx 'data_2023_feb'; then
    section "2a · Cargar data_2023_feb.csv"
    ctx "El CSV está disponible en el repositorio, pero la tabla aún no existe en PostgreSQL."
    ctx "Se cargará como tabla fuente independiente; no se mezclará con customers hasta EX01."
    show_cmd "docker exec -i \"$CONTAINER_NAME\" sh -c 'cat > /tmp/data_2023_feb.csv' < \"$SCRIPT_DIR/data_2023_feb.csv\""
    show_cmd "docker exec -i \"$CONTAINER_NAME\" psql -U \"$DB_USER\" -d \"$DB_NAME\" -v ON_ERROR_STOP=1 <<'SQL'"
    echo "      DROP TABLE IF EXISTS data_2023_feb;"
    echo "      CREATE TABLE data_2023_feb (event_time TIMESTAMPTZ, event_type VARCHAR(50), product_id INTEGER, price NUMERIC(10,2), user_id BIGINT, user_session UUID);"
    echo "      COPY data_2023_feb FROM '/tmp/data_2023_feb.csv' WITH (FORMAT csv, HEADER true);"
    echo "      SELECT COUNT(*) FROM data_2023_feb;"
    echo "      SQL"
    info "Se ejecutarán DROP/CREATE/COPY y después se comprobará el número de filas."
    note "La tabla se crea con las mismas seis columnas y tipos que las demás tablas mensuales."
    if ! ask_yes_no "¿Cargar ahora data_2023_feb.csv como tabla fuente?" "s"; then
      info "No se cargó data_2023_feb; la evaluación queda detenida."
      return 1
    fi
    if ! docker exec -i "$CONTAINER_NAME" sh -c 'cat > /tmp/data_2023_feb.csv' < "$SCRIPT_DIR/data_2023_feb.csv"; then
      fail "No se pudo copiar data_2023_feb.csv al contenedor"
      return 1
    fi
    local feb_sql
    feb_sql="DROP TABLE IF EXISTS data_2023_feb;
CREATE TABLE data_2023_feb (
  event_time TIMESTAMPTZ,
  event_type VARCHAR(50),
  product_id INTEGER,
  price NUMERIC(10,2),
  user_id BIGINT,
  user_session UUID
);
COPY data_2023_feb FROM '/tmp/data_2023_feb.csv' WITH (FORMAT csv, HEADER true);
SELECT COUNT(*) AS data_2023_feb_rows FROM data_2023_feb;"
    if docker_psql "$feb_sql"; then
      ok "data_2023_feb creada y cargada desde el CSV adjunto"
      return 0
    fi
    fail "Falló la carga SQL de data_2023_feb"
    return 1
  fi
  return 1
}

check_existing_tables() {
  section "2 · Estado inicial de la BD"
  ctx "Antes de EX01 deben conservarse todas las tablas fuente data_202*, incluida data_2023_feb, e items."
  ctx "Cualquier otra tabla se considera ajena al estado inicial, aunque no se llame customers."
  ctx "Se muestra el DROP exacto y solo se ejecuta tras tu confirmación."
  ctx_blank
  show_cmd "docker exec -it $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME -c '\\dt'"
  local tables
  tables="$(docker_psql "SELECT tablename FROM pg_tables WHERE schemaname='public' ORDER BY 1;" 2>/dev/null || true)"
  if [[ -z "$tables" ]]; then
    fail "No se pudieron listar las tablas"
    RESULT[initial]=no
    return 0
  fi
  echo "$tables" | sed 's/^/      /'

  local extras
  extras="$(printf '%s\n' "$tables" | grep -vE '^data_202[0-9]_.*$|^items$' || true)"
  if [[ -n "$extras" ]]; then
    warn "Hay tablas que no deberían existir al inicio de la evaluación"
    info "Lista blanca permitida: tablas data_202* e items"
    echo "$extras" | sed 's/^/      /'
    if printf '%s\n' "$extras" | grep -qE '^(customers|customers_fused)$'; then
      info "customers/customers_fused son resultados de Module 1, no tablas fuente."
    fi
    echo
    echo -e "  ${YELLOW}${BOLD}Se propone borrar exclusivamente estas tablas inesperadas del esquema public.${RESET}"
    echo -e "  ${YELLOW}No se borrarán ninguna tabla data_202* ni items.${RESET}"
    local drop_unexpected_sql
    drop_unexpected_sql="DO \$\$ DECLARE t record; BEGIN FOR t IN SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename !~ '^data_202[0-9]_.*$' AND tablename <> 'items' LOOP EXECUTE format('DROP TABLE IF EXISTS public.%I', t.tablename); END LOOP; END \$\$;"
    show_cmd "docker exec -it $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME -v ON_ERROR_STOP=1 -c \"$drop_unexpected_sql\""
    note "La ejecución usa format('%I', tablename), que cita cada identificador de forma segura."
    note "Tras aceptar, customers dejará de existir hasta que ejecutes EX01 si estaba entre las tablas listadas."
    if ask_yes_no "¿Eliminar todas las tablas inesperadas listadas para comenzar desde cero?" "n"; then
      if docker_psql "$drop_unexpected_sql" >/dev/null 2>&1; then
        ok "Tablas inesperadas eliminadas"
        tables="$(docker_psql "SELECT tablename FROM pg_tables WHERE schemaname='public' ORDER BY 1;" 2>/dev/null || true)"
        extras="$(printf '%s\n' "$tables" | grep -vE '^data_202[0-9]_.*$|^items$' || true)"
        if [[ -z "$extras" ]]; then
          ok "La base queda en estado inicial: solo data_202* e items"
          RESULT[initial]=yes
        else
          fail "Persisten tablas inesperadas después del borrado"
          echo "$extras" | sed 's/^/      /'
          RESULT[initial]=no
        fi
      else
        fail "No se pudieron eliminar las tablas inesperadas"
        RESULT[initial]=no
      fi
    else
      info "No se eliminó ninguna tabla; se conserva el estado existente"
      note "La evaluación no puede comenzar desde cero mientras permanezcan tablas fuera de la lista blanca."
      RESULT[initial]=no
    fi
  else
    ok "Solo se observan tablas de origen data_202* e items"
    RESULT[initial]=yes
  fi
  local required_source missing_source
  required_source="$(printf '%s\n' \
    data_2022_oct data_2022_nov data_2022_dec data_2023_jan data_2023_feb)"
  missing_source="$(comm -23 \
    <(printf '%s\n' "$required_source" | sort) \
    <(printf '%s\n' "$tables" | sort) || true)"
  if [[ -n "$missing_source" ]]; then
    warn "Faltan tablas fuente obligatorias al inicio"
    echo "$missing_source" | sed 's/^/      /'
    if printf '%s\n' "$missing_source" | grep -qx 'data_2023_feb' \
      && [[ "$(printf '%s\n' "$missing_source" | wc -l)" -eq 1 ]]; then
      if offer_load_february "$missing_source"; then
        tables="$(docker_psql "SELECT tablename FROM pg_tables WHERE schemaname='public' ORDER BY 1;" 2>/dev/null || true)"
        missing_source="$(comm -23 \
          <(printf '%s\n' "$required_source" | sort) \
          <(printf '%s\n' "$tables" | sort) || true)"
      fi
    else
      info "Solo se puede cargar automáticamente febrero porque es el CSV adjunto de este repositorio."
      show_cmd "docker exec -it $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME -c '\\dt data_2023_feb'"
      note "Para los demás meses ausentes, recupera sus CSV mediante Module 0/pgAdmin y vuelve a ejecutar evaluation.sh."
    fi
    if [[ -n "$missing_source" ]]; then
      fail "La carga de tablas fuente no se completó"
      RESULT[initial]=no
    else
      ok "Todas las tablas fuente requeridas están disponibles"
      RESULT[initial]=yes
    fi
  else
    ok "Están presentes las cinco tablas fuente requeridas, incluida data_2023_feb"
  fi
  if [[ "${RESULT[initial]:-}" != "yes" ]]; then
    STOP_EVAL=true
    warn "La evaluación oficial debe detenerse hasta dejar únicamente data_202* e items"
  fi
}

check_ex01() {
  section "3 · EX01 – customers table"
  ctx "La escala exige una tabla customers que reúna todas las data_202*_*** y el resultado exacto esperado es 20,692,840 filas."
  ctx "UNION ALL es correcto: EX02 es quien elimina duplicados."
  ctx "Si customers no existe, ejecuta primero ex01/start.sh; esta sección solo verifica, no crea la tabla."
  ctx_blank
  local source_count customers_count
  show_cmd "SELECT tablename, COUNT(*) FROM public.data_202* GROUP BY tablename ORDER BY tablename;"
  # Cuenta dinámicamente todas las tablas públicas que cumplen data_202%.
  source_count="$(docker_psql "SELECT COALESCE(SUM((xpath('/row/c/text()', query_to_xml(format('SELECT COUNT(*) AS c FROM %I', tablename), false, true, '')))[1]::text::bigint),0) FROM pg_tables WHERE schemaname='public' AND tablename LIKE 'data_202%';" 2>/dev/null || true)"
  show_cmd "SELECT COUNT(*) FROM customers;"
  customers_count="$(docker_psql "SELECT COUNT(*) FROM customers;" 2>/dev/null || true)"
  if [[ "$customers_count" == "20692840" ]]; then
    ok "customers tiene exactamente 20,692,840 filas"
    RESULT[ex01]=yes
  elif [[ "$customers_count" =~ ^[0-9]+$ ]]; then
    fail "customers tiene $customers_count filas; se esperaba 20,692,840"
    RESULT[ex01]=no
  else
    fail "No existe customers o no se pudo consultar"
    RESULT[ex01]=no
  fi
  [[ "$source_count" =~ ^[0-9]+$ ]] && info "Suma dinámica de tablas data_202*: $source_count"
  check_deliverable ex01 customers_table
}

check_ex02() {
  section "4 · EX02 – remove duplicates"
  ctx "Se verifican los dos ejemplos del PDF y el caso que no debe borrarse."
  ctx "Después, COUNT(*) debe quedar entre 18,500,000 y 19,200,000."
  ctx "Si customers aún tiene 20,692,840 filas, ejecuta primero ex02/start.sh; esta sección solo verifica."
  ctx_blank
  local exact echo_gap distinct_case count
  show_cmd "SELECT COUNT(*) FROM customers WHERE event_time='2022-10-01 00:00:30' AND event_type='remove_from_cart' AND product_id=5809103;"
  exact="$(docker_psql "SELECT COUNT(*) FROM customers WHERE event_time='2022-10-01 00:00:30' AND event_type='remove_from_cart' AND product_id=5809103;" 2>/dev/null || true)"
  [[ "$exact" == "1" ]] && ok "Duplicado exacto del PDF reducido a una fila" || fail "Caso exacto: se esperaba 1 fila, resultado $exact"

  show_cmd "SELECT COUNT(*) FROM customers WHERE event_time IN ('2022-10-01 00:00:32','2022-10-01 00:00:33') AND event_type='remove_from_cart' AND product_id=5779403;"
  echo_gap="$(docker_psql "SELECT COUNT(*) FROM customers WHERE event_time IN ('2022-10-01 00:00:32','2022-10-01 00:00:33') AND event_type='remove_from_cart' AND product_id=5779403;" 2>/dev/null || true)"
  [[ "$echo_gap" == "1" ]] && ok "Eco de un segundo del PDF reducido a una fila" || fail "Caso de un segundo: se esperaba 1 fila, resultado $echo_gap"

  show_cmd "SELECT COUNT(*) FROM customers WHERE event_time='2022-10-01 00:04:15' AND event_type='remove_from_cart' AND product_id IN (5692893,5802443);"
  distinct_case="$(docker_psql "SELECT COUNT(*) FROM customers WHERE event_time='2022-10-01 00:04:15' AND event_type='remove_from_cart' AND product_id IN (5692893,5802443);" 2>/dev/null || true)"
  [[ "$distinct_case" == "2" ]] && ok "Dos productos distintos del PDF siguen presentes" || fail "Caso de productos distintos: se esperaban 2 filas, resultado $distinct_case"

  show_cmd "SELECT COUNT(*) FROM customers;"
  count="$(docker_psql 'SELECT COUNT(*) FROM customers;' 2>/dev/null || true)"
  if [[ "$count" =~ ^(185|186|187|188|189|190|191)[0-9]{5}$ ]]; then
    ok "COUNT(*)=$count dentro del rango 18,500,000–19,200,000"
    RESULT[ex02]=yes
  else
    fail "COUNT(*)=$count fuera del rango esperado"
    RESULT[ex02]=no
  fi
  check_deliverable ex02 remove_duplicates
}

check_ex03() {
  section "5 · EX03 – fusion"
  ctx "La escala exige enriquecer customers con items sin perder filas ni información."
  ctx "Se comprueba el producto 5846774 y que el número total de filas no cambie."
  ctx "Si aún no aparecen las columnas de items, ejecuta primero ex03/start.sh; esta sección solo verifica."
  ctx_blank
  local count row
  show_cmd "SELECT product_id, category_id, category_code, brand FROM customers WHERE product_id = 5846774;"
  row="$(docker_psql "SELECT product_id, category_id, category_code, brand FROM customers WHERE product_id = 5846774 LIMIT 1;" 2>/dev/null || true)"
  if [[ "$row" == *"5846774"* && "$row" == *"1487580010695884800"* && "$row" == *"accessories.bag"* && "$row" == *"vosev"* ]]; then
    ok "Producto 5846774 tiene los cuatro valores esperados"
  else
    fail "No se obtuvo la fila esperada para product_id=5846774"
  fi

  show_cmd "SELECT COUNT(*) FROM customers;"
  count="$(docker_psql 'SELECT COUNT(*) FROM customers;' 2>/dev/null || true)"
  if [[ "$count" =~ ^(185|186|187|188|189|190|191)[0-9]{5}$ ]]; then
    ok "COUNT(*)=$count no muestra pérdida de filas"
    RESULT[ex03]=yes
  else
    fail "COUNT(*)=$count fuera del rango esperado tras fusionar"
    RESULT[ex03]=no
  fi
  check_deliverable ex03 fusion
}

check_deliverable() {
  local exercise="$1" stem="$2" found=false f
  for f in "$SCRIPT_DIR/$exercise/$stem.sql" "$SCRIPT_DIR/$exercise/$stem.py"; do
    if [[ -f "$f" ]]; then
      ok "Entregable encontrado: $f"
      found=true
    fi
  done
  [[ "$found" == true ]] || fail "No se encontró $stem.sql ni $stem.py en $exercise/"
}

summary() {
  section "6 · Resumen para Intra"
  printf "  %-16s %s\n" "Repositorio" "${RESULT[layout]:-—}"
  printf "  %-16s %s\n" "CSV adjunto" "${RESULT[attachment]:-—}"
  printf "  %-16s %s\n" "Docker/DB/EX00" "${RESULT[ex00]:-—}"
  printf "  %-16s %s\n" "Estado inicial" "${RESULT[initial]:-—}"
  printf "  %-16s %s\n" "pgAdmin / GUI" "${RESULT[pgadmin]:-—}"
  printf "  %-16s %s\n" "GUI demostrada" "${RESULT[gui]:-—}"
  printf "  %-16s %s\n" "EX01" "${RESULT[ex01]:-—}"
  printf "  %-16s %s\n" "EX02" "${RESULT[ex02]:-—}"
  printf "  %-16s %s\n" "EX03" "${RESULT[ex03]:-—}"
  echo
  echo -e "  ${GREEN}OK=$PASS_COUNT${RESET}  ${RED}Errores=$FAIL_COUNT${RESET}  ${YELLOW}Avisos=$WARN_COUNT${RESET}"
  echo
  if [[ "${RESULT[ex00]:-}" == yes && "${RESULT[ex01]:-}" == yes \
        && "${RESULT[ex02]:-}" == yes && "${RESULT[ex03]:-}" == yes \
        && "${RESULT[gui]:-}" == yes \
        && "$STOP_EVAL" != true && "$FAIL_COUNT" -eq 0 ]]; then
    echo -e "  ${GREEN}${BOLD}✅ RESULTADO FINAL: EVALUACIÓN SUPERADA${RESET}"
  else
    echo -e "  ${RED}${BOLD}❌ RESULTADO FINAL: EVALUACIÓN NO SUPERADA${RESET}"
  fi
  echo -e "  ${DIM}Resultado orientativo: la decisión oficial corresponde a la escala y al evaluador.${RESET}"
  echo
}

main() {
  header
  section "Guías oficiales"
  ctx "evaluation_en.pdf y en.subject.pdf se han usado como fuente de esta guía."
  ctx "Ratings oficiales: Ok, Outstanding project, Empty work, Incomplete work, Cheat, Crash, Concern, Forbidden function."
  pause
  check_subject_and_layout
  pause
  check_docker_and_pgadmin
  if [[ "$STOP_EVAL" == true ]]; then
    summary
    exit 0
  fi
  pause
  confirm_gui_connection
  if [[ "$STOP_EVAL" == true ]]; then
    summary
    exit 0
  fi
  pause
  check_existing_tables
  if [[ "$STOP_EVAL" == true ]]; then
    summary
    exit 0
  fi
  pause
  run_confirmed_pipeline
  if [[ "$PIPELINE_VERIFIED" != true ]]; then
    check_ex01
    pause
    check_ex02
    pause
    check_ex03
  fi
  summary
}

main "$@"
