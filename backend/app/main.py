import logging
from logging.handlers import RotatingFileHandler
import sys
import os

def setup_logging():
    log_dir = "logs"
    os.makedirs(log_dir, exist_ok=True)
    
    # Unified handler for ALL logs
    file_handler = RotatingFileHandler(
        filename=os.path.join(log_dir, 'server.log'),
        maxBytes=5*1024*1024,  # 5MB
        backupCount=3,
        encoding='utf-8'
    )
    file_handler.setFormatter(
        logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    )

    # Console handler (for real-time viewing)
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setFormatter(
        logging.Formatter('%(asctime)s - %(message)s')
    )

    # Configure root logger (captures everything)
    logging.basicConfig(
        level=logging.INFO,
        handlers=[file_handler, console_handler]
    )

    # Redirect Uvicorn access logs to root logger
    uvicorn_access = logging.getLogger("uvicorn.access")
    uvicorn_access.handlers.clear()
    uvicorn_access.addHandler(file_handler)
    uvicorn_access.addHandler(console_handler)
    uvicorn_access.propagate = False

setup_logging()


from fastapi import FastAPI
from contextlib import asynccontextmanager
from app.routers.auth import router as auth_router
from app.routers.rooms import router as rooms_router
from app.routers.game import router as game_router
from app.routers.game_bot import router as ai_game_router
from app.routers.settings import router as setting_router
from app.routers.avatar import router as avatar_router
from app.database import database
from fastapi.middleware.cors import CORSMiddleware

# Define async context manager for database connection lifecycle management
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Connect to the database when the application starts
    await database.connect()
    yield  # Yield control back to FastAPI
    # Disconnect from the database when the application shuts down
    await database.disconnect()

# Create FastAPI application instance with database lifecycle management
app = FastAPI(lifespan=lifespan)

# Add CORS middleware to allow cross-origin requests
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow requests from all origins (consider restricting in production)
    allow_credentials=True,
    allow_methods=["*"],  # Allow all HTTP methods
    allow_headers=["*"],  # Allow all headers
)

# Register route handlers from different modules
app.include_router(auth_router)  # Authentication routes
app.include_router(rooms_router)  # Room management routes
app.include_router(game_router)  # Game functionality routes
app.include_router(setting_router) # Routes for user statistics
app.include_router(ai_game_router)  # AI game routes 
app.include_router(avatar_router) # Avatar upload routes


# Define root endpoint
@app.get("/")
async def read_root():
    return {"message": "Hello World"}
