# Barycentric Triangle Rasterization Explanation

## Overview
This is a **bounding box + barycentric coordinates** approach to triangle rasterization. Instead of scanlines, it tests every pixel in the triangle's bounding box to see if it's inside the triangle using barycentric coordinates.

## Algorithm Steps

### 1. Bounding Box Calculation

```cpp
Vec2i bboxmin(image.get_width()-1,  image.get_height()-1); 
Vec2i bboxmax(0, 0); 
Vec2i clamp(image.get_width()-1, image.get_height()-1);
```

**Initial Setup:**
- `bboxmin`: Start with maximum possible values (width-1, height-1)
- `bboxmax`: Start with minimum possible values (0, 0)
- `clamp`: Screen boundaries for clipping

**Why this initialization?**
- We want to find the **minimum** bounding box, so start `bboxmin` large and shrink it
- We want to find the **maximum** bounding box, so start `bboxmax` small and grow it

### 2. Finding Tight Bounding Box

```cpp
for (int i=0; i<3; i++) { 
    bboxmin.x = std::max(0, std::min(bboxmin.x, pts[i].x));
    bboxmin.y = std::max(0, std::min(bboxmin.y, pts[i].y));
    
    bboxmax.x = std::min(clamp.x, std::max(bboxmax.x, pts[i].x));
    bboxmax.y = std::min(clamp.y, std::max(bboxmax.y, pts[i].y));
}
```

**For each vertex:**

**Minimum bounds:**
- `std::min(bboxmin.x, pts[i].x)` - Find smallest X coordinate
- `std::max(0, ...)` - Clamp to screen boundary (don't go negative)

**Maximum bounds:**
- `std::max(bboxmax.x, pts[i].x)` - Find largest X coordinate  
- `std::min(clamp.x, ...)` - Clamp to screen boundary (don't exceed screen)

**Result:** A tight bounding box around the triangle, clipped to screen boundaries.

### 3. Pixel Testing Loop

```cpp
Vec2i P; 
for (P.x=bboxmin.x; P.x<=bboxmax.x; P.x++) { 
    for (P.y=bboxmin.y; P.y<=bboxmax.y; P.y++) { 
        Vec3f bc_screen = barycentric(pts, P); 
        if (bc_screen.x<0 || bc_screen.y<0 || bc_screen.z<0) continue; 
        image.set(P.x, P.y, color); 
    } 
}
```

**For each pixel P in the bounding box:**

1. **Calculate barycentric coordinates:** `barycentric(pts, P)`
   - Returns (λ₀, λ₁, λ₂) weights for the three vertices
   - These weights satisfy: λ₀ + λ₁ + λ₂ = 1

2. **Inside/outside test:** Check if all barycentric coordinates are non-negative
   - If **all λᵢ ≥ 0**: Point P is **inside** the triangle
   - If **any λᵢ < 0**: Point P is **outside** the triangle

3. **Render pixel:** If inside, set the pixel color

## Visual Representation

```
Screen boundaries
┌─────────────────────────────┐
│                             │
│    bboxmin ┌─────────┐      │
│           │░░░░░░░░░│      │
│           │░░░/\░░░░│      │
│           │░░/  \░░░│      │
│           │░/____\░░│      │
│           │░░░░░░░░░│      │
│           └─────────┘      │
│                   bboxmax   │
│                             │
└─────────────────────────────┘

░ = Tested pixels (bounding box)
Triangle = Actual triangle
Only pixels inside triangle get colored
```

## Key Advantages

### 1. **Simplicity**
- Very straightforward algorithm
- Easy to understand and debug
- No edge cases with triangle orientation

### 2. **Robustness**
- Works with any triangle shape
- Handles degenerate triangles gracefully
- No floating-point precision issues with edge walking

### 3. **Barycentric Benefits**
- Natural for interpolation (colors, textures, normals)
- Easy to extend for shader calculations
- Mathematical elegance

### 4. **Parallel-Friendly**
- Each pixel test is independent
- Perfect for GPU parallelization
- No dependencies between pixels

## Key Disadvantages

### 1. **Efficiency**
- Tests **every pixel** in bounding box
- Wastes computation on pixels outside triangle
- For thin triangles, tests many unnecessary pixels

### 2. **Performance Analysis**
```
Scanline algorithm: O(triangle_area)
Bounding box algorithm: O(bounding_box_area)

For thin triangles: bounding_box_area >> triangle_area
```

### 3. **Cache Performance**
- Random access pattern (not scanline-coherent)
- Less cache-friendly than scanline algorithms

## When to Use Each Approach

### **Barycentric (This Algorithm):**
- ✅ Simple implementation needed
- ✅ GPU/parallel processing
- ✅ Need barycentric coordinates for interpolation
- ✅ Triangles are roughly square/compact

### **Scanline (Previous Algorithm):**
- ✅ CPU implementation
- ✅ Thin/elongated triangles
- ✅ Memory/cache efficiency important
- ✅ Sequential processing

## Example Walkthrough

Given triangle vertices: (10,5), (20,15), (5,15)

**Step 1: Bounding box**
- bboxmin = (5, 5)
- bboxmax = (20, 15)

**Step 2: Test each pixel**
- Test (5,5): barycentric = (0.5, 0.3, 0.2) → All positive → Draw
- Test (6,5): barycentric = (0.4, 0.4, 0.2) → All positive → Draw  
- Test (25,5): barycentric = (-0.2, 0.7, 0.5) → Negative → Skip
- Continue for all pixels in bounding box...

This algorithm is widely used in modern GPU rasterizers because it's simple to implement in parallel hardware, even though it may test more pixels than strictly necessary.
