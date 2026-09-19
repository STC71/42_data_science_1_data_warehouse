#!/usr/bin/env bash

# ============================================================
# PISCINE PEDAGO - DATA SCIENCE
# Data Science 1 - Data Warehouse — ASISTENTE GLOBAL (raíz)
#
# INDEPENDIENTE de ex00…ex03/start.sh
#   • Estado, PostgreSQL (Module 0), pgAdmin, pipeline EX01–EX03
#   • Preparar repo_<login> para evaluación (lista blanca)
#   • Git asistido (push solo con confirmación explícita)
#
# Uso:
#   ./start.sh
#   /ruta/a/data_science_1_data_warehouse/start.sh
# ============================================================

set -u

RESET='\033[0m'
BOLD='\033[1m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
EX00_DIR="$PROJECT_DIR/ex00"
EX01_DIR="$PROJECT_DIR/ex01"
EX02_DIR="$PROJECT_DIR/ex02"
EX03_DIR="$PROJECT_DIR/ex03"
CONTAINER_NAME="postgres_piscineds"
EVAL_DIR_LAST=""

print_header()
{
    clear
    echo
    echo -e "${CYAN}${BOLD}╔════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}${BOLD}║  PISCINE PEDAGO - DATA SCIENCE - sternero - 42 Málaga      ║${RESET}"
    echo -e "${CYAN}${BOLD}║  Data Science 1 – Data Warehouse – Asistente GLOBAL        ║${RESET}"
    echo -e "${CYAN}${BOLD}╚════════════════════════════════════════════════════════════╝${RESET}"
    echo
    echo -e "${WHITE}  Script:   ${SCRIPT_DIR}/start.sh${RESET}"
    echo -e "${WHITE}  Proyecto: ${PROJECT_DIR}${RESET}"
    echo
}

ask_yes_no()
{
    local prompt="$1" default="$2" answer
    if [ "$default" = "s" ]; then
        read -r -p "$(echo -e "${YELLOW}${prompt} [S/n] → ${RESET}")" answer
        answer=${answer:-s}
    else
        read -r -p "$(echo -e "${YELLOW}${prompt} [s/N] → ${RESET}")" answer
        answer=${answer:-n}
    fi
    [[ "$answer" =~ ^[sS]$ ]]
}

pause() { echo; read -r -p "$(echo -e "${CYAN}Pulsa Enter...${RESET}")"; }
section()
{
    echo
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BOLD}$1${RESET}"
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo
}
ok()   { echo -e "${GREEN}✓ $1${RESET}"; }
warn() { echo -e "${YELLOW}⚠ $1${RESET}"; }
err()  { echo -e "${RED}✗ $1${RESET}"; }
info() { echo -e "${CYAN}→ $1${RESET}"; }

# ------------------------------------------------------------
# Module 0
# ------------------------------------------------------------
find_module0()
{
    local c
    for c in \
        "$PROJECT_DIR/../data_science_0_creation_db" \
        "$PROJECT_DIR/../../data_science_0_creation_db" \
        "$HOME/sgoinfre/42_outer_core/piscine_pedago_data_science/data_science_0_creation_db" \
        "$HOME/sgoinfre/students/$(id -un)/42_outer_core/piscine_pedago_data_science/data_science_0_creation_db"
    do
        if [[ -f "$c/ex00/docker-compose.yml" ]] || [[ -f "$c/ex00/.env" ]]; then
            echo "$(cd -- "$c" && pwd)"
            return 0
        fi
    done
    return 1
}

MODULE0_DIR="$(find_module0 || true)"
ENV_FILE=""
[[ -n "$MODULE0_DIR" && -f "$MODULE0_DIR/ex00/.env" ]] && ENV_FILE="$MODULE0_DIR/ex00/.env"

