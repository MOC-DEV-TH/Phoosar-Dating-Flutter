import 'dart:convert';
import 'dart:io';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:phoosar/env/env.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:phoosar/src/common/widgets/common_button.dart';
import 'package:phoosar/src/common/widgets/email_and_phone_number_view.dart';
import 'package:phoosar/src/common/widgets/horizontal_text_icon_button.dart';
import 'package:phoosar/src/common/widgets/input_view.dart';
import 'package:phoosar/src/data/models/facebook_user.dart';
import 'package:phoosar/src/data/response/authentication_response.dart';
import 'package:phoosar/src/data/response/self_profile_response.dart';
import 'package:phoosar/src/features/auth/choose_gender_screen.dart';
import 'package:phoosar/src/features/auth/forgot_password_screen.dart';
import 'package:phoosar/src/features/auth/register.dart';
import 'package:phoosar/src/features/home/home.dart';
import 'package:phoosar/src/features/onboarding_screen/onboarding_screen.dart';
import 'package:phoosar/src/providers/app_provider.dart';
import 'package:phoosar/src/providers/data_providers.dart';
import 'package:phoosar/src/providers/profile_provider.dart';
import 'package:phoosar/src/providers/profiles_provider.dart';
import 'package:phoosar/src/providers/room_provider.dart';
import 'package:phoosar/src/services/facebook_analytics_service.dart';
import 'package:phoosar/src/utils/colors.dart';
import 'package:phoosar/src/utils/constants.dart';
import 'package:phoosar/src/utils/dimens.dart';
import 'package:phoosar/src/utils/gap.dart';
import 'package:phoosar/src/utils/strings.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../localization/app_localizations.dart';

