import 'package:flutter/material.dart';
import 'registration/initial_registration_screen.dart';

class RegistrationPageAr extends StatelessWidget {
  final bool isArabic;
  
  const RegistrationPageAr({
    Key? key,
    this.isArabic = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InitialRegistrationScreen(isArabic: isArabic);
  }
} 