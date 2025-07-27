package keypra

import "core:os"
import "core:path/filepath"

Score :: struct {
	score:    u32,
	mistakes: u32,
}

hiscore_file_path := "hiscore.txt"
hiscores: [10]Score

load_hiscore :: proc() {
	// TODO: load from file
}

save_hiscore :: proc() {

	// file, err := os.open(hiscore_file_path, os.O_WRONLY)
	// os.args

	// os.set_current_directory()
	// defer os.close(file)

	// TODO: save to file
}

get_absolute_hiscore_file_path :: proc() -> string {
	exe_dir := filepath.dir(os.args[0], context.temp_allocator)
	abs_dir, _ := filepath.abs(exe_dir, context.temp_allocator)
	return abs_dir
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

