from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
from typing import List, Optional
import json
import os
import shutil
import hmac
import hashlib
import base64
import urllib.request
from datetime import datetime
import database

app = FastAPI(title="Curry Mama Meat Admin API")

@app.on_event("startup")
def on_startup():
    try:
        database.init_db()
        print("Database initialized on startup.")
    except Exception as e:
        print(f"Startup DB init warning: {e}")

@app.get("/")
def root():
    return {"status": "ok", "app": "Curry Mama Meat API Server Live", "docs": "/docs"}

@app.get("/health")
def health():
    return {"status": "healthy"}

# Setup uploads directory and mount it as /static
UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)
app.mount("/static", StaticFiles(directory=UPLOAD_DIR), name="static")

# Configure CORS so Flutter Web can fetch our API without issues
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # In development, allow all origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

from fastapi import Request
from fastapi.responses import JSONResponse
from fastapi.middleware.gzip import GZipMiddleware

# Add GZip Compression for maximum network response speed
app.add_middleware(GZipMiddleware, minimum_size=500)

API_KEY = os.getenv("API_KEY", "CurryMamaSecret2026")

@app.middleware("http")
async def security_and_auth_middleware(request: Request, call_next):
    # Enforce security verification on all /api endpoints except OPTIONS preflight
    if request.url.path.startswith("/api") and request.method != "OPTIONS":
        api_key = request.headers.get("X-API-Key")
        if api_key != API_KEY:
            return JSONResponse(
                status_code=403,
                content={"detail": "Unauthorized request: Invalid or missing X-API-Key header."}
            )
    response = await call_next(request)
    # Add Security Headers to protect data privacy and prevent leaks
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "SAMEORIGIN"
    response.headers["X-XSS-Protection"] = "1; mode=block"
    response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
    return response

# Upload File API
@app.post("/api/upload")
async def upload_file(request: Request, file: UploadFile = File(...)):
    try:
        # Sanitize filename by removing spaces to prevent issues
        safe_filename = file.filename.replace(" ", "_")
        file_location = os.path.join(UPLOAD_DIR, safe_filename)
        with open(file_location, "wb+") as file_object:
            shutil.copyfileobj(file.file, file_object)
        
        # Return static serving URL matching request base host
        base_url = str(request.base_url).rstrip('/')
        url = f"{base_url}/static/{safe_filename}"
        return {"url": url}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Initialize Database on Startup
@app.on_event("startup")
def startup_event():
    database.init_db()

# Pydantic Schemas
class ProductCreate(BaseModel):
    name: str
    category: str
    price: float
    weight: str
    stock: int
    image_url: str

class ProductResponse(ProductCreate):
    id: int

class OrderItem(BaseModel):
    name: str
    quantity: int
    price: float

class OrderCreate(BaseModel):
    customer_name: str
    mobile_number: str
    address: str
    payment_method: str
    items: List[OrderItem]
    total_price: float
    status: str = "Pending"
    payment_status: str = "Unpaid"
    transaction_id: str = ""

class OrderResponse(BaseModel):
    id: int
    customer_name: str
    mobile_number: str
    address: str
    payment_method: str
    items: List[OrderItem]
    total_price: float
    status: str
    date: str
    payment_status: str
    transaction_id: str

class OrderStatusUpdate(BaseModel):
    status: str

class PaymentStatusUpdate(BaseModel):
    payment_status: str

class OtpRequest(BaseModel):
    mobile_number: str

class OtpVerifyRequest(BaseModel):
    mobile_number: str
    otp: str

class ThankYouSmsRequest(BaseModel):
    mobile_number: str
    customer_name: str
    order_id: int
    total_amount: float

class BannerCreate(BaseModel):
    image_url: str
    title: str = ""
    is_active: bool = True

class BannerResponse(BannerCreate):
    id: int
    created_at: str

# In-memory OTP storage
otp_store = {}

@app.post("/api/send_otp")
def send_otp(req: OtpRequest):
    import random
    # Generate 4-digit OTP
    otp = str(random.randint(1000, 9999))
    otp_store[req.mobile_number] = otp
    print(f"==================================================")
    print(f"📱 SMS GATEWAY: Sending 4-Digit OTP [{otp}] to +91 {req.mobile_number}")
    print(f"==================================================")
    return {
        "success": True, 
        "message": f"OTP sent to +91 {req.mobile_number}",
        "otp": otp # Returned for dev testing convenience
    }

