from typing import Optional
from sqlmodel import SQLModel, Field
from datetime import date
from pydantic import validator
from pydantic import root_validator
from datetime import datetime


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


class Histori(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    nama: str = Field(..., max_length=100)
    terjual: int = Field(default=0, ge=1)
    harga: int = Field(..., ge=0)
    total_harga: int = 0
    waktujual: datetime = Field(default_factory=datetime.utcnow)

    @root_validator(pre=True)
    def hitung_total(cls, values):
        harga = values.get('harga') or 0
        terjual = values.get('terjual') or 0    
        values['total_harga'] = harga * terjual
        return values

    
class BarangCreate(SQLModel):
    gambar: Optional[str]
    nama: str
    harga: int
    stok: int
    lokasi: str
    waktu: date
    jenis: Optional[str] = None
    terjual: int = 0
    waktujual: Optional[date] = None

    @validator('harga', 'stok')
    def must_be_positive(cls, v, field):
        if v < 0:
            raise ValueError(f"{field.name} tidak boleh negatif")
        return v

class BarangUpdate(SQLModel):
    nama: Optional[str] = None
    harga: Optional[int] = None
    stok: Optional[int] = None
    
    
from pydantic import BaseModel

class HistoriCreate(BaseModel):
    nama: str
    terjual: int
    harga: int
    waktujual: Optional[datetime] = None

class HistoriRead(BaseModel):
    id: int
    nama: str
    terjual: int
    harga: int
    total_harga: int
    waktujual: datetime

    class Config:
        orm_mode = True  
