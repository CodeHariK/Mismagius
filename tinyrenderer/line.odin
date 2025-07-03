package main

import "core:bytes"

import "core:fmt"
import "core:image"
import "core:image/tga"

import "core:time"

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

draw_line2 :: proc(img: ^tga.Image, x0, y0, x1, y1: int, r, g, b: u8) {
	// Copy parameters to mutable locals
	_x0 := x0
	_y0 := y0
	_x1 := x1
	_y1 := y1

	steep := false
	if abs(_x0 - _x1) < abs(_y0 - _y1) {
		// Swap x and y for both points
		tmp := _x0;_x0 = _y0;_y0 = tmp
		tmp = _x1;_x1 = _y1;_y1 = tmp
		steep = true
	}
	if _x0 > _x1 {
		// Swap start and end points
		tmp := _x0;_x0 = _x1;_x1 = tmp
		tmp = _y0;_y0 = _y1;_y1 = tmp
	}
	dx := _x1 - _x0
	dy := _y1 - _y0
	derror2 := abs(dy) * 2
	error2 := 0
	y := _y0
	y_step := 1
	if _y1 < _y0 {
		y_step = -1
	}
	if steep {
		for x := _x0; x <= _x1; x += 1 {
			set_pixel(img, y, x, r, g, b)
			error2 += derror2
			if error2 > dx {
				y += y_step
				error2 -= dx * 2
			}
		}
	} else {
		for x := _x0; x <= _x1; x += 1 {
			set_pixel(img, x, y, r, g, b)
			error2 += derror2
			if error2 > dx {
				y += y_step
				error2 -= dx * 2
			}
		}
	}
}

benchmark_draw_lines :: proc() {
	img := tga.Image{}
	img.width = 100
	img.height = 100
	img.channels = 3
	img.depth = 8
	img.pixels = bytes.Buffer {
		buf = make([dynamic]u8, img.width * img.height * 3),
	}
	for i in 0 ..< len(img.pixels.buf) {
		img.pixels.buf[i] = 255
	}

	start := time.now()
	for i in 0 ..< 100000 {
		draw_line(&img, 10, 10, 90, 90, 0, 0, 255)
	}
	elapsed1 := time.since(start)
	fmt.println("draw_line: ", elapsed1)

	start = time.now()
	for i in 0 ..< 10000 {
		draw_line2(&img, 10, 10, 90, 90, 0, 0, 255)
	}
	elapsed2 := time.since(start)
	fmt.println("draw_line2: ", elapsed2)
}

Vec2i :: struct {
	x, y: int,
}
