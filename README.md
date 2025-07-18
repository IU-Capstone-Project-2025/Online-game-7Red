# Online-game-7Red
## Project description

The application includes the following core components:

1. **User Authentication**: Secure login and registration system to manage individual player accounts.

2. **Main Menu Interface**: A central hub for users to access game modes, settings, and statistics.

3. **Game Modes**:
   - Play with Friends: Create and join private game rooms using custom IDs and passwords.
   - Play Online: Match with random players through a smart matchmaking system.
   - Play with AI: Option to play against computer-controlled opponent.

4. **Statistics & Achievements Page**: Tracks wins, losses, game history, and unlockable achievements to enhance engagement and competition.

5. **Rules Page**: Provides users with clear instructions and gameplay rules.

6. **Settings Page**: Allows users to update profile data, change their avatar, switch languages, and log out.

7. **Real-Time Multiplayer Infrastructure**: A database system to store user accounts and manage the state of live games, ensuring synchronization across devices.

8. **Error Handling and UI Feedback**: Friendly error messages and loading states for smoother UX.

## Website Usage Instructions

1. If needed, **check the documentation**:

   - Backend API Documentation: [https://7red.ru/api/docs](https://7red.ru/api/docs)
   - Alternative API Documentation: [https://7red.ru/api/redoc](https://7red.ru/api/redoc)

2. Access the **game website** at: [https://7red.ru](https://7red.ru)

3. Log in and play! (In case of any questions, refer to **Testing Scenarios** in **Docker Usage Instructions** below)

## Docker Usage Instructions (for code testing)

1. **Clone the Repository**

2. Ensure you have **the following installed on your system**:
   - Docker and Docker Compose (required for containerized deployment)
   - Python 3.8+ (for local backend development)
   - Flutter SDK (for local frontend development)
   - Git (for version control)

3. Copy the environment template from .env.example and **add to the root of the project .env file** with needed configuration

4. **Build and start the project** with Docker, using:

   **Option A: Using Pre-built Images from DockerHub spalkkina/7red** 

   Build and start all services with  
   ```sh
   docker-compose up --build
   ```

   **Option B: Local Development Build**

   Use the local development configuration 
   ```sh
   docker-compose -f docker-compose.local.yml up --build
   ```

   **Local access to the website at**: [http://localhost:8080](http://localhost:8080)

5. **Testing Scenarios**:

   5.1 For **Multiplayer Testing**:

      1. Open 2-4 browser tabs

      2. Create different accounts in each tab (Sign In/Sign Up)

      3. From one account: Create private room (Start new game → Create private room)

      4. From other accounts: Join using room ID and password (Start new game → Connect private room)

      5. Click "Get Ready" button in each tab

      6. Start playing by dragging cards and submitting moves

      7. If you want to read the rules, click the ? button in the lower right corner

      8. If you lose, stay as a spectator and watch the rest of the game (if you're interested)

      9. If you want to leave the game, click the "Exit" button in the upper left corner

      10. After the game is over, see the statistics by clicking the button in the lower right corner of the main page

   5.2 For **Bot Testing**:

      1. Open a browser tab

      2. Log in to your account

      3. Start a game against the bot (Start new game → Vs Bot)

      4. Play against the AI opponent

      5. If you want to leave the game, click the "Exit" button in the upper left corner

   5.3 For **Random Opponents Search Testing**:

      1. Open a browser tab

      2. Log in to your account

      3. Search for random opponents (Start new game → Random Opponents)

      4. When in an Online Room, click "Get Ready" button

      5. Start playing by dragging cards and submitting moves

      6. If you want to read the rules, click the ? button in the lower right corner

      7. If you lose, stay as a spectator and watch the rest of the game (if you're interested)

      8. If you want to leave the game, click the "Exit" button in the upper left corner

      9. After the game is over, see the statistics by clicking the button in the lower right corner of the main page

   5.4 For **Settings Testing**:

      1. Open a browser tab

      2. Log in to your account

      3. Enter Settings (click the ⚙️ button in the upper right corner of the main page)

      4. Set up the website and your profile as you wish

      5. If you want to log out of your account, use the same button

   5.5 **DQN Testing** in Console (if you want to see bot's cards):

      1. Upload the file DON.py

      2. There should also be enviroment.py and final_agent (4) files in the same directory as DON.py

      3. Install torch

      4. Write in the console in the directory where the file DQN.py is located
      ```sh
         python DQN.py
      ```

6. Monitor **Docker logs** with 
   ```sh
   docker-compose logs -f
   ```

   Or, to check the **logs saved in files**, use
   ```sh
   docker exec -it <backend_container_id> /bin/bash -c "cd /app/logs && tail -f server.log"
   ```

7. **Stop Docker containers** using
   ```sh
   docker-compose down -v
   ```
