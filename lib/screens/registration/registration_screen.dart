import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/registration_provider.dart';
import '../../services/registration_service.dart';
import '../../services/auth_service.dart';
import '../main_page.dart';
import 'steps/id_phone_step.dart';
import 'steps/otp_verification_step.dart';
import 'steps/password_creation_step.dart';
import 'steps/mpin_creation_step.dart';
import 'steps/biometric_setup_step.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RegistrationProvider(),
      child: const RegistrationView(),
    );
  }
}

class RegistrationView extends StatelessWidget {
  const RegistrationView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RegistrationProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration'),
        leading: provider.currentStep != RegistrationStep.idAndPhone
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  // Show confirmation dialog before going back
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Go Back?'),
                      content: const Text(
                          'Going back will reset your current progress. Are you sure?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            provider.reset();
                            Navigator.pop(context);
                          },
                          child: const Text('Go Back'),
                        ),
                      ],
                    ),
                  );
                },
              )
            : null,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Progress indicator
              LinearProgressIndicator(
                value: provider.progress,
                backgroundColor: theme.colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
              // Step indicator
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _getStepTitle(provider.currentStep),
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              // Current step content
              Expanded(
                child: _getCurrentStep(provider.currentStep),
              ),
            ],
          ),
          // Loading overlay
          if (provider.isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  String _getStepTitle(RegistrationStep step) {
    switch (step) {
      case RegistrationStep.idAndPhone:
        return 'Step 1: Enter ID and Phone Number';
      case RegistrationStep.otpVerification:
        return 'Step 2: Verify Phone Number';
      case RegistrationStep.passwordCreation:
        return 'Step 3: Create Password';
      case RegistrationStep.mpinCreation:
        return 'Step 4: Set Quick Access PIN';
      case RegistrationStep.biometricSetup:
        return 'Step 5: Setup Biometric Login';
      case RegistrationStep.completed:
        return 'Registration Complete!';
    }
  }

  Widget _getCurrentStep(RegistrationStep step) {
    switch (step) {
      case RegistrationStep.idAndPhone:
        return const IdPhoneStep();
      case RegistrationStep.otpVerification:
        return const OtpVerificationStep();
      case RegistrationStep.passwordCreation:
        return const PasswordCreationStep();
      case RegistrationStep.mpinCreation:
        return const MpinCreationStep();
      case RegistrationStep.biometricSetup:
        return const BiometricSetupStep();
      case RegistrationStep.completed:
        return const RegistrationCompleteStep();
    }
  }
}

class RegistrationCompleteStep extends StatelessWidget {
  const RegistrationCompleteStep({Key? key}) : super(key: key);

