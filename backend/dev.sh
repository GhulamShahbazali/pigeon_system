#!/usr/bin/env bash
# PigeonFly backend — one-command dev runner.
# Handles: .env check · dependencies · Prisma client · schema (db push) ·
# search indexes (trigram SQL) · optional seed · starts the chosen process role.
#
# Usage:
#   ./dev.sh                 # ALL-IN-ONE dev: API + embedded BullMQ workers +
#                            #   bot engine/scheduler, in one process+terminal.
#   ./dev.sh --api-only      # just the API (no embedded workers / bot engine)
#   ./dev.sh worker          # BullMQ workers only (production-like separation)
#   ./dev.sh scheduler       # scheduler + bot engine only (exactly one)
#   ./dev.sh --seed          # also seed the bot roster before starting
#   ./dev.sh --install       # force `npm install`
#   ./dev.sh --setup-only    # do all prep, don't start the server
#
# NOTE: the all-in-one default already runs the bot engine. Do NOT also start a
# separate `./dev.sh scheduler` alongside it, or the engine + crons run twice.
set -euo pipefail
cd "$(dirname "$0")"

c() { printf "\033[%sm%s\033[0m\n" "$1" "$2"; }   # color echo
info() { c "1;34" "▶ $1"; }
ok()   { c "1;32" "✓ $1"; }
warn() { c "1;33" "! $1"; }
die()  { c "1;31" "✗ $1"; exit 1; }

ROLE="api"
SEED=false; FORCE_INSTALL=false; SETUP_ONLY=false; FORCE_SYNC=false; API_ONLY=false
PORT="${PORT:-3000}"
for arg in "$@"; do
  case "$arg" in
    api|worker|scheduler) ROLE="$arg" ;;
    --api-only) API_ONLY=true ;;
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

# 3-5. DB sync — auto-detect ANY change to the DB schema (or index SQL) by
#      content hash, so a pull / branch switch / edit re-syncs itself without
#      relying on file mtimes. The network db-push is the slow part, so we only
#      run it when the fingerprint actually changes.
STAMP=".dev-last-sync"

# Fingerprint = hash of schema.prisma (+ index SQL). Empty string if no hasher
# is available, which falls back to the mtime check below.
db_fingerprint() {
  local files=(prisma/schema.prisma)
  [ -f prisma/sql/01-search-indexes.sql ] && files+=(prisma/sql/01-search-indexes.sql)
  if command -v sha256sum >/dev/null 2>&1; then
    cat "${files[@]}" | sha256sum | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    cat "${files[@]}" | shasum -a 256 | awk '{print $1}'
  else
    echo ""
  fi
}

CUR_FP="$(db_fingerprint)"
PREV_FP="$([ -f "$STAMP" ] && cat "$STAMP" 2>/dev/null || echo "")"

need_sync=false
if $FORCE_SYNC; then need_sync=true
elif [ ! -d node_modules/.prisma/client ]; then need_sync=true            # client missing
elif [ ! -f "$STAMP" ]; then need_sync=true                               # first run
elif [ -n "$CUR_FP" ]; then
  # Content-hash mode: re-sync whenever the schema/index SQL content changes.
  [ "$CUR_FP" != "$PREV_FP" ] && need_sync=true
else
  # Fallback (no hasher): compare file mtimes against the stamp.
  if [ prisma/schema.prisma -nt "$STAMP" ]; then need_sync=true
  elif [ -f prisma/sql/01-search-indexes.sql ] && [ prisma/sql/01-search-indexes.sql -nt "$STAMP" ]; then need_sync=true
  fi
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
  # Record the fingerprint (or touch, in fallback mode) so the next run can skip.
  if [ -n "$CUR_FP" ]; then printf '%s\n' "$CUR_FP" > "$STAMP"; else touch "$STAMP"; fi
  ok "DB sync complete"
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

# All-in-one dev default: a plain `./dev.sh` (api role) also embeds the bot
# engine + BullMQ workers in the same process, so one command/terminal brings
# the whole system up. `SCHEDULER_ENABLED=true` starts the bot engine
# (BotEngineBootstrap) and the worker runner in the API process. Opt out with
# `--api-only`, or split into roles for production-like separation.
if [ "$ROLE" = "api" ] && ! $API_ONLY; then
  export SCHEDULER_ENABLED=true
  export WORKERS_EMBEDDED=true
  info "All-in-one dev: embedding bot engine + workers in the API process"
fi

[ "$ROLE" = "api" ] && free_port "$PORT"
info "Starting backend as PROCESS_ROLE=$ROLE (watch mode)…"
exec npx nest start --watch
