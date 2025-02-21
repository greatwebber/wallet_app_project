import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wallet_app/services/home_controller.dart';
import 'package:flutter/services.dart';

class ReceiveScreen extends StatelessWidget {
  final HomeController homeController = Get.find<HomeController>();

  @override
  Widget build(BuildContext context) {
    String walletID =
        homeController.userEmail.value; // Using email as wallet ID

    return Scaffold(
      appBar: AppBar(
        title: Text("Receive Money"),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📌 Wallet Address Display
            Text("Your Wallet ID:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey.shade100,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: SelectableText(
                      walletID,
                      style: TextStyle(fontSize: 16, color: Colors.blue),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.copy, color: Colors.orange),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: walletID));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Wallet ID copied to clipboard"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // 📌 Transaction History (Received)
            Text("Recent Received Transactions",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Expanded(
              child: Obx(() {
                var receivedTransactions =
                    homeController.transactionHistory.where((transaction) {
                  return transaction["type"] == "credit" &&
                      transaction["recipient"] != "Deposit" &&
                      transaction["recipient"].isNotEmpty;
                }).toList();

                if (receivedTransactions.isEmpty) {
                  return Center(child: Text("No received payments yet"));
                }

                return ListView.builder(
                  itemCount: receivedTransactions.length,
                  itemBuilder: (context, index) {
                    var transaction = receivedTransactions[index];
                    return ListTile(
                      leading: Icon(Icons.arrow_downward, color: Colors.green),
                      title: Text(transaction["recipient"] ?? "Unknown"),
                      subtitle: Text("Received: ₦${transaction["amount"]}"),
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
}
