package keypra

import "core:fmt"
import rl "vendor:raylib"

DEBUG_BACK_COLOR := rl.Color{22, 22, 22, 155}
DEBUG_FORE_COLOR := rl.Color{255, 255, 255, 150}
DEBUG_FONT_SIZE: i32 : 15
DEBUG_PADDING :: 3

//Draws debug panel
draw_debug :: proc(env: Environment) {

	//bottom panel
	debug_height := i32(font_size) + 2 * DEBUG_PADDING

	rl.DrawRectangle(
		0,
		env.window_size.y - debug_height,
		env.window_size.x,
		env.window_size.y,
		DEBUG_BACK_COLOR,
	)

	message: cstring = fmt.ctprintf(
		"Score: %d Mistakes: %d    Speed: %.3f     %s",
		current_score.score,
		current_score.mistakes,
		speed,
		debug_message,
	)

	rl.DrawText(
		message,
		DEBUG_PADDING,
		env.window_size.y - debug_height + DEBUG_PADDING,
		i32(font_size),
		DEBUG_FORE_COLOR,
	)
}

