import 'package:flutter/material.dart';
import 'app_localizations.dart';

class NationalIdScreen extends StatefulWidget {
  @override
  _NationalIdScreenState createState() => _NationalIdScreenState();
}

class _NationalIdScreenState extends State<NationalIdScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nationalIdController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  bool _termsAccepted = false;

  bool get isArabic => Localizations.localeOf(context).languageCode == 'ar';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Theme.of(context).primaryColor,
          title: Text(
            AppLocalizations.getText('Loan Application', 'طلب التمويل'),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header Section with Decorative Wave
                Container(
                  width: double.infinity,
                  color: Theme.of(context).primaryColor,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Icon(
                        Icons.account_balance,
                        size: 60,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.getText(
                          'Start Your Loan Journey',
                          'ابدأ رحلة تمويلك'
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Container(
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(40),
                            topRight: Radius.circular(40),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Form Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        // National ID Field
                        Text(
                          AppLocalizations.getText('National ID', 'رقم الهوية'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nationalIdController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: AppLocalizations.getText('Enter your 10-digit ID', 'أدخل رقم الهوية المكون من 10 أرقام'),
                            prefixIcon: const Icon(Icons.credit_card),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Theme.of(context).primaryColor),
                            ),
                          ),
                          maxLength: 10,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.getText(
                                'Please enter your National ID',
                                'يرجى إدخال رقم الهوية'
                              );
                            } else if (value.length != 10) {
                              return AppLocalizations.getText(
                                'National ID must be 10 digits',
                                'يجب أن يتكون رقم الهوية من 10 أرقام'
                              );
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Date of Birth Field
                        Text(
                          AppLocalizations.getText('Date of Birth', 'تاريخ الميلاد'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _dobController,
                          readOnly: true,
                          decoration: InputDecoration(
                            hintText: AppLocalizations.getText('Select your date of birth', 'اختر تاريخ ميلادك'),
                            prefixIcon: const Icon(Icons.calendar_today),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Theme.of(context).primaryColor),
                            ),
                          ),
                          onTap: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime(2000),
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (pickedDate != null) {
                              _dobController.text =
                                  "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.getText(
                                'Please select your Date of Birth',
                                'يرجى اختيار تاريخ الميلاد'
                              );
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Terms and Conditions
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: _termsAccepted,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      _termsAccepted = value ?? false;
                                    });
                                  },
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  AppLocalizations.getText(
                                    'I accept the Terms and Conditions',
                                    'أوافق على الشروط والأحكام'
                                  ),
                                  style: TextStyle(
                                    color: Colors.grey[800],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Continue Button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _termsAccepted
                                ? () {
                                    if (_formKey.currentState!.validate()) {
                                      Navigator.pushNamed(
                                        context,
                                        '/UserDetailsScreen',
                                        arguments: {
                                          'nationalId': _nationalIdController.text,
                                          'dob': _dobController.text,
                                        },
                                      );
                                    }
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: Text(
                              AppLocalizations.getText('Continue', 'متابعة'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
