import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from fastapi.testclient import TestClient
from backend.main import app
import time

def test_signup_and_create_room():
    with TestClient(app) as client:
        unique_email = f"testuser_{int(time.time() * 1000)}@example.com"
        signup_data = {
            "email": unique_email,
            "password": "testpass",
            "repeated_password": "testpass",
            "nickname": "TestUser"
        }
        response = client.post("/auth/signup", json=signup_data)
        assert response.status_code == 200
        user_id = response.json()["user_id"]

        # Теперь создаём комнату с этим user_id
        response = client.post("/rooms/create", json={"user_id": user_id})
        assert response.status_code == 200
        data = response.json()
        assert "assigned_id" in data
        assert "password" in data
        assert len(data["assigned_id"]) == 5
        assert len(data["password"]) == 5
        
def test_signup():
    with TestClient(app) as client:
        unique_email = f"testuser_{int(time.time() * 1000)}@example.com"
        signup_data = {
            "email": unique_email,
            "password": "testpass",
            "repeated_password": "testpass",
            "nickname": "TestUser"
        }
        response = client.post("/auth/signup", json=signup_data)
        assert response.status_code == 200
        data = response.json()
        assert data["message"] == "User reqistered succesfully"
        assert "user_id" in data

        # again register the same user
        response = client.post("/auth/signup", json=signup_data)
        assert response.status_code == 400
        assert response.json()["detail"] == "Email already registered"
        
        # with password != repeated_password
        signup_data["email"] = f"testuser_{int(time.time() * 1000)+1}@example.com"
        signup_data["repeated_password"] = "wrongpass"
        response = client.post("/auth/signup", json=signup_data)
        assert response.status_code == 400
        assert response.json()["detail"] == "Passwords do not match"
        
def test_player_is_ready():
    with TestClient(app) as client:
        unique_email = f"testuser_{int(time.time() * 1000)}@example.com"
        signup_data = {
            "email": unique_email,
            "password": "testpass",
            "repeated_password": "testpass",
            "nickname": "TestUser"
        }
        
        response = client.post("/auth/signup", json=signup_data)
        assert response.status_code == 200
        user_id = response.json()["user_id"]
        
        # create the room
        response = client.post("/rooms/create", json={"user_id": user_id})
        assert response.status_code == 200
        assigned_id = response.json()["assigned_id"]
        
        # send ready
        ready = {"user_id": user_id, "assigned_id": assigned_id}
        response = client.post("/rooms/ready", json=ready)
        assert response.status_code == 200
        assert f"Player {user_id} is ready in room {assigned_id}" in response.json()["message"]
    
def test_leave_room():
    with TestClient(app) as client:
        unique_email = f"testuser_{int(time.time() * 1000)}@example.com"
        signup_data = {
            "email": unique_email,
            "password": "testpass",
            "repeated_password": "testpass",
            "nickname": "TestUser"
        }
        response = client.post("/auth/signup", json=signup_data)
        assert response.status_code == 200
        user_id = response.json()["user_id"]

        # create room
        response = client.post("/rooms/create", json={"user_id": user_id})
        assert response.status_code == 200
        assigned_id = response.json()["assigned_id"]

        # send ready
        ready = {"user_id": user_id, "assigned_id": assigned_id}
        response = client.post("/rooms/ready", json=ready)
        assert response.status_code == 200

        # leave room
        leave = {"user_id": user_id, "assigned_id": assigned_id}
        response = client.post("/rooms/leave", json=leave)
        assert response.status_code == 200
        assert f"User {user_id} left room {assigned_id}" in response.json()["message"]
        