import 'dart:math';
import 'package:flutter/material.dart';

enum BarColorPickerStyle {
  ColorScaleHorizontal,
  ColorScaleVertical,
  GreyScaleHorizontal,
  GreyScaleVertical,
}

class BarColorPicker extends StatefulWidget {
  final BarColorPickerStyle style;
  final double width;
  final double length;
  final Color initialColor;
  final ValueChanged onColorChange;

  BarColorPicker({
    Key key,
    this.style = BarColorPickerStyle.ColorScaleHorizontal,
    this.width = 16.0,
    this.length = 200.0,
    this.initialColor = const Color(0xffff0000),
    @required this.onColorChange,
  })  : assert(style != null),
        assert(width != null),
        assert(length != null),
        assert(initialColor != null),
        assert(onColorChange != null),
        super(key: key);

  @override
  _BarColorPickerState createState() => _BarColorPickerState();
}

class _BarColorPickerState extends State<BarColorPicker> {
  List<Color> colors;
  double percentOffset;
  bool isHorizontal, isColor;

  get currentColor {
    if (isColor) {
      return HSVColor.fromAHSV(1.0, percentOffset * 360, 1.0, 1.0).toColor();
    } else {
      int channel = (0xff * percentOffset).toInt();
      return Color.fromARGB(0xff, channel, channel, channel);
    }
  }

  @override
  void initState() {
    super.initState();

    switch (widget.style) {
      case BarColorPickerStyle.ColorScaleHorizontal:
        isHorizontal = true;
        isColor = true;
        break;

      case BarColorPickerStyle.ColorScaleVertical:
        isHorizontal = false;
        isColor = true;
        break;

      case BarColorPickerStyle.GreyScaleHorizontal:
        isHorizontal = true;
        isColor = false;
        break;

      case BarColorPickerStyle.GreyScaleVertical:
        isHorizontal = false;
        isColor = false;
        break;
    }

    if (isColor) {
      colors = const [
        Color(0xffff0000),
        Color(0xffffff00),
        Color(0xff00ff00),
        Color(0xff00ffff),
        Color(0xff0000ff),
        Color(0xffff00ff),
        Color(0xffff0000)
      ];
    } else {
      colors = const [Color(0xff000000), Color(0xffffffff)];
    }

    percentOffset = HSVColor.fromColor(widget.initialColor).hue / 360.0;
  }

  void handleTouchEnded() {
    if (isColor) {
      Color color =
          HSVColor.fromAHSV(1.0, percentOffset * 360, 1.0, 1.0).toColor();
      widget.onColorChange(color);
    } else {
      final int channel = (0xff * percentOffset).toInt();
      Color color = Color.fromARGB(0xff, channel, channel, channel);
      widget.onColorChange(color);
    }
  }

  void handleTouch(Offset globalPosition, BuildContext context) {
    RenderBox box = context.findRenderObject();
    double localPosition = isHorizontal
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
    // size helpers
    double barLength = widget.length;
    double barWidth = widget.width;
    double cursorRadius = widget.width;
    double cursorDiameter = widget.width * 2.0;

    // container
    Widget container = SizedBox(
      width: isHorizontal ? barLength + cursorDiameter : cursorDiameter,
      height: isHorizontal ? cursorDiameter : barLength + cursorDiameter,
    );

    // gradientBar
    Gradient gradient = isHorizontal
        ? LinearGradient(colors: colors)
        : LinearGradient(
            colors: colors,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );
    double left = isHorizontal ? cursorRadius : (cursorDiameter - barWidth) / 2;
    double top = isHorizontal ? (cursorDiameter - barWidth) / 2 : cursorRadius;

    Widget gradientBar = Positioned(
      left: left,
      top: top,
      child: Container(
        width: isHorizontal ? barLength : barWidth,
        height: isHorizontal ? barWidth : barLength,
        decoration: BoxDecoration(
          borderRadius: isHorizontal
              ? BorderRadius.all(Radius.circular(barWidth / 2.0))
              : BorderRadius.all(Radius.circular(barLength / 2.0)),
          gradient: gradient,
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

    var handleHorizontalTouch = isHorizontal
        ? (details) => handleTouch(details.globalPosition, context)
        : null;
    var handleVerticalTouch = isHorizontal
        ? null
        : (details) => handleTouch(details.globalPosition, context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragDown: handleVerticalTouch,
      onVerticalDragStart: handleVerticalTouch,
      onVerticalDragUpdate: handleVerticalTouch,
      onVerticalDragCancel: isHorizontal ? null : () => handleTouchEnded(),
      onVerticalDragEnd: isHorizontal ? null : (_) => handleTouchEnded(),
      onHorizontalDragDown: handleHorizontalTouch,
      onHorizontalDragStart: handleHorizontalTouch,
      onHorizontalDragUpdate: handleHorizontalTouch,
      onHorizontalDragCancel: isHorizontal ? () => handleTouchEnded() : null,
      onHorizontalDragEnd: isHorizontal ? (_) => handleTouchEnded() : null,
      child: Stack(children: [container, gradientBar, cursor]),
    );
  }
}
