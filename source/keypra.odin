package keypra

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:time"
import rl "vendor:raylib"

INITIAL_SPEED: f32 = 1
SPEED_INCREASE_STANDARD: f32 = 1.03
SPEED_INCREASE_PER_SECOND: f32 = 1.007
NATIVE_RESOLUTION: [2]i32 = {1920, 1080}

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
main_font: rl.Font
virtual_texture: rl.RenderTexture2D

main :: proc() {

	load_hiscore()
	init_game()

	for should_run() {
		env: Environment = update_frame()
		draw_frame(env)
		free_all(context.temp_allocator)
	}
}

init_game :: proc() {
	exe_path := os.args[0]
	exe_dir := filepath.dir(string(exe_path), context.temp_allocator)
	os.set_current_directory(exe_dir)

	rl.SetConfigFlags({.VSYNC_HINT, .WINDOW_RESIZABLE, .WINDOW_MAXIMIZED})
	rl.SetTargetFPS(60)
	rl.InitWindow(NATIVE_RESOLUTION.x, NATIVE_RESOLUTION.y, "Keypra")
	rl.MaximizeWindow()
	virtual_texture = rl.LoadRenderTexture(NATIVE_RESOLUTION.x, NATIVE_RESOLUTION.y)
	rl.SetTextureFilter(virtual_texture.texture, rl.TextureFilter.TRILINEAR)
	main_font = rl.LoadFontEx("font.ttf", 32, nil, 0)

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

		if i32(current_word.location.y) > NATIVE_RESOLUTION.y {
			game_over = true
			game_over_hiscore_place = try_add_score_hiscore(current_score)
		}
	}

	return env
}

draw_frame :: proc(env: Environment) {
	// Draw world to texture
	rl.BeginTextureMode(virtual_texture)

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

	rl.EndTextureMode()

	// Draw texture to screen
	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)
	virtual_w := 1920
	virtual_h := 1080
	scale := min(f32(env.window_size.x) / f32(virtual_w), f32(env.window_size.y) / f32(virtual_h))
	dest_w := i32(f32(virtual_w) * scale)
	dest_h := i32(f32(virtual_h) * scale)
	offset_x := (env.window_size.x - dest_w) / 2
	offset_y := (env.window_size.y - dest_h) / 2

	rl.DrawTexturePro(
		virtual_texture.texture,
		rl.Rectangle{0, 0, f32(virtual_w), -f32(virtual_h)},
		rl.Rectangle{f32(offset_x), f32(offset_y), f32(dest_w), f32(dest_h)},
		rl.Vector2{0, 0},
		0,
		rl.WHITE,
	)

	rl.EndDrawing()
}

draw_game_stats :: proc(env: Environment) {
	s_current_score := fmt.ctprint(current_score.score)
	rl.DrawText("Score", NATIVE_RESOLUTION.x - 607, 30, 50, rl.GRAY)
	rl.DrawText(s_current_score, NATIVE_RESOLUTION.x - 340, 10, 100, rl.GREEN)

	s_current_mistakes := fmt.ctprint(current_score.mistakes)
	rl.DrawText("Mistakes", NATIVE_RESOLUTION.x - 607, 130, 50, rl.GRAY)
	rl.DrawText(s_current_mistakes, NATIVE_RESOLUTION.x - 340, 110, 100, rl.RED)

	s_speed := fmt.ctprintf("%.3f", speed)
	rl.DrawText("Speed", NATIVE_RESOLUTION.x - 607, 230, 50, rl.GRAY)
	rl.DrawText(s_speed, NATIVE_RESOLUTION.x - 340, 210, 100, rl.WHITE)

	total_weight := lowercase_weight + uppercase_weight + number_weight + special_weight
	s_lowercase := fmt.ctprintf("%.2f %%", lowercase_weight / total_weight * 100)
	s_uppercase := fmt.ctprintf("%.2f %%", uppercase_weight / total_weight * 100)
	s_number := fmt.ctprintf("%.2f %%", number_weight / total_weight * 100)
	s_special := fmt.ctprintf("%.2f %%", special_weight / total_weight * 100)

	rl.DrawText("Probabilities", NATIVE_RESOLUTION.x - 607, 400, 50, rl.BLUE)

	rl.DrawText("Lowercase", NATIVE_RESOLUTION.x - 607, 470, 35, rl.GRAY)
	rl.DrawText(s_lowercase, NATIVE_RESOLUTION.x - 340, 470, 35, rl.WHITE)

	rl.DrawText("Uppercase", NATIVE_RESOLUTION.x - 607, 520, 35, rl.GRAY)
	rl.DrawText(s_uppercase, NATIVE_RESOLUTION.x - 340, 520, 35, rl.WHITE)

	rl.DrawText("Numbers", NATIVE_RESOLUTION.x - 607, 570, 35, rl.GRAY)
	rl.DrawText(s_number, NATIVE_RESOLUTION.x - 340, 570, 35, rl.WHITE)

	rl.DrawText("Special", NATIVE_RESOLUTION.x - 607, 620, 35, rl.GRAY)
	rl.DrawText(s_special, NATIVE_RESOLUTION.x - 340, 620, 35, rl.WHITE)
}

draw_game_over :: proc(env: Environment) {
	rl.DrawText("GAME OVER", 100, 50, 100, rl.ORANGE)
	rl.DrawText("SCORE", 100, 225, 50, rl.GRAY)
	rl.DrawText(fmt.ctprint(current_score.score), 425, 200, 125, rl.GREEN)
	rl.DrawText("MISTAKES", 100, 400, 50, rl.GRAY)
	rl.DrawText(fmt.ctprint(current_score.mistakes), 425, 375, 125, rl.MAROON)
	rl.DrawText("Press SPACE to restart", 200, 625, 35, rl.BLUE)

	rl.DrawText("HISCORES", 1000, 50, 60, rl.SKYBLUE)
	rl.DrawText("SCORE", 1000, 125, 25, rl.GRAY)
	rl.DrawText("MISTAKES", 1185, 125, 25, rl.GRAY)

	for i: i32 = 0; i < len(hiscores); i += 1 {
		if hiscores[i].score >= 0 {
			score := fmt.ctprint(hiscores[i].score)
			mistakes := fmt.ctprint(hiscores[i].mistakes)
			y := 175 + 40 * i
			rl.DrawText(score, 1000, y, 35, rl.GREEN)
			rl.DrawText(mistakes, 1185, y, 35, rl.MAROON)

			if game_over_hiscore_place == i {
				rl.DrawText("you >", 890, y, 35, rl.WHITE)
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

