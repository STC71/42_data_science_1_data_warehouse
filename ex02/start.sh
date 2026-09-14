#!/usr/bin/env bash

# ============================================================
# PISCINE PEDAGO - DATA SCIENCE
# Module 1 – Data Warehouse – EX02 remove duplicates
#
# sternero – 42 Málaga – Octubre 2026
#
# Asistente opcional (NO sustituye remove_duplicates.*)
# - Comprueba PostgreSQL / tabla customers
# - Ejecuta remove_duplicates.py o aplica remove_duplicates.sql
# - Muestra COUNT(*) antes/después orientativo
# - Puede arrancar contenedor + pgAdmin (Module 0)
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
MODULE1_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
CONTAINER_NAME="postgres_piscineds"
PY_SCRIPT="$SCRIPT_DIR/remove_duplicates.py"
SQL_SCRIPT="$SCRIPT_DIR/remove_duplicates.sql"

find_module0()
{
    local c
    for c in \
        "$MODULE1_DIR/../data_science_0_creation_db" \
        "$MODULE1_DIR/../../data_science_0_creation_db" \
        "$HOME/sgoinfre/42_outer_core/piscine_pedago_data_science/data_science_0_creation_db" \
        "$HOME/sgoinfre/students/$(id -un)/42_outer_core/piscine_pedago_data_science/data_science_0_creation_db"
    do
        if [[ -f "$c/ex00/.env" ]] || [[ -f "$c/ex00/docker-compose.yml" ]]; then
            echo "$(cd -- "$c" && pwd)"
            return 0
        fi
    done
    return 1
}

MODULE0_DIR="$(find_module0 || true)"
ENV_FILE=""
[[ -n "$MODULE0_DIR" && -f "$MODULE0_DIR/ex00/.env" ]] && ENV_FILE="$MODULE0_DIR/ex00/.env"

print_header()
{
    clear
    echo
    echo -e "${CYAN}${BOLD}╔════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}${BOLD}║  Module 1 – Data Warehouse – EX02 remove duplicates        ║${RESET}"
    echo -e "${CYAN}${BOLD}║  sternero – 42 Málaga                                      ║${RESET}"
    echo -e "${CYAN}${BOLD}╚════════════════════════════════════════════════════════════╝${RESET}"
    echo
    echo -e "${WHITE}  $SCRIPT_DIR${RESET}"
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
    local sql="$1"
    docker exec -i "$CONTAINER_NAME" \
        psql -U "$(db_user)" -d "$(db_name)" -c "$sql"
}

check_container()
{
    section "🐘  Contenedor PostgreSQL"
    if docker ps --format '{{.Names}}' 2>/dev/null | grep -qx "$CONTAINER_NAME"; then
        ok "$CONTAINER_NAME está Up"
        return 0
    fi
    err "Contenedor no está corriendo"
    info "Module 0: cd .../ex00 && docker-compose up -d"
    return 1
}

count_customers()
{
    section "🔢  COUNT(*) de customers"
    if ! docker ps --format '{{.Names}}' 2>/dev/null | grep -qx "$CONTAINER_NAME"; then
        err "Sin contenedor"
        return 1
    fi
    info "Comando: SELECT COUNT(*) FROM customers;"
    if ! psql_c "SELECT COUNT(*) AS customers_rows FROM customers;" 2>/dev/null; then
        warn "¿Existe la tabla customers? (EX01)"
        return 1
    fi
    echo
    return 0
}

run_python()
{
    section "🐍  remove_duplicates.py"
    if [[ ! -f "$PY_SCRIPT" ]]; then
        err "Falta $PY_SCRIPT"
        return 1
    fi
    chmod +x "$PY_SCRIPT" 2>/dev/null || true
    info "DELETE con LAG: misma instrucción y gap ≤ 1 segundo"
    warn "Puede tardar varios minutos (~20M filas)"
    if ! ask_yes_no "¿Ejecutar remove_duplicates.py ahora?" "s"; then
        warn "Omitido"
        return 0
    fi
    ( cd "$SCRIPT_DIR" && python3 "$PY_SCRIPT" )
}

