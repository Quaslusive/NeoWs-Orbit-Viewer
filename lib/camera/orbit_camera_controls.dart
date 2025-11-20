import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neows_app/camera/orbit_camera_controller.dart';
import 'package:neows_app/camera/camera_pose.dart' as cam;

class OrbitCameraControls extends StatefulWidget {
  const OrbitCameraControls({
    super.key,
    required this.controller,
    required this.child,
    this.onTapSelect,
    this.onDoubleTapToFocus,
    this.viewportHeightPx = 800,
    this.enableKeyboard = true,
  });

  final OrbitCameraController controller;
  final Widget child;
  final Future<void> Function(Offset localPx)? onTapSelect;
  final Future<cam.Offset3?> Function(Offset localPx)? onDoubleTapToFocus;
  final double viewportHeightPx;
  final bool enableKeyboard;

  @override
  State<OrbitCameraControls> createState() => _OrbitCameraControlsState();
}

class _OrbitCameraControlsState extends State<OrbitCameraControls> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget layer = GestureDetector(
      behavior: HitTestBehavior.opaque,

      onTapDown: (_) {
        if (!_focusNode.hasFocus) _focusNode.requestFocus();
      },

    /*  onTapUp: (details) async {
        if (widget.onTapSelect != null) {
          await widget.onTapSelect!(details.localPosition);
        }
        },*/

      onTapUp: (details) async {
        final cb = widget.onTapSelect;
        if (cb != null) await cb(details.localPosition);
      },

      onScaleUpdate: (details) {
        Offset d = details.focalPointDelta;
        if (d.dx.abs() < 0.1 && d.dy.abs() < 0.1) d = Offset.zero;

        if (details.pointerCount >= 2) {
          widget.controller.panBy(d, viewportHeightPx: widget.viewportHeightPx);

          // gentler pinch zoom
          final pinch = 1 - details.scale;
          if (pinch.abs() > 0.0001) {
            widget.controller.dollyBy(pinch * 30);
          }
        } else {
          widget.controller.orbitBy(d);
        }
      },

/*      onScaleUpdate: (details) {
        final n = details.pointerCount;
        if (n >= 2) {
          widget.controller.panBy(
            details.focalPointDelta,
            viewportHeightPx: widget.viewportHeightPx,
          );
          final pinch = 1 - details.scale;
          if (pinch.abs() > 0.0001) widget.controller.dollyBy(pinch * 30);
        } else {
          widget.controller.orbitBy(details.focalPointDelta);
        }
      },*/

      onDoubleTapDown: (ev) async {
        final cb = widget.onDoubleTapToFocus;
        if (cb != null) {
          final world = await cb(ev.localPosition);
          if (world != null) {
            widget.controller.focusOn(world);
            widget.controller.setFollow(true);
          }
        }
      },

 /*     onDoubleTapDown: (d) async {
        if (widget.onDoubleTapToFocus != null) {
          final world = await widget.onDoubleTapToFocus!(d.localPosition);
          if (world != null) widget.controller.focusOn(world);
        }
      },*/
  /*    onLongPress: () =>
          widget.controller.setFollow(!widget.controller.isFollowing),*/
      child: Listener(
        onPointerSignal: (sig) {
          if (sig is PointerScrollEvent) {
            widget.controller.dollyBy(sig.scrollDelta.dy.sign * 100);
          }
        },
        child: widget.child,
      ),
    );

    if (widget.enableKeyboard) {
      layer = KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (KeyEvent e) {
          if (e is! KeyDownEvent) return;
          final bool shift = HardwareKeyboard.instance.isShiftPressed;
          final mul = shift ? 4.0 : 1.0;
          const px = 50.0;
          final k = e.logicalKey;
          if (k == LogicalKeyboardKey.keyW) {
            widget.controller.panBy(const Offset(0, -px * 2),
                viewportHeightPx: widget.viewportHeightPx);
          } else if (k == LogicalKeyboardKey.keyS) {
            widget.controller.panBy(const Offset(0, px * 2),
                viewportHeightPx: widget.viewportHeightPx);
          } else if (k == LogicalKeyboardKey.keyA) {
            widget.controller.panBy(const Offset(px * 2, 0),
                viewportHeightPx: widget.viewportHeightPx);
          } else if (k == LogicalKeyboardKey.keyD) {
            widget.controller.panBy(const Offset(-px * 2, 0),
                viewportHeightPx: widget.viewportHeightPx);
          } else if (k == LogicalKeyboardKey.keyQ) {
            widget.controller.dollyBy(120 * mul);
          } else if (k == LogicalKeyboardKey.keyE) {
            widget.controller.dollyBy(-120 * mul);
          } else if (k == LogicalKeyboardKey.keyH) {
            widget.controller.home();
          }
        },
        child: layer,
      );
    }
    return layer;
  }
}
