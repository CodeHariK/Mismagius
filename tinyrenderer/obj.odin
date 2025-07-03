package main

import "core:fmt"
import "core:image/tga"
import "core:os"
import "core:strconv"

Vec2 :: [2]f32
Vec3 :: [3]f32

Model_Data :: struct {
	vertex_positions:  []Vec3,
	vertex_normals:    []Vec3,
	vertex_uvs:        []Vec2,
	indices_positions: []i32,
	indices_normals:   []i32,
	indices_uvs:       []i32,
}

free_model_data :: proc(using model_data: Model_Data) {
	// free(vertex_positions)
	// free(vertex_normals)
	// free(vertex_uvs)
	// free(indices_positions)
	// free(indices_normals)
	// free(indices_uvs)
}

print_model_data :: proc(using model_data: Model_Data, N: int) {
	for i := 0; i < N; i += 1 {
		v := model_data.vertex_positions[i]
		fmt.printf("v[%d]: %v\n", i, v)
	}
	for i := 0; i < N; i += 1 {
		v := model_data.vertex_normals[i]
		fmt.printf("vn[%d]: %v\n", i, v)
	}
	for i := 0; i < N; i += 1 {
		v := model_data.vertex_uvs[i]
		fmt.printf("vt[%d]: %v\n", i, v)
	}
	for i := 0; i < N; i += 1 {
		fmt.printf(
			"fv[%d]: %d %d %d\n",
			i,
			model_data.indices_positions[3 * i + 0],
			model_data.indices_positions[3 * i + 1],
			model_data.indices_positions[3 * i + 2],
		)
	}
	for i := 0; i < N; i += 1 {
		fmt.printf(
			"fvn[%d]: %d %d %d\n",
			i,
			model_data.indices_normals[3 * i + 0],
			model_data.indices_normals[3 * i + 1],
			model_data.indices_normals[3 * i + 2],
		)
	}
	for i := 0; i < N; i += 1 {
		fmt.printf(
			"fvt[%d]: %d %d %d\n",
			i,
			model_data.indices_uvs[3 * i + 0],
			model_data.indices_uvs[3 * i + 1],
			model_data.indices_uvs[3 * i + 2],
		)
	}
}

stream: string

is_whitespace :: #force_inline proc(c: u8) -> bool {
	switch c {
	case ' ', '\t', '\n', '\v', '\f', '\r', '/':
		return true
	}
	return false
}

skip_whitespace :: #force_inline proc() #no_bounds_check {
	for stream != "" && is_whitespace(stream[0]) do stream = stream[1:]
}

skip_line :: proc() #no_bounds_check {
	N := len(stream)
	for i := 0; i < N; i += 1 {
		if stream[0] == '\r' || stream[0] == '\n' {
			skip_whitespace()
			return
		}
		stream = stream[1:]
	}
}

next_word :: proc() -> string #no_bounds_check {
	skip_whitespace()

	for i := 0; i < len(stream); i += 1 {
		if is_whitespace(stream[i]) || i == len(stream) - 1 {
			current_word := stream[0:i]
			stream = stream[i + 1:]
			return current_word
		}
	}
	return ""
}

// @WARNING! This assumes the obj file is well formed. 
//
//   Each v, vn line has to have at least 3 elements. Every element after the third is discarded
//   Each vt line has to have at least 2 elements. Every element after the second is discarded
//   Each f line has to have at least 9 elements. Every element after the ninth is discarded
//
//   Note that we only support files where the faces are specified as A/A/A B/B/B C/C/C
//   Note also that '/' is regarded as whitespace, to simplify the face parsing
read_obj :: proc(filename: string) -> (Model_Data, bool) #no_bounds_check {
	to_f32 :: proc(str: string) -> f32 {
		value, _ := strconv.parse_f32(str)
		return value
	}
	to_i32 :: proc(str: string) -> i32 {
		value, _ := strconv.parse_int(str)
		return cast(i32)value
	}

	data, status := os.read_entire_file(filename)
	if !status do return Model_Data{}, false
	// defer free(data)

	vertex_positions: [dynamic]Vec3
	vertex_normals: [dynamic]Vec3
	vertex_uvs: [dynamic]Vec2
	indices_positions: [dynamic]i32
	indices_normals: [dynamic]i32
	indices_uvs: [dynamic]i32

	stream = string(data)
	for stream != "" {
		current_word := next_word()

		switch current_word {
		case "v":
			append(
				&vertex_positions,
				Vec3{to_f32(next_word()), to_f32(next_word()), to_f32(next_word())},
			)
		case "vn":
			append(
				&vertex_normals,
				Vec3{to_f32(next_word()), to_f32(next_word()), to_f32(next_word())},
			)
		case "vt":
			append(&vertex_uvs, Vec2{to_f32(next_word()), to_f32(next_word())})
		case "f":
			indices: [9]i32
			for i := 0; i < 9; i += 1 {
				indices[i] = to_i32(next_word()) - 1
			}
			append(&indices_positions, indices[0], indices[3], indices[6])
			append(&indices_normals, indices[1], indices[4], indices[7])
			append(&indices_uvs, indices[2], indices[5], indices[8])
		}
		skip_line()
	}

	fmt.printf(
		"vertex positions = %d, vertex normals = %d, vertex uvs = %d\n",
		len(vertex_positions),
		len(vertex_normals),
		len(vertex_uvs),
	)
	fmt.printf(
		"indices positions = %d, indices normals = %d, indices uvs = %d\n",
		len(indices_positions),
		len(indices_normals),
		len(indices_uvs),
	)

	return Model_Data {
			vertex_positions[:],
			vertex_normals[:],
			vertex_uvs[:],
			indices_positions[:],
			indices_normals[:],
			indices_uvs[:],
		},
		true
}


render_wireframe :: proc(model: Model_Data, img: ^tga.Image, color: [3]u8) {
	// Simple orthographic projection: just use x and y, scale to image size
	scale_x := f32(img.width) / 30.0
	scale_y := f32(img.height) / 30.0
	offset_x := f32(img.width) / 2.0
	offset_y := f32(img.height) / 10.0

	num_faces := len(model.indices_positions) / 3
	for i := 0; i < num_faces; i += 1 {
		// Get indices for this triangle
		i0 := model.indices_positions[3 * i + 0]
		i1 := model.indices_positions[3 * i + 1]
		i2 := model.indices_positions[3 * i + 2]

		// Get vertex positions
		v0 := model.vertex_positions[i0]
		v1 := model.vertex_positions[i1]
		v2 := model.vertex_positions[i2]

		// Project to 2D (orthographic, assuming model is centered in [-1,1])
		p0 := Vec2i {
			x = int(v0[0] * scale_x + offset_x),
			y = int(v0[1] * scale_y + offset_y),
		}
		p1 := Vec2i {
			x = int(v1[0] * scale_x + offset_x),
			y = int(v1[1] * scale_y + offset_y),
		}
		p2 := Vec2i {
			x = int(v2[0] * scale_x + offset_x),
			y = int(v2[1] * scale_y + offset_y),
		}

		// Draw triangle edges
		draw_line(img, p0.x, p0.y, p1.x, p1.y, color[0], color[1], color[2])
		draw_line(img, p1.x, p1.y, p2.x, p2.y, color[0], color[1], color[2])
		draw_line(img, p2.x, p2.y, p0.x, p0.y, color[0], color[1], color[2])
	}
}
