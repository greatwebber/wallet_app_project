import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:wallet_app/services/api_service.dart';
import 'package:pay_with_paystack/pay_with_paystack.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:wallet_app/services/home_controller.dart';

class HomeScreen extends StatelessWidget {
  final HomeController homeController = Get.put(HomeController());

  void _showAddMoneyModal(BuildContext context) {
    TextEditingController amountController = TextEditingController();

    void _showSnackBar(String message, {bool isError = false}) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }

    void _submitToBackend(double amount) async {
      String? token = await ApiService.getToken();
      if (token == null) {
        _showSnackBar("User not authenticated", isError: true);
        return;
      }

      final response = await ApiService.submitAddMoney(amount);
      if (response) {
        // ✅ Fetch updated balance from API after successful money addition
        double? updatedBalance = await ApiService.getWalletBalance();
        if (updatedBalance != null) {
          homeController.walletBalance.value = updatedBalance; // ✅ Update UI
        }

        Navigator.pop(context); // Close modal after successful submission
        _showSnackBar(
            "Money added successfully! New Balance: ₦${updatedBalance?.toStringAsFixed(2)}");
      } else {
        _showSnackBar("Failed to add money.", isError: true);
      }
    }

    Future<void> _processPaystackPayment(double amount) async {
      final uniqueTransRef = PayWithPayStack().generateUuidV4();
      final String userEmail = homeController.userEmail.value;

      print(amount);

      PayWithPayStack().now(
        context: context,
        secretKey: "sk_test_0fb9aaa0ace494abaea6e3fc180084d74082cb2e",
        customerEmail: userEmail,
        reference: uniqueTransRef,
        currency: "NGN",
        amount: (amount).toDouble(), // ✅ Convert to Kobo
        transactionCompleted: (paymentData) {
          _showSnackBar("Transaction Successful!");
          _submitToBackend(amount); // ✅ After success, update wallet
        },
        transactionNotCompleted: (reason) {
          _showSnackBar("Transaction Failed: $reason", isError: true);
        },
        callbackUrl: '',
      );
    }

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Add Money",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text("Enter the amount you want to add to your wallet.",
                  style: TextStyle(color: Colors.grey)),
              SizedBox(height: 20),

              // Amount Input Field
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Amount (₦)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.money),
                ),
              ),
              SizedBox(height: 10),

              // Suggested Amount Buttons
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [1000, 5000, 10000, 20000].map((amount) {
                    return ElevatedButton(
                      onPressed: () {
                        amountController.text = amount.toString();
                      },
                      child: Text("₦$amount"),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 20),

              // Paystack Payment Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    double? amount = double.tryParse(amountController.text);
                    if (amount != null && amount > 0) {
                      _processPaystackPayment(amount);
                    } else {
                      _showSnackBar("Enter a valid amount", isError: true);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Proceed to Pay",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSendMoneyDialog(BuildContext context) async {
    TextEditingController amountController = TextEditingController();
    TextEditingController recipientController = TextEditingController();

    double? balance = await ApiService.getWalletBalance();
    if (balance == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to fetch wallet balance!")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Send Money"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(() => Text(
                  "Available Balance: ₦${homeController.walletBalance.value.toStringAsFixed(2)}")),
              TextField(
                controller: recipientController,
                decoration:
                    InputDecoration(labelText: "Recipient (Email or ID)"),
              ),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Amount"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                double amount = double.tryParse(amountController.text) ?? 0;
                String recipient = recipientController.text.trim();

                if (amount <= 0 || recipient.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text("Enter a valid amount and recipient")),
                  );
                  return;
                }

                if (amount > homeController.walletBalance.value) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Insufficient balance!")),
                  );
                  return;
                }

                Navigator.pop(context);

                double? updatedBalance =
                    await ApiService.sendMoney(amount, recipient);
                if (updatedBalance != null) {
                  homeController.walletBalance.value =
                      updatedBalance; // ✅ Update GetX state

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            "Money sent successfully! New Balance: ₦${updatedBalance.toStringAsFixed(2)}")),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to send money!")),
                  );
                }
              },
              child: Text("Send"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Obx(() => Text(
              "Welcome ${homeController.userName.value}",
              style: TextStyle(fontWeight: FontWeight.bold),
            )),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.account_circle, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // Wallet Balance Card
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 5,
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Wallet Balance",
                        style: TextStyle(fontSize: 16, color: Colors.grey)),
                    SizedBox(height: 8),
                    Obx(() => Text(
                          "₦${homeController.walletBalance.value.toStringAsFixed(2)}",
                          style: TextStyle(
                              fontSize: 28, fontWeight: FontWeight.bold),
                        )),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildActionButton(
                          "Add Money", Icons.add, Colors.blueAccent,
                          () => _showAddMoneyModal(
                              context), // Show modal on click
                        ),
                        _buildActionButton(
                          "Send Money",
                          Icons.send,
                          Colors.green,
                          () {
                            _showSendMoneyDialog(context);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Quick Actions Section
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12, blurRadius: 5, spreadRadius: 1)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Quick Actions",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildQuickAction(
                          "Pay", FontAwesomeIcons.creditCard, Colors.purple),
                      _buildQuickAction(
                          "Receive", FontAwesomeIcons.qrcode, Colors.orange),
                      _buildQuickAction("Bills",
                          FontAwesomeIcons.fileInvoiceDollar, Colors.teal),
                      _buildQuickAction(
                          "More", FontAwesomeIcons.ellipsisH, Colors.grey),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12, blurRadius: 5, spreadRadius: 1)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Recent Transactions",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Obx(() {
                    return homeController.transactionHistory.isEmpty
                        ? Center(
                            child: Text("No transactions found",
                                style: TextStyle(color: Colors.grey)))
                        : Column(
                            children: homeController.transactionHistory
                                .map((transaction) => ListTile(
                                      title: Text(transaction["title"],
                                          style: TextStyle(fontSize: 16)),
                                      subtitle: Text(transaction["date"]),
                                      trailing: Text(
                                        "₦${transaction["amount"]}",
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red),
                                      ),
                                    ))
                                .toList(),
                          );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
      String text, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed, // Call the function when button is pressed
      icon: Icon(icon, color: Colors.white),
      label: Text(text, style: TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildQuickAction(String label, IconData icon, Color color) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, size: 28, color: color),
        ),
        SizedBox(height: 8),
        Text(label,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTransactionItem(String title, String amount, String date) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text(date, style: TextStyle(color: Colors.grey)),
            ],
          ),
          Text(amount,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red)),
        ],
      ),
    );
  }
}