  Future<Map<String, dynamic>> _getStoredRegistrationData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('registration_data');
    print('Retrieved stored registration data: $jsonStr');
    if (jsonStr != null) {
      return json.decode(jsonStr);
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RegistrationProvider>();
    final isArabic = provider.isArabic;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 100,
            color: Colors.green,
          ),
          const SizedBox(height: 24),
          Text(
            'Registration Complete!',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          const Text(
            'Your account has been created successfully',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (provider.isLoading)
            const CircularProgressIndicator()
          else
            ElevatedButton(
              onPressed: () async {
                try {
                  provider.setLoading(true);
                  print('Starting post-registration process...');
                  
                  final storedData = await _getStoredRegistrationData();
                  print('Working with stored registration data: $storedData');
                  
                  if (storedData.isNotEmpty) {
                    final authService = Provider.of<AuthService>(context, listen: false);
                    
                    // Get device info
                    print('Getting device info...');
                    final deviceInfo = await authService.getDeviceInfo();
                    print('Device info: $deviceInfo');
                    
                    // Start sign in
                    print('Attempting sign in...');
                    final result = await authService.signIn(
                      nationalId: storedData['national_id'].toString(),
                      deviceId: deviceInfo['deviceId'],
                      password: storedData['password'],
                    );
                    print('Sign in result: $result');
                    
                    if (result['status'] == 'success') {
                      // Get user data from API response
                      var userData = result['user'];
                      print('\n=== USER DATA SOURCE ===');
                      print('1. API Response user data: $userData');
                      print('2. Stored user data: ${storedData['userData']}');
                      print('=== USER DATA SOURCE END ===\n');
                      
                      if (userData == null) {
                        print('No user data in API response, using stored data');
                        // Fallback to stored data
                        userData = storedData['userData'];
                      }
                      
                      // Store tokens in secure storage
                      if (result['token'] != null) {
                        print('\n=== STORING TOKEN ===');
                        print('Token being stored in secure storage: ${result['token']}');
                        await authService.storeTokens(result['token']);
                        print('=== TOKEN STORED ===\n');
                      }
                      
                      // Log data from both storage types
                      print('\n=== CHECKING ALL STORAGE LOCATIONS ===');
                      
                      // 1. Check SharedPreferences
                      final prefs = await SharedPreferences.getInstance();
                      final regDataStr = prefs.getString('registration_data');
                      print('1. SharedPreferences:');
                      print('- Key: registration_data');
                      print('- Value: $regDataStr');
                      
                      // 2. Check SecureStorage user data
                      final secureUserData = await authService.getUserData();
                      print('\n2. SecureStorage:');
                      print('- Key: user_data');
                      print('- Value: $secureUserData');
                      
                      // 3. Check auth token in secure storage
                      final authToken = await authService.getToken();
                      print('\n3. SecureStorage Token:');
                      print('- Key: auth_token');
                      print('- Value: ${authToken != null ? 'Present' : 'Not found'}');
                      
                      // Get the user data we'll send to MainPage
                      final userData = storedData['userData'];
                      print('\nData we will send to MainPage: $userData');
                      
                      print('=== STORAGE CHECK COMPLETE ===\n');
                      
                      // Store user data in secure storage
                      if (userData != null) {
                        print('\n=== STORING USER DATA ===');
                        print('Storing in SecureStorage:');
                        print('- Key: user_data');
                        print('- Value: $userData');
                        await authService.storeUserData(userData);
                        print('=== USER DATA STORED ===\n');
                      }
                      
                      // Store device registration in both storages
                      print('\n=== STORING DEVICE REGISTRATION ===');
                      print('Storing in both SecureStorage and SharedPreferences:');
                      print('- National ID: ${storedData['national_id']}');
                      await authService.storeDeviceRegistration(storedData['national_id'].toString());
                      print('=== DEVICE REGISTRATION STORED ===\n');
                      
                      // Start session
                      print('\n=== STARTING SESSION ===');
                      await authService.startSession(
                        storedData['national_id'].toString(),
                        userId: userData?['id']?.toString(),
                      );
                      print('=== SESSION STARTED ===\n');
                      
                      // Final storage check before navigation
                      print('\n=== FINAL STORAGE CHECK BEFORE NAVIGATION ===');
                      final finalSecureData = await authService.getUserData();
                      print('1. Final SecureStorage user_data: $finalSecureData');
                      final finalRegData = prefs.getString('registration_data');
                      print('2. Final SharedPreferences registration_data: $finalRegData');
                      print('=== FINAL CHECK COMPLETE ===\n');
                      
                      print('\n>>> NAVIGATING TO MAIN PAGE');
                      print('- Using userData: $userData');
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MainPage(
                            isArabic: isArabic,
                            onLanguageChanged: (bool newIsArabic) {
                              // Handle language change if needed
                            },
                            userData: userData,
                          ),
                        ),
                      );
                      print('>>> NAVIGATION COMPLETED\n');
                    } else {
                      print('Sign in failed: ${result['message']}');
                      throw Exception(result['message'] ?? 'Failed to start session');
                    }
                  } else {
                    print('Error: No stored registration data found');
                    throw Exception('Registration data not found');
                  }
                } catch (e) {
                  print('Error in post-registration process: $e');
                  print('Stack trace: ${StackTrace.current}');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error starting session: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } finally {
                  provider.setLoading(false);
                  print('Post-registration process completed');
                }
              },
              child: const Text('Continue to Home'),
            ),
        ],
      ),
    );
  }
} 