import '../../services/tiktok_events.dart';
import '../../utils/fonts.dart';
import 'eula_view.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({
    Key? key,
  }) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;
  static Future<void>? _googleInitialization;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  ///Email or Phone number
  String selectedText = "Phone";
  String e164PhoneNo = "";
  PhoneNumber phone = PhoneNumber(isoCode: 'MM');
  TextEditingController _phoneController = TextEditingController();
  bool isLoading = false;
  String? recentOnBoarding;
  bool haveNavigated = false;
  String? recentOnboardingStatus;
  bool isShowPassword = true;
  bool _hasAgreedToTerms = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void onTapToggleObscured(){
    setState(() {
      isShowPassword = !isShowPassword;
    });
  }

  Future<void> saveSupabaseUserId(String userId) async {
    var response = await ref.read(repositoryProvider).saveSupabaseUserId(
      {
        "supabase_user_id": userId.toString(),
      },
      context,
    );
    if (response.statusCode.toString().startsWith("2")) {
      navigateToNextScreen();
    } else {
      // Handle error response
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Image.asset(
            'assets/images/signin_bg.png',
            height: double.infinity,
            width: double.infinity,
            fit: BoxFit.fill,
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ///app icon
                    Image.asset(
                      'assets/images/white_logo.png',
                      height: 80,
                    ),
                    80.vGap,

                    Text(
                      AppLocalizations.of(context)!.kPhoneNumberLabel.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.cyan,
                          fontSize: 22,fontFamily: kFontGibsonBold),
                    ),

                    20.vGap,

                    ///phone number and password input view
                    Visibility(
                      visible: true,
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                    color: Colors.white,
                                    width: 1),
                                borderRadius: BorderRadius.circular(4.0)),
                            child: InternationalPhoneNumberInput(
                              onInputChanged: (PhoneNumber number) {
                                print(number.phoneNumber);
                                setState(() {
                                  e164PhoneNo = number.phoneNumber.toString();
                                });
                              },
                              onInputValidated: (bool value) {
                                print(value);
                              },
                              selectorConfig: SelectorConfig(
                                leadingPadding: 12,
                                selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                              ),
                              ignoreBlank: false,
                              initialValue: phone,
                              hintText: '',
                              textAlignVertical: TextAlignVertical.top,
                              autoValidateMode: AutovalidateMode.disabled,
                              selectorTextStyle: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold,color: Colors.black),
                              textFieldController: _phoneController,
                              formatInput: true,
                              cursorColor: Colors.black,
                              textStyle: TextStyle(color: Colors.black),
                              keyboardType: TextInputType.number,
                              keyboardAction: TextInputAction.done,
                              inputBorder: InputBorder.none,
                              onSaved: (PhoneNumber number) {
                                print('On Saved: $number');
                              },
                            ),
                          ),

                          24.vGap,

                          ///password input
                          InputView(
                              bgColor: Colors.white,
                              cursorColor: Colors.black,
                              controller: passwordController,
                              hintTextColor: Colors.black,
                              isSecure : isShowPassword,
                              isPasswordView: true,
                              toggleObscured: onTapToggleObscured,
                              toggleObscuredColor: Colors.black,
                              hintLabel:
                              AppLocalizations.of(context)!.kPasswordLabel),
                        ],
                      ),
                    ),

                    40.vGap,

                    ///sign in
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 2,
                      child: CommonButton(
                        containerVPadding: 10,
                        text: AppLocalizations.of(context)!.kSignInLabel.toUpperCase(),
                        fontSize: 18,
                        buttonTextColor: Colors.white,
                        isLoading: _isLoading,
                        onTap: () {
                          if (!_isLoading) {
                            _signIn();
                          }
                        },
                        bgColor: primaryColor,
                      ),
                    ),

                    20.vGap,

                    ///forgot password
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ForgotPasswordScreen(
                                type: selectedText.toLowerCase()),
                          ),
                        );
                      },
                      child: Text(
                        AppLocalizations.of(context)!.kForgotPasswordLabel,
                        style:
                        TextStyle(fontSize: kTextRegular2x, color: Color(0xFFF5D5DD)),
                      ),
                    ),

                    60.vGap,

                    ///facebook and google sign in view
                    Visibility(
                      visible: false,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ///facebook signIn button
                          HorizontalTextIconButton(
                              onTap: () {
                                facebookSignIn(context);
                              },
                              icon: Icon(
                                Icons.facebook,
                                color: Colors.blue,
                              ),
                              text: AppLocalizations.of(context)!.kSignInLabel),

                          20.hGap,

                          ///google signIn button
                          HorizontalTextIconButton(
                              onTap: () {
                                googleSignIn();
                              },
                              icon: Image.asset(
                                'assets/images/google.jpg',
                                height: 24,
                                fit: BoxFit.cover,
                              ),
                              text: AppLocalizations.of(context)!.kSignInLabel),
                        ],
                      ),
                    ),

                    40.vGap,

                    ///dont have account
                    RichText(
                      text: new TextSpan(
                        style: new TextStyle(
                          fontSize: kTextRegular2x,
                          color: Colors.grey,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                              text: AppLocalizations.of(context)!.kDontHaveAccount,style: TextStyle(color: Colors.white,fontFamily: kFontArticulatCFNormal)),
                          TextSpan(
                            text: AppLocalizations.of(context)!.kSignUpLabel,
                            style: new TextStyle(
                                fontFamily: kFontArticulatCFNormal,
                                fontWeight: FontWeight.bold, color: Colors.cyan),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RegisterScreen(),
                                  ),
                                );
                              },
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signIn() async {
    if (_isLoading) return;
    if (e164PhoneNo.trim().isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter phone number and password.')),
      );
      return;
    }

    // Never include credentials, phone numbers, or passwords in analytics.
    FacebookAnalyticsService.instance.logEvent(
      name: 'login',
      parameters: {'method': 'phone'},
    );
    await FirebaseAnalytics.instance.logEvent(
      name: 'login',
      parameters: {'method': 'phone'},
    );
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final response = await ref.read(repositoryProvider).login(
        jsonEncode({
          'type': 'phone',
          'value': e164PhoneNo,
          'password': passwordController.text,
        }),
        context,
      );
      if (!mounted) return;
      if (!response.statusCode.toString().startsWith('2')) return;

      final authResponse = AuthenticationResponse.fromJson(
        jsonDecode(response.body),
      );
      final prefs = ref.read(sharedPrefProvider);
      await prefs.setString(kTokenKey, authResponse.token ?? '');
      await prefs.setString(
        kRecentOnboardingKey,
        authResponse.recentOnBoarding ?? '',
      );

      final profileRes = await ref.read(repositoryProvider).getProfile(
        jsonEncode({}), context,
      );
      if (!mounted) return;
      final data = SelfProfileResponse.fromJson(jsonDecode(profileRes.body));
      ref.read(selfProfileProvider.notifier).state = data;
      recentOnboardingStatus = authResponse.recentOnBoarding ?? '';
      recentOnBoarding = authResponse.recentOnBoarding;

      await supabase.auth.signInWithPassword(
        email: 'user$e164PhoneNo@gmail.com',
        password: passwordController.text,
      );
      if (!mounted) return;
      await navigateToNextScreen();
    } on AuthException catch (error) {
      if (mounted) context.showErrorSnackBar(message: error.message);
    } catch (error) {
      debugPrint('Login failed: $error');
      if (mounted) {
        context.showErrorSnackBar(message: unexpectedErrorMessage);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> navigateToNextScreen() async {
    if (!mounted) return;
    ref.invalidate(profilesProvider);
    ref.invalidate(profileProvider);
    ref.invalidate(roomsProvider);
    ref.invalidate(supabaseClientProvider);

    // Avoid transmitting personal identifiers in marketing analytics.
    await TikTokEvents.trackEvent('Login', properties: {'method': 'phone'});
    if (!mounted) return;

    await ref.read(sharedPrefProvider).setString(
      kRecentOnboardingKey,
      recentOnboardingStatus ?? '',
    );
    if (!mounted) return;

    if (recentOnboardingStatus == kProfileStatus) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ChooseGenderScreen()),
      );
    } else if (recentOnboardingStatus == kQuestionStatus) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => OnBoardingScreen()),
      );
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => HomeScreen()),
            (_) => false,
      );
    }
  }

  Future<void> googleSignIn() async {
    try {
      final google = GoogleSignIn.instance;
      _googleInitialization ??= google.initialize(
        clientId: Platform.isIOS ? Env.googleClientId : null,
      );
      await _googleInitialization;

      if (!google.supportsAuthenticate()) {
        throw StateError('Interactive Google Sign-In unsupported on this platform');
      }
      final account = await google.authenticate();
      const scopes = <String>['email'];
      final auth = await account.authorizationClient.authorizationForScopes(scopes)
          ?? await account.authorizationClient.authorizeScopes(scopes);
      if (!mounted) return;
      await loginWithSocialToken(
        auth.accessToken,
        'google',
        account.photoUrl ?? '',
        account.displayName ?? '',
        account.email,
      );
    } on GoogleSignInException catch (error) {
      debugPrint('Google Sign-In failed: $error');
    } catch (error) {
      debugPrint('Google login failed: $error');
    }
  }

  supabaseSocialRegister(String email, String name) async {
    // Supabase Register
    try {
      var authState = await supabase.auth.signUp(
        email: email,
        password: email,
        data: {
          'username': name,
          'device_token': 'device_token',
        },
        emailRedirectTo: 'io.supabase.chat://login',
      );
      saveSupabaseUserId(authState.session!.user.id.toString());
    } on AuthException catch (error) {
      debugPrint(error.toString());
      context.showErrorSnackBar(message: error.message);
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (error) {
      debugPrint(error.toString());
      context.showErrorSnackBar(message: unexpectedErrorMessage);
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  facebookSignIn(BuildContext context) async {
    await FacebookAuth.instance.login(
      permissions: ['email'],
    ).then((result) {
      FacebookAuth.instance.getUserData().then((userData) async {
        // log("Facebook userData => $userData");

        // or FacebookAuth.i.login()
        if (result.status == LoginStatus.success) {
          final userProfile = FacebookUser.fromJson(userData);
          var name = userProfile.name;
          var email = userProfile.email;
          var avator = userProfile.pictureUrl;
          // you are logged
          final AccessToken accessToken = result.accessToken!;
          loginWithSocialToken(accessToken.tokenString, "facebook", avator,
              name, email); // print(result.accessToken!.token
        } else if (result.status == LoginStatus.cancelled) {
        } else if (result.status == LoginStatus.failed) {}
      });
    }); // by default we request the email and the public profile
  }

  loginWithSocialToken(String socialToken, String type, String avator,
      String name, String email) async {
    // Sanitize the username
    String sanitizedName =
    name.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_').toLowerCase();
    if (sanitizedName.length > 30) {
      sanitizedName = sanitizedName.substring(0, 30);
    }

    var response = await ref.read(repositoryProvider).socialLogin(
      jsonEncode({
        "provider": type,
        "provider_id": socialToken,
        "email": email,
        "name": sanitizedName
      }),
      context,
    );
    if (response.statusCode.toString().startsWith("2")) {
      AuthenticationResponse authResponse =
      AuthenticationResponse.fromJson(jsonDecode(response.body));
      ref
          .read(sharedPrefProvider)
          .setString(kTokenKey, authResponse.token ?? '');

      if (authResponse.type == "old") {
        setState(() {
          recentOnboardingStatus = authResponse.recentOnBoarding ?? '';
        });

        supabaseSocialLogin(email);
      } else {
        setState(() {
          recentOnboardingStatus = kProfileStatus;
        });
        supabaseSocialRegister(email, sanitizedName);
      }
    }
  }

  supabaseSocialLogin(String email) async {
    try {
      var authState = await supabase.auth.signInWithPassword(
        email: email,
        password: email,
      );
      saveSupabaseUserId(authState.session!.user.id.toString());
    } on AuthException catch (error) {
      setState(() {
        _isLoading = false;
      });
      context.showErrorSnackBar(message: error.message);
    } catch (_) {
      setState(() {
        _isLoading = false;
      });
      context.showErrorSnackBar(message: unexpectedErrorMessage);
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
