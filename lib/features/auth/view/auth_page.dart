import 'package:flutter/material.dart';
import 'package:habit_app/core/models/contants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

bool showSignIn = true;

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Habit App",
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      SizedBox(width: 10),
                      Icon(
                        Icons.track_changes,
                        size: 72,
                        color: Colors.deepOrange,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child:
                      showSignIn
                          ? _SignInForm(
                            onSignIn: (email, password) async {
                              try {
                                final supabase = Supabase.instance.client;
                                final res = await supabase.auth
                                    .signInWithPassword(
                                      email: email,
                                      password: password,
                                    );
                                // await PushService.initAndRegisterToken();
                                if (res.user != null && mounted) {
                                  final supabase = Supabase.instance.client;
                                  final user = res.user!;

                                  // Check if profile already exists
                                  final existing =
                                      await supabase
                                          .from('profiles')
                                          .select('id')
                                          .eq('id', user.id)
                                          .maybeSingle();

                                  // Insert only if profile doesn't exist
                                  if (existing == null) {
                                    await supabase.from('profiles').insert({
                                      'id': user.id,
                                      'name': '', // optional placeholder
                                      'surname': '', // optional placeholder
                                      'phone': '', // optional placeholder
                                      'email': user.email,
                                    });
                                  }
                                }
                              } on AuthException catch (e) {
                                final msg = e.message.toLowerCase();
                                final snack =
                                    msg.contains('email') &&
                                            msg.contains('confirm')
                                        ? const SnackBar(
                                          content: Text(
                                            'Please confirm your email to log in.',
                                          ),
                                        )
                                        : SnackBar(
                                          content: Text(
                                            'Login failed: ${e.message}',
                                          ),
                                        );
                                if (mounted) {
                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(snack);
                                }
                              }
                            },
                          )
                          : _SignUpForm(
                            // This function will be called on successful sign-up
                            onSignUpSuccess:
                                () => setState(() => showSignIn = true),
                          ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      showSignIn
                          ? "Don't have an account?"
                          : 'Already have an account?',
                    ),
                    TextButton(
                      onPressed: () => setState(() => showSignIn = !showSignIn),
                      child: Text(
                        showSignIn ? 'Sign Up!' : 'Log In!',
                        style: TextStyle(color: AppColors.accentRed),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SignUpForm extends StatefulWidget {
  final VoidCallback onSignUpSuccess;
  const _SignUpForm({required this.onSignUpSuccess});
  @override
  State<_SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<_SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _passwordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _nameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
  // In auth_page.dart -> class _SignUpFormState

  Future<void> _signUpUser(String email, String password) async {
    // Add a mounted check for safety, especially with async operations
    if (!mounted) return;

    try {
      final supabase = Supabase.instance.client;

      // Sign up the user and pass the additional data
      await supabase.auth.signUp(
        email: email,
        password: password,
        // This 'data' is passed as raw_user_meta_data to your trigger
        data: {
          'name': _nameController.text.trim(),
          'surname': _surnameController.text.trim(),
          'phone':
              _phoneController.text.trim().isEmpty
                  ? null
                  : _phoneController.text.trim(),
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Account created! Please check your email to confirm.',
            ),
          ),
        );

        widget.onSignUpSuccess();
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sign-up failed: ${e.message}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          const SizedBox(height: 15),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(30)),
              ),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Enter your name' : null,
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: _surnameController,
            decoration: const InputDecoration(
              labelText: 'Surname',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(30)),
              ),
            ),
            validator:
                (v) => v == null || v.isEmpty ? 'Enter your surname' : null,
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(30)),
              ),
            ),
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(30)),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter email';
              if (!v.contains('@')) return 'Enter valid email';
              return null;
            },
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: _passwordController,
            obscureText: !_passwordVisible,
            decoration: InputDecoration(
              labelText: 'Password',
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(30)),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _passwordVisible ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed:
                    () => setState(() => _passwordVisible = !_passwordVisible),
              ),
            ),
            validator:
                (v) => v != null && v.length >= 6 ? null : 'Password too short',
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: _confirmController,
            obscureText: !_passwordVisible,
            decoration: const InputDecoration(
              labelText: 'Confirm Password',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(30)),
              ),
            ),
            validator:
                (v) =>
                    v == _passwordController.text
                        ? null
                        : "Passwords don’t match",
          ),
          const SizedBox(height: 20),

          FilledButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(AppColors.primaryBlue),
            ),
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                await _signUpUser(
                  _emailController.text.trim(),
                  _passwordController.text.trim(),
                );
              }
            },
            child: const Text('Create Account'),
          ),
        ],
      ),
    );
  }
}

class _SignInForm extends StatefulWidget {
  final void Function(String email, String password) onSignIn;
  const _SignInForm({required this.onSignIn});

  @override
  State<_SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<_SignInForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSignIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(30)),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter email';
              if (!v.contains('@')) return 'Enter valid email';
              return null;
            },
          ),
          const SizedBox(height: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                  ),
                ),
                validator:
                    (v) => v == null || v.isEmpty ? 'Enter password' : null,
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(color: AppColors.accentRed),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(AppColors.primaryBlue),
            ),
            onPressed: _submit,
            child: const Text('Log In'),
          ),
          const SizedBox(height: 15),
        ],
      ),
    );
  }
}
