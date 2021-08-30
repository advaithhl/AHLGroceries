import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

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
    QuerySnapshot allDataSnap = await getCollection().orderBy('index').get();
    List<String> allDataList = [];
    allDataSnap.docs.forEach((document) {
      allDataList.add(document.get('itemName'));
    });
    return allDataList;
  }

  void updateAllItems(List<String> updatedList) {
    getInstance().runTransaction((transaction) async {
      QuerySnapshot<dynamic> snapAllDocs =
          await getCollection().orderBy('index').get();
      int idx, listLength, snapLength;
      listLength = updatedList.length;
      snapLength = snapAllDocs.docs.length;
      for (idx = 0; idx < min(listLength, snapLength); ++idx) {
        transaction.update(
            snapAllDocs.docs[idx].reference, {'itemName': updatedList[idx]});
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
