// For localhost

// String signInUrl = 'http://localhost:8000/auth/signin';
// String signUpUrl = 'http://localhost:8000/auth/signup';
// String createRoomUrl = 'http://localhost:8000/rooms/create';
// String joinRoomUrl = 'http://localhost:8000/rooms/join';
// String roomStateUrl = 'http://localhost:8000/rooms/state';
// String roomReadyUrl = 'http://localhost:8000/rooms/ready';
// String roomNotReadyUrl = 'http://localhost:8000/rooms/not_ready';
// String leaveRoomUrl = 'http://localhost:8000/rooms/leave';
// String serverUrlPartUrl = 'ws://localhost:8000';
// String statisticsUrl = 'http://localhost:8000/settings/user_stats';
// String onlineSearchUrl = 'http://localhost:8000/rooms/find_online';
// String onlineStateUrl = 'http://localhost:8000/rooms/find_online_status';
// String onlineLeaveUrl = 'http://localhost:8000/rooms/cancel_find_online';

// For server

String signInUrl = '/api/auth/signin';
String signUpUrl = '/api/auth/signup';
String createRoomUrl = '/api/rooms/create';
String joinRoomUrl = '/api/rooms/join';
String roomStateUrl = '/api/rooms/state';
String roomReadyUrl = '/api/rooms/ready';
String roomNotReadyUrl = '/api/rooms/not_ready';
String leaveRoomUrl = '/api/rooms/leave';
String serverUrlPartUrl = String.fromEnvironment('WS_URL', defaultValue: 'wss://localhost:8000/api');
String statisticsUrl = '/api/settings/user_stats';
String onlineSearchUrl = '/api/rooms/find_online';
String onlineStateUrl = '/api/rooms/find_online_status';
String onlineLeaveUrl = '/api/rooms/cancel_find_online';
String changeNicknameUrl = '/api/settings/change_nickname';
String changeEmailUrl = '/api/settings/change_email';
String changePasswordUrl = '/api/settings/change_password';
String uploadImageUrl = '/api/profile_page/upload-avatar/';
String fetchImageUrl = '/api/profile_page/get-avatar/';
