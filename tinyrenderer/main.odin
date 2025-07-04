package main

import clay "./clay/bindings/odin/clay-odin"
import "core:bytes"
import "core:fmt"
import "core:image"
import "core:image/tga"

import "core:math"

import "core:time"

Vec3f :: struct {
	x, y, z: f32,
}

main :: proc() {
	tgasave()

	// benchmark_draw_lines()
}

tgasave :: proc() {
	img := tga.Image{}
	img.width = 500
	img.height = 500
	img.channels = 3 // RGB
	img.depth = 8 // 8 bits per channel
	img.pixels = bytes.Buffer {
		buf = make([dynamic]u8, img.width * img.height * 3),
	}
	for i in 0 ..< len(img.pixels.buf) {
		img.pixels.buf[i] = 255 // Set all pixels to white
	}

	set_pixel(&img, 10, 10, 255, 0, 0)

	draw_line(&img, 10, 10, 90, 90, 0, 0, 255) // Draws a blue diagonal line

	t0 := Vec3f {
		x = 10,
		y = 10,
	}
	t1 := Vec3f {
		x = 50,
		y = 80,
	}
	t2 := Vec3f {
		x = 90,
		y = 20,
	}

	pts := [3]Vec3f{Vec3f{x = 10, y = 10}, Vec3f{x = 50, y = 80}, Vec3f{x = 90, y = 20}}

	zbuffer := make([dynamic]f32, img.width * img.height)
	for i in 0 ..< len(zbuffer) {
		zbuffer[i] = -math.INF_F32
	}

	// drawTriangleFilledZ(
	// 	[3]Vec3f {
	// 		Vec3f{x = 10, y = 10, z = 0.5},
	// 		Vec3f{x = 50, y = 80, z = 0.7},
	// 		Vec3f{x = 90, y = 20, z = 0.2},
	// 	},
	// 	zbuffer,
	// 	&img,
	// 	255,
	// 	0,
	// 	0,
	// )

	// drawTriangleFilled(pts, &img, 0, 255, 0)
	// drawTriangle(pts, &img, 255, 0, 0)

	model, ok := read_obj("assets/Lowpoly_tree_sample.obj")
	if (ok) {
		render_wireframe(model, &img, &zbuffer, &[3]u8{200, 200, 200})
		// render_wireframe(model, &img, nil, &[3]u8{200, 200, 200})
	}

	flip_image_vertical(&img)
	err := tga.save_to_file("hello.tga", &img)
	fmt.println(err)
}
