package main

import "core:c"
import "core:fmt"
import "core:image/tga"
import "core:math/linalg/glsl"
import "core:math/rand"

sample_texture :: proc(texture: ^tga.Image, uv: Vec2f, color: ^Color, intensity: f32) -> Color {
	r := color.r if color != nil else u8(rand.int63_max(255))
	g := color.g if color != nil else u8(rand.int63_max(255))
	b := color.b if color != nil else u8(rand.int63_max(255))

	if (texture != nil) {
		// Clamp UVs to [0,1]
		u := clamp(uv.x, 0.0, 1.0)
		v := clamp(uv.y, 0.0, 1.0)
		// Convert to pixel coordinates
		x := int(u * f32(texture.width - 1))
		y := int((1.0 - v) * f32(texture.height - 1)) // Flip v if needed
		idx := (y * texture.width + x) * texture.channels
		r = texture.pixels.buf[idx + 0]
		g = texture.pixels.buf[idx + 1]
		b = texture.pixels.buf[idx + 2]
	}

	icolor := Color {
		u8(clamp(f32(r) * intensity, 0, 255)),
		u8(clamp(f32(g) * intensity, 0, 255)),
		u8(clamp(f32(b) * intensity, 0, 255)),
	}
	return icolor
}

barycentric :: proc(pts: [3]Vec3f, P: Vec3f) -> Vec3f {
	a := Vec3f{f32(pts[2].x - pts[0].x), f32(pts[1].x - pts[0].x), f32(pts[0].x - P.x)}
	b := Vec3f{f32(pts[2].y - pts[0].y), f32(pts[1].y - pts[0].y), f32(pts[0].y - P.y)}
	u := glsl.cross_vec3(a, b)
	if abs(u.z) < 1.0 {
		return Vec3f{-1, 1, 1}
	}
	return Vec3f{1.0 - (u.x + u.y) / u.z, u.y / u.z, u.x / u.z}
}

drawTriangleFilled :: proc(
	zbuffer: ^[dynamic]f32,
	img: ^tga.Image,
	texture: ^tga.Image,
	pts: [3]Vec3f,
	uvs: ^[3]Vec2f,
	intensity: f32,
	color: ^Color,
) {
	width := f32(img.width)
	height := f32(img.height)

	bboxmin := Vec2f{width - 1, height - 1}
	bboxmax := Vec2f{0, 0}
	bboxmaxclamp := Vec2f{width - 1, height - 1}

	for i in 0 ..< 3 {
		bboxmin.x = max(0, min(bboxmin.x, pts[i].x))
		bboxmin.y = max(0, min(bboxmin.y, pts[i].y))
		bboxmax.x = min(bboxmaxclamp.x, max(bboxmax.x, pts[i].x))
		bboxmax.y = min(bboxmaxclamp.y, max(bboxmax.y, pts[i].y))
	}

	P := Vec3f{}
	// for x := bboxmin.x; x <= bboxmax.x; x += 1 {
	// 	for y := bboxmin.y; y <= bboxmax.y; y += 1 {
	// 		P.x = x
	// 		P.y = y
	// 		bc := barycentric(pts, P)
	// 		if bc.x < 0.0 || bc.y < 0.0 || bc.z < 0.0 {
	// 			continue
	// 		}

	// 		uv := uvs[0] * bc.x + uvs[1] * bc.y + uvs[2] * bc.z
	// 		icolor := sample_texture(texture, uv, color, intensity)

	// 		if (zbuffer == nil) {
	// 			set_pixel(img, x, y, icolor)
	// 		} else {
	// 			z := pts[0].z * bc.x + pts[1].z * bc.y + pts[2].z * bc.z

	// 			idx := int(x + y * width)
	// 			if zbuffer[idx] < z {
	// 				zbuffer[idx] = z
	// 				set_pixel(img, x, y, icolor)
	// 			}
	// 		}
	// 	}
	// }

	for x := int(bboxmin.x); x <= int(bboxmax.x); x += 1 {
		for y := int(bboxmin.y); y <= int(bboxmax.y); y += 1 {
			P.x = f32(x)
			P.y = f32(y)
			bc := barycentric(pts, P)

			epsilon := f32(0.000001)
			if bc.x < -epsilon || bc.y < -epsilon || bc.z < -epsilon {
				continue
			}

			uv := uvs[0] * bc.x + uvs[1] * bc.y + uvs[2] * bc.z
			icolor := sample_texture(texture, uv, color, intensity)

			if zbuffer == nil {
				set_pixel(img, f32(x), f32(y), icolor)
			} else {
				z := pts[0].z * bc.x + pts[1].z * bc.y + pts[2].z * bc.z
				idx := x + y * int(width)
				if zbuffer[idx] < z {
					zbuffer[idx] = z
					set_pixel(img, f32(x), f32(y), icolor)
				}
			}
		}
	}
}