run_sql()
{
    section "📜  remove_duplicates.sql"
    if [[ ! -f "$SQL_SCRIPT" ]]; then
        err "Falta $SQL_SCRIPT"
        return 1
    fi
    if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
        err "Sin contenedor"
        return 1
    fi
    info "Misma regla que el .py (ventana LAG + intervalo 1 s)"
    warn "Puede tardar varios minutos"
    if ! ask_yes_no "¿Aplicar SQL vía docker cp + psql -f?" "s"; then
        warn "Omitido"
        return 0
    fi
    docker cp "$SQL_SCRIPT" "$CONTAINER_NAME:/tmp/remove_duplicates.sql" 2>/dev/null || true
    docker exec -i "$CONTAINER_NAME" \
        psql -U "$(db_user)" -d "$(db_name)" -f /tmp/remove_duplicates.sql
    echo
    info "Vuelve a lanzar la opción COUNT para ver el resultado"
}

open_psql()
{
    section "💻  psql"
    docker exec -it "$CONTAINER_NAME" \
        psql -U "$(db_user)" -d "$(db_name)"
}

check_pgadmin()
{
    section "🖥️  pgAdmin"
    if ! command -v curl >/dev/null 2>&1; then
        warn "curl no está instalado; no se puede comprobar pgAdmin"
        return 1
    fi
    if curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 \
        "http://127.0.0.1:5050" 2>/dev/null | grep -qE '200|301|302|401|403'; then
        ok "pgAdmin responde en http://127.0.0.1:5050"
        return 0
    fi
    warn "pgAdmin no responde en :5050"
    return 1
}

start_pgadmin()
{
    section "▶️  Arrancar pgAdmin"
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
        err "No se encontró el venv de pgAdmin"
        info "Instálalo siguiendo data_science_0_creation_db/ex01"
        return 1
    fi
    if check_pgadmin >/dev/null 2>&1; then
        ok "pgAdmin ya estaba en marcha"
        return 0
    fi

    local pgadmin_dir
    pgadmin_dir="$(dirname "$venv")"
    local cfg="$pgadmin_dir/config"
    local data_dir="$pgadmin_dir/data"
    if ! mkdir -p "$cfg" "$data_dir"; then
        err "No se pudo preparar la configuración escribible de pgAdmin"
        return 1
    fi
    if [[ ! -f "$cfg/config_local.py" ]]; then
        printf "DATA_DIR = '%s'\n\n" "$data_dir" > "$cfg/config_local.py"
        printf "SQLITE_PATH = '%s/pgadmin4.db'\n\n" "$data_dir" >> "$cfg/config_local.py"
        printf "SESSION_DB_PATH = '%s/sessions'\n" "$data_dir" >> "$cfg/config_local.py"
        printf "STORAGE_DIR = '%s/storage'\n" "$data_dir" >> "$cfg/config_local.py"
        printf "LOG_FILE = '%s/pgadmin4.log'\n" "$data_dir" >> "$cfg/config_local.py"
    fi

    info "Iniciando pgAdmin en segundo plano desde $venv"
    (
        # shellcheck disable=SC1091
        source "$venv/bin/activate"
        export PYTHONPATH="$cfg${PYTHONPATH:+:$PYTHONPATH}"
        nohup pgadmin4 >/tmp/pgadmin4_m1_ex02.log 2>&1 &
        echo $! >/tmp/pgadmin4_m1_ex02.pid
    )

    local attempt
    for attempt in 1 2 3 4 5 6 7 8 9 10; do
        sleep 1
        if check_pgadmin >/dev/null 2>&1; then
            ok "pgAdmin arrancado → http://127.0.0.1:5050"
            return 0
        fi
        printf '\r\033[K%s→ Esperando a pgAdmin... (%d/10 s)%s' \
            "$CYAN" "$attempt" "$RESET"
    done
    echo
    warn "pgAdmin aún no responde; revisa /tmp/pgadmin4_m1_ex02.log"
    return 1
}

