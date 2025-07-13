import 'package:get/get.dart';
import 'package:flutter_project_final/moduels/users.dart';
import '../../Service/login_service.dart';

class LoginController extends GetxController {
  var email = '';
  var password = '';
  var message = '';
  var loginStatus = false;

  final loginService = LoginService();

  Future<void> loginOnClick() async {
    User user = User(
      email: email,
      password: password,
      id: null,
      name: '',
      role: '',
    );
    loginStatus = await loginService.login(user);
    message = loginService.message;
  }
}