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
      body: Center(
        child: Text(
          "Text"
        ),
      ),
    );
  }
}
