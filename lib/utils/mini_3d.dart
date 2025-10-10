import 'dart:math' as math;
import 'package:flutter/material.dart';

class Camera3D {
  Camera3D({
    required this.fovYDeg,
    required this.aspect,
    this.near = 0.1,
    this.far = 1000.0,
    this.position = const Offset3(0, 0, 6), // camera at +Z looking toward target (typically -Z)
    this.target = const Offset3(0, 0, 0),
    this.up = const Offset3(0, 1, 0),
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
      final fallbackUp = (math.cos(f.y) < 0.99) ? const Offset3(0,1,0) : const Offset3(1,0,0);
      s = f.cross(fallbackUp);
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
    final fov = fovYDeg * math.pi / 180.0;
    final t = math.tan(fov / 2.0);
    final a = (aspect == 0) ? 1e-9 : aspect;
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
  // Multiply column-major matrices with column vectors
  Offset3 mulMat(List<double> m, Offset3 p, {double w = 1}) {
    return Offset3(
      m[0] * p.x + m[4] * p.y + m[8]  * p.z + m[12] * w,
      m[1] * p.x + m[5] * p.y + m[9]  * p.z + m[13] * w,
      m[2] * p.x + m[6] * p.y + m[10] * p.z + m[14] * w,
    );
  }

  // World -> View -> Clip
  final vCam  = mulMat(cam.viewMatrix, v);
  final vClip = mulMat(cam.projMatrix, vCam, w: 1);

  // Compute w' = last row dot [x y z 1]^T
  final pm = cam.projMatrix;
  final wPrime = (pm[3] * vCam.x + pm[7] * vCam.y + pm[11] * vCam.z + pm[15] * 1.0);

  // Behind camera or invalid
  if (!wPrime.isFinite || wPrime <= 0) return null;

  final ndcX = vClip.x / wPrime; // -1..1
  final ndcY = vClip.y / wPrime;

  // Optional quick clip test: skip things far off-screen
  if (!ndcX.isFinite || !ndcY.isFinite) return null;

  // NDC -> screen
  final x = (ndcX * 0.5 + 0.5) * size.width;
  final y = (1.0 - (ndcY * 0.5 + 0.5)) * size.height;
  return Offset(x, y);
}
