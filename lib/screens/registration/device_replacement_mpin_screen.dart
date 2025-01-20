import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import '../../services/auth_service.dart';
import 'device_replacement_biometric_screen.dart';

class DeviceReplacementMPINScreen extends StatefulWidget {
  final bool isArabic;
  final Map<String, dynamic> userData;

  const DeviceReplacementMPINScreen({
    Key? key,
    required this.isArabic,
    required this.userData,
  }) : super(key: key);

  @override
  State<DeviceReplacementMPINScreen> createState() => _DeviceReplacementMPINScreenState();
}

class _DeviceReplacementMPINScreenState extends State<DeviceReplacementMPINScreen> {
  final primaryColor = const Color(0xFF0077B6);
  final List<String> _pin = List.filled(6, '');
  final List<String> _confirmPin = List.filled(6, '');
  bool _isFirstPinValid = false;
  bool _isLoading = false;
  String? _errorMessage;
  final FocusNode _focusNode = FocusNode();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyPress(String value) {
    setState(() {
      if (_isFirstPinValid) {
        // If first PIN is valid, fill the confirmation PIN
        final emptyIndex = _confirmPin.indexOf('');
        if (emptyIndex != -1) {
          _confirmPin[emptyIndex] = value;
          _errorMessage = null;

          // Check if confirmation PIN is complete
          if (!_confirmPin.contains('')) {
            if (_pin.join() != _confirmPin.join()) {
              _errorMessage = widget.isArabic 
                  ? 'الرمزان غير متطابقين'
                  : 'PINs do not match';
              _confirmPin.fillRange(0, _confirmPin.length, '');
            } else {
              _handleMPINSetup();
            }
          }
        }
      } else {
        // Fill the first PIN
        final emptyIndex = _pin.indexOf('');
        if (emptyIndex != -1) {
          _pin[emptyIndex] = value;
          _errorMessage = null;

          // If first PIN is complete, validate it
          if (!_pin.contains('')) {
            _isFirstPinValid = true;
          }
        }
      }
    });
  }

  void _handleBackspace() {
    setState(() {
      if (_isFirstPinValid) {
        // Handle confirmation PIN backspace
        final lastFilledIndex = _confirmPin.lastIndexWhere((digit) => digit.isNotEmpty);
        
        if (lastFilledIndex != -1) {
          _confirmPin[lastFilledIndex] = '';
          _errorMessage = null;
        } else {
          // If confirmation PIN is empty, go back to first PIN
          _isFirstPinValid = false;
        }
      } else {
        // Handle first PIN backspace
        final lastFilledIndex = _pin.lastIndexWhere((digit) => digit.isNotEmpty);
        
        if (lastFilledIndex != -1) {
          _pin[lastFilledIndex] = '';
          _errorMessage = null;
        }
      }
    });
  }

  void _handleClear() {
    setState(() {
      // Clear both PINs
      _pin.fillRange(0, _pin.length, '');
      _confirmPin.fillRange(0, _confirmPin.length, '');
      _isFirstPinValid = false;
      _errorMessage = null;
    });
  }

  Widget _buildPinDisplay() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.isArabic 
              ? (_isFirstPinValid ? 'تأكيد رمز الدخول' : 'أدخل رمز دخول مكون من 6 أرقام')
              : (_isFirstPinValid ? 'Confirm MPIN' : 'Enter a 6-digit MPIN'),
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            final digits = _isFirstPinValid ? _confirmPin : _pin;
            final bool isFilled = digits[index].isNotEmpty;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFilled ? primaryColor : Colors.transparent,
                border: Border.all(
                  color: isFilled ? primaryColor : Colors.grey[300]!,
                  width: 2,
                ),
                boxShadow: isFilled ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ] : null,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildNumpad() {
    Widget buildButton(String value, {bool isSpecial = false}) {
      final bool isBackspace = value == '⌫';
      final bool isClear = value == 'C';

      return Container(
        width: 75,
        height: 75,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          gradient: !isSpecial ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.grey.shade50,
            ],
          ) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.8),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipOval(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (isBackspace) {
                  _handleBackspace();
                } else if (isClear) {
                  _handleClear();
                } else {
                  _handleKeyPress(value);
                }
              },
              splashColor: primaryColor.withOpacity(0.1),
              highlightColor: primaryColor.withOpacity(0.05),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: isBackspace
                      ? Icon(
                          Icons.backspace_rounded,
                          color: primaryColor,
                          size: 28,
                        )
                      : isClear
                          ? Text(
                              'C',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w100,
                                color: primaryColor,
                                letterSpacing: 1,
                              ),
                            )
                          : Text(
                              value,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                                letterSpacing: 1,
                              ),
                            ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['1', '2', '3']
                .map((number) => buildButton(number))
                .toList(),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['4', '5', '6']
                .map((number) => buildButton(number))
                .toList(),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['7', '8', '9']
                .map((number) => buildButton(number))
                .toList(),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              buildButton('C', isSpecial: true),
              buildButton('0'),
              buildButton('⌫', isSpecial: true),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleMPINSetup() async {
    if (_pin.join() == _confirmPin.join()) {
      setState(() => _isLoading = true);
      
      try {
        // Save MPIN using AuthService
        final mpin = _pin.join();
        await _authService.storeMPIN(mpin);
        
        if (!mounted) return;
        
        // Navigate to biometric setup
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => DeviceReplacementBiometricScreen(
              isArabic: widget.isArabic,
              userData: {
                ...widget.userData,
                'mpin': mpin,
              },
            ),
          ),
        );
      } catch (e) {
        print('Error saving MPIN: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isArabic 
                  ? 'حدث خطأ أثناء حفظ رمز الدخول'
                  : 'Error saving MPIN',
            ),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Color(0xFFF5F6FA);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: constraints.maxHeight < 600 
                  ? const AlwaysScrollableScrollPhysics() 
                  : const NeverScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                  minWidth: constraints.maxWidth,
                ),
                child: IntrinsicHeight(
                  child: Stack(
                    children: [
                      // Background Logo
                      Positioned(
                        top: -75,
                        right: widget.isArabic ? null : -75,
                        left: widget.isArabic ? -75 : null,
                        child: Opacity(
                          opacity: 0.2,
                          child: Image.asset(
                            'assets/images/nayifatlogocircle-nobg.png',
                            width: 200,
                            height: 200,
                          ),
                        ),
                      ),

                      // Main Content
                      Column(
                        children: [
                          const SizedBox(height: 100),
                          // Title with decoration
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            child: Column(
                              children: [
                                Text(
                                  widget.isArabic ? 'إنشاء رمز دخول سريع' : 'Create MPIN',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: 60,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildPinDisplay(),
                                if (_errorMessage != null) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          _buildNumpad(),
                        ],
                      ),

                      if (_isLoading)
                        Container(
                          color: Colors.black.withOpacity(0.1),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
} 