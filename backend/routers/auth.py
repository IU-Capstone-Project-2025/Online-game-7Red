from fastapi import APIRouter
from backend.models import SignInRequest, SignUpRequest

router = APIRouter(prefix="/auth", tags=["auth"])

@router.post("/signup")
async def signup(request: SignUpRequest):
    #
    return {"message": "Not implemented yet"}


@router.post("/signin")
async def signin(request: SignInRequest):
    #
    return {"message": "Not implemented yet"}

