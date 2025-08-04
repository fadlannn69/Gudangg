from sqlmodel import SQLModel, Field , select ,Session
from database import get_session
from fastapi import Depends
from pydantic import BaseModel
from typing import Optional, List


class User(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    nik: int
    nama: str
    email: str
    password: str
    

class LoginInput(BaseModel):
    nik: int
    password: str

def find_user(nik: int, session: Session): 
    statement = select(User).where(User.nik == nik)
    return session.exec(statement).first()
