from typing import Optional
from sqlmodel import SQLModel, Field
from datetime import date

class Barang(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    gambar: Optional[str]
    nama: str
    harga: int
    stok: int
    lokasi : str
    waktu: date
    jenis: Optional[str] = None

class BarangUpdate(SQLModel):  
    nama: Optional[str] = None
    harga: Optional[int] = None
    stok: Optional[int] = None
    

class BarangCreate(SQLModel):
    gambar: Optional[str]
    nama: str
    harga: int
    stok: int
    lokasi: str
    waktu: date
    jenis: Optional[str] = None 