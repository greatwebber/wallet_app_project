import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:wallet_app/services/home_controller.dart';

class TransactionsScreen extends StatelessWidget {
  final HomeController homeController =
      Get.find<HomeController>(); // Get the controller

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Transaction History",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        automaticallyImplyLeading: false, // Removes the back arrow
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Recent Transactions",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Expanded(
              child: Obx(() {
                if (homeController.isLoading.value) {
                  return Center(child: CircularProgressIndicator());
                }

                if (homeController.transactionHistory.isEmpty) {
                  return Center(
                    child: Text("No transactions found",
                        style: TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  itemCount: homeController.transactionHistory.length,
                  itemBuilder: (context, index) {
                    var transaction = homeController.transactionHistory[index];
                    bool isCredit = transaction["type"] == "credit";
                    return _buildTransactionItem(
                      isCredit
                          ? "Received from ${transaction['recipient']}"
                          : "Sent to ${transaction['recipient']}",
                      (isCredit ? "+₦" : "-₦") +
                          transaction["amount"].toString(),
                      isCredit ? Colors.green : Colors.red,
                      isCredit
                          ? FontAwesomeIcons.moneyBillWave
                          : FontAwesomeIcons.arrowUp,
                      transaction["created_at"],
                      isCredit ? "Income" : "Transfer",
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(String title, String amount, Color color,
      IconData icon, String date, String type) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        subtitle: Text("$type • $date", style: TextStyle(color: Colors.grey)),
        trailing: Text(amount,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ),
    );
  }
}
