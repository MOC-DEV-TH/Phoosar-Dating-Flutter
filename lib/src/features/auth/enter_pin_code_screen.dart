
import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import 'package:phoosar/src/common/widgets/common_button.dart';
import 'package:phoosar/src/features/auth/enter_password_screen.dart';
import 'package:phoosar/src/features/auth/login.dart';
import 'package:phoosar/src/providers/app_provider.dart';
import 'package:phoosar/src/utils/colors.dart';
import 'package:phoosar/src/utils/dimens.dart';
import 'package:phoosar/src/utils/fonts.dart';
import 'package:phoosar/src/utils/gap.dart';

import '../../localization/app_localizations.dart';

class EnterPinCodeScreen extends ConsumerStatefulWidget {
  const EnterPinCodeScreen({
    super.key,
    required this.email,
    required this.type,
    required this.userName,
    required this.phoneNumber,
  });

  final String email;
  final String type;
  final String userName;
  final String phoneNumber;

  @override
  ConsumerState<EnterPinCodeScreen> createState() =>
      _EnterPinCodeScreenState();
}

class _EnterPinCodeScreenState
    extends ConsumerState<EnterPinCodeScreen> {
  final _formKey = GlobalKey<FormState>();

  final PinInputController _pinController =
  PinInputController();

  bool isLoading = false;

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
                      AppLocalizations.of(context)!
                          .kCheckYourMessage,
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

                    // PIN input
                    Center(
                      child: MaterialPinField(
                        length: 6,
                        pinController: _pinController,
                        keyboardType: TextInputType.number,
                        theme: MaterialPinTheme(
                          shape: MaterialPinShape.outlined,
                          cellSize: const Size(50, 50),
                          spacing: 8,
                          borderRadius: BorderRadius.circular(10),
                          borderWidth: 1.5,
                          focusedBorderWidth: 2,
                          borderColor: Colors.black,
                          focusedBorderColor: primaryColor,
                        ),
                        onCompleted: (value) {
                          // Optional automatic OTP verification:
                          // _verifyOTP();
                        },
                      ),
                    ),

                    // Resend OTP
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () {
                        _requestOTP();
                      },
                      child: Text(
                        AppLocalizations.of(context)!
                            .kResendOTPLabel,
                        style: const TextStyle(
                          fontSize: kTextRegular2x,
                          color: Colors.black,
                        ),
                      ),
                    ),

                    30.vGap,

                    // Confirm button
                    SizedBox(
                      width:
                      MediaQuery.of(context).size.width / 2,
                      child: CommonButton(
                        containerVPadding: 10,
                        text: AppLocalizations.of(context)!
                            .kConfirmLabel
                            .toUpperCase(),
                        fontSize: 18,
                        onTap: () {
                          if (!isLoading) {
                            _verifyOTP();
                          }
                        },
                        bgColor: Colors.green,
                        buttonTextColor: Colors.white,
                        isLoading: isLoading,
                      ),
                    ),

                    60.vGap,

                    // Already have account
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
                              fontFamily:
                              kFontArticulatCFNormal,
                            ),
                          ),

                          TextSpan(
                            text: AppLocalizations.of(context)!
                                .kSignInLabel,
                            style: const TextStyle(
                              fontFamily:
                              kFontArticulatCFNormal,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                if (isLoading) return;

                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                    const LoginScreen(),
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

  // ----------------------------------
  // RESEND OTP
  // ----------------------------------

  Future<void> _requestOTP() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      await ref.read(repositoryProvider).sendOTP(
        jsonEncode({
          "type": widget.type,
          "value": widget.type == "email"
              ? widget.email
              : widget.phoneNumber,
          "user_name": widget.userName,
        }),
        context,
      );
    } catch (error) {
      debugPrint('Resend OTP error: $error');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to resend OTP. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ----------------------------------
  // VERIFY OTP
  // ----------------------------------

  Future<void> _verifyOTP() async {
    if (isLoading) return;

    final isValid =
        _formKey.currentState?.validate() ?? false;

    if (!isValid) return;

    final pin = _pinController.text.trim();

    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 6-digit OTP code.'),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response =
      await ref.read(repositoryProvider).verifyOTP(
        jsonEncode({
          "type": widget.type,
          "value": widget.type == "email"
              ? widget.email
              : widget.phoneNumber,
          "user_name": widget.userName,
          "otp": pin,
        }),
        context,
      );

      if (!mounted) return;

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => EnterPasswordScreen(
              email: widget.email,
              type: widget.type,
              userName: widget.userName,
              phoneNumber: widget.phoneNumber,
            ),
          ),
        );
      } else {
        _pinController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid OTP. Please try again.'),
          ),
        );
      }
    } catch (error) {
      debugPrint('Verify OTP error: $error');

      if (!mounted) return;

      _pinController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP verification failed. Please try again.'),
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
