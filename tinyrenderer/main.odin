package main

import clay "./clay/bindings/odin/clay-odin"
import "core:bytes"
import "core:fmt"
import "core:image"
import "core:image/tga"

import "core:math"
import "core:math/linalg/glsl"

import "core:time"

Color :: struct {
	r, g, b: u8,
}
Vec4f :: glsl.vec4
Vec3f :: glsl.vec3
Vec2f :: glsl.vec2
Mat4 :: glsl.mat4

main :: proc() {

	start := time.now()

	tgasave()

	// benchmark_draw_lines()

	elapsed := time.since(start)
	fmt.printf("Main execution time: %v\n", elapsed)
}

tgasave :: proc() {
	img := tga.Image{}
	img.width = 800
	img.height = 800
	img.channels = 3 // RGB
	img.depth = 8 // 8 bits per channel
	img.pixels = bytes.Buffer {
		buf = make([dynamic]u8, img.width * img.height * 3),
	}
	for i in 0 ..< len(img.pixels.buf) {
		img.pixels.buf[i] = 0 // Set all pixels to white
	}

	set_pixel(&img, 10, 10, Color{255, 0, 0})

	draw_line(&img, nil, [2]Vec3f{Vec3f{10, 10, 0}, Vec3f{90, 90, 0}}, Color{0, 0, 255})

	t0 := Vec3f{10, 10, 0}
	t1 := Vec3f{50, 80, 0}
	t2 := Vec3f{90, 20, 0}

	pts := [3]Vec3f{Vec3f{10, 10, 0.5}, Vec3f{50, 80, 0.7}, Vec3f{90, 20, 0.2}}

	zbuffer := make([dynamic]f32, img.width * img.height)
	for i in 0 ..< len(zbuffer) {
		zbuffer[i] = -math.INF_F32
	}

	// drawTriangleFilled(pts, &zbuffer, &img, 0, 255, 0)
	// drawTriangle(pts, &img, 255, 0, 0)

	assetpath := "assets/diablo3_pose.obj"
	texturepath := "assets/diablo3_pose_diffuse.tga"

	texture, err := tga.load_from_file(texturepath)
	if err != nil {
		fmt.panicf("%v", err)
	}

	light := &Vec3f{0, 0, 1}

	model := load_model(assetpath)

	renderModel(
		model,
		&img,
		texture,
		&zbuffer,
		true,
		light,
		Vec3f{.5, .5, 1},
		Vec3f{0, 400, 0},
		&Color{200, 150, 250},
		false,
	)
	renderModel(
		model,
		&img,
		texture,
		&zbuffer,
		false,
		light,
		Vec3f{.5, .5, 1},
		Vec3f{400, 400, 0},
		&Color{200, 150, 250},
		false,
	)
	renderModel(
		model,
		&img,
		nil,
		&zbuffer,
		true,
		light,
		Vec3f{.5, .5, 1},
		Vec3f{0, 0, 0},
		&Color{200, 150, 250},
		false,
	)
	renderModel(
		model,
		&img,
		texture,
		&zbuffer,
		true,
		light,
		Vec3f{1, 1, 1},
		// Vec3f{.5, .5, 1},
		Vec3f{200, -200, 1.5},
		&Color{200, 150, 250},
		true,
	)

	flip_image_vertical(&img)
	err = tga.save_to_file("hello.tga", &img)
	fmt.println(err)
}
