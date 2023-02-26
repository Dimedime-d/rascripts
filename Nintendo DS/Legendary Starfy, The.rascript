// Legendary Starfy, The
// #ID = 9119

// -----
// UTILS
// -----

function mem_in(mem, arr) { // Credit: gde_00
    cond = always_false()
    for el in arr
        cond = cond || (mem == el)
    return cond
}

function just_increased(mem) => mem > prev(mem)

function just_changed(mem, from, to) => prev(mem) == from && mem == to
function just_changed_to(mem, to) => prev(mem) != to && mem == to
function just_changed_from(mem, from) => prev(mem) == from && mem != from

function sum_dword_be(mem) => byte(mem) * 0x1000000 + byte(mem+1) * 0x10000 + byte(mem+2) * 0x100 + byte(mem+3)

function get_bit(addr, bit) {
    bit__mems = {
        0: bit0(addr),
        1: bit1(addr),
        2: bit2(addr),
        3: bit3(addr),
        4: bit4(addr),
        5: bit5(addr),
        6: bit6(addr),
        7: bit7(addr)
    }
    return bit__mems[bit]
}

function sum_contiguous_bits(addr, num_bits) {
    sum = 0
    for i in range(1, num_bits / 8)
    {
        sum = sum + bitcount(addr + i - 1)
    }
    remaining_bits = num_bits % 8
    if (remaining_bits % 8 != 0) //partial bitcount if needed
    {
        last_addr = addr + num_bits / 8
        if remaining_bits <= 4 {
            for j in range(0, remaining_bits - 1)
            {
                sum = sum + get_bit(last_addr, j) 
                // simplify this to a subsource + bitcount in some cases, once the new helper functions come out
            }
        }
        else {
            sum = sum + bitcount(last_addr) - bit7(last_addr)
            if remaining_bits <= 6 {sum = sum - bit6(last_addr)}
            if remaining_bits <= 5 {sum = sum - bit5(last_addr)}
        }
    }
    return sum
}

// Ex: 15th bit after addr gives bit6 of addr+1
function get_offset_bit(addr, bit) {
    return get_bit(addr + bit/8, bit%8)
}

function sum_discrete_bits(addr, bit_list) {
    sum = 0
    for bit in bit_list{
        sum = sum + get_offset_bit(addr, bit)
    }
    return sum
}

function frames(minutes, seconds)
{
    frames_per_second = 60
    return (minutes * 60 + seconds) * frames_per_second
}

// -------
// STRUCTS
// -------

object__struct = {
    "huff status":      0x90,  // byte
    "status":           0x9C, // byte
    "timer value":      0xEC, // dword
    "misc value":       0xF0, // dword
    "behavior address": 0x10C // dword
}
object__sizeof = 0x114

function struct_field(struct_def, base, field) => base + struct_def[field]
function object_field(base, field) => struct_field(object__struct, base, field)

// -------
// OBJECTS
// -------

behavior_address__values = {
    "Big Bossdown Timer":   0x02039054,
    "Misc Counter":         0x02180C68,
    "Hurdle":               0x0218AA1C,
    "Misc Counter 2":       0x0218C3F4,
    "Huffinfluff":          0x02194C74
}

function object_is(addr, name) => dword(object_field(addr, "behavior address")) == behavior_address__values[name]

// object specific
function object_bossdown_timer_is_active(addr) => byte(object_field(addr, "status")) == 1
function object_bossdown_timer_current_time(addr) => dword(object_field(addr, "timer value"))
function object_bossdown_timer_time_passed(addr) => just_increased(object_bossdown_timer_current_time(addr))

function object_misc_counter_value(addr) => dword(object_field(addr, "timer value"))
function object_misc_counter_2_value(addr) => dword(object_field(addr, "misc value"))

function object_hurdle_is_destroyed(addr) => byte(object_field(addr, "status")) == 2

function object_huffinfluff_woke_up(addr) => just_changed(byte(object_field(addr, "huff status")), 4, 5)

// ------------
// OBJECT ARRAY
// ------------

object_array__addr = 0x1F0E14

function nth_array_object(index) => object_array__addr + (index * object__sizeof)

function array_object_is(index, name) => object_is(nth_array_object(index), name)

function array_object_bossdown_timer_is_active(index)   => object_bossdown_timer_is_active(nth_array_object(index))
function array_object_bossdown_timer_current_time(index) => object_bossdown_timer_current_time(nth_array_object(index))
function array_object_bossdown_timer_time_passed(index) => object_bossdown_timer_time_passed(nth_array_object(index))

function array_object_misc_counter_value(index) => object_misc_counter_value(nth_array_object(index))
function array_object_misc_counter_2_value(index) => object_misc_counter_2_value(nth_array_object(index))

function array_object_hurdle_is_destroyed(index) => object_hurdle_is_destroyed(nth_array_object(index))

function array_object_huffinfluff_woke_up(index) => object_huffinfluff_woke_up(nth_array_object(index))

object_indexes = {
    "Bossdown Timers": [10, 11, 12, 13, 14, 15, 18]
}

// Game States

game_state__addr            = 0x1C03D4
story_cartoon__addr         = 0x1C03DC
game_state_transition__addr = 0x1C03EC

game_state__values = {
    "Coin Slinger"      : 0x04,
    "Fishing Derby"     : 0x05,
    "Sand Tracer"       : 0x06,
    "Depth Chargers"    : 0x07,
    "Minigame Select"   : 0x08,
    "Dumpling Master"   : 0x09,
    "Starting Up"       : 0x0A,
    "Starfy Dance"      : 0x0C,
    "Abilities"         : 0x0D,
    "Collection"        : 0x0E,
    "Journal"           : 0x0F,
    "File Select"       : 0x10,
    "Game Over"         : 0x11,
    "Suspend Save"      : 0x13,
    "Configure Buttons" : 0x14,
    "Moe's Case"        : 0x15,
    "World Map"         : 0x16,
    "Stage Map"         : 0x17,
    "Notes"             : 0x18,
    "Paused"            : 0x19,
    "Sea Jams"          : 0x1A,
    "Title Screen"      : 0x1B,
    "Toys"              : 0x1C,
    "Toy Collection"    : 0x1D,
    "Stuff"             : 0x1F,
    "Story Cartoon"     : 0x20,
    "RPS Battle"        : 0x21,
    "Story Select"      : 0x22,
    "Credits"           : 0x23,
    "Bossdown Results"  : 0x24,
    "Play Area"         : 0x26,
    "Local Wireless"    : 0x27
}

story_cartoon__values = {
    "Missing Chapter"       : 0x19,
    "Starly Bossdown Ending": 0x25
}

function in_game() => !(game_state_is("Starting Up") || game_state_is("File Select") || game_state_is("Title Screen") || game_state__mem() >= 0x27)

function game_state__mem() => dword(game_state__addr)
function game_state_is(name) => game_state__mem() == game_state__values[name]
function game_state_just_changed(from_name, to_name) =>
    just_changed(game_state__mem(), game_state__values[from_name], game_state__values[to_name])
    
function game_state_transition__mem() => dword(game_state_transition__addr)
function game_state_transitioning_to(name) => game_state_transition__mem() == game_state__values[name]

function story_cartoon__mem() => byte(story_cartoon__addr)
function in_story_cartoon(name) => game_state_is("Story Cartoon") && story_cartoon__mem() == story_cartoon__values[name]

