import 'dart:math' as math;
import 'package:flutter/material.dart';

class Camera3D {
  Camera3D({
    required this.fovYDeg,
    required this.aspect,
    this.near = 0.001,
    this.far  = 50.0,
    this.position = const Offset3(0, 0, 6),
    this.target   = const Offset3(0, 0, 0),
    this.up       = const Offset3(0, 1, 0),
  });

  double fovYDeg;
  double aspect;
  double near, far;
  Offset3 position, target, up;

  // Column-major 4x4 view matrix (RH)
  List<double> get viewMatrix {
    // Normalize up to avoid skew if user passes a scaled vector
    final upN = up.normalized();
    final f = (target - position).normalized(); // forward (toward -Z if target is in front)
    // If up is nearly parallel to f, fix it (rare but prevents NaNs)
    Offset3 s = f.cross(upN);
    if (s.len < 1e-9) {
      // choose an arbitrary orthogonal up
      final worldUp = (f.y.abs() > 0.99) ? const Offset3(1,0,0) : const Offset3(0,1,0);
     // final fallbackUp = (math.cos(f.y) < 0.99) ? const Offset3(0,1,0) : const Offset3(1,0,0);
     s = f.cross(worldUp);
      // s = f.cross(fallbackUp);
    }
    s = s.normalized();
    final u = s.cross(f); // already orthonormal

    // Column-major
    return <double>[
      s.x, u.x, -f.x, 0,
      s.y, u.y, -f.y, 0,
      s.z, u.z, -f.z, 0,
      -s.dot(position), -u.dot(position), f.dot(position), 1,
    ];
  }

  // Column-major RH perspective projection (OpenGL-style z in [-1,1])
  List<double> get projMatrix {
    final fov = (fovYDeg.clamp(1e-3, 179.0)) * math.pi / 180.0; // avoid tan blow-ups
    final t = math.tan(fov / 2.0);
    final a = (aspect <= 0) ? 1e-9 : aspect;
/*    final fov = fovYDeg * math.pi / 180.0;
    final t = math.tan(fov / 2.0);
    final a = (aspect == 0) ? 1e-9 : aspect;*/
    // near/far guards
    final n = (near <= 0) ? 1e-3 : near;
    final f = (far <= n + 1e-6) ? n + 1.0 : far;

    final inv_t = 1.0 / t;
    final nf = 1.0 / (n - f);

    return <double>[
      inv_t / a, 0,           0,              0,
      0,         inv_t,       0,              0,
      0,         0,           (f + n) * nf,  -1,
      0,         0,           (2 * f * n) * nf, 0,
    ];
  }
}

class Offset3 {
  final double x, y, z;
  const Offset3(this.x, this.y, this.z);

  Offset3 operator +(Offset3 o) => Offset3(x + o.x, y + o.y, z + o.z);
  Offset3 operator -(Offset3 o) => Offset3(x - o.x, y - o.y, z - o.z);
  Offset3 operator *(double k)  => Offset3(x * k, y * k, z * k);

  double dot(Offset3 o)   => x * o.x + y * o.y + z * o.z;
  Offset3 cross(Offset3 o)=> Offset3(y * o.z - z * o.y, z * o.x - x * o.z, x * o.y - y * o.x);

  double get len => math.sqrt(x * x + y * y + z * z);
  Offset3 normalized() => (len == 0) ? this : this * (1 / len);
}

/// Project a world-space point to screen. Returns null if behind the camera.
Offset? projectVec(Offset3 v, Camera3D cam, Size size) {
  final pv = mulMat4(cam.projMatrix, cam.viewMatrix);

  final clip = mul4(pv, _Vec4(v.x, v.y, v.z, 1.0));
  final w = clip.w;

  if (!w.isFinite || w <= 0) return null; // behind camera

  final ndcX = clip.x / w;
  final ndcY = clip.y / w;
  if (!ndcX.isFinite || !ndcY.isFinite) return null;

  final x = (ndcX * 0.5 + 0.5) * size.width;
  final y = (1.0 - (ndcY * 0.5 + 0.5)) * size.height;
  return Offset(x, y);
}

class _Vec4 {
  final double x,y,z,w;
  const _Vec4(this.x,this.y,this.z,this.w);
}

_Vec4 mul4(List<double> m, _Vec4 v) {
  // column-major: m[c*4 + r]
  return _Vec4(
    m[0]*v.x + m[4]*v.y + m[8]*v.z  + m[12]*v.w,
    m[1]*v.x + m[5]*v.y + m[9]*v.z  + m[13]*v.w,
    m[2]*v.x + m[6]*v.y + m[10]*v.z + m[14]*v.w,
    m[3]*v.x + m[7]*v.y + m[11]*v.z + m[15]*v.w,
  );
}

///  precompute PV to reduce allocations:
List<double> mulMat4(List<double> a, List<double> b) {
  // column-major 4x4 * 4x4
  final r = List<double>.filled(16, 0.0);
  for (int c = 0; c < 4; c++) {
    for (int rIdx = 0; rIdx < 4; rIdx++) {
      r[c*4 + rIdx] =
          a[0*4 + rIdx]*b[c*4 + 0] +
              a[1*4 + rIdx]*b[c*4 + 1] +
              a[2*4 + rIdx]*b[c*4 + 2] +
              a[3*4 + rIdx]*b[c*4 + 3];
    }
  }
  return r;
}