@app.post("/api/verify_otp")
def verify_otp(req: OtpVerifyRequest):
    stored_otp = otp_store.get(req.mobile_number)
    if stored_otp and stored_otp == req.otp.strip():
        # Clean up OTP after verification
        otp_store.pop(req.mobile_number, None)
        return {"success": True, "message": "OTP verified successfully"}
    else:
        raise HTTPException(status_code=400, detail="Invalid OTP entered. Please try again.")

@app.post("/api/send_thankyou_sms")
def send_thankyou_sms(req: ThankYouSmsRequest):
    message = (
        f"Dear {req.customer_name}, Thank you for ordering from Curry Mama! "
        f"Your Order #{req.order_id} for ₹{req.total_amount:.0f} has been confirmed. "
        f"We are preparing your fresh meat order!"
    )
    print(f"==================================================")
    print(f"📩 THANK YOU SMS SENT TO +91 {req.mobile_number}:")
    print(f"   {message}")
    print(f"==================================================")
    return {"success": True, "message": "Thank you SMS sent successfully"}

# Products API
@app.get("/api/products", response_model=List[ProductResponse])
def get_products():
    conn = database.get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM products ORDER BY id DESC")
    rows = cursor.fetchall()
    conn.close()
    return [dict(row) for row in rows]

@app.post("/api/products", response_model=ProductResponse)
def create_product(product: ProductCreate):
    conn = database.get_db()
    cursor = conn.cursor()
    try:
        cursor.execute(
            "INSERT INTO products (name, category, price, weight, stock, image_url) VALUES (%s, %s, %s, %s, %s, %s) RETURNING id",
            (product.name, product.category, product.price, product.weight, product.stock, product.image_url)
        )
        product_id = cursor.fetchone()['id']
        conn.commit()
        conn.close()
        return {**product.dict(), "id": product_id}
    except Exception as e:
        conn.close()
        raise HTTPException(status_code=500, detail=str(e))

@app.put("/api/products/{product_id}", response_model=ProductResponse)
def update_product(product_id: int, product: ProductCreate):
    conn = database.get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT id FROM products WHERE id = %s", (product_id,))
    if not cursor.fetchone():
        conn.close()
        raise HTTPException(status_code=404, detail="Product not found")
    
    try:
        cursor.execute(
            "UPDATE products SET name = %s, category = %s, price = %s, weight = %s, stock = %s, image_url = %s WHERE id = %s",
            (product.name, product.category, product.price, product.weight, product.stock, product.image_url, product_id)
        )
        conn.commit()
        conn.close()
        return {**product.dict(), "id": product_id}
    except Exception as e:
        conn.close()
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/api/products/{product_id}")
def delete_product(product_id: int):
    conn = database.get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT id FROM products WHERE id = %s", (product_id,))
    if not cursor.fetchone():
        conn.close()
        raise HTTPException(status_code=404, detail="Product not found")
    
    try:
        cursor.execute("DELETE FROM products WHERE id = %s", (product_id,))
        conn.commit()
        conn.close()
        return {"message": f"Product with ID {product_id} deleted successfully"}
    except Exception as e:
        conn.close()
        raise HTTPException(status_code=500, detail=str(e))

# Orders API
@app.get("/api/orders", response_model=List[OrderResponse])
def get_orders():
    conn = database.get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM orders ORDER BY id DESC")
    rows = cursor.fetchall()
    conn.close()
    
    orders = []
    for row in rows:
        order_dict = dict(row)
        order_dict["items"] = json.loads(order_dict["items"])
        orders.append(order_dict)
    return orders

@app.get("/api/orders/track", response_model=List[OrderResponse])
def track_orders(mobile_number: str):
    conn = database.get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM orders WHERE mobile_number = %s ORDER BY id DESC", (mobile_number,))
    rows = cursor.fetchall()
    conn.close()
    
    orders = []
    for row in rows:
        order_dict = dict(row)
        order_dict["items"] = json.loads(order_dict["items"])
        orders.append(order_dict)
    return orders


