from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session
from database import get_session
from model.model_user import User, LoginInput, find_user
from auth import AuthHandler


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
