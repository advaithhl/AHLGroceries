import 'dart:io' show Platform;

import 'package:ahl_groceries/database.dart';
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
  final Database db = Database('testcoll');

  /// Share the list, if user taps on share button.
  void shareList() async {
    List<String> shareTextList = await db.getShareTextList();
    StringBuffer stringBuffer = StringBuffer();
    for (int idx = 1; idx <= shareTextList.length; ++idx) {
      stringBuffer.write('$idx. ${shareTextList[idx - 1]}\n');
    }
    String shareText = stringBuffer.toString();
    if (shareText.isNotEmpty)
      Share.share(stringBuffer.toString());
    else
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Please add items to share')),
      );
  }

  Icon _getShareIcon() {
    return Icon(Platform.isAndroid ? Icons.share : Icons.ios_share);
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
    return Scaffold(
      appBar: AppBar(
        title: Text("Second Route"),
        actions: <Widget>[
          IconButton(
            onPressed: shareList,
            icon: _getShareIcon(),
          ),
        ],
      ),
      body: Column(
        children: [
          StreamBuilder<dynamic>(
            stream: db.getStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Expanded(
                  child: Center(
                    child: Text('Loading'),
                  ),
                );
              return Expanded(
                child: Center(
                  child: ListView.builder(
                    itemCount: db.getSnapshotLength(snapshot),
                    itemBuilder: (BuildContext context, int index) {
                      String item = db.getItemByIndex(snapshot, index);
                      return Dismissible(
                        key: ValueKey(item),
                        child: ListTile(
                          key: ValueKey(item),
                          title: Container(
                            color: Colors.cyan,
                            height: 80,
                            child: Row(
                              children: [
                                Container(
                                  width: 70,
                                  child: IconButton(
                                    onPressed: () {
                                      if (index != 0) {
                                        db.moveItemUp(index);
                                      }
                                    },
                                    icon: Icon(Icons.arrow_upward),
                                  ),
                                ),
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      item,
                                      style: TextStyle(
                                        fontSize: 30,
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 70,
                                  child: IconButton(
                                    onPressed: () {
                                      if (index !=
                                          db.getSnapshotLength(snapshot) - 1)
                                        db.moveItemDown(index);
                                    },
                                    icon: Icon(Icons.arrow_downward),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          onTap: () async {
                            String editedValue = await _showEditDialogue(item);
                            db.updateItemByIndex(snapshot, index, editedValue);
                          },
                        ),
                        onDismissed: (direction) {
                          db.deleteItemByIndex(index);
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
                  db.addItem(text);
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
