import 'package:flutter/material.dart';
import 'dart:async';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallet_app/dashboard/dashboard_screen.dart';
import 'package:wallet_app/onboarding_screen.dart';
import 'package:wallet_app/services/api_service.dart';
import 'package:wallet_app/services/home_controller.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(Duration(seconds: 2)); // Show splash for 2 seconds

    String? token = await ApiService.getToken();
    if (token != null) {
      // User is authenticated, get user data
      final HomeController homeController = Get.find<HomeController>();
      var userData = await ApiService.getUserDetails();
      
      if (userData != null) {
        // Update HomeController with user data
        homeController.userName.value = userData["name"];
        homeController.userEmail.value = userData["email"];
        homeController.walletBalance.value = 
            double.tryParse(userData["balance"].toString()) ?? 0.00;
        homeController.transactionHistory.assignAll(userData["transactions"] ?? []);

        // Navigate to Dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardScreen()),
        );
      } else {
        // Token invalid or expired
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove("token");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => OnboardingScreen()),
        );
      }
    } else {
      // No token found, go to onboarding
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet, size: 100, color: Colors.white),
            SizedBox(height: 20),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
