#importing necessary libraries/functions 
from fastapi import APIRouter, UploadFile, File, HTTPException, status
from fastapi.responses import JSONResponse, Response
import os
from contextlib import asynccontextmanager
from PIL import Image
import io
from app.database import update_avatar, get_avatar_from_db, delete_avatar_from_db
import paramiko
from dotenv import load_dotenv

#creating FastAPI router for endpoints for profile page data retrieval
router = APIRouter(prefix="/api/profile_page", tags=["Profile page"])

#loading environment variables from .env file
# load_dotenv(os.path.join(os.path.dirname(__file__), '../database/.env'))
load_dotenv(os.path.join(os.path.dirname(__file__), '../../.env'))

#getting server related data from environment variables
SERVER_PW = os.getenv("SERVER_PW")

#configuration
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg'}
MAX_FILE_SIZE = 2 * 1024 * 1024  # 2MB

#function that checks correct file format
def allowed_file(filename: str) -> bool:
    return "." in filename and filename.rsplit(".", 1)[1].lower() in ALLOWED_EXTENSIONS

#function that processes uploaded image
async def process_image(file: UploadFile):
    #verifying file size
    file_size = 0
    for chunk in file.file:
        file_size += len(chunk)
        if file_size > MAX_FILE_SIZE:
            raise HTTPException(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                detail="File too large"
            )
    
    #reseting file pointer after size check
    await file.seek(0)
    
    #reading and processing image
    contents = await file.read()
    try:
        image = Image.open(io.BytesIO(contents))
        
        #converting to RGB if needed (for JPEG)
        if image.mode != 'RGB':
            image = image.convert('RGB')
            
        #resizing to maximum 500x500 while maintaining aspect ratio
        image.thumbnail((500, 500))
        
        #saving processed image to bytes
        byte_arr = io.BytesIO()
        image.save(byte_arr, format='JPEG', quality=85)
        return byte_arr.getvalue()
    
    #handling exceptions 
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid image file: {str(e)}"
        )

#function for uploading an image to the remote server
async def upload_to_remote_server(file_content: bytes, filename: str):
    """Uploads a file to remote server via SFTP"""
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        #connecting to remote server
        ssh.connect(
            hostname="192.145.30.253",
            username="root",
            password=SERVER_PW,
            port=22,
        )
        
        #uploading file via SFTP
        sftp = ssh.open_sftp()
        
        #defining the remote path
        remote_dir = "/root/7RED/avatars"
        remote_path = f"{remote_dir}/{filename}"
        
        #ensuring the directory exists
        try:
            sftp.stat(remote_dir)  #checking if directory exists
        except FileNotFoundError:
            sftp.mkdir(remote_dir)  #creating if it doesn't exist
        
        #writing the file
        with sftp.file(remote_path, "wb") as remote_file:
            remote_file.write(file_content)
        
        #return a URL to photo
        return filename

    #handling exceptions 
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"SFTP upload failed: {str(e)}"
        )
    #closing server connection
    finally:
        if 'sftp' in locals(): sftp.close()
        ssh.close()

#endpoint for uploading avatar image
@router.post("/upload-avatar/{user_id}")
async def upload_avatar(user_id: int, file: UploadFile = File(...)):
    #validating and processing the image
    processed_image = await process_image(file)
    #processing the image's name and format
    ext = file.filename.split(".")[-1].lower()
    filename = f"avatar_{user_id}.{ext}"

    #uploading to remote server
    avatar_url = await upload_to_remote_server(processed_image, filename)
    
    #updating database with remote URL
    await update_avatar(user_id, avatar_url)
    
    return JSONResponse({
        "status": "success",
        "avatar_url": avatar_url,
        "message": "Avatar uploaded to remote server"
    })

#function for managing SFTP connection to remote server
@asynccontextmanager
async def sftp_connection():
    """Context manager for SFTP connection"""
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    try:
        ssh.connect(
            hostname="192.145.30.253",
            username="root",
            password=SERVER_PW,
            timeout=10
        )
        sftp = ssh.open_sftp()
        try:
            yield sftp
        finally:
            sftp.close()
    finally:
        ssh.close()

#endpoint for retrieving avatar image
@router.get("/get-avatar/{user_id}")
async def get_avatar(user_id: int):
    filename = await get_avatar_from_db(user_id)
    if not filename:
        raise HTTPException(status_code=404, detail="Avatar not found")

    async with sftp_connection() as sftp:
        remote_path = f"/root/7RED/avatars/{filename}"
        
        try:
            #verifying avatar exists
            sftp.stat(remote_path)
        except FileNotFoundError:
            raise HTTPException(status_code=404, detail="Avatar not found")

        #reading entire file into memory (for small files)
        with sftp.file(remote_path, "rb") as file_obj:
            file_content = file_obj.read()

        ext = filename.split('.')[-1].lower()
        media_type = f"image/{ext}" if ext in ['jpeg', 'jpg', 'png'] else 'application/octet-stream'
        
        #returning avatar image (raw binary data)
        return Response(
            content=file_content,
            media_type=media_type,
            headers={"Content-Disposition": f"inline; filename={filename}"}
        )

#endpoint for deleting avatar image
@router.delete("/delete-avatar/{user_id}")
async def delete_avatar(user_id: int):
    """
    Delete user avatar from SFTP server and database
    Returns 404 if avatar not found, 200 on success
    """
    #getting filename from database
    filename = await get_avatar_from_db(user_id)
    if not filename:
        raise HTTPException(status_code=404, detail="No avatar record found")

    async with sftp_connection() as sftp:
        remote_path = f"/root/7RED/avatars/{filename}"
        
        try:
            #checking if file exists
            sftp.stat(remote_path)
            
            #deleting the file
            sftp.remove(remote_path)
            
            #updating database
            await delete_avatar_from_db(user_id)
            
            return JSONResponse(
                {"status": "success", "message": "Avatar deleted successfully"}
            )
            
        #exception handling
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Failed to delete avatar: {str(e)}"
            )