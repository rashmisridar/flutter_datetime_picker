library flutter_datetime_picker;

import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker/src/datetime_picker_theme.dart';
import 'package:flutter_datetime_picker/src/date_model.dart';
import 'package:flutter_datetime_picker/src/i18n_model.dart';

export 'package:flutter_datetime_picker/src/datetime_picker_theme.dart';
export 'package:flutter_datetime_picker/src/date_model.dart';
export 'package:flutter_datetime_picker/src/i18n_model.dart';

typedef DateChangedCallback(DateTime time);
typedef DateCancelledCallback();
typedef String StringAtIndexCallBack(int index);

class DatePicker {
  ///
  /// Display date picker bottom sheet.
  ///

  ///
  /// Display time picker bottom sheet with AM/PM.
  ///
  static showTime12hPickerOnly(
    BuildContext context, {
    bool showTitleActions: true,
    DateChangedCallback onChanged,
    DateChangedCallback onConfirm,
    DateCancelledCallback onCancel,
    locale: LocaleType.en,
    DateTime currentTime,
    DateTime maxDatePicker,
    DateTime minDatePicker,
    DatePickerTheme theme,
  }) {
    return DatePickerRoute(
      context: context,
      showTitleActions: showTitleActions,
      onChanged: onChanged,
      onConfirm: onConfirm,
      onCancel: onCancel,
      locale: locale,
      theme: theme,
      maxDatePicker: maxDatePicker,
      minDatePicker: minDatePicker,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      pickerModel: Time12hPickerModel(
        currentTime: currentTime,
        locale: locale,
      ),
    );
  }
}

class DatePickerRoute extends StatelessWidget {
  DatePickerRoute({
    this.context,
    this.showTitleActions,
    this.onChanged,
    this.onConfirm,
    this.onCancel,
    DatePickerTheme theme,
    this.barrierLabel,
    this.locale,
    this.minDatePicker,
    this.maxDatePicker,
    RouteSettings settings,
    BasePickerModel pickerModel,
  })  : this.pickerModel = pickerModel ?? DatePickerModel(),
        this.theme = theme ?? DatePickerTheme();

  final bool showTitleActions;
  final DateChangedCallback onChanged;
  final DateChangedCallback onConfirm;
  final DateCancelledCallback onCancel;
  final LocaleType locale;
  final DatePickerTheme theme;
  final DateTime minDatePicker;
  final DateTime maxDatePicker;
  final BasePickerModel pickerModel;
  final BuildContext context;
  @override
  Duration get transitionDuration => const Duration(milliseconds: 200);

  @override
  bool get barrierDismissible => true;

  @override
  final String barrierLabel;

  @override
  Color get barrierColor => Colors.black54;

  //AnimationController _animationController;

  /* @override
  AnimationController createAnimationController() {
    assert(_animationController == null);
    _animationController =
        BottomSheet.createAnimationController(navigator.overlay);
    return _animationController;
  }*/

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    Widget bottomSheet = MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: DatePickerComponent(
          onChanged: onChanged,
          locale: this.locale,
          route: this,
          pickerModel: pickerModel,
          maxDatePicker: maxDatePicker,
          minDatePicker: minDatePicker),
    );
    return InheritedTheme.captureAll(context, bottomSheet);
  }

  @override
  Widget build(BuildContext context) {
    Widget bottomSheet = MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: DatePickerComponent(
        onChanged: onChanged,
        locale: this.locale,
        route: this,
        pickerModel: pickerModel,
      ),
    );
    return InheritedTheme.captureAll(context, bottomSheet);
  }
}

class DatePickerComponent extends StatefulWidget {
  DatePickerComponent({
    Key key,
    this.route,
    this.pickerModel,
    this.onChanged,
    this.locale,
    this.minDatePicker,
    this.maxDatePicker,
  }) : super(key: key);

  final DateChangedCallback onChanged;

  final DateTime maxDatePicker;
  final DateTime minDatePicker;
  final DatePickerRoute route;

  final LocaleType locale;

  final BasePickerModel pickerModel;

  @override
  State<StatefulWidget> createState() {
    return _DatePickerState();
  }
}

class _DatePickerState extends State<DatePickerComponent> {
  FixedExtentScrollController leftScrollCtrl, middleScrollCtrl, rightScrollCtrl;

  @override
  void initState() {
    super.initState();
    refreshScrollOffset();
  }

  void refreshScrollOffset() {
    print('refreshScrollOffset ${widget.pickerModel.currentLeftIndex()}');
    leftScrollCtrl = FixedExtentScrollController(
        initialItem: widget.pickerModel.currentLeftIndex());
    middleScrollCtrl = FixedExtentScrollController(
        initialItem: widget.pickerModel.currentMiddleIndex());
    rightScrollCtrl = FixedExtentScrollController(
        initialItem: widget.pickerModel.currentRightIndex());
  }

