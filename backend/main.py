from fastapi import FastAPI
from backend.routers.auth import router as auth_router
from backend.routers.rooms import router as rooms_router

app = FastAPI()

app.include_router(auth_router)
app.include_router(rooms_router)

@app.get("/")
async def read_root():
    return {"message": "Hello World"}
