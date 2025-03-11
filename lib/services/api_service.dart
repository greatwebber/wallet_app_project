import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallet_app/auth/login_screen.dart';
import 'package:wallet_app/services/home_controller.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  
  ApiException(this.message, {this.statusCode});
  
  @override
  String toString() => 'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

class ApiService {
  static const String baseUrl = "https://restapi.accttradecenter.com/api";
  static const Duration timeoutDuration = Duration(seconds: 10);

  // Save Token Locally
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("token", token);
  }

  // Get Token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  // Register User
  static Future<bool> register(
      String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/register"),
        headers: await _getHeaders(),
        body: jsonEncode({
          "name": name,
          "email": email,
          "password": password
        }),
      ).timeout(timeoutDuration);

      await _handleResponse(response);
      return true;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Registration failed: ${e.toString()}');
    }
  }

  // Login User
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          "email": email,
          "password": password
        }),
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await saveToken(data["token"]);
        return {
          "success": true,
          "message": "Login successful"
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          "success": false,
          "message": error["message"] ?? "Invalid email or password"
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Connection error. Please check your internet connection."
      };
    }
  }

  // Logout User
  static Future<void> logout(BuildContext context) async {
    try {
      final token = await getToken();
      if (token != null) {
        await http.post(
          Uri.parse("$baseUrl/logout"),
          headers: await _getHeaders(),
        ).timeout(timeoutDuration);
      }
    } finally {
      await clearToken();
    }
  }

  // Fetch User Details
  // Save User Data to SharedPreferences
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("user_data", jsonEncode(userData));
  }

  // Get User Data from SharedPreferences
  static Future<Map<String, dynamic>?> getUserDataFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString("user_data");
    
    if (userDataString != null) {
      return jsonDecode(userDataString);
    }
    return null;
  }

  // Fetch User Details (Check Local Storage First)
  static Future<Map<String, dynamic>?> getUserDetails() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/user"),
        headers: await _getHeaders(),
      ).timeout(timeoutDuration);

      return await _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch user details: ${e.toString()}');
    }
  }

  static Future<double?> getWalletBalance() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/wallet/balance"),
        headers: await _getHeaders(),
      ).timeout(timeoutDuration);

      final data = await _handleResponse(response);
      return double.tryParse(data['balance'].toString()) ?? 0.0;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch wallet balance: ${e.toString()}');
    }
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
      Get.find<HomeController>().loadUserData();

      return true;
    } else {
      print("Failed to add money: ${response.body}");
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getTransactions() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/transactions"),
        headers: await _getHeaders(),
      ).timeout(timeoutDuration);

      final data = await _handleResponse(response);
      return List<Map<String, dynamic>>.from(data['transactions'] ?? []);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch transactions: ${e.toString()}');
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
        Get.find<HomeController>().loadUserData();
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

  static Future<Map<String, dynamic>> processBillPayment({
    required String category,
    required String provider,
    required String number,
    required double amount,
    String? plan,
  }) async {
    String? token = await getToken();
    if (token == null)
      return {"success": false, "message": "Authentication failed"};

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/wallet/bill-payment"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "category": category,
          "provider": provider,
          "number": number,
          "amount": amount,
          if (plan != null) "plan": plan,
        }),
      );

      print('Bill Payment Response: ${response.body}'); // Debug log

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        if (data['success'] == true) {
          // Ensure transaction data has all required fields
          final transactionData = {
            'id': data['transaction']['id'] ?? '',
            'amount': data['transaction']['amount'] ?? amount,
            'type': data['transaction']['type'] ?? 'bill_payment',
            'status': data['transaction']['status'] ?? 'completed',
            'created_at': data['transaction']['created_at'] ?? DateTime.now().toIso8601String(),
            'balance': data['balance']?.toString() ?? '0.00',
          };
          
          Get.find<HomeController>().loadUserData();
          
          return {
            "success": true,
            "message": data["message"] ?? "Payment successful",
            "balance": data["balance"]?.toString() ?? '0.00',
            "transaction": transactionData,
          };
        } else {
          return {
            "success": false,
            "message": data["message"] ?? "Payment failed"
          };
        }
      } else {
        print('Bill Payment Error: ${response.statusCode} - ${response.body}');
        return {
          "success": false,
          "message": data["message"] ?? "Server error occurred"
        };
      }
    } catch (e) {
      print('Bill Payment Exception: $e');
      return {
        "success": false,
        "message": "Connection error occurred"
      };
    }
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<dynamic> _handleResponse(http.Response response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }

    if (response.statusCode == 401) {
      await clearToken();
      Get.offAll(() => LoginScreen());
      throw ApiException('Unauthorized access', statusCode: response.statusCode);
    }

    throw ApiException(
      response.body.isNotEmpty ? jsonDecode(response.body)['message'] ?? 'Unknown error occurred' : 'Unknown error occurred',
      statusCode: response.statusCode
    );
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
  }
}
