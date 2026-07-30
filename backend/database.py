import os
import json
import sqlite3
from datetime import datetime, timedelta
from dotenv import load_dotenv

# Load .env file from the current directory
base_dir = os.path.dirname(os.path.abspath(__file__))
env_path = os.path.join(base_dir, ".env")
if os.path.exists(env_path):
    load_dotenv(env_path)
else:
    load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")
DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "curry_mama")
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD", "postgres")

# Check if psycopg2 is installed and postgres credentials exist
USE_POSTGRES = False
psycopg2 = None
if DATABASE_URL or (DB_HOST and DB_HOST != "localhost"):
    try:
        import psycopg2
        from psycopg2.extras import RealDictCursor
        USE_POSTGRES = True
    except Exception:
        USE_POSTGRES = False

class PostgresConnectionWrapper:
    def __init__(self, conn):
        self._conn = conn

    def cursor(self, *args, **kwargs):
        if 'cursor_factory' not in kwargs:
            kwargs['cursor_factory'] = RealDictCursor
        return self._conn.cursor(*args, **kwargs)

    def __getattr__(self, name):
        return getattr(self._conn, name)

class SqliteDictCursor:
    def __init__(self, cursor):
        self._cursor = cursor

    def execute(self, sql, params=()):
        sql_converted = sql.replace("%s", "?").replace("SERIAL PRIMARY KEY", "INTEGER PRIMARY KEY AUTOINCREMENT")
        sql_converted = sql_converted.replace("BOOLEAN", "INTEGER").replace("TRUE", "1").replace("FALSE", "0")
        return self._cursor.execute(sql_converted, params)

    def executemany(self, sql, seq_of_params=()):
        sql_converted = sql.replace("%s", "?").replace("SERIAL PRIMARY KEY", "INTEGER PRIMARY KEY AUTOINCREMENT")
        return self._cursor.executemany(sql_converted, seq_of_params)

    def fetchone(self):
        row = self._cursor.fetchone()
        if row is None:
            return None
        return dict(row)

    def fetchall(self):
        rows = self._cursor.fetchall()
        return [dict(r) for r in rows]

    @property
    def lastrowid(self):
        return self._cursor.lastrowid

    def __getattr__(self, name):
        return getattr(self._cursor, name)

    def close(self):
        self._cursor.close()

class SqliteConnectionWrapper:
    def __init__(self, conn):
        self._conn = conn

    def cursor(self):
        return SqliteDictCursor(self._conn.cursor())

    def commit(self):
        self._conn.commit()

    def close(self):
        self._conn.close()

def get_db():
    if USE_POSTGRES:
        try:
            if DATABASE_URL:
                conn = psycopg2.connect(DATABASE_URL)
            else:
                conn = psycopg2.connect(
                    host=DB_HOST,
                    port=DB_PORT,
                    database=DB_NAME,
                    user=DB_USER,
                    password=DB_PASSWORD,
                    connect_timeout=5
                )
            return PostgresConnectionWrapper(conn)
        except Exception as e:
            print(f"Postgres connection failed ({e}). Falling back to SQLite...")
    
    # Fallback to SQLite
    db_dir = os.getenv("DATA_DIR") or base_dir
    db_file = os.getenv("DB_PATH") or os.path.join(db_dir, "curry_mama.db")
    conn = sqlite3.connect(db_file)
    conn.row_factory = sqlite3.Row
    return SqliteConnectionWrapper(conn)

BACKUP_JSON_PATH = os.path.join(base_dir, "orders_backup.json")

def backup_orders_to_json(conn=None):
    close_at_end = False
    if conn is None:
        conn = get_db()
        close_at_end = True
    try:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM orders ORDER BY id ASC")
        rows = cursor.fetchall()
        orders_list = [dict(r) for r in rows]
        with open(BACKUP_JSON_PATH, "w", encoding="utf-8") as f:
            json.dump(orders_list, f, indent=2)
    except Exception as e:
        print(f"Error backing up orders to JSON: {e}")
    finally:
        if close_at_end:
            conn.close()

