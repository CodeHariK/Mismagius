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