# testing functions for creating, deleting and searching rooms and users
import asyncio
from database import database, create_game_room, delete_game_room, search_game_room, create_user, delete_user, search_user_by_id, search_user_by_login

async def test_create_and_delete():
    await database.connect()

    # create a game room
    room_id = await create_game_room("test123", "secret")
    print("Created room with ID:", room_id)

    # search for the game room
    game = await search_game_room("test123")
    print("Found game:", dict(game) if game else None)

    # delete the game room
    if game:
        await delete_game_room(game["room_id"])
        print("Deleted game room.")

    # search again after deletion
    game = await search_game_room("test123")
    print("After deletion, found:", game)


    # create a user
    user_id = await create_user("testABC", "secret")
    print("Created user with ID:", user_id)

    # search for the user
    user = await search_user_by_id(user_id)
    print("Found user:", dict(user) if user else None)

    # delete the user
    if user:
        await delete_user(user_id)
        print("Deleted user") 

    # search again after deletion
    user = await search_user_by_id(user_id)
    print("After deletion, found:", user)

    await database.disconnect()

if __name__ == "__main__":
    asyncio.run(test_create_and_delete())