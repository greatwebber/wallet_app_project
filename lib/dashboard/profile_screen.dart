import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:wallet_app/services/api_service.dart';
import 'package:wallet_app/services/home_controller.dart';

class ProfileScreen extends StatelessWidget {
  final HomeController homeController = Get.find<HomeController>();

  Future<bool> _showLogoutConfirmationDialog(BuildContext context) async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Logout"),
            content: Text("Are you sure you want to log out?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text("Logout", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profile"), backgroundColor: Colors.teal),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Picture
            Center(
              child: Stack(
                children: [
                  Obx(() => CircleAvatar(
                        radius: 50,
                        backgroundImage: homeController
                                .profileImage.value.isNotEmpty
                            ? NetworkImage(homeController.profileImage.value)
                            : AssetImage("assets/profile_placeholder.png")
                                as ImageProvider,
                      )),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        // TODO: Implement image upload functionality
                      },
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.teal,
                        child: Icon(Icons.camera_alt,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 15),

            // User Details
            Obx(() => Text(
                  homeController.userName.value,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                )),
            Obx(() => Text(
                  homeController.userEmail.value,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                )),

            SizedBox(height: 20),

            // Wallet Balance
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 3,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Wallet Balance",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Obx(() => Text(
                          "₦${homeController.walletBalance.value.toStringAsFixed(2)}",
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.teal,
                              fontWeight: FontWeight.bold),
                        )),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),

            // Additional Account Details
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 3,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                        "Account ID", homeController.userEmail.value),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Edit Profile Button
            ListTile(
              leading: Icon(FontAwesomeIcons.userEdit, color: Colors.blue),
              title: Text("Edit Profile"),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Navigate to Edit Profile Screen
              },
            ),
            Divider(),

            // Change Password
            ListTile(
              leading: Icon(FontAwesomeIcons.lock, color: Colors.orange),
              title: Text("Change Password"),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Navigate to Change Password Screen
              },
            ),
            Divider(),

            // Logout Button
            ListTile(
              leading:
                  Icon(FontAwesomeIcons.rightFromBracket, color: Colors.red),
              title: Text("Logout"),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                bool confirmLogout = await _showLogoutConfirmationDialog(context);
                if (confirmLogout) {
                  final homeController = Get.find<HomeController>();
                  await homeController.logout();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700])),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
        ],
      ),
    );
  }
}
