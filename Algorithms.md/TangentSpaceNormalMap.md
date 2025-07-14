# Tangent Space

* [Tangent Space](https://www.youtube.com/watch?v=lbL_GiWLQpM)
* [Normal Mapping](https://learnopengl.com/Advanced-Lighting/Normal-Mapping)

A tangent space normal map is a texture that stores surface normal vectors in a coordinate system local to each surface point, rather than in world space. This allows the same normal map to be used on different surfaces and orientations while maintaining correct lighting behavior.

## Understanding Tangent Space

Tangent space is a 3D coordinate system defined at each point on a surface by three orthogonal vectors:
- **Tangent (T)**: Points along the surface in the U texture coordinate direction
- **Bitangent (B)**: Points along the surface in the V texture coordinate direction  
- **Normal (N)**: Points perpendicular to the surface

## Calculating Tangent and Bitangent

Given a triangle with vertices and UV coordinates, you can calculate the tangent and bitangent vectors:

```
For triangle with vertices P0, P1, P2 and UV coordinates (u0,v0), (u1,v1), (u2,v2):

Edge1 = P1 - P0
Edge2 = P2 - P0
DeltaUV1 = (u1-u0, v1-v0)
DeltaUV2 = (u2-u0, v2-v0)

f = 1.0 / (DeltaUV1.x * DeltaUV2.y - DeltaUV2.x * DeltaUV1.y)

Tangent = f * (DeltaUV2.y * Edge1 - DeltaUV1.y * Edge2)
Bitangent = f * (DeltaUV1.x * Edge2 - DeltaUV2.x * Edge1)
```

The tangent and bitangent should be normalized and made orthogonal to the vertex normal.

## Constructing the TBN Matrix

The tangent-bitangent-normal (TBN) matrix transforms vectors from tangent space to world space:

```
TBN = [Tx Ty Tz]
      [Bx By Bz]
      [Nx Ny Nz]
```

Where T, B, N are the tangent, bitangent, and normal vectors in world space coordinates.

## Applying Lighting

To use tangent space normal maps in lighting calculations:

1. **Sample the normal map**: Extract the normal vector from the texture (typically stored as RGB values from 0-1, converted to -1 to 1 range)

2. **Transform to world space**: Multiply the tangent space normal by the TBN matrix
   ```
   worldNormal = TBN * tangentSpaceNormal
   ```

3. **Use in lighting calculations**: Apply your lighting model (Lambert, Phong, etc.) using the transformed normal

## Alternative Approach: Transform Light to Tangent Space

Instead of transforming normals to world space, you can transform the light direction to tangent space:

1. Calculate the inverse TBN matrix (transpose, since it's orthogonal)
2. Transform light direction: `tangentSpaceLight = transpose(TBN) * worldSpaceLight`
3. Use the tangent space normal directly from the texture with the transformed light

This approach is often more efficient in shaders since you avoid the matrix multiplication per pixel.

The key advantage of tangent space normal mapping is that it provides surface detail that responds correctly to lighting regardless of the surface orientation, creating the illusion of complex geometry with simple meshes.
