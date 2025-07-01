from pydantic import BaseModel, EmailStr, Field

class SignUpRequest(BaseModel):
    nickname: str = Field(..., min_length=1)
    email: EmailStr
    password: str = Field(..., min_length=6)
    repeated_password: str = Field(..., min_length=6)

class SignInRequest(BaseModel):
    email: EmailStr
    password: str
    
class JoinRoomRequest(BaseModel):
    assigned_id: str = Field(..., min_length=5, max_length=5)
    password: str = Field(..., min_length=5, max_length=5)
    user_id: int