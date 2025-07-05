package main

import "core:bytes"
import "core:math"

import "core:fmt"
import "core:image"
import "core:image/tga"

import "core:time"

set_pixel :: proc(img: ^tga.Image, _x, _y: f32, color: Color) {
	x := int(_x)
	y := int(_y)

	// Bounds check
	if x < 0 || x >= img.width || y < 0 || y >= img.height {
		return
	}
	index := (y * img.width + x) * img.channels
	img.pixels.buf[index + 0] = color.r
	img.pixels.buf[index + 1] = color.g
	img.pixels.buf[index + 2] = color.b
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

draw_line :: proc(img: ^tga.Image, zbuffer: ^[dynamic]f32, pts: [2]Vec3f, color: Color) {
	x0 := int(pts[0].x)
	y0 := int(pts[0].y)
	z0 := pts[0].z
	x1 := int(pts[1].x)
	y1 := int(pts[1].y)
	z1 := pts[1].z

	dx := abs(x1 - x0)
	dy := abs(y1 - y0)
	sx := 1
	if x0 > x1 {sx = -1}
	sy := 1
	if y0 > y1 {sy = -1}
	err := dx - dy

	x := x0
	y := y0
	n := max(abs(x1 - x0), abs(y1 - y0))
	for i := 0;; i += 1 {
		t := (0.0) if n == 0 else (f32(i) / f32(n))
		z := z0 * (1.0 - t) + z1 * t

		if (zbuffer != nil) {
			idx := x + y * img.width
			if idx >= 0 && idx < len(zbuffer) && zbuffer[idx] < z {
				zbuffer[idx] = z
				set_pixel(img, f32(x), f32(y), color)
			}
		} else {
			set_pixel(img, f32(x), f32(y), color)
		}

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

draw_line2 :: proc(img: ^tga.Image, zbuffer: ^[dynamic]f32, pts: [2]Vec3f, color: Color) {
	_x0 := pts[0].x
	_y0 := pts[0].y
	_z0 := pts[0].z
	_x1 := pts[1].x
	_y1 := pts[1].y
	_z1 := pts[1].z

	steep := false
	if abs(_x0 - _x1) < abs(_y0 - _y1) {
		tmp := _x0;_x0 = _y0;_y0 = tmp
		tmp = _x1;_x1 = _y1;_y1 = tmp
		steep = true
	}
	if _x0 > _x1 {
		tmp := _x0;_x0 = _x1;_x1 = tmp
		tmp = _y0;_y0 = _y1;_y1 = tmp
		tmpf := _z0;_z0 = _z1;_z1 = tmpf
	}
	dx := _x1 - _x0
	dy := _y1 - _y0
	derror2 := abs(dy) * 2
	error2 := f32(0)
	y := _y0
	y_step := f32(1)
	if _y1 < _y0 {
		y_step = -1
	}
	n := max(abs(int(_x1 - _x0)), abs(int(_y1 - _y0)))
	for i := 0; _x0 + f32(i) <= _x1; i += 1 {
		t := (0.0) if n == 0 else (f32(i) / f32(n))
		z := _z0 * (1.0 - t) + _z1 * t
		ix := int(_x0 + f32(i))
		iy := int(y)
		if steep {
			ix, iy = iy, ix
		}

		if (zbuffer != nil) {
			idx := ix + iy * img.width
			if idx >= 0 && idx < len(zbuffer) && zbuffer[idx] < z {
				zbuffer[idx] = z
				set_pixel(img, f32(ix), f32(iy), color)
			}
		} else {
			set_pixel(img, f32(ix), f32(iy), color)
		}
		error2 += derror2
		if error2 > dx {
			y += y_step
			error2 -= dx * 2
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
		draw_line(&img, nil, [2]Vec3f{Vec3f{10, 10, 0}, Vec3f{90, 90, 0}}, Color{0, 0, 255})
	}
	elapsed1 := time.since(start)
	fmt.println("draw_line: ", elapsed1)

	start = time.now()
	for i in 0 ..< 10000 {
		draw_line2(&img, nil, [2]Vec3f{Vec3f{10, 10, 0}, Vec3f{90, 90, 0}}, Color{0, 0, 255})
	}
	elapsed2 := time.since(start)
	fmt.println("draw_line2: ", elapsed2)
}