@app.post("/api/orders", response_model=OrderResponse)
def create_order(order: OrderCreate):
    conn = database.get_db()
    cursor = conn.cursor()
    date_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    items_json = json.dumps([item.dict() for item in order.items])
    try:
        if database.USE_POSTGRES:
            cursor.execute(
                "INSERT INTO orders (customer_name, mobile_number, address, payment_method, items, total_price, status, date, payment_status, transaction_id) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s) RETURNING id",
                (order.customer_name, order.mobile_number, order.address, order.payment_method, items_json, order.total_price, order.status, date_str, order.payment_status, order.transaction_id)
            )
            res = cursor.fetchone()
            order_id = res['id'] if (res and isinstance(res, dict) and 'id' in res) else 1
        else:
            cursor.execute(
                "INSERT INTO orders (customer_name, mobile_number, address, payment_method, items, total_price, status, date, payment_status, transaction_id) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)",
                (order.customer_name, order.mobile_number, order.address, order.payment_method, items_json, order.total_price, order.status, date_str, order.payment_status, order.transaction_id)
            )
            order_id = getattr(cursor, 'lastrowid', None)
            if not order_id:
                cursor.execute("SELECT MAX(id) as max_id FROM orders")
                row = cursor.fetchone()
                order_id = row['max_id'] if row and row['max_id'] else 1
        conn.commit()
        conn.close()
        return {
            "id": order_id,
            "customer_name": order.customer_name,
            "mobile_number": order.mobile_number,
            "address": order.address,
            "payment_method": order.payment_method,
            "items": order.items,
            "total_price": order.total_price,
            "status": order.status,
            "date": date_str,
            "payment_status": order.payment_status,
            "transaction_id": order.transaction_id
        }
    except Exception as e:
        conn.close()
        raise HTTPException(status_code=500, detail=str(e))

@app.put("/api/orders/{order_id}", response_model=OrderResponse)
def update_order_status(order_id: int, status_update: OrderStatusUpdate):
    conn = database.get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM orders WHERE id = %s", (order_id,))
    row = cursor.fetchone()
    if not row:
        conn.close()
        raise HTTPException(status_code=404, detail="Order not found")
    
    try:
        cursor.execute(
            "UPDATE orders SET status = %s WHERE id = %s",
            (status_update.status, order_id)
        )
        conn.commit()
        
        # Fetch updated order to return
        cursor.execute("SELECT * FROM orders WHERE id = %s", (order_id,))
        updated_row = dict(cursor.fetchone())
        conn.close()
        
        updated_row["items"] = json.loads(updated_row["items"])
        return updated_row
    except Exception as e:
        conn.close()
        raise HTTPException(status_code=500, detail=str(e))

@app.put("/api/orders/{order_id}/payment_status", response_model=OrderResponse)
def update_payment_status(order_id: int, status_update: PaymentStatusUpdate):
    conn = database.get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM orders WHERE id = %s", (order_id,))
    row = cursor.fetchone()
    if not row:
        conn.close()
        raise HTTPException(status_code=404, detail="Order not found")
    
    try:
        cursor.execute(
            "UPDATE orders SET payment_status = %s WHERE id = %s",
            (status_update.payment_status, order_id)
        )
        conn.commit()
        
        cursor.execute("SELECT * FROM orders WHERE id = %s", (order_id,))
        updated_row = dict(cursor.fetchone())
        conn.close()
        
        updated_row["items"] = json.loads(updated_row["items"])
        return updated_row
    except Exception as e:
        conn.close()
        raise HTTPException(status_code=500, detail=str(e))

