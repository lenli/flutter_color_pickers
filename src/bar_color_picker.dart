import 'dart:math';
import 'package:flutter/material.dart';

// default sizes
const double _kDefaultWidth = 16.0;
const double _kDefaultLength = 200.0;

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

// default values for grayscale
const Color _kDefaultGrayScaleColor = Color(0xff000000);
const List<Color> _kDefaultGrayScaleColors = [
  Color(0xff000000),
  Color(0xffffffff)
];

class BarColorPicker extends StatefulWidget {
  // horizontal bar vs vertical bar
  final bool isHorizontal;

  // color bar vs grayscale bar
  final bool isColor;

  // set initial starting color
  final Color initialColor;

  // ranges of colors to display in bar
  final List<Color> colors;

  // height for a horizontal bar, width for a vertical bar
  final double width;

  // width for a horizontal bar, height for a vertical bar
  final double length;

  // callback when drag ends, returns ending color
  final ValueChanged onColorChange;

  // constructor for grayscale bar color picker
  BarColorPicker.grayScale({
    Key key,
    bool isHorizontal,
    Color initialColor,
    List<Color> colors,
    double width,
    double length,
    ValueChanged onColorChange,
  }) : this(
    key: key,
    isHorizontal: isHorizontal ?? true,
    isColor: false,
    initialColor: initialColor ?? _kDefaultGrayScaleColor,
    colors: colors ?? _kDefaultGrayScaleColors,
    width: width ?? _kDefaultWidth,
    length: length ?? _kDefaultLength,
    onColorChange: onColorChange,
  );

  // default constructor is for color
  BarColorPicker({
    Key key,
    this.isHorizontal = true,
    this.isColor = true,
    this.initialColor = _kDefaultColor,
    this.colors = _kDefaultColors,
    this.width = _kDefaultWidth,
    this.length = _kDefaultLength,
    @required this.onColorChange,
  })  : assert(isHorizontal != null),
        assert(isColor != null),
        assert(initialColor != null),
        assert(colors != null),
        assert(width != null),
        assert(length != null),
        assert(onColorChange != null),
        super(key: key);

  @override
  _BarColorPickerState createState() => _BarColorPickerState();
}

class _BarColorPickerState extends State<BarColorPicker> {
  // represents the current offset, which can be converted to the current color
  double percentOffset;

  // convert percent offset to a color based on color vs grayscale
  get currentColor {
    if (widget.isColor) {
      return HSVColor.fromAHSV(1.0, percentOffset * 360, 1.0, 1.0).toColor();
    } else {
      int channel = (0xff * percentOffset).toInt();
      return Color.fromARGB(0xff, channel, channel, channel);
    }
  }

  @override
  void initState() {
    super.initState();
    // set percent offset for initial color provided
    percentOffset = HSVColor.fromColor(widget.initialColor).hue / 360.0;
  }

  // when drag ends, send notification of color change
  void handleDragEnded() {
    widget.onColorChange(currentColor);
  }

  // handle horizontal drag events
  void handleHorizontalDrag(Offset globalPosition, BuildContext context) {
    if (!widget.isHorizontal) {
      return;
    }
    // only update offset if horizontal
    handleDrag(globalPosition, context);
  }

  // handle vertical drag events
  void handleVerticalDrag(Offset globalPosition, BuildContext context) {
    if (widget.isHorizontal) {
      return;
    }
    // only update offset if not horizontal
    handleDrag(globalPosition, context);
  }

  // handle generic drag events
  void handleDrag(Offset globalPosition, BuildContext context) {
    // update percent offset of a drag gesture event converting global coordinates to local
    RenderBox box = context.findRenderObject();
    double localPosition = widget.isHorizontal
        ? box.globalToLocal(globalPosition).dx
        : box.globalToLocal(globalPosition).dy;
    double rawTouchOffset = (localPosition - widget.width) / widget.length;
    double touchOffset = min(max(0.0, rawTouchOffset), 1.0);
    setState(() {
      if (this.percentOffset != touchOffset) {
        this.percentOffset = touchOffset;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // helpers to make code more readable
    double barLength = widget.length;
    double barWidth = widget.width;
    double cursorRadius = widget.width;
    double cursorDiameter = widget.width * 2.0;
    bool isHorizontal = widget.isHorizontal;

    // container
    Widget container = SizedBox(
      width: isHorizontal ? barLength + cursorDiameter : cursorDiameter,
      height: isHorizontal ? cursorDiameter : barLength + cursorDiameter,
    );

    // gradient
    Widget gradientBar = Positioned(
      left: isHorizontal ? cursorRadius : cursorRadius / 2.0,
      top: isHorizontal ? cursorRadius / 2.0 : cursorRadius,
      child: Container(
        width: isHorizontal ? barLength : barWidth,
        height: isHorizontal ? barWidth : barLength,
        decoration: BoxDecoration(
          borderRadius: isHorizontal
              ? BorderRadius.all(Radius.circular(barWidth / 2.0))
              : BorderRadius.all(Radius.circular(barLength / 2.0)),
          gradient: isHorizontal
              ? LinearGradient(colors: widget.colors)
              : LinearGradient(
            colors: widget.colors,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
    );

    // cursor
    Widget cursor = Positioned(
      left: isHorizontal ? barLength * percentOffset : null,
      top: isHorizontal ? null : barLength * percentOffset,
      child: Container(
        width: cursorDiameter,
        height: cursorDiameter,
        decoration: BoxDecoration(
          color: currentColor,
          shape: BoxShape.circle,
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
        ),
      ),
    );

    // handle gestures
    var handleHorizontalTouch =
        (details) => handleHorizontalDrag(details.globalPosition, context);
    var handleVerticalTouch =
        (details) => handleVerticalDrag(details.globalPosition, context);
    var handleCancelTouch = isHorizontal ? () => handleDragEnded() : null;
    var handleEndTouch = isHorizontal ? (_) => handleDragEnded() : null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragDown: handleVerticalTouch,
      onVerticalDragStart: handleVerticalTouch,
      onVerticalDragUpdate: handleVerticalTouch,
      onVerticalDragCancel: handleCancelTouch,
      onVerticalDragEnd: handleEndTouch,
      onHorizontalDragDown: handleHorizontalTouch,
      onHorizontalDragStart: handleHorizontalTouch,
      onHorizontalDragUpdate: handleHorizontalTouch,
      onHorizontalDragCancel: handleCancelTouch,
      onHorizontalDragEnd: handleEndTouch,
      child: Stack(children: [container, gradientBar, cursor]),
    );
  }
}
