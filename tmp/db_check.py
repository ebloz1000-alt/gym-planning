import os
import sys

try:
    import psycopg2
except Exception as e:
    print("MISSING_PKG", e)
    sys.exit(2)

url = os.environ.get("DATABASE_URL")
if not url:
    print("NO_URL")
    sys.exit(3)

try:
    conn = psycopg2.connect(url, connect_timeout=10)
    cur = conn.cursor()
    cur.execute("SELECT version(), current_database();")
    row = cur.fetchone()
    print("OK", row[0], row[1])
    cur.close()
    conn.close()
except Exception as e:
    print("ERR", str(e))
    sys.exit(4)
