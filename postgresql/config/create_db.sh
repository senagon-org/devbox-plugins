#! bash
set -euo pipefail

pg_port="${PGPORT:-5432}"
pg_user="${PGUSER:-postgres}"

psql_c() {
  psql -h "$PGHOST" -p "$pg_port" -U "$pg_user" -d postgres -v ON_ERROR_STOP=1 "$@"
}

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

for db_name in ${POSTGRES_DATABASES:-}; do
  exists="$(psql_c -tAc "SELECT 1 FROM pg_database WHERE datname = '${db_name}'")"
  if [ "$exists" != "1" ]; then
    echo "postgresql plugin: creating database ${db_name}"
    createdb -h "$PGHOST" -p "$pg_port" -U "$pg_user" "${db_name}"
  fi
done
