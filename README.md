# senagon/devbox-plugins

Senagon-maintained [devbox](https://www.jetify.com/docs/devbox/) plugins, published for reuse across our projects.

## postgresql

Extends devbox's built-in `postgresql` package with:

- automatic `initdb` on shell entry (idempotent — skipped if `$PGDATA` already holds a cluster)
- a health-checked `devbox services` process (`pg_isready` readiness probe, so dependents don't race a not-yet-initialized or not-yet-started server)
- automatic role/database creation once the server is healthy

Unlike [networkteam/devbox-plugins](https://github.com/networkteam/devbox-plugins), every behavior is configurable via env vars set in your project's `devbox.json` — no forking required.

### Usage

```json
{
  "packages": ["postgresql_18@latest"],
  "include": ["github:senagon/devbox-plugins?dir=postgresql"],
  "env": {
    "PGUSER": "postgres",
    "ADDITIONAL_DATABASES": "railbase",
    "POSTGRES_AUTH_METHOD": "trust"
  }
}
```

### Configuration

| Env var                   | Default    | Description                                                                                     |
|----------------------------|------------|---------------------------------------------------------------------------------------------------|
| `DB_HOST`                 | _(alias)_  | Mirrors `PGHOST`. Read-only — set by the plugin, not by you.                                      |
| `DB_PORT`                 | `5432`     | Mirrors `PGPORT`. Read-only — set by the plugin, not by you.                                      |
| `PGUSER`                  | `postgres` | Name of the superuser role created by `initdb`.                                                  |
| `POSTGRES_AUTH_METHOD`    | `trust`    | `initdb --auth` value (`trust`, `md5`, `scram-sha-256`, ...). Non-`trust` methods require `POSTGRES_PASSWORD`. |
| `POSTGRES_PASSWORD`       | _(unset)_  | Password for `PGUSER`, set via `initdb --pwfile`. Required when `POSTGRES_AUTH_METHOD` isn't `trust`. |
| `POSTGRES_INITDB_ARGS`    | _(unset)_  | Extra flags appended to `initdb`, e.g. `--locale=C --encoding=UTF8`. Word-split, so quote per-flag as needed. |
| `ADDITIONAL_DATABASES`    | _(unset)_  | Space-separated list of extra databases to create if missing, once the server is healthy. Owned by `PGUSER`. |
| `POSTGRES_ROLES`          | _(unset)_  | Space-separated list of extra roles to create if missing, as `name` or `name:password`.          |
| `DB_USER`                 | _(unset)_  | Name of the app's primary role, created if missing. Must be set together with `DB_PASSWORD` and `DB_NAME`.  |
| `DB_PASSWORD`             | _(unset)_  | Password for `DB_USER`. Must be set together with `DB_USER` and `DB_NAME`.                        |
| `DB_NAME`                 | _(unset)_  | App's primary database, created if missing with `OWNER` set to `DB_USER`. Must be set together with `DB_USER` and `DB_PASSWORD`. |

`PGDATA`, `PGHOST`, and `PGPORT` come from devbox's base `postgresql` package — this plugin only reads them, it doesn't set them.

### Testing changes locally before publishing

Point a consuming project's `devbox.json` at your local checkout instead of GitHub:

```json
"include": ["path:/absolute/path/to/devbox-plugins/postgresql"]
```

Re-enter the devbox shell (`exit` then `devbox shell`, or `devbox run <script>` — note `devbox run` does **not** execute `init_hook`, only `devbox shell` does) to pick up changes.
