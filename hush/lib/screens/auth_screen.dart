import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _signIn() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (res.session == null) {
        setState(() { _error = 'Sign in failed'; });
      }
    } catch (e) {
      setState(() { _error = e.toString(); });
    }
    setState(() { _isLoading = false; });
  }

  Future<void> _signUp() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final res = await Supabase.instance.client.auth.signUp(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (res.user == null) {
        setState(() { _error = 'Sign up failed'; });
      }
    } catch (e) {
      setState(() { _error = e.toString(); });
    }
    setState(() { _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign In / Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            if (_error != null) ...[
              SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: Colors.red)),
            ],
            SizedBox(height: 24),
            if (_isLoading)
              CircularProgressIndicator()
            else ...[
              ElevatedButton(
                onPressed: _signIn,
                child: Text('Sign In'),
              ),
              SizedBox(height: 12),
              OutlinedButton(
                onPressed: _signUp,
                child: Text('Sign Up'),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