// ------
// MEMORY
// ------

stage__addr = 0x1C03DA
function stage__mem() => byte(stage__addr)
area__addr  = 0x1C03D9
function area__mem() => byte(area__addr)
room__addr  = 0x1C03D8
function room__mem() => byte(room__addr)
function minigame_difficulty__mem() => byte(room__addr)

minigame_difficulty__values = {
    "Easy":     0,
    "Normal":   1,
    "Hard":     2,
}

level_pearl__addr = 0x19A5A8
function level_pearl__mem() => word(level_pearl__addr)

function in_water() => bit2(0x19A5E0) != 0
function on_ground() => bit6(0x19A5E0) != 0

anim__addr = 0x19A616
function anim__mem() => word(anim__addr)

anim__values = {
    "Shooting Star Start"   : 0x33,
    "Holding Chest"         : 0x3D
}

function anim_is(name) => anim__mem() == anim__values[name]

current_health__addr = 0x19A5A4
function current_health__mem() => byte(current_health__addr)
max_health__addr    = 0x19A5A6
function max_health__mem() => byte(max_health__addr)

function is_minigame_difficulty(diff) => minigame_difficulty__mem() == minigame_difficulty__values[diff]

function area_start(stage, area) => game_state_just_changed("Stage Map", "Play Area") && stage__mem() == stage && area__mem() == area && room__mem() == 1
function area_exit() => game_state_is("Game Over") || game_state_is("Starting Up") || game_state_is("Stage Map")
function in_room(stage, area, room) => stage__mem() == stage && area__mem() == area && room__mem() == room
function in_room_bossdown_transition() => in_room(4, 1, 6)

function reached_goal() => just_changed_to(byte(0x19A629), 6) && just_changed_to(byte(0x19A64C), 4)

boss_health__addr = 0x1E1988
function boss_health__mem() => word(boss_health__addr)

boss_max_health__addr = 0x1E198A
function boss_max_health__mem() => word(boss_max_health__addr)

function boss_active() => boss_max_health__mem() == 10

// Give some time for other memory to initialize (ex: Starfy vs Starly)
function boss_fight_just_started() => just_changed(boss_health__mem(), 9, 10)
function boss_defeat(deltas) {
    cond = always_false()
    for num in deltas {
        cond = cond || prev(boss_health__mem()) == num
    }
    cond = cond && boss_health__mem() == 0
    return cond
}

char__addr = 0x19A5AE
function char__mem() => byte(char__addr)
char__values = {
    "Starfy"    : 0x00,
    "Starly"    : 0x0B
}
function char_is(name) => char__mem() == char__values[name]

tf__addr = 0x19A62C
function tf__mem() => byte(tf__addr)
tf__values = {
    "None":         0,
    "Monstar":      1,
    "Starpedo":     2,
    "Roostar":      3,
    "Starfright":   4
}
function tf_is(name) => tf__mem() == tf__values[name]
function tf_just_changed(from_name, to_name) => just_changed(tf__mem(), tf__values[from_name], tf__values[to_name])

function in_water() => bit2(0x19A5E0) != 0

active_collision__addr = 0x19A5C0
function active_collision__mem() => dword(active_collision__addr)

function fadeout_no_control() => active_collision__mem() == 0xFF
function entering_door() => active_collision__mem() == 0x10
function in_cutscene() => active_collision__mem() == 0x13
function in_controllable_mine_car() => active_collision__mem() == 0x22
function was_spin_attacking() => prior(active_collision__mem()) == 3 || prior(active_collision__mem()) == 4 || prior(active_collision__mem()) == 5
function enemy_pushback() => !was_spin_attacking() && active_collision__mem() == 0x0C

function exited_cutscene_only_npc() => just_changed_from(active_collision__mem(), 0x13)

quiz_room__conds = [in_room(11, 4, 13), in_room(12, 3, 10), in_room(13, 2, 6), in_room(14, 4, 6),
                    in_room(15, 4, 6),  in_room(16, 3, 1) , in_room(17, 2, 5), in_room(18, 2, 12)]            
text_pointer__addr = 0x1E7994
function text_pointer__mem() => dword(text_pointer__addr)
quiz_completion__values = [0x023DC2C0, 0x023DD790, 0x023DC8C0, 0x023DC500,
                           0x023DD680, 0x023DC8E0, 0x023DD560, 0x023DD890]
                           
quiz_completion_tally = []
for i in range(0, 7)
{
    array_push(quiz_completion_tally, once(in_cutscene() && quiz_room__conds[i] && text_pointer__mem() == quiz_completion__values[i]))
}

achievement (
    title = "Quiz Master",
    description = "Find Moe's Family in each of the first 8 stages and answer all of their quizzes correctly! [One Session]",
    points = 5,
    trigger = measured(tally(8, quiz_completion_tally))
)

pufftop_legend_room__conds = [in_room(9, 1, 4), in_room(9, 2, 4), in_room(9, 4, 1), in_room(9, 5, 6), in_room(9, 7, 4)]

pufftop_legend_tally = []
for room_cond in pufftop_legend_room__conds {
    //must talk to each guard twice to listen to their story
    array_push(pufftop_legend_tally, repeated(2, room_cond && exited_cutscene_only_npc()))
}

achievement(
    title = "Legends of Pufftop",
    description = "Find the 5 Pufftop Guards with stories to tell and listen to all of them [One Session] (talk to each one twice)",
    points = 5,
    trigger = measured(tally(10, pufftop_legend_tally))
)

konk_room__conds = [in_room(9, 3, 8), in_room(9, 4, 9), in_room(9, 7, 5)]

konk_tally = []
for room_cond in konk_room__conds {
    array_push(konk_tally, once(room_cond && just_changed(boss_health__mem(), 1, 0)))
}

achievement(
    title = "All KONKed Out",
    description = "Find and defeat Konk at 3 separate locations in Pufftop! [One Session]",
    points = 5,
    trigger = measured(tally(3, konk_tally))
)

achievement(
    title = "Three Lost Heart Gems",
    description = "Increase your maximum hearts for the first time",
    points = 2,
    trigger = game_state_is("Play Area") && just_changed(max_health__mem(), 5, 6)
)

achievement(
    title = "All the Blue Chests",
    description = "Find all 15 Heart Gems",
    points = 5,
    trigger = game_state_is("Play Area") && just_changed(max_health__mem(), 9, 10)
)

control_bits__values = {
    "A":        0,
    "B":        1,
    "Select":   2,
    "Start":    3,
    "R":        8,
    "L":        9,
    "X":        10,
    "Y":        11
}

control_bit__addr = 0x19A636
function control_button_set(btn) => get_offset_bit(control_bit__addr, control_bits__values[btn]) != 0

// Fine, let's do boss challenges

function no_damage() => never(current_health__mem() < prev(current_health__mem()))

