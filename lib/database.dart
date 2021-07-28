import 'package:cloud_firestore/cloud_firestore.dart';

class Database {
  late FirebaseFirestore _instance;
  final String collectionPath;
  late CollectionReference _collectionReference;

  Database(this.collectionPath) {
    this._instance = FirebaseFirestore.instance;
    this._collectionReference = this._instance.collection(collectionPath);
  }

  FirebaseFirestore getInstance() {
    return this._instance;
  }

  CollectionReference getCollection() {
    return this._collectionReference;
  }

  Query<dynamic> getOrderedCollection() {
    return getCollection().orderBy('index');
  }

  Stream<QuerySnapshot<dynamic>> getStream() {
    return getOrderedCollection().snapshots();
  }

  List<QueryDocumentSnapshot<dynamic>> getDocs(var snapshot) {
    return snapshot.data.docs;
  }

  int getSnapshotLength(var snapshot) {
    return getDocs(snapshot).length;
  }

  String getItemByIndex(var snapshot, int index) {
    return getDocs(snapshot)[index]['itemName'];
  }
}