read_env()
{
    POSTGRES_USER=""
    POSTGRES_PASSWORD=""
    POSTGRES_DB=""
    [[ -n "$ENV_FILE" && -f "$ENV_FILE" ]] || return 1
    POSTGRES_USER="$(sed -n 's/^POSTGRES_USER=//p' "$ENV_FILE" | head -n 1)"
    POSTGRES_PASSWORD="$(sed -n 's/^POSTGRES_PASSWORD=//p' "$ENV_FILE" | head -n 1)"
    POSTGRES_DB="$(sed -n 's/^POSTGRES_DB=//p' "$ENV_FILE" | head -n 1)"
    [[ -n "$POSTGRES_USER" && -n "$POSTGRES_DB" ]]
}

db_user()
{
    if read_env; then echo "$POSTGRES_USER"; else id -un 2>/dev/null || whoami; fi
}

db_name()
{
    if read_env; then echo "$POSTGRES_DB"; else echo "piscineds"; fi
}

psql_c()
{
    docker exec -i "$CONTAINER_NAME" \
        psql -U "$(db_user)" -d "$(db_name)" -c "$1"
}

# ------------------------------------------------------------
# Permisos +x
# ------------------------------------------------------------
collect_exec_candidates()
{
    local base="${1:-$PROJECT_DIR}"
    local f
    [[ -f "$base/start.sh" ]] && echo "$base/start.sh"
    for f in \
        "$base"/ex00/start.sh \
        "$base"/ex01/start.sh \
        "$base"/ex02/start.sh \
        "$base"/ex03/start.sh \
        "$base"/ex01/customers_table.py \
        "$base"/ex02/remove_duplicates.py \
        "$base"/ex03/fusion.py
    do
        [[ -f "$f" ]] && echo "$f"
    done
}