// first visits, re-visists, Pufftop, and Bossdown
boss_room__conds = {
    "Big Squiddy":          (in_room(1, 4, 8) || in_room(11, 4, 8) || in_room(1, 4, 10)                    ),
    "Hot-Spring Snapper":   (in_room(2, 4, 9) || in_room(12, 4, 9) || in_room(2, 1, 8)                     ),
    "King Ping":            (in_room(3, 4, 10)|| in_room(13, 4, 10)|| in_room(3, 4, 9)                     ),
    "Papes":                (in_room(4, 4, 10)|| in_room(14, 4, 10)|| in_room(4, 1, 5) || in_room(9, 3, 7) ),
    "Ronk":                 (in_room(5, 3, 5) || in_room(15, 3, 5) || in_room(5, 3, 10)|| in_room(9, 4, 8) ),
    "Train":                (in_room(5, 4, 2) || in_room(15, 4, 2)                                         ),
    "Snips":                (in_room(6, 4, 10)|| in_room(16, 4, 10)|| in_room(6, 1, 6) || in_room(9, 5, 9) ),
    "Terrible Trio":        (in_room(7, 4, 6) || in_room(17, 4, 6) || in_room(7, 1, 7) || in_room(9, 6, 6) ),
    "Mashtooth":            (in_room(8, 4, 7) || in_room(18, 4, 7) || in_room(8, 1, 5)                     ),
    "Mega Mashtooth":       (in_room(8, 4, 9) || in_room(18, 4, 9) || in_room(8, 1, 6)                     
                            || in_room(8, 4, 12) || in_room(18, 4, 12) || in_room(8, 1, 7)),
    "Old Man Lobber":       (in_room(10, 7, 3)                                                             ) 
}

bosses = {
    "Big Squiddy": {"title": "Steady Squiddy Fight", "description": "Defeat Big Squiddy without taking damage or using the B Button", "points": 5,
        "conds": (no_damage() && never(control_button_set("B"))), "health deltas": [1]},
    "Hot-Spring Snapper": {"title": "Always Vulnerable", "description":  "Defeat the Hot-Spring Snapper in only 5 hits and without using the Shooting Star ability", "points": 5,
        "conds": never(high4(boss_health__addr) == 0 && bit0(boss_health__addr) != 0 || anim_is("Shooting Star Start")), "health deltas": [2]},
    "King Ping": {"title": "Icebreaker", "description": "Defeat King Ping without taking damage", "points": 5,
        "conds": no_damage(), "health deltas": [1, 2, 3, 4]},
    "Papes": {"title": "Wrestle for His Shield", "description": "Defeat Papes without taking damage or getting pushed back by him", "points": 5,
        "conds": (no_damage() && never(enemy_pushback())), "health deltas": [1, 2]},
    "Ronk": {"title": "Waterless Mode", "description": "Defeat Ronk without swimming", "points": 5,
        "conds": never(in_water()), "health deltas": [1, 2]},
    "Train": {"title": "Flawless Mine Car Battle", "description": "Defeat Papes and Ronk on the train without taking damage", "points": 5,
        "conds": no_damage(), "health deltas": [1]},
    "Snips": {"title": "Tennis Exhibition", "description": "Defeat Snips without taking damage", "points": 5,
        "conds": no_damage(), "health deltas": [2]},
    "Terrible Trio": {"title": "They're Still Not That Threatening", "description": "Defeat the Terrible Trio without taking damage", "points": 5,
        "conds": no_damage(), "health deltas": [1]},
    "Mashtooth": {"title": "Top Space Pirate", "description": "Defeat Mashtooth's first form without taking damage", "points": 5,
        "conds": no_damage(), "health deltas": [1, 2]},
    "Old Man Lobber": {"title": "Living Legend", "description": "Defeat Old Man Lobber without taking damage", "points": 10,
        "conds": no_damage(), "health deltas": [1]}
}

for name in bosses {
    achievement(
        title = bosses[name]["title"],
        description = bosses[name]["description"],
        points = bosses[name]["points"],
        trigger = unless(game_state_is("Paused") || game_state_is("Abilities")) && game_state_is("Play Area") && boss_room__conds[name] && once(boss_fight_just_started()) && bosses[name]["conds"]
            && never(area_exit()) && trigger_when(boss_defeat(bosses[name]["health deltas"]))
    )
}

// Special bosses

achievement(
    title = "Not so Unlimited Power",
    description = "Defeat Mega Mashtooth without taking damage or getting a Game Over",
    points = 10,
    trigger = unless(game_state_is("Paused") || game_state_is("Abilities") || game_state_is("Configure Buttons") || game_state_is("Journal") || game_state_is("Stuff") || game_state_is("Suspend Save")) 
        && boss_room__conds["Mega Mashtooth"] && once(boss_fight_just_started())
        && no_damage() && never(area_exit()) && never(game_state_is("Moe's Case")) && never(game_state_is("Bossdown Results")) 
        && trigger_when(once(boss_defeat([1])) && game_state_just_changed("Play Area", "Story Cartoon"))
)

rps_battle_boss_health__addr = 0x1D0750
rps_battle_player_health__addr = 0x1D0751

function rps_battle_boss_health__mem() => byte(rps_battle_boss_health__addr)
function rps_battle_player_health__mem() => byte(rps_battle_player_health__addr)

achievement(
    title = "The Uncoordinated Trio",
    description = "Win a round of rock paper scissors against the Terrible Trio without losing",
    points = 3,
    trigger = game_state_is("RPS Battle") && rps_battle_player_health__mem() == 3 && trigger_when(just_changed(rps_battle_boss_health__mem(), 2, 0))
)

// ---------
// SAVE DATA
// ---------

file_data__addr = 0x8FD74

function file_offset(offset) => tbyte(file_data__addr) + offset

shop_bits_from_offset = [3, 6, 9, 12, 14, 16, 21, 24, 27, 30, 32, 34]

stage_10_records__arr = [0]
for i in range(0, 6) {
    array_push(stage_10_records__arr, sum_dword_be(file_offset(0xF5 + i*4)))
}

bossdown_splits__arr = [0]
for i in range(0, 8) {
    array_push(bossdown_splits__arr, sum_dword_be(file_offset(0xB5 + i*4)))
}

file_data__mems = {
    "Transformations"           : sum_discrete_bits(file_offset(0x0A), [4, 5, 6, 7, 8, 9, 10, 11]),
    "Side Quests"               : sum_contiguous_bits(file_offset(0x25), 24),
    "Toys"                      : sum_contiguous_bits(file_offset(0x56), 127),
    "Heart Gems"                : sum_contiguous_bits(file_offset(0x76), 15),
    "Stuff"                     : sum_contiguous_bits(file_offset(0x78), 36),
    "Specials"                  : (sum_discrete_bits(file_offset(0x7C), range(4, 7))
        + bitcount(file_offset(0x7D)) + sum_discrete_bits(file_offset(0x7E), range(0, 5))),
    "Shop"                      : sum_discrete_bits(file_offset(0x78), shop_bits_from_offset),
    "Bossdown Current Split"    : byte(file_offset(0xAC)),
    "Bossdown Split Times"      : bossdown_splits__arr,
    "Notes"                     : sum_contiguous_bits(file_offset(0xEA), 56),
    "Stage 10 Current Time"     : sum_dword_be(file_offset(0xF1)),
    "Stage 10 Records List"     : stage_10_records__arr,
    "Bossdown Transition Split" : byte(file_offset(0x10D)),
}

function room_flags__addr(room) => file_offset(0x140 + 0x40 * (room - 1))