def restore_orders_from_json(conn=None):
    if not os.path.exists(BACKUP_JSON_PATH):
        return
    close_at_end = False
    if conn is None:
        conn = get_db()
        close_at_end = True
    try:
        with open(BACKUP_JSON_PATH, "r", encoding="utf-8") as f:
            backup_orders = json.load(f)
        if not backup_orders:
            return
        
        cursor = conn.cursor()
        cursor.execute("SELECT id FROM orders")
        existing_ids = {row['id'] for row in cursor.fetchall()}

        placeholder = "%s" if USE_POSTGRES else "?"
        inserted_count = 0
        for o in backup_orders:
            if o.get('id') not in existing_ids:
                items_str = o['items'] if isinstance(o['items'], str) else json.dumps(o['items'])
                cursor.execute(
                    f"INSERT INTO orders (id, customer_name, mobile_number, address, payment_method, items, total_price, status, date, payment_status, transaction_id) VALUES ({placeholder}, {placeholder}, {placeholder}, {placeholder}, {placeholder}, {placeholder}, {placeholder}, {placeholder}, {placeholder}, {placeholder}, {placeholder})",
                    (
                        o.get('id'),
                        o.get('customer_name', ''),
                        o.get('mobile_number', ''),
                        o.get('address', ''),
                        o.get('payment_method', ''),
                        items_str,
                        o.get('total_price', 0.0),
                        o.get('status', 'Pending'),
                        o.get('date', datetime.now().strftime("%Y-%m-%d %H:%M:%S")),
                        o.get('payment_status', 'Unpaid'),
                        o.get('transaction_id', '')
                    )
                )
                inserted_count += 1
        conn.commit()
        if inserted_count > 0:
            print(f"Restored {inserted_count} orders from JSON backup.")
    except Exception as e:
        print(f"Error restoring orders from JSON: {e}")
    finally:
        if close_at_end:
            conn.close()

def cleanup_dummy_orders(conn=None):
    close_at_end = False
    if conn is None:
        conn = get_db()
        close_at_end = True
    try:
        cursor = conn.cursor()
        dummy_mobiles = (
            '9876543210', '9876543211', '9876543212', '9876543213',
            '9876543214', '9876543215', '9876543216', '9876543217'
        )
        placeholder = "%s" if USE_POSTGRES else "?"
        placeholders_str = ", ".join([placeholder] * len(dummy_mobiles))
        cursor.execute(f"DELETE FROM orders WHERE mobile_number IN ({placeholders_str})", dummy_mobiles)
        conn.commit()
        backup_orders_to_json(conn)
    except Exception as e:
        print(f"Error cleaning dummy orders: {e}")
    finally:
        if close_at_end:
            conn.close()

