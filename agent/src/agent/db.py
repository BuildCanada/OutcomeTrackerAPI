import os
from contextlib import contextmanager

import psycopg2
import psycopg2.extras


def get_connection_string() -> str:
    return os.environ["AGENT_DATABASE_URL"]


@contextmanager
def get_db():
    """Context manager for read-only database connection."""
    conn = psycopg2.connect(
        get_connection_string(),
        cursor_factory=psycopg2.extras.RealDictCursor,
    )
    conn.set_session(readonly=True, autocommit=True)
    try:
        yield conn
    finally:
        conn.close()


def query(sql: str, params: tuple | None = None) -> list[dict]:
    """Execute a read-only query and return results as list of dicts."""
    with get_db() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, params)
            return [dict(row) for row in cur.fetchall()]


def query_one(sql: str, params: tuple | None = None) -> dict | None:
    """Execute a read-only query and return a single result."""
    results = query(sql, params)
    return results[0] if results else None