achievement(
    title = "Every Figurine Friend and Foe",
    description = "Obtain all 127 Toys",
    points = 25,
    trigger = game_state_is("Toys") && measured(file_data__mems["Toys"] == 127, prev(file_data__mems["Toys"]) <= 126 && in_game())
)

achievement(
    title = "Funded Retirement",
    description = "Buy everything from Moe's Shop",
    points = 10,
    trigger = game_state_is("Moe's Case") && measured(file_data__mems["Shop"] == length(shop_bits_from_offset),
        when = prev(file_data__mems["Shop"]) <= length(shop_bits_from_offset) - 1 && in_game())
)

achievement(
    title = "Just Another Errand",
    description = "Complete your first Side Quest",
    points = 1,
    trigger = game_state_is("Play Area") && file_data__mems["Side Quests"] == 1
        && prev(file_data__mems["Side Quests"]) == 0
)

achievement(
    title = "All the Secret Areas",
    description = "Complete all 24 Side Quests",
    points = 10,
    trigger = game_state_is("Play Area") && measured(file_data__mems["Side Quests"] == 24,
        when = prev(file_data__mems["Side Quests"]) <= 23 && in_game())
)

achievement(
    title = "Stylish Star",
    description = "Match some Clothing and Extras to unlock all 18 Special Stuff!",
    points = 5,
    trigger = game_state_is("Stuff") && measured(file_data__mems["Specials"] == 18,
        when = prev(file_data__mems["Specials"]) <= 17 && in_game())
)

function file_chests() {
    return sum_discrete_bits(file_offset(0x0A), range(5, 11, 1)) + file_data__mems["Heart Gems"]
    + file_data__mems["Stuff"] - file_data__mems["Shop"] + file_data__mems["Notes"]
}

chest_hunt = {
    26:  {"title":"Notes, Stuff, Stones, and Heart Gems", "fdescription":"Find {0} out of 102 treasure chests", "points":5},
    51:  {"title":"How Did These Get Here?", "fdescription":"Find {0} out of 102 treasure chests", "points":10},
    76:  {"title":"Sniffing Out Loot", "fdescription":"Find {0} out of 102 treasure chests", "points":10},
    102: {"title":"All Clear", "fdescription":"Find all 102 treasure chests", "points":25}
}

for chests in chest_hunt{
    achievement(
        title = chest_hunt[chests]["title"],
        description = format(chest_hunt[chests]["fdescription"], chests),
        points  = chest_hunt[chests]["points"],
        trigger = game_state_is("Play Area") && measured(file_chests() == chests, prev(file_chests()) <= chests - 1 && in_game())
    )
}

areas_per_stage = 7
function area_complete__mem(stage, area) {
    return get_offset_bit(file_offset(0x11), (stage-1)*areas_per_stage + (area-1))
}

stage_complete = {
    1: {"title":"Hunt for Crystal Shards", "stage_name":"Gluglug Lagoon", "points":5},
    2: {"title":"Restoring Some Memories", "stage_name":"Hotcha Springs", "points":5},
    3: {"title":"Bunston Bounty", "stage_name":"Chillydip Cove", "points":5},
    4: {"title":"Chasing Some Goons", "stage_name":"Sogwood Forest", "points":5},
    5: {"title":"Quest to Repair the Spaceship", "stage_name":"Glitzem Grotto", "points":5},
    6: {"title":"Intel on the Last Shard", "stage_name":"Skydye Heights", "points":5},
    7: {"title":"The Ship is Complete", "stage_name":"S.S. Logwater", "points":5},
}

for stage in stage_complete{
    achievement(
        title = stage_complete[stage]["title"],
        description = format("Clear {0} during the main story", stage_complete[stage]["stage_name"]),
        points = stage_complete[stage]["points"],
        trigger = just_increased(area_complete__mem(stage, 4)) && game_state_is("Story Cartoon")
    )
}

// Slightly different timing
achievement(
    title = "Peace to this Galaxy",
    description = "Defeat Mashtooth (for good).",
    points = 10,
    // trigger = once(just_increased(area_complete__mem(8, 4))) && game_state_is("Credits") && never(game_state_is("Title Screen"))
    trigger = boss_room__conds["Mega Mashtooth"] && game_state_just_changed("Play Area", "Story Cartoon")
)

achievement(
    title = "Bunston's Past",
    description = "Defeat Mashtooth with all area secrets cleared and watch the Missing Chapter after the credits!",
    points = 10,
    trigger = once(game_state_is("Credits")) && in_story_cartoon("Missing Chapter") && never(game_state_is("Title Screen"))
)

achievement(
    title = "Starly's Adventure",
    description = "Fight off the Terrible Trio at Pufftop!",
    points = 5,
    trigger = game_state_is("Play Area") && in_room(9, 6, 6) && just_changed(boss_health__mem(), 1, 0)
)


// ~~~~~~~~~~~~
// Big Bossdown
// ~~~~~~~~~~~~

function big_bossdown_start() => once(game_state_just_changed("Moe's Case", "Play Area")) && never(big_bossdown_cancel())
function big_bossdown_cancel() => game_state_is("Moe's Case")
function big_bossdown_finish() => just_changed(file_data__mems["Bossdown Current Split"], 8, 9)

function bossdown_transition_timer_pause() => prev(file_data__mems["Bossdown Transition Split"]) == file_data__mems["Bossdown Current Split"] 
    && in_room_bossdown_transition()
    
function bossdown_sum_all_splits(){
    sum = 0
    for i in range(1, 8) {
        sum = sum + file_data__mems["Bossdown Split Times"][i]
    }
    return sum
}
    

// Leaderboard value, which I manually changed all alt groups (S) to maxof operators ($) and moved each measuredif in front of the measured
// (Also removed the core group and all measured targets (9001))
function timer_cond_measured() {
    cond = always_false()
    for timer_index in object_indexes["Bossdown Timers"] {
        cond = cond || measured(array_object_bossdown_timer_current_time(timer_index) == 9001,
            array_object_is(timer_index, "Big Bossdown Timer"))
    }
    return cond
}

leaderboard(
    title = "Big Bossdown (Starfy)",
    description = "Fastest Time",
    start = big_bossdown_start() && boss_fight_just_started() && char_is("Starfy"),
    cancel = big_bossdown_cancel(),
    submit = big_bossdown_finish(),
    value = 0
)

leaderboard(
    title = "Big Bossdown (Starly)",
    description = "Fastest Time",
    start = big_bossdown_start() && boss_fight_just_started() && char_is("Starly"),
    cancel = big_bossdown_cancel(),
    submit = big_bossdown_finish(),
    value = 0
)

function bossdown_timer_threshold_passed(frames)
{
    cond = always_false()
    for timer_index in object_indexes["Bossdown Timers"] {
        cond = cond || (array_object_is(timer_index, "Big Bossdown Timer") 
            && just_changed(array_object_bossdown_timer_current_time(timer_index), frames-1, frames))
    }
    return cond
    //Timer seems to rewind a few frames between each boss transition, but the last segment is long enough
    //such that this rewind wouldn't matter for false resets
}

function in_big_bossdown() {
    cond = always_false()
    for timer_index in object_indexes["Bossdown Timers"] {
        cond = cond || (array_object_is(timer_index, "Big Bossdown Timer"))
    }
    return cond && game_state_is("Play Area")
}

