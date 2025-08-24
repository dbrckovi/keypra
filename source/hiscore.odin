package keypra

Score :: struct {
	score:    u32,
	mistakes: u32,
}

hiscores: [10]Score

load_hiscore :: proc() {
	when ODIN_OS != .JS {
		load_hiscore_desktop()
	}
}

save_hiscore :: proc() {
	when ODIN_OS != .JS {
		save_hiscore_desktop()
	}
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