fix_executable_permissions()
{
    section "🔑  Permisos de ejecución (+x)"
    local root="${1:-$PROJECT_DIR}"
    local -a files=()
    local line
    while IFS= read -r line; do
        [[ -n "$line" ]] && files+=("$line")
    done < <(collect_exec_candidates "$root")

    if [[ ${#files[@]} -eq 0 ]]; then
        warn "No hay candidatos en $root"
        return 0
    fi
    echo -e "${BOLD}Candidatos:${RESET}"
    local f
    for f in "${files[@]}"; do
        if [[ -x "$f" ]]; then
            echo -e "  ${GREEN}[ya +x]${RESET} $f"
        else
            echo -e "  ${YELLOW}[sin +x]${RESET} $f"
        fi
    done
    echo
    if ! ask_yes_no "¿Aplicar chmod +x?" "s"; then
        warn "Sin cambios"
        return 0
    fi
    for f in "${files[@]}"; do
        chmod +x "$f" 2>/dev/null && ok "chmod +x → $f" || err "Falló: $f"
    done
}

# ------------------------------------------------------------
# Docker / PostgreSQL
# ------------------------------------------------------------
ensure_docker()
{
    if ! command -v docker >/dev/null 2>&1; then
        err "Docker no está en el PATH"
        return 1
    fi
    if ! docker info >/dev/null 2>&1; then
        err "Docker no responde (demonio o permisos)"
        return 1
    fi
    ok "Docker operativo"
}

start_postgres()
{
    section "🐘  Levantar PostgreSQL (Module 0)"
    if [[ -z "$MODULE0_DIR" || ! -f "$MODULE0_DIR/ex00/docker-compose.yml" ]]; then
        err "No se encontró data_science_0_creation_db/ex00/docker-compose.yml"
        return 1
    fi
    ensure_docker || return 1
    if docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
        ok "Contenedor ya Up"
        docker ps --filter "name=^/${CONTAINER_NAME}$" --format "  {{.Status}} | {{.Ports}}"
        return 0
    fi
    if docker ps -a --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
        if ask_yes_no "¿docker start $CONTAINER_NAME?" "s"; then
            docker start "$CONTAINER_NAME" && sleep 2
            ok "Arrancado"
            return 0
        fi
        return 1
    fi
    if ! ask_yes_no "¿docker-compose up -d en Module 0 ex00?" "s"; then
        warn "Omitido"
        return 1
    fi
    if command -v docker-compose >/dev/null 2>&1; then
        ( cd "$MODULE0_DIR/ex00" && docker-compose up -d )
    else
        ( cd "$MODULE0_DIR/ex00" && docker compose up -d )
    fi
    sleep 2
    if docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
        ok "PostgreSQL arriba (localhost:5432)"
    else
        err "Contenedor no visible"
        return 1
    fi
}

# ------------------------------------------------------------
# pgAdmin (mismo enfoque que Module 0 / cluster 42)
# ------------------------------------------------------------
check_pgadmin()
{
    if ! command -v curl >/dev/null 2>&1; then
        return 1
    fi
    curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 \
        "http://127.0.0.1:5050" 2>/dev/null | grep -qE '200|301|302|401|403'
}

start_pgadmin()
{
    section "🖥️  pgAdmin"
    echo -e "Útil para EX00 (GUI) y para inspeccionar ${BOLD}customers${RESET} tras EX01–EX03."
    echo -e "URL típica: ${WHITE}http://127.0.0.1:5050${RESET}"
    echo

    if check_pgadmin; then
        ok "pgAdmin ya responde en http://127.0.0.1:5050"
        return 0
    fi

    local venv=""
    for venv in \
        "/sgoinfre/students/$(id -un)/pgadmin4/venv" \
        "$HOME/sgoinfre/pgadmin4/venv" \
        "$HOME/goinfre/pgadmin4/venv" \
        "$HOME/sgoinfre/students/$(id -un)/pgadmin4/venv"
    do
        [[ -x "$venv/bin/pgadmin4" ]] && break
        venv=""
    done

    if [[ -z "$venv" ]]; then
        err "No se encontró el venv de pgAdmin (rutas habituales del campus)"
        info "Instálalo como en Module 0 EX01 o arráncalo a mano."
        return 1
    fi

    local pgadmin_dir cfg data_dir
    pgadmin_dir="$(dirname "$venv")"
    cfg="$pgadmin_dir/config"
    data_dir="$pgadmin_dir/data"
    mkdir -p "$cfg" "$data_dir" || return 1
    if [[ ! -f "$cfg/config_local.py" ]]; then
        {
            printf "DATA_DIR = '%s'\n" "$data_dir"
            printf "SQLITE_PATH = '%s/pgadmin4.db'\n" "$data_dir"
            printf "SESSION_DB_PATH = '%s/sessions'\n" "$data_dir"
            printf "STORAGE_DIR = '%s/storage'\n" "$data_dir"
            printf "LOG_FILE = '%s/pgadmin4.log'\n" "$data_dir"
        } > "$cfg/config_local.py"
        ok "Creado $cfg/config_local.py"
    fi

    if ! ask_yes_no "¿Arrancar pgAdmin en segundo plano?" "s"; then
        warn "Omitido"
        return 0
    fi

    info "Iniciando pgAdmin…"
    (
        # shellcheck disable=SC1091
        source "$venv/bin/activate"
        export PYTHONPATH="$cfg${PYTHONPATH:+:$PYTHONPATH}"
        nohup pgadmin4 >/tmp/pgadmin4_m1.log 2>&1 &
        echo $! >/tmp/pgadmin4_m1.pid
    )
    local attempt
    for attempt in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
        sleep 1
        if check_pgadmin; then
            ok "pgAdmin → http://127.0.0.1:5050"
            info "Conexión: Host localhost · Port 5432 · DB piscineds · User=$(db_user)"
            return 0
        fi
    done
    warn "pgAdmin no responde aún; revisa /tmp/pgadmin4_m1.log"
    return 1
}

start_full_environment()
{
    section "🚀  Entorno completo (PostgreSQL + pgAdmin)"
    start_postgres || true
    start_pgadmin || true
}

status_environment()
{
    section "📊  Estado del entorno (Module 1)"
    echo -e "${BOLD}Module 0${RESET}"
    if [[ -n "$MODULE0_DIR" ]]; then
        ok "$MODULE0_DIR"
    else
        warn "No localizado"
    fi
    echo
    echo -e "${BOLD}.env${RESET}"
    if read_env; then
        ok "USER=$POSTGRES_USER DB=$POSTGRES_DB"
    else
        warn "Sin .env legible"
    fi
    echo
    echo -e "${BOLD}Docker / contenedor${RESET}"
    ensure_docker || true
    if docker ps --format '{{.Names}}' 2>/dev/null | grep -qx "$CONTAINER_NAME"; then
        ok "Up"
        docker ps --filter "name=^/${CONTAINER_NAME}$" --format "  {{.Status}} | {{.Ports}}" 2>/dev/null || true
    else
        warn "postgres_piscineds no está corriendo"
    fi
    echo
    echo -e "${BOLD}pgAdmin${RESET}"
    if check_pgadmin; then
        ok "Responde en http://127.0.0.1:5050"
    else
        warn "No responde (opción g o 2 del menú)"
    fi
    echo
    echo -e "${BOLD}Tablas clave${RESET}"
    if docker ps --format '{{.Names}}' 2>/dev/null | grep -qx "$CONTAINER_NAME"; then
        psql_c "SELECT tablename FROM pg_tables WHERE schemaname='public' AND (tablename LIKE 'data_202%' OR tablename IN ('customers','items')) ORDER BY 1;" 2>/dev/null \
            || warn "No se pudo listar tablas"
        echo
        psql_c "SELECT COUNT(*) AS customers_rows FROM customers;" 2>/dev/null \
            || info "Tabla customers aún no existe (EX01)"
    else
        info "Sin SQL (contenedor parado)"
    fi
}

# ------------------------------------------------------------
# Pipeline EX01–EX03
# ------------------------------------------------------------
run_ex01()
{
    section "📦  EX01 – customers_table"
    local py="$EX01_DIR/customers_table.py"
    local sql="$EX01_DIR/customers_table.sql"
    if [[ ! -f "$py" && ! -f "$sql" ]]; then
        err "Faltan customers_table.* en ex01/"
        return 1
    fi
    if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
        err "Contenedor parado — opción 2"
        return 1
    fi
    echo -e "  ${BOLD}1)${RESET} Python  ${BOLD}2)${RESET} SQL"
    local c
    read -r -p "$(echo -e "${YELLOW}Elige [1/2] → ${RESET}")" c
    case "$c" in
        1)
            [[ -f "$py" ]] || { err "No hay $py"; return 1; }
            chmod +x "$py" 2>/dev/null || true
            ( cd "$EX01_DIR" && python3 "$py" )
            ;;
        2)
            [[ -f "$sql" ]] || { err "No hay $sql"; return 1; }
            docker cp "$sql" "$CONTAINER_NAME:/tmp/customers_table.sql"
            docker exec -i "$CONTAINER_NAME" \
                psql -U "$(db_user)" -d "$(db_name)" -f /tmp/customers_table.sql
            ;;
        *) warn "Cancelado" ;;
    esac
}

