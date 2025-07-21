import time
import psycopg2
from psycopg2 import OperationalError
import os
from dotenv import load_dotenv

load_dotenv()

DB_NAME = os.getenv("POSTGRES_DB", "gudkoptell")
DB_USER = os.getenv("POSTGRES_USER", "koptel")
DB_PASS = os.getenv("POSTGRES_PASSWORD", "koptel2018")
DB_HOST = os.getenv("DB_HOST", "db")
DB_PORT = os.getenv("DB_PORT", "5432")

print(f"Menunggu DB: {DB_USER}@{DB_HOST}:{DB_PORT}/{DB_NAME}")

while True:
    try:
        conn = psycopg2.connect(
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASS,
            host=DB_HOST,
            port=DB_PORT
        )
        conn.close()
        print(" Database siap!")
        break
    except OperationalError as e:
        print("Database belum siap, tunggu 1 detik...", str(e))
        time.sleep(1)
