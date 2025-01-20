import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'sign_in_screen.dart';

class SignInPageAr extends StatelessWidget {
  final bool startWithPassword;
  
  const SignInPageAr({
    Key? key,
    this.startWithPassword = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SignInScreen(
      isArabic: true,
      startWithPassword: startWithPassword,
    );
  }
} 