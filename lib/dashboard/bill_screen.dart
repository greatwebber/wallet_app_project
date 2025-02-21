import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:wallet_app/services/bill_category_modal.dart';

class BillsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> billCategories = [
    {"name": "Airtime", "icon": FontAwesomeIcons.phone, "color": Colors.blue},
    {"name": "Internet", "icon": FontAwesomeIcons.wifi, "color": Colors.green},
    {
      "name": "Electricity",
      "icon": FontAwesomeIcons.bolt,
      "color": Colors.orange
    },
    {
      "name": "TV Subscription",
      "icon": FontAwesomeIcons.tv,
      "color": Colors.red
    },
  ];

  void _openBillCategoryModal(BuildContext context, String category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows full screen height usage
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => BillCategoryModal(category: category),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text("Bills Payment"), backgroundColor: Colors.blue),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text("Select a Bill Type",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 15),
            Column(
              children: billCategories.map((bill) {
                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    leading: Icon(bill["icon"], color: bill["color"], size: 30),
                    title: Text(bill["name"],
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _openBillCategoryModal(context, bill["name"]),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
