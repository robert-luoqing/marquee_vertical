import 'dart:async';

import 'package:flutter/material.dart';

typedef MarqueeVerticalOnPress = void Function(int index);

class MarqueeVertical extends StatefulWidget {
  final List<String> textList;
  final TextStyle textStyle;
  final Duration scrollDuration;
  final Duration stopDuration;
  final int maxLine;
  final double lineSpace;
  final MarqueeVerticalOnPress onPress;

  const MarqueeVertical(
      {Key? key,
      this.textList = const [],
      this.textStyle = const TextStyle(fontSize: 14, color: Colors.black),
      this.scrollDuration = const Duration(seconds: 1),
      this.stopDuration = const Duration(seconds: 3),
      this.maxLine = 1,
      required this.onPress,
      this.lineSpace = 0})
      : super(key: key);

  @override
  _MarqueeVerticalState createState() => _MarqueeVerticalState();
}

class _MarqueeVerticalState extends State<MarqueeVertical>
    with SingleTickerProviderStateMixin {
  List<String> get textList => widget.textList;
  Timer? stopTimer;
  late AnimationController animationConroller;
  late List<Widget> textWidgets = [];
  late List<double> textHeights = [];
  late List<int> showItems = [];
  double currentAnimationHeight = 0;
  double defaultHeight = 0;

  _resetDataFromWidget() {
    textWidgets = [];
    textHeights = [];
    showItems = [];
    for (var index = 0; index < textList.length; index++) {
      var text = textList[index];
      textWidgets.add(_renderText(index));
      textHeights
          .add(getTextSize(text, widget.textStyle, double.maxFinite).height);
    }

    for (var i = 0; i < widget.maxLine; i++) {
      if (textList.length > i) {
        showItems.add(i);
        // if (i == 0) {
        //   defaultHeight += textHeights[i];
        // } else {
        //   defaultHeight += textHeights[i] + this.widget.lineSpace;
        // }
      }
    }

    var textHeight = textHeights.isNotEmpty ? textHeights[0] : 15.0;
    defaultHeight =
        textHeight * widget.maxLine + (widget.maxLine - 1.0) * widget.lineSpace;

    if (textList.length > widget.maxLine) {
      if (stopTimer != null) {
        stopTimer!.cancel();
        stopTimer = null;
      }
      stopTimer =
          Timer.periodic(widget.stopDuration + widget.scrollDuration, (timer) {
        next();
      });
    } else {
      if (stopTimer != null) {
        stopTimer!.cancel();
        stopTimer = null;
      }
    }
  }

  _initAnimation() {
    animationConroller = AnimationController(vsync: this);
  }

  @override
  void didUpdateWidget(covariant MarqueeVertical oldWidget) {
    _resetDataFromWidget();
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    _resetDataFromWidget();
    _initAnimation();
    super.initState();
  }

  void next() async {
    setState(() {
      // 1. Add more to bottom
      currentAnimationHeight = textHeights[showItems[0]] + widget.lineSpace;
      var lastIndex = showItems[showItems.length - 1];
      if (textWidgets.length > (lastIndex + 1)) {
        showItems.add(lastIndex + 1);
      } else {
        showItems.add(0);
      }
    });
    await animationConroller.animateTo(1.0, duration: widget.scrollDuration);
    setState(() {
      animationConroller.value = 0.0;
      // 1. Remove first item
      showItems.removeAt(0);
    });
  }

  Widget _renderText(index) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        widget.onPress(index);
      },
      child: Text(
        textList[index],
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.left,
        style: widget.textStyle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (textList.length <= widget.maxLine) {
      var textChildren = textList.map((item) => _renderText(0)).toList();
      return Align(
        alignment: Alignment.centerLeft,
        child: Column(
          children: textChildren,
        ),
      );
    }

    var stackChildren = <Widget>[];

    var accumlateX = 0.0;
    for (var item in showItems) {
      stackChildren.add(
        Positioned(
            top: accumlateX,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
                animation: animationConroller,
                builder: (context, child) {
                  return Transform.translate(
                      offset: Offset(0,
                          -currentAnimationHeight * animationConroller.value),
                      child: textWidgets[item]);
                })),
      );

      accumlateX += textHeights[item] + widget.lineSpace;
    }

    return SizedBox(
        height: defaultHeight,
        child: ClipRect(
          child: Stack(
            children: stackChildren,
          ),
        ));
  }

  @override
  void dispose() {
    animationConroller.dispose();
    if (stopTimer != null) {
      stopTimer!.cancel();
    }

    super.dispose();
  }
}

Size getTextSize(String text, TextStyle style, double maxWidth) {
  var textPainter = TextPainter(
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.left,
  );
  textPainter.text = TextSpan(
    text: text,
    style: style,
  );
  textPainter.textAlign = TextAlign.left;
  textPainter.maxLines = 1;
  // textPainter.ellipsis = "...";

  textPainter.layout(maxWidth: maxWidth);
  var width = textPainter.width;
  var height = textPainter.height;
  return Size(width, height);
}