run_ex02()
{
    section "🧹  EX02 – remove_duplicates"
    local py="$EX02_DIR/remove_duplicates.py"
    local sql="$EX02_DIR/remove_duplicates.sql"
    if [[ ! -f "$py" && ! -f "$sql" ]]; then
        err "Faltan remove_duplicates.*"
        return 1
    fi
    if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
        err "Contenedor parado"
        return 1
    fi
    warn "Puede tardar varios minutos"
    echo -e "  ${BOLD}1)${RESET} Python  ${BOLD}2)${RESET} SQL"
    local c
    read -r -p "$(echo -e "${YELLOW}Elige [1/2] → ${RESET}")" c
    case "$c" in
        1)
            [[ -f "$py" ]] || { err "No hay $py"; return 1; }
            chmod +x "$py" 2>/dev/null || true
            ( cd "$EX02_DIR" && python3 "$py" )
            ;;
        2)
            [[ -f "$sql" ]] || { err "No hay $sql"; return 1; }
            if ! ask_yes_no "¿Aplicar SQL?" "s"; then return 0; fi
            docker cp "$sql" "$CONTAINER_NAME:/tmp/remove_duplicates.sql"
            docker exec -i "$CONTAINER_NAME" \
                psql -U "$(db_user)" -d "$(db_name)" -f /tmp/remove_duplicates.sql
            ;;
        *) warn "Cancelado" ;;
    esac
}