bossdown_time_attack = {
    0: {"title": "Stage 10 Unlocked!", "points": 10, "minutes": 9},
    1: {"title": "Bossdown Blitz", "points": 10, "minutes": 7},
    2: {"title": "Shoot the Moon", "points": 25, "minutes": 5},
}

for key in bossdown_time_attack {
    achievement(
        title = bossdown_time_attack[key]["title"],
        description = format("Complete Big Bossdown in under {0} minutes", bossdown_time_attack[key]["minutes"]),
        points = bossdown_time_attack[key]["points"],
        //trigger = big_bossdown_start() && never(bossdown_timer_threshold_passed(frames(bossdown_time_attack[key]["minutes"], 0))) && trigger_when(big_bossdown_finish())
        
        trigger = game_state_is("Bossdown Results") && file_data__mems["Bossdown Current Split"] == 9 && bossdown_sum_all_splits() < frames(bossdown_time_attack[key]["minutes"], 0)
    )
}

achievement(
    title = "Pink Powder Keg",
    description = "Complete Big Bossdown with Starly and watch her ending!",
    points = 10,
    trigger = big_bossdown_start() && once(boss_fight_just_started() && char_is("Starly")) && in_story_cartoon("Starly Bossdown Ending")
)

// ~~~~~~~~~~~~~~~~~~~~
// Stage 10 Time Attack
// ~~~~~~~~~~~~~~~~~~~~

function time_attack_cancel() => area_exit()

for i in range(1, 6) {
    leaderboard(
	    title = format("10-{0} Time Attack", i),
		description = format("Complete Stage 10-{0} as fast as possible", i),
		start = area_start(10, i),
		cancel = time_attack_cancel(),
		submit = reached_goal(),
		value = file_data__mems["Stage 10 Current Time"],
		format = "FRAMES"
	)
}

// 10-7 boss
leaderboard(
    title = "10-7 Time Attack",
    description = "Defeat Old Man Lobber in Stage 10-7 as fast as possible",
    start = game_state_is("Play Area") && in_room(10, 7, 3) && just_changed(room__mem(), 2, 3),
    cancel = time_attack_cancel(),
    submit = game_state_is("Play Area") && just_changed(boss_health__mem(), 1, 0),
    value = dword(0x1F1464),
    format = "FRAMES"
)

time_attack_limits = {1:frames(0, 45), 2:frames(2, 20), 3:frames(3, 50), 
    4:frames(2, 10), 5:frames(2, 50), 6:frames(2, 30)}

function time_attack_thresholds_met(mem_type) {
    trigger = []
    for i in range(1, 6) {
        if (mem_type == "isDelta")
            array_push(trigger, once(prev(file_data__mems["Stage 10 Records List"][i]) <= time_attack_limits[i]))
        else
            array_push(trigger, once(file_data__mems["Stage 10 Records List"][i] <= time_attack_limits[i]))
    }
    return trigger
}

achievement(
    title = "The Final Challenge Opens",
    description = "Meet all the time requirements to unlock the door in Stage 10-7",
    points = 10,
    trigger = game_state_is("Play Area") && tally(5, time_attack_thresholds_met("isDelta")) && never(tally(6, time_attack_thresholds_met("isDelta"))) 
        && measured(tally(6, time_attack_thresholds_met("false"))) && never(!in_game())
)

achievement(
    title = "Worthy Prince of Pufftop",
    description = "Defeat Old Man Lobber in Stage 10-7",
    points = 10,
    trigger = game_state_is("Play Area") && in_room(10, 7, 3) && just_changed(boss_health__mem(), 1, 0)
)

// Dumpling Master

dumpling_master_state__addr = 0x1D0424
dumpling_master_score__addr = 0x1D042C

function dumpling_master_state__mem() => byte(dumpling_master_state__addr)
function dumpling_master_score__mem() => byte(dumpling_master_score__addr)

function dumpling_master_start() => game_state_is("Dumpling Master") && 
    just_changed(dumpling_master_state__mem(), 1, 2) && byte(0x1D0434) != 3
function dumpling_master_cancel() => !game_state_is("Dumpling Master") || dumpling_master_state__mem() == 0x0B
function dumpling_master_finish() => just_changed(dumpling_master_state__mem(), 9, 0x0A)

leaderboard(
    title = "Dumpling Master",
    description = "Score as many points as possible",
    start = dumpling_master_start(),
    cancel = dumpling_master_cancel(),
    submit = dumpling_master_finish(),
    value = dumpling_master_score__mem(),
    format = "VALUE"
)

dumpling_master_ranks = {
    "Humpty Dumpling": {"score":15, "points":5},
    "Dumpling Master": {"score":48, "points":25}
}

for rank in dumpling_master_ranks {
    achievement(
        title = rank,
        description = format("Score at least {0} points in the Dumpling Master minigame (unlocks at result screen)", dumpling_master_ranks[rank]["score"]),
        points = dumpling_master_ranks[rank]["points"],
        trigger = once(dumpling_master_start()) && never(dumpling_master_cancel()) 
            && dumpling_master_finish() && dumpling_master_score__mem() >= dumpling_master_ranks[rank]["score"]
    )
}

minigame_result_state__addr = 0x9627c
function minigame_result_state__mem() => byte(minigame_result_state__addr)

function multi_minigame_final_results() => prev(minigame_result_state__mem()) == 0x0A 
    && (minigame_result_state__mem() == 0x46 || minigame_result_state__mem() == 0x47)

// Sand Tracer

sand_tracer_time__addr          = 0x1F2604
sand_tracer_score__addr         = 0x1F261C // P1 base
sand_tracer_max_time            = 0x1C20
sand_tracer_outline__addr       = 0x1F2608
sand_tracer_amount_traced__addr = 0x1F25F0
sand_tracer_inaccuracy__addr    = 0x1F25F4

function sand_tracer_time__mem() => word(sand_tracer_time__addr)
function sand_tracer_score__mem(player) => dword(sand_tracer_score__addr + 4 * (player - 1))
function sand_tracer_outline__mem() => byte(sand_tracer_outline__addr)
function sand_tracer_amount_traced__mem() => dword(sand_tracer_amount_traced__addr)
function sand_tracer_inaccuracy__mem() => dword(sand_tracer_inaccuracy__addr)

function sand_tracer_won() => sand_tracer_score__mem(1) >= sand_tracer_score__mem(2)
    && sand_tracer_score__mem(1) >= sand_tracer_score__mem(3)
    && sand_tracer_score__mem(1) >= sand_tracer_score__mem(4)

function sand_tracer_start() => game_state_is("Sand Tracer") && 
    sand_tracer_time__mem() == sand_tracer_max_time
function sand_tracer_cancel() => !game_state_is("Sand Tracer")
function sand_tracer_finish() => just_changed(sand_tracer_time__mem(), 1, 0)

function traced_moe_correctly() => sand_tracer_outline__mem() == 9 
    && sand_tracer_amount_traced__mem() >= 0x158
    && sand_tracer_inaccuracy__mem() <= 0x525

leaderboard(
    title = "Sand Tracer",
    description = "Score as many points as possible (any difficulty)",
    start = sand_tracer_start(),
    cancel = sand_tracer_cancel(),
    submit = sand_tracer_finish(),
    value = sand_tracer_score__mem(1),
    format = "VALUE"
)

