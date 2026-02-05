# Triangle Rasterization Algorithm Explanation

```C++
void triangle(Vec2i t0, Vec2i t1, Vec2i t2, TGAImage &image, TGAColor color) { 
    if (t0.y==t1.y && t0.y==t2.y) return; // I dont care about degenerate triangles 
    // sort the vertices, t0, t1, t2 lower−to−upper (bubblesort yay!) 
    if (t0.y>t1.y) std::swap(t0, t1); 
    if (t0.y>t2.y) std::swap(t0, t2); 
    if (t1.y>t2.y) std::swap(t1, t2); 
    int total_height = t2.y-t0.y; 
    for (int i=0; i<total_height; i++) { 
        bool second_half = i>t1.y-t0.y || t1.y==t0.y; 
        int segment_height = second_half ? t2.y-t1.y : t1.y-t0.y; 
        float alpha = (float)i/total_height; 
        float beta  = (float)(i-(second_half ? t1.y-t0.y : 0))/segment_height; // be careful: with above conditions no division by zero here 
        Vec2i A =               t0 + (t2-t0)*alpha; 
        Vec2i B = second_half ? t1 + (t2-t1)*beta : t0 + (t1-t0)*beta; 
        if (A.x>B.x) std::swap(A, B); 
        for (int j=A.x; j<=B.x; j++) { 
            image.set(j, t0.y+i, color); // attention, due to int casts t0.y+i != A.y 
        } 
    } 
}
```

## Overview
This is a **scanline-based triangle rasterization algorithm** that fills a triangle by drawing horizontal lines (scanlines) from top to bottom. It's an efficient method for converting triangle vertices into pixels.

## Algorithm Steps

### 1. Vertex Sorting
```cpp
if (t0.y>t1.y) std::swap(t0, t1); 
if (t0.y>t2.y) std::swap(t0, t2); 
if (t1.y>t2.y) std::swap(t1, t2);
```

**Purpose:** Sort vertices by Y-coordinate so that:
- `t0` = topmost vertex (smallest Y)
- `t1` = middle vertex  
- `t2` = bottommost vertex (largest Y)

**Why needed:** The algorithm processes scanlines from top to bottom, so it needs vertices in Y-order.

### 2. Two-Pass Approach

The triangle is divided into two parts:
- **Upper part:** From `t0.y` to `t1.y` (top to middle)
- **Lower part:** From `t1.y` to `t2.y` (middle to bottom)

This handles the case where triangles aren't perfectly flat-topped or flat-bottomed.

## Pass 1: Upper Triangle (t0 to t1)

```cpp
for (int y=t0.y; y<=t1.y; y++) { 
    int segment_height = t1.y-t0.y+1; 
    float alpha = (float)(y-t0.y)/total_height; 
    float beta  = (float)(y-t0.y)/segment_height; 
    Vec2i A = t0 + (t2-t0)*alpha; 
    Vec2i B = t0 + (t1-t0)*beta; 
    if (A.x>B.x) std::swap(A, B); 
    for (int j=A.x; j<=B.x; j++) { 
        image.set(j, y, color); 
    } 
}
```

### Key Calculations:

**Alpha (α):** `(y-t0.y)/total_height`
- Interpolation factor along the **long edge** (t0 → t2)
- Ranges from 0 to ~0.5 as we go from t0 to t1
- `total_height = t2.y - t0.y` (full triangle height)

**Beta (β):** `(y-t0.y)/segment_height`  
- Interpolation factor along the **short edge** (t0 → t1)
- Ranges from 0 to 1 as we go from t0 to t1
- `segment_height = t1.y - t0.y + 1` (upper segment height)

### Edge Points:
- **Point A:** `t0 + (t2-t0)*alpha` - Point on long edge (t0→t2)
- **Point B:** `t0 + (t1-t0)*beta` - Point on short edge (t0→t1)

## Pass 2: Lower Triangle (t1 to t2)

```cpp
for (int y=t1.y; y<=t2.y; y++) { 
    int segment_height = t2.y-t1.y+1; 
    float alpha = (float)(y-t0.y)/total_height; 
    float beta  = (float)(y-t1.y)/segment_height; 
    Vec2i A = t0 + (t2-t0)*alpha; 
    Vec2i B = t1 + (t2-t1)*beta; 
    if (A.x>B.x) std::swap(A, B); 
    for (int j=A.x; j<=B.x; j++) { 
        image.set(j, y, color); 
    } 
}
```

### Key Differences:

**Alpha (α):** Still `(y-t0.y)/total_height`
- Continues interpolating along the **long edge** (t0 → t2)
- Ranges from ~0.5 to 1 as we go from t1 to t2

**Beta (β):** Now `(y-t1.y)/segment_height`
- Interpolates along the **new short edge** (t1 → t2)  
- Ranges from 0 to 1 as we go from t1 to t2
- `segment_height = t2.y - t1.y + 1` (lower segment height)

### Edge Points:
- **Point A:** `t0 + (t2-t0)*alpha` - Still on long edge (t0→t2)
- **Point B:** `t1 + (t2-t1)*beta` - Now on short edge (t1→t2)

## Visual Representation

```
    t0 (top)
    /\
   /  \
  /    \
 /      \
t1------\ (middle)
 \       \
  \       \
   \       \
    \       \
     \      /
      \    /
       \  /
        \/
       t2 (bottom)
```

**Pass 1:** Fill from t0 to t1 using edges (t0→t2) and (t0→t1)
**Pass 2:** Fill from t1 to t2 using edges (t0→t2) and (t1→t2)

## Key Features

### 1. **Interpolation:**
- Linear interpolation along triangle edges
- Ensures smooth, continuous filling
- Handles arbitrary triangle shapes

### 2. **Scanline Filling:**
- For each Y-coordinate, find left and right X boundaries
- Fill all pixels between boundaries
- Efficient pixel-by-pixel rasterization

### 3. **Edge Handling:**
- `if (A.x>B.x) std::swap(A, B)` ensures A is always leftmost
- Handles triangles with different orientations

### 4. **Robustness:**
- Works for any triangle shape (acute, obtuse, right)
- Handles degenerate cases (very thin triangles)
- Integer arithmetic prevents floating-point errors

## Advantages

1. **Simple:** Easy to understand and implement
2. **Efficient:** O(triangle_area) complexity
3. **Scanline-coherent:** Good for hardware rasterization
4. **No gaps:** Guarantees complete triangle filling

## Potential Issues

1. **Division by zero:** When `segment_height = 0` (flat triangle)
2. **Precision:** Integer casting can cause small gaps
3. **Overdraw:** Some pixels might be drawn multiple times at edges

This algorithm is fundamental in computer graphics and forms the basis for more advanced rasterization techniques used in GPUs.
