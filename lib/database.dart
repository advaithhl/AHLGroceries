import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

/// This class acts as an abstraction to Firestore.
/// All database operations are defined here.
/// There must be no isolated database operation anywhere else in the app.
class Database {
  late FirebaseFirestore _instance;
  final String collectionPath;
  late CollectionReference _collectionReference;

  Database(this.collectionPath) {
    this._instance = FirebaseFirestore.instance;
    this._collectionReference = this._instance.collection(collectionPath);
  }

  Future<bool> isSomeoneEditing(String storeName) async {
    DocumentSnapshot documentSnapshot = await getInstance()
        .doc('/EditMode/$storeName')
        .get(GetOptions(source: Source.server));
    return documentSnapshot.get('editingNow');
  }

  void changeEditMode(String storeName, bool editingNow) async {
    DocumentSnapshot documentSnapshot =
        await getInstance().doc('/EditMode/$storeName').get();
    documentSnapshot.reference.set({'editingNow': editingNow});
  }

  Future<List<String>> getAllItems() async {
    QuerySnapshot allDataSnap = await getCollection()
        .where('index', isLessThan: 16384)
        .orderBy('index')
        .get();
    List<String> allDataList = [];
    allDataSnap.docs.forEach((document) {
      allDataList.add(document.get('itemName'));
    });
    return allDataList;
  }

  void updateAllItems(List<String> updatedList) {
    getInstance().runTransaction((transaction) async {
      QuerySnapshot<dynamic> snapAllDocs = await getCollection()
          .where('index', isLessThan: 16384)
          .orderBy('index')
          .get();
      int idx, listLength, snapLength;
      listLength = updatedList.length;
      snapLength = snapAllDocs.docs.length;
      for (idx = 0; idx < min(listLength, snapLength); ++idx) {
        // update all index values with the list's "actual" indices.
        // this is so as to rectify gaps introduced by dismissing items
        // outside edit mode.
        transaction.update(snapAllDocs.docs[idx].reference, {
          'index': idx,
          'itemName': updatedList[idx],
        });
      }
      if (listLength > snapLength) {
        // items were added.
        for (; idx < listLength; ++idx) {
          transaction.set(getCollection().doc(), {
            'index': idx,
            'itemName': updatedList[idx],
          });
        }
      } else {
        //items were deleted.
        for (; idx < snapLength; ++idx) {
          transaction.delete(snapAllDocs.docs[idx].reference);
        }
      }
    });
  }

  int _getDismissedIndex() {
    // number of milliseconds since epoch - number of milliseconds since
    // beginning of month + 16384. 16384 is so that the first subtraction
    // might yield 0, a conflicting index. Also, it's 2^14, so that's nice.
    DateTime now = DateTime.now().toUtc();
    DateTime beginning = DateTime.utc(now.year, now.month);
    Duration duration = now.difference(beginning);
    return duration.inMilliseconds + 16384;
  }

  void deleteItemInStore(DocumentReference documentReference) {
    // deleting the item in the store DOES NOT actually delete the document.
    // the document gets a large positive value as index, strictly greater
    // than 2^14 - 1. this makes the document go to the bottom. only this
    // document has to be updated. later, this will be deleted.
    documentReference
        .set({'index': _getDismissedIndex()}, SetOptions(merge: true));
  }

  void deleteDismissedItems() async {
    QuerySnapshot dismissedItems = await getCollection()
        .where('index', isGreaterThanOrEqualTo: 16384)
        .get();
    dismissedItems.docs.forEach((doc) {
      doc.reference.delete();
    });
  }

  void moveItem(String toMoveItem, String toMoveStore) {
    Database toMoveDB = Database(toMoveStore);
    toMoveDB.addItem(toMoveItem);
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
        .where('index', isLessThan: 16384)
        .get()
        .then((allDocsSnapshot) => allDocsSnapshot.docs.length);
    getCollection().add({'index': index, 'itemName': itemName});
  }

  int getIndexFieldByIndex(var snapshot, int index) {
    return getDocByIndex(snapshot, index)['index'];
  }

  String getItemByIndex(var snapshot, int index) {
    return getDocByIndex(snapshot, index)['itemName'];
  }

  void updateItemByIndex(var snapshot, int index, String newValue) {
    // get the instance, and run a transation.
    getInstance().runTransaction((transaction) async {
      // get a snapshot of the document and update the item within the transation.
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

  void moveItemUp(int index) {
    // move the item at index, one position up.
    getInstance().runTransaction((transaction) async {
      // get index and index-1 snapshots.
      QuerySnapshot<dynamic> snapDocAndUp = await getCollection()
          .where('index',
              isGreaterThanOrEqualTo: index - 1, isLessThanOrEqualTo: index)
          .orderBy('index')
          .get();
      // swap their indices.
      transaction.update(snapDocAndUp.docs.first.reference, {'index': index});
      transaction
          .update(snapDocAndUp.docs.last.reference, {'index': index - 1});
    });
  }

  void moveItemDown(int index) {
    // move the item at index, one position down.
    getInstance().runTransaction((transaction) async {
      // get index and index+1 snapshots.
      QuerySnapshot<dynamic> snapDocAndDown = await getCollection()
          .where('index',
              isGreaterThanOrEqualTo: index, isLessThanOrEqualTo: index + 1)
          .orderBy('index')
          .get();
      // swap their indices.
      transaction
          .update(snapDocAndDown.docs.first.reference, {'index': index + 1});
      transaction.update(snapDocAndDown.docs.last.reference, {'index': index});
    });
  }

  // Order items by the index, and append items to a list, and return this list.
  Future<List<String>> getShareTextList() async {
    List<String> allItems = [];
    await getCollection()
        .orderBy('index')
        .get()
        .then((allDocsSnapshot) => allDocsSnapshot.docs.forEach((doc) {
              allItems.add(doc.get('itemName'));
            }));
    return allItems;
  }
}