achievement(
    title = "Speed Tracing",
    description = "Get 1st place in the Sand Tracer minigame on hard difficulty",
    points = 10,
    trigger = game_state_is("Sand Tracer") && is_minigame_difficulty("Hard")
        && multi_minigame_final_results() && sand_tracer_won()
)

achievement(
    title = "Lucky Clam",
    description = "Trace Moe in the Sand Tracer minigame and steal up to 3 points from an opponent!",
    points = 2,
    trigger = game_state_is("Sand Tracer") && traced_moe_correctly()
)

// Depth Chargers

depth_chargers_time__addr = 0x1D2784
depth_chargers_score__addr = 0x1D1B30 // P1 base
depth_chargers_max_time = 0x4B0

function depth_chargers_time__mem() => word(depth_chargers_time__addr)
function depth_chargers_score__mem(player) => dword(depth_chargers_score__addr + 4 *(player - 1))
function depth_chargers_won() => depth_chargers_score__mem(1) >= depth_chargers_score__mem(2)
    && depth_chargers_score__mem(1) >= depth_chargers_score__mem(3)
    && depth_chargers_score__mem(1) >= depth_chargers_score__mem(4)

function depth_chargers_start() => game_state_is("Depth Chargers") && 
    depth_chargers_time__mem() == depth_chargers_max_time
function depth_chargers_cancel() => !game_state_is("Depth Chargers")
function depth_chargers_finish() => just_changed(depth_chargers_time__mem(), 0x3C, 0x3B)

leaderboard(
    title = "Depth Chargers",
    description = "Dive as deep as possible (any difficulty)",
    start = depth_chargers_start(),
    cancel = depth_chargers_cancel(),
    submit = depth_chargers_finish(),
    value = depth_chargers_score__mem(1),
    format = "VALUE"
)

achievement(
    title = "Deepest Diver",
    description = "Get 1st place in the Depth Chargers minigame on hard difficulty",
    points = 10,
    trigger = game_state_is("Depth Chargers") && is_minigame_difficulty("Hard")
        && multi_minigame_final_results() && depth_chargers_won() 
)

// Fishing Derby

fishing_derby_increment_counter__addr = 0x1D2956 // P1 only
fishing_derby_countdown_active__addr = 0x96282
fishing_derby_time__addr = 0x1D34BA
fishing_derby_score__addr = 0x1D34BC // P1 base
fishing_derby_max_time = 0x2A2F

function fishing_derby_countdown_active__mem() => byte(fishing_derby_countdown_active__addr)
function fishing_derby_countdown_active() => prev(fishing_derby_countdown_active__mem()) == 0 
    && fishing_derby_countdown_active__mem() == 1
    
function fishing_derby_time__mem() => word(fishing_derby_time__addr)
function fishing_derby_score__mem(player) => word(fishing_derby_score__addr + 2*(player - 1))
function fishing_derby_increment_counter__mem() => word(fishing_derby_increment_counter__addr)
function fishing_derby_won() => fishing_derby_score__mem(1) >= fishing_derby_score__mem(2)
    && fishing_derby_score__mem(1) >= fishing_derby_score__mem(3)
    && fishing_derby_score__mem(1) >= fishing_derby_score__mem(4)
    
function fishing_derby_start() => game_state_is("Fishing Derby") && fishing_derby_countdown_active()
    && fishing_derby_time__mem() == fishing_derby_max_time
function fishing_derby_cancel() => !game_state_is("Fishing Derby")
function fishing_derby_finish() => just_changed(fishing_derby_time__mem(), 1, 0)

leaderboard(
    title = "Fishing Derby",
    description = "Score as many points as possible (any difficulty)",
    start = fishing_derby_start(),
    cancel = fishing_derby_cancel(),
    submit = fishing_derby_finish(),
    value = fishing_derby_score__mem(1),
    format = "VALUE"
)

achievement(
    title = "The Biggest Catch",
    description = "Get 1st place in the Fishing Derby minigame on hard difficulty",
    points = 10,
    trigger = game_state_is("Fishing Derby") && is_minigame_difficulty("Hard")
        && multi_minigame_final_results() && fishing_derby_won()
)

achievement(
    title = "Exotic Heart Gem",
    description = "Reel in Moe in the Fishing Derby minigame and score 5 points at once!",
    points = 2,
    trigger = game_state_is("Fishing Derby")
        && just_changed(fishing_derby_increment_counter__mem(), 0, 5)
)

// Coin Slinger

coin_slinger_score__addr = 0x1D1B30 // P1 Base
coin_slinger_combo__addr = 0x1D3C5A // P1

function coin_slinger_score__mem(player) => dword(coin_slinger_score__addr + 4*(player - 1))
function coin_slinger_combo__mem() => byte(0x1D3C5A)
function coin_slinger_won() => coin_slinger_score__mem(1) == 40 //Score limit

achievement(
    title = "Lucrative Sharpshooter",
    description = "Get 1st place in the Coin Slinger minigame on hard difficulty",
    points = 10,
    trigger = game_state_is("Coin Slinger") && is_minigame_difficulty("Hard")
        && multi_minigame_final_results() && coin_slinger_won()
)

achievement(
    title = "Starstruck Coin Combo",
    description = "Get a combo of 5 or more in the Coin Slinger minigame to spawn even more balloons!",
    points = 5,
    trigger = game_state_is("Coin Slinger") && just_changed(coin_slinger_combo__mem(), 4, 5)
)

// -------------------------------
// Misc. Side Quests / Extra Tasks
// -------------------------------

side_quest_room__conds = {
    "2-4": (in_room(2, 4, 7) || in_room(12, 4, 7)),
    "3-3": (in_room(3, 3, 6) || in_room(13, 3, 6)),
    "4-3": (in_room(4, 3, 6) || in_room(14, 3, 6)),
    "5-4": (in_room(5, 4, 3) || in_room(15, 4, 3)),
    "6-3": (in_room(6, 3, 8) || in_room(16, 3, 8)),
    "6-4": in_room(16, 4, 8) //revisit only triggerable achievement
}

side_quest_health__mems = {
    "2-4": byte(0x1F204C),
    "4-3": byte(0x1F123C),
    "5-4": byte(0x1F1128),
}

ring_course_timer__addr = 0x1F19A8
function ring_course_timer__mem() => byte(ring_course_timer__addr)
function ring_course_score__mem() => array_object_misc_counter_2_value(3)

function ring_course_start() => side_quest_room__conds["3-3"] && tf_just_changed("None", "Starpedo")
function ring_course_cancel() => area_exit() || !tf_is("Starpedo")
function ring_course_finish() => game_state_is("Play Area") && fadeout_no_control()

achievement(
    title = "Acrobatic Starpedo",
    description = "Score at least 50 points in Piplion's ring course in Stage 3-3",
    points = 5,
    trigger = game_state_is("Play Area") && once(ring_course_start()) && never(ring_course_cancel()) && never(ring_course_finish()) && array_object_is(3, "Misc Counter 2") && trigger_when(ring_course_score__mem() >= 50 && prev(ring_course_score__mem()) >= 46 && prev(ring_course_score__mem()) < 50)
)

leaderboard(
    title = "Piplion's Ring Course",
    description = "Jump through as many rings as possible in the 3-3 Side Quest",
    start = game_state_is("Play Area") && ring_course_start(),
    cancel = ring_course_cancel(),
    submit = ring_course_finish(),
    value = ring_course_score__mem(),
    format = "VALUE"
)

