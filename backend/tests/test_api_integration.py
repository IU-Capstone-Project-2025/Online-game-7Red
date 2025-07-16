import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from fastapi.testclient import TestClient
from app.main import app
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
        response = client.post("/api/auth/signup", json=signup_data)
        assert response.status_code == 200
        user_id = response.json()["user_id"]

        # Теперь создаём комнату с этим user_id
        response = client.post("/api/rooms/create", json={"user_id": user_id})
        assert response.status_code == 200
        data = response.json()
        assert "assigned_id" in data
        assert "password" in data
        assert len(data["assigned_id"]) == 5
        assert len(data["password"]) == 5
        leave = {"user_id": user_id, "assigned_id": data["assigned_id"]}
        response = client.post("/api/rooms/leave", json=leave)
        if response.status_code not in (200, 404):
            assert False, f"Unexpected status code: {response.status_code}"

        response = client.post("/api/auth/delete", json={"user_id": user_id})
        if response.status_code not in (200, 404):
            assert False, f"Unexpected status code: {response.status_code}"
        
def test_signup():
    with TestClient(app) as client:
        unique_email = f"testuser_{int(time.time() * 1000)}@example.com"
        signup_data = {
            "email": unique_email,
            "password": "testpass",
            "repeated_password": "testpass",
            "nickname": "TestUser"
        }
        response = client.post("/api/auth/signup", json=signup_data)
        assert response.status_code == 200
        data = response.json()
        assert data["message"] == "User reqistered succesfully"
        assert "user_id" in data
        user_id = data["user_id"]

        # again register the same user
        response = client.post("/api/auth/signup", json=signup_data)
        assert response.status_code == 400
        assert response.json()["detail"] == "Email already registered"
        
        # with password != repeated_password
        signup_data["email"] = f"testuser_{int(time.time() * 1000)+1}@example.com"
        signup_data["repeated_password"] = "wrongpass"
        response = client.post("/api/auth/signup", json=signup_data)
        assert response.status_code == 400
        assert response.json()["detail"] == "Passwords do not match"
        response = client.post("/api/auth/delete", json={"user_id": user_id})
        if response.status_code not in (200, 404):
            assert False, f"Unexpected status code: {response.status_code}"
        
def test_player_is_ready():
    with TestClient(app) as client:
        unique_email = f"testuser_{int(time.time() * 1000)}@example.com"
        signup_data = {
            "email": unique_email,
            "password": "testpass",
            "repeated_password": "testpass",
            "nickname": "TestUser"
        }
        
        response = client.post("/api/auth/signup", json=signup_data)
        assert response.status_code == 200
        user_id = response.json()["user_id"]
        
        # create the room
        response = client.post("/api/rooms/create", json={"user_id": user_id})
        assert response.status_code == 200
        assigned_id = response.json()["assigned_id"]
        
        # send ready
        ready = {"user_id": user_id, "assigned_id": assigned_id}
        response = client.post("/api/rooms/ready", json=ready)
        assert response.status_code == 200
        assert f"Player {user_id} is ready in room {assigned_id}" in response.json()["message"]
        leave = {"user_id": user_id, "assigned_id": assigned_id}
        response = client.post("/api/rooms/leave", json=leave)
        if response.status_code not in (200, 404):
            assert False, f"Unexpected status code: {response.status_code}"

        response = client.post("/api/auth/delete", json={"user_id": user_id})
        if response.status_code not in (200, 404):
            assert False, f"Unexpected status code: {response.status_code}"
    
def test_leave_room():
    with TestClient(app) as client:
        unique_email = f"testuser_{int(time.time() * 1000)}@example.com"
        signup_data = {
            "email": unique_email,
            "password": "testpass",
            "repeated_password": "testpass",
            "nickname": "TestUser"
        }
        response = client.post("/api/auth/signup", json=signup_data)
        assert response.status_code == 200
        user_id = response.json()["user_id"]

        # create room
        response = client.post("/api/rooms/create", json={"user_id": user_id})
        assert response.status_code == 200
        assigned_id = response.json()["assigned_id"]

        # send ready
        ready = {"user_id": user_id, "assigned_id": assigned_id}
        response = client.post("/api/rooms/ready", json=ready)
        assert response.status_code == 200

        # leave room
        leave = {"user_id": user_id, "assigned_id": assigned_id}
        response = client.post("/api/rooms/leave", json=leave)
        if response.status_code not in (200, 404):
            assert False, f"Unexpected status code: {response.status_code}"

        response = client.post("/api/auth/delete", json={"user_id": user_id})
        if response.status_code not in (200, 404):
            assert False, f"Unexpected status code: {response.status_code}"

def test_signin():
    with TestClient(app) as client:
        unique_email = f"testuser_{int(time.time() * 1000)}@example.com"
        signup_data = {
            "email": unique_email,
            "password": "testpass",
            "repeated_password": "testpass",
            "nickname": "TestUser"
        }
        response = client.post("/api/auth/signup", json=signup_data)
        assert response.status_code == 200
        user_id = response.json()["user_id"]

        signin_data = {
            "email": unique_email,
            "password": "testpass"
        }
        response = client.post("/api/auth/signin", json=signin_data)
        assert response.status_code == 200
        data = response.json()
        assert data["message"] == "Sign in succesfully"
        assert data["user_id"] == user_id
        assert data["nickname"] == "TestUser"

        response = client.post("/api/auth/signin", json={
            "email": unique_email,
            "password": "wrongpass"
        })
        assert response.status_code == 401
        assert response.json()["detail"] == "Invalid email or password"

        response = client.post("/api/auth/signin", json={
            "email": "notfound@example.com",
            "password": "testpass"
        })
        assert response.status_code == 401
        assert response.json()["detail"] == "Invalid email or password"
        response = client.post("/api/auth/delete", json={"user_id": user_id})
        if response.status_code not in (200, 404):
            assert False, f"Unexpected status code: {response.status_code}"