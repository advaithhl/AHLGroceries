import 'package:ahl_groceries/database.dart';
import 'package:ahl_groceries/main.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// This is the place where all the action takes place. :P
class StorePage extends StatefulWidget {
  final List<String> myItems = [];
  final String storeName;
  static const int STORE_MODE = 0;
  static const int HOME_MODE = 1;

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
  int _amIEditing = StorePage.STORE_MODE;
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
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                controller: _editItemTextFieldController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context)
                        .pop(_editItemTextFieldController.text);
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        ) ??
        item;
  }

  Future<void> showItemExistsDialogue() async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('This item already exists'),
          content: const Text(
              'The item which you just entered already exists in the list.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  String _getNewItemInBetween() {
    int counter = 1;
    String newItemNameStart = 'New item';
    while (widget.myItems.contains('$newItemNameStart $counter')) counter++;
    return '$newItemNameStart $counter';
  }

  void manageNewItem() {
    if (!widget.myItems.contains(newItemName)) {
      setState(() {
        widget.myItems.add(newItemName);
        newItemName = '';
        _newItemTextFieldController.clear();
      });
    } else {
      showItemExistsDialogue();
    }
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

  Future<bool> saveOnGoingBack() async {
    if (_amIEditing == StorePage.HOME_MODE) _exitEditMode();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _amIEditing == StorePage.STORE_MODE
            ? Text(widget.storeName)
            : Text('${widget.storeName} - Editing'),
        backgroundColor:
            _amIEditing == StorePage.STORE_MODE ? Colors.green : Colors.red,
        // show actions only in store mode.
        actions: _amIEditing == StorePage.STORE_MODE
            ? <Widget>[
                IconButton(
                  onPressed: db.deleteDismissedItems,
                  icon: Icon(Icons.delete),
                ),
                IconButton(
                  onPressed: shareList,
                  icon: Icon(Icons.share),
                ),
              ]
            : null,
        centerTitle: true,
      ),
      body: WillPopScope(
        onWillPop: saveOnGoingBack,
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
                        key: ValueKey(indexField),
                        onDismissed: (_) {
                          var dismissedReference =
                              db.getDocByIndex(snapshot, index).reference;
                          db.deleteItemInStore(dismissedReference);
                        },
                        child: ListTile(
                          key: ValueKey(indexField),
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
                  child: ReorderableListView.builder(
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    itemCount: widget.myItems.length,
                    itemBuilder: (BuildContext context, int index) {
                      String item = widget.myItems[index];
                      return Dismissible(
                        key: ValueKey(item),
                        child: ListTile(
                          key: ValueKey(item),
                          title: Container(
                            child: Column(
                              children: [
                                Material(
                                  elevation: 4,
                                  child: Container(
                                    color: Colors.cyan,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 70,
                                          child: IconButton(
                                            onPressed: () {
                                              String newItem =
                                                  _getNewItemInBetween();
                                              setState(() {
                                                widget.myItems
                                                    .insert(index, newItem);
                                              });
                                            },
                                            icon: Icon(Icons.arrow_upward),
                                          ),
                                        ),
                                        Expanded(
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
                                        ),
                                        Container(
                                          width: 70,
                                          child: IconButton(
                                            onPressed: () {
                                              String newItem =
                                                  _getNewItemInBetween();
                                              setState(() {
                                                widget.myItems
                                                    .insert(index + 1, newItem);
                                              });
                                            },
                                            icon: Icon(Icons.arrow_downward),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: double.infinity,
                                  child: IconButton(
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
                                ),
                              ],
                            ),
                            decoration: BoxDecoration(
                              color: Colors.pink[600],
                              borderRadius: BorderRadius.horizontal(
                                right: Radius.circular(12.0),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.5),
                                  spreadRadius: 5,
                                  blurRadius: 7,
                                  offset: Offset(0, 3),
                                ),
                              ],
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
                                onPressed: manageNewItem,
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
        visible: _amIEditing == StorePage.STORE_MODE ? true : false,
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
                  _amIEditing = StorePage.HOME_MODE;
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
          heroTag: 'storeFab',
        ),
      ),
    );
  }
}
