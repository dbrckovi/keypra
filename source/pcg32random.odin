package keypra

//PCG32 random number generator
PCG32 :: struct {
	state: u64,
	inc:   u64,
}

pcg32_init :: proc(seed: u64) -> PCG32 {
	rng := PCG32 {
		state = seed,
		inc   = 0x4d595df4d0f33173,
	}
	pcg32_next(&rng)
	return rng
}

pcg32_next :: proc(rng: ^PCG32) -> u32 {
	old_state := rng.state
	rng.state = old_state * 6364136223846793005 + rng.inc
	xorshifted := u32(((old_state >> 18) ~ old_state) >> 27)
	rot := u32(old_state >> 59)
	return (xorshifted >> rot) | (xorshifted << ((-rot) & 31))
}

pcg32_float :: proc(rng: ^PCG32) -> f32 {
	return f32(pcg32_next(rng)) / f32(0xffffffff)
}

pcg32_int_max :: proc(rng: ^PCG32, max: int) -> int {
	return int(pcg32_next(rng) % u32(max))
}

