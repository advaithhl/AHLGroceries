import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PopupCardRoute<T> extends PageRoute<T> {
  PopupCardRoute({
    required WidgetBuilder builder,
    bool fullscreenDialog = false,
  })  : _builder = builder,
        super(fullscreenDialog: fullscreenDialog);

  final WidgetBuilder _builder;

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  bool get maintainState => true;

  @override
  Color get barrierColor => Colors.black54;

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return child;
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return _builder(context);
  }

  @override
  String get barrierLabel => 'A popup of item being displayed.';
}

class PopupCard extends StatefulWidget {
  final String item;

  PopupCard({required this.item});

  @override
  _PopupCardState createState() => _PopupCardState();
}

class _PopupCardState extends State<PopupCard> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Material(
          color: Colors.green,
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  children: [
                    Text(widget.item),
                    const Divider(
                      color: Colors.white,
                      thickness: 0.5,
                    ),
                    Container(
                      child: Row(
                        children: [
                          Flexible(
                            flex: 1,
                            fit: FlexFit.tight,
                            child: FloatingActionButton(
                              heroTag: null,
                              child: Icon(
                                Icons.remove,
                                color: Colors.black,
                              ),
                              onPressed: () {},
                              backgroundColor: Colors.deepOrange,
                            ),
                          ),
                          Flexible(
                            flex: 2,
                            fit: FlexFit.tight,
                            child: Container(
                              margin: EdgeInsets.all(10),
                              height: 100,
                              child: Center(
                                child: Text(
                                  '9999',
                                  style: TextStyle(
                                    fontSize: 40,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Flexible(
                            flex: 1,
                            fit: FlexFit.tight,
                            child: FloatingActionButton(
                              heroTag: null,
                              child: Icon(
                                Icons.add,
                                color: Colors.black,
                              ),
                              onPressed: () {},
                              backgroundColor: Colors.deepOrange,
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
