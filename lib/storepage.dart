import 'package:ahl_groceries/popups.dart';
import 'package:flutter/material.dart';

class StorePage extends StatefulWidget {
  final List<String> myItems = [
    'Item name 1',
    'Item name 2',
    'Item name 3',
    'Item name 4',
    'Item name 5',
    'Item name 6',
    'Item name 7',
  ];

  @override
  _StorePageState createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Second Route"),
      ),
      body: Center(
        child: ReorderableListView.builder(
          itemCount: widget.myItems.length,
          onReorder: reorderData,
          itemBuilder: (BuildContext context, int index) {
            var item = widget.myItems[index];
            return Dismissible(
              key: ValueKey(item),
              child: ListTile(
                key: ValueKey(item),
                title: Text(item),
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
    );
  }
}
