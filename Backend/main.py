from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from route.route_barang import barang
from route.route_user import user
from database import engine
from sqlmodel import SQLModel

app = FastAPI()

@app.on_event("startup")
def on_startup():
    SQLModel.metadata.create_all(engine)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


app.include_router(user , prefix = '/user' , tags=['User'])
app.include_router(barang, prefix='/barang', tags=['Barang'])  