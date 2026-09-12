#!/usr/bin/env bash

# ============================================================
# PISCINE PEDAGO - DATA SCIENCE
# Module 1 – Data Warehouse – EX00 Show me your DB
#
# Independiente: no exige los start.sh de Module 0, pero los
# reutiliza si existen (Docker / pgAdmin ya instalado).
#
# Subject: herramienta gráfica para ver la BD y buscar por ID.
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

# Candidatos a Module 0 (monorepo piscine o rutas cercanas)
find_module0()
{
    local c
    for c in \
        "$MODULE1_DIR/../data_science_0_creation_db" \
        "$MODULE1_DIR/../../data_science_0_creation_db" \
        "$HOME/sgoinfre/42_outer_core/piscine_pedago_data_science/data_science_0_creation_db" \
        "$HOME/sgoinfre/students/$(id -un)/42_outer_core/piscine_pedago_data_science/data_science_0_creation_db"
    do
        if [[ -d "$c/ex00" ]] || [[ -f "$c/ex00/docker-compose.yml" ]]; then
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
    echo -e "${CYAN}${BOLD}║  PISCINE DATA SCIENCE – Module 1 – Data Warehouse          ║${RESET}"
    echo -e "${CYAN}${BOLD}║  EX00 – Show me your DB          sternero – 42 Málaga      ║${RESET}"
    echo -e "${CYAN}${BOLD}╚════════════════════════════════════════════════════════════╝${RESET}"
    echo
    echo -e "${WHITE}  Script:  $SCRIPT_DIR/start.sh${RESET}"
    if [[ -n "$MODULE0_DIR" ]]; then
        echo -e "${WHITE}  Module0: $MODULE0_DIR${RESET}"
    else
        echo -e "${YELLOW}  Module0: no localizado automáticamente${RESET}"
    fi
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

pause()
{
    echo
    read -r -p "$(echo -e "${CYAN}Pulsa Enter para continuar...${RESET}")"
}

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

show_connection_card()
{
    section "🔌  Datos de conexión (subject / Module 0)"
    local u d
    u="$(id -un 2>/dev/null || whoami)"
    d="piscineds"
    if read_env; then
        u="$POSTGRES_USER"
        d="$POSTGRES_DB"
    fi
    cat << EOF
  Host:     localhost
  Port:     5432
  Database: $d
  Username: $u
  Password: mysecretpassword

  pgAdmin (si usas la instalación campus):
  URL:      http://127.0.0.1:5050

  En pgAdmin: Servers → Register → Server…
  General: nombre libre (p. ej. Piscine DS)
  Connection: valores de arriba
EOF
    echo
}

check_docker()
{
    section "🐳  Docker"
    if ! command -v docker >/dev/null 2>&1; then
        err "Docker no está en el PATH"
        return 1
    fi
    if ! docker info >/dev/null 2>&1; then
        err "Docker no responde"
        return 1
    fi
    ok "Docker operativo"
    return 0
}

check_postgres()
{
    section "🐘  PostgreSQL ($CONTAINER_NAME)"
    if docker ps --format '{{.Names}}' 2>/dev/null | grep -qx "$CONTAINER_NAME"; then
        ok "Contenedor en ejecución"
        docker ps --filter "name=^/${CONTAINER_NAME}$" --format "  {{.Status}} | {{.Ports}}" 2>/dev/null || true
        if read_env; then
            if docker exec "$CONTAINER_NAME" \
                pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB" >/dev/null 2>&1; then
                ok "pg_isready OK"
            else
                warn "Contenedor up pero pg_isready falló"
            fi
        fi
        return 0
    fi
    if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -qx "$CONTAINER_NAME"; then
        warn "Contenedor existe pero está parado"
        if ask_yes_no "¿docker start $CONTAINER_NAME?" "s"; then
            docker start "$CONTAINER_NAME" && sleep 2 && ok "Arrancado" && return 0
        fi
        return 1
    fi
    err "No existe $CONTAINER_NAME"
    info "Levántalo desde Module 0: cd .../data_science_0_creation_db/ex00 && docker-compose up -d"
    if [[ -n "$MODULE0_DIR" && -f "$MODULE0_DIR/ex00/docker-compose.yml" ]]; then
        if ask_yes_no "¿Ejecutar docker-compose up -d en Module 0 ex00?" "s"; then
            ( cd "$MODULE0_DIR/ex00" && docker-compose up -d )
            sleep 2
            docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME" && ok "Arriba" && return 0
        fi
    fi
    return 1
}

list_tables()
{
    section "📋  Tablas en piscineds"
    if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
        err "Sin contenedor"
        return 1
    fi
    local u d
    u="$(id -un 2>/dev/null || whoami)"
    d="piscineds"
    read_env && u="$POSTGRES_USER" && d="$POSTGRES_DB"
    docker exec -i "$CONTAINER_NAME" \
        psql -U "$u" -d "$d" -c '\dt' 2>/dev/null || warn "No se pudo listar"
    echo
}

check_pgadmin()
{
    section "🖥️  pgAdmin"
    if curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 "http://127.0.0.1:5050" 2>/dev/null | grep -qE '200|302|301|401|403'; then
        ok "Responde en http://127.0.0.1:5050"
        return 0
    fi
    warn "No responde en :5050 (¿no arrancado o no instalado?)"
    return 1
}

start_pgadmin()
{
    section "▶️  Arrancar pgAdmin"
    local venv=""
    for venv in \
        "$HOME/sgoinfre/pgadmin4/venv" \
        "$HOME/goinfre/pgadmin4/venv" \
        "$HOME/sgoinfre/students/$(id -un)/pgadmin4/venv"
    do
        [[ -x "$venv/bin/pgadmin4" ]] && break
        venv=""
    done

    if [[ -z "$venv" ]]; then
        err "No se encontró venv de pgAdmin"
        info "Instala desde Module 0: .../data_science_0_creation_db/ex01/install.sh"
        if [[ -n "$MODULE0_DIR" && -f "$MODULE0_DIR/ex01/install.sh" ]]; then
            echo -e "  Ruta: $MODULE0_DIR/ex01/install.sh"
            if ask_yes_no "¿Abrir/ejecutar install.sh de Module 0 ahora?" "n"; then
                chmod +x "$MODULE0_DIR/ex01/install.sh" 2>/dev/null || true
                ( cd "$MODULE0_DIR/ex01" && ./install.sh )
            fi
        fi
        return 1
    fi

    if check_pgadmin 2>/dev/null; then
        ok "Ya estaba en marcha"
        return 0
    fi

    info "venv: $venv"
    if ! ask_yes_no "¿Arrancar pgAdmin en segundo plano?" "s"; then
        warn "Omitido"
        return 0
    fi

    # config path si existe
    local cfg="$HOME/sgoinfre/pgadmin4/config"
    [[ -d "$cfg" ]] || cfg="$(dirname "$venv")/config"
    (
        # shellcheck disable=SC1091
        source "$venv/bin/activate"
        export PYTHONPATH="${cfg}:${PYTHONPATH:-}"
        nohup pgadmin4 >/tmp/pgadmin4_m1_ex00.log 2>&1 &
        echo $! >/tmp/pgadmin4_m1_ex00.pid
    )
    sleep 3
    if check_pgadmin; then
        ok "pgAdmin arrancado → http://127.0.0.1:5050"
    else
        warn "No responde aún; mira /tmp/pgadmin4_m1_ex00.log"
        info "O usa: cd $MODULE0_DIR/ex01 && ./start.sh"
    fi
}

open_module0_start()
{
    section "↪️  Module 0 – ex01/start.sh (opcional)"
    if [[ -z "$MODULE0_DIR" || ! -f "$MODULE0_DIR/ex01/start.sh" ]]; then
        warn "No hay Module 0 ex01/start.sh localizado"
        return 1
    fi
    if ask_yes_no "¿Ejecutar el asistente completo de Module 0 EX01?" "n"; then
        chmod +x "$MODULE0_DIR/ex01/start.sh" 2>/dev/null || true
        ( cd "$MODULE0_DIR/ex01" && ./start.sh )
    fi
}

show_menu()
{
    echo
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${CYAN}${BOLD}  MENÚ EX00 – Show me your DB (Module 1)${RESET}"
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo
    echo -e "  ${BOLD}1)${RESET}  Comprobar Docker + PostgreSQL"
    echo -e "  ${BOLD}2)${RESET}  Listar tablas (\\dt)"
    echo -e "  ${BOLD}3)${RESET}  Mostrar datos de conexión"
    echo -e "  ${BOLD}4)${RESET}  Comprobar pgAdmin (:5050)"
    echo -e "  ${BOLD}5)${RESET}  Arrancar pgAdmin"
    echo -e "  ${BOLD}6)${RESET}  Atajo: Module 0 ex01/start.sh ${WHITE}(opcional)${RESET}"
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
            1) check_docker; check_postgres; pause ;;
            2) list_tables; pause ;;
            3) show_connection_card; pause ;;
            4) check_pgadmin; pause ;;
            5) start_pgadmin; pause ;;
            6) open_module0_start; pause ;;
            q|Q) echo -e "${GREEN}Listo para la demo de la GUI.${RESET}"; exit 0 ;;
            *) warn "Opción no válida" ;;
        esac
    done
}

main()
{
    print_header
    echo -e "${WHITE}Subject EX00:${RESET} ver la BD con una herramienta gráfica y buscar por ID."
    echo -e "${WHITE}Este script${RESET} no sustituye la demo: prepara el entorno y recuerda la conexión."
    echo
    if [[ -z "$MODULE0_DIR" ]]; then
        warn "Module 0 no encontrado. Puedes indicar la ruta luego o arrancar Docker a mano."
        if ask_yes_no "¿Escribir ahora la ruta absoluta a data_science_0_creation_db?" "n"; then
            read -r -p "$(echo -e "${YELLOW}Ruta → ${RESET}")" MODULE0_DIR
            [[ -f "$MODULE0_DIR/ex00/.env" ]] && ENV_FILE="$MODULE0_DIR/ex00/.env"
        fi
    fi
    if ask_yes_no "¿Comprobar PostgreSQL al empezar?" "s"; then
        check_docker
        check_postgres
    fi
    menu_loop
}

main "$@"
