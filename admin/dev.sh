#!/usr/bin/env bash
# PigeonFly admin — one-command dev runner.
# Handles: .env.local check · dependencies · starts Next.js dev on :3001.
#
# Usage:
#   ./dev.sh              # install (if needed) then `next dev -p 3001`
#   ./dev.sh --install    # force `npm install`
#   ./dev.sh --build      # production build instead of dev server
set -euo pipefail
cd "$(dirname "$0")"

c() { printf "\033[%sm%s\033[0m\n" "$1" "$2"; }
info() { c "1;34" "▶ $1"; }
ok()   { c "1;32" "✓ $1"; }
warn() { c "1;33" "! $1"; }
die()  { c "1;31" "✗ $1"; exit 1; }

FORCE_INSTALL=false; DO_BUILD=false
PORT="${PORT:-3001}"
for arg in "$@"; do
  case "$arg" in
    --install) FORCE_INSTALL=true ;;
    --build) DO_BUILD=true ;;
    --port=*) PORT="${arg#*=}" ;;
    *) warn "ignoring unknown arg: $arg" ;;
  esac
done

command -v node >/dev/null || die "node not found — install Node 20 LTS"

# Free the port if a stale dev server is holding it (EADDRINUSE).
free_port() {
  local port="$1" pids
  command -v lsof >/dev/null || return 0
  pids=$(lsof -ti "tcp:${port}" 2>/dev/null || true)
  if [ -n "$pids" ]; then
    warn "port ${port} busy (pids: ${pids//$'\n'/ }) — freeing it"
    # shellcheck disable=SC2086
    kill $pids 2>/dev/null || true
    sleep 1
    pids=$(lsof -ti "tcp:${port}" 2>/dev/null || true)
    [ -n "$pids" ] && kill -9 $pids 2>/dev/null || true
    ok "port ${port} freed"
  fi
}

# 1. env ---------------------------------------------------------------------
if [ ! -f .env.local ]; then
  warn ".env.local missing — creating from .env.example"
  cp .env.example .env.local
  ok "created .env.local (NEXT_PUBLIC_API_BASE=http://localhost:3000/v1) — edit if your backend differs"
fi
ok ".env.local present"

# 2. dependencies ------------------------------------------------------------
if $FORCE_INSTALL || [ ! -d node_modules ] || [ package-lock.json -nt node_modules ]; then
  info "Installing dependencies…"; npm install; ok "dependencies installed"
else
  ok "dependencies up to date (--install to force)"
fi

# 3. run / build -------------------------------------------------------------
if $DO_BUILD; then
  info "Production build…"; npm run build; ok "build complete — run with: npm start"; exit 0
fi

free_port "$PORT"
info "Starting admin on http://localhost:${PORT} …"
warn "Backend must be running (./dev.sh in backend/). Sign in with a SuperAdmin token."
exec npx next dev -p "$PORT"
