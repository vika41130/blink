class Contact {
  final String username;
  final String userId;

  Contact({required this.username, required this.userId});

  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      username: map['username'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'username': username, 'userId': userId};
  }
}
