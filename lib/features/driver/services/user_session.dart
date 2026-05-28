// lib/features/driver/services/user_session.dart
class UserSession {
  static final UserSession _instance = UserSession._internal();
  factory UserSession() => _instance;
  UserSession._internal();

  String? userId;         
  String? registerNumber;

  String? get driverId => userId;

  void setUser(String id, {String? reg}) {
    userId = id;
    registerNumber = reg;
  }

  void clear() {
    userId = null;
    registerNumber = null;
  }

  bool get isLoggedIn => userId != null;
}