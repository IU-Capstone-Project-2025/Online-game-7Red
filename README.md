# Online-game-7Red
## Project description

The application includes the following core components:

1) User Authentication: Secure login and registration system to manage individual player accounts.

2) Main Menu Interface: A central hub for users to access game modes, settings, and statistics.

3) Game Modes:

    - Play with Friends: Create and join private game rooms using custom IDs.

    - Play Online: Match with random players through a smart matchmaking system.

    - Play with AI: Option to play against computer-controlled opponents.

4) Statistics & Achievements Page: Tracks wins, losses, game history, and unlockable achievements to enhance engagement and competition.

5) Rules Page: Provides users with clear instructions and gameplay rules.

6) Settings Page: Allows users to update profile data, change their avatar, and switch languages.

7) Real-Time Multiplayer Infrastructure: A database system to store user accounts and manage the state of live games, ensuring synchronization across devices.

8) Error Handling and UI Feedback: Friendly error messages and loading states for smoother UX.

## Running with Docker

1. Build and start all services:
   ```sh
   docker-compose up --build
   ```

2. Access to the website at:
 [http://localhost:8080](http://localhost:8080)

3. Access the interactive Swagger UI at: [http://192.145.30.253:8000/docs](http://localhost:8000/docs)

## To play in a 2-4 player game mode using docker (on your local machine to test something), do the following:

1. Build and start all services using:
   ```sh
   docker-compose up --build
   ```

2. Open 2-4 browser tabs at:
 [http://localhost:8080](http://localhost:8080)

3. Log in into 2-4 different accounts (using Sign In or Sign Up) from each of the browser tab respectively

4. From one of the logged accounts create a private room (Start new game -> Create private room).

5. From another logged accounts connect to the created private room using room ID and room password (Start new game -> Connect private room)

6. When in a waiting room, from each of the account click "Get Ready" button

7. Play a game - drag cards and submit your moves from both of the accounts

## To play in a 2-4 player game mode online, do the following:
1. Open browser tab at:
 [http://192.145.30.253:8080/](http://192.145.30.253:8080/)

2. Log in into account (using Sign In or Sign Up)

3. Create a private room (Start new game -> Create private room) or connect to the created private room using room ID and room password (Start new game -> Connect private room)

4. When in a waiting room, click "Get Ready" button

5. Play a game - drag cards and submit your moves

## To play with bot, do the following:
1. Open browser tab at:
 [http://192.145.30.253:8080/](http://192.145.30.253:8080/)

2. Log in into account (using Sign In or Sign Up)

3. Start new game -> Vs Bot

4. Play a game - drag cards and submit your moves

## To play with DQN (if you want to see bot's cards)
1. Upload the file DON.py

2. There should be files next to it in the same directory. enviroment.py and final_agent (4).

3. Install torch

4. Write in the console in the directory where the file is located DQN.py 
```sh
   python DQN.py
   ```