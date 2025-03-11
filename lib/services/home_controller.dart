import 'package:get/get.dart';
import 'package:wallet_app/services/api_service.dart';
import 'package:wallet_app/auth/login_screen.dart';

class HomeController extends GetxController {
  // User data
  final userName = ''.obs;
  final userEmail = ''.obs;
  final walletBalance = 0.00.obs;
  final transactionHistory = <Map<String, dynamic>>[].obs;
  final profileImage = ''.obs;
  
  // State flags
  final isLoading = false.obs;
  final isAuthenticated = false.obs;

  Future<void> initializeApp() async {
    try {
      // Check if user is authenticated
      final token = await ApiService.getToken();
      isAuthenticated.value = token != null;
      
      if (isAuthenticated.value) {
        await loadUserData();
      }
    } catch (e) {
      print('Initialization error: $e');
      isAuthenticated.value = false;
    }
  }

  Future<void> loadUserData() async {
    try {
      isLoading.value = true;
      
      // Load cached data first for instant UI update
      final cachedData = await ApiService.getUserDataFromStorage();
      if (cachedData != null) {
        _updateUserData(cachedData);
      }
      
      // Then fetch fresh data from API
      final freshData = await ApiService.getUserDetails();
      if (freshData != null) {
        _updateUserData(freshData);
        await ApiService.saveUserData(freshData); // Update cache
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _updateUserData(Map<String, dynamic> userData) {
    userName.value = userData["name"] ?? '';
    userEmail.value = userData["email"] ?? '';
    walletBalance.value = double.tryParse(userData["balance"]?.toString() ?? "0") ?? 0.00;
    
    if (userData["transactions"] != null) {
      final List<dynamic> transactions = userData["transactions"];
      transactionHistory.assignAll(
        transactions.map((t) => t as Map<String, dynamic>).toList()
      );
    }
    
    if (userData["profile_image"] != null) {
      profileImage.value = userData["profile_image"];
    }
  }

  Future<void> refreshData() async {
    if (isAuthenticated.value) {
      await loadUserData();
    }
  }

  Future<void> logout() async {
    try {
      isLoading.value = true;
      await ApiService.logout(Get.context!);
      
      // Reset controller state
      userName.value = '';
      userEmail.value = '';
      walletBalance.value = 0.00;
      transactionHistory.clear();
      profileImage.value = '';
      isAuthenticated.value = false;
      
      // Navigate to login screen
      Get.offAll(() => LoginScreen());
      
    } catch (e) {
      print('Logout error: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
