from fastapi import FastAPI
from contextlib import asynccontextmanager
from backend.routers.auth import router as auth_router
from backend.routers.rooms import router as rooms_router
from backend.routers.game import router as game_router
from backend.routers import settings as setting_router

#from backend.routers.bot import router as bot_router
#from backend.routers.game_bot import router as ai_game_router 
from backend.database import database
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
app.include_router(auth_router)
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
app.include_router(setting_router)
#app.include_router(bot_router)  # Bot-related routes 
#app.include_router(ai_game_router)  # AI game routes 

# Define root endpoint
@app.get("/")
async def read_root():
    return {"message": "Hello World"}