run_ex03()
{
    section "🔗  EX03 – fusion"
    local py="$EX03_DIR/fusion.py"
    local sql="$EX03_DIR/fusion.sql"
    if [[ ! -f "$py" && ! -f "$sql" ]]; then
        err "Faltan fusion.*"
        return 1
    fi
    if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
        err "Contenedor parado"
        return 1
    fi
    warn "LEFT JOIN; puede tardar varios minutos"
    echo -e "  ${BOLD}1)${RESET} Python  ${BOLD}2)${RESET} SQL"
    local c
    read -r -p "$(echo -e "${YELLOW}Elige [1/2] → ${RESET}")" c
    case "$c" in
        1)
            [[ -f "$py" ]] || { err "No hay $py"; return 1; }
            chmod +x "$py" 2>/dev/null || true
            ( cd "$EX03_DIR" && python3 "$py" )
            ;;
        2)
            [[ -f "$sql" ]] || { err "No hay $sql"; return 1; }
            if ! ask_yes_no "¿Aplicar SQL?" "s"; then return 0; fi
            docker cp "$sql" "$CONTAINER_NAME:/tmp/fusion.sql"
            docker exec -i "$CONTAINER_NAME" \
                psql -U "$(db_user)" -d "$(db_name)" -f /tmp/fusion.sql
            ;;
        *) warn "Cancelado" ;;
    esac
}

count_customers()
{
    section "🔢  COUNT(*) / \\d customers"
    if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
        err "Sin contenedor"
        return 1
    fi
    psql_c "SELECT COUNT(*) AS customers_rows FROM customers;" 2>/dev/null \
        || warn "¿Existe customers?"
    docker exec -i "$CONTAINER_NAME" \
        psql -U "$(db_user)" -d "$(db_name)" -c '\d customers' 2>/dev/null || true
}

open_psql()
{
    section "💻  psql"
    docker exec -it "$CONTAINER_NAME" \
        psql -U "$(db_user)" -d "$(db_name)"
}

check_delivery_files()
{
    section "📋  Archivos de entrega (subject)"
    local ok_all=1
    local pair
    for pair in \
        "ex01:customers_table" \
        "ex02:remove_duplicates" \
        "ex03:fusion"
    do
        local dir="${pair%%:*}"
        local base="${pair##*:}"
        if [[ -f "$PROJECT_DIR/$dir/${base}.py" || -f "$PROJECT_DIR/$dir/${base}.sql" ]]; then
            ok "$dir/${base}.*"
        else
            err "Falta $dir/${base}.*"
            ok_all=0
        fi
    done
    [[ -d "$EX00_DIR" ]] && ok "ex00/ (GUI en defensa)" || warn "ex00/ no presente"
    echo
    [[ "$ok_all" -eq 1 ]] && ok "Entregables mínimos localizados" || warn "Revisa nombres del PDF"
}

optional_ex_start()
{
    local dir="$1" label="$2"
    local s="$dir/start.sh"
    section "▶  $label (atajo opcional)"
    if [[ ! -f "$s" ]]; then
        info "No hay $s"
        return 0
    fi
    if ask_yes_no "¿Abrir $s?" "n"; then
        chmod +x "$s" 2>/dev/null || true
        ( cd "$dir" && "$s" )
    fi
}

eval_reminder()
{
    section "🎓  Recordatorio de defensa"
    echo "  • Solo cuenta lo del Git del evaluado."
    echo "  • Nombres: customers_table.*, remove_duplicates.*, fusion.*"
    echo "  • Demostrar en la máquina del grupo evaluado."
    echo "  • Orden: GUI → customers → dedup → fusion (LEFT JOIN)."
    echo "  • Module 0: data_202*, items, contenedor Up."
    echo
}

# ------------------------------------------------------------
# Preparar carpeta de evaluación (lista blanca, estilo Module 0)
# ------------------------------------------------------------
copy_if()
{
    local src="$1" dest="$2"
    if [[ -f "$src" ]]; then
        mkdir -p "$(dirname "$dest")"
        cp -a "$src" "$dest"
        ok "copiado $(basename "$src")"
    fi
}

