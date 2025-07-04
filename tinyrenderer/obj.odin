package main

import "core:fmt"
import "core:image/tga"
import "core:math"
import "core:math/rand"
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

render_wireframe :: proc(
	using model: Model_Data,
	img: ^tga.Image,
	zbuffer: ^[dynamic]f32,
	color: ^[3]u8,
) {
	// Simple orthographic projection: just use x and y, scale to image size
	scale_x := f32(img.width) / 30.0
	scale_y := f32(img.height) / 30.0
	offset_x := f32(img.width) / 2.0
	offset_y := f32(img.height) / 10.0

	// Light direction (normalized)
	light_dir := [3]f32{0, 0, -1.4}

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

		// Compute face normal (cross product of two edges)
		edge1 := [3]f32{v1[0] - v0[0], v1[1] - v0[1], v1[2] - v0[2]}
		edge2 := [3]f32{v2[0] - v0[0], v2[1] - v0[1], v2[2] - v0[2]}
		normal := [3]f32 {
			edge1[1] * edge2[2] - edge1[2] * edge2[1],
			edge1[2] * edge2[0] - edge1[0] * edge2[2],
			edge1[0] * edge2[1] - edge1[1] * edge2[0],
		}
		// Normalize normal
		norm_len := math.sqrt(
			normal[0] * normal[0] + normal[1] * normal[1] + normal[2] * normal[2],
		)
		if norm_len > 0 {
			normal[0] /= norm_len
			normal[1] /= norm_len
			normal[2] /= norm_len
		}

		// Dot product with light direction
		intensity := normal[0] * light_dir[0] + normal[1] * light_dir[1] + normal[2] * light_dir[2]
		if intensity < 0 {
			intensity = 0
		}

		// Project to 2D and keep z for depth
		p0 := Vec3f {
			x = v0[0] * scale_x + offset_x,
			y = v0[1] * scale_y + offset_y,
			z = v0[2],
		}
		p1 := Vec3f {
			x = v1[0] * scale_x + offset_x,
			y = v1[1] * scale_y + offset_y,
			z = v1[2],
		}
		p2 := Vec3f {
			x = v2[0] * scale_x + offset_x,
			y = v2[1] * scale_y + offset_y,
			z = v2[2],
		}

		// Choose color: use provided or random, then scale by intensity
		c := [3]u8{0, 0, 0}
		if color != nil {
			c = color^
		} else {
			c = [3]u8{u8(rand.int63_max(255)), u8(rand.int63_max(255)), u8(rand.int63_max(255))}
		}
		shaded := [3]u8 {
			u8(clamp(f32(c[0]) * intensity, 0, 255)),
			u8(clamp(f32(c[1]) * intensity, 0, 255)),
			u8(clamp(f32(c[2]) * intensity, 0, 255)),
		}

		if (zbuffer != nil) {
			drawTriangleFilledZ(
				[3]Vec3f{p0, p1, p2},
				zbuffer,
				img,
				shaded[0],
				shaded[1],
				shaded[2],
			)
		} else {
			drawTriangleFilled([3]Vec3f{p0, p1, p2}, img, shaded[0], shaded[1], shaded[2])
		}
	}
}

clamp :: proc(x, min, max: f32) -> f32 {
	if x < min {return min}
	if x > max {return max}
	return x
}
