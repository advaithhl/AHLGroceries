import 'package:ahl_groceries/database.dart';
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

  FloatingActionButton _getFAB(String heroTag) {
    return FloatingActionButton(
      child: Center(
        child:
            Icon(_amIEditing == StorePage.VIEW_MODE ? Icons.edit : Icons.save),
      ),
      onPressed: () {
        setState(() {
          _amIEditing == StorePage.VIEW_MODE
              ? _amIEditing = StorePage.EDIT_MODE
              : _amIEditing = StorePage.VIEW_MODE;
        });
      },
      heroTag: heroTag,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.storeName),
        actions: <Widget>[
          IconButton(
            onPressed: shareList,
            icon: Icon(Icons.share),
          ),
        ],
      ),
      body: IndexedStack(
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
                    return ListTile(
                      key: ValueKey(item),
                      title: Container(
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
                          title: PhysicalModel(
                            color: Colors.black,
                            elevation: 8.0,
                            borderRadius: _listItemBorderRadius,
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
                      print(widget.myItems);
                    },
                  ),
                  floatingActionButton: _getFAB('editModeFab'),
                ),
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
        ],
      ),
      floatingActionButton: Visibility(
        visible: _amIEditing == StorePage.VIEW_MODE ? true : false,
        child: _getFAB('viewModeFab'),
      ),
    );
  }
}
