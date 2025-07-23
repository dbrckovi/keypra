package keypra

import "core:fmt"
import "core:time"
import rl "vendor:raylib"

current_word: Word
speed: f32 = 0.01
max_length: i32 = 3
score: i32 = 0
max_words: int = 1
debug_mode := true
debug_message: string
rng: PCG32
font_size: f32 = 30

main :: proc() {

	init()

	for should_run() {
		env: Environment = update()
		draw(env)
		free_all(context.temp_allocator)
	}
}

init :: proc() {
	rl.SetConfigFlags({.VSYNC_HINT, .WINDOW_RESIZABLE, .WINDOW_MAXIMIZED})
	rl.SetTargetFPS(60)
	rl.InitWindow(800, 600, "Forest")
	rl.MaximizeWindow()
	now := time.now()
	nanoseconds := time.time_to_unix_nano(now)
	rng = pcg32_init(u64(nanoseconds))
	generate_word(&current_word)
}

update :: proc() -> Environment {
	env: Environment = get_environment_data()

	current_word.location.y += speed
	char: rune = rl.GetCharPressed()

	if char != 0 {
		next_word_char := rune(current_word.goal_sentence.data[current_word.correct_letters])
		fmt.println("Pressed:", char, "Next:", next_word_char)

		if char == next_word_char {
			fmt.println("MATCH")
			current_word.correct_letters += 1
		} else {
			increase_difficulty()
		}

		if current_word.correct_letters == current_word.goal_sentence.len {
			score += 1
			generate_word(&current_word)
			increase_difficulty()
		}
	}

	return env
}

draw :: proc(env: Environment) {
	rl.BeginDrawing()
	rl.ClearBackground(rl.Color{22, 22, 22, 22})

	draw_word(env)

	if debug_mode {draw_debug(env)}
	rl.EndDrawing()
}

increase_difficulty :: proc() {
	speed *= 1.1
}

should_run :: proc() -> bool {
	when ODIN_OS != .JS {
		if rl.WindowShouldClose() {
			return false
		}
	}

	return true
}

