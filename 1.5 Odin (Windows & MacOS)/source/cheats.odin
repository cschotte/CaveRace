package caverace

// Cheat_Key is domain input shared by platform polling, queued gameplay input,
// and fixed-tick results. Platform key codes are mapped separately in input.odin.
Cheat_Key :: enum {
	F1,
	F2,
	F3,
	F4,
	F5,
}

// apply_gameplay_cheat preserves the 1.2 powerblast effects while keeping
// their mutations in one deterministic gameplay procedure. Bomb power is
// capped because explosion storage is deliberately fixed to that safe limit.
apply_gameplay_cheat :: proc(gameplay: ^Gameplay, cheat: Cheat_Key) {
	tuning := gameplay_tuning(gameplay.difficulty)
	switch cheat {
	case .F1:
		for &enemy in enemy_slots(gameplay) {
			enemy.active = false
		}
	case .F2:
		gameplay.player.lives = tuning.player_max_lives
		gameplay.player.energy = tuning.player_max_energy
	case .F3:
		gameplay.player.bomb_capacity = tuning.player_max_bomb_capacity
	case .F4:
		if gameplay.player.bomb_power < tuning.player_max_bomb_power {
			gameplay.player.bomb_power += 1
		}
	case .F5:
		if gameplay.player.score > max(int) / 2 {
			gameplay.player.score = max(int)
		} else {
			gameplay.player.score *= 2
		}
	}
}
