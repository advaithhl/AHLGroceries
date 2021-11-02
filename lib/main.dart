import 'package:ahl_groceries/storepage.dart';
import 'package:animations/animations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';


/// Entry point of the application.
///
/// Before application is run, await Firebase initialisation, and post that,
/// initialise FirebaseFirestore.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseFirestore.instance.enablePersistence();
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
      child: OpenContainer(
          transitionType: ContainerTransitionType.fadeThrough,
          closedBuilder: (_, __) {
            return InkWell(
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
            );
          },
          openBuilder: (_, __) => StorePage(storeName: storeName)),
    );
  }
}
