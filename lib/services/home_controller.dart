import 'package:get/get.dart';
import 'package:wallet_app/services/api_service.dart';

class HomeController extends GetxController {
  var userName = "Guest User".obs;
  var userEmail = "guest@example.com".obs;
  var walletBalance = 0.00.obs;
  var transactionHistory = <dynamic>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadUserData();
    fetchWalletBalance();
  }

  Future<void> loadUserData() async {
    final userData = await ApiService.getUserDataFromStorage();
    if (userData != null) {
      // ✅ Load cached data first
      userName.value = userData["name"];
      userEmail.value = userData["email"];
      walletBalance.value =
          double.tryParse(userData["balance"].toString()) ?? 0.00;
      transactionHistory.assignAll(userData["transactions"] ?? []);

      // ✅ Then fetch fresh data from API
      fetchUserData();
    } else {
      fetchUserData();
    }
  }

  Future<void> fetchWalletBalance() async {
    double? balance = await ApiService.getWalletBalance();
    if (balance != null) {
      walletBalance.value = balance;
    }
  }

  Future<void> fetchUserData() async {
    final userData = await ApiService.getUserDetails();
    if (userData != null) {
      userName.value = userData["name"];
      userEmail.value = userData["email"];

      walletBalance.value =
          double.tryParse(userData["balance"].toString()) ?? 0.00;
      transactionHistory.assignAll(userData["transactions"] ?? []);
    }
  }
}
