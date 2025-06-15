from pydantic import BaseModel, EmailStr, Field


# does all fields required?
class SignUpRequest(BaseModel):
    nickname: str = Field(..., min_length=1)
    email: EmailStr
    password: str = Field(..., min_length=6)
    repeated_password: str = Field(..., min_length=6)

class SignInRequest(BaseModel):
    email: EmailStr
    password: str

# id of rooms only numbers or no?min length

class CreateRoomRequest(BaseModel):
    room_id: str = Field(..., min_length=1)
    password: str = Field(..., min_length=5)
    
class JoinRoomRequest(BaseModel):
    room_id: str = Field(..., min_length=1)
    password: str = Field(..., min_length=5)