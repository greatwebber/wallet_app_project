import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class TransactionsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> transactions = [
    {
      "title": "Jumia Purchase",
      "amount": "-₦120,000.00",
      "color": Colors.red,
      "icon": FontAwesomeIcons.shoppingBag,
      "date": "Feb 5, 2025",
      "type": "Online Shopping"
    },
    {
      "title": "Salary Credit",
      "amount": "+₦3,000,000.00",
      "color": Colors.green,
      "icon": FontAwesomeIcons.moneyBillWave,
      "date": "Feb 1, 2025",
      "type": "Income"
    },
    {
      "title": "Market Shopping",
      "amount": "-₦45,750.00",
      "color": Colors.red,
      "icon": FontAwesomeIcons.shoppingCart,
      "date": "Feb 3, 2025",
      "type": "Supermarket"
    },
    {
      "title": "DSTV Subscription",
      "amount": "-₦15,990.00",
      "color": Colors.red,
      "icon": FontAwesomeIcons.tv,
      "date": "Feb 2, 2025",
      "type": "Entertainment"
    },
  ];

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
              child: ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  return _buildTransactionItem(
                    transactions[index]["title"],
                    transactions[index]["amount"],
                    transactions[index]["color"],
                    transactions[index]["icon"],
                    transactions[index]["date"],
                    transactions[index]["type"],
                  );
                },
              ),
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
