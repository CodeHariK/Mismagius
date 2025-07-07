# Perspective Projection

[html](./PerspectiveProjection.html)

```code
    Model Space (OBJ verts)
        |
        v
    [Optional: Model Transform]
        |
        v
    World Space (still Vec3f)
        |
        v
    [Optional: Camera/View Transform]
        |
        v
    Camera/View Space (Vec3f, z is depth)
        |
        v
    Perspective Projection (divide x and y by z, scale by tan(fov), aspect)
        |
        v
    Normalized Device Coordinates (NDC)
        |
        v
    Viewport Transform (world2screen)
        |
        v
    Screen Space (pixel coordinates)



   [OBJ Vertex]
        |
        v
   +-------------------+
   |   world2screen    |
   +-------------------+
        |
        v
   [Perspective Divide]
        |
        v
   [NDC: x, y in [-1,1]]
        |
        v
   [Viewport Transform]
        |
        v
   [Screen Pixel (x, y)]

```

I'll explain perspective projection with a comprehensive diagram and derive the matrix equations step by step.I've created a comprehensive explanation of perspective projection with an interactive diagram and complete mathematical derivation. Here's a summary of the key concepts:

## Core Principle
Perspective projection creates the illusion of depth by dividing x and y coordinates by the z coordinate (depth). This causes distant objects to appear smaller, mimicking how our eyes perceive the 3D world.

## Mathematical Foundation

**Basic projection equations:**
- x' = f·x/z
- y' = f·y/z

Where f is the focal length and z is the depth.

**Projection Matrix:**
```
[f  0  0  0]   [x]     [f·x]
[0  f  0  0] × [y]  =  [f·y]
[0  0  1  0]   [z]     [z  ]
[0  0  1  0]   [1]     [z  ]
```

After matrix multiplication, perspective division (dividing by the w-component) gives the final 2D coordinates.

## Key Features of the Interactive Diagram

1. **Adjustable Parameters**: You can modify focal length, object distance, and object size to see real-time effects
2. **Visual Representation**: Shows the eye, projection plane, 3D object, and resulting 2D projection
3. **Projection Rays**: Illustrates how light rays travel from the object through the projection plane to the eye

## Important Properties

- **Foreshortening**: Objects farther away appear smaller due to z-division
- **Vanishing Points**: Parallel lines converge in the projection
- **Non-linear Depth**: Z-values are not uniformly distributed in screen space
- **Focal Length Effects**: Changes the field of view and perspective distortion

The interactive diagram helps visualize how these mathematical concepts translate into the visual effects we see in 3D graphics and computer vision applications.
