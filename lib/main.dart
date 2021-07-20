import 'package:ahl_groceries/storepage.dart';
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
  static const List<String> stores = [
    'Daily Angadi',
    'Lulu',
    'Farm Mart',
    'Supreme',
    'Worldmart',
    'Farmers',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(this.title),
      ),
      body: Column(
        children: [for (String store in stores) StoreListPageItem(store)],
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
      child: InkWell(
        child: Container(
          color: Colors.blue,
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.all(5),
          alignment: Alignment.center,
          child: FittedBox(
            child: Text(
              this.storeName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
              ),
            ),
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => StorePage()),
          );
        },
      ),
    );
  }
}
