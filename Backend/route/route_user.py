from fastapi import APIRouter, Depends, UploadFile, File, HTTPException, Form
from sqlmodel import select, Session
from database import get_session
from model.model_user import User, LoginInput, find_user
from auth import AuthHandler
import numpy as np
import face_recognition
from PIL import Image
import io
import shutil
import json
import os


auth_handler = AuthHandler()
user = APIRouter()


@user.post("/register")
def register(user: User, session: Session = Depends(get_session)):
    user.password = auth_handler.get_password_hash(user.password)
    session.add(user)
    session.commit()
    session.refresh(user)
    return {"message": "User registered successfully"}


@user.post("/login")
def login(auth_details: LoginInput, session: Session = Depends(get_session)):
    user = find_user(auth_details.nik, session)
    if (user is None) or (not auth_handler.verify_password(auth_details.password, user.password)):
        raise HTTPException(status_code=401, detail="Invalid credentials")

    token = auth_handler.encode_token(user.nik)
    return {"token": token}

@user.post("/register-face")
async def register_face(
    nik: int = Form(...),
    file: UploadFile = File(...),
    db: Session = Depends(get_session)
):
    try:
        import shutil, os  

        temp_path = f"temp_{file.filename}"
        with open(temp_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        image = face_recognition.load_image_file(temp_path)
        face_encodings = face_recognition.face_encodings(image)

        if len(face_encodings) == 0:
            raise HTTPException(status_code=400, detail="No face detected in the image.")

        face_encoding = face_encodings[0]

        user = db.query(User).filter(User.nik == nik).first()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        user.face_encoding = face_encoding.tolist()
        db.commit()

        os.remove(temp_path)

        return {"message": "Face registered successfully"}

    except Exception as e:
        print("🔥 ERROR register-face:", str(e))
        raise HTTPException(status_code=500, detail=f"Internal Server Error: {str(e)}")


@user.post("/verify-face")
async def verify_face(
    nik: int = Form(...),
    file: UploadFile = File(...),
    db: Session = Depends(get_session)
):
    temp_path = f"temp_{file.filename}"
    try:
        with open(temp_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        image = face_recognition.load_image_file(temp_path)
        face_encodings = face_recognition.face_encodings(image)

        if not face_encodings:
            raise HTTPException(status_code=400, detail="No face detected in the image.")

        input_encoding = face_encodings[0]

        user = db.query(User).filter(User.nik == nik).first()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        face_data = user.face_encoding

        # Periksa format face_data
        if isinstance(face_data, str):
            try:
                face_data = json.loads(face_data)
            except Exception:
                raise HTTPException(status_code=500, detail="Corrupted face encoding (invalid JSON string)")
        elif isinstance(face_data, list):
            pass
        else:
            raise HTTPException(status_code=500, detail="Corrupted face encoding (unknown format)")

        # Bandingkan wajah
        match_result = face_recognition.compare_faces([np.array(face_data)], input_encoding)

        if match_result[0]:
            return {"message": "Face verified successfully"}
        else:
            raise HTTPException(status_code=401, detail="Face verification failed")

    except HTTPException:
        raise
    except Exception as e:
        print("🔥 ERROR verify-face:", str(e))
        raise HTTPException(status_code=500, detail=f"Internal Server Error: {str(e)}")
    finally:
        if os.path.exists(temp_path):
            os.remove(temp_path)
