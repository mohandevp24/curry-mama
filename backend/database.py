import os
import json
from datetime import datetime, timedelta
import psycopg2
from psycopg2.extras import RealDictCursor
from dotenv import load_dotenv

# Load .env file from the current directory
base_dir = os.path.dirname(os.path.abspath(__file__))
env_path = os.path.join(base_dir, ".env")
if os.path.exists(env_path):
    load_dotenv(env_path)
else:
    load_dotenv()

DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "curry_mama")
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD", "postgres")

class PostgresConnectionWrapper:
    def __init__(self, conn):
        self._conn = conn

    def cursor(self, *args, **kwargs):
        if 'cursor_factory' not in kwargs:
            kwargs['cursor_factory'] = RealDictCursor
        return self._conn.cursor(*args, **kwargs)

    def __getattr__(self, name):
        return getattr(self._conn, name)

def get_db():
    conn = psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD
    )
    return PostgresConnectionWrapper(conn)

def init_db():
    conn = get_db()
    cursor = conn.cursor()
    
    # Create products table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS products (
            id SERIAL PRIMARY KEY,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            price REAL NOT NULL,
            weight TEXT NOT NULL,
            stock INTEGER NOT NULL,
            image_url TEXT NOT NULL
        )
    """)
    
    # Create orders table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS orders (
            id SERIAL PRIMARY KEY,
            customer_name TEXT NOT NULL,
            mobile_number TEXT NOT NULL DEFAULT '',
            address TEXT NOT NULL DEFAULT '',
            payment_method TEXT NOT NULL DEFAULT '',
            items TEXT NOT NULL, -- JSON string representing the items in the order
            total_price REAL NOT NULL,
            status TEXT NOT NULL, -- 'Pending', 'Completed', 'Cancelled'
            date TEXT NOT NULL,
            payment_status TEXT NOT NULL DEFAULT 'Unpaid',
            transaction_id TEXT NOT NULL DEFAULT ''
        )
    """)
    
    # Add columns if they do not exist
    try:
        cursor.execute("ALTER TABLE orders ADD COLUMN IF NOT EXISTS mobile_number TEXT NOT NULL DEFAULT ''")
    except Exception:
        pass
    try:
        cursor.execute("ALTER TABLE orders ADD COLUMN IF NOT EXISTS address TEXT NOT NULL DEFAULT ''")
    except Exception:
        pass
    try:
        cursor.execute("ALTER TABLE orders ADD COLUMN IF NOT EXISTS payment_method TEXT NOT NULL DEFAULT ''")
    except Exception:
        pass
    try:
        cursor.execute("ALTER TABLE orders ADD COLUMN IF NOT EXISTS payment_status TEXT NOT NULL DEFAULT 'Unpaid'")
    except Exception:
        pass
    try:
        cursor.execute("ALTER TABLE orders ADD COLUMN IF NOT EXISTS transaction_id TEXT NOT NULL DEFAULT ''")
    except Exception:
        pass
    
    # Create shops table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS shops (
            id SERIAL PRIMARY KEY,
            name TEXT NOT NULL,
            owner_name TEXT NOT NULL,
            workers TEXT NOT NULL,
            workers_mobile TEXT NOT NULL DEFAULT '',
            location TEXT NOT NULL,
            phone_number TEXT NOT NULL
        )
    """)
    try:
        cursor.execute("ALTER TABLE shops ADD COLUMN IF NOT EXISTS workers_mobile TEXT NOT NULL DEFAULT ''")
    except Exception:
        pass

    # Create delivery_partners table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS delivery_partners (
            id SERIAL PRIMARY KEY,
            name TEXT NOT NULL,
            mobile_number TEXT NOT NULL,
            location TEXT NOT NULL
        )
    """)
    # Create indexes for performance
    try:
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_orders_status_date ON orders (status, date)")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_orders_mobile ON orders (mobile_number)")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_products_category ON products (category)")
    except Exception as e:
        print(f"Error creating indexes: {e}")

    conn.commit()
    
    # Check if we need to seed data (e.g. if products table is empty)
    cursor.execute("SELECT COUNT(*) FROM products")
    count = cursor.fetchone()['count']
    if count == 0:
        print("Seeding database...")
        seed_data(conn)
        
    cursor.close()
    conn.close()

