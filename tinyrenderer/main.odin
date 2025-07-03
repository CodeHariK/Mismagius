package main

import clay "./clay/bindings/odin/clay-odin"
import "core:bytes"
import "core:fmt"
import "core:image"
import "core:image/tga"

import "core:time"

main :: proc() {
	tgasave()

	// benchmark_draw_lines()
}

tgasave :: proc() {
	img := tga.Image{}
	img.width = 100
	img.height = 100
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

	t0 := Vec2i {
		x = 10,
		y = 10,
	}
	t1 := Vec2i {
		x = 50,
		y = 80,
	}
	t2 := Vec2i {
		x = 90,
		y = 20,
	}

	pts := [3]Vec2i{Vec2i{x = 10, y = 10}, Vec2i{x = 50, y = 80}, Vec2i{x = 90, y = 20}}

	// triangle_filled(pts, &img, 0, 255, 0)
	// triangle(pts, &img, 255, 0, 0)

	model, ok := read_obj("assets/Lowpoly_tree_sample.obj")
	if (ok) {
		render_wireframe(model, &img, [3]u8{0, 0, 255})
	}

	flip_image_vertical(&img)
	err := tga.save_to_file("hello.tga", &img)
	fmt.println(err)
}