# Analytics API
@app.get("/api/analytics")
def get_analytics():
    conn = database.get_db()
    cursor = conn.cursor()
    
    # 1. Total Revenue
    cursor.execute("SELECT SUM(total_price) as total_rev FROM orders WHERE status = 'Completed'")
    total_revenue = cursor.fetchone()['total_rev'] or 0.0
    
    # 2. Total Orders count
    cursor.execute("SELECT COUNT(*) as total_cnt FROM orders")
    total_orders = cursor.fetchone()['total_cnt'] or 0
    
    # 3. Completed Orders count
    cursor.execute("SELECT COUNT(*) as completed_cnt FROM orders WHERE status = 'Completed'")
    completed_orders = cursor.fetchone()['completed_cnt'] or 0
    
    # 4. Pending Orders count
    cursor.execute("SELECT COUNT(*) as pending_cnt FROM orders WHERE status = 'Pending'")
    pending_orders = cursor.fetchone()['pending_cnt'] or 0
    
    # 5. Cancelled Orders count
    cursor.execute("SELECT COUNT(*) as cancelled_cnt FROM orders WHERE status = 'Cancelled'")
    cancelled_orders = cursor.fetchone()['cancelled_cnt'] or 0
    
    # 6. Daily sales graph data (last 7 days)
    cursor.execute("""
        SELECT CAST(date AS DATE) as order_date, SUM(total_price) as daily_revenue, COUNT(*) as daily_orders 
        FROM orders 
        WHERE status = 'Completed' 
        GROUP BY CAST(date AS DATE) 
        ORDER BY CAST(date AS DATE) ASC 
        LIMIT 7
    """)
    daily_rows = cursor.fetchall()
    
    # Fill in or format daily sales
    daily_sales = []
    for r in daily_rows:
        daily_sales.append({
            "date": str(r["order_date"]),
            "revenue": r["daily_revenue"] or 0.0,
            "orders": r["daily_orders"] or 0
        })
        
    conn.close()
    return {
        "total_revenue": total_revenue,
        "total_orders": total_orders,
        "completed_orders": completed_orders,
        "pending_orders": pending_orders,
        "cancelled_orders": cancelled_orders,
        "daily_sales": daily_sales
    }

class ShopCreate(BaseModel):
    name: str
    owner_name: str
    workers: str
    workers_mobile: str
    location: str
    phone_number: str

class ShopResponse(ShopCreate):
    id: int

class DeliveryCreate(BaseModel):
    name: str
    mobile_number: str
    location: str

class DeliveryResponse(DeliveryCreate):
    id: int

# Shop Partners API
@app.get("/api/shops", response_model=List[ShopResponse])
def get_shops():
    conn = database.get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM shops ORDER BY id DESC")
    rows = cursor.fetchall()
    conn.close()
    return [dict(row) for row in rows]

@app.post("/api/shops", response_model=ShopResponse)
def create_shop(shop: ShopCreate):
    conn = database.get_db()
    cursor = conn.cursor()
    try:
        cursor.execute(
            "INSERT INTO shops (name, owner_name, workers, workers_mobile, location, phone_number) VALUES (%s, %s, %s, %s, %s, %s) RETURNING id",
            (shop.name, shop.owner_name, shop.workers, shop.workers_mobile, shop.location, shop.phone_number)
        )
        shop_id = cursor.fetchone()['id']
        conn.commit()
        conn.close()
        return {**shop.dict(), "id": shop_id}
    except Exception as e:
        conn.close()
        raise HTTPException(status_code=500, detail=str(e))

@app.put("/api/shops/{shop_id}", response_model=ShopResponse)
def update_shop(shop_id: int, shop: ShopCreate):
    conn = database.get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT id FROM shops WHERE id = %s", (shop_id,))
    if not cursor.fetchone():
        conn.close()
        raise HTTPException(status_code=404, detail="Shop partner not found")
    try:
        cursor.execute(
            "UPDATE shops SET name = %s, owner_name = %s, workers = %s, workers_mobile = %s, location = %s, phone_number = %s WHERE id = %s",
            (shop.name, shop.owner_name, shop.workers, shop.workers_mobile, shop.location, shop.phone_number, shop_id)
        )
        conn.commit()
        conn.close()
        return {**shop.dict(), "id": shop_id}
    except Exception as e:
        conn.close()
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/api/shops/{shop_id}")
def delete_shop(shop_id: int):
    conn = database.get_db()
    cursor = conn.cursor()
    try:
        cursor.execute("DELETE FROM shops WHERE id = %s", (shop_id,))
        conn.commit()
        conn.close()
        return {"message": "Shop deleted successfully"}
    except Exception as e:
        conn.close()
        raise HTTPException(status_code=500, detail=str(e))

