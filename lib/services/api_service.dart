import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallet_app/services/home_controller.dart';

class ApiService {
  static const String baseUrl = "https://restapi.accttradecenter.com/api";

  // Save Token Locally
  static Future<void> saveToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("token", token);
  }

  // Get Token
  static Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  // Register User
  static Future<bool> register(
      String name, String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/register"),
      body: {"name": name, "email": email, "password": password},
    );

    return response.statusCode == 201;
  }

  // Login User
  static Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      body: {"email": email, "password": password},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await saveToken(data["token"]);
      return true;
    }
    return false;
  }

  // Logout User
  static Future<void> logout() async {
    final HomeController homeController = Get.find<HomeController>();
    String? token = await getToken();
    await http.post(
      Uri.parse("$baseUrl/logout"),
      headers: {"Authorization": "Bearer $token"},
    );
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
    homeController.userName.value = "";
    homeController.userEmail.value = "";
    homeController.walletBalance.value = 0.00;
    homeController.transactionHistory.clear();
  }

  // Fetch User Details
  // Save User Data to SharedPreferences
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("user_data", jsonEncode(userData));
  }

  // Get User Data from SharedPreferences
  static Future<Map<String, dynamic>?> getUserDataFromStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userDataString = prefs.getString("user_data");

    if (userDataString != null) {
      return jsonDecode(userDataString);
    }
    return null;
  }

  // Fetch User Details (Check Local Storage First)
  static Future<Map<String, dynamic>?> getUserDetails() async {
    String? token = await getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse("$baseUrl/user"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final userData = jsonDecode(response.body);

      // Update local storage with fresh data
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString("user_data", jsonEncode(userData));

      return userData;
    }
    return null;
  }

  static Future<double?> getWalletBalance() async {
    String? token = await getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse("$baseUrl/wallet"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Ensure the balance is parsed correctly
      if (data["balance"] is num) {
        return (data["balance"] as num).toDouble();
      } else if (data["balance"] is String) {
        return double.tryParse(data["balance"]);
      }
    }
    return null;
  }

  static Future<bool> submitAddMoney(double amount) async {
    String? token = await getToken();
    if (token == null) return false; // No auth token found

    final response = await http.post(
      Uri.parse("$baseUrl/wallet/add-money"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"amount": amount}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // ✅ Update wallet balance in HomeController
      Get.find<HomeController>().walletBalance.value =
          data["balance"].toDouble();

      // ✅ Refresh transaction history
      Get.find<HomeController>().fetchUserData();

      return true;
    } else {
      print("Failed to add money: ${response.body}");
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getTransactions() async {
    String? token = await getToken();
    if (token == null) return [];
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user'),
        headers: {
          'Authorization': "Bearer $token",
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data["transactions"]);
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> sendMoney(
      double amount, String recipient) async {
    String? token = await getToken();
    if (token == null)
      return {"success": false, "message": "Authentication failed"};

    final response = await http.post(
      Uri.parse("$baseUrl/wallet/send-money"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "amount": amount,
        "recipient": recipient,
      }),
    );

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        Get.find<HomeController>().fetchUserData();
        return {
          "success": true,
          "balance": data["balance"].toDouble(),
          "transaction": data["transaction"],
        };
      } catch (e) {
        return {"success": false, "message": "Invalid server response"};
      }
    } else {
      try {
        final errorData = jsonDecode(response.body);
        return {
          "success": false,
          "message": errorData["message"] ?? "Transaction failed"
        };
      } catch (e) {
        return {"success": false, "message": "Unexpected error occurred"};
      }
    }
  }
}
