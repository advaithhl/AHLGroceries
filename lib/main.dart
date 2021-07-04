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
      home: StorePage(title: 'AHL Groceries'),
    );
  }
}

class StorePage extends StatefulWidget {
  StorePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _StorePageState createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          StoreWidget("Store1"),
          StoreWidget("Store2"),
          StoreWidget("Store3"),
          StoreWidget("Store4"),
          StoreWidget("Store5"),
        ],
      ),
    );
  }
}

/// A StatelessWidget to represent a single store.
class StoreWidget extends StatelessWidget {
  final String storeName;

  const StoreWidget(this.storeName);

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
