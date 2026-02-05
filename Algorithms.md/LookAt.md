# LookAt

[html](./LookAt.html)

* [Placing a Camera: the LookAt Function](https://www.scratchapixel.com/lessons/mathematics-physics-for-computer-graphics/lookat-function/framing-lookat-function.html)

Excellent — you’re diving into how camera/view matrices work!

⸻

🎯 What is gluLookAt?

gluLookAt is a helper function (from the old OpenGL GLU library) that builds a view matrix to simulate a camera positioned in the scene.

It answers the question:

“Given a camera position, a target to look at, and an up vector, how do I build the view matrix?”

⸻

📌 Signature of gluLookAt:

gluLookAt(
    eyeX, eyeY, eyeZ,      // camera position
    centerX, centerY, centerZ,  // point to look at
    upX, upY, upZ          // up direction
);

It constructs a 4×4 view matrix that transforms world coordinates into the camera’s local space.

⸻

🔧 Let’s Build Our Own lookAt Matrix

We’ll define:
	•	eye: camera position
	•	center: target position
	•	up: up direction

Step-by-step
	1.	Compute the forward vector (from eye to center):
f = normalize(center - eye)
	2.	Compute the right vector:
s = normalize(f x up)
	3.	Compute the true up vector:
u = s x f
	4.	Build the rotation + translation matrix:

View matrix =
sx 	 	  ux 	  -fx 	  0 
sy 	 	  uy 	  -fy 	  0 
sz 	 	  uz 	  -fz 	  0 
s.eye 	-u.eye   f.eye 	  1

This matrix transforms world-space coordinates into camera-space.

⸻

🟩 Odin Version of look_at (right-handed)

look_at :: proc(eye, center, up: Vec3) -> Mat4 {
	forward := normalize(center - eye)
	right := normalize(cross(forward, up))
	true_up := cross(right, forward)

	return Mat4{
		right.x,    true_up.x,    -forward.x,    0,
		right.y,    true_up.y,    -forward.y,    0,
		right.z,    true_up.z,    -forward.z,    0,
		-dot(right, eye), -dot(true_up, eye), dot(forward, eye), 1,
	}
}


⸻

🟦 C++ Version of lookAt

glm::mat4 lookAt(glm::vec3 eye, glm::vec3 center, glm::vec3 up) {
    glm::vec3 f = glm::normalize(center - eye);
    glm::vec3 s = glm::normalize(glm::cross(f, up));
    glm::vec3 u = glm::cross(s, f);

    glm::mat4 result(1.0f);
    result[0][0] = s.x;
    result[1][0] = s.y;
    result[2][0] = s.z;
    result[0][1] = u.x;
    result[1][1] = u.y;
    result[2][1] = u.z;
    result[0][2] = -f.x;
    result[1][2] = -f.y;
    result[2][2] = -f.z;
    result[3][0] = -glm::dot(s, eye);
    result[3][1] = -glm::dot(u, eye);
    result[3][2] = glm::dot(f, eye);
    return result;
}


⸻

🔄 Left-handed vs Right-handed
	•	OpenGL uses right-handed:
	•	Z-axis points backward
	•	DirectX uses left-handed:
	•	Z-axis points forward

To switch handedness:
	•	Use +f instead of -f in the matrix.

⸻

📷 Summary

gluLookAt creates the camera’s view matrix by:
	•	Aligning the camera’s local axes (right, up, forward)
	•	Applying translation so that the camera is positioned correctly
	•	Transforming the world into camera space

⸻



I've completed the comprehensive gluLookAt matrix derivation with an interactive visualization. Here's a summary of the key concepts:

## Core Algorithm

The gluLookAt function creates a view transformation matrix through these steps:

1. **Forward Vector**: `forward = normalize(center - eye)`
2. **Right Vector**: `right = normalize(forward × up)`
3. **True Up Vector**: `up = normalize(right × forward)`
4. **View Matrix**: Combines rotation and translation

## Final Matrix Form

```
[rx  ry  rz  -(r·e)]
[ux  uy  uz  -(u·e)]
[-fx -fy -fz  (f·e)]
[0   0   0    1   ]
```

Where:
- `r` = right vector
- `u` = up vector  
- `f` = forward vector
- `e` = eye position
- `·` = dot product

## Key Mathematical Insights

1. **Orthonormal Basis**: The three vectors (right, up, forward) form a perpendicular coordinate system
2. **Cross Products**: Used to ensure perpendicularity between vectors
3. **Dot Products**: Used for translation components to project eye position onto each axis
4. **Normalization**: Ensures all direction vectors have unit length

## Interactive Features

- **Real-time Visualization**: Adjust eye and center positions to see how the camera coordinate system changes
- **Live Matrix Display**: Shows the actual numerical values of the resulting view matrix
- **Vector Calculations**: Displays the computed forward, right, and up vectors

## Practical Applications

- **3D Graphics**: Essential for camera positioning in OpenGL/DirectX
- **Game Engines**: Used for first-person and third-person camera systems
- **Computer Vision**: Camera calibration and pose estimation
- **Robotics**: Coordinate frame transformations

The interactive diagram helps visualize how changing the eye position and look-at target affects the camera's local coordinate system and the resulting transformation matrix.
