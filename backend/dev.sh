#!/usr/bin/env bash
# PigeonFly backend — one-command dev runner.
# Handles: .env check · dependencies · Prisma client · schema (db push) ·
# search indexes (trigram SQL) · optional seed · starts the chosen process role.
#
# Usage:
#   ./dev.sh                 # api (default) — installs/migrates then `nest start --watch`
#   ./dev.sh worker          # BullMQ workers
#   ./dev.sh scheduler       # scheduler + bot engine (exactly one)
#   ./dev.sh --seed          # also seed the bot roster before starting
#   ./dev.sh --install       # force `npm install`
#   ./dev.sh --setup-only    # do all prep, don't start the server
set -euo pipefail
cd "$(dirname "$0")"

c() { printf "\033[%sm%s\033[0m\n" "$1" "$2"; }   # color echo
info() { c "1;34" "▶ $1"; }
ok()   { c "1;32" "✓ $1"; }
warn() { c "1;33" "! $1"; }
die()  { c "1;31" "✗ $1"; exit 1; }

ROLE="api"
SEED=false; FORCE_INSTALL=false; SETUP_ONLY=false; FORCE_SYNC=false
PORT="${PORT:-3000}"
for arg in "$@"; do
  case "$arg" in
    api|worker|scheduler) ROLE="$arg" ;;
    --seed) SEED=true ;;
    --install) FORCE_INSTALL=true ;;
    --sync) FORCE_SYNC=true ;;
    --setup-only) SETUP_ONLY=true; FORCE_SYNC=true ;;
    --port=*) PORT="${arg#*=}" ;;
    *) warn "ignoring unknown arg: $arg" ;;
  esac
done

command -v node >/dev/null || die "node not found — install Node 20 LTS"
command -v npm  >/dev/null || die "npm not found"

# Free the port if a stale server is holding it (EADDRINUSE). api role only;
# worker/scheduler do not bind a port.
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
if [ ! -f .env ]; then
  warn ".env missing — creating from .env.example"
  cp .env.example .env
  die "Fill DATABASE_URL / REDIS_URL / JWT_SECRET in backend/.env, then re-run ./dev.sh"
fi
ok ".env present"

# 2. dependencies (only when missing or forced — a verify-install is slow) ----
if $FORCE_INSTALL || [ ! -d node_modules ]; then
  info "Installing dependencies…"; npm install; ok "dependencies installed"
else
  ok "dependencies present (--install to reinstall)"
fi

# 3-5. DB sync — SKIP when the schema hasn't changed since the last sync.
#      The network db-push is the slow part, so only run it when needed.
STAMP=".dev-last-sync"
need_sync=false
if $FORCE_SYNC; then need_sync=true
elif [ ! -d node_modules/.prisma/client ]; then need_sync=true   # client missing
elif [ ! -f "$STAMP" ]; then need_sync=true                      # first run
elif [ prisma/schema.prisma -nt "$STAMP" ]; then need_sync=true  # schema changed
elif [ -f prisma/sql/01-search-indexes.sql ] && [ prisma/sql/01-search-indexes.sql -nt "$STAMP" ]; then need_sync=true
fi

if $need_sync; then
  info "Generating Prisma client…"; npx prisma generate >/dev/null; ok "Prisma client generated"
  info "Applying schema (prisma db push)…"
  npx prisma db push --skip-generate --accept-data-loss
  ok "schema in sync"
  if [ -f prisma/sql/01-search-indexes.sql ]; then
    info "Applying search (trigram) indexes…"
    npx prisma db execute --file prisma/sql/01-search-indexes.sql --schema prisma/schema.prisma \
      && ok "search indexes applied" || warn "index step skipped (DB unreachable?) — safe to retry"
  fi
  touch "$STAMP"
else
  ok "schema unchanged — skipping DB sync (--sync to force)"
fi

# 6. optional seed -----------------------------------------------------------
if $SEED; then
  info "Seeding bot roster…"; npm run seed:bots; ok "roster seeded"
fi

if $SETUP_ONLY; then ok "setup complete (--setup-only)"; exit 0; fi

# 7. start -------------------------------------------------------------------
export PROCESS_ROLE="$ROLE"
export PORT
[ "$ROLE" = "scheduler" ] && export SCHEDULER_ENABLED=true
[ "$ROLE" = "api" ] && free_port "$PORT"
info "Starting backend as PROCESS_ROLE=$ROLE (watch mode)…"
exec npx nest start --watch