start_services()
{
    section "🚀  Arrancar entorno (Module 0 + pgAdmin)"
    if [[ -z "$MODULE0_DIR" || ! -f "$MODULE0_DIR/ex00/docker-compose.yml" ]]; then
        err "No se encontró el compose de Module 0"
        info "Necesario: data_science_0_creation_db/ex00/docker-compose.yml"
        return 1
    fi
    if ! command -v docker >/dev/null 2>&1; then
        err "Docker no está en el PATH"
        return 1
    fi

    info "PostgreSQL guarda los datos en un volumen Docker persistente"
    if command -v docker-compose >/dev/null 2>&1; then
        ( cd "$MODULE0_DIR/ex00" && docker-compose up -d )
    elif docker compose version >/dev/null 2>&1; then
        ( cd "$MODULE0_DIR/ex00" && docker compose up -d )
    else
        err "No se encontró docker-compose ni docker compose"
        return 1
    fi
    sleep 2
    if docker ps --format '{{.Names}}' 2>/dev/null | grep -qx "$CONTAINER_NAME"; then
        ok "PostgreSQL está disponible en localhost:5432"
    else
        err "El contenedor no aparece en ejecución"
        return 1
    fi

    start_pgadmin || warn "PostgreSQL está listo, pero pgAdmin requiere atención"
    echo
    info "URL pgAdmin: http://127.0.0.1:5050"
    echo "  Host: localhost | Port: 5432 | DB: $(db_name) | User: $(db_user)"
}

show_guides()
{
    section "📘  Guías del ejercicio"
    echo -e "  README:  ${BOLD}$SCRIPT_DIR/README.md${RESET}"
    echo -e "  SQL:     ${BOLD}$SCRIPT_DIR/sql.md${RESET}"
    echo -e "  Python:  ${BOLD}$SCRIPT_DIR/python.md${RESET}"
    echo
    info "Subject: duplicados + misma instrucción con intervalo de 1 segundo"
}

show_menu()
{
    echo
    echo -e "${CYAN}${BOLD}  MENÚ EX02 – remove duplicates${RESET}"
    echo
    echo -e "  ${BOLD}1)${RESET}  Arrancar contenedor + pgAdmin ${WHITE}(entorno)${RESET}"
    echo -e "  ${BOLD}2)${RESET}  Comprobar contenedor"
    echo -e "  ${BOLD}3)${RESET}  COUNT(*) de customers ${WHITE}(antes o después)${RESET}"
    echo -e "  ${BOLD}4)${RESET}  Ejecutar remove_duplicates.py ${WHITE}(recomendado)${RESET}"
    echo -e "  ${BOLD}5)${RESET}  Aplicar remove_duplicates.sql"
    echo -e "  ${BOLD}6)${RESET}  Abrir psql"
    echo -e "  ${BOLD}7)${RESET}  Ver rutas de guías (README / sql.md / python.md)"
    echo -e "  ${RED}${BOLD}q)${RESET}  ${RED}Salir${RESET}"
    echo
}

main()
{
    print_header
    echo -e "Subject: borrar duplicados en ${BOLD}customers${RESET}"
    echo -e "         y ecos de la misma instrucción a ${BOLD}≤ 1 segundo${RESET}."
    echo -e "Entrega: ${BOLD}remove_duplicates.*${RESET}  ·  Este menú es solo ayuda."
    echo
    local choice
    while true; do
        show_menu
        read -r -p "$(echo -e "${YELLOW}Opción → ${RESET}")" choice
        case "$choice" in
            1) start_services; pause ;;
            2) check_container; pause ;;
            3) count_customers; pause ;;
            4) run_python; pause ;;
            5) run_sql; pause ;;
            6) open_psql; pause ;;
            7) show_guides; pause ;;
            q|Q) echo -e "${GREEN}Siguiente del subject: EX03 – fusion (customers + items).${RESET}"; exit 0 ;;
            *) warn "Opción no válida" ;;
        esac
    done
}

main "$@"
