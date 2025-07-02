package main

import clay "./clay/bindings/odin/clay-odin"
import "core:bytes"
import "core:fmt"
import "core:image"
import "core:image/tga"

main :: proc() {
	tgasave()
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

	flip_image_vertical(&img)
	err := tga.save_to_file("hello.tga", &img)
	fmt.println(err)
}

set_pixel :: proc(img: ^tga.Image, x, y: int, r, g, b: u8) {
	// Bounds check
	if x < 0 || x >= img.width || y < 0 || y >= img.height {
		return
	}
	index := (y * img.width + x) * img.channels
	img.pixels.buf[index + 0] = r
	img.pixels.buf[index + 1] = g
	img.pixels.buf[index + 2] = b
}

flip_image_vertical :: proc(img: ^tga.Image) {
	row_size := img.width * img.channels
	height := img.height

	for y in 0 ..< height / 2 {
		top_idx := y * row_size
		bot_idx := (height - 1 - y) * row_size

		for x in 0 ..< row_size {
			// Swap each byte in the row
			tmp := img.pixels.buf[top_idx + x]
			img.pixels.buf[top_idx + x] = img.pixels.buf[bot_idx + x]
			img.pixels.buf[bot_idx + x] = tmp
		}
	}
}

draw_line :: proc(img: ^tga.Image, x0, y0, x1, y1: int, r, g, b: u8) {
	dx := abs(x1 - x0)
	dy := abs(y1 - y0)
	sx := 1
	if x0 > x1 {sx = -1}
	sy := 1
	if y0 > y1 {sy = -1}
	err := dx - dy

	// Use mutable local variables
	x := x0
	y := y0

	for {
		set_pixel(img, x, y, r, g, b)
		if x == x1 && y == y1 {
			break
		}
		e2 := 2 * err
		if e2 > -dy {
			err -= dy
			x += sx
		}
		if e2 < dx {
			err += dx
			y += sy
		}
	}
}
