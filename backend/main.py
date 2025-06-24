from fastapi import FastAPI
from backend.routers.auth import router as auth_router
from backend.routers.rooms import router as rooms_router
from backend.routers.game import router as game_router
from backend.routers.bot import router as bot_router
from backend.database import database
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],  
    allow_headers=["*"],
)

@app.on_event("startup")
async def startup():
    await database.connect()

@app.on_event("shutdown")
async def shutdown():
    await database.disconnect()

app.include_router(auth_router)
app.include_router(rooms_router)
app.include_router(game_router)
app.include_router(bot_router)


@app.get("/")
async def read_root():
    return {"message": "Hello World"}