# Delivery Partners API
@app.get("/api/delivery", response_model=List[DeliveryResponse])
def get_delivery():
    conn = database.get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM delivery_partners ORDER BY id DESC")
    rows = cursor.fetchall()
    conn.close()
    return [dict(row) for row in rows]

@app.post("/api/delivery", response_model=DeliveryResponse)
def create_delivery(delivery: DeliveryCreate):
    conn = database.get_db()
    cursor = conn.cursor()
    try:
        cursor.execute(
            "INSERT INTO delivery_partners (name, mobile_number, location) VALUES (%s, %s, %s) RETURNING id",
            (delivery.name, delivery.mobile_number, delivery.location)
        )
        delivery_id = cursor.fetchone()['id']
        conn.commit()
        conn.close()
        return {**delivery.dict(), "id": delivery_id}
    except Exception as e:
        conn.close()
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/api/delivery/{partner_id}")
def delete_delivery(partner_id: int):
    conn = database.get_db()
    cursor = conn.cursor()
    try:
        cursor.execute("DELETE FROM delivery_partners WHERE id = %s", (partner_id,))
        conn.commit()
        conn.close()
        return {"message": "Delivery partner deleted successfully"}
    except Exception as e:
        conn.close()
        raise HTTPException(status_code=500, detail=str(e))

# Banners API
@app.get("/api/banners", response_model=List[BannerResponse])
def get_banners():
    conn = database.get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM banners ORDER BY id DESC")
    rows = cursor.fetchall()
    
    if not rows:
        # Seed initial default banners if DB table is empty
        initial_banners = [
            ("https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&q=80", "Quality Chicken", True),
            ("https://images.unsplash.com/photo-1603048588665-791ca8aea617?auto=format&fit=crop&q=80", "Quality Mutton", True),
            ("https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&q=80", "Online Meat Market", True),
        ]
        for img, title, active in initial_banners:
            now_iso = datetime.now().isoformat()
            cursor.execute(
                "INSERT INTO banners (image_url, title, is_active, created_at) VALUES (%s, %s, %s, %s)",
                (img, title, active, now_iso)
            )
        conn.commit()
        cursor.execute("SELECT * FROM banners ORDER BY id DESC")
        rows = cursor.fetchall()
        
    conn.close()
    return [dict(row) for row in rows]

@app.post("/api/banners", response_model=BannerResponse)
def create_banner(banner: BannerCreate):
    conn = database.get_db()
    cursor = conn.cursor()
    created_at = datetime.now().isoformat()
    try:
        cursor.execute(
            "INSERT INTO banners (image_url, title, is_active, created_at) VALUES (%s, %s, %s, %s) RETURNING id",
            (banner.image_url, banner.title, banner.is_active, created_at)
        )
        banner_id = cursor.fetchone()['id']
        conn.commit()
        conn.close()
        return {**banner.dict(), "id": banner_id, "created_at": created_at}
    except Exception as e:
        conn.close()
        raise HTTPException(status_code=500, detail=str(e))

@app.put("/api/banners/{banner_id}", response_model=BannerResponse)
def update_banner(banner_id: int, banner: BannerCreate):
    conn = database.get_db()
    cursor = conn.cursor()
    try:
        cursor.execute(
            "UPDATE banners SET image_url = %s, title = %s, is_active = %s WHERE id = %s RETURNING created_at",
            (banner.image_url, banner.title, banner.is_active, banner_id)
        )
        row = cursor.fetchone()
        if not row:
            conn.close()
            raise HTTPException(status_code=404, detail="Banner not found")
        created_at = row['created_at']
        conn.commit()
        conn.close()
        return {**banner.dict(), "id": banner_id, "created_at": created_at}
    except HTTPException:
        raise
    except Exception as e:
        conn.close()
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/api/banners/{banner_id}")
def delete_banner(banner_id: int):
    conn = database.get_db()
    cursor = conn.cursor()
    try:
        cursor.execute("DELETE FROM banners WHERE id = %s", (banner_id,))
        conn.commit()
        conn.close()
        return {"message": "Banner deleted successfully"}
    except Exception as e:
        conn.close()
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    uvicorn.run("main:app", host="0.0.0.0", port=port)


