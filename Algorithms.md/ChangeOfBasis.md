Change of basis in 3D is the process of representing vectors in a new coordinate system defined by a different set of basis vectors.

Let’s go step-by-step.

⸻

🔢 What is a Basis?

In 3D, a basis is a set of 3 linearly independent vectors:

Standard basis:
  e1  e2  e3
[ 1   0   0  ]
[ 0   1   0  ]
[ 0   0   1  ]

Any vector v in R^3 can be written as:
v = x * e1 + y * e2 + z * e3

⸻

🧭 Suppose You Have a New Basis

Let the new basis be 3 vectors:
u1, u2, u3 in R^3

Let’s build a matrix from them:

U = (3x3 matrix) =
|    |    |
u1   u2   u3
|    |    |

⸻

🎯 Problem: Change Representation of a Vector

1. From new basis → standard basis

If you are given coordinates  in the new basis, then:

v’ = | a |
     | b |
     | c |

v = U * v’

You’re combining basis vectors with the coefficients.

⸻

2. From standard basis → new basis

If you’re given a vector v in standard basis and want its coordinates v’ in the new basis:

v’ = U^{-1} * v

You’re projecting the vector into the new basis space.

⸻

🔁 Summary Table

Task	Formula
From new basis to world basis	v = U * v’
From world basis to new basis	v’ = U^{-1} * v


⸻

📦 Applications
	•	3D graphics: moving between object space, world space, camera space
	•	Physics: working in rotated coordinate frames
	•	Robotics: frame transformations
	•	Linear algebra: diagonalizing matrices

⸻




You’re absolutely right — what I explained was linear change of basis, which covers rotation and scaling, but not translation.

When you include translation, you’re dealing with a full affine transformation, and to handle that in 3D, you need to use homogeneous coordinates.

Let’s break it down properly:

⸻

🔁 Change of Basis + Translation = Affine Transform

In 3D, to go from one coordinate system (frame) to another, you often need to apply:
	1.	A rotation (change of axes)
	2.	A scaling (optional)
	3.	A translation (move the origin)

This is represented by a 4×4 matrix acting on 4D homogeneous vectors.

⸻

🧮 Homogeneous Transformation Matrix

If your new basis has:
	•	Axes u1, u2, u3 (i.e. the new X, Y, Z directions)
	•	Origin at point 
        O = | ox | 
            | oy | 
            | oz |

Then the matrix to go from local to world coordinates is:

M = 
|   |   |   ox 
u1  u2  u3  oy
|   |   |   oz 
0   0   0   1

Apply it to homogeneous vector:
v’ = 
| x’ | 
| y’ | 
| z’ | 
| 1  | 

v = M * v’

This gives you the world-space position of a point defined in the local frame.

⸻

🔁 Going the Other Way (World → Local)

To go from world coordinates v to local coordinates v’, you invert the affine matrix:

v’ = M^{-1} * v

If the basis vectors u1, u2, u3 are orthonormal (i.e. pure rotation), you can compute the inverse efficiently:
	•	Transpose the rotation part
	•	Negate the translation and apply the transposed rotation

⸻

📘 Example

Let’s say you have a local frame:
	•	Origin at O = (10, 0, 0)
	•	Local axes:
	•	u1 = (0, 1, 0)
	•	u2 = (1, 0, 0)
	•	u3 = (0, 0, 1)

Then the transformation matrix is:

M =
0    1    0    10 
1    0    0    0 
0    0    1    0 
0    0    0    1

If you have a local point v’ = (1, 2, 3, 1), then:

v = M * v’ = (2, 1, 3, 1)

⸻

🧠 Summary

Purpose	Matrix	Action
Change of basis (rotation)	3×3	v = U * v’
Add translation	4×4	v = M * v’
Homogeneous coordinates	4D vectors	Enables translation in matrix
Local → World coords	Apply matrix	v = M * v’
World → Local coords	Invert matrix	v’ = M^{-1} * v
