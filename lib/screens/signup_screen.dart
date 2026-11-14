
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import '../utils/validators.dart';
import '../widgets/auth_background.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/buttons.dart';
import 'home_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _firstController = TextEditingController();
  final _lastController = TextEditingController();
  final _shopController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  String _countryCode = '+92';

  bool _acceptTerms = false;
  bool _showTermsError = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _firstController.dispose();
    _lastController.dispose();
    _shopController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? AppColors.danger : AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleSignUp() async {
    final isValid = _formKey.currentState!.validate();

    if (!_acceptTerms) {
      setState(() => _showTermsError = true);
    }

    if (!isValid || !_acceptTerms) return;

    setState(() => _isLoading = true);

    final error = await _authService.signUp(
      firstName: _firstController.text.trim(),
      lastName: _lastController.text.trim(),
      shopName: _shopController.text.trim(),
      email: _emailController.text.trim(),
      phone: Validators.buildFullPhone(
        _countryCode,
        _phoneController.text,
      ),
      password: _passwordController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (error == null) {
      _showMessage(
        'Account created successfully.',
        isError: false,
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
        (route) => false,
      );
    } else {
      _showMessage(error);
    }
  }

  Widget _countryPicker() {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _countryCode,
          isDense: true,
          items: Validators.countryCodes.map((country) {
            return DropdownMenuItem<String>(
              value: country.code,
              child: Text('${country.name} ${country.code}'),
            );
          }).toList(),
          onChanged: _isLoading
              ? null
              : (value) {
                  setState(() {
                    _countryCode = value ?? '+92';
                  });
                },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AuthBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 18,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: AppColors.primary,
                          ),
                        ),
                        const Expanded(
                          child: Center(
                            child: PayEasyLogo(size: 29),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Create Your Account',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Get started in a few simple steps.',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textGrey,
                      ),
                    ),

                    const SizedBox(height: 25),

                    AuthTextField(
                      label: 'First Name',
                      hint: 'Enter your first name',
                      icon: Icons.person_outline,
                      controller: _firstController,
                      validator: Validators.personName,
                    ),

                    const SizedBox(height: 16),

                    AuthTextField(
                      label: 'Last Name',
                      hint: 'Enter your last name',
                      icon: Icons.person_outline,
                      controller: _lastController,
                      validator: Validators.personName,
                    ),

                    const SizedBox(height: 16),

                    AuthTextField(
                      label: 'Shop Name',
                      hint: 'Enter your shop name',
                      icon: Icons.store_outlined,
                      controller: _shopController,
                      validator: Validators.required,
                    ),

                    const SizedBox(height: 16),

                    AuthTextField(
                      label: 'Phone Number',
                      hint: 'Enter your phone number',
                      icon: Icons.phone_outlined,
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      customPrefix: _countryPicker(),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
                      validator: (value) =>
                          Validators.phoneNumber(
                        value,
                        _countryCode,
                      ),
                    ),

                    const SizedBox(height: 16),

                    AuthTextField(
                      label: 'Email Address',
                      hint: 'Enter your email address',
                      icon: Icons.email_outlined,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                    ),

                    const SizedBox(height: 16),

                    AuthTextField(
                      label: 'Password',
                      hint: 'Create a password',
                      icon: Icons.lock_outline,
                      controller: _passwordController,
                      isPassword: true,
                      validator: Validators.password,
                    ),

                    const SizedBox(height: 16),

                    AuthTextField(
                      label: 'Confirm Password',
                      hint: 'Re-enter your password',
                      icon: Icons.lock_outline,
                      controller: _confirmController,
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      validator: (value) =>
                          Validators.confirmPassword(
                        value,
                        _passwordController.text,
                      ),
                    ),

                    const SizedBox(height: 12),

                    CheckboxListTile(
                      value: _acceptTerms,
                      onChanged: _isLoading
                          ? null
                          : (value) {
                              setState(() {
                                _acceptTerms = value ?? false;
                                _showTermsError = false;
                              });
                            },
                      activeColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity:
                          ListTileControlAffinity.leading,
                      title: const Text(
                        'I agree to the Terms and Conditions and Privacy Policy.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ),

                    if (_showTermsError)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Please accept the terms to continue.',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),

                    const SizedBox(height: 10),

                    PrimaryButton(
                      label: 'Create Account',
                      isLoading: _isLoading,
                      onPressed: _handleSignUp,
                    ),

                    const SizedBox(height: 26),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(
                            color: AppColors.textGrey,
                          ),
                        ),
                        GestureDetector(
                          onTap: _isLoading
                              ? null
                              : () => Navigator.pop(context),
                          child: const Text(
                            'Log In',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
