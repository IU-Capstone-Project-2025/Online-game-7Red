# Changelog

All notable changes to this project will be documented in this file.

## [MVP0]

### 🚀 Features

- Add starting vertion of project structure and docker fills
- Add database in Neon
- Add file generation data(red 7), decryptor data, dataset, read file(py)
- Set up structure and adding test page
- Add WelkomePage
- Add SignIn and SignUp pages
- First connect to backend
- Add functions for creating,  deleting and searching game rooms
- Add functions for creating, searching and deleting users
- Add basic MVP endpoints
- Add new MVP endpoints
- Implemented registration and authorization
- Function for creating profile in database
- Implement MCTS AI-opponent
- Add functions for creating,  deleting and searching game rooms
- Add functions for creating, searching and deleting users
- Add basic MVP endpoints
- Add new MVP endpoints
- Implemented registration and authorization
- Function for creating profile in database
- Add MainMenuPage
- Complete SignUp page with connection to back and error handling
- Upgrade SignIn connection from frontend to backend
- Add new functions for joining game rooms, searching users and rooms, creating password and assigned_id
- Add functional create and join room endpoints
- New column "ready" was added to user_room table
- Add functional endpoints for ready/not_ready and update_room_state
- Add WaitingRoomPage, update http-requests in SignIn, SignUp, MainMenuPage for creating and connecting to the room, add Provider and SharedPreferences for saving data
- Add partial logic for playing in a game room
- Add more logic to playing in a game room
- Add deleting room from db if there are no players
- Add a base of DQN model
- Add a model, user consol interface, fix in training
- Add basic logic to connect to DQN
- Add function to check a move in list of all possible moves
- Basic shema of GamePage
- Add moving and functions to GamePage, connection with backend
- 2 player game
- Lose/win alerts and confirm exit alert in GamePage
- Add a new part of enviroment, upgrade dqn, add a new test model
- Added transfer of some of the processes to the graphics card, added a mask, improved training, selection of parameters
- Add new model, integration function
- Add partial logic for ai game room
- Add room state update and exit handling
- Add timer and animation to it in GamePage
- Add schema to ResultPage, upgrade text in WaitingRoomPage, upgrade place and time saving in GamePage
- Add leave and exit f-ns in GamePage
- Add a new part of enviroment, upgrade dqn, add a new test model
- Change links for webserver
- Update links to webserver id
- Add file for all urls
- Add error alert when player try to connect to room which already in play mode
- Add error alert in MainMenu when player try to connect to the room where he already exist
- Add achievement 7_days_streak
- Add achievement 5_wins_streak
- Add achievement 3_wins_of_bot
- Add functionality of showing and hiding a password
- Add test coverage
- Add htmlcov
- Add validation test, add mcts work in cpu

### 🐛 Bug Fixes

- Move database ERD to database folder
- Fix database access
- Fix errors in tests of user functions
- Fix database access
- Fix errors in tests of user functions
- Fix database access
- Fix connection to database from backend
- Fix conflicts
- Finish first connection between frontend and backend
- Fix database access
- Edit models
- Edit sign_in and sign_up
- Fix small error
- Add functional endpoint for leaving room
- Fix name for room id
- Change names
- Small fix connection bw Front and Back
- Solve conflict
- Fix connection in MainPage
- Fix leave connect in WaitingPage
- WaitingPage leave connection
- Fix states connect in WaitingRoomPage
- Fix State, Ready, Unready connections in WaitingRoomPage
- Solve conflict
- Fix get to post
- Fix start of the game
- Room_id retrieve changed
- Fix null-error in GamePage
- Fix bugs
- Fix button in GamePage
- Fix sending turn in GamePage
- Fix privilegies in turn GamePage
- Fix bugs
- Fix GamePage structure
- Fix button invis in GamePage
- Fix message sending  in GamePage
- Fix lose alert in GamePage
- Fix fix leaving the game in GamePage
- Fix range on winners on GamePage
- Fix is_winning bug and longest sequence bug
- Main.py to old version
- Fix sizes of widgets and fix email chicking in SignIn/SignUp
- Fix ready/unready in Waiting room after connection to new room
- Fix error alerts when user tru to commect with wrong ip of passord
- Fix exit handling
- Fix main.py
- Fix length of password signup
- Fix connection to room
- Localhost links
- Fix situation with no cards at the end
- Fix order of players
- Fix connection to GameRoom
- Fix time_out
- Exit handling in someone else's turn
- Change urls to server ip
- Update to correct file versions

### 💼 Other

- Upgrade Dockerfile for frontend

### 📚 Documentation

- Add database ERD
- Add project description
- Update changelog
- Update readme
- Update readme
- Update README.md with 2 player game mode rules
- Update changelog
- Update README.md
- Update changelog
- Readme added for webserver use

### 🎨 Styling

- Change function name
- Change style for functions
- Change some functions

### 🧪 Testing

- Add test script for creating, deleting, and searching game rooms
- Add test script for creating, deleting, and searching game rooms
- Add unit tests, widget tests and integration tests
- Add unit tests and  integration tests
- Add one more test
- Add basic DQN testing

### ⚙️ Miscellaneous Tasks

- Add cliff.toml for changelog generation
- Add .env to gitignore
- Add .env to gitignore
- Delete .env from gitignore
- Edit docker-compose.yml
- Add Flame package
- Change achievement name

<!-- generated by git-cliff -->
