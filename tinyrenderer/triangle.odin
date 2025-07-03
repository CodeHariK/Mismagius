package main

import "core:image/tga"

Vec3f :: struct {
	x, y, z: f32,
}

cross :: proc(a, b: Vec3f) -> Vec3f {
	return Vec3f{x = a.y * b.z - a.z * b.y, y = a.z * b.x - a.x * b.z, z = a.x * b.y - a.y * b.x}
}

barycentric :: proc(pts: [3]Vec2i, P: Vec2i) -> Vec3f {
	a := Vec3f {
		x = f32(pts[2].x - pts[0].x),
		y = f32(pts[1].x - pts[0].x),
		z = f32(pts[0].x - P.x),
	}
	b := Vec3f {
		x = f32(pts[2].y - pts[0].y),
		y = f32(pts[1].y - pts[0].y),
		z = f32(pts[0].y - P.y),
	}
	u := cross(a, b)
	if abs(u.z) < 1.0 {
		return Vec3f{-1, 1, 1}
	}
	return Vec3f{x = 1.0 - (u.x + u.y) / u.z, y = u.y / u.z, z = u.x / u.z}
}

// Rasterize triangle using barycentric coordinates
triangle_filled :: proc(pts: [3]Vec2i, img: ^tga.Image, r, g, b: u8) {
	bboxmin := Vec2i {
		x = img.width - 1,
		y = img.height - 1,
	}
	bboxmax := Vec2i {
		x = 0,
		y = 0,
	}
	clamp := Vec2i {
		x = img.width - 1,
		y = img.height - 1,
	}

	for i in 0 ..< 3 {
		bboxmin.x = max(0, min(bboxmin.x, pts[i].x))
		bboxmin.y = max(0, min(bboxmin.y, pts[i].y))
		bboxmax.x = min(clamp.x, max(bboxmax.x, pts[i].x))
		bboxmax.y = min(clamp.y, max(bboxmax.y, pts[i].y))
	}

	P := Vec2i{}
	for x := bboxmin.x; x <= bboxmax.x; x += 1 {
		for y := bboxmin.y; y <= bboxmax.y; y += 1 {
			P.x = x
			P.y = y
			bc_screen := barycentric(pts, P)
			if bc_screen.x < 0.0 || bc_screen.y < 0.0 || bc_screen.z < 0.0 {
				continue
			}
			set_pixel(img, x, y, r, g, b)
		}
	}
}

triangle :: proc(pts: [3]Vec2i, img: ^tga.Image, r, g, b: u8) {
	draw_line2(img, pts[0].x, pts[0].y, pts[1].x, pts[1].y, r, g, b)
	draw_line2(img, pts[1].x, pts[1].y, pts[2].x, pts[2].y, r, g, b)
	draw_line2(img, pts[2].x, pts[2].y, pts[0].x, pts[0].y, r, g, b)
}
