class Player {
  final int id;
  final String name;
  final bool isMe;
  List<String> pallete = [];
  int numOfCards = 7;

  Player({required this.id, required this.name, required this.isMe});
}