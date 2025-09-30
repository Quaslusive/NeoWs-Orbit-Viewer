import 'dart:math' as math;
import 'package:flutter/material.dart';

class Camera3D {
  Camera3D({
    required this.fovYDeg,
    required this.aspect,
    this.near = 0.01,
    this.far = 1000.0,
    this.position = const Offset3(0, 0, 6), // z-forward
    this.target = const Offset3(0, 0, 0),
    this.up = const Offset3(0, 1, 0),
  });

  double fovYDeg;
  double aspect;
  double near, far;
  Offset3 position, target, up;

  // Simple lookAt matrix → returns 4x4 column-major
  List<double> get viewMatrix {
    final f = (target - position).normalized();
    final s = f.cross(up).normalized();
    final u = s.cross(f);

    // Column-major 4x4
    return <double>[
      s.x, u.x, -f.x, 0,
      s.y, u.y, -f.y, 0,
      s.z, u.z, -f.z, 0,
      -s.dot(position), -u.dot(position), f.dot(position), 1,
    ];
  }

  List<double> get projMatrix {
    final fov = fovYDeg * math.pi / 180.0;
    final f = 1.0 / math.tan(fov / 2.0);
    final nf = 1 / (near - far);
    return <double>[
      f / aspect, 0, 0, 0,
      0, f, 0, 0,
      0, 0, (far + near) * nf, -1,
      0, 0, (2 * far * near) * nf, 0,
    ];
  }
}

class Offset3 {
  final double x,y,z;
  const Offset3(this.x, this.y, this.z);
  Offset3 operator +(Offset3 o)=> Offset3(x+o.x,y+o.y,z+o.z);
  Offset3 operator -(Offset3 o)=> Offset3(x-o.x,y-o.y,z-o.z);
  Offset3 operator *(double k)=> Offset3(x*k,y*k,z*k);
  double dot(Offset3 o)=> x*o.x + y*o.y + z*o.z;
  Offset3 cross(Offset3 o)=> Offset3(y*o.z - z*o.y, z*o.x - x*o.z, x*o.y - y*o.x);
  double get len => math.sqrt(x*x+y*y+z*z);
  Offset3 normalized()=> len==0? this : this*(1/len);
}

Offset? projectVec(Offset3 v, Camera3D cam, Size size) {
  // Multiply by View then Projection (column-major)
  Offset3 mulMat(List<double> m, Offset3 p, {double w = 1}) {
    return Offset3(
      m[0]*p.x + m[4]*p.y + m[8]*p.z + m[12]*w,
      m[1]*p.x + m[5]*p.y + m[9]*p.z + m[13]*w,
      m[2]*p.x + m[6]*p.y + m[10]*p.z + m[14]*w,
    );
  }
  final vCam = mulMat(cam.viewMatrix, v);
  final vClip = mulMat(cam.projMatrix, vCam, w:1);
  final w = (cam.projMatrix[3]*vCam.x + cam.projMatrix[7]*vCam.y + cam.projMatrix[11]*vCam.z + cam.projMatrix[15]*1);
  final W = w == 0 ? 1e-9 : w;
  final ndc = Offset(vClip.x / W, vClip.y / W); // -1..1
  if (W < 0) return null; // behind camera
  // map to screen
  final x = (ndc.dx * 0.5 + 0.5) * size.width;
  final y = (1 - (ndc.dy * 0.5 + 0.5)) * size.height;
  return Offset(x, y);
}
