package keypra

import "core:fmt"
import "core:time"
import rl "vendor:raylib"

INITIAL_SPEED: f32 = 1

current_word: Word
speed: f32 = INITIAL_SPEED
score: i32 = 0
debug_mode := true
debug_message: string
rng: PCG32
font_size: f32 = 50
blink := false
game_over_score: i32 = -1

main :: proc() {

	init_game()

	for should_run() {
		env: Environment = update_frame()
		draw_frame(env)
		free_all(context.temp_allocator)
	}
}

init_game :: proc() {
	rl.SetConfigFlags({.VSYNC_HINT, .WINDOW_RESIZABLE, .WINDOW_MAXIMIZED})
	rl.SetTargetFPS(60)
	rl.InitWindow(800, 600, "Forest")
	rl.MaximizeWindow()
	now := time.now()
	nanoseconds := time.time_to_unix_nano(now)
	rng = pcg32_init(u64(nanoseconds))
	initialize_level()
	generate_word(&current_word)
}

update_frame :: proc() -> Environment {
	env: Environment = get_environment_data()

	if game_over_score >= 0 {

		if rl.IsKeyPressed(rl.KeyboardKey.SPACE) {
			initialize_level()
			game_over_score = -1
		}

	} else {
		current_word.location.y += speed * env.frame_time
		char: rune = rl.GetCharPressed()

		if char != 0 {
			next_word_char := rune(current_word.goal_sentence.data[current_word.correct_letters])
			fmt.println("Pressed:", char, "Next:", next_word_char)

			if char == next_word_char {
				score += 1
				current_word.correct_letters += 1
			} else {
				increase_difficulty()
				blink = true
			}

			if current_word.correct_letters == current_word.goal_sentence.len {
				score += 1
				generate_word(&current_word)
				increase_difficulty()
			}
		}

		if i32(current_word.location.y) > env.window_size.y {
			game_over_score = score
		}
	}

	return env
}

draw_frame :: proc(env: Environment) {
	rl.BeginDrawing()
	if blink {
		rl.ClearBackground(rl.Color{255, 255, 0, 255})
		blink = false
	} else {
		rl.ClearBackground(rl.Color{22, 22, 22, 255})
	}

	if game_over_score >= 0 {
		draw_game_over(env)
	} else {
		draw_word(env)
	}

	if debug_mode {draw_debug(env)}
	rl.EndDrawing()
}

draw_game_over :: proc(env: Environment) {
	rl.DrawText("GAME OVER", i32(600), i32(300), i32(200), rl.ORANGE)
	rl.DrawText("SCORE", i32(600), i32(650), i32(150), rl.GRAY)
	rl.DrawText(fmt.ctprint(game_over_score), i32(1300), i32(600), i32(250), rl.YELLOW)
	rl.DrawText("Press SPACE to restart", i32(600), i32(900), i32(70), rl.GRAY)
}

increase_difficulty :: proc() {
	speed *= 1.04
}

initialize_level :: proc() {
	uppercase_weight = UPPERCASE_WEIGHT_INITIAL
	lowercase_weight = LOWERCASE_WEIGHT_INITIAL
	numbers_weight = NUMBERS_WEIGHT_INITIAL
	special_weight = SPECIAL_WEIGHT_INITIAL
	score = 0
	speed = INITIAL_SPEED
	current_word.location = {0, 0}
	current_word.correct_letters = 0
}

should_run :: proc() -> bool {
	when ODIN_OS != .JS {
		if rl.WindowShouldClose() {
			return false
		}
	}

	return true
}

