class User {
  final String username;
  final String pin;
  final String userNickName;
  final List<String> contacts;
  final int chatMessageDuration;
  final bool contactsLocked;
  final String email;

  User({
    required this.username,
    required this.pin,
    this.userNickName = '',
    this.contacts = const [],
    this.chatMessageDuration = 1,
    this.contactsLocked = false,
    this.email = '',
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      username: map['username'] as String? ?? '',
      pin: map['pin'] as String? ?? '',
      userNickName: map['userNickName'] as String? ?? '',
      contacts: (map['contacts'] as List<dynamic>?)?.cast<String>() ?? [],
      chatMessageDuration: map['chatMessageDuration'] as int? ?? 1,
      contactsLocked: map['contactsLocked'] as bool? ?? false,
      email: map['email'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'pin': pin,
      'userNickName': userNickName,
      'contacts': contacts,
      'chatMessageDuration': chatMessageDuration,
      'contactsLocked': contactsLocked,
      'email': email,
    };
  }
}
