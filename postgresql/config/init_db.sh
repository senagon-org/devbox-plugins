#! bash
set -euo pipefail

if [ -f "$PGDATA/PG_VERSION" ]; then
  exit 0
fi

auth_method="${POSTGRES_AUTH_METHOD:-trust}"

if [ "$auth_method" != "trust" ] && [ -z "${POSTGRES_PASSWORD:-}" ]; then
  echo "postgresql plugin: POSTGRES_AUTH_METHOD=$auth_method requires POSTGRES_PASSWORD to be set" >&2
  exit 1
fi

initdb_args=(-D "$PGDATA" -U "${PGUSER:-postgres}" --auth="$auth_method")

if [ -n "${POSTGRES_INITDB_ARGS:-}" ]; then
  # shellcheck disable=SC2206 # intentional word-splitting of user-supplied flags
  initdb_args+=($POSTGRES_INITDB_ARGS)
fi

pwfile=""
if [ -n "${POSTGRES_PASSWORD:-}" ]; then
  pwfile="$(mktemp)"
  trap 'rm -f "$pwfile"' EXIT
  printf '%s' "$POSTGRES_PASSWORD" >"$pwfile"
  initdb_args+=(--pwfile="$pwfile")
fi

mkdir -p "$PGDATA"
initdb "${initdb_args[@]}"
