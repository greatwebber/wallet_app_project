import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:wallet_app/services/home_controller.dart';
import 'package:wallet_app/widgets/transaction_list_item.dart';

class TransactionsScreen extends StatelessWidget {
  final HomeController homeController = Get.find<HomeController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Transaction History",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => homeController.fetchTransactions(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () {
          return Future<void>.value();
        },
        child: Padding(
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
                      return TransactionListItem(
                        transaction: homeController.transactionHistory[index],
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
