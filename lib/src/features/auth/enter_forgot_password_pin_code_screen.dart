import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import 'package:phoosar/src/common/widgets/common_button.dart';
import 'package:phoosar/src/features/auth/login.dart';
import 'package:phoosar/src/features/auth/update_password_screen.dart';
import 'package:phoosar/src/providers/app_provider.dart';
import 'package:phoosar/src/utils/colors.dart';
import 'package:phoosar/src/utils/dimens.dart';
import 'package:phoosar/src/utils/fonts.dart';
import 'package:phoosar/src/utils/gap.dart';

import '../../data/request/forgot_password_otp_request.dart';
import '../../localization/app_localizations.dart';

class EnterForgotPasswordPinCodeScreen extends ConsumerStatefulWidget {
  const EnterForgotPasswordPinCodeScreen({
    super.key,
    required this.phoneNumber,
  });

  final String phoneNumber;

  @override
  ConsumerState<EnterForgotPasswordPinCodeScreen> createState() =>
      _EnterForgotPasswordPinCodeScreenState();
}

class _EnterForgotPasswordPinCodeScreenState
    extends ConsumerState<EnterForgotPasswordPinCodeScreen> {
  final _formKey = GlobalKey<FormState>();

  final PinInputController _pinController = PinInputController();

  bool isLoading = false;
  bool _isResending = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Image.asset(
            'assets/images/sign_up_bg.png',
            height: double.infinity,
            width: double.infinity,
            fit: BoxFit.fill,
          ),
          Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    80.vGap,

                    // App logo
                    Image.asset(
                      'assets/images/phoosar_img.png',
                      height: 80,
                    ),

                    40.vGap,

                    Text(
                      AppLocalizations.of(context)!.kCheckYourMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: kTextRegular2x,
                        fontWeight: FontWeight.normal,
                      ),
                    ),

                    40.vGap,

                    Text(
                      AppLocalizations.of(context)!
                          .kYourCodeIsComing
                          .toUpperCase(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 22,
                        fontFamily: kFontGibsonBold,
                      ),
                    ),

                    20.vGap,

                    // Updated PIN field
                    Center(
                      child: MaterialPinField(
                        length: 6,
                        pinController: _pinController,
                        keyboardType: TextInputType.number,
                        theme: MaterialPinTheme(
                          shape: MaterialPinShape.outlined,
                          cellSize: const Size(48, 55),
                          spacing: 8,
                          borderRadius: BorderRadius.circular(10),
                          borderColor: Colors.black,
                          focusedBorderColor: primaryColor,
                        ),
                        onCompleted: (value) {
                          // _verifyOTP();
                        },
                      ),
                    ),

                    // Resend OTP
                    TextButton(
                      onPressed:
                          (isLoading || _isResending) ? null : _requestOTP,
                      child: Text(
                        AppLocalizations.of(context)!.kResendOTPLabel,
                        style: const TextStyle(
                          fontSize: kTextRegular2x,
                          color: Colors.black,
                        ),
                      ),
                    ),

                    30.vGap,

                    // Confirm button
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 2,
                      child: CommonButton(
                        containerVPadding: 10,
                        text: AppLocalizations.of(context)!
                            .kConfirmLabel
                            .toUpperCase(),
                        fontSize: 18,
                        onTap: () {
                          if (!isLoading && !_isResending) {
                            _verifyOTP();
                          }
                        },
                        bgColor: Colors.green,
                        buttonTextColor: Colors.white,
                        isLoading: isLoading,
                      ),
                    ),

                    60.vGap,

                    // Already have an account
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: kTextRegular2x,
                          color: Colors.black,
                        ),
                        children: [
                          TextSpan(
                            text: AppLocalizations.of(context)!
                                .kAlreadyHaveAccount,
                            style: const TextStyle(
                              fontFamily: kFontArticulatCFNormal,
                            ),
                          ),
                          TextSpan(
                            text: AppLocalizations.of(context)!.kSignInLabel,
                            style: const TextStyle(
                              fontFamily: kFontArticulatCFNormal,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                if (isLoading || _isResending) {
                                  return;
                                }

                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                );
                              },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------
  // RESEND FORGOT PASSWORD OTP
  // -----------------------------------

  Future<void> _requestOTP() async {
    if (isLoading || _isResending) return;

    setState(() {
      _isResending = true;
    });

    try {
      final request = ForgotPasswordOtpRequest(
        phone: widget.phoneNumber,
      );

      await ref.read(repositoryProvider).forgotPasswordOtpRequest(
            request,
            context,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP request completed.'),
        ),
      );
    } catch (error) {
      debugPrint('Resend forgot password OTP error: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to resend OTP. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  // -----------------------------------
  // VERIFY FORGOT PASSWORD OTP
  // -----------------------------------

  Future<void> _verifyOTP() async {
    if (isLoading || _isResending) return;

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) return;

    final pin = _pinController.text.trim();

    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a valid 6-digit OTP code.',
          ),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response =
          await ref.read(repositoryProvider).forgotPasswordVerifyOTP(
                jsonEncode({
                  "phone": widget.phoneNumber,
                  "otp": pin,
                }),
                context,
              );

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Clear OTP after successful verification
        _pinController.clear();

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => UpdatePasswordScreen(
              phoneNumber: widget.phoneNumber,
            ),
          ),
        );
      } else {
        _pinController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Invalid OTP. Please try again.',
            ),
          ),
        );
      }
    } catch (error) {
      debugPrint('Forgot password OTP verification error: $error');

      if (!mounted) return;

      _pinController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'OTP verification failed. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
}
