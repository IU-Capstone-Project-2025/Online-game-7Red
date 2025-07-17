# Online-game-7Red
## Project description

The application includes the following core components:

1. User Authentication: Secure login and registration system to manage individual player accounts.

2. Main Menu Interface: A central hub for users to access game modes, settings, and statistics.

3. Game Modes:

    - Play with Friends: Create and join private game rooms using custom IDs and passwords.

    - Play Online: Match with random players through a smart matchmaking system.

    - Play with AI: Option to play against computer-controlled opponent.

4. Statistics & Achievements Page: Tracks wins, losses, game history, and unlockable achievements to enhance engagement and competition.

5. Rules Page: Provides users with clear instructions and gameplay rules.

6. Settings Page: Allows users to update profile data, change their avatar, switch languages, and log out.

7. Real-Time Multiplayer Infrastructure: A database system to store user accounts and manage the state of live games, ensuring synchronization across devices.

8. Error Handling and UI Feedback: Friendly error messages and loading states for smoother UX.

## Website Usage Instructions

1. If needed, check the documentation:

   1.1 To check Backend API Documentation, use: [http://7red.ru/api/docs](http://7red.ru/api/docs)
   1.2 To check Alternative API Documentation, use: [http://7red.ru/api/redoc](http://7red.ru/api/redoc)

2. Access the game website at: [http://7red.ru](http://7red.ru)

3. Log in and play! (in case of any questions read through Testing situations in Docker Usage Instructions below)

## Docker Usage Instructions (for code testing)

1. Clone the Repository

2. Ensure you have the following installed on your system:
   - Docker and Docker Compose (required for containerized deployment)
   - Python 3.8+ (for local backend development)
   - Flutter SDK (for local frontend development)
   - Git (for version control)

3. Copy the environment template from .env.example and add to the root of the project .env file with needed configuration

4. Build and start the project with Docker, using:

   4.1 Option A: Using Pre-built Images from DockerHub spalkkina/7red. 
   Build and start all services with  
   ```sh
   docker-compose up --build
   ```
   4.2 Option B: Local Development Build. 
   Use the local development configuration 
   ```sh
   docker-compose -f docker-compose.local.yml up --build
   ```

5. For Multiplayer Testing:

   5.1 Open 2-4 browser tabs
   5.2 Create different accounts in each tab (Sign In/Sign Up)
   5.3 From one account: Create private room (Start new game → Create private room)
   5.4 From other accounts: Join using room ID and password (Start new game → Connect private room)
   5.5 Click "Get Ready" button in each tab
   5.6 Start playing by dragging cards and submitting moves
   5.7 If you want to read the rules, click the ? button in the lower right corner
   5.8 If you lose, stay as a spectator and watch the rest of the game (if you're interested)
   5.9 If you want to leave the game, click the "Exit" button in the upper left corner
   5.10 After the game is over, see the statistics by clicking the button in the lower right corner of the main page

6. For Bot Testing:

   6.1 Open a browser tab
   6.2 Log in to your account
   6.3 Start a game against the bot (Start new game → Vs Bot)
   6.4 Play against the AI opponent
   6.5 If you want to leave the game, click the "Exit" button in the upper left corner

7. For Random Opponents Search Testing:

   7.1 Open a browser tab
   7.2 Log in to your account
   7.3 Search for random opponents (Start new game → Random Opponents)
   7.4 When in an Online Room, click "Get Ready" button
   7.5 Start playing by dragging cards and submitting moves
   7.6 If you want to read the rules, click the ? button in the lower right corner
   7.7 If you lose, stay as a spectator and watch the rest of the game (if you're interested)
   7.8 If you want to leave the game, click the "Exit" button in the upper left corner
   7.9 After the game is over, see the statistics by clicking the button in the lower right corner of the main page

8. For Settings Testing:

   8.1 Open a browser tab
   8.2 Log in to your account
   8.3 Enter Settings (click the ⚙️ button in the upper right corner of the main page)
   8.4 Set up the website and your profile as you wish
   8.5 If you want to log out of your account, use the same button

9. DQN Testing in Console (if you want to see bot's cards):

   9.1 Upload the file DON.py
   9.2 There should also be enviroment.py and final_agent (4) files in the same directory as DON.py
   9.3 Install torch
   9.4 Write in the console in the directory where the file DQN.py is located
   ```sh
      python DQN.py
   ```

10. Monitor Docker logs with 
   ```sh
   docker-compose logs -f
   ```

   Or, to check the logs saved in files, use
   ```sh
   docker exec -it <backend_container_id> /bin/bash -c "cd /app/logs && tail -f server.log"
   ```

11. Stop Docker containers using
   ```sh
   docker-compose down -v
   ```
