from sqlmodel import SQLModel, Field , select ,Session
from database import get_session
from fastapi import Depends
from pydantic import BaseModel
from typing import Optional, List
from sqlalchemy import Column, JSON

class User(SQLModel, table=True):
    id: int = Field(default=None, primary_key=True)
    nik: int
    nama: str
    email: str
    password: str
    face_encoding: Optional[List[float]] = Field(
        default=None,
        sa_column=Column(JSON)
    )


class LoginInput(BaseModel):
    nik: int
    password: str

def find_user(nik: int, session: Session): 
    statement = select(User).where(User.nik == nik)
    return session.exec(statement).first()