  @override
  Widget build(BuildContext context) {
    DatePickerTheme theme = widget.route.theme;
    return Material(
      // color: CoonstColor.green,
      child: Container(
        color: Colors.white,
        child: Material(
          //color: CoonstColor.red,
          //   color: theme.backgroundColor,
          //color: Colors.blueAccent,
          child: _renderPickerView(theme),
        ),
      ),
    );
  }

  void _notifyDateChanged() {
    if (widget.onChanged != null) {
      print('notofydata change ${widget.pickerModel.finalTime()}');
      widget.onChanged(widget.pickerModel.finalTime());
    }
  }

  Widget _renderPickerView(DatePickerTheme theme) {
    Widget itemView = _renderItemView(theme);
    if (widget.route.showTitleActions == true) {
      return Column(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Expanded(flex: 4, child: itemView),
          Expanded(flex: 1, child: _renderTitleActionsView(theme)),
        ],
      );
    }
    return itemView;
  }

  Widget _renderColumnView(
    ValueKey key,
    DatePickerTheme theme,
    StringAtIndexCallBack stringAtIndexCB,
    ScrollController scrollController,
    int layoutProportion,
    ValueChanged<int> selectedChangedWhenScrolling,
    ValueChanged<int> selectedChangedWhenScrollEnd,
  ) {
    return Flexible(
      flex: layoutProportion,
      child: Container(
        padding: EdgeInsets.all(0.0),
        margin: EdgeInsets.fromLTRB(0, 10, 0, 10),
        // height: theme.containerHeight,
        decoration: BoxDecoration(
          color: theme.backgroundColor,
        ), //// Colors.yellow
        child: NotificationListener(
          onNotification: (ScrollNotification notification) {
            if (notification.depth == 0 &&
                notification is ScrollEndNotification &&
                notification.metrics is FixedExtentMetrics) {
              final FixedExtentMetrics metrics =
                  notification.metrics as FixedExtentMetrics;
              final int currentItemIndex = metrics.itemIndex;
              selectedChangedWhenScrollEnd(currentItemIndex);
            }
            return false;
          },
          child: CupertinoTheme(
            data: CupertinoThemeData(
                textTheme: CupertinoTextThemeData(
                    navTitleTextStyle: TextStyle(
                  color: Colors.white,
                  decorationColor: Colors.green,
                  decoration: TextDecoration.underline,
                  decorationStyle: TextDecorationStyle.wavy,
                )),
                barBackgroundColor: Colors.amber,
                primaryColor: Colors.green,
                brightness: Brightness.dark,
                scaffoldBackgroundColor: Colors.white,
                primaryContrastingColor: Colors.red),
            child: CupertinoPicker.builder(
              key: key,
              //theme.backgroundColor
              //  squeeze: 10,
              squeeze: 1.5,
              offAxisFraction: 0.0,
              magnification: 1.1,
              scrollController: scrollController as FixedExtentScrollController,
              itemExtent: theme.itemHeight,
              diameterRatio: 0.8,
              onSelectedItemChanged: (int index) {
                print('onSelectedItemChanged $index');
                selectedChangedWhenScrolling(index);
              },
              useMagnifier: false,
              itemBuilder: (BuildContext context, int index) {
                final content = stringAtIndexCB(index);
                if (content == null) {
                  return null;
                }
                return Container(
                  //  color: Colors.brown,
                  height: theme.itemHeight,
                  alignment: Alignment.center,
                  child: Text(
                    content,
                    style: theme.itemStyle,
                    textAlign: TextAlign.start,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _renderItemView(DatePickerTheme theme) {
    return Container(
      color: theme.backgroundColor, //Colors.red,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            //  width: 25,
            child: widget.pickerModel.layoutProportions()[0] > 0
                ? _renderColumnView(
                    ValueKey(widget.pickerModel.currentLeftIndex()),
                    theme,
                    widget.pickerModel.leftStringAtIndex,
                    leftScrollCtrl,
                    widget.pickerModel.layoutProportions()[0], (index) {
                    widget.pickerModel.setLeftIndex(index);
                  }, (index) {
                    setState(() {
                      refreshScrollOffset();
                      _notifyDateChanged();
                    });
                  })
                : null,
          ),
          Container(
            margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
            // width: 25,
            //  color: Colors.green,
            child: Text(
              widget.pickerModel.leftDivider(),
              style: theme.itemStyle,
            ),
          ),
          Container(
            //  width: 25,
            child: widget.pickerModel.layoutProportions()[1] > 0
                ? _renderColumnView(
                    ValueKey(widget.pickerModel.currentLeftIndex()),
                    theme,
                    widget.pickerModel.middleStringAtIndex,
                    middleScrollCtrl,
                    widget.pickerModel.layoutProportions()[1], (index) {
                    widget.pickerModel.setMiddleIndex(index);
                  }, (index) {
                    setState(() {
                      refreshScrollOffset();
                      _notifyDateChanged();
                    });
                  })
                : null,
          ),
          Container(
            // width: 25,
            margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
            child: Text(
              widget.pickerModel.rightDivider(),
              style: theme.itemStyle,
            ),
          ),
          Container(
            //  width: 25,
            child: widget.pickerModel.layoutProportions()[2] > 0
                ? _renderColumnView(
                    ValueKey(widget.pickerModel.currentMiddleIndex() * 100 +
                        widget.pickerModel.currentLeftIndex()),
                    theme,
                    widget.pickerModel.rightStringAtIndex,
                    rightScrollCtrl,
                    widget.pickerModel.layoutProportions()[2], (index) {
                    widget.pickerModel.setRightIndex(index);
                  }, (index) {
                    setState(() {
                      refreshScrollOffset();
                      _notifyDateChanged();
                    });
                  })
                : null,
          ),
        ],
      ),
    );
  }

  // Title View
  Widget _renderTitleActionsView(DatePickerTheme theme) {
    final done = _localeDone();
    final cancel = _localeCancel();

    return Container(
      //height: theme.titleHeight,
      decoration: BoxDecoration(
        color: theme.headerColor ?? theme.backgroundColor,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          /*  Container(
            height: theme.titleHeight,
            child: CupertinoButton(
              pressedOpacity: 0.3,
              padding: EdgeInsets.only(left: 16, top: 0),
              child: Text(
                '$cancel',
                style: theme.cancelStyle,
              ),
              onPressed: () {
                Navigator.pop(context);
                if (widget.route.onCancel != null) {
                  widget.route.onCancel();
                }
              },
            ),
          ),*/

          Expanded(
            flex: 1,
            child: Container(
              height: 50,
              child: MaterialButton(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    side: BorderSide(color: Colors.grey)),
                color: Colors.white,
                //Theme.of(context).primaryColor,
                textColor: Colors.white,
                child: new Text(
                  '$cancel',
                ),
                onPressed: () {
                  Navigator.pop(context);
                  if (widget.route.onCancel != null) {
                    widget.route.onCancel();
                  }
                },
                //splashColor: Constant.blue,
              ),
            ),
          ),
          SizedBox(width: 20),
          /* Container(
            height: theme.titleHeight,
            child: CupertinoButton(
              pressedOpacity: 0.3,
              padding: EdgeInsets.only(right: 16, top: 0),
              child: Text(
                '$done',
                style: theme.doneStyle,
              ),
              onPressed: () {
                Navigator.pop(context, widget.pickerModel.finalTime());
                if (widget.route.onConfirm != null) {
                  widget.route.onConfirm(widget.pickerModel.finalTime());
                }
              },
            ),
          )*/
          Expanded(
            flex: 1,
            child: Container(
              height: 50,
              child: MaterialButton(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    side: BorderSide(color: Colors.blue)),

                color: Colors.blue,
                //Theme.of(context).primaryColor,
                textColor: Colors.white,
                child: new Text(
                  '$done',
                ),
                onPressed: () {
                  Navigator.pop(context, widget.pickerModel.finalTime());
                  if (widget.route.onConfirm != null) {
                    widget.route.onConfirm(widget.pickerModel.finalTime());
                  }
                },
                //splashColor: Constant.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _localeDone() {
    return i18nObjInLocale(widget.locale)['done'] as String;
  }

  String _localeCancel() {
    return i18nObjInLocale(widget.locale)['cancel'] as String;
  }
}

class _BottomPickerLayout extends SingleChildLayoutDelegate {
  _BottomPickerLayout(
    this.progress,
    this.theme, {
    this.itemCount,
    this.showTitleActions,
    this.bottomPadding = 0,
  });

  final double progress;
  final int itemCount;
  final bool showTitleActions;
  final DatePickerTheme theme;
  final double bottomPadding;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    double maxHeight = theme.containerHeight;
    if (showTitleActions == true) {
      maxHeight += theme.titleHeight;
    }
    return BoxConstraints(
      minWidth: constraints.maxWidth,
      maxWidth: constraints.maxWidth,
      minHeight: 0.0,
      maxHeight: maxHeight + bottomPadding,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final height = size.height - childSize.height * progress;
    return Offset(0.0, height);
  }

  @override
  bool shouldRelayout(_BottomPickerLayout oldDelegate) {
    return progress != oldDelegate.progress;
  }
}
