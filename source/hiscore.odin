package keypra

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strconv"
import "core:strings"

Score :: struct {
	score:    u32,
	mistakes: u32,
}

hiscore_file_path := "hiscore.txt"
hiscores: [10]Score

load_hiscore :: proc() {
	file_path := get_absolute_hiscore_file_path()
	if os.exists(file_path) {
		fmt.println("Loading from", file_path)

		data, ok := os.read_entire_file(file_path)
		if !ok {
			fmt.println("Error reading hiscore file!")
			return
		}

		lines := strings.split_lines(string(data))
		for i in 0 ..< len(hiscores) {
			if i >= len(lines) || strings.trim_space(lines[i]) == "" {
				break
			}

			parts := strings.split(lines[i], ",")
			if len(parts) != 2 {
				fmt.println("Invalid hiscore line:", lines[i])
				continue
			}

			score_val := strconv.atoi(strings.trim_space(parts[0]))
			mistake_val := strconv.atoi(strings.trim_space(parts[1]))

			hiscores[i] = Score{u32(score_val), u32(mistake_val)}
		}
	}
}


// load_hiscore :: proc() {
// 	file_path := get_absolute_hiscore_file_path()
// 	if os.exists(file_path) {
// 		fmt.println("Saving to", file_path)
// 		// TODO: load from file
// 	}
// }

save_hiscore :: proc() {
	file_path := get_absolute_hiscore_file_path()
	fmt.println("Saving to", file_path)
	file, err := os.open(file_path, os.O_WRONLY | os.O_CREATE | os.O_TRUNC, 0o644)

	if err != nil {
		fmt.println("Error saving hiscores!", err)
		return
	}

	for score in hiscores {
		line := fmt.aprintf(
			"%d,%d\n",
			score.score,
			score.mistakes,
			allocator = context.temp_allocator,
		)
		_, err := os.write_string(file, line)

		if err != nil {
			fmt.println("Error writing hiscore line to file", err)
			return
		}
	}

	defer os.close(file)
}

get_absolute_hiscore_file_path :: proc() -> string {
	exe_dir := filepath.dir(os.args[0], context.temp_allocator)
	abs_dir, _ := filepath.abs(exe_dir, context.temp_allocator)
	return fmt.aprintf("%s/%s", abs_dir, hiscore_file_path, allocator = context.temp_allocator)
}

// If score made to the highscore table, adds it, saves the hiscore to file and returns a highscore index (0 is top score)
try_add_score_hiscore :: proc(score: Score) -> i32 {

	for x: i32 = 0; x < len(hiscores); x += 1 {
		if score.score > hiscores[x].score {

			for y: i32 = len(hiscores) - 2; y >= x; y -= 1 {
				hiscores[y + 1] = hiscores[y]
			}

			hiscores[x] = score

			save_hiscore()

			return x
		}
	}

	return -1
}