juggling_quest_timer__addr = 0x1F135C
function juggling_quest_timer__mem() => word(juggling_quest_timer__addr)
function juggling_quest_score__mem() => array_object_misc_counter_value(2)

function juggling_quest_start() => side_quest_room__conds["6-3"] && just_changed(juggling_quest_timer__mem(), 3600, 3599)
function juggling_quest_cancel() => area_exit() || entering_door()
function juggling_quest_finish() => game_state_is("Play Area") && fadeout_no_control()

achievement(
    title = "Juggling Champ",
    description  = "Score at least 25 points in Herman's juggling Side Quest in Stage 6-3",
    points = 10,
    trigger = game_state_is("Play Area") && side_quest_room__conds["6-3"] && juggling_quest_timer__mem() < 3600 && juggling_quest_timer__mem() > 0 && array_object_is(2, "Misc Counter") && trigger_when(just_changed(juggling_quest_score__mem(), 24, 25))
)

leaderboard(
    title = "Herbert's Juggling Game",
    description = "Juggle the Puffy Chub as many times as possible in the 6-3 Side Quest",
    start = game_state_is("Play Area") && juggling_quest_start(),
    cancel = juggling_quest_cancel(),
    submit = juggling_quest_finish(),
    value = juggling_quest_score__mem(),
    format = "VALUE"
)

function gliding_distance__mem() => array_object_misc_counter_value(1)

achievement(
    title = "Long Flier",
    description = "Glide the maximum possible distance in Herbert's Side Quest in Stage 6-4",
    points = 5,
    trigger = game_state_is("Play Area") && side_quest_room__conds["6-4"] && array_object_is(1, "Misc Counter") && trigger_when(just_changed(gliding_distance__mem(), 169, 170))
)

//
//  Damageless Side Quests
//

//achievement(
//    title = "Ninja Mine-Car Battle",
//    description = "Complete Kittana's Side Quest in Stage 5-4 without taking damage",
//    points = 5,
//    trigger = game_state_is("Play Area") && side_quest_room__conds["5-4"] && side_quest_health__mems["5-4"] == 3 && trigger_when(anim_is("Holding Chest"))
//)

function side_quest_treasure_collected() => prev(byte(0x1F3580)) == 6

achievement(
    title = "Help from the Capfish",
    description = "Complete Old Man Vern's Side Quest in Stage 4-3 without taking damage",
    points = 5,
    trigger = game_state_is("Play Area") && side_quest_room__conds["4-3"] && side_quest_health__mems["4-3"] == 5 
        && trigger_when(side_quest_treasure_collected() && anim_is("Holding Chest"))
)

achievement(
    title = "Sprint to Bawss's Spa",
    description = "Complete The Squirts' Side Quest in Stage 2-4 without taking damage",
    points = 5,
    trigger = game_state_is("Play Area") && side_quest_room__conds["2-4"] && side_quest_health__mems["2-4"] == 3 && trigger_when(anim_is("Holding Chest"))
)

//
//  Hurdles
//

//function hurdle_flags_sum() => sum_discrete_bits(room_flags__addr(2), [42, 36, 28, 43, 44, 45, 46, 47, 48, 49])
//    + sum_discrete_bits(room_flags__addr(4), [44, 26, 45, 46, 47])
//These flags are for revisiting 5-2 only. There's nothing worth replaying this area for, so I gotta also support the uncleared version of this level.
function hurdle_challenge_goal() => reached_goal() && (in_room(5, 2, 5) || in_room(15, 2, 5))
//
//achievement(
//    title = "Careful Mine Car Ride",
//    description = "Clear Stage 5-2 without breaking any hurdles",
//    points = 5,
//    trigger = unless(!game_state_is("Play Area")) && (once(area_start(5, 2)) || once(area_start(15, 2))) && never(hurdle_flags_sum() > 0) && trigger_when(hurdle_challenge_goal())
//)

function any_hurdle_destroyed()  //Checks the first ~48 object slots for a destroyed hurdle
{
    cond = always_false()
    for i in range(0, 47) {
        cond = cond || (in_controllable_mine_car() && array_object_is(i, "Hurdle") && array_object_hurdle_is_destroyed(i))
    }
    return cond
}

achievement(
    title = "Careful Mine Car Ride",
    description = "Clear Stage 5-2 from the beginning without breaking any avoidable hurdles",
    points = 5,
    trigger = game_state_is("Play Area") && (once(area_start(5, 2)) || once(area_start(15, 2))) && never(area_exit())
        && never(any_hurdle_destroyed()) && trigger_when(hurdle_challenge_goal())
)

//
//  Huffinfluff
//

function huff_challenge_goal() => in_room(6, 6, 4) && reached_goal()

achievement(
    title = "Calm Skies",
    description = "Clear Stage 6-6 without waking up Huffinfluff",
    points = 5,
    trigger = game_state_is("Play Area") && once(area_start(6, 6)) && never(area_exit()) && never(array_object_is(1, "Huffinfluff") && array_object_huffinfluff_woke_up(1)) 
        && trigger_when(huff_challenge_goal())
)

// RP

static_states = {
    0x08: "Deciding what minigame to play",
    0x09: "🍳 Cooking some takoyaki with Starly",
    0x0A: "Starting up the game",
    0x0D: "Viewing the Abilities menu",
    0x0E: "Checking in on Bunston in the Collections screen",
    0x0F: "Viewing story events and side quests in the Journals menu",
    0x10: "Chilling on the file select",
    0x11: "Listening to the Game Over music",
    0x13: "💤 Making a suspend save",
    0x14: "🔧 Deciding which control scheme to use (Configure Buttons menu)",
    0x15: "Hanging out in Moe's Case",
    0x16: "On the world map",
    0x18: "Viewing some Notes that Starfy collected",
    0x19: "In the main Pause Menu",
    0x1A: "🎶 Listening to some Sea Jams",
    0x1B: "Hanging out on the title screen",
    0x1F: "Dressing up in the Stuff menu",
    0x20: "Watching a story cartoon",
    0x22: "Picking a story cartoon to watch",
    0x23: "Watching the Credits Roll",
    0x24: "Just completed Big Bossdown and viewing the results"
}

static_state__lookup = rich_presence_lookup("StaticStates", game_state__mem(), static_states)

minigame_states = {
    0x04: "Slinging some coins",
    0x05: "Catching some fish",
    0x06: "Tracing some outlines in the sand",
    0x07: "Diving really deep into the water"
}

minigame_state__lookup = rich_presence_lookup("MinigameStates", game_state__mem(), minigame_states)

minigame_difficulties = {
    0: "Easy",
    1: "Normal",
    2: "Hard"
}

minigame_difficulty__lookup = rich_presence_lookup("MinigameDifficulties", minigame_difficulty__mem(), minigame_difficulties)

toy_states = {
    0x1C: "Rolling for toys in the gacha machine",
    0x1D: "Viewing the Toy Collection"
}

toy_state__lookup = rich_presence_lookup("ToyStates", game_state__mem(), toy_states)

toys__value = rich_presence_value("Number", file_data__mems["Toys"])

