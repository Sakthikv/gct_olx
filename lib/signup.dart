import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'login_page.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _agreeToTerms = false;
  bool _isEmailVerified = false;
  bool _isLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _batchController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;

  Future<void> _verifyEmail() async {
    setState(() => _isLoading = true);
    final String apiUrl = "https://gctolx-api-gi75.onrender.com/signup_validation";
    final String email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@gct.ac.in')) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Enter a valid gct email.")));
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"gct_mail_id": email}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 409) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseData['error'])));
      } else if (response.statusCode == 200) {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: _passwordController.text,
        );
        _user = userCredential.user;

        if (_user != null && !_user!.emailVerified) {
          await _user!.sendEmailVerification();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Verification email sent. Please check your inbox."),
          ));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Unexpected error. Please try again.")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("API Request Failed: $e")));
    }
    setState(() => _isLoading = false);
  }

  Future<void> _checkVerificationStatus() async {
    setState(() => _isLoading = true);
    await _user?.reload();
    _user = _auth.currentUser;
    if (_user != null && _user!.emailVerified) {
      setState(() {
        _isEmailVerified = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Email Verified! You can now sign up.")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Email not verified yet. Please check again later.")));
    }
    setState(() => _isLoading = false);
  }

  Future<void> _signupUser() async {
    if (!_formKey.currentState!.validate() || !_agreeToTerms || !_isEmailVerified) {
      return;
    }

    setState(() => _isLoading = true);
    final String apiUrl = "https://gctolx-api-gi75.onrender.com/addUser";

    Map<String, String> userData = {
      "student_name": _nameController.text,
      "emailid": _emailController.text,
      "phone": _phoneController.text,
      "department": _departmentController.text,
      "batch": _batchController.text,
      "password": _passwordController.text,
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(userData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Signup Successful!")));
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
              (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to store user data!")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("API Request Failed: $e")));
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            child: Center(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          icon: Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      Center(
                        child: Text('Signup', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(labelText: 'Email Address'),
                      ),
                      SizedBox(height: 10),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
                        ),
                        validator: (value) => value!.length < 6 ? 'Password must be at least 6 characters' : null,
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _verifyEmail,
                        child: Text("Verify Email"),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _checkVerificationStatus,
                        child: Text("Check Verification"),
                      ),
                      SizedBox(height: 10),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(labelText: 'Student Name'),
                        validator: (value) => value!.isEmpty ? 'Enter your name' : null,
                      ),
                      SizedBox(height: 10),
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(labelText: 'Phone'),
                        validator: (value) => value!.length < 10 ? 'Enter a valid phone number' : null,
                      ),
                      SizedBox(height: 10),
                      TextFormField(
                        controller: _departmentController,
                        decoration: InputDecoration(labelText: 'Department'),
                        validator: (value) => value!.isEmpty ? 'Enter a valid department' : null,
                      ),
                      SizedBox(height: 10),
                      TextFormField(
                        controller: _batchController,
                        decoration: InputDecoration(labelText: 'Batch'),
                        validator: (value) => value!.isEmpty ? 'Enter a batch' : null,
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Checkbox(
                            value: _agreeToTerms,
                            onChanged: (value) {
                              setState(() => _agreeToTerms = value!);
                            },
                          ),
                          Expanded(child: Text("I accept the Terms and Privacy Policy")),
                        ],
                      ),
                      SizedBox(height: 10),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _isEmailVerified ? _signupUser : null,
                        child: Text("Signup"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            Center(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}
