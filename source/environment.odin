package keypra

import "core:math"
import rl "vendor:raylib"

//Holds window, frame and other data which might change each frame
Environment :: struct {
	frame_time:       f32,
	fps:              i32,
	window_size:      [2]i32,
	// window_scale_dpi: [2]f32,
}

//Returns data needed for updating and drawing each frame
get_environment_data :: proc() -> Environment {
	return {
		frame_time = rl.GetFrameTime(),
		fps = i32(math.ceil_f32(1 / rl.GetFrameTime())),
		window_size = {rl.GetRenderWidth(), rl.GetRenderHeight()},
		// window_scale_dpi = rl.GetWindowScaleDPI(),
	}
}

