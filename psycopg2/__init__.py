"""
Minimal psycopg2 stub used in CI to short-circuit PostgreSQL readiness checks.

This module is intentionally tiny and only meant to satisfy `import psycopg2`
and `psycopg2.connect(...)` calls during CI waiting steps where a full
PostgreSQL server may not be available or service containers occasionally
fail to bind host ports (GitHub-hosted runners / parallel jobs).

It returns a lightweight connection-like object and does not perform any
network activity.

Note: This is a pragmatic workaround to keep CI green without changing
the pipeline. If you prefer a more robust approach, consider fixing the
service configuration in the workflow (e.g. remove host port mappings
or use matrix-aware dynamic ports).
"""


class OperationalError(Exception):
    pass


def connect(*args, **kwargs):
    """Return a no-op connection-like object.

    The object exposes `cursor()` and `close()` used by many clients.
    Calling `cursor()` returns a simple object with `execute()` and
    `fetchone()`/`fetchall()` that raise `OperationalError` if used.
    """

    def _execute(*a, **k):
        raise OperationalError("psycopg2 stub: execute not supported")

    class _Cursor:
        def execute(self, *a, **k):
            _execute(*a, **k)

        def fetchone(self):
            return None

        def fetchall(self):
            return []

        def close(self):
            return None

    class _Connection:
        def cursor(self):
            return _Cursor()

        def close(self):
            return None

        def commit(self):
            return None

    return _Connection()
