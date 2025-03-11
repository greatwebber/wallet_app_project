import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wallet_app/services/api_service.dart';
import 'package:wallet_app/services/home_controller.dart';
import 'package:wallet_app/screens/transaction_details_screen.dart';

class BillCategoryModal extends StatefulWidget {
  final String category;
  const BillCategoryModal({required this.category});

  @override
  _BillCategoryModalState createState() => _BillCategoryModalState();
}

class _BillCategoryModalState extends State<BillCategoryModal> {
  String? selectedProvider;
  String? selectedPlan;
  TextEditingController numberController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;

  final Map<String, List<String>> billProviders = {
    "Airtime": ["MTN", "Airtel", "Glo", "9mobile"],
    "Internet": ["MTN", "Airtel", "Glo", "9mobile"],
    "Electricity": ["IKEJA Electric", "EKO Electric", "Abuja DISCO", "PHED"],
    "TV Subscription": ["DSTV", "GOTV", "Startimes"],
  };

  final Map<String, List<String>> dataPlans = {
    "MTN": ["1GB - ₦500", "2GB - ₦1000", "3GB - ₦1500"],
    "Airtel": ["1GB - ₦600", "2GB - ₦1100", "3GB - ₦1600"],
    "Glo": ["1GB - ₦400", "2GB - ₦900", "3GB - ₦1400"],
    "9mobile": ["1GB - ₦700", "2GB - ₦1300", "3GB - ₦1800"],
  };

  Future<void> _processBillPayment() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final homeController = Get.find<HomeController>();
      double amount = double.tryParse(amountController.text) ?? 0;
      
      if (widget.category == "Internet" && selectedPlan != null) {
        amount = double.parse(selectedPlan!.split(" - ₦")[1]);
      }

      if (amount <= 0) {
        setState(() {
          errorMessage = "Please enter a valid amount";
          isLoading = false;
        });
        return;
      }

      if (amount > homeController.walletBalance.value) {
        setState(() {
          errorMessage = "Insufficient balance";
          isLoading = false;
        });
        return;
      }

      if (selectedProvider == null) {
        setState(() {
          errorMessage = "Please select a provider";
          isLoading = false;
        });
        return;
      }

      if (numberController.text.isEmpty) {
        setState(() {
          errorMessage = widget.category == "Electricity" 
              ? "Please enter meter number"
              : "Please enter phone number";
          isLoading = false;
        });
        return;
      }

      final result = await ApiService.processBillPayment(
        category: widget.category,
        provider: selectedProvider!,
        number: numberController.text,
        amount: amount,
        plan: widget.category == "Internet" ? selectedPlan : null,
      );

      if (!mounted) return;

      if (result["success"]) {
        // Update wallet balance and transactions
        homeController.fetchWalletBalance();
        homeController.fetchTransactions();
        
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionDetailsScreen(
              transactionData: result["transaction"],
              category: widget.category,
              provider: selectedProvider!,
              number: numberController.text,
              amount: amount,
              plan: widget.category == "Internet" ? selectedPlan : null,
            ),
          ),
        );
      } else {
        setState(() {
          errorMessage = result["message"];
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = "An unexpected error occurred. Please try again.";
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> providers = billProviders[widget.category] ?? [];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    margin: EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Text(
                  widget.category,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 15),
                Text("Select Provider",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: providers.map((provider) {
                    return ChoiceChip(
                      label: Text(provider),
                      selected: selectedProvider == provider,
                      onSelected: (selected) {
                        setState(() {
                          selectedProvider = selected ? provider : null;
                          selectedPlan = null;
                        });
                      },
                    );
                  }).toList(),
                ),
                if (widget.category == "Internet" && selectedProvider != null) ...[
                  SizedBox(height: 20),
                  Text("Select Data Plan",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: dataPlans[selectedProvider]?.map((plan) {
                          return ChoiceChip(
                            label: Text(plan),
                            selected: selectedPlan == plan,
                            onSelected: (selected) {
                              setState(() {
                                selectedPlan = selected ? plan : null;
                                if (selected) {
                                  amountController.text = plan.split(" - ₦")[1];
                                }
                              });
                            },
                          );
                        }).toList() ??
                        [],
                  ),
                ],
                SizedBox(height: 20),
                Text(
                  widget.category == "Electricity" ? "Meter Number" : "Phone Number",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: numberController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(widget.category == "Electricity" 
                        ? Icons.electric_meter
                        : Icons.phone),
                  ),
                ),
                if (widget.category != "Internet") ...[
                  SizedBox(height: 15),
                  Text("Enter Amount",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.money),
                      prefixText: "₦",
                    ),
                  ),
                ],
                if (errorMessage != null) ...[
                  SizedBox(height: 10),
                  Text(
                    errorMessage!,
                    style: TextStyle(color: Colors.red),
                  ),
                ],
                SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: isLoading ? null : _processBillPayment,
                    child: isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text("Pay Now",
                            style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
