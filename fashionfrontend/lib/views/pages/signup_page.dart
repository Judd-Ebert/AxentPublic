import 'package:Axent/views/pages/login_page.dart';
import 'package:Axent/views/pages/onboarding_page.dart';
import 'package:Axent/views/pages/auth_wrapper.dart';
import 'package:Axent/utils/page_transitions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  bool _isLoading = false;
  String? _errorMessage;
  bool _tacAccepted = false;
  bool _passwordVisible = false;

  showTermsAndConditions(BuildContext context) async {
    const url =
        'https://axent.notion.site/Terms-of-Service-26f97832788680a88f00e3a31be6c8f8';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  showPrivacyPolicy(BuildContext context) async {
    const url =
        'https://axent.notion.site/Privacy-Policy-26f97832788680fa885ee723deac2b53';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Future<void> _signUp() async {
    // Log signup attempt for analytics
    FirebaseCrashlytics.instance.log('User attempting email signup');

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (!_tacAccepted) {
      setState(() {
        _errorMessage = "Please agree to the terms and conditions.";
        _isLoading = false;
      });
      return;
    }

    if (!_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Set display name
      await credential.user?.updateDisplayName(_nameController.text.trim());

      final newUser = FirebaseAuth.instance.currentUser;
      await newUser?.reload(); // Force refresh
      final refreshedUser = FirebaseAuth.instance.currentUser;

      final idToken = await refreshedUser!.getIdToken();

      await Dio().post(
        'https://axentbackend.onrender.com/preferences/create_user/',
        options: Options(
          headers: {
            'Authorization': 'Bearer $idToken',
          },
        ),
        data: {
          'name': _nameController.text.trim(),
        },
      );

      // Log successful signup
      FirebaseCrashlytics.instance.log('Email signup successful');
      FirebaseCrashlytics.instance.setUserIdentifier(refreshedUser.uid);

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          PageTransitions.fadeSlideTransition(
            page: const OnboardingPage(),
            duration: const Duration(milliseconds: 600),
            slideOffset:
                const Offset(0.0, 0.5), // Slide up from bottom for success
          ),
          (route) => false, // This removes all previous routes
        );
      }
    } on FirebaseAuthException catch (e) {
      // Log Firebase auth errors
      FirebaseCrashlytics.instance.recordError(
        'Firebase Auth Error during signup: ${e.code}',
        StackTrace.current,
        fatal: false,
        information: [
          DiagnosticsProperty('error_code', e.code),
          DiagnosticsProperty('error_message', e.message),
          DiagnosticsProperty(
              'email_domain', _emailController.text.split('@').last),
        ],
      );

      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          errorMessage = 'An account already exists for this email.';
          break;
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address.';
          break;
        default:
          errorMessage = 'Account creation failed. Please try again.';
      }

      setState(() {
        _errorMessage = errorMessage;
      });
    } catch (e) {
      // Log unexpected errors during signup
      FirebaseCrashlytics.instance.recordError(
        'Unexpected error during signup',
        StackTrace.current,
        fatal: false,
        information: [
          DiagnosticsProperty('error_type', e.runtimeType.toString()),
          DiagnosticsProperty('error_message', e.toString()),
        ],
      );

      setState(() {
        _errorMessage = 'Something went wrong. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    // Log Google Sign-In attempt for analytics
    FirebaseCrashlytics.instance.log('User attempting Google Sign-In');

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        FirebaseCrashlytics.instance.log('User cancelled Google Sign-In');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      // Get current user and ID token
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Set user identifier for Crashlytics
        FirebaseCrashlytics.instance.setUserIdentifier(currentUser.uid);

        final idToken = await currentUser.getIdToken();

        // Check if user profile exists in backend
        bool userExists = false;
        try {
          await Dio().get(
            'https://axentbackend.onrender.com/preferences/user-profile/',
            options: Options(
              headers: {
                'Authorization': 'Bearer $idToken',
              },
            ),
          );
          FirebaseCrashlytics.instance.log('Existing user profile found');
          userExists = true;
        } catch (e) {
          // User doesn't exist, create new profile
          FirebaseCrashlytics.instance
              .log('Creating new user profile for Google user');
          try {
            await Dio().post(
              'https://axentbackend.onrender.com/preferences/create_user/',
              options: Options(
                headers: {
                  'Authorization': 'Bearer $idToken',
                },
              ),
              data: {
                'name': currentUser.displayName ?? 'Google User',
              },
            );
            FirebaseCrashlytics.instance
                .log('User profile created successfully');
          } catch (createError) {
            // Log backend errors but continue
            FirebaseCrashlytics.instance.recordError(
              'Backend user creation failed',
              StackTrace.current,
              fatal: false,
              information: [
                DiagnosticsProperty('error', createError.toString()),
                DiagnosticsProperty('user_id', currentUser.uid),
              ],
            );
          }
        }

        // Navigate based on whether user exists
        if (mounted) {
          if (userExists) {
            // Existing user - go to home
            FirebaseCrashlytics.instance
                .log('Existing user, navigating to home');
            Navigator.pushAndRemoveUntil(
              context,
              PageTransitions.fadeSlideTransition(
                page: const AuthWrapper(),
                duration: const Duration(milliseconds: 600),
                slideOffset: const Offset(0.0, 0.5),
              ),
              (route) => false,
            );
          } else {
            // New user - go to onboarding
            FirebaseCrashlytics.instance
                .log('New user, navigating to onboarding');
            Navigator.pushAndRemoveUntil(
              context,
              PageTransitions.fadeSlideTransition(
                page: const OnboardingPage(),
                duration: const Duration(milliseconds: 600),
                slideOffset: const Offset(0.0, 0.5),
              ),
              (route) => false,
            );
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      // Log Google Sign-In errors
      FirebaseCrashlytics.instance.recordError(
        'Google Sign-In Firebase Auth error: ${e.code}',
        StackTrace.current,
        fatal: false,
        information: [
          DiagnosticsProperty('error_code', e.code),
          DiagnosticsProperty('error_message', e.message),
        ],
      );

      setState(() {
        _errorMessage = e.message ?? 'Google sign-in failed. Please try again.';
      });
    } catch (e) {
      // Log unexpected Google Sign-In errors
      FirebaseCrashlytics.instance.recordError(
        'Unexpected Google Sign-In error',
        StackTrace.current,
        fatal: false,
        information: [
          DiagnosticsProperty('error_type', e.runtimeType.toString()),
          DiagnosticsProperty('error_message', e.toString()),
        ],
      );

      setState(() {
        _errorMessage = 'Google sign-in failed. Please try again. Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appleCredentail =
          await SignInWithApple.getAppleIDCredential(scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ]);

      final oAuthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredentail.identityToken,
        accessToken: appleCredentail.authorizationCode,
      );

      await FirebaseAuth.instance.signInWithCredential(oAuthCredential);

      // Get current user and ID token
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final idToken = await currentUser.getIdToken();

        // Check if user profile exists in backend
        bool userExists = false;
        try {
          await Dio().get(
            'https://axentbackend.onrender.com/preferences/user-profile/',
            options: Options(
              headers: {
                'Authorization': 'Bearer $idToken',
              },
            ),
          );
          userExists = true;
        } catch (e) {
          // User doesn't exist, create new profile
          try {
            await Dio().post(
              'https://axentbackend.onrender.com/preferences/create_user/',
              options: Options(
                headers: {
                  'Authorization': 'Bearer $idToken',
                },
              ),
              data: {
                'name': currentUser.displayName ?? 'Apple User',
              },
            );
          } catch (createError) {
            // Continue anyway - user can still use the app
          }
        }

        // Navigate based on whether user exists
        if (mounted) {
          if (userExists) {
            // Existing user - go to home
            Navigator.pushAndRemoveUntil(
              context,
              PageTransitions.fadeSlideTransition(
                page: const AuthWrapper(),
                duration: const Duration(milliseconds: 600),
                slideOffset: const Offset(0.0, 0.5),
              ),
              (route) => false,
            );
          } else {
            // New user - go to onboarding
            Navigator.pushAndRemoveUntil(
              context,
              PageTransitions.fadeSlideTransition(
                page: const OnboardingPage(),
                duration: const Duration(milliseconds: 600),
                slideOffset: const Offset(0.0, 0.5),
              ),
              (route) => false,
            );
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'Apple sign-in failed. Please try again.';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Apple sign-in failed. Please try again. Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter',
                    color: scheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // Name Field
                Text(
                  "Name",
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  cursorColor: scheme.secondary,
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(color: scheme.onSurface),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: scheme.surface,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: scheme.onSurface.withAlpha(128),
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: scheme.onSurface.withAlpha(128),
                        width: 1,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: scheme.error,
                        width: 1,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: scheme.error,
                        width: 2,
                      ),
                    ),
                    hintText: 'John Doe',
                    hintStyle: TextStyle(
                      color: scheme.secondary.withAlpha(128),
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                  ),
                ),
                const SizedBox(height: 16),

                // Email Field
                Text(
                  "Email",
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  cursorColor: scheme.secondary,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  style: TextStyle(color: scheme.onSurface),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: scheme.surface,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: scheme.onSurface.withAlpha(128),
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: scheme.onSurface.withAlpha(128),
                        width: 1,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: scheme.error,
                        width: 1,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: scheme.error,
                        width: 2,
                      ),
                    ),
                    hintText: 'johndoe@example.com',
                    hintStyle: TextStyle(
                      color: scheme.secondary.withAlpha(128),
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                  ),
                ),
                const SizedBox(height: 16),

                // Password Field
                Text(
                  "Password",
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  cursorColor: scheme.secondary,
                  obscureText: !_passwordVisible,
                  style: TextStyle(color: scheme.onSurface),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: scheme.surface,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: scheme.onSurface.withAlpha(128),
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: scheme.onSurface.withAlpha(128),
                        width: 1,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: scheme.error,
                        width: 1,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: scheme.error,
                        width: 2,
                      ),
                    ),
                    hintText: '••••••••••',
                    hintStyle: TextStyle(
                      color: scheme.secondary.withAlpha(128),
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: scheme.secondary.withAlpha(179),
                      ),
                      onPressed: () {
                        setState(() {
                          _passwordVisible = !_passwordVisible;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Terms and Conditions
                Row(
                  children: [
                    Checkbox(
                      value: _tacAccepted,
                      onChanged: (bool? newValue) {
                        setState(() {
                          _tacAccepted = newValue!;
                        });
                      },
                      activeColor: scheme.primary,
                      semanticLabel:
                          "I Agree to Terms and Conditions and Privacy Policy",
                    ),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: scheme.onSurface,
                          ),
                          children: [
                            TextSpan(text: 'I agree to the '),
                            TextSpan(
                                text: 'Terms and Conditions ',
                                style: TextStyle(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    showTermsAndConditions(context);
                                  }),
                            TextSpan(text: 'and '),
                            TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    showPrivacyPolicy(context);
                                  }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Error Message
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: scheme.onErrorContainer,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                // Google Sign-In Button
                SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    icon: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(
                              'https://developers.google.com/identity/images/g-logo.png'),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    label: Text(
                      'Continue with Google',
                      style: TextStyle(
                        fontSize: 16,
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: scheme.surface,
                      side: BorderSide(color: scheme.outline, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SignInWithAppleButton(onPressed: _signInWithApple),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'By selecting "Continue with Google" or "Sign in with Apple", you agree to our Terms and Conditions and Privacy Policy',
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: Divider(color: scheme.outline)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'or',
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: scheme.outline)),
                  ],
                ),
                const SizedBox(height: 16),

                // Sign Up Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: scheme.primary,
                      disabledBackgroundColor: scheme.primary.withAlpha(153),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: scheme.onPrimary,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 16,
                              color: scheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Login Link
                Center(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontFamily: 'Inter',
                      ),
                      children: [
                        TextSpan(
                          text: 'Already have an account? ',
                        ),
                        TextSpan(
                          text: 'Log In',
                          style: TextStyle(
                            color: scheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              // Smooth fade transition between signup and login
                              Navigator.pushReplacement(
                                context,
                                PageTransitions.fadeTransition(
                                  page: const LogInPage(),
                                  duration: const Duration(milliseconds: 300),
                                ),
                              );
                            },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
