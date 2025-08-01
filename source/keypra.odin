package keypra

import "core:fmt"
import "core:os"
import "core:time"
import rl "vendor:raylib"

INITIAL_SPEED: f32 = 1
SPEED_INCREASE_STANDARD: f32 = 1.03
SPEED_INCREASE_PER_SECOND: f32 = 1.007

current_word: Word
speed: f32 = INITIAL_SPEED
current_score: Score
debug_mode := true
debug_message: cstring
rng: PCG32
font_size: f32 = 50
blink := false
game_over := false
game_over_hiscore_place: i32 = -1
pressed_rune: rune
last_pressed_rune: rune
last_pressed_rune_time: time.Time
last_pressed_rune_good: bool = true
last_timed_speed_increase: time.Time

main :: proc() {

	load_hiscore()
	init_game()
	init_debug()

	for should_run() {
		env: Environment = update_frame()
		draw_frame(env)
		free_all(context.temp_allocator)
	}
}

//used to set a game in a state for debugging specific part
init_debug :: proc() {
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

			if pressed_rune == next_word_char {
				last_pressed_rune_good = true
				current_score.score += 1
				current_word.correct_letters += 1
			} else {
				increase_difficulty()
				last_pressed_rune_good = false
				current_score.mistakes += 1
				blink = true
			}

			if current_word.correct_letters == current_word.goal_sentence.len {
				current_score.score += 1
				generate_word(&current_word)
				increase_difficulty()
			}
		}

		time_since_last_increase := time.diff(last_timed_speed_increase, time.now())
		if time_since_last_increase > time.Second {
			speed *= SPEED_INCREASE_PER_SECOND
			last_timed_speed_increase = time.now()
		}

		if i32(current_word.location.y) > env.window_size.y {
			game_over = true
			game_over_hiscore_place = try_add_score_hiscore(current_score)
		}
	}

	return env
}

draw_frame :: proc(env: Environment) {
	rl.BeginDrawing()
	if blink && !game_over {
		rl.ClearBackground(rl.Color{50, 0, 0, 255})
		blink = false
	} else {
		rl.ClearBackground(rl.Color{22, 22, 22, 255})
	}

	if game_over {
		draw_game_over(env)
	} else {
		draw_word(env)
		draw_game_stats(env)
	}

	if debug_mode {draw_debug(env)}
	rl.EndDrawing()
}

draw_game_stats :: proc(env: Environment) {
	s_current_score := fmt.ctprint(current_score.score)
	rl.DrawText("Score", env.window_size.x - 400, 30, 50, rl.GRAY)
	rl.DrawText(s_current_score, env.window_size.x - 200, 10, 100, rl.GREEN)

	s_current_mistakes := fmt.ctprint(current_score.mistakes)
	rl.DrawText("Mistakes", env.window_size.x - 467, 130, 50, rl.GRAY)
	rl.DrawText(s_current_mistakes, env.window_size.x - 200, 110, 100, rl.RED)
}

draw_game_over :: proc(env: Environment) {
	rl.DrawText("GAME OVER", 200, 100, 200, rl.ORANGE)
	rl.DrawText("SCORE", 200, 450, 100, rl.GRAY)
	rl.DrawText(fmt.ctprint(current_score.score), 850, 400, 250, rl.GREEN)
	rl.DrawText("MISTAKES", 200, 800, 100, rl.GRAY)
	rl.DrawText(fmt.ctprint(current_score.mistakes), 850, 750, 250, rl.MAROON)
	rl.DrawText("Press SPACE to restart", 400, 1250, 70, rl.BLUE)

	rl.DrawText("HISCORES", 1800, 100, 120, rl.SKYBLUE)
	rl.DrawText("SCORE", 1800, 220, 50, rl.GRAY)
	rl.DrawText("MISTAKES", 2150, 220, 50, rl.GRAY)

	for i: i32 = 0; i < len(hiscores); i += 1 {
		if hiscores[i].score >= 0 {
			score := fmt.ctprint(hiscores[i].score)
			mistakes := fmt.ctprint(hiscores[i].mistakes)
			y := 320 + 80 * i
			rl.DrawText(score, 1800, y, 70, rl.GREEN)
			rl.DrawText(mistakes, 2150, y, 70, rl.MAROON)

			if game_over_hiscore_place == i {
				rl.DrawText("you >", 1580, y, 70, rl.WHITE)
			}
		}
	}
}

increase_difficulty :: proc() {
	speed *= SPEED_INCREASE_STANDARD
	uppercase_weight = f32(current_score.score / 30)
	number_weight = f32(current_score.score / 60)
	special_weight = f32(current_score.score / 90)
}

initialize_level :: proc() {
	uppercase_weight = UPPERCASE_WEIGHT_INITIAL
	lowercase_weight = LOWERCASE_WEIGHT_INITIAL
	number_weight = NUMBERS_WEIGHT_INITIAL
	special_weight = SPECIAL_WEIGHT_INITIAL
	current_score = {}
	speed = INITIAL_SPEED
	current_word.location = {0, 0}
	current_word.correct_letters = 0
	game_over_hiscore_place = -1
	last_timed_speed_increase = time.now()
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

