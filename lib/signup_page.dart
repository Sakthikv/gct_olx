import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'main.dart';
import 'login_page.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController departmentController = TextEditingController();
  final TextEditingController batchController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child("users");

  String verificationCode = "";
  bool isOtpSent = false;

  void sendOTP() async {
    String email = emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Enter email first")));
      return;
    }

    // Generate a 6-digit OTP
    Random random = Random();
    verificationCode = (100000 + random.nextInt(900000)).toString();

    // Simulate sending OTP via Firebase (Replace with email sending logic)
    print("OTP Sent to $email: $verificationCode");

    setState(() {
      isOtpSent = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("OTP sent to $email")));
  }

  void signUp() async {
    String name = nameController.text.trim();
    String department = departmentController.text.trim();
    String batch = batchController.text.trim();
    String phone = phoneController.text.trim();
    String email = emailController.text.trim();
    String otp = otpController.text.trim();

    if (otp != verificationCode) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Invalid OTP")));
      return;
    }

    try {
      // Create user with email/password authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: "Default@123");

      // Store user details in Firebase Realtime Database
      _dbRef.child(userCredential.user!.uid).set({
        "name": name,
        "department": department,
        "batch": batch,
        "phone": phone,
        "email": email,
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Signup successful!")));
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Signup failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sign Up")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: "Name")),
            TextField(controller: departmentController, decoration: InputDecoration(labelText: "Department")),
            TextField(controller: batchController, decoration: InputDecoration(labelText: "Batch")),
            TextField(controller: phoneController, decoration: InputDecoration(labelText: "Phone Number")),
            TextField(controller: emailController, decoration: InputDecoration(labelText: "Email"), keyboardType: TextInputType.emailAddress),
            SizedBox(height: 10),
            ElevatedButton(onPressed: sendOTP, child: Text("Verify Email")),
            if (isOtpSent) ...[
              TextField(controller: otpController, decoration: InputDecoration(labelText: "Enter OTP")),
              SizedBox(height: 10),
              ElevatedButton(onPressed: signUp, child: Text("Sign Up")),
            ],
          ],
        ),
      ),
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'home_page.dart';
//
// class SignUpPage extends StatefulWidget {
//   @override
//   _SignUpPageState createState() => _SignUpPageState();
// }
//
// class _SignUpPageState extends State<SignUpPage> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();
//
//   bool isEmailVerified = false;
//   bool verificationEmailSent = false;
//
//   Future<void> signUpAndSendVerification() async {
//     try {
//       UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
//         email: emailController.text.trim(),
//         password: passwordController.text.trim(),
//       );
//
//       User? user = userCredential.user;
//       if (user != null && !user.emailVerified) {
//         await user.sendEmailVerification();
//         setState(() {
//           verificationEmailSent = true;
//         });
//       }
//     } catch (e) {
//       print("Error: $e");
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Signup failed: $e")));
//     }
//   }
//
//   Future<void> checkEmailVerification() async {
//     User? user = _auth.currentUser;
//     await user?.reload(); // Refresh user status
//     if (user?.emailVerified ?? false) {
//       setState(() {
//         isEmailVerified = true;
//       });
//       Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage()));
//     }
//   }
//
//   Future<void> resendVerificationEmail() async {
//     User? user = _auth.currentUser;
//     if (user != null && !user.emailVerified) {
//       await user.sendEmailVerification();
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Verification email sent again!")));
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Sign Up')),
//       body: Padding(
//         padding: EdgeInsets.all(16.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             TextField(
//               controller: emailController,
//               decoration: InputDecoration(labelText: "Email"),
//             ),
//             TextField(
//               controller: passwordController,
//               obscureText: true,
//               decoration: InputDecoration(labelText: "Password"),
//             ),
//             SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: signUpAndSendVerification,
//               child: Text("Sign Up"),
//             ),
//             SizedBox(height: 10),
//             if (verificationEmailSent)
//               Column(
//                 children: [
//                   Text(
//                     "Verification email sent! Please check your inbox.",
//                     style: TextStyle(color: Colors.green),
//                   ),
//                   SizedBox(height: 10),
//                   ElevatedButton(
//                     onPressed: checkEmailVerification,
//                     child: Text("I have verified my email"),
//                   ),
//                   TextButton(
//                     onPressed: resendVerificationEmail,
//                     child: Text("Resend Verification Email"),
//                   ),
//                 ],
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }