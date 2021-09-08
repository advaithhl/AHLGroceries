import 'dart:math';

import 'package:ahl_groceries/database.dart';
import 'package:ahl_groceries/main.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class StorePage extends StatefulWidget {
  final List<String> myItems = [];
  final String storeName;
  static const int VIEW_MODE = 0;
  static const int EDIT_MODE = 1;

  StorePage({required this.storeName});

  @override
  _StorePageState createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  late TextEditingController _newItemTextFieldController =
      TextEditingController();
  late Database db;
  final BorderRadius _listItemBorderRadius =
      BorderRadius.all(Radius.circular(12.0));
  int _amIEditing = StorePage.VIEW_MODE;
  String newItemName = '';

  @override
  void initState() {
    super.initState();
    db = Database(widget.storeName);
  }

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

  Future<bool> showForwardDialogue(String toMoveItem) async {
    return await showDialog(
            context: context,
            builder: (_) {
              return AlertDialog(
                title: const Text('Move item'),
                content: Container(
                  width: double.minPositive,
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (String toMoveStore in StoreListPage.stores)
                        ListTile(
                          title: Center(
                            child: Text(
                              toMoveStore,
                              style: TextStyle(fontSize: 20),
                            ),
                          ),
                          onTap: () {
                            db.moveItem(toMoveItem, toMoveStore);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Item moved to $toMoveStore.'),
                              ),
                            );
                            Navigator.of(context).pop(true);
                          },
                        ),
                    ],
                  ),
                ),
              );
            }) ??
        false;
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

  Future<bool> _enterEditMode() async {
    bool isSomeoneEditing = await db.isSomeoneEditing(widget.storeName);
    if (!isSomeoneEditing) {
      db.changeEditMode(widget.storeName, true);
      widget.myItems.clear();
      List<String> allItems = await db.getAllItems();
      allItems.forEach((itemName) {
        widget.myItems.add(itemName);
      });
      return true;
    }
    return false;
  }

  void _exitEditMode() {
    db.updateAllItems(widget.myItems);
    db.changeEditMode(widget.storeName, false);
  }

  Future<bool> _onGoingBack() async {
    if (_amIEditing == StorePage.EDIT_MODE) {
      return await showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Discard changes?'),
                content: const Text('Do you want to leave without saving your '
                    'changes?'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('No'),
                  ),
                  TextButton(
                    onPressed: () {
                      db.changeEditMode(widget.storeName, false);
                      Navigator.of(context).pop(true);
                    },
                    child: const Text('Yes'),
                  ),
                ],
              );
            },
          ) ??
          false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.storeName),
        actions: <Widget>[
          IconButton(
            onPressed: db.deleteDismissedItems,
            icon: Icon(Icons.delete),
          ),
          IconButton(
            onPressed: shareList,
            icon: Icon(Icons.share),
          ),
        ],
      ),
      body: WillPopScope(
        onWillPop: _onGoingBack,
        child: IndexedStack(
          index: _amIEditing,
          children: [
            StreamBuilder<dynamic>(
              stream: db.getStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(
                    child: CircularProgressIndicator.adaptive(),
                  );
                return Center(
                  child: ListView.builder(
                    itemCount: db.getSnapshotLength(snapshot),
                    itemBuilder: (BuildContext context, int index) {
                      String item = db.getItemByIndex(snapshot, index);
                      int indexField = db.getIndexFieldByIndex(snapshot, index);
                      return Dismissible(
                        // random keys are generated, as item is not deleted.
                        key: ValueKey(index + Random().nextInt(100000)),
                        onDismissed: (_) {
                          var dismissedReference =
                              db.getDocByIndex(snapshot, index).reference;
                          db.deleteItemInStore(dismissedReference);
                        },
                        child: ListTile(
                          key: ValueKey(item),
                          title: Container(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                item,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 30,
                                  decoration: (indexField > 16383)
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                ),
                              ),
                            ),
                            decoration: BoxDecoration(
                              color: (indexField > 16383)
                                  ? Colors.grey
                                  : Colors.cyan,
                              borderRadius: _listItemBorderRadius,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            Column(
              children: [
                Expanded(
                  child: Scaffold(
                    body: ReorderableListView.builder(
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      itemCount: widget.myItems.length,
                      itemBuilder: (BuildContext context, int index) {
                        String item = widget.myItems[index];
                        return Dismissible(
                          key: ValueKey(item),
                          child: ListTile(
                            key: ValueKey(item),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Text(
                                        item,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 30,
                                        ),
                                      ),
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.cyan,
                                      borderRadius: _listItemBorderRadius,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.forward),
                                  onPressed: () async {
                                    bool moveConfirmed =
                                        await showForwardDialogue(item);
                                    if (moveConfirmed) {
                                      setState(() {
                                        widget.myItems.removeAt(index);
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                            onTap: () async {
                              String editedValue =
                                  await _showEditDialogue(item);
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
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) {
                            newIndex -= 1;
                          }
                          final item = widget.myItems.removeAt(oldIndex);
                          widget.myItems.insert(newIndex, item);
                        });
                      },
                    ),
                    floatingActionButton: FloatingActionButton(
                      child: Center(
                        child: Icon(Icons.save),
                      ),
                      onPressed: () {
                        _exitEditMode();
                        setState(() {
                          _amIEditing = StorePage.VIEW_MODE;
                        });
                      },
                      heroTag: 'editFab',
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    height: 70,
                    width: double.infinity,
                    child: TextField(
                      controller: _newItemTextFieldController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        suffixIcon: newItemName.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  setState(() {
                                    widget.myItems.add(newItemName);
                                    newItemName = '';
                                    _newItemTextFieldController.clear();
                                  });
                                },
                                icon: Icon(Icons.send),
                              )
                            : null,
                        labelText: 'Tap here to add new item',
                        hintText: 'New item',
                        border: OutlineInputBorder(),
                      ),
                      onEditingComplete: () {},
                      onChanged: (String text) {
                        setState(() {
                          newItemName = text;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: Visibility(
        visible: _amIEditing == StorePage.VIEW_MODE ? true : false,
        child: FloatingActionButton(
          child: Center(
            child: Icon(Icons.edit),
          ),
          onPressed: () async {
            bool editAllowed = false;
            bool errorCaught = false;
            try {
              editAllowed = await _enterEditMode();
            } catch (_) {
              errorCaught = true;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('You seem to be offline. Please go '
                      'online to edit items.'),
                ),
              );
            }
            if (!errorCaught) {
              if (editAllowed) {
                setState(() {
                  _amIEditing = StorePage.EDIT_MODE;
                });
              } else {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Someone else is editing'),
                      content:
                          const Text('Someone else is editing this list right '
                              'now. Please wait for them to finish editing, '
                              'before trying to edit yourself.'),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('OK'),
                        ),
                      ],
                    );
                  },
                );
              }
            }
          },
          heroTag: 'viewFab',
        ),
      ),
    );
  }
}
