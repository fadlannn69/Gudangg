from typing import Optional
from sqlmodel import SQLModel, Field, UniqueConstraint
from datetime import date, datetime


class Barang(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    gambar: Optional[str] = Field(default=None, max_length=255)
    nama: str = Field(..., max_length=100)
    harga: int
    stok: int
    lokasi: str = Field(..., max_length=100)
    waktu: date
    jenis: Optional[str] = Field(default=None, max_length=50)
    terjual: int = 0
    waktujual: Optional[date] = None


class BarangCreate(SQLModel):
    gambar: Optional[str]
    nama: str
    harga: int
    stok: int
    lokasi: str
    waktu: date
    jenis: Optional[str] = None


class BarangUpdate(SQLModel):
    nama: Optional[str] = None
    harga: Optional[int] = None
    stok: Optional[int] = None


class Histori(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    barang_id: int = Field(foreign_key="barang.id")
    terjual: int
    harga: int
    total_harga: int
    waktujual: datetime
    transaksi_id: str

    __table_args__ = (
        UniqueConstraint("transaksi_id", "barang_id", name="unique_transaksi_barang"),
    )


class HistoriCreate(SQLModel):
    terjual: int
    harga: int
    total_harga: int
    waktujual: Optional[datetime] = None
    transaksi_id: str

class HistoriRead(SQLModel):
    id: int
    terjual: int
    harga: int
    total_harga: int
    waktujual: datetime
    nama: str  # Tambahkan ini
