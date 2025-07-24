package keypra

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

LOWERCASE_COLOR: rl.Color : {200, 120, 120, 255}
UPPERCASE_COLOR: rl.Color : {255, 120, 120, 255}
NUMBERS_COLOR: rl.Color : {180, 255, 120, 255}
SPECIAL_COLOR: rl.Color : {180, 120, 255, 255}
CORRECT_COLOR: rl.Color : {70, 70, 80, 255}
lowercase := "qwertzuiopasdfghjklyxcvbnm"
uppercase := "QWERTZUIOPASDFGHJKLYXCVBNM"
numbers := "1234567890"
special := "~!\"#$%&/()=?*'+{}[]<>,.-;:_\\|"
lowercase_weight: f32 = 0.9
uppercase_weight: f32 = 0
numbers_weight: f32 = 0.95
special_weight: f32 = 1

FixedString :: struct {
	data: [30]u8,
	len:  i32,
}

Word :: struct {
	goal_sentence:   FixedString,
	location:        [2]f32,
	correct_letters: i32,
}

get_max_length :: proc() -> i32 {
	max_length := 3 + score / 100
	if max_length > 30 {max_length = 30}
	return max_length
}

generate_word :: proc(word: ^Word) {
	for x: i32 = 0; x < get_max_length(); x += 1 {
		char := generate_next_char()
		word.goal_sentence.data[x] = char
	}
	word.goal_sentence.len = get_max_length()

	word.location = {0, 0}
	word.correct_letters = 0
}

generate_next_char :: proc() -> u8 {
	char_source: ^string
	type_value := pcg32_float(&rng)

	if type_value <= lowercase_weight {
		char_source = &lowercase
	} else if type_value <= uppercase_weight {
		char_source = &uppercase
	} else if type_value <= numbers_weight {
		char_source = &numbers
	} else {
		char_source = &special
	}

	index := pcg32_int_max(&rng, len(char_source))
	ret: u8 = char_source[index] // no cast needed

	fmt.println("Source: ", char_source^)
	fmt.println("Index: ", index)
	fmt.println("Char: ", ret, " ('", rune(ret), "')") // print as char

	return ret
}

draw_word :: proc(env: Environment) {
	text: string = string(current_word.goal_sentence.data[:current_word.goal_sentence.len])

	for x := 0; x < len(text); x += 1 {
		character := fmt.ctprint(text[x:x + 1])

		color: rl.Color = UPPERCASE_COLOR
		if current_word.correct_letters > i32(x) {color = CORRECT_COLOR} else {
			if strings.contains(
				lowercase,
				string(character),
			) {color = LOWERCASE_COLOR} else if strings.contains(uppercase, string(character)) {color = UPPERCASE_COLOR} else if strings.contains(numbers, string(character)) {color = NUMBERS_COLOR} else {color = SPECIAL_COLOR}
		}

		rl.DrawText(
			character,
			i32(current_word.location.x + font_size * 0.8 * env.window_scale_dpi.x * f32(x)),
			i32(current_word.location.y),
			i32(font_size * env.window_scale_dpi.x),
			color,
		)
	}
}