def seed_data(conn):
    cursor = conn.cursor()
    
    # Seed products
    products = [
        ("Premium Chicken Breast", "Chicken", 280.0, "500g", 25, "https://images.unsplash.com/photo-1604503468506-a8da13d82791?w=500&auto=format&fit=crop&q=60"),
        ("Tender Mutton Curry Cut", "Mutton", 780.0, "1kg", 15, "https://images.unsplash.com/photo-1603048588665-791ca8aea617?w=500&auto=format&fit=crop&q=60"),
        ("Chicken Drumsticks", "Chicken", 320.0, "1kg", 30, "https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?w=500&auto=format&fit=crop&q=60"),
        ("Premium Lamb Chops", "Mutton", 650.0, "500g", 10, "https://images.unsplash.com/photo-1544025162-d76694265947?w=500&auto=format&fit=crop&q=60"),
        ("Spiced Chicken Kebab (Ready to Cook)", "Marinated", 220.0, "350g", 20, "https://images.unsplash.com/photo-1599487488170-d11ec9c172f0?w=500&auto=format&fit=crop&q=60"),
        ("Fresh Fish Fillet (Seer)", "Seafood", 450.0, "500g", 8, "https://images.unsplash.com/photo-1534604973900-c43ab4c2e0ab?w=500&auto=format&fit=crop&q=60")
    ]
    
    cursor.executemany(
        "INSERT INTO products (name, category, price, weight, stock, image_url) VALUES (%s, %s, %s, %s, %s, %s)",
        products
    )
    
    # Seed orders representing Day 1 and recent days to build realistic analytics
    now = datetime.now()
    day_1 = now - timedelta(days=2)
    yesterday = now - timedelta(days=1)
    
    orders = [
        # Day 1 Orders
        ("Ramesh Kumar", "9876543210", "12, South Usman Road, T-Nagar", "Cash on Delivery", json.dumps([{"name": "Premium Chicken Breast", "quantity": 2, "price": 280.0}, {"name": "Chicken Drumsticks", "quantity": 1, "price": 320.0}]), 880.0, "Completed", day_1.strftime("%Y-%m-%d %H:%M:%S")),
        ("Anitha Raj", "9876543211", "45, Sardar Patel Road, Adyar", "Online Pay", json.dumps([{"name": "Tender Mutton Curry Cut", "quantity": 1, "price": 780.0}]), 780.0, "Completed", (day_1 + timedelta(hours=3)).strftime("%Y-%m-%d %H:%M:%S")),
        ("Vijay Anand", "9876543212", "78, G.N. Chetty Road, T-Nagar", "Cash on Delivery", json.dumps([{"name": "Spiced Chicken Kebab (Ready to Cook)", "quantity": 2, "price": 220.0}]), 440.0, "Completed", (day_1 + timedelta(hours=5)).strftime("%Y-%m-%d %H:%M:%S")),
        
        # Yesterday's Orders
        ("Suresh Sharma", "9876543213", "101, Velachery Main Road, Velachery", "Online Pay", json.dumps([{"name": "Premium Lamb Chops", "quantity": 2, "price": 650.0}]), 1300.0, "Completed", yesterday.strftime("%Y-%m-%d %H:%M:%S")),
        ("Priya Nair", "9876543214", "22, OMR Road, Thoraipakkam", "Online Pay", json.dumps([{"name": "Premium Chicken Breast", "quantity": 1, "price": 280.0}, {"name": "Fresh Fish Fillet (Seer)", "quantity": 1, "price": 450.0}]), 730.0, "Completed", (yesterday + timedelta(hours=2)).strftime("%Y-%m-%d %H:%M:%S")),
        ("Karthik S", "9876543215", "5, ECR Road, Thiruvanmiyur", "Cash on Delivery", json.dumps([{"name": "Tender Mutton Curry Cut", "quantity": 1, "price": 780.0}]), 780.0, "Cancelled", (yesterday + timedelta(hours=4)).strftime("%Y-%m-%d %H:%M:%S")),
        
        # Today's Orders
        ("Meena Krishnan", "9876543216", "34, West Mada Street, Mylapore", "Online Pay", json.dumps([{"name": "Chicken Drumsticks", "quantity": 2, "price": 320.0}]), 640.0, "Pending", (now - timedelta(hours=3)).strftime("%Y-%m-%d %H:%M:%S")),
        ("Rahul Verma", "9876543217", "9, 2nd Main Road, Besant Nagar", "Cash on Delivery", json.dumps([{"name": "Premium Lamb Chops", "quantity": 1, "price": 650.0}, {"name": "Spiced Chicken Kebab (Ready to Cook)", "quantity": 1, "price": 220.0}]), 870.0, "Pending", (now - timedelta(hours=1)).strftime("%Y-%m-%d %H:%M:%S")),
    ]
    
    cursor.executemany(
        "INSERT INTO orders (customer_name, mobile_number, address, payment_method, items, total_price, status, date) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)",
        orders
    )
    
    # Create banners table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS banners (
            id SERIAL PRIMARY KEY,
            image_url TEXT NOT NULL,
            title TEXT NOT NULL DEFAULT '',
            is_active BOOLEAN NOT NULL DEFAULT TRUE,
            created_at TEXT NOT NULL
        )
    """)
    
    conn.commit()
    cursor.close()

if __name__ == "__main__":
    init_db()
    print("Database initialized successfully.")
