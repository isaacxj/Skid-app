import 'package:flutter/material.dart';
import 'package:skid/services/authentication_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthenticationService();
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Image.asset('assets/logo.png', width: 150, height: 150),
              SizedBox(height: 24),
              TextFormField(
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) => _email = value.trim(),
                validator: (value) =>
                    value!.isEmpty ? 'Email is required' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                onChanged: (value) => _password = value,
                validator: (value) =>
                    value!.isEmpty ? 'Password is required' : null,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final user =
                        await _authService.signInWithEmail(_email, _password);
                    Navigator.pushReplacementNamed(context, '/home');
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to log in')));
                    }
                  }
                },
                child: Text('Login'),
              ),
              SizedBox(height: 12),
              TextButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/signup'),
                child: Text('Create Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
