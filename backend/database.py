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
    db_file = os.path.join(base_dir, "curry_mama.db")
    conn = sqlite3.connect(db_file)
    conn.row_factory = sqlite3.Row
    return SqliteConnectionWrapper(conn)

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

    conn.commit()
    
    # Check if seed needed
    try:
        cursor.execute("SELECT COUNT(*) as count FROM products")
        row = cursor.fetchone()
        count = row['count'] if row else 0
    except Exception:
        count = 0

    if count == 0:
        print("Seeding database...")
        seed_data(conn, placeholder)
        
    cursor.close()
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
    
    now = datetime.now()
    day_1 = now - timedelta(days=2)
    yesterday = now - timedelta(days=1)
    
    orders = [
        ("Ramesh Kumar", "9876543210", "12, South Usman Road, T-Nagar", "Cash on Delivery", json.dumps([{"name": "Premium Chicken Breast", "quantity": 2, "price": 280.0}, {"name": "Chicken Drumsticks", "quantity": 1, "price": 320.0}]), 880.0, "Completed", day_1.strftime("%Y-%m-%d %H:%M:%S")),
        ("Anitha Raj", "9876543211", "45, Sardar Patel Road, Adyar", "Online Pay", json.dumps([{"name": "Tender Mutton Curry Cut", "quantity": 1, "price": 780.0}]), 780.0, "Completed", (day_1 + timedelta(hours=3)).strftime("%Y-%m-%d %H:%M:%S")),
        ("Vijay Anand", "9876543212", "78, G.N. Chetty Road, T-Nagar", "Cash on Delivery", json.dumps([{"name": "Spiced Chicken Kebab (Ready to Cook)", "quantity": 2, "price": 220.0}]), 440.0, "Completed", (day_1 + timedelta(hours=5)).strftime("%Y-%m-%d %H:%M:%S")),
        ("Suresh Sharma", "9876543213", "101, Velachery Main Road, Velachery", "Online Pay", json.dumps([{"name": "Premium Lamb Chops", "quantity": 2, "price": 650.0}]), 1300.0, "Completed", yesterday.strftime("%Y-%m-%d %H:%M:%S")),
        ("Priya Nair", "9876543214", "22, OMR Road, Thoraipakkam", "Online Pay", json.dumps([{"name": "Premium Chicken Breast", "quantity": 1, "price": 280.0}, {"name": "Fresh Fish Fillet (Seer)", "quantity": 1, "price": 450.0}]), 730.0, "Completed", (yesterday + timedelta(hours=2)).strftime("%Y-%m-%d %H:%M:%S")),
        ("Karthik S", "9876543215", "5, ECR Road, Thiruvanmiyur", "Cash on Delivery", json.dumps([{"name": "Tender Mutton Curry Cut", "quantity": 1, "price": 780.0}]), 780.0, "Cancelled", (yesterday + timedelta(hours=4)).strftime("%Y-%m-%d %H:%M:%S")),
        ("Meena Krishnan", "9876543216", "34, West Mada Street, Mylapore", "Online Pay", json.dumps([{"name": "Chicken Drumsticks", "quantity": 2, "price": 320.0}]), 640.0, "Pending", (now - timedelta(hours=3)).strftime("%Y-%m-%d %H:%M:%S")),
        ("Rahul Verma", "9876543217", "9, 2nd Main Road, Besant Nagar", "Cash on Delivery", json.dumps([{"name": "Premium Lamb Chops", "quantity": 1, "price": 650.0}, {"name": "Spiced Chicken Kebab (Ready to Cook)", "quantity": 1, "price": 220.0}]), 870.0, "Pending", (now - timedelta(hours=1)).strftime("%Y-%m-%d %H:%M:%S")),
    ]
    
    cursor.executemany(
        f"INSERT INTO orders (customer_name, mobile_number, address, payment_method, items, total_price, status, date) VALUES ({placeholder}, {placeholder}, {placeholder}, {placeholder}, {placeholder}, {placeholder}, {placeholder}, {placeholder})",
        orders
    )
    
    conn.commit()
    cursor.close()

if __name__ == "__main__":
    init_db()
    print("Database initialized successfully.")
