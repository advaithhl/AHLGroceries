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

class StoreListPage extends StatefulWidget {
  StoreListPage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _StoreListPageState createState() => _StoreListPageState();
}

class _StoreListPageState extends State<StoreListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
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
