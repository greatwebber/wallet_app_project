import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:wallet_app/dashboard/bill_screen.dart';
import 'package:wallet_app/dashboard/pay_screen.dart';
import 'package:wallet_app/dashboard/receive_screen.dart';
import 'package:wallet_app/services/api_service.dart';
import 'package:pay_with_paystack/pay_with_paystack.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:wallet_app/widgets/transaction_list_item.dart';
import 'package:wallet_app/services/home_controller.dart';
import 'package:wallet_app/controllers/dashboard_controller.dart';

class HomeScreen extends StatelessWidget {
  final HomeController homeController = Get.put(HomeController());
  final DashboardController dashboardController = Get.put(DashboardController());

  void _showAddMoneyModal(BuildContext context) {
    TextEditingController amountController = TextEditingController();

    void _showSnackBar(String message, {bool isError = false}) {
      if (!context.mounted) return; // ✅ Prevent crash if widget is disposed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
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

        homeController.isLoading.value = false;

        if (context.mounted) {
          Navigator.pop(
              context); // ✅ Only close modal if widget is still mounted
        }

        _showSnackBar(
            "Money added successfully! New Balance: ₦${updatedBalance?.toStringAsFixed(2)}");
      } else {
        _showSnackBar("Failed to add money.", isError: true);
      }
    }

    Future<void> _processPaystackPayment(double amount) async {
      final uniqueTransRef = PayWithPayStack().generateUuidV4();
      final String userEmail = homeController.userEmail.value;

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
          homeController.isLoading.value = true;
        },
        transactionNotCompleted: (reason) {
          _showSnackBar("Transaction Failed: $reason", isError: true);
        },
        callbackUrl: 'https://standard.paystack.co/close',
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
                child: Obx(() => ElevatedButton(
                      onPressed: homeController.isLoading.value
                          ? null // ✅ Disable button while loading
                          : () {
                              double? amount =
                                  double.tryParse(amountController.text);
                              if (amount != null && amount > 0) {
                                _processPaystackPayment(
                                    amount); // ✅ Start Paystack process
                              } else {
                                _showSnackBar("Enter a valid amount",
                                    isError: true);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: homeController.isLoading.value
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ) // ✅ Show loading indicator
                          : const Text(
                              "Proceed to Pay",
                              style: TextStyle(color: Colors.white),
                            ),
                    )),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSendMoneyBottomSheet(BuildContext context) {
    TextEditingController amountController = TextEditingController();
    TextEditingController recipientController = TextEditingController();
    bool isLoading = false;
    String? errorMessage; // Holds the error message

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Center(
                    child: Text(
                      "Send Money",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (errorMessage != null) // Show error message if available
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      child: Center(
                        child: Text(
                          errorMessage!,
                          style: TextStyle(color: Colors.red, fontSize: 14),
                        ),
                      ),
                    ),
                  Obx(() => Text(
                        "Available Balance: ₦${homeController.walletBalance.value.toStringAsFixed(2)}",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      )),
                  SizedBox(height: 10),
                  TextField(
                    controller: recipientController,
                    decoration: InputDecoration(
                      labelText: "Recipient (Email or ID)",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Amount",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.money),
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("Cancel", style: TextStyle(fontSize: 16)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: isLoading
                            ? null // Disable button while loading
                            : () async {
                                double amount =
                                    double.tryParse(amountController.text) ?? 0;
                                String recipient =
                                    recipientController.text.trim();

                                if (amount <= 0 || recipient.isEmpty) {
                                  setState(() {
                                    errorMessage =
                                        "Enter a valid amount and recipient.";
                                  });
                                  return;
                                }

                                if (amount >
                                    homeController.walletBalance.value) {
                                  setState(() {
                                    errorMessage = "Insufficient balance!";
                                  });
                                  return;
                                }

                                setState(() {
                                  isLoading = true;
                                  errorMessage =
                                      null; // Clear any previous errors
                                });

                                var result = await ApiService.sendMoney(
                                    amount, recipient);

                                if (result["success"]) {
                                  if (context.mounted) {
                                    Navigator.pop(context); // Close modal
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            "Money sent successfully! New Balance: ₦${result["balance"].toStringAsFixed(2)}"),
                                      ),
                                    );
                                  }
                                } else {
                                  setState(() {
                                    errorMessage = result["message"];
                                  });
                                }

                                setState(() {
                                  isLoading = false;
                                });
                              },
                        child: isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text("Send", style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
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
                          () => _showSendMoneyBottomSheet(context),
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
                          context,
                          "Pay",
                          FontAwesomeIcons.creditCard,
                          Colors.purple,
                          PayScreen()),
                      _buildQuickAction(
                          context,
                          "Receive",
                          FontAwesomeIcons.qrcode,
                          Colors.orange,
                          ReceiveScreen()),
                      _buildQuickAction(
                          context,
                          "Bills",
                          FontAwesomeIcons.fileInvoiceDollar,
                          Colors.teal,
                          BillsScreen()),
                      // _buildQuickAction(
                      //     context,
                      //     "More",
                      //     FontAwesomeIcons.ellipsisH,
                      //     Colors.grey,
                      //     MoreOptionsScreen()),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Recent Transactions",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          // Switch to Transactions tab
                          Get.find<DashboardController>().changeTabIndex(1);
                        },
                        child: Text("See All"),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Obx(() {
                    if (homeController.isLoading.value) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (homeController.transactionHistory.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            "No transactions found",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: homeController.transactionHistory
                          .take(5)
                          .map((transaction) => TransactionListItem(
                                transaction: transaction,
                                isCompact: true,
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

  Widget _buildQuickAction(BuildContext context, String label, IconData icon,
      Color color, Widget targetScreen) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => targetScreen),
        );
      },
      child: Column(
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
      ),
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
