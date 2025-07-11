from fastapi import APIRouter, HTTPException
from app.models import SignInRequest, SignUpRequest
from passlib.context import CryptContext
from app.database import (add_visit, create_user_statistics, create_user, search_user_by_login, create_profile, get_profile_by_user_id, check_and_award_7_days_streak)

router = APIRouter(prefix="/api/auth", tags=["auth"])

# Set up password hashing with bcrypt
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


@router.post("/signup")
async def signup(request: SignUpRequest):
    """
    Handle user registration.
    Takes user email, password, and nickname.
    Creates a new user account and profile if validation passes.
    """
    # Check if the user already registered
    exist = await search_user_by_login(request.email)
    if exist:
        raise HTTPException(status_code=400, detail="Email already registered")
    if request.password != request.repeated_password:
        raise HTTPException(status_code=400, detail="Passwords do not match")
    
    # Create safe hash of password before saving to database
    hashed_password = pwd_context.hash(request.password)
    # Create user in database and get the new user ID
    user_id = await create_user(request.email, hashed_password)
    await create_user_statistics(user_id)
    # Create profile associated with the new user
    await create_profile(user_id, request.nickname)
    
    return {"message": "User reqistered succesfully", "user_id": user_id}


@router.post("/signin")
async def signin(request: SignInRequest):
    """
    Handle user authentication.
    Validates credentials and returns user info if successful.
    Also tracks user visits and checks for achievement conditions.
    """
    # Search for user in database
    user = await search_user_by_login(request.email)
    if not user:
        raise HTTPException(status_code=401, detail="Invalid email or password")
    
    # Verify password against stored hash
    if not pwd_context.verify(request.password, user["password"]):
        raise HTTPException(status_code=401, detail="Invalid email or password")
    
    # Record this login as a visit
    await add_visit(user["id"])

    # Check if user has earned the 7-day streak achievement
    await check_and_award_7_days_streak(user["id"])
    
    # Get the user's profile information
    profile = await get_profile_by_user_id(user["id"])
    nickname = profile["name"] if profile else None
    
    return {
        "message": "Sign in succesfully", 
        "user_id": user["id"],
        "nickname": nickname
    }
