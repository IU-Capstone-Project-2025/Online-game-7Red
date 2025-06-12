# testing functions for creating, deleting and searching rooms
import asyncio
from database import database, create_game_room, delete_game_room, search_game_room

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

    await database.disconnect()

if __name__ == "__main__":
    asyncio.run(test_create_and_delete())