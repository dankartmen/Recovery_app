import 'package:auth_test/services/auth_service.dart';
import 'package:flutter/material.dart';

class AuthController with ChangeNotifier{
  final AuthService _authService;
  bool isLoading = false;
  String? errorMassage;

  AuthController(this._authService);

  Future<void> login(String username, String password) async {
    isLoading = true;
    errorMassage = null;
    notifyListeners();

    try {
      await _authService.login(username,password,);
      errorMassage = null;
    } catch (e) {
      errorMassage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void cleanError(){
    errorMassage = null;
    notifyListeners();
  }
}