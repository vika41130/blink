class User {
  final String username;
  final String passcode;
  final String userNickName;
  final List<String> contacts;

  User({
    required this.username,
    required this.passcode,
    this.userNickName = '',
    this.contacts = const [],
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      username: map['username'] as String? ?? '',
      passcode: map['passcode'] as String? ?? '',
      userNickName: map['userNickName'] as String? ?? '',
      contacts: (map['contacts'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'passcode': passcode,
      'userNickName': userNickName,
      'contacts': contacts,
    };
  }
}
