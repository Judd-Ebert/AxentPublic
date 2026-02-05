import 'package:Axent/views/pages/auth_wrapper.dart';
import 'package:Axent/views/pages/signup_page.dart';
import 'package:Axent/utils/page_transitions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class LogInPage extends StatefulWidget {
  const LogInPage({super.key});

  @override
  State<LogInPage> createState() => _LogInPageState();
}

class _LogInPageState extends State<LogInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  bool _isLoading = false;
  String? _errorMessage;
  bool _passwordVisible = false;

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    final scheme = Theme.of(context).colorScheme;

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter your email address first.'),
          backgroundColor: scheme.error,
        ),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Password reset email sent! Check your inbox(inclduing spam and junk folders).'),
            backgroundColor: scheme.primary,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address.';
          break;
        case 'user-not-found':
          errorMessage = 'No account found with this email address.';
          break;
        default:
          errorMessage = 'Failed to send reset email. Please try again.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: scheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Something went wrong. Please try again.'),
            backgroundColor: scheme.error,
          ),
        );
      }
    }
  }

  Future<void> _logIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill out all fields.';
        _isLoading = false;
      });
      return;
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          PageTransitions.fadeSlideTransition(
            page: AuthWrapper(),
            duration: const Duration(milliseconds: 600),
            slideOffset:
                const Offset(0.0, 0.5), // Slide up from bottom for success
          ),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'invalid-credential':
        case 'user-not-found':
        case 'wrong-password':
          errorMessage = 'Invalid email or password. Please try again.';
          break;
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many failed attempts. Please try again later.';
          break;
        default:
          errorMessage = 'Login failed. Please try again.';
      }

      setState(() {
        _errorMessage = errorMessage;
      });
    } catch (e) {
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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
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
        final idToken = await currentUser.getIdToken();

        // Check if user profile exists in backend
        try {
          await Dio().get(
            'https://axentbackend.onrender.com/preferences/user-profile/',
            options: Options(
              headers: {
                'Authorization': 'Bearer $idToken',
              },
            ),
          );
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
                'name': currentUser.displayName ?? 'Google User',
              },
            );
          } catch (createError) {
            // Continue anyway - user can still use the app
          }
        }
      }

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          PageTransitions.fadeSlideTransition(
            page: AuthWrapper(),
            duration: const Duration(milliseconds: 600),
            slideOffset: const Offset(0.0, 0.5),
          ),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'Google sign-in failed. Please try again.';
      });
    } catch (e) {
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
        try {
          await Dio().get(
            'https://axentbackend.onrender.com/preferences/user-profile/',
            options: Options(
              headers: {
                'Authorization': 'Bearer $idToken',
              },
            ),
          );
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
                'name': currentUser.displayName ?? 'Google User',
              },
            );
          } catch (createError) {
            // Continue anyway - user can still use the app
          }
        }
      }

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          PageTransitions.fadeSlideTransition(
            page: AuthWrapper(),
            duration: const Duration(milliseconds: 600),
            slideOffset: const Offset(0.0, 0.5),
          ),
          (route) => false,
        );
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
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
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter',
                    color: scheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
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
                  style: TextStyle(
                    color: scheme.onSurface,
                  ),
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
                  style: TextStyle(
                    color: scheme.onSurface,
                  ),
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
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _resetPassword,
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: scheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
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
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _logIn,
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
                            'Log In',
                            style: TextStyle(
                              fontSize: 16,
                              color: scheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: RichText(
                      text: TextSpan(children: [
                    TextSpan(
                      text: 'Don\'t have an account? ',
                      style: TextStyle(
                        color: scheme.primary,
                      ),
                    ),
                    TextSpan(
                      text: 'Sign Up',
                      style: TextStyle(
                        color: scheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          // Smooth fade transition between login and signup
                          Navigator.pushReplacement(
                            context,
                            PageTransitions.fadeTransition(
                              page: const SignupPage(),
                              duration: const Duration(milliseconds: 300),
                            ),
                          );
                        },
                    ),
                  ])),
                ),
              ],
            ),
          ),
        ),
      )
    );
  }
}
