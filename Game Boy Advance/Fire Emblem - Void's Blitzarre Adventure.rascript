function in_save_menu() {
    return proc_is(main_proc_ptr(3), "GAMECTRL")
    && proc_is(proc_first_child_ptr(main_proc_ptr(3)), "SaveMenu2")
}

dummy_achievement(title="Save Test", description="DUMMY", points=0, trigger=in_save_menu())

function in_player_phase_battle() {
    return proc_is(main_proc_ptr(2), "MapMain")
    && proc_is(proc_first_child_ptr(main_proc_ptr(2)), "PlayerPhase")
    && proc_is(proc_first_child_ptr(proc_first_child_ptr(main_proc_ptr(2))), "Battle")
}

// Just to be fancy...
function triangle_attack_test_with_proc() {
    return in_player_phase_battle()
    && first_attack_is_triangle_attack()
}

function battle_check_for_leaderboard() { //todo: pause in shops, map events EXCEPT sent to convoy, dialogue, 
    return  unless(proc_is(proc_first_child_ptr(main_proc_ptr(2)), "TerrainHealLoop"))
    &&      unless(proc_is(proc_first_child_ptr(main_proc_ptr(2)), "PhaseSwitchGfx"))
    &&      unless(proc_is(proc_first_child_ptr(proc_first_child_ptr(main_proc_ptr(2))), "Battle"))
    &&      unless(proc_is(proc_first_child_ptr(proc_first_child_ptr(main_proc_ptr(2))), "PromotionInit"))
    &&      unless(proc_is(proc_first_child_ptr(proc_first_child_ptr(main_proc_ptr(2))), "BattleAnimSimpleLock")) // Heal/Physic, etc.
    &&      unless(proc_is(proc_next_proc(proc_first_child_ptr(proc_first_child_ptr(main_proc_ptr(2)))), "BattleAnimSimpleLock")) // Warp, Berserk, etc.
    &&      unless(!in_player_phase())
}


dummy_achievement(title="Triangle Attack Test", description="DUMMY", points=0, trigger=triangle_attack_test_with_proc())

dummy_achievement(
    title = "Prologue Start",
    description = "stuffs",
    points = 0,
    trigger = chapter_just_started("Prologue")
)

leaderboard(
        title = "Test (todo: Add cheat protection)",
        description = "Prologue completion",
        start  = chapter_just_started("Prologue"),
        cancel = current_turn() < prev(current_turn()),
        submit = in_chapter("Prologue") && in_save_menu(),
        value  = measured(in_chapter("Prologue")),
        format = "FRAMES"
)

leaderboard(
    title = "DUMMY",
    description = "DUMMY",
    start = once(0==1) && battle_check_for_leaderboard(),
    cancel = always_false(),
    submit = always_true(),
    value = 0,
    format = "VALUE"
)

//I:0xW02ea78_I:0xW008018_P:0xX008000=140108552_I:0xW02ea78_I:0xW008018_P:0xX008000=140095360_I:0xW02ea78_I:0xW008018_I:0xW008018_P:0xX008000=140106428_I:0xW02ea78_I:0xW008018_I:0xW008018_P:0xX008000=145827532_I:0xW02ea78_I:0xW008018_I:0xW008018_P:0xX008000=140098244_I:0xW02ea78_I:0xW008018_I:0xW008018_I:0xW008020_P:0xX008000=140098244_P:0xH033cff!=0_

dummy_achievement(
    title = "Guiding Ring Test",
    description = "Obtain a Guiding ring anywhere",
    points = 0,
    trigger = disable_when(event_ids_set([CHEATING_EID+1])) && got_items_triggered_and_measured(["Guiding Ring", "Blue Gem"], "Chapter 12")
)