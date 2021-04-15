import 'dart:async';

import 'package:flutter/material.dart';

import 'package:rxdart/subjects.dart';
import 'package:rxdart/rxdart.dart';

import 'models/prediction.dart';

class AutocompleteTextField extends StatefulWidget {
  final InputDecoration inputDecoration;
  final ItemClick itmClick;
  final GetPlaceDetailsWithLatLng getPlaceDetailWithLatLng;
  final bool dismissKeyboardAfterClick;
  final Function onTap;
  final Color backgroundColor;
  final EdgeInsets margin;
  final TextStyle textStyle;
  final int debounceTime;
  final bool showMapButton;
  final FocusNode focusNode;
  final Function onCleanUp;

  final TextEditingController textEditingController;

  AutocompleteTextField({
    @required this.textEditingController,
    this.debounceTime = 300,
    this.inputDecoration = const InputDecoration(),
    this.itmClick,
    this.dismissKeyboardAfterClick = true,
    this.textStyle = const TextStyle(),
    this.getPlaceDetailWithLatLng,
    this.onTap,
    this.backgroundColor,
    this.margin = EdgeInsets.zero,
    this.showMapButton = true,
    this.focusNode,
    this.onCleanUp,
  });

  @override
  AutocompleteTextFieldState createState() => AutocompleteTextFieldState();
}

class AutocompleteTextFieldState extends State<AutocompleteTextField> {
  final subject = PublishSubject<String>();
  OverlayEntry _overlayEntry;
  List<Prediction> alPredictions = [];

  TextEditingController controller = TextEditingController();
  bool isSearched = false;

  final GlobalKey key = GlobalKey();
  final LayerLink _layerLink = LayerLink();

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Padding(
        padding: widget.margin,
        child: TextFormField(
          key: key,
          onTap: widget.onTap,
          decoration: widget.inputDecoration.copyWith(
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                MaterialButton(
                  onPressed: () {
                    if (widget.onCleanUp != null) {
                      widget.onCleanUp();
                    }
                    widget.textEditingController.clear();
                    getLocation('');
                  },
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          widget.showMapButton ? BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)) : BorderRadius.circular(10)),
                  minWidth: 0,
                  child: Icon(
                    Icons.clear,
                    color: Colors.red,
                    size: 18,
                  ),
                ),
                Visibility(
                  visible: widget.showMapButton,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 1, height: 40, color: Color.fromARGB(255, 128, 128, 128)),
                      TextButton(
                        child: Text(
                          'Карта',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color.fromARGB(255, 97, 97, 97)),
                        ),
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 15),
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topRight: Radius.circular(10), bottomRight: Radius.circular(10))),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          style: widget.textStyle,
          controller: widget.textEditingController,
          onChanged: subject.add,
          focusNode: widget.focusNode,
        ),
      ),
    );
  }

  void dismissOverlay() {
    FocusScopeNode currentFocus = FocusScope.of(key.currentContext);
    if (currentFocus.hasPrimaryFocus) {
      removeOverlay();
    }
  }

  StreamSubscription subscription;

  @override
  void initState() {
    widget.textEditingController.addListener(dismissOverlay);
    subscription = subject.stream.distinct().debounceTime(Duration(milliseconds: widget.debounceTime)).listen(textChanged);
    super.initState();
  }

  @override
  void dispose() {
    widget.textEditingController.removeListener(dismissOverlay);
    this.controller.dispose();
    this.alPredictions.clear();
    this.subscription?.cancel();
    this.subject.close();
    this._overlayEntry?.remove();
    this._overlayEntry = null;
    super.dispose();
  }

  getLocation(String text) async {
    PlacesAutocompleteResponse subscriptionResponse = PlacesAutocompleteResponse();
    await subscriptionResponse.getPredictions(text);

    if (text.isEmpty) {
      alPredictions.clear();
      if (_overlayEntry != null) {
        _overlayEntry.remove();
        _overlayEntry = null;
      }
      return;
    }

    isSearched = false;
    alPredictions.clear();
    if (subscriptionResponse.predictions != null && subscriptionResponse.predictions.isNotEmpty) {
      alPredictions.addAll(subscriptionResponse.predictions);
    }

    if (_overlayEntry != null) {
      _overlayEntry.remove();
    }

    this._overlayEntry = null;
    this._overlayEntry = this._createOverlayEntry();
    Overlay.of(context).insert(this._overlayEntry);
  }

  textChanged(String text) async {
    getLocation(text);
  }

  OverlayEntry _createOverlayEntry() {
    if (context != null && context.findRenderObject() != null) {
      RenderBox renderBox = context.findRenderObject();
      var size = renderBox.size;
      var offset = renderBox.localToGlobal(Offset.zero);
      return OverlayEntry(
        builder: (context) => Positioned(
          left: offset.dx + widget.margin.left,
          top: size.height + offset.dy,
          width: size.width - widget.margin.left - widget.margin.right,
          bottom: MediaQuery.of(context).viewInsets.bottom,
          child: CompositedTransformFollower(
            showWhenUnlinked: false,
            link: _layerLink,
            offset: Offset(widget.margin.left, size.height),
            child: Material(
              color: widget.backgroundColor,
              elevation: 0.0,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                shrinkWrap: true,
                itemCount: alPredictions.length,
                itemBuilder: (BuildContext context, int index) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      if (index < alPredictions.length) {
                        if (widget.itmClick != null) widget.itmClick(alPredictions[index]);
                        if (widget.getPlaceDetailWithLatLng != null) widget.getPlaceDetailWithLatLng(alPredictions[index]);

                        if (!widget.dismissKeyboardAfterClick) return;
                        removeOverlay();
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.only(left: 10, right: 10, top: 13, bottom: 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alPredictions[index].structuredFormatting.mainText,
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            alPredictions[index].structuredFormatting.secondaryText,
                            style: TextStyle(
                              fontSize: 12,
                              color: Color.fromARGB(128, 0, 0, 0),
                            ),
                          ),
                          SizedBox(height: 13),
                          Divider(
                            color: Color.fromARGB(255, 128, 128, 128),
                            thickness: 1,
                            height: 0,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
    }
    return OverlayEntry(builder: (context) => Container());
  }

  removeOverlay() {
    alPredictions.clear();
    if (_overlayEntry != null) {
      _overlayEntry.remove();
      _overlayEntry = null;
    }
    /*this._overlayEntry = this._createOverlayEntry(dismiss: true);
    if (context != null) {
      Overlay.of(context).insert(this._overlayEntry);
      this._overlayEntry.markNeedsBuild();
    }*/
  }
}

void hideKeyboard(BuildContext context) {
  FocusScopeNode currentFocus = FocusScope.of(context);
  if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
    FocusManager.instance.primaryFocus.unfocus();
  }
}

typedef ItemClick = void Function(Prediction postalCodeResponse);
typedef GetPlaceDetailsWithLatLng = void Function(Prediction postalCodeResponse);
