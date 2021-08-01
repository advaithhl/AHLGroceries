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

  DocumentSnapshot getDocByIndex(var snapshot, int index) {
    return getDocs(snapshot)[index];
  }

  void addItem(String itemName) async {
    int index = await getCollection()
        .get()
        .then((allDocsSnapshot) => allDocsSnapshot.docs.length);
    getCollection().add({'index': index, 'itemName': itemName});
  }

  String getItemByIndex(var snapshot, int index) {
    return getDocByIndex(snapshot, index)['itemName'];
  }

  void updateItemByIndex(var snapshot, int index, String newValue) {
    getInstance().runTransaction((transaction) async {
      DocumentSnapshot documentSnapshot =
          await transaction.get(getDocByIndex(snapshot, index).reference);
      transaction.update(documentSnapshot.reference, {'itemName': newValue});
    });
  }

  void deleteItemByIndex(int index) {
    // get the instance, and run a transaction.
    getInstance().runTransaction((transaction) async {
      // get all docs whose 'index' field is greater than or equal to the
      // index the index to be deleted. also fetch the item to be deleted, to
      // delete in the next step. order by index, because, the deleted item
      // will be the first item in the snapshot.
      QuerySnapshot<dynamic> snapDocsFromIndex = await getCollection()
          .where('index', isGreaterThanOrEqualTo: index)
          .orderBy('index')
          .get();
      // iterate through documents, set index-- for all.
      snapDocsFromIndex.docs.forEach((doc) =>
          transaction.update(doc.reference, {'index': doc.get('index') - 1}));
      // delete the first doc. this is the doc to delete, as the snapshot was
      // ordered, while fetching.
      transaction.delete(snapDocsFromIndex.docs.first.reference);
    });
  }
}
