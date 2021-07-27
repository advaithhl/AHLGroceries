import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class StorePage extends StatefulWidget {
  final List<String> myItems = [];

  @override
  _StorePageState createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  late TextEditingController _newItemTextFieldController =
      TextEditingController();

  /// Update backend list on reordering.
  void reorderData(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final items = widget.myItems.removeAt(oldIndex);
      widget.myItems.insert(newIndex, items);
    });
  }

  /// Share the list, if user taps on share button.
  void shareList() {
    String shareText = widget.myItems.join("\n");
    Share.share(shareText);
  }

  Icon _getShareIcon() {
    if (Platform.isAndroid) return Icon(Icons.share);
    return Icon(Icons.ios_share);
  }

  Future<String> _showEditDialogue(String item) async {
    late TextEditingController _editItemTextFieldController =
        TextEditingController(text: item);
    return await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Edit item'),
          content: TextField(
            controller: _editItemTextFieldController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(_editItemTextFieldController.text);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    CollectionReference storeCollection =
        FirebaseFirestore.instance.collection('testcoll');
    return Scaffold(
      appBar: AppBar(
        title: Text("Second Route"),
        actions: <Widget>[
          if (widget.myItems.length != 0)
            IconButton(
              onPressed: shareList,
              icon: _getShareIcon(),
            ),
        ],
      ),
      body: Column(
        children: [
          StreamBuilder<dynamic>(
            stream: storeCollection.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Expanded(
                  child: Center(
                    child: Text('Loading'),
                  ),
                );
              return Expanded(
                child: Center(
                  child: ReorderableListView.builder(
                    itemCount: snapshot.data.docs.length,
                    onReorder: reorderData,
                    itemBuilder: (BuildContext context, int index) {
                      var item = snapshot.data.docs[index]['itemName'];
                      return Dismissible(
                        key: ValueKey(item),
                        child: ListTile(
                          key: ValueKey(item),
                          title: Container(
                            color: Colors.cyan,
                            height: 80,
                            child: Center(
                              child: Text(
                                item,
                                style: TextStyle(
                                  fontSize: 30,
                                ),
                              ),
                            ),
                          ),
                          onTap: () async {
                            String editedValue = await _showEditDialogue(item);
                            setState(() {
                              widget.myItems[index] = editedValue;
                            });
                          },
                        ),
                        onDismissed: (direction) {
                          setState(() {
                            widget.myItems.removeAt(index);
                          });
                        },
                      );
                    },
                  ),
                ),
              );
            },
          ),
          SizedBox(
            height: 70,
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _newItemTextFieldController,
                decoration: InputDecoration(
                  labelText: 'Tap here to add new item',
                  hintText: 'New item',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (String text) {
                  if (!widget.myItems.contains(text)) widget.myItems.add(text);
                  setState(() {
                    _newItemTextFieldController.text = '';
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
