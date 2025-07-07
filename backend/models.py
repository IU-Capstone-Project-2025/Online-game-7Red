from pydantic import BaseModel, EmailStr, Field

class SignUpRequest(BaseModel):
    """Request model for user registration."""
    nickname: str = Field(..., min_length=1)  # User's display name, minimum 1 character
    email: EmailStr  # User's email address (validated format)
    password: str = Field(..., min_length=6, max_length=16)  # User password with length constraints
    repeated_password: str = Field(..., min_length=6, max_length=16)  # Confirmation password

class SignInRequest(BaseModel):
    """Request model for user authentication."""
    email: EmailStr  # User's email address
    password: str  # User's password

class JoinRoomRequest(BaseModel):
    """Request model for joining a game room."""
    assigned_id: str = Field(..., min_length=5, max_length=5)  # Room identifier, exactly 5 characters
    password: str = Field(..., min_length=5, max_length=5)  # Room password, exactly 5 characters
    user_id: int  # User identifier of the player joining the room