class AppUser {
  final String uid;
  final String phoneNumber;
  final String displayName;
  final String? photoUrl;
  final String? status;
  final bool isOnline;
  final DateTime? lastSeen;

  AppUser({
    required this.uid,
    required this.phoneNumber,
    required this.displayName,
    this.photoUrl,
    this.status,
    this.isOnline = false,
    this.lastSeen,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      displayName: map['displayName'] ?? map['phoneNumber'] ?? 'مستخدم',
      photoUrl: map['photoUrl'],
      status: map['status'] ?? 'مرحباً، أنا على واتساب',
      isOnline: map['isOnline'] ?? false,
      lastSeen: (map['lastSeen'] as dynamic)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'phoneNumber': phoneNumber,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'status': status ?? 'مرحباً، أنا على واتساب',
      'isOnline': isOnline,
      'lastSeen': lastSeen,
    };
  }
}
