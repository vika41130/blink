class Contact {
  final String username;
  final String userNickName;

  Contact({required this.username, this.userNickName = ''});

  String get displayName => userNickName.isNotEmpty ? userNickName : username;
}