rps_starfy_health__value = rich_presence_value("Number", rps_battle_player_health__mem())
rps_boss_health__value = rich_presence_value("Number", rps_battle_boss_health__mem())

stages = {
    1: "Gluglug Lagoon",
    2: "Hotcha Springs",
    3: "Chillydip Cove",
    4: "Sogwood Forest",
    5: "Glitzem Grotto",
    6: "Skydye Heights",
    7: "S. S. Logwater",
    8: "Planet Bunnera",
    9: "Pufftop",
    10: "???"
}

stage__lookup = rich_presence_lookup("Stages", stage__mem(), stages, "an unknown location")

stage__value = rich_presence_value("Number", stage__mem())
area__value = rich_presence_value("Number", area__mem())

characters = {
    0   : "Starfy",
    0x0B: "Starly"
}

character__lookup = rich_presence_lookup("Character", char__mem(), characters, "Starfy")

player_health__value = rich_presence_value("Number", current_health__mem())
player_max_health__value = rich_presence_value("Number", max_health__mem())
boss_health__value = rich_presence_value("Number", boss_health__mem())

bossdown_segments = {
    0: "1 - Big Squiddy",
    1: "2 - Hot-Spring Snapper",
    2: "3 - King Ping",
    3: "4 - Papes",
    4: "5 - Ronk",
    5: "6 - Snips",
    6: "7 - The Terrible Trio",
    7: "8 - Mashtooth",
    8: "9 - Mega Mashtooth",
    9: "🏁 Done!"
}

bossdown_segment__lookup = rich_presence_lookup("BossdownSplit", file_data__mems["Bossdown Current Split"], bossdown_segments)

bossdown_time__value = rich_presence_value("Time", word(0x9001), "FRAMES")

level_pearl__value = rich_presence_value("Number", level_pearl__mem())
chests__value = rich_presence_value("Number", word(0x9001))

rich_presence_conditional_display(game_state__mem() >= 0x27, "Attempting to use Local Wireless features. Get outta there!")
rich_presence_conditional_display(mem_in(game_state__mem(), static_states), "{0}", static_state__lookup)
rich_presence_conditional_display(mem_in(game_state__mem(), minigame_states), "{0} ({1} Difficulty Minigame)", minigame_state__lookup, minigame_difficulty__lookup)
rich_presence_conditional_display(mem_in(game_state__mem(), toy_states), "{0} [{1}/127 Toys]", toy_state__lookup, toys__value)
rich_presence_conditional_display(game_state__mem() == 0x21, "Playing some rock paper scissors! ⭐❤️{0}/3 💀❤️{1}/10", rps_starfy_health__value, rps_boss_health__value) 
rich_presence_conditional_display(game_state__mem() == 0x17, "Selecting an area in {0}", stage__lookup)   
rich_presence_conditional_display(game_state__mem() == 0x0C, "{0} just defeated a boss! (Starfy Dance)", character__lookup)
rich_presence_conditional_display(in_big_bossdown(), "{0} is in Big Bossdown! Current Segment: {1} ⏱️{2}", character__lookup, bossdown_segment__lookup, bossdown_time__value)
rich_presence_conditional_display(game_state__mem() == 0x26 && boss_active(), "{0} is fighting a boss in {1}! ⭐❤️{2}/{3} 💀❤️{4}/10", character__lookup, stage__lookup, player_health__value, player_max_health__value, boss_health__value)
rich_presence_conditional_display(game_state__mem() == 0x26, "{0} is in Area {1} of {2} | ❤️{3}/{4} | ⍟{5} | 🧰{6}/102", character__lookup, area__value, stage__lookup, player_health__value, player_max_health__value, level_pearl__value, chests__value)
rich_presence_display("Starfy is on an adventure")

//Replace toy state display with this:
//?1=1S0xX1c03d4=28S0xX1c03d4=29?@ToyStates(0xX1c03d4) [@Number(I:0xW08fd74_A:0xK000056_I:0xW08fd74_A:0xK000057_I:0xW08fd74_A:0xK000058_I:0xW08fd74_A:0xK000059_I:0xW08fd74_A:0xK00005a_I:0xW08fd74_A:0xK00005b_I:0xW08fd74_A:0xK00005c_I:0xW08fd74_A:0xK00005d_I:0xW08fd74_A:0xK00005e_I:0xW08fd74_A:0xK00005f_I:0xW08fd74_A:0xK000060_I:0xW08fd74_A:0xK000061_I:0xW08fd74_A:0xK000062_I:0xW08fd74_A:0xK000063_I:0xW08fd74_A:0xK000064_I:0xW08fd74_A:0xK000065_I:0xW08fd74_B:0xT000065_M:0)/127 Toys]

//Replace Bossdown time with this:
//Q:0xX1f19e8=33787988_M:0xX1f19c8$Q:0xX1f1afc=33787988_M:0xX1f1adc$Q:0xX1f1c10=33787988_M:0xX1f1bf0$Q:0xX1f1d24=33787988_M:0xX1f1d04$Q:0xX1f1e38=33787988_M:0xX1f1e18$Q:0xX1f1f4c=33787988_M:0xX1f1f2c$Q:0xX1f2288=33787988_M:0xX1f2268

//Replace in-level display with this:
//?0xX1c03d4=38?@Character(0xH19a5ae) is in Area @Number(0xH1c03d9) of @Stages(0xH1c03da) | ❤️@Number(0xH19a5a4)/@Number(0xH19a5a6) | ⍟@Number(0x 19a5a8) | 🧰@Number(I:0xW08fd74_B:0xP000078_I:0xW08fd74_B:0xS000078_I:0xW08fd74_B:0xN000079_I:0xW08fd74_B:0xQ000079_I:0xW08fd74_B:0xS000079_I:0xW08fd74_B:0xM00007a_I:0xW08fd74_B:0xR00007a_I:0xW08fd74_B:0xM00007b_I:0xW08fd74_B:0xP00007b_I:0xW08fd74_B:0xS00007b_I:0xW08fd74_B:0xM00007c_I:0xW08fd74_B:0xO00007c_I:0xW08fd74_B:0xQ00000a_I:0xW08fd74_A:0xQ00000a_I:0xW08fd74_A:0xR00000a_I:0xW08fd74_A:0xS00000a_I:0xW08fd74_A:0xT00000a_I:0xW08fd74_A:0xM00000b_I:0xW08fd74_A:0xN00000b_I:0xW08fd74_A:0xO00000b_I:0xW08fd74_A:0xP00000b_I:0xW08fd74_B:0xT000077_I:0xW08fd74_A:0xK000076_I:0xW08fd74_A:0xK000077_I:0xW08fd74_A:0xK000078_I:0xW08fd74_A:0xK000079_I:0xW08fd74_A:0xK00007a_I:0xW08fd74_A:0xK00007b_I:0xW08fd74_A:0xM00007c_I:0xW08fd74_A:0xN00007c_I:0xW08fd74_A:0xO00007c_I:0xW08fd74_A:0xP00007c_I:0xW08fd74_A:0xK0000ea_I:0xW08fd74_A:0xK0000eb_I:0xW08fd74_A:0xK0000ec_I:0xW08fd74_A:0xK0000ed_I:0xW08fd74_A:0xK0000ee_I:0xW08fd74_A:0xK0000ef_I:0xW08fd74_A:0xK0000f0_M:0)/102