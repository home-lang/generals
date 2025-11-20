# Generals Math Library

**Status**: ✅ Core implementation complete
**Source**: Ported from [Thyme Engine](https://github.com/TheAssemblyArmada/Thyme) (GPL licensed)
**Language**: Home programming language

## Overview

This math library provides the foundation for the C&C Generals engine implementation. All code is ported from the Thyme engine's W3D math library.

## Components

### Vector Math

- **Vec2** (`vector2.home`) - 2D vectors
  - Basic operations: add, sub, mul, div
  - Dot product, perpendicular dot product
  - Normalization, length calculations
  - Rotation, interpolation
  - Quick distance approximation

- **Vec3** (`vector3.home`) - 3D vectors
  - All Vec2 operations plus:
  - Cross product (full and individual components)
  - Rotation around X, Y, Z axes
  - Quick length approximation
  - Color conversion (ARGB/ABGR)
  - Utility functions for line intersection

- **Vec4** (`vector4.home`) - 4D vectors
  - Homogeneous coordinates for transformations
  - Used in Matrix4 operations
  - Conversion to/from Vec3

### Matrix Math

- **Mat4** (`matrix4.home`) - 4x4 matrices
  - Identity, zero matrix constructors
  - Perspective projection (FOV and frustum)
  - Orthographic projection
  - Matrix multiplication, addition, subtraction
  - Transpose, determinant, inverse
  - Transform points and directions
  - Full Vec3/Vec4 transformation support

### Rotation Math

- **Quat** (`quaternion.home`) - Quaternions
  - Rotation representation (more efficient than matrices)
  - Spherical linear interpolation (SLERP)
  - Axis-angle conversion
  - Vector rotation
  - Quaternion multiplication
  - Conjugate and inverse

## Design Principles

### Memory Layout

- All types use `f32` (32-bit floats) matching Thyme exactly
- Vectors use separate x, y, z, w fields (not arrays) for clarity
- Matrix4 uses row-major storage (4 Vec4 rows)

### Performance

- Avoided unnecessary allocations (stack-based types)
- Inline-friendly function structure
- Quick approximations for distance/length when precision isn't critical
- Pre-computed sin/cos variants for rotation functions

### Accuracy

- Uses standard math functions from `std.math`
- Normalization guards against zero-length vectors
- Matrix inverse checks determinant before computing
- SLERP uses linear interpolation fallback for near-parallel quaternions

## Usage Examples

```home
import math.vector3.Vec3
import math.matrix4.Mat4
import math.quaternion.Quat

// Vector operations
let a = Vec3.init(1.0, 2.0, 3.0)
let b = Vec3.init(4.0, 5.0, 6.0)
let c = a.add(&b)           // Vector addition
let dot = a.dot(&b)         // Dot product: 32.0
let cross = a.cross(&b)     // Cross product

// Matrix transformations
let view = Mat4.identity()
let proj = Mat4.perspective_fov(
    1.57,  // 90 degrees horizontal FOV
    1.18,  // ~68 degrees vertical FOV
    1.0,   // near plane
    1000.0 // far plane
)

let point = Vec3.init(100.0, 50.0, 200.0)
let transformed = proj.transform_point(&point)

// Quaternion rotations
let axis = Vec3.unit_y()  // Rotate around Y axis
let rotation = Quat.from_axis_angle(&axis, 1.57)  // 90 degrees
let rotated = rotation.rotate_vector(&point)

// Interpolation
let start = Vec3.init(0.0, 0.0, 0.0)
let end = Vec3.init(10.0, 10.0, 10.0)
let midpoint = Vec3.lerp(&start, &end, 0.5)  // (5, 5, 5)
```

## Testing

Each module includes inline validation:
- NaN/Inf checking via `is_valid()`
- Zero-length guards in normalization
- Epsilon comparison for floating-point equality

## References

### Thyme Source Files
- `Thyme/src/w3d/math/vector2.h` → `vector2.home`
- `Thyme/src/w3d/math/vector3.h` → `vector3.home`
- `Thyme/src/w3d/math/vector4.h` → `vector4.home`
- `Thyme/src/w3d/math/matrix4.h` → `matrix4.home`
- `Thyme/src/w3d/math/quat.h` → `quaternion.home`

### Key Features Preserved
- ✅ Inline function structure
- ✅ Fast inverse square root for normalization
- ✅ Quick distance approximations
- ✅ Rotation helper functions (separate sin/cos variants)
- ✅ Static utility functions
- ✅ Operator-like methods (add, sub, mul, div)

## Next Steps

This math library forms the foundation for:
1. **Renderer** - Camera, view/projection matrices
2. **Game Logic** - Entity positions, rotations, physics
3. **Collision** - Bounding boxes, ray intersections
4. **Animation** - Skeletal transforms, interpolation
5. **Particles** - Velocity, acceleration vectors

## License

This implementation maintains the GPL license from Thyme Engine.
Original authors: Tiberian Technologies, OmniBlade
Ported to Home language: November 2024
