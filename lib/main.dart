import 'package:flutter/material.dart';

void main() {
  runApp(AHLGroceries());
}

class AHLGroceries extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AHL Groceries',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: StoreListPage(title: 'AHL Groceries'),
    );
  }
}

/// A StatelessWidget which displays all storenames.
///
/// Note: [StoreListPage] is a StatelessWidget because the stores and their
/// names are constants.
class StoreListPage extends StatelessWidget {
  StoreListPage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(this.title),
      ),
      body: Column(
        children: [
          StoreListPageItem("Store1"),
          StoreListPageItem("Store2"),
          StoreListPageItem("Store3"),
          StoreListPageItem("Store4"),
          StoreListPageItem("Store5"),
        ],
      ),
    );
  }
}

/// A StatelessWidget to represent a single store.
class StoreListPageItem extends StatelessWidget {
  final String storeName;

  const StoreListPageItem(this.storeName);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        color: Colors.blue,
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.all(5),
        alignment: Alignment.center,
        child: Text(
          this.storeName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
          ),
        ),
      ),
    );
  }
}
