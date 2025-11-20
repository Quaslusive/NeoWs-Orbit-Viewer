
class Offset3 {
  final double x, y, z;
  const Offset3(this.x, this.y, this.z);
  Offset3 operator +(Offset3 o) => Offset3(x+o.x, y+o.y, z+o.z);
  Offset3 operator -(Offset3 o) => Offset3(x-o.x, y-o.y, z-o.z);
  Offset3 scale(double s) => Offset3(x*s, y*s, z*s);
}

class CameraPose {
  final double yaw;
  final double pitch;
  final double dist;
  final Offset3 target;
  const CameraPose({required this.yaw, required this.pitch, required this.dist, required this.target});

  CameraPose copyWith({double? yaw, double? pitch, double? dist, Offset3? target}) =>
      CameraPose(yaw: yaw ?? this.yaw, pitch: pitch ?? this.pitch, dist: dist ?? this.dist, target: target ?? this.target);
}
