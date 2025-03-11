import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallet_app/auth/forgot_password_screen.dart';
import 'package:wallet_app/dashboard/dashboard_screen.dart';
import 'package:wallet_app/auth/signup_screen.dart';
import 'package:wallet_app/services/api_service.dart';
import 'package:wallet_app/services/home_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>(); // ✅ Form key for validation

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      bool success = await ApiService.login(
        emailController.text.trim(),
        passwordController.text,
      );

      if (!success) {
        setState(() {
          _isLoading = false;
        });
        _showError("Invalid email or password. Please try again.");
        return;
      }

      // Get the HomeController instance
      final HomeController homeController = Get.find<HomeController>();

      // Fetch user data and update UI in parallel
      await Future.wait([
        // Fetch and update user data
        ApiService.getUserDetails().then((userData) {
          if (userData != null) {
            homeController.userName.value = userData["name"];
            homeController.userEmail.value = userData["email"];
            homeController.walletBalance.value =
                double.tryParse(userData["balance"].toString()) ?? 0.00;
            homeController.transactionHistory
                .assignAll(userData["transactions"] ?? []);
          }
        }),

        // Save data to SharedPreferences in parallel
        ApiService.getUserDetails().then((userData) async {
          if (userData != null) {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString("username", userData["name"]);
            await prefs.setDouble("walletBalance",
                double.tryParse(userData["balance"].toString()) ?? 0.00);
            await ApiService.saveUserData(userData); // Save complete user data
          }
        }),
      ]);

      // Navigate to Dashboard
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showError("An error occurred. Please try again.");
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 60),
          child: Form(
            key: _formKey, // ✅ Wrap with Form widget
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(FontAwesomeIcons.lock, size: 80, color: Colors.blueAccent),
                SizedBox(height: 20),

                Text("Welcome Back!",
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
                SizedBox(height: 10),
                Text("Login to continue",
                    style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                SizedBox(height: 30),

                // ✅ Email Field (Required)
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: Icon(Icons.email, color: Colors.blueAccent),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Email is required";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // ✅ Password Field (Required)
                TextFormField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: Icon(Icons.lock, color: Colors.blueAccent),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Password is required";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ForgotPasswordScreen()),
                      );
                    },
                    child: Text("Forgot Password?",
                        style: TextStyle(color: Colors.blueAccent)),
                  ),
                ),
                SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text("Login",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account? ",
                        style:
                            TextStyle(fontSize: 16, color: Colors.grey[700])),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SignUpScreen()),
                        );
                      },
                      child: Text(
                        "Sign Up",
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
