import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wallet_app/services/api_service.dart';
import 'package:wallet_app/services/home_controller.dart';

class PayScreen extends StatelessWidget {
  final HomeController homeController = Get.find<HomeController>();

  PayScreen({super.key});

  void _showSendMoneyBottomSheet(BuildContext context,
      {required String prefillRecipient}) {
    TextEditingController amountController = TextEditingController();
    TextEditingController recipientController =
        TextEditingController(text: prefillRecipient);
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
      appBar: AppBar(
        title: Text("Pay"),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pay Options
            _buildPayOption(context, "Pay to Merchant", "Enter merchant ID", '',
                Icons.store),
            SizedBox(height: 15),

            // Recent Payments
            Text("Recent Payments",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),

            Expanded(
              child: Obx(() {
                if (homeController.isLoading.value) {
                  return Center(
                      child: CircularProgressIndicator(color: Colors.blue));
                }

                var transactions =
                    homeController.transactionHistory.where((transaction) {
                  return transaction["type"] == "debit" &&
                      transaction["recipient"] != null &&
                      transaction["recipient"].isNotEmpty;
                }).toList();

                if (transactions.isEmpty) {
                  return Center(child: Text("No recent payments"));
                }

                return ListView.builder(
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    var transaction = transactions[index];

                    return _recentPaymentTile(
                        context,
                        transaction["recipient"],
                        "₦${transaction["amount"]}",
                        transaction["recipient_email"],
                        Icons.person);
                  },
                );
              }),
            ),

            // Confirm Payment Button
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildPayOption(BuildContext context, String title, String subtitle,
      String email, IconData icon) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () =>
            _showSendMoneyBottomSheet(context, prefillRecipient: email),
      ),
    );
  }

  Widget _recentPaymentTile(BuildContext context, String name, String amount,
      String email, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(name),
      subtitle: Text("Last payment: $amount"),
      trailing: IconButton(
        icon: Icon(Icons.send, color: Colors.blue),
        onPressed: () {
          _showSendMoneyBottomSheet(context, prefillRecipient: email);
        },
      ),
    );
  }
}
