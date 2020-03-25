import 'dart:math';
import 'package:flutter/material.dart';

// default sizes
const double _kDefaultCursorRadius = 16.0;
const double _kDefaultRadius = 100.0;

// default values for color
const Color _kDefaultColor = Color(0xffff0000);
const List<Color> _kDefaultColors = [
  Color(0xffff0000),
  Color(0xffffff00),
  Color(0xff00ff00),
  Color(0xff00ffff),
  Color(0xff0000ff),
  Color(0xffff00ff),
  Color(0xffff0000)
];

class CircularColorPicker extends StatefulWidget {
  // set initial starting color
  final Color initialColor;

  // radius of picker container
  final double radius;

  // radius of cursor
  final double cursorRadius;

  // callback when drag ends, returns ending color
  final ValueChanged onColorChange;

  CircularColorPicker({
    Key key,
    this.initialColor = _kDefaultColor,
    this.radius = _kDefaultRadius,
    this.cursorRadius = _kDefaultCursorRadius,
    @required this.onColorChange,
  })  : assert(initialColor != null),
        assert(radius != null),
        assert(cursorRadius != null),
        assert(onColorChange != null),
        super(key: key);

  @override
  _CircularColorPickerState createState() => _CircularColorPickerState();
}

class _CircularColorPickerState extends State<CircularColorPicker> {
  // position of cursor in circle, can be used to determine current color
  double cursorDistanceFromCenter;
  double cursorDegrees;

  // get current color from cursor position
  get currentColor {
    return HSVColor.fromAHSV(1.0, cursorDegrees, 1.0, 1.0).toColor();
  }

  // when drag ends, send notification of color change
  void handleDragEnded() {
    widget.onColorChange(currentColor);
  }

  // handle drag events
  void handleDrag(Offset globalPosition, BuildContext context) {
    // update position of a drag gesture event converting global coordinates to local
    RenderBox box = context.findRenderObject();
    Offset localPosition = box.globalToLocal(globalPosition);
    final double centerX = box.size.width / 2;
    final double centerY = box.size.height / 2;
    final double deltaX = localPosition.dx - centerX;
    final double deltaY = localPosition.dy - centerY;
    final double distanceToCenter = sqrt(deltaX * deltaX + deltaY * deltaY);
    double theta = atan2(deltaX, deltaY);
    double degrees = 270 - _radiansToDegrees(theta);
    if (degrees < 0.0) degrees = 360 + degrees;

    setState(() {
      cursorDistanceFromCenter = min(distanceToCenter, widget.radius);
      cursorDegrees = degrees;
    });
  }

  @override
  void initState() {
    super.initState();
    // set position of cursor based on initial color
    cursorDistanceFromCenter = widget.radius;
    cursorDegrees = HSVColor.fromColor(widget.initialColor).hue;
  }

  @override
  Widget build(BuildContext context) {
    // helpers to make code more readable
    final double radius = widget.radius;
    final double cursorRadius = widget.cursorRadius;
    final double cursorDiameter = widget.cursorRadius * 2.0;
    final double cursorRadians = _degreesToRadians(270 - cursorDegrees);
    final Offset cursorPosition = Offset(
      radius + cursorDistanceFromCenter * sin(cursorRadians),
      radius + cursorDistanceFromCenter * cos(cursorRadians),
    );

    // container
    Widget container = SizedBox(
        width: (radius + cursorRadius) * 2.0,
        height: (radius + cursorRadius) * 2.0);

    // gradient
    Widget gradient = Positioned(
      left: cursorRadius,
      top: cursorRadius,
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(radius)),
            gradient: SweepGradient(colors: _kDefaultColors)),
      ),
    );

    // cursor
    Widget cursor = Positioned(
      left: cursorPosition.dx,
      top: cursorPosition.dy,
      child: Container(
        width: cursorDiameter,
        height: cursorDiameter,
        decoration: BoxDecoration(
          border: Border.all(
            width: 3.0,
            color: Colors.white,
            style: BorderStyle.solid,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              spreadRadius: min(1.0, cursorRadius / 8.0),
              blurRadius: 3.0,
            )
          ],
          color: currentColor,
          shape: BoxShape.circle,
        ),
      ),
    );

    // handle gestures
    var handleDragTouch =
        (details) => handleDrag(details.globalPosition, context);
    var handleCancelTouch = () => handleDragEnded();
    var handleEndTouch = (_) => handleDragEnded();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragDown: handleDragTouch,
      onVerticalDragStart: handleDragTouch,
      onVerticalDragUpdate: handleDragTouch,
      onVerticalDragCancel: handleCancelTouch,
      onVerticalDragEnd: handleEndTouch,
      onHorizontalDragDown: handleDragTouch,
      onHorizontalDragStart: handleDragTouch,
      onHorizontalDragUpdate: handleDragTouch,
      onHorizontalDragCancel: handleCancelTouch,
      onHorizontalDragEnd: handleEndTouch,
      child: Stack(children: [container, gradient, cursor]),
    );
  }

  // convert an angle value from radian to degree representation.
  double _radiansToDegrees(double radians) {
    return (radians + pi) / pi * 180;
  }

  // convert an angle value from degree to radian representation.
  double _degreesToRadians(double degrees) {
    return degrees / 180 * pi - pi;
  }
}
