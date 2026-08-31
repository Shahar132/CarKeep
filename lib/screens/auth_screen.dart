import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  // Optional actions for Widget Tests.
  //
  // When they are not supplied, the screen
  // continues using the real Supabase Auth.
  final Future<void> Function(
    String email,
    String password,
  )? signInAction;

  // Returns true when sign up created
  // an active session immediately.
  //
  // Returns false when email confirmation
  // is still required.
  final Future<bool> Function(
    String name,
    String email,
    String password,
  )? signUpAction;

  const AuthScreen({
    super.key,
    this.signInAction,
    this.signUpAction,
  });

  @override
  State<AuthScreen> createState() =>
      _AuthScreenState();
}

class _AuthScreenState
    extends State<AuthScreen> {
  final nameController =
      TextEditingController();

  final emailController =
      TextEditingController();

  final passwordController =
      TextEditingController();

  bool isLogin = true;
  bool isLoading = false;

  Future<void> performSignIn({
    required String email,
    required String password,
  }) async {
    if (widget.signInAction != null) {
      await widget.signInAction!(
        email,
        password,
      );

      return;
    }

    await Supabase.instance.client.auth
        .signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<bool> performSignUp({
    required String name,
    required String email,
    required String password,
  }) async {
    if (widget.signUpAction != null) {
      return widget.signUpAction!(
        name,
        email,
        password,
      );
    }

    final response =
        await Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
      },
    );

    return response.session != null;
  }

  Future<void> submit() async {
    final name =
        nameController.text.trim();

    final email =
        emailController.text.trim();

    final password =
        passwordController.text.trim();

    if (!isLogin && name.isEmpty) {
      showMessage(
        'יש להזין שם',
      );

      return;
    }

    if (email.isEmpty ||
        password.isEmpty) {
      showMessage(
        'יש למלא אימייל וסיסמה',
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      if (isLogin) {
        await performSignIn(
          email: email,
          password: password,
        );
      } else {
        final hasSession =
            await performSignUp(
          name: name,
          email: email,
          password: password,
        );

        if (!mounted) {
          return;
        }

        if (!hasSession) {
          showMessage(
            'החשבון נוצר. יש לאשר את האימייל לפני ההתחברות.',
          );

          setState(() {
            isLogin = true;
          });
        }
      }
    } on AuthException catch (error) {
      showMessage(
        error.message,
      );
    } catch (error) {
      debugPrint(
        'Unexpected authentication error: $error',
      );

      showMessage(
        'אירעה שגיאה. נסה שוב.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  Widget buildLogo() {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(24),
      child: Image.asset(
        'assets/icon/app_icon.png',
        width: 100,
        height: 100,
        fit: BoxFit.cover,
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child:
              SingleChildScrollView(
            padding:
                const EdgeInsets.all(
              24,
            ),
            child:
                ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 420,
              ),
              child:
                  Column(
                children: [
                  buildLogo(),

                  const SizedBox(
                    height: 20,
                  ),

                  Text(
                    isLogin
                        ? 'ברוך הבא'
                        : 'יצירת חשבון',
                    style:
                        const TextStyle(
                      fontSize: 28,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          AppTheme.textPrimary,
                    ),
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  Text(
                    isLogin
                        ? 'התחבר כדי לנהל את הרכבים שלך'
                        : 'צור חשבון והתחל לנהל את הרכבים שלך',
                    textAlign:
                        TextAlign.center,
                    style:
                        const TextStyle(
                      fontSize: 14,
                      color:
                          AppTheme.textSecondary,
                    ),
                  ),

                  const SizedBox(
                    height: 28,
                  ),

                  Card(
                    child:
                        Padding(
                      padding:
                          const EdgeInsets.all(
                        20,
                      ),
                      child:
                          Column(
                        children: [
                          if (!isLogin) ...[
                            TextField(
                              controller:
                                  nameController,
                              decoration:
                                  const InputDecoration(
                                labelText:
                                    'שם',
                                prefixIcon:
                                    Icon(
                                  Icons
                                      .person_outline,
                                ),
                              ),
                            ),

                            const SizedBox(
                              height: 16,
                            ),
                          ],

                          TextField(
                            controller:
                                emailController,
                            keyboardType:
                                TextInputType
                                    .emailAddress,
                            textDirection:
                                TextDirection.ltr,
                            decoration:
                                const InputDecoration(
                              labelText:
                                  'אימייל',
                              prefixIcon:
                                  Icon(
                                Icons
                                    .email_outlined,
                              ),
                            ),
                          ),

                          const SizedBox(
                            height: 16,
                          ),

                          TextField(
                            controller:
                                passwordController,
                            obscureText: true,
                            textDirection:
                                TextDirection.ltr,
                            decoration:
                                const InputDecoration(
                              labelText:
                                  'סיסמה',
                              prefixIcon:
                                  Icon(
                                Icons
                                    .lock_outline,
                              ),
                            ),
                          ),

                          const SizedBox(
                            height: 24,
                          ),

                          SizedBox(
                            width:
                                double.infinity,
                            child:
                                ElevatedButton(
                              onPressed:
                                  isLoading
                                      ? null
                                      : submit,
                              child:
                                  isLoading
                                      ? const SizedBox(
                                          width:
                                              20,
                                          height:
                                              20,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth:
                                                2,
                                          ),
                                        )
                                      : Text(
                                          isLogin
                                              ? 'התחבר'
                                              : 'הרשם',
                                        ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  TextButton(
                    onPressed:
                        isLoading
                            ? null
                            : () {
                                setState(() {
                                  isLogin =
                                      !isLogin;
                                });
                              },
                    child:
                        Text(
                      isLogin
                          ? 'אין לך חשבון? הירשם'
                          : 'כבר יש לך חשבון? התחבר',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}