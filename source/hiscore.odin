package keypra

import "core:os"

hiscore_file_path := "hiscore.txt"
hiscores: [10]u32

load_hiscore :: proc() {
	// TODO: load from file
}

save_hiscore :: proc() {
	// TODO: save to file
}

// If score made to the highscore table, adds it, saves the hiscore to file and returns a highscore index (0 is top score)
try_add_score :: proc(score: u32) -> i32 {

	for x: i32 = 0; x < len(hiscores); x += 1 {
		if score > hiscores[x] {

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

