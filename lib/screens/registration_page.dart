import 'package:flutter/material.dart';
import 'registration/initial_registration_screen.dart';

class RegistrationPage extends StatelessWidget {
  final bool isArabic;
  
  const RegistrationPage({
    Key? key,
    this.isArabic = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InitialRegistrationScreen(isArabic: isArabic);
  }
} 