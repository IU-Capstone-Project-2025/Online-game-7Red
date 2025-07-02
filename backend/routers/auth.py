from fastapi import APIRouter, HTTPException
from backend.models import SignInRequest, SignUpRequest
from backend.database import create_user, search_user_by_login, create_profile, get_profile_by_user_id
from passlib.context import CryptContext
from backend.database import add_visit, get_visit_streak, award_achievement_if_needed, get_achievement_id_by_name

router = APIRouter(prefix="/auth", tags=["auth"])

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


@router.post("/signup")
async def signup(request: SignUpRequest):
    # Check if the user alredy registered
    exist = await search_user_by_login(request.email)
    if exist:
        raise HTTPException(status_code=400, detail="Email already registered")
    if request.password != request.repeated_password:
        raise HTTPException(status_code=400, detail="Passwords do not match")
    # create safe hash of password before saving to database
    hashed_password = pwd_context.hash(request.password)
    user_id = await create_user(request.email, hashed_password)
    await create_profile(user_id, request.nickname)
    return {"message": "User reqistered succesfully", "user_id": user_id}


@router.post("/signin")
async def signin(request: SignInRequest):
    user = await search_user_by_login(request.email)
    if not user:
        raise HTTPException(status_code=401, detail="Invalid email or password")
    if not pwd_context.verify(request.password, user["password"]):
        raise HTTPException(status_code=401, detail="Invalid email or password")
    
    await add_visit(user["id"])
    
    streak = await get_visit_streak(user["id"])
    if streak >= 7:
        achievement_id = await get_achievement_id_by_name("7_days_streak")
        if achievement_id:
            awarded = await award_achievement_if_needed(user["id"], achievement_id)
            if awarded:
                new_achievement = "7_days_streak"
    
    profile = await get_profile_by_user_id(user["id"])
    nickname = profile["name"] if profile else None
    return {
        "message": "Sign in succesfully", 
        "user_id": user["id"],
        "nickname": nickname
        }
    



