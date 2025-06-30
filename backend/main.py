from fastapi import FastAPI
from contextlib import asynccontextmanager
from backend.routers.auth import router as auth_router
from backend.routers.rooms import router as rooms_router
from backend.routers.game import router as game_router
#from backend.routers.bot import router as bot_router
#from backend.routers.game_bot import router as ai_game_router
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



@asynccontextmanager
async def lifespan(app: FastAPI):
    await database.connect()
    yield
    await database.disconnect()

app = FastAPI(lifespan=lifespan)

app.include_router(auth_router)
app.include_router(rooms_router)
app.include_router(game_router)
#app.include_router(bot_router)
#app.include_router(ai_game_router)


@app.get("/")
async def read_root():
    return {"message": "Hello World"}
