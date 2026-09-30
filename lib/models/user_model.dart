enum LoginType { dummyJson, firebase }

class UserModel {
  const UserModel({
    required this.uid,
    required this.id,
    required this.username,
    required this.email,
    required this.fName,
    required this.lName,
    required this.age,
    required this.contactNo,
    required this.gender,
    required this.image,
    required this.accessToken,
    required this.refreshToken,
    required this.loginType,
  });

  final String uid;
  final String id;
  final String username;
  final String email;
  final String fName;
  final String lName;
  final int? age;
  final String contactNo;
  final String gender;
  final String image;
  final String accessToken;
  final String refreshToken;
  final LoginType loginType;

  String get fullName => '$fName $lName'.trim();

  factory UserModel.fromDummyJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? '').toString();
    return UserModel(
      uid: id,
      id: id,
      username: (json['username'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      fName: (json['firstName'] ?? json['firstname'] ?? '').toString(),
      lName: (json['lastName'] ?? json['lastname'] ?? '').toString(),
      age: int.tryParse((json['age'] ?? '').toString()),
      contactNo: (json['phone'] ?? json['contactNo'] ?? '').toString(),
      gender: (json['gender'] ?? '').toString(),
      image: (json['image'] ?? '').toString(),
      accessToken: (json['accessToken'] ?? json['token'] ?? '').toString(),
      refreshToken: (json['refreshToken'] ?? '').toString(),
      loginType: LoginType.dummyJson,
    );
  }

  factory UserModel.fromFirebase({
    required String uid,
    required String email,
    required String username,
    required String fName,
    required String lName,
    required int? age,
    required String contactNo,
    required String accessToken,
  }) {
    return UserModel(
      uid: uid,
      id: uid,
      username: username,
      email: email,
      fName: fName,
      lName: lName,
      age: age,
      contactNo: contactNo,
      gender: '',
      image: '',
      accessToken: accessToken,
      refreshToken: '',
      loginType: LoginType.firebase,
    );
  }

  UserModel copyWith({String? username}) {
    return UserModel(
      uid: uid,
      id: id,
      username: username ?? this.username,
      email: email,
      fName: fName,
      lName: lName,
      age: age,
      contactNo: contactNo,
      gender: gender,
      image: image,
      accessToken: accessToken,
      refreshToken: refreshToken,
      loginType: loginType,
    );
  }
}
