package keypra

import "core:fmt"
import "core:strings"
import "core:time"
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

LOWERCASE_WEIGHT_INITIAL: f32 = 20
UPPERCASE_WEIGHT_INITIAL: f32 = 0
NUMBERS_WEIGHT_INITIAL: f32 = 0
SPECIAL_WEIGHT_INITIAL: f32 = 0

lowercase_weight: f32 = LOWERCASE_WEIGHT_INITIAL
uppercase_weight: f32 = UPPERCASE_WEIGHT_INITIAL
number_weight: f32 = NUMBERS_WEIGHT_INITIAL
special_weight: f32 = SPECIAL_WEIGHT_INITIAL

FixedString :: struct {
	data: [30]u8,
	len:  u32,
}

Word :: struct {
	goal_sentence:   FixedString,
	location:        [2]f32,
	correct_letters: u32,
}

get_max_length :: proc() -> u32 {
	max_length := 3 + current_score.score / 50
	if max_length > 30 {max_length = 30}
	return max_length
}

generate_word :: proc(word: ^Word) {
	for x: u32 = 0; x < get_max_length(); x += 1 {
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

	total_weight := lowercase_weight + uppercase_weight + number_weight + special_weight

	lowercase_value := lowercase_weight / total_weight
	uppercase_value := uppercase_weight / total_weight + lowercase_value
	number_value := number_weight / total_weight + uppercase_value
	special_value := special_weight / total_weight + number_value

	if type_value <= lowercase_value {
		char_source = &lowercase
	} else if type_value <= uppercase_value {
		char_source = &uppercase
	} else if type_value <= number_value {
		char_source = &numbers
	} else {
		char_source = &special
	}

	index := pcg32_int_max(&rng, len(char_source))
	ret: u8 = char_source[index] // no cast needed
	s := fmt.ctprintf("%r", ret)

	fmt.println(
		"Type value:",
		type_value,
		", Lowercase value:",
		lowercase_value,
		", Uppercase value:",
		uppercase_value,
		", Number value:",
		number_value,
		", Special value:",
		special_value,
		", Selected:",
		s,
	)

	return ret
}

draw_word :: proc(env: Environment) {

	duration := time.diff(last_pressed_rune_time, time.now())

	dur_ms := time.duration_milliseconds(duration)
	if dur_ms < 1000 {
		alpha := 255 - dur_ms / 4
		color: rl.Color
		if last_pressed_rune_good {color = {128, 128, 128, u8(alpha)}} else {color = {128, 0, 0, u8(alpha)}}
		rl.DrawText(fmt.ctprint(last_pressed_rune), i32(1300), i32(600), i32(400), color)
	}

	text: string = string(current_word.goal_sentence.data[:current_word.goal_sentence.len])

	for x := 0; x < len(text); x += 1 {
		character := fmt.ctprint(text[x:x + 1])

		color: rl.Color = UPPERCASE_COLOR
		if current_word.correct_letters > u32(x) {color = CORRECT_COLOR} else {
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