def init_db():
    conn = get_db()
    cursor = conn.cursor()
    
    pk_type = "SERIAL PRIMARY KEY" if USE_POSTGRES else "INTEGER PRIMARY KEY AUTOINCREMENT"
    placeholder = "%s" if USE_POSTGRES else "?"

    # Create products table
    cursor.execute(f"""
        CREATE TABLE IF NOT EXISTS products (
            id {pk_type},
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            price REAL NOT NULL,
            weight TEXT NOT NULL,
            stock INTEGER NOT NULL,
            image_url TEXT NOT NULL
        )
    """)
    
    # Create orders table
    cursor.execute(f"""
        CREATE TABLE IF NOT EXISTS orders (
            id {pk_type},
            customer_name TEXT NOT NULL,
            mobile_number TEXT NOT NULL DEFAULT '',
            address TEXT NOT NULL DEFAULT '',
            payment_method TEXT NOT NULL DEFAULT '',
            items TEXT NOT NULL,
            total_price REAL NOT NULL,
            status TEXT NOT NULL,
            date TEXT NOT NULL,
            payment_status TEXT NOT NULL DEFAULT 'Unpaid',
            transaction_id TEXT NOT NULL DEFAULT ''
        )
    """)
    
    # Safely migrate orders table columns if DB already existed
    cols_to_add = [
        ("mobile_number", "TEXT NOT NULL DEFAULT ''"),
        ("address", "TEXT NOT NULL DEFAULT ''"),
        ("payment_method", "TEXT NOT NULL DEFAULT ''"),
        ("payment_status", "TEXT NOT NULL DEFAULT 'Unpaid'"),
        ("transaction_id", "TEXT NOT NULL DEFAULT ''")
    ]
    for col_name, col_def in cols_to_add:
        try:
            cursor.execute(f"ALTER TABLE orders ADD COLUMN {col_name} {col_def}")
            conn.commit()
        except Exception:
            try:
                conn.rollback()
            except Exception:
                pass
    
    # Create shops table
    cursor.execute(f"""
        CREATE TABLE IF NOT EXISTS shops (
            id {pk_type},
            name TEXT NOT NULL,
            owner_name TEXT NOT NULL,
            workers TEXT NOT NULL,
            workers_mobile TEXT NOT NULL DEFAULT '',
            location TEXT NOT NULL,
            phone_number TEXT NOT NULL
        )
    """)

    # Create delivery_partners table
    cursor.execute(f"""
        CREATE TABLE IF NOT EXISTS delivery_partners (
            id {pk_type},
            name TEXT NOT NULL,
            mobile_number TEXT NOT NULL,
            location TEXT NOT NULL
        )
    """)

    # Create banners table
    cursor.execute(f"""
        CREATE TABLE IF NOT EXISTS banners (
            id {pk_type},
            image_url TEXT NOT NULL,
            title TEXT NOT NULL DEFAULT '',
            is_active INTEGER NOT NULL DEFAULT 1,
            created_at TEXT NOT NULL
        )
    """)

    # Create indexes for high-speed queries & performance
    try:
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_orders_mobile ON orders(mobile_number)")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status)")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_orders_date ON orders(date)")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_products_category ON products(category)")
    except Exception:
        pass

    conn.commit()
    
    # Check if product seed needed
    try:
        cursor.execute("SELECT COUNT(*) as count FROM products")
        row = cursor.fetchone()
        count = row['count'] if row else 0
    except Exception:
        count = 0

    if count == 0:
        print("Seeding initial products...")
        seed_data(conn, placeholder)
        
    cursor.close()
    
    # Restore any backed-up orders from JSON if database was reset
    restore_orders_from_json(conn)
    # Clean up dummy sample orders
    cleanup_dummy_orders(conn)
    
    conn.close()

def seed_data(conn, placeholder="%s"):
    cursor = conn.cursor()
    
    products = [
        ("Premium Chicken Breast", "Chicken", 280.0, "500g", 25, "https://images.unsplash.com/photo-1604503468506-a8da13d82791?w=500&auto=format&fit=crop&q=60"),
        ("Tender Mutton Curry Cut", "Mutton", 780.0, "1kg", 15, "https://images.unsplash.com/photo-1603048588665-791ca8aea617?w=500&auto=format&fit=crop&q=60"),
        ("Chicken Drumsticks", "Chicken", 320.0, "1kg", 30, "https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?w=500&auto=format&fit=crop&q=60"),
        ("Premium Lamb Chops", "Mutton", 650.0, "500g", 10, "https://images.unsplash.com/photo-1544025162-d76694265947?w=500&auto=format&fit=crop&q=60"),
        ("Spiced Chicken Kebab (Ready to Cook)", "Marinated", 220.0, "350g", 20, "https://images.unsplash.com/photo-1599487488170-d11ec9c172f0?w=500&auto=format&fit=crop&q=60"),
        ("Fresh Fish Fillet (Seer)", "Seafood", 450.0, "500g", 8, "https://images.unsplash.com/photo-1534604973900-c43ab4c2e0ab?w=500&auto=format&fit=crop&q=60")
    ]
    
    cursor.executemany(
        f"INSERT INTO products (name, category, price, weight, stock, image_url) VALUES ({placeholder}, {placeholder}, {placeholder}, {placeholder}, {placeholder}, {placeholder})",
        products
    )
    
    conn.commit()
    cursor.close()

if __name__ == "__main__":
    init_db()
    print("Database initialized successfully.")

