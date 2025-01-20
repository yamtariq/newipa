import 'package:flutter/material.dart';

class MPINInput extends StatelessWidget {
  final Function(String) onCompleted;
  final bool isArabic;

  const MPINInput({
    Key? key,
    required this.onCompleted,
    required this.isArabic,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<String> mpinDigits = List.filled(6, '');
    final primaryColor = Color(0xFF0077B6);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // PIN Display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (index) {
              return Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: mpinDigits[index].isEmpty
                        ? Colors.grey[300]!
                        : primaryColor,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: mpinDigits[index].isEmpty
                      ? null
                      : Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),

          // Numpad
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['1', '2', '3']
                      .map((number) => _buildNumpadButton(
                            number,
                            mpinDigits,
                            onCompleted,
                          ))
                      .toList(),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['4', '5', '6']
                      .map((number) => _buildNumpadButton(
                            number,
                            mpinDigits,
                            onCompleted,
                          ))
                      .toList(),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['7', '8', '9']
                      .map((number) => _buildNumpadButton(
                            number,
                            mpinDigits,
                            onCompleted,
                          ))
                      .toList(),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNumpadButton('C', mpinDigits, onCompleted,
                        isSpecial: true),
                    _buildNumpadButton('0', mpinDigits, onCompleted),
                    _buildNumpadButton('⌫', mpinDigits, onCompleted,
                        isSpecial: true),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumpadButton(
    String value,
    List<String> mpinDigits,
    Function(String) onCompleted, {
    bool isSpecial = false,
  }) {
    final bool isBackspace = value == '⌫';
    final bool isClear = value == 'C';
    final primaryColor = Color(0xFF0077B6);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (isBackspace) {
            _handleMPINBackspace(mpinDigits);
          } else if (isClear) {
            _handleMPINClear(mpinDigits);
          } else {
            _handleMPINKeyPress(value, mpinDigits, onCompleted);
          }
        },
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 65,
          height: 65,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSpecial ? primaryColor : Colors.white,
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Center(
            child: isBackspace
                ? Icon(
                    Icons.backspace_outlined,
                    color: Colors.white,
                    size: 24,
                  )
                : Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isClear ? Colors.white : Colors.black87,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _handleMPINKeyPress(
    String value,
    List<String> mpinDigits,
    Function(String) onCompleted,
  ) {
    final emptyIndex = mpinDigits.indexOf('');
    if (emptyIndex != -1) {
      mpinDigits[emptyIndex] = value;

      // If MPIN is complete, call onCompleted
      if (!mpinDigits.contains('')) {
        onCompleted(mpinDigits.join());
      }
    }
  }

  void _handleMPINBackspace(List<String> mpinDigits) {
    final lastFilledIndex =
        mpinDigits.lastIndexWhere((digit) => digit.isNotEmpty);
    if (lastFilledIndex != -1) {
      mpinDigits[lastFilledIndex] = '';
    }
  }

  void _handleMPINClear(List<String> mpinDigits) {
    mpinDigits.fillRange(0, mpinDigits.length, '');
  }
} 