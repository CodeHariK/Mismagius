package main

import "core:c"
import "core:image/tga"
import "core:math/linalg/glsl"

sample_texture :: proc(texture: tga.Image, uv: Vec2f) -> Color {
	// Clamp UVs to [0,1]
	u := clamp(uv.x, 0.0, 1.0)
	v := clamp(uv.y, 0.0, 1.0)
	// Convert to pixel coordinates
	x := int(u * f32(texture.width - 1))
	y := int((1.0 - v) * f32(texture.height - 1)) // Flip v if needed
	idx := (y * texture.width + x) * texture.channels
	r := texture.pixels.buf[idx + 0]
	g := texture.pixels.buf[idx + 1]
	b := texture.pixels.buf[idx + 2]
	return Color{r, g, b}
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

// Rasterize triangle using barycentric coordinates
drawTriangleFilled :: proc(
	pts: [3]Vec3f,
	zbuffer: ^[dynamic]f32,
	img: ^tga.Image,
	texture: ^tga.Image,
	uvs: ^[3]Vec2f,
	intensity: f32,
	color: Color,
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
	for x := bboxmin.x; x <= bboxmax.x; x += 1 {
		for y := bboxmin.y; y <= bboxmax.y; y += 1 {
			P.x = x
			P.y = y
			bc := barycentric(pts, P)
			if bc.x < 0.0 || bc.y < 0.0 || bc.z < 0.0 {
				continue
			}

			uv := uvs[0] * bc.x + uvs[1] * bc.y + uvs[2] * bc.z

			color := sample_texture(texture^, uv) if texture != nil else color

			color = Color {
				u8(clamp(f32(color.r) * intensity, 0, 255)),
				u8(clamp(f32(color.g) * intensity, 0, 255)),
				u8(clamp(f32(color.b) * intensity, 0, 255)),
			}

			if (zbuffer == nil) {
				set_pixel(img, x, y, color)
			} else {
				z := pts[0].z * bc.x + pts[1].z * bc.y + pts[2].z * bc.z
				idx := int(x + y * width)
				if zbuffer[idx] < z {
					zbuffer[idx] = z
					set_pixel(img, x, y, color)
				}
			}
		}
	}
}

drawTriangle :: proc(img: ^tga.Image, zbuffer: ^[dynamic]f32, pts: [3]Vec3f, color: Color) {
	draw_line2(img, zbuffer, [2]Vec3f{pts[0], pts[1]}, color)
	draw_line2(img, zbuffer, [2]Vec3f{pts[1], pts[2]}, color)
	draw_line2(img, zbuffer, [2]Vec3f{pts[0], pts[2]}, color)
}
