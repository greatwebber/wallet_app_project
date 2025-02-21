import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    List<String> providers = billProviders[widget.category] ?? [];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6, // Start with 60% of the screen
      minChildSize: 0.5, // Minimum height
      maxChildSize: 0.9, // Maximum height
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
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: providers.map((provider) {
                    return ChoiceChip(
                      backgroundColor: Colors.blue[200],
                      label: Text(provider),
                      selected: selectedProvider == provider,
                      onSelected: (selected) {
                        setState(() {
                          selectedProvider = provider;
                          selectedPlan = null;
                        });
                      },
                    );
                  }).toList(),
                ),
                SizedBox(height: 20),
                if (widget.category == "Internet" && selectedProvider != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Select Data Plan",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        children: dataPlans[selectedProvider]?.map((plan) {
                              return ChoiceChip(
                                label: Text(plan),
                                selected: selectedPlan == plan,
                                onSelected: (selected) {
                                  setState(() {
                                    selectedPlan = plan;
                                  });
                                },
                              );
                            }).toList() ??
                            [],
                      ),
                    ],
                  ),
                SizedBox(height: 20),
                Text(
                  "Enter ${widget.category == 'Electricity' ? 'Meter Number' : 'Phone Number'}",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextField(
                  controller: numberController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                SizedBox(height: 15),
                if (widget.category != "Internet")
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Enter Amount",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.money),
                        ),
                      ),
                    ],
                  ),
                SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      // Process payment logic
                    },
                    child: Text("Proceed to Pay",
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
