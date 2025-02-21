import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wallet_app/services/home_controller.dart';

class BillsScreen extends StatelessWidget {
  final HomeController homeController = Get.find<HomeController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Pay Bills"),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📌 Wallet Balance Display
            Obx(() => Text(
                  "Available Balance: ₦${homeController.walletBalance.value.toStringAsFixed(2)}",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                )),
            SizedBox(height: 20),

            // 📌 Bill Categories (Full-size, No Scrolling)
            Text("Select Bill Type",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),

            _buildBillCategory(context, "Electricity",
                Icons.electrical_services, "Enter meter number"),
            _buildBillCategory(
                context, "Internet", Icons.wifi, "Enter provider & account ID"),
            _buildBillCategory(
                context, "Water", Icons.water, "Enter customer ID"),
            _buildBillCategory(context, "TV Subscription", Icons.tv,
                "Enter Smart Card number"),
            _buildBillCategory(
                context, "Airtime", Icons.phone_android, "Enter mobile number"),

            SizedBox(height: 20),

            // 📌 Transaction History (Bills Only)
            Text("Recent Bill Payments",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),

            Expanded(
              child: Obx(() {
                var billTransactions =
                    homeController.transactionHistory.where((transaction) {
                  return transaction["type"] == "debit" &&
                      transaction["category"] == "bill";
                }).toList();

                if (billTransactions.isEmpty) {
                  return Center(child: Text("No bill payments yet"));
                }

                return ListView.builder(
                  itemCount: billTransactions.length,
                  itemBuilder: (context, index) {
                    var transaction = billTransactions[index];
                    return ListTile(
                      leading: Icon(Icons.receipt_long, color: Colors.blue),
                      title: Text(transaction["bill_type"] ?? "Unknown Bill"),
                      subtitle: Text("Paid: ₦${transaction["amount"]}"),
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

  Widget _buildBillCategory(
      BuildContext context, String title, IconData icon, String placeholder) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(placeholder),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          _showBillPaymentDialog(context, title);
        },
      ),
    );
  }

  void _showBillPaymentDialog(BuildContext context, String billType) {
    TextEditingController accountController = TextEditingController();
    TextEditingController amountController = TextEditingController();
    String? errorMessage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                    child: Text("Pay $billType",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  if (errorMessage != null) // Show error message if available
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      child: Center(
                        child: Text(errorMessage!,
                            style: TextStyle(color: Colors.red, fontSize: 14)),
                      ),
                    ),
                  TextField(
                    controller: accountController,
                    decoration: InputDecoration(
                      labelText: "Enter account details",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.account_circle),
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
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          double amount =
                              double.tryParse(amountController.text) ?? 0;
                          if (amount <= 0 ||
                              accountController.text.trim().isEmpty) {
                            setState(() {
                              errorMessage =
                                  "Enter valid account details and amount.";
                            });
                            return;
                          }

                          if (amount > homeController.walletBalance.value) {
                            setState(() {
                              errorMessage = "Insufficient balance!";
                            });
                            return;
                          }

                          // Perform Bill Payment
                          // homeController.payBill(billType, amount, accountController.text);
                          Navigator.pop(context);
                          Get.snackbar("Success", "Bill Payment Successful",
                              snackPosition: SnackPosition.BOTTOM);
                        },
                        child: Text("Pay", style: TextStyle(fontSize: 16)),
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
}
