#! bash
set -euo pipefail

pg_port="${PGPORT:-5432}"
pg_user="${PGUSER:-postgres}"

psql_c() {
  psql -h "$PGHOST" -p "$pg_port" -U "$pg_user" -d postgres -v ON_ERROR_STOP=1 "$@"
}

db_user="${DB_USER:-}"
db_password="${DB_PASSWORD:-}"
db_name="${DB_NAME:-}"

set_count=0
[ -n "$db_user" ] && set_count=$((set_count + 1))
[ -n "$db_password" ] && set_count=$((set_count + 1))
[ -n "$db_name" ] && set_count=$((set_count + 1))

if [ "$set_count" -gt 0 ] && [ "$set_count" -lt 3 ]; then
  echo "postgresql plugin: DB_USER, DB_PASSWORD, and DB_NAME must all be set together (currently set: ${db_user:+DB_USER }${db_password:+DB_PASSWORD }${db_name:+DB_NAME})" >&2
  exit 1
fi

for role_spec in ${POSTGRES_ROLES:-}; do
  role_name="${role_spec%%:*}"
  role_pass="${role_spec#*:}"
  [ "$role_pass" = "$role_spec" ] && role_pass=""

  exists="$(psql_c -tAc "SELECT 1 FROM pg_roles WHERE rolname = '${role_name}'")"
  if [ "$exists" != "1" ]; then
    echo "postgresql plugin: creating role ${role_name}"
    if [ -n "$role_pass" ]; then
      psql_c -c "CREATE ROLE \"${role_name}\" LOGIN PASSWORD '${role_pass}'"
    else
      psql_c -c "CREATE ROLE \"${role_name}\" LOGIN"
    fi
  fi
done

if [ -n "$db_user" ]; then
  exists="$(psql_c -tAc "SELECT 1 FROM pg_roles WHERE rolname = '${db_user}'")"
  if [ "$exists" != "1" ]; then
    echo "postgresql plugin: creating role ${db_user}"
    psql_c -c "CREATE ROLE \"${db_user}\" LOGIN PASSWORD '${db_password}'"
  fi
fi

for db in ${ADDITIONAL_DATABASES:-}; do
  exists="$(psql_c -tAc "SELECT 1 FROM pg_database WHERE datname = '${db}'")"
  if [ "$exists" != "1" ]; then
    echo "postgresql plugin: creating database ${db}"
    createdb -h "$PGHOST" -p "$pg_port" -U "$pg_user" "${db}"
  fi
done

if [ -n "$db_name" ]; then
  exists="$(psql_c -tAc "SELECT 1 FROM pg_database WHERE datname = '${db_name}'")"
  if [ "$exists" != "1" ]; then
    echo "postgresql plugin: creating database ${db_name} (owner ${db_user})"
    createdb -h "$PGHOST" -p "$pg_port" -U "$pg_user" --owner="${db_user}" "${db_name}"
  fi
fi
