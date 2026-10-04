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
LAST_RESULT_KIND="info"
LAST_RESULT_TEXT="Evaluación iniciada"

CONTAINER_NAME="${DS_CONTAINER_NAME:-postgres_piscineds}"
DB_NAME="${POSTGRES_DB:-piscineds}"
DB_USER="${POSTGRES_USER:-$(id -un 2>/dev/null || whoami)}"

header() {
  clear 2>/dev/null || true
  echo -e "${BOLD}${BLUE}"
  echo "╔══════════════════════════════════════════════════════════════════╗"
  echo "║  DATA SCIENCE 1 – Data Warehouse · DEFENSA / EVALUATION          ║"
  echo "║  Escala: /PROJECTS/DATA-SCIENCE-1                               ║"
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

redraw_after_continue() { header; show_last_result; }

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
    show_cmd "wc -l \"$SCRIPT_DIR/data_2023_feb.csv\""
    wc -l "$SCRIPT_DIR/data_2023_feb.csv" 2>/dev/null | sed 's/^/      /'
  else
    warn "No está data_2023_feb.csv en el clon; descárgalo desde Attachments de la evaluación"
    note "Después, cárgalo como tabla data_2023_feb antes de EX01"
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
  ctx "pgAdmin no es obligatorio por nombre: también valen Postico, DBeaver u otra GUI que permita buscar por ID."
  ctx_blank

  subsection "Contenedor PostgreSQL"
  if ! command -v docker >/dev/null 2>&1; then
    fail "docker no está disponible"
    RESULT[ex00]=no
    STOP_EVAL=true
    return 0
  fi
  show_cmd "docker ps -a --filter name=^/${CONTAINER_NAME}$ --format 'table {{.Names}}\\t{{.Status}}\\t{{.Ports}}'"
  if docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
    ok "$CONTAINER_NAME está ejecutándose"
  else
    fail "$CONTAINER_NAME no está ejecutándose"
    note "Levántalo desde Module 0: cd \"$MODULE0_DIR/ex00\" && docker compose up -d"
    RESULT[ex00]=no
    STOP_EVAL=true
    return 0
  fi

  subsection "Consulta de conexión"
  show_cmd "docker exec -it $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME -c '\\conninfo'"
  if docker_psql '\conninfo' >/tmp/ds1_conninfo.$$ 2>/dev/null; then
    ok "Conexión a $DB_NAME operativa"
    sed 's/^/      /' /tmp/ds1_conninfo.$$ 
  else
    fail "No se pudo conectar a $DB_NAME"
    STOP_EVAL=true
  fi
  rm -f /tmp/ds1_conninfo.$$

  subsection "pgAdmin / GUI"
  show_cmd "curl -s -o /dev/null -w '%{http_code}\\n' http://localhost:5050"
  if command -v curl >/dev/null 2>&1 && curl -s -o /dev/null -w '%{http_code}' --connect-timeout 2 http://localhost:5050 2>/dev/null | grep -qE '200|301|302|401|403'; then
    ok "pgAdmin responde en http://localhost:5050"
    RESULT[pgadmin]=yes
  else
    warn "pgAdmin no responde en http://localhost:5050"
    note "Para EX00 puedes usar cualquier GUI permitida; si usas pgAdmin, arráncalo con el start.sh de Module 0 EX01."
    if [[ -n "$MODULE0_DIR" && -x "$MODULE0_DIR/ex01/start.sh" ]] && ask_yes_no "¿Abrir el asistente de Module 0 para arrancar pgAdmin?" "n"; then
      show_cmd "cd \"$MODULE0_DIR/ex01\" && ./start.sh"
      (cd "$MODULE0_DIR/ex01" && ./start.sh)
    fi
    RESULT[pgadmin]=no
  fi
  if [[ "$STOP_EVAL" == true ]]; then
    RESULT[ex00]=no
  else
    RESULT[ex00]=yes
  fi
}

confirm_gui_connection() {
  section "1b · Demostración real de la conexión GUI"
  ctx "La escala de EX00 no evalúa solo que pgAdmin responda por HTTP: hay que mostrar una GUI conectada a la base de datos."
  ctx "pgAdmin, Postico, DBeaver u otra herramienta equivalente son válidas si permiten buscar por ID."
  ctx_blank
  show_cmd "docker exec -it $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME -c '\\conninfo'"
  info "Abre la GUI y muestra la conexión a localhost:5432 / $DB_NAME / usuario $DB_USER."
  info "Después navega a public → Tables y realiza una búsqueda por user_id o product_id."
  if [[ "${RESULT[pgadmin]:-}" == "yes" ]]; then
    show_cmd "xdg-open http://localhost:5050"
    note "Con pgAdmin: abre http://localhost:5050 y muestra el servidor registrado y una consulta por ID."
  else
    note "Si usas pgAdmin: abre http://localhost:5050; también puedes usar Postico, DBeaver u otra GUI permitida."
  fi
  if ask_yes_no "¿Se ha mostrado una GUI conectada y se ha podido buscar por ID?" "n"; then
    ok "Conexión GUI demostrada en vivo"
    RESULT[gui]=yes
  else
    fail "No se ha demostrado la conexión GUI exigida por EX00"
    RESULT[gui]=no
    STOP_EVAL=true
  fi
}

check_existing_tables() {
  section "2 · Estado inicial de la BD"
  ctx "EX00 exige que solo estén las tablas data_202*_*** e items. customers es un resultado posterior y debe revisarse antes de empezar."
  ctx "Se muestran las consultas; no se eliminan tablas automáticamente."
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
    warn "Hay tablas adicionales al estado inicial permitido"
    echo "$extras" | sed 's/^/      /'
    if printf '%s\n' "$extras" | grep -qE '^(customers|customers_fused)$'; then
      echo
      echo -e "  ${YELLOW}${BOLD}customers/customers_fused son resultados de Module 1, no tablas fuente.${RESET}"
      show_cmd "docker exec -it $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME -c \"DROP TABLE IF EXISTS customers_fused, customers;\""
      echo -e "  ${YELLOW}El DROP solo afecta a resultados derivados; no borra data_202* ni items.${RESET}"
      if ask_yes_no "¿Eliminar esos resultados para comenzar EX01 desde cero?" "n"; then
        if docker_psql "DROP TABLE IF EXISTS customers_fused, customers;" >/dev/null 2>&1; then
          ok "Resultados derivados eliminados"
          extras="$(printf '%s\n' "$extras" | grep -vE '^customers$|^customers_fused$' || true)"
        else
          fail "No se pudieron eliminar los resultados derivados"
        fi
      else
        info "No se eliminó ninguna tabla; se conserva el estado existente"
      fi
    fi
    if [[ -n "$extras" ]]; then
      note "Las tablas restantes deben revisarse según la escala antes de continuar."
      RESULT[initial]=no
    else
      ok "No quedan tablas derivadas adicionales"
      RESULT[initial]=yes
    fi
  else
    ok "Solo se observan tablas de origen data_202* e items"
    RESULT[initial]=yes
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
  check_ex01
  pause
  check_ex02
  pause
  check_ex03
  summary
}

main "$@"
