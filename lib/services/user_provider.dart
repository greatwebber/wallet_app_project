import 'package:flutter/material.dart';
import 'package:wallet_app/services/api_service.dart';

class UserProvider with ChangeNotifier {
  Map<String, dynamic>? _user;
  double _walletBalance = 0.0;
  bool _isLoading = true;

  Map<String, dynamic>? get user => _user;
  double get walletBalance => _walletBalance;
  bool get isLoading => _isLoading;

  // Fetch User Details
  Future<void> fetchUserDetails() async {
    _isLoading = true;
    notifyListeners();

    final data = await ApiService.getUserDetails();
    if (data != null) {
      _user = data;
      _walletBalance = (data['wallet_balance'] ?? 0.0).toDouble();
    }

    _isLoading = false;
    notifyListeners();
  }
}
