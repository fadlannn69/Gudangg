from fastapi import APIRouter, Depends, HTTPException,Query,File,Form,UploadFile
from sqlmodel import select , Session 
from database import get_session, engine 
from model.model_barang import Barang, SQLModel ,BarangUpdate , BarangCreate
from auth import AuthHandler
from fastapi.responses import FileResponse ,StreamingResponse
from openpyxl import Workbook
import os
from openpyxl.styles import Font, Border, Side, Alignment
import qrcode
from sqlalchemy import func
from io import BytesIO
from datetime import datetime
from typing import List , Optional
from uuid import uuid4

auth_handler = AuthHandler()
barang = APIRouter()


@barang.get("/{nama}/qrcode")
def generate_qrcode(nama: str, session: Session = Depends(get_session)):
    
    print("Mencari barang dengan nama:", nama)
    
    barang_data = session.exec(
        select(Barang).where(func.lower(Barang.nama) == nama.lower())
    ).first()
    
    print("Hasil pencarian:", barang_data)

    if not barang_data:
        return {"error": "Barang tidak ditemukan"}

    qr_data = f"Nama Barang: {barang_data.nama}\nHarga Barang: Rp{barang_data.harga}\nLokasi Penempatan Barang: {barang_data.lokasi}\nWaktu Pembelian Barang: {barang_data.waktu}\nJenis Barang: {barang_data.jenis}"

    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_H,
        box_size=10,
        border=4,
    )
    qr.add_data(qr_data)
    qr.make(fit=True)

    img = qr.make_image(fill_color="black", back_color="white")

    img_io = BytesIO()
    img.save(img_io, format='PNG')
    img_io.seek(0)

    return StreamingResponse(img_io, media_type="image/png")


@barang.get("/laporan/export-excel")
def export_barang_excel(session: Session = Depends(get_session)):
    barangs = session.exec(select(Barang)).all()
    
    waktu = datetime.now()
    tgl= waktu.date()
    wb = Workbook()
    ws = wb.active
    ws.title = f"Laporan Barang Tanggal {tgl}"

    border = Border(
        left=Side(style='thin'),
        right=Side(style='thin'),
        top=Side(style='thin'),
        bottom=Side(style='thin')
    )

    headers = ["Nama Barang", "Harga Barang(Rp)", "Stok Barang(Pcs)", "Lokasi Penempatan Barang" , "Waktu Pembelian Barang" , "jenis Barang"]
    ws.append(headers)

    for col_num, column_title in enumerate(headers, 1):
        cell = ws.cell(row=1, column=col_num)
        cell.font = Font(bold=True)
        cell.border = border
        cell.alignment = Alignment(horizontal='center')

    for row_num, item in enumerate(barangs, 2):
        row_data = [item.nama, item.harga, item.stok,item.lokasi , item.waktu , item.jenis]
        for col_num, value in enumerate(row_data, 1):
            cell = ws.cell(row=row_num, column=col_num, value=value)
            cell.border = border
            cell.alignment = Alignment(horizontal='left')

    for column_cells in ws.columns:
        length = max(len(str(cell.value)) if cell.value else 0 for cell in column_cells)
        ws.column_dimensions[column_cells[0].column_letter].width = length + 2

    stream = BytesIO()
    wb.save(stream)
    stream.seek(0)

    return StreamingResponse(
        stream,
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={"Content-Disposition": "attachment; filename=laporan_barang.xlsx"}
    )

UPLOAD_DIR = "uploaded_images"
os.makedirs(UPLOAD_DIR, exist_ok=True)

@barang.post("/tambah")
async def tambah_barang(
    nama: str = Form(...),
    harga: int = Form(...),
    stok: int = Form(...),
    gambar: UploadFile = File(None),
    session: Session = Depends(get_session)
):
    filename = None

    if gambar:
        ext = gambar.filename.split(".")[-1].lower()
        if ext not in {"jpg", "jpeg", "png"}:
            raise HTTPException(status_code=400, detail="Format gambar tidak valid")
        
        # Buat nama unik dan path file
        filename = f"{uuid4()}.{ext}"
        filepath = os.path.join(UPLOAD_DIR, filename)

        try:
            with open(filepath, "wb") as f:
                shutil.copyfileobj(gambar.file, f)
        except Exception as e:
            raise HTTPException(status_code=500, detail="Gagal menyimpan gambar")

    # Simpan data barang ke DB
    barang = Barang(nama=nama, harga=harga, stok=stok, gambar=filename)
    session.add(barang)
    session.commit()
    session.refresh(barang)
    return barang


@barang.get("/ambil", response_model=List[Barang])
def get_barang(
    skip: int = Query(0, ge=0),
    limit: int = Query(10, ge=1),
    jenis: Optional[str] = None,
    session: Session = Depends(get_session)
):
    query = select(Barang)
    if jenis:
        query = query.where(Barang.jenis == jenis)
    barang = session.exec(query.offset(skip).limit(limit)).all()
    return barang


@barang.put("/update/{nama}")
def update_barang(nama: str, updated_barang: BarangUpdate,session = Depends(get_session)):
    existing_barang = session.exec(select(Barang).where(Barang.nama == nama)).first()

    if not existing_barang:
        raise HTTPException(status_code=404, detail="Barang tidak ditemukan")

    if updated_barang.harga is not None:
        existing_barang.harga = updated_barang.harga
    if updated_barang.stok is not None:
        existing_barang.stok = updated_barang.stok

    session.add(existing_barang)
    session.commit()
    session.refresh(existing_barang)

    return {"detail": f"Barang '{nama}' berhasil diperbarui"}


@barang.delete("/hapus/{nama}")
def delete_barang(nama:str, session=Depends(get_session)):
    existing_barang = session.exec(select(Barang).where(Barang.nama == nama)).first()
    if not existing_barang:
        raise HTTPException(status_code=404, detail="Barang tak ditemukan")
    
    session.delete(existing_barang)         
    session.commit()
    return {"detail": f"{existing_barang.nama} berhasil dihapus"}