neotriangle :: proc(
	zbuffer: ^[dynamic]f32,
	image: ^tga.Image,
	texture: ^tga.Image,
	pts: [3]Vec3f,
	uvs: ^[3]Vec2f,
	intensity: f32,
	color: ^Color,
) {
	t0 := pts[0]
	t1 := pts[1]
	t2 := pts[2]

	if t0.y == t1.y && t0.y == t2.y {
		return
	}
	uv0 := uvs[0]
	uv1 := uvs[1]
	uv2 := uvs[2]

	if t0.y > t1.y {
		swapVec3f(&t0, &t1)
		swapVec2f(&uv0, &uv1)
	}
	if t0.y > t2.y {
		swapVec3f(&t0, &t2)
		swapVec2f(&uv0, &uv2)
	}
	if t1.y > t2.y {
		swapVec3f(&t1, &t2)
		swapVec2f(&uv1, &uv2)
	}

	total_height := t2.y - t0.y
	for i in 0 ..< total_height {

		second_half := i > (t1.y - t0.y) || t1.y == t0.y
		segment_height := (t2.y - t1.y) if second_half else (t1.y - t0.y)

		alpha := f32(i) / f32(total_height)
		beta := f32(i - ((t1.y - t0.y) if second_half else 0)) / f32(segment_height)

		A := t0 + (t2 - t0) * alpha
		B := (t1 + (t2 - t1) * beta) if second_half else (t0 + (t1 - t0) * beta)

		uvA := uv0 + (uv2 - uv0) * alpha
		uvB := (uv1 + (uv2 - uv1) * beta) if second_half else (uv0 + (uv1 - uv0) * beta)

		if A.x > B.x {
			swapVec3f(&A, &B)
			swapVec2f(&uvA, &uvB)
		}

		for j := A.x; j <= B.x; j += 1 {
			phi := 1.0 if int(B.x) == int(A.x) else (f32(j - (A.x)) / f32(int(B.x) - int(A.x)))
			P := A + (B - A) * phi
			uvP := uvA + (uvB - uvA) * phi

			idx := int(P.x) + int(P.y) * image.width
			if zbuffer[idx] < (P.z) {
				zbuffer[idx] = (P.z)

				color := sample_texture(texture, uvP, color, intensity)

				set_pixel(image, (P.x), (P.y), color)
			}
		}
	}
}

drawTriangle :: proc(img: ^tga.Image, zbuffer: ^[dynamic]f32, pts: [3]Vec3f, color: Color) {
	draw_line2(img, zbuffer, [2]Vec3f{pts[0], pts[1]}, color)
	draw_line2(img, zbuffer, [2]Vec3f{pts[1], pts[2]}, color)
	draw_line2(img, zbuffer, [2]Vec3f{pts[0], pts[2]}, color)
}

swapVec3f :: proc(a, b: ^Vec3f) {
	tmp := a^
	a^ = b^
	b^ = tmp
}

swapVec2f :: proc(a, b: ^Vec2f) {
	tmp := a^
	a^ = b^
	b^ = tmp
}
