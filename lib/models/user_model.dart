class UserModel {
  final String uid;
  final String shopName;
  final String email;
  final String mobile;
  final String deviceToken;
  final double latitude;
  final double longitude;
  final String status;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.shopName,
    required this.email,
    required this.mobile,
    required this.deviceToken,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'shopName': shopName,
      'email': email,
      'mobile': mobile,
      'deviceToken': deviceToken,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      shopName: map['shopName'],
      email: map['email'],
      mobile: map['mobile'],
      deviceToken: map['deviceToken'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      status: map['status'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
