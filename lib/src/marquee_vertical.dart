import 'dart:async';

import 'package:flutter/material.dart';

typedef MarqueeVerticalOnPress = void Function(int index);
typedef MarqueeVerticalItemBuilder = Widget Function(int index);
enum MarqueeVerticalDirection { moveUp, moveDown }

class MarqueeVertical extends StatefulWidget {
  final int itemCount;
  final MarqueeVerticalItemBuilder itemBuilder;
  final double lineHeight;
  final Duration scrollDuration;
  final Duration stopDuration;
  final int marqueeLine;
  final MarqueeVerticalOnPress? onPress;
  final MarqueeVerticalDirection direction;

  const MarqueeVertical(
      {Key? key,
      required this.itemCount,
      required this.itemBuilder,
      required this.lineHeight,
      this.scrollDuration = const Duration(seconds: 1),
      this.stopDuration = const Duration(seconds: 3),
      this.direction = MarqueeVerticalDirection.moveUp,
      this.marqueeLine = 1,
      this.onPress})
      : super(key: key);

  @override
  _MarqueeVerticalState createState() => _MarqueeVerticalState();
}

class _MarqueeVerticalState extends State<MarqueeVertical>
    with SingleTickerProviderStateMixin {
  Timer? _stopTimer;
  late AnimationController _animationConroller;
  late Widget _containerWidget;

  /// [_showWidgets] the items host in [_containerWidget]
  late List<Widget> _showWidgets;

  /// [_topVisibleItemIndex] is mean the index of the second item
  int _topVisibleItemIndex = 0;

  _cancelStopTimer() {
    if (_stopTimer != null) {
      _stopTimer!.cancel();
      _stopTimer = null;
    }
  }

  _initAnimation() {
    _animationConroller = AnimationController(vsync: this);
    _stopTimer =
        Timer.periodic(widget.stopDuration + widget.scrollDuration, (timer) {
      next();
    });
  }

  @override
  void didUpdateWidget(covariant MarqueeVertical oldWidget) {
    if (widget.itemCount != oldWidget.itemCount ||
        widget.lineHeight != oldWidget.lineHeight ||
        widget.marqueeLine != oldWidget.marqueeLine) {
      _topVisibleItemIndex = 0;
      _reconstructWidget();
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    _initAnimation();
    _reconstructWidget();
    super.initState();
  }

  _reconstructWidget() {
    if (widget.itemCount > widget.marqueeLine) {
      _showWidgets = _buildRenderItems();
      _containerWidget = _buildContainer();
    } else {
      _showWidgets = [];
      _containerWidget = Container();
    }
  }

  void next() async {
    if (widget.itemCount > widget.marqueeLine) {
      await _animationConroller.animateTo(1.0, duration: widget.scrollDuration);
      if (widget.direction == MarqueeVerticalDirection.moveUp) {
        _topVisibleItemIndex++;
      } else {
        _topVisibleItemIndex--;
      }

      if (_topVisibleItemIndex >= widget.itemCount) {
        _topVisibleItemIndex = 0;
      } else if (_topVisibleItemIndex < 0) {
        _topVisibleItemIndex = widget.itemCount - 1;
      }
      _showWidgets = _buildRenderItems();
      _animationConroller.value = 0.0;
    }
  }

  List<Widget> _buildRenderItems() {
    var items = <Widget>[];
    for (var i = 0; i < widget.marqueeLine + 2; i++) {
      var currentItemIndex = (_topVisibleItemIndex - 1) + i;

      if (currentItemIndex < 0) {
        currentItemIndex = widget.itemCount + currentItemIndex;
      } else {
        while (currentItemIndex >= widget.itemCount) {
          currentItemIndex = currentItemIndex - widget.itemCount;
        }
      }
      items.add(GestureDetector(
          onTap: () {
            if (widget.onPress != null) {
              widget.onPress!(currentItemIndex);
            }
          },
          behavior: HitTestBehavior.opaque,
          child: widget.itemBuilder(currentItemIndex)));
    }
    return items;
  }

  Widget _buildContainer() {
    /// If [marqueeLine] is 2, we need construct 2+2 item, the top item and bottom item
    /// which hide on top and bottom
    var stackChildren = <Widget>[];
    for (var i = 0; i < widget.marqueeLine + 2; i++) {
      stackChildren.add(
        Positioned(
            top: (i - 1) * widget.lineHeight,
            left: 0,
            right: 0,
            height: widget.lineHeight,
            child: AnimatedBuilder(
                animation: _animationConroller,
                builder: (context, child) {
                  return Transform.translate(
                      offset: Offset(
                          0,
                          (widget.direction == MarqueeVerticalDirection.moveUp
                                  ? -widget.lineHeight
                                  : widget.lineHeight) *
                              _animationConroller.value),
                      child: _showWidgets[i]);
                })),
      );
    }

    return Stack(
      children: stackChildren,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.itemCount <= widget.marqueeLine) {
      var children = <Widget>[];
      for (var i = 0; i < widget.itemCount; i++) {
        var item = Positioned(
            left: 0,
            right: 0,
            top: 0 + i * widget.lineHeight,
            height: widget.lineHeight,
            child: widget.itemBuilder(i));
        children.add(item);
      }

      return SizedBox(
        height: widget.marqueeLine * widget.lineHeight,
        child: Stack(
          children: children,
        ),
      );
    } else {
      return SizedBox(
          height: widget.marqueeLine * widget.lineHeight,
          child: _containerWidget);
    }
  }

  @override
  void dispose() {
    _cancelStopTimer();
    _animationConroller.dispose();
    super.dispose();
  }
}
