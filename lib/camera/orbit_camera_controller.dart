import 'dart:math' as math;
import 'dart:ui'; // for Offset
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:neows_app/camera/camera_pose.dart' as cam;


class OrbitCameraController extends ChangeNotifier {
  OrbitCameraController({
    required cam.CameraPose initial,
    this.minDist = 2.0,
    this.maxDist = 50.0,
    this.rotateSensitivity = 0.008,
    this.zoomSensitivity = 0.05,
    this.panWorldScale = 1.0,
    this.invertY = false,
  }) : _pose = initial {
    _ticker = Ticker(_tick)..start();
  }

  late final Ticker _ticker;
  Duration _last = Duration.zero;

  cam.CameraPose _pose;
  cam.CameraPose get pose => _pose;

  // Tunables (mutable so the page/canvas can adjust them)
  double minDist, maxDist;
  double rotateSensitivity, zoomSensitivity;
  double panWorldScale;
  bool invertY;

  // Inertia state
  double _vyaw = 0, _vpitch = 0, _vdist = 0;
  cam.Offset3 _vpan = const cam.Offset3(0, 0, 0);

  // Follow / easing
  cam.Offset3 _targetDesired = const cam.Offset3(0, 0, 0);
  bool _follow = false;
  final double _followEase = 0.12;

  // Friction (per second)
  final double _rotFriction = 6.0;
  final double _zoomFriction = 6.0;
  final double _panFriction  = 6.0;

  void setPanWorldScale(double v) { panWorldScale = v; }

  void updateFollowTarget(cam.Offset3 t) {
    _targetDesired = t;
  }

  void orbitBy(Offset deltaPx) {
    final dy = invertY ? deltaPx.dy : -deltaPx.dy;
    _vyaw   += deltaPx.dx * rotateSensitivity;
    _vpitch += dy        * rotateSensitivity;
  }

  void panBy(Offset deltaPx, {double viewportHeightPx = 800}) {
    final s  = _pose.dist * (panWorldScale / viewportHeightPx);
    final dx = -deltaPx.dx * s;
    final dy =  deltaPx.dy * s;
    _vpan = cam.Offset3(_vpan.x + dx, _vpan.y + dy, _vpan.z);
  }

  void dollyBy(double pinchDelta) {
    final k = math.max(0.6, _pose.dist * 0.12);
    _vdist += -pinchDelta * zoomSensitivity * k;
   // _vdist += -pinchDelta * zoomSensitivity * math.max(0.6, _pose.dist * 0.15);
  }

  void setFollow(bool on) { _follow = on; }
  bool get isFollowing => _follow;

  void focusOn(
      cam.Offset3 worldTarget, {
        double? distance,
        double yaw = double.nan,
        double pitch = double.nan,
        bool snap = false,
      }) {
    _targetDesired = worldTarget;
    if (distance != null) {
      final d = distance.clamp(minDist, maxDist);
      _pose = _pose.copyWith(dist: d.toDouble());
    }
    if (!yaw.isNaN)   _pose = _pose.copyWith(yaw: yaw);
    if (!pitch.isNaN) _pose = _pose.copyWith(pitch: pitch);

    if (snap) {
      _pose = _pose.copyWith(target: worldTarget);
      _vpan = const cam.Offset3(0, 0, 0);
    }
    notifyListeners();
  }


/*  void focusOn(
      cam.Offset3 worldTarget, {
        double? distance,
        double yaw = double.nan,
        double pitch = double.nan,
      }) {
    _targetDesired = worldTarget;
    _pose = _pose.copyWith(dist: distance ?? _pose.dist);
    if (!yaw.isNaN)   _pose = _pose.copyWith(yaw: yaw);
    if (!pitch.isNaN) _pose = _pose.copyWith(pitch: pitch);
    notifyListeners();
  }*/

  void animateTo(cam.CameraPose target) {
    _pose = target;
    notifyListeners();
  }

  void home({
    cam.Offset3 target = const cam.Offset3(0, 0, 0),
    double dist = 6.0,
    double yaw = 0.0,
    double pitch = 0.0,
  }) {
    _pose = cam.CameraPose(yaw: yaw, pitch: pitch, dist: dist, target: target);
    _vyaw = _vpitch = _vdist = 0;
    _vpan = const cam.Offset3(0, 0, 0);
    notifyListeners();
  }

  // knob setters called from didUpdateWidget in the canvas
  void setRotateSensitivity(double v) { rotateSensitivity = v; }
  void setZoomSensitivity(double v)   { zoomSensitivity = v; }
  void setInvertY(bool v)             { invertY = v; }
  void setDistanceClamp(double min, double max) {
    minDist = min;
    maxDist = max;
    _pose = _pose.copyWith(dist: _pose.dist.clamp(minDist, maxDist));
    notifyListeners();
  }


  void _tick(Duration t) {
    final dt = ((t - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = t;
    if (dt == 0) return;

    // Follow target easing
    final tgt = _follow ? _targetDesired : _pose.target;
    final easedTarget = cam.Offset3(
      _pose.target.x + (tgt.x - _pose.target.x) * _followEase,
      _pose.target.y + (tgt.y - _pose.target.y) * _followEase,
      _pose.target.z + (tgt.z - _pose.target.z) * _followEase,
    );

    // Integrate velocities
    var yaw   = _pose.yaw   + _vyaw   * dt;
    var pitch = _pose.pitch + _vpitch * dt;
    var dist  = _pose.dist  + _vdist  * dt;

    // Clamp pitch (-85..+85 deg)
    const maxPitch = 83 * math.pi / 180;
    pitch = pitch.clamp(-maxPitch, maxPitch);

    // Clamp distance
    dist = dist.clamp(minDist, maxDist);

    // Apply pan
    final pan = _vpan.scale(dt);
    final target = cam.Offset3(
      easedTarget.x + pan.x,
      easedTarget.y + pan.y,
      easedTarget.z + pan.z,
    );

    // Friction
    double decay(double v, double k) => v * math.exp(-k * dt);
    _vyaw   = decay(_vyaw,   _rotFriction);
    _vpitch = decay(_vpitch, _rotFriction);
    _vdist  = decay(_vdist,  _zoomFriction);
    _vpan   = _vpan.scale(math.exp(-_panFriction * dt));

    final next = cam.CameraPose(yaw: yaw, pitch: pitch, dist: dist, target: target);
    if (next.yaw != _pose.yaw ||
        next.pitch != _pose.pitch ||
        next.dist != _pose.dist ||
        next.target.x != _pose.target.x ||
        next.target.y != _pose.target.y ||
        next.target.z != _pose.target.z) {
      _pose = next;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}
