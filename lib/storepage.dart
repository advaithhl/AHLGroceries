import 'package:ahl_groceries/popups.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io' show Platform;

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

  void _showPopupCardRoute(BuildContext context, int index) async {
    var item = widget.myItems[index];
    final double itemQuantity = await Navigator.of(context).push(
      PopupCardRoute(
        builder: (context) => PopupCard(
          item: item,
        ),
      ),
    );
    final snackBar = SnackBar(content: Text('$item set to $itemQuantity'));
    Scaffold.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  Icon _getShareIcon() {
    if (Platform.isAndroid) return Icon(Icons.share);
    return Icon(Icons.ios_share);
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
          Expanded(
            child: Center(
              child: ReorderableListView.builder(
                itemCount: widget.myItems.length,
                onReorder: reorderData,
                itemBuilder: (BuildContext context, int index) {
                  var item = widget.myItems[index];
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
                      onTap: () {
                        _showPopupCardRoute(context, index);
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
