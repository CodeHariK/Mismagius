# Barycentric Coordinates Derivation

```C++
Vec3f barycentric(Vec2i *pts, Vec2i P) { 
    Vec3f u = 
    Vec3f(pts[2][0]-pts[0][0], pts[1][0]-pts[0][0], pts[0][0]-P[0])
    ^
    Vec3f(pts[2][1]-pts[0][1], pts[1][1]-pts[0][1], pts[0][1]-P[1]);
    
    if (std::abs(u.z)<1) return Vec3f(-1,1,1);
    
    return Vec3f(1.f-(u.x+u.y)/u.z, u.y/u.z, u.x/u.z); 
} 
```

## Overview
Barycentric coordinates express a point P as a weighted combination of triangle vertices. For triangle with vertices A, B, C and point P:
```
P = λ₀A + λ₁B + λ₂C
```
where λ₀ + λ₁ + λ₂ = 1 and λᵢ ≥ 0 means P is inside the triangle.

## Mathematical Setup

Given:
- Triangle vertices: `pts[0]`, `pts[1]`, `pts[2]` (let's call them A, B, C)
- Point P to test
- Need to find barycentric coordinates (λ₀, λ₁, λ₂)

## The Linear System

The barycentric coordinate equation can be written as:
```
P = λ₀A + λ₁B + λ₂C
```

With the constraint: λ₀ + λ₁ + λ₂ = 1

Substituting the constraint (λ₀ = 1 - λ₁ - λ₂):
```
P = (1 - λ₁ - λ₂)A + λ₁B + λ₂C
P = A + λ₁(B - A) + λ₂(C - A)
P - A = λ₁(B - A) + λ₂(C - A)
```

## Vector Form

Let:
- **v₀** = C - A = `(pts[2] - pts[0])`
- **v₁** = B - A = `(pts[1] - pts[0])`  
- **v₂** = A - P = `(pts[0] - P)`

Then: **v₂** = λ₁**v₁** + λ₂**v₀**

## Cross Product Solution

In 2D, we can solve this using cross products. The system becomes:
```
v₂ = λ₁v₁ + λ₂v₀
```

Taking cross product with **v₁** and **v₀**:
```
v₂ × v₁ = λ₂(v₀ × v₁)
v₂ × v₀ = λ₁(v₁ × v₀) = -λ₁(v₀ × v₁)
```

## Code Implementation Analysis

The code creates two 3D vectors for cross product calculation:

**First vector:**
```cpp
Vec3f(pts[2][0]-pts[0][0], pts[1][0]-pts[0][0], pts[0][0]-P[0])
```
This is: `(v₀.x, v₁.x, v₂.x)`

**Second vector:**
```cpp
Vec3f(pts[2][1]-pts[0][1], pts[1][1]-pts[0][1], pts[0][1]-P[1])
```
This is: `(v₀.y, v₁.y, v₂.y)`

## Cross Product Calculation

The cross product **u** = **a** × **b** where:
- **a** = `(v₀.x, v₁.x, v₂.x)`
- **b** = `(v₀.y, v₁.y, v₂.y)`

Result:
```
u.x = v₁.x × v₂.y - v₂.x × v₁.y = v₁ × v₂  (2D cross product)
u.y = v₂.x × v₀.y - v₀.x × v₂.y = v₂ × v₀  (2D cross product)  
u.z = v₀.x × v₁.y - v₁.x × v₀.y = v₀ × v₁  (2D cross product)
```

## Solving for Barycentric Coordinates

From our earlier equations:
```
v₂ × v₁ = λ₂(v₀ × v₁)  →  λ₂ = (v₂ × v₁)/(v₀ × v₁) = u.x/u.z
v₂ × v₀ = -λ₁(v₀ × v₁)  →  λ₁ = -(v₂ × v₀)/(v₀ × v₁) = -u.y/u.z = u.y/u.z
```

And: λ₀ = 1 - λ₁ - λ₂ = 1 - u.y/u.z - u.x/u.z = 1 - (u.x + u.y)/u.z

## Final Result

The function returns:
```cpp
Vec3f(1.f-(u.x+u.y)/u.z, u.y/u.z, u.x/u.z)
```

Which corresponds to: `(λ₀, λ₁, λ₂)` where:
- λ₀ = 1 - (u.x + u.y)/u.z  (weight for pts[0])
- λ₁ = u.y/u.z              (weight for pts[1])  
- λ₂ = u.x/u.z              (weight for pts[2])

## Degenerate Case

If `abs(u.z) < 1`, then `u.z ≈ 0`, meaning `v₀ × v₁ ≈ 0`. This happens when:
- The triangle is degenerate (vertices are collinear)
- The triangle has zero or near-zero area

In this case, the function returns `(-1, 1, 1)` to indicate invalid barycentric coordinates.

## Geometric Interpretation

- If all λᵢ ≥ 0: Point P is inside the triangle
- If any λᵢ < 0: Point P is outside the triangle  
- λᵢ represents the "weight" or "influence" of vertex i on point P
- The coordinates naturally satisfy λ₀ + λ₁ + λ₂ = 1
