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

2. Access the backend at:
 [http://localhost:8000](http://localhost:8000)

3. After starting the backend, you can access the interactive Swagger UI at: [http://localhost:8000/docs](http://localhost:8000/docs)
