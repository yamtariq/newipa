import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'sign_in_screen.dart';

class SignInPage extends StatelessWidget {
  final bool startWithPassword;
  
  const SignInPage({
    Key? key,
    this.startWithPassword = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SignInScreen(
      isArabic: false,
      startWithPassword: startWithPassword,
    );
  }
} 