prepare_eval_folder()
{
    section "📁  Preparar repo_<login> (evaluación)"

    echo -e "Copia ${BOLD}solo entregables${RESET} a una carpeta limpia para clonar/pushear."
    echo -e "No se copian: .env, CSV pesados, venv, logs, cachés."
    echo

    local login dest_name dest_path parent
    login="$(id -un 2>/dev/null || whoami)"
    dest_name="repo_${login}"
    read -r -p "$(echo -e "${YELLOW}Nombre de carpeta [${dest_name}] → ${RESET}")" dest_name
    dest_name="${dest_name:-repo_${login}}"

    parent="$(dirname "$PROJECT_DIR")"
    dest_path="$parent/$dest_name"
    echo -e "Destino propuesto: ${BOLD}$dest_path${RESET}"
    if ! ask_yes_no "¿Crear/actualizar esta carpeta?" "s"; then
        warn "Cancelado"
        return 0
    fi

    mkdir -p "$dest_path/ex00" "$dest_path/ex01" "$dest_path/ex02" "$dest_path/ex03"

    # EX00: README (+ start.sh opcional de ayuda; sin secretos)
    copy_if "$EX00_DIR/README.md" "$dest_path/ex00/README.md"
    copy_if "$EX00_DIR/start.sh" "$dest_path/ex00/start.sh"

    # EX01
    for f in "$EX01_DIR"/customers_table.*; do
        [[ -f "$f" ]] || continue
        copy_if "$f" "$dest_path/ex01/$(basename "$f")"
    done
    copy_if "$EX01_DIR/README.md" "$dest_path/ex01/README.md"
    copy_if "$EX01_DIR/sql.md" "$dest_path/ex01/sql.md"
    copy_if "$EX01_DIR/python.md" "$dest_path/ex01/python.md"
    copy_if "$EX01_DIR/start.sh" "$dest_path/ex01/start.sh"

    # EX02
    for f in "$EX02_DIR"/remove_duplicates.*; do
        [[ -f "$f" ]] || continue
        copy_if "$f" "$dest_path/ex02/$(basename "$f")"
    done
    copy_if "$EX02_DIR/README.md" "$dest_path/ex02/README.md"
    copy_if "$EX02_DIR/sql.md" "$dest_path/ex02/sql.md"
    copy_if "$EX02_DIR/python.md" "$dest_path/ex02/python.md"
    copy_if "$EX02_DIR/start.sh" "$dest_path/ex02/start.sh"

    # EX03
    for f in "$EX03_DIR"/fusion.*; do
        [[ -f "$f" ]] || continue
        copy_if "$f" "$dest_path/ex03/$(basename "$f")"
    done
    copy_if "$EX03_DIR/README.md" "$dest_path/ex03/README.md"
    copy_if "$EX03_DIR/sql.md" "$dest_path/ex03/sql.md"
    copy_if "$EX03_DIR/python.md" "$dest_path/ex03/python.md"
    copy_if "$EX03_DIR/start.sh" "$dest_path/ex03/start.sh"

    # Raíz
    copy_if "$PROJECT_DIR/README.md" "$dest_path/README.md"
    copy_if "$PROJECT_DIR/start.sh" "$dest_path/start.sh"
    copy_if "$PROJECT_DIR/.gitignore" "$dest_path/.gitignore"

    if [[ ! -f "$dest_path/.gitignore" ]]; then
        cat > "$dest_path/.gitignore" << 'GI'
.env
*.env
__pycache__/
*.pyc
.venv/
venv/
*.log
.DS_Store
GI
        ok ".gitignore creado"
    fi

    # Imágenes opcionales (banners / capturas de README)
    if [[ -d "$PROJECT_DIR/imgs" ]]; then
        if ask_yes_no "¿Copiar carpeta imgs/ (banners README)?" "s"; then
            mkdir -p "$dest_path/imgs"
            cp -a "$PROJECT_DIR/imgs/." "$dest_path/imgs/" 2>/dev/null && ok "imgs/" || warn "imgs parcial"
        fi
    fi
    for d in ex00 ex01 ex02 ex03; do
        if [[ -d "$PROJECT_DIR/$d/imgs" ]]; then
            if ask_yes_no "¿Copiar $d/imgs?" "n"; then
                mkdir -p "$dest_path/$d/imgs"
                cp -a "$PROJECT_DIR/$d/imgs/." "$dest_path/$d/imgs/" 2>/dev/null || true
            fi
        fi
    done

    echo
    if ask_yes_no "¿chmod +x scripts en $dest_path?" "s"; then
        fix_executable_permissions "$dest_path"
    fi

    EVAL_DIR_LAST="$dest_path"
    ok "Listo: $dest_path"
    echo "  Siguiente: opción 0 (Git asistido) o git init/add/commit/push a mano."
    echo "  No se ha hecho push automático."
    echo
}

# ------------------------------------------------------------
# Git asistido (push default N)
# ------------------------------------------------------------
git_assisted()
{
    section "🔧  Git asistido"

    local target="${EVAL_DIR_LAST:-$PROJECT_DIR}"
    echo -e "Directorio: ${BOLD}$target${RESET}"
    if ! ask_yes_no "¿Usar esta ruta?" "s"; then
        read -r -p "$(echo -e "${YELLOW}Ruta → ${RESET}")" target
    fi
    [[ -d "$target" ]] || { err "No existe"; return 1; }

    (
        cd "$target" || exit 1
        echo "1) status  2) init  3) add  4) commit  5) remote  6) push (default N)  7) update-index +x  b) volver"
        local gopt
        read -r -p "$(echo -e "${YELLOW}→ ${RESET}")" gopt
        case "$gopt" in
            1) git status 2>&1 || true ;;
            2)
                if [[ -d .git ]]; then
                    warn "Ya hay .git"
                else
                    ask_yes_no "¿git init?" "s" && git init
                fi
                ;;
            3)
                if ask_yes_no "¿git add README.md .gitignore start.sh ex00 ex01 ex02 ex03?" "s"; then
                    git add README.md .gitignore start.sh 2>/dev/null || true
                    git add ex00 ex01 ex02 ex03 2>/dev/null || true
                    [[ -d imgs ]] && git add imgs 2>/dev/null || true
                    git status
                fi
                ;;
            4)
                local msg
                read -r -p "$(echo -e "${YELLOW}Mensaje → ${RESET}")" msg
                msg="${msg:-Module 1 Data Warehouse delivery}"
                ask_yes_no "¿commit?" "s" && git commit -m "$msg" 2>&1 || true
                ;;
            5)
                git remote -v 2>/dev/null || true
                if ask_yes_no "¿add origin?" "n"; then
                    local url
                    read -r -p "$(echo -e "${YELLOW}URL origin → ${RESET}")" url
                    [[ -n "$url" ]] && git remote add origin "$url" 2>&1 || true
                fi
                ;;
            6)
                warn "Push solo si lo autorizas explícitamente"
                if ask_yes_no "¿git push -u origin HEAD (o master/main)?" "n"; then
                    git push -u origin HEAD 2>&1 || git push -u origin master 2>&1 || git push -u origin main 2>&1 || true
                else
                    info "Push omitido"
                fi
                ;;
            7)
                local rel
                for rel in start.sh \
                    ex00/start.sh ex01/start.sh ex02/start.sh ex03/start.sh \
                    ex01/customers_table.py ex02/remove_duplicates.py ex03/fusion.py
                do
                    [[ -f "$rel" ]] || continue
                    if git ls-files --error-unmatch "$rel" >/dev/null 2>&1; then
                        if ask_yes_no "¿update-index --chmod=+x $rel?" "s"; then
                            git update-index --chmod=+x "$rel" && ok "+x índice $rel"
                        fi
                    else
                        info "Sin trackear: $rel (haz add antes)"
                    fi
                done
                ;;
            b|B) ;;
            *) warn "Opción no válida" ;;
        esac
    )
    echo
}

# ------------------------------------------------------------
# Menú
# ------------------------------------------------------------
show_menu()
{
    echo
    echo -e "${CYAN}${BOLD}  MENÚ GLOBAL – Module 1 (Data Warehouse)${RESET}"
    echo
    echo -e "  ${BOLD}${WHITE}— Entorno —${RESET}"
    echo -e "  ${BOLD}1)${RESET}  Estado (Module 0 / Docker / pgAdmin / tablas)"
    echo -e "  ${BOLD}2)${RESET}  Levantar PostgreSQL + pgAdmin"
    echo -e "  ${BOLD}g)${RESET}  Solo pgAdmin"
    echo -e "  ${BOLD}p)${RESET}  Permisos +x"
    echo
    echo -e "  ${BOLD}${WHITE}— Pipeline —${RESET}"
    echo -e "  ${BOLD}3)${RESET}  EX01 – customers_table"
    echo -e "  ${BOLD}4)${RESET}  EX02 – remove_duplicates"
    echo -e "  ${BOLD}5)${RESET}  EX03 – fusion"
    echo -e "  ${BOLD}6)${RESET}  COUNT / \\d customers"
    echo -e "  ${BOLD}7)${RESET}  Abrir psql"
    echo -e "  ${BOLD}8)${RESET}  Verificar entregables"
    echo
    echo -e "  ${BOLD}${WHITE}— Evaluación —${RESET}"
    echo -e "  ${BOLD}e)${RESET}  Preparar repo_<login> (lista blanca + chmod)"
    echo -e "  ${BOLD}0)${RESET}  Git asistido (push default N; update-index +x)"
    echo -e "  ${BOLD}9)${RESET}  Recordatorio de defensa"
    echo
    echo -e "  ${BOLD}${WHITE}— Atajos opcionales —${RESET}"
    echo -e "  ${BOLD}a)${RESET} ex00  ${BOLD}b)${RESET} ex01  ${BOLD}c)${RESET} ex02  ${BOLD}d)${RESET} ex03"
    echo
    echo -e "  ${RED}${BOLD}q)${RESET}  ${RED}Salir${RESET}"
    echo
}

menu_loop()
{
    local choice
    while true; do
        show_menu
        read -r -p "$(echo -e "${YELLOW}Opción → ${RESET}")" choice
        echo
        case "$choice" in
            1) status_environment; pause ;;
            2) start_full_environment; pause ;;
            g|G) start_pgadmin; pause ;;
            p|P) fix_executable_permissions "$PROJECT_DIR"; pause ;;
            3) run_ex01; pause ;;
            4) run_ex02; pause ;;
            5) run_ex03; pause ;;
            6) count_customers; pause ;;
            7) open_psql; pause ;;
            8) check_delivery_files; pause ;;
            e|E) prepare_eval_folder; pause ;;
            0) git_assisted; pause ;;
            9) eval_reminder; pause ;;
            a|A) optional_ex_start "$EX00_DIR" "EX00"; pause ;;
            b|B) optional_ex_start "$EX01_DIR" "EX01"; pause ;;
            c|C) optional_ex_start "$EX02_DIR" "EX02"; pause ;;
            d|D) optional_ex_start "$EX03_DIR" "EX03"; pause ;;
            q|Q) echo -e "${GREEN}Hasta luego.${RESET}"; exit 0 ;;
            *) warn "Opción no válida" ;;
        esac
    done
}

main()
{
    print_header
    echo -e "${WHITE}Asistente ${BOLD}independiente${RESET}${WHITE}: pipeline, pgAdmin, repo de evaluación, Git.${RESET}"
    echo -e "  ${CYAN}Sin push automático · sin borrar volúmenes · +x solo con permiso.${RESET}"
    echo
    if [[ -z "$MODULE0_DIR" ]]; then
        warn "Module 0 no encontrado en rutas habituales."
    else
        info "Module 0: $MODULE0_DIR"
    fi
    echo
    if ask_yes_no "¿Comprobar permisos +x al arrancar?" "s"; then
        fix_executable_permissions "$PROJECT_DIR"
    fi
    if ask_yes_no "¿Ver estado del entorno?" "s"; then
        status_environment
    fi
    menu_loop
}

main "$@"
