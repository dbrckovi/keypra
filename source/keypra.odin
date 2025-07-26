package keypra

import "core:fmt"
import "core:time"
import rl "vendor:raylib"

INITIAL_SPEED: f32 = 1

current_word: Word
speed: f32 = INITIAL_SPEED
score: i32 = 0
mistakes: i32 = 0
debug_mode := true
debug_message: cstring
rng: PCG32
font_size: f32 = 50
blink := false
game_over := false
pressed_rune: rune
last_pressed_rune: rune
last_pressed_rune_time: time.Time

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
}

update_frame :: proc() -> Environment {
	env: Environment = get_environment_data()

	if game_over {

		if rl.IsKeyPressed(rl.KeyboardKey.SPACE) {
			initialize_level()
			game_over = false
		}

	} else {
		current_word.location.y += speed * env.frame_time
		pressed_rune = rl.GetCharPressed()

		if pressed_rune != 0 {
			last_pressed_rune = pressed_rune
			last_pressed_rune_time = time.now()
			next_word_char := rune(current_word.goal_sentence.data[current_word.correct_letters])
			fmt.println("Pressed:", pressed_rune, "Next:", next_word_char)

			if pressed_rune == next_word_char {
				score += 1
				current_word.correct_letters += 1
			} else {
				increase_difficulty()
				mistakes += 1
				blink = true
			}

			if current_word.correct_letters == current_word.goal_sentence.len {
				score += 1
				generate_word(&current_word)
				increase_difficulty()
			}
		}

		if i32(current_word.location.y) > env.window_size.y {
			game_over = true
			try_add_score(u32(score))
		}
	}

	return env
}

draw_frame :: proc(env: Environment) {
	rl.BeginDrawing()
	if blink && !game_over {
		rl.ClearBackground(rl.Color{255, 255, 0, 255})
		blink = false
	} else {
		rl.ClearBackground(rl.Color{22, 22, 22, 255})
	}

	if game_over {
		draw_game_over(env)
	} else {
		draw_word(env)
	}

	if debug_mode {draw_debug(env)}
	rl.EndDrawing()
}

draw_game_over :: proc(env: Environment) {
	rl.DrawText("GAME OVER", i32(600), i32(300), i32(200), rl.ORANGE)
	rl.DrawText("SCORE", i32(600), i32(650), i32(100), rl.GRAY)
	rl.DrawText(fmt.ctprint(score), i32(1300), i32(600), i32(250), rl.GREEN)
	rl.DrawText("MISTAKES", i32(600), i32(900), i32(100), rl.GRAY)
	rl.DrawText(fmt.ctprint(mistakes), i32(1300), i32(850), i32(250), rl.MAROON)
	rl.DrawText("Press SPACE to restart", i32(600), i32(1250), i32(70), rl.BLUE)

	// TODO: Draw hiscore
}

increase_difficulty :: proc() {
	speed *= 1.04
	uppercase_weight = f32(score / 20)
	number_weight = f32(score / 30)
	special_weight = f32(score / 40)
}

initialize_level :: proc() {
	uppercase_weight = UPPERCASE_WEIGHT_INITIAL
	lowercase_weight = LOWERCASE_WEIGHT_INITIAL
	number_weight = NUMBERS_WEIGHT_INITIAL
	special_weight = SPECIAL_WEIGHT_INITIAL
	score = 0
	mistakes = 0
	speed = INITIAL_SPEED
	current_word.location = {0, 0}
	current_word.correct_letters = 0
	generate_word(&current_word)
}

should_run :: proc() -> bool {
	when ODIN_OS != .JS {
		if rl.WindowShouldClose() {
			return false
		}
	}

	return true
}

