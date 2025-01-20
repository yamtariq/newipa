import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../providers/registration_provider.dart';
import '../../../services/registration_service.dart';
import '../registration_constants.dart';

class IdPhoneStep extends StatefulWidget {
  const IdPhoneStep({Key? key}) : super(key: key);

  @override
  State<IdPhoneStep> createState() => _IdPhoneStepState();
}

class _IdPhoneStepState extends State<IdPhoneStep> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _phoneController = TextEditingController();
  final _registrationService = RegistrationService();

  @override
  void dispose() {
    _idController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _validateAndProceed(RegistrationProvider provider) async {
    if (!_formKey.currentState!.validate()) return;

    provider.setLoading(true);
    try {
      // Check if user exists
      final response = await _registrationService.validateIdentity(
        _idController.text,
        _phoneController.text,
      );

      if (!mounted) return;

      if (response['success'] == true) {
        if (response['userExists'] == true) {
          // Show dialog for existing user
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('User Already Registered'),
              content: const Text(
                  'This ID is already registered. Would you like to reset your password?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pushReplacementNamed(
                        context, '/forgot-password'); // Navigate to password reset
                  },
                  child: const Text('Reset Password'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          );
        } else {
          // Generate OTP for new user
          final otpResponse = await _registrationService.generateOTP(
            _idController.text,
            _phoneController.text,
          );

          if (otpResponse['success'] == true) {
            provider.setIdAndPhone(_idController.text, _phoneController.text);
            provider.nextStep();
          } else {
            _showError('Failed to generate OTP. Please try again.');
          }
        }
      } else {
        _showError('Invalid ID or phone number. Please check and try again.');
      }
    } catch (e) {
      _showError('An error occurred. Please try again later.');
    } finally {
      provider.setLoading(false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RegistrationProvider>();
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ID Number field
            TextFormField(
              controller: _idController,
              decoration: const InputDecoration(
                labelText: 'ID Number',
                hintText: 'Enter your ID number',
                prefixIcon: Icon(Icons.badge),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return RegistrationConstants.invalidIdMessage;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Phone Number field
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Mobile Number',
                hintText: 'Enter your mobile number',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return RegistrationConstants.invalidPhoneMessage;
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Next button
            ElevatedButton(
              onPressed: provider.isLoading
                  ? null
                  : () => _validateAndProceed(provider),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: theme.textTheme.titleMedium,
              ),
              child: const Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
} 