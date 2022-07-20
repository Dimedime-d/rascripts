// Densetsu no Stafy 3
// #ID = 7270
// Made in RATools v1.9.1

// ------------- //
//   u t i l s   //
// ------------- //

// Set this to ZERO before pushing to unofficial or core
GENERATE_DUMMY_ACHIEVEMENTS = 0

function DUMMY_ACHIEVEMENT(title="", description="DUMMY", points=0, trigger=always_false()) {
    if (GENERATE_DUMMY_ACHIEVEMENTS != 0) {
        achievement(
        title=format("[Dummy] {0}", title), description=description, points=points, trigger=trigger
        )
    }
    
}

function mem_in(mem, arr) {
    return any_of(arr, a => mem == a)
}

function just_increased(mem) => mem > prev(mem)
function just_decreased(mem) => mem < prev(mem)

function stayed_same(mem) => mem == prev(mem)
function just_changed_any(mem) => mem != prev(mem)
function just_changed(mem, from, to) => prev(mem) == from && mem == to
function just_changed_to(mem, to) => prev(mem) != to && mem == to
function just_changed_from(mem, from) => prev(mem) == from && mem != from

function offset_bit(addr, index) {
    return bit(index % 8, addr + index/8) 
}

function struct_field(struct_def, base, field) => base + struct_def[field]

function merge_arrays(arr1, arr2) // thanks Xor
{
    new_arr = arr1
    for i in arr2
    {
        array_push(new_arr, i)
    }
    return new_arr
}

// State Structs

active_state_struct__addr = 0x2940

minigame_state__struct = {
    "difficulty": 0x8060,
    
    "state_a": 0x94B8, // every other minigame
    "sub-state_a": 0x94BA,
    "state_b": 0x94BC, // squid
    "sub-state_b": 0x94BE,
}

function minigame_state_field(field) => struct_field(minigame_state__struct, tbyte(active_state_struct__addr), field)

function minigame_difficulty() => byte(minigame_state_field("difficulty"))

function minigame_state(type="a") => byte(minigame_state_field(format("state_{0}", type)))
function minigame_sub_state(type="a") => byte(minigame_state_field(format("sub-state_{0}", type)))

// Game States

demo_id__addr = 0x7A58
function demo_id__mem() => byte(demo_id__addr)

active_file__addr = 0x8028
function active_file() => byte(active_file__addr)

game_state__addr            = 0x7E28

game_state__values = {
    "Play Area":        0x05,
    "Title Screen":     0x08,
    "Intro":            0x09,
    "File Select":      0x0A,
    "Area Select":      0x0B,
    "Minigame":         0x0D,
    "Clear":            0x0E,
    "Staff Roll":       0x0F,
    "Sea Jams":         0x10,
    "Shop":             0x12,
    "Moe House":        0x13,
    "Ending":           0x14,
    "World Map":        0x15,
    "Starfy Dance":     0x16,
    "Game Over":        0x18,
    "Stuff":            0x19, // only from world map / area select
    "Trading Cards":    0x1A,
}

game_substate__addr = 0x7e2c
function game_substate__mem() => byte(game_substate__addr)

function file_is_selected() => all_of(["Title Screen", "Intro", "File Select"], s => !game_state_is(s)) // don't really care about demo

function game_state__mem() => dword(game_state__addr)
function game_state_is(name) => game_state__mem() == game_state__values[name]
function game_state_was(name) => prev(game_state__mem()) == game_state__values[name]
function game_state_just_changed(from_name, to_name) =>
    just_changed(game_state__mem(), game_state__values[from_name], game_state__values[to_name])
    
    
// play area

stage__addr = 0x4516
function stage__mem() => byte(stage__addr)

function area_exit() => any_of(["Game Over", "Area Select", "Intro"], a => game_state_is(a))
function paused() => game_state_is("Play Area") && byte(0x4508) == 0

function ending_index() => game_substate__mem()

area__addr  = 0x4515
function area__mem() => byte(area__addr)
room__addr  = 0x4514
function room__mem() => byte(room__addr)

function in_room(stage, area=-1, room=-1) {
    cond = game_state_is("Play Area") && stage__mem() == stage
    if (area != -1) cond = cond && area__mem() == area
    if (room != -1) cond = cond && room__mem() == room
    return cond
}

regular_hearts__addr = 0x7cf8
function regular_hearts__mem() => byte(regular_hearts__addr)

pearls_in_area__addr = 0x7cfa
function pearls_in_area__mem() => word(pearls_in_area__addr)

function took_damage_regular() => game_state_was("Play Area") && regular_hearts__mem() < prev(regular_hearts__mem())

// starfy abilities use 1-2-3, starly uses individual bits
starly_ability__addr = 0x7cfe
starly_ability_bits = {
    "Crawl": bit(0, starly_ability__addr),
    "Wall Jump": bit(1, starly_ability__addr),
    "Switch Characters": bit(2, starly_ability__addr),
}

character_collision__addr = 0x7d34
character_collision_bits = {
    "Boss Movement Lock": bit(0, character_collision__addr),
    "In Water": bit(2, character_collision__addr),
    "On Ground": bit(6, character_collision__addr),
    "On Ice": bit(7, character_collision__addr),
    
    "Facing Left": bit(0, character_collision__addr+1),
    "Clip Through Walls": bit(1, character_collision__addr+1),
    "Goal Movement Lock": bit(2, character_collision__addr+1),
    "No Enemy Collision": bit(6, character_collision__addr+1)
}

ending_bits = {
    1: bit3(0x8791),
    2: bit7(0x8791),
    3: bit0(0x8792),
}

char_animation__addr = 0x7d6a
function char_animation__mem() => byte(char_animation__addr)

function starly_active() => bit(0, 0x7d98)
function playing_as_starly() => starly_active() != 0

// minigames
    
minigame_type__addr = 0xC4F4

function minigame_meta(type, title, desc, state, winning_player_offset, draw_indicator_offset, points) => {"type": type, "title": title, "desc": desc, "state": state, "winning player offset": winning_player_offset, "draw indicator offset": draw_indicator_offset, "points": points}

minigame__values = {
    "Clam":      minigame_meta(0x00, "Fastest Clam in the Sea", "the clam racing minigame", "a", 0x9638, 0x97D0, 5),
    "Volleyball":minigame_meta(0x01, "Lovely Volley Champ", "the volleyball minigame", "a", 0x9638, 0x97D0, 5),
    "Trampoline":minigame_meta(0x02, "The Bounciest Colored Star", "the trampoline minigame", "a", 0x9634, 0x97CC, 10),
    "Dance":     minigame_meta(0x03, "Good Memory", "the dance-off minigame", "a", 0x963a, 0x97d0, 5),
    "Squid":     minigame_meta(0x04, "The Best Hoarder", "the Squirt catch minigame", "b", 0x9634, 0x97cc, 5),
}

function minigame_type__mem() => byte(minigame_type__addr)
function minigame_type_is(name) => minigame_type__mem() == minigame__values[name]["type"]

// Beat minigames
for name in minigame__values {
    info = minigame__values[name]
    cheev_title = info["title"]
    cheev_desc = format("Win at {0} on hard difficulty.", info["desc"])
    cheev_points = info["points"]
    
    state = info["state"]
    
    winning_player = byte(tbyte(active_state_struct__addr) + info["winning player offset"])
    draw_indicator = byte(tbyte(active_state_struct__addr) + info["draw indicator offset"])
    
    substate_cond = just_changed(minigame_sub_state(state), 5, 6)
    if (name == "Trampoline" || name == "Squid" || name == "Dance")
        substate_cond = just_changed(minigame_sub_state(state), 6, 7)
    
    cheev_cond = game_state_is("Minigame") && minigame_type_is(name)
        && minigame_difficulty() == 2 
        && trigger_when(
            winning_player == 0
            && draw_indicator != 7
            && minigame_state(state) == 4
            && substate_cond
            )
    
    achievement(
        title=cheev_title,
        description=cheev_desc,
        trigger=cheev_cond,
        points=cheev_points
    )
}

// General Memory

// Audio
audio_slots = [0x2090, 0x20d0, 0x2110, 0x2160]

function audio_slot_sappy_header(index) => dword(audio_slots[index])
function audio_slot_running(index) => byte(audio_slots[index] + 4)

function audio_slot_playing(index, sappy_header) => audio_slot_sappy_header(index) == sappy_header && audio_slot_running(index) != 0

achievement(
    title="Jackpot!",
    description="Touch a Goal when the light lands on a star. (50 bonus pearls)",
    points=2,
    trigger=game_state_is("Play Area") && (audio_slot_playing(1, 0x8E74564) || audio_slot_playing(1, 0x8E74680))
) // must also account for rev 1 differences

//
// bitflag hell
//

// Area Completions (basic progression)

function area_complete_flag(stage, area) => offset_bit(0x8727, stage * 10 + area)

function stage_meta(title, stage, points) => {"title": title, "stage": stage, "points": points}
stages = {
    1: stage_meta("Relearning Basic Abilities, Again", "Lobber's Cave", 5),
    2: stage_meta("Coast Control", "Coral Coast", 5),
    3: stage_meta("Deception in the Fog", "Misty Town", 5),
    4: stage_meta("Tasting Crushed Ice", "Kachiwari Iceberg", 5),
    5: stage_meta("Jungle Friends, Old and New", "Jungle", 5),
    6: stage_meta("Hot Pursuit", "Crackling Volcano", 5),
    7: stage_meta("Giant Robot Hermit Crab", "Gabun Ocean Trench", 5),
    8: stage_meta("Puzzles With a New Friend", "Undersea Ruins", 10),
    9: stage_meta("Even Floatier Platforming", "Sea of Sky", 10),
    
    // post-game
    11: stage_meta("Even More Treasures in the Cave", "Lobber's Cave", 5),
    12: stage_meta("Other Riches in the Coral", "Coral Coast", 5),
    13: stage_meta("Abandoned Town Treasures", "Misty Town", 5),
    14: stage_meta("Within the Avalanche", "Kachiwari Iceberg", 5),
    15: stage_meta("Jungle's Bounty", "Jungle", 5),
    16: stage_meta("Looting the Active Volcano", "Crackling Volcano", 10),
    17: stage_meta("Deep Diving", "Gabun Ocean Trench", 10),
    18: stage_meta("Treasure Hunting With Wario", "Undersea Ruins", 10),
    19: stage_meta("Cloudy Treasures", "Sea of Sky", 10),
    20: stage_meta("Plundering the Old Hideout", "Old Castle", 10),
}

for i in range(1, 9) {
    stage = stages[i]
    achievement(
        title=stage["title"],
        description=format("Clear Stage {1}, {0}, during the main story.", stage["stage"], i),
        trigger = game_state_is("Clear")
            && just_increased(area_complete_flag(i, 4)),
        points=stage["points"]
    )
}

for i in range(11, 19) {
    stage = stages[i]
    area_flags = array_map(range(1, 8), a => area_complete_flag(i, a))
    achievement(
        title=stage["title"],
        description=format("Complete every area in Stage {0}. (post-game)", i - 10),
        points=stage["points"],
        trigger=game_state_is("Clear")
            && prev(sum_of(area_flags, a => a)) == 7
            && measured(sum_of(area_flags, a => a) == 8, when=file_is_selected())
    )
}

// stage 10 (skip area 4)
stage = stages[20]
area_flags = array_map([1, 2, 3, 5, 6, 7, 8], a => area_complete_flag(20, a))
achievement(
    title = stage["title"],
    description = "Complete every area (except 10-4) in Stage 10. (post-game)",
    points = stage["points"],
    trigger = game_state_is("Clear")
        && prev(sum_of(area_flags, a => a)) == 6
        && measured(sum_of(area_flags, a => a) == 7, when=file_is_selected())
)

function global_flag(id) => bit(id % 8, 0x8038 + id / 8)

// Story stuffs

achievement(
    title = "Hopping High",
    description = "Save Old Man Mechani using the pogo stick. (first playthrough)",
    points = 2,
    trigger = in_room(2, 2, 5) && global_flag(1) != 0 && just_decreased(global_flag(2))
)

achievement(
    title = "Bomb Squad",
    description = "Help the army birds find all three bombs after learning how to crawl.",
    points = 2,
    trigger = in_room(3, 2, 6) && global_flag(5) != 0 && just_increased(global_flag(27))
)

achievement(
    title = "Mandatory Trading Sequence",
    description = "Bring all necessary materials to Fluffy to make the sheep costume.",
    points = 2,
    trigger = in_room(4, 2, 2) && global_flag(2) != 0 && just_increased(global_flag(9))
)

achievement(
    title = "Jumping Pony",
    description = "Find Tweeto's lost horse, Pakara.",
    points = 1,
    trigger = in_room(6, 2, 6) && global_flag(2) != 0 && just_increased(global_flag(3))
)

achievement(
    title = "Hide and Seek",
    description = "Find Kittana two times to learn the wall jump.",
    points = 1,
    trigger = in_room(6, 3, 3) && starly_ability_bits["Crawl"] != 0 && just_increased(starly_ability_bits["Wall Jump"])
)

achievement(
    title = "Exploring in the Dark",
    description = "Ride the submarine for the first time.",
    points = 2,
    trigger = in_room(7, 1, 4) && char_animation__mem() >= 0x70 && char_animation__mem() <= 0x7d
)

// END 1
achievement(
    title = "The Plan to Beat Evil",
    description = "Defeat Altered Ogura for the first time. (You get your first Evil Crystal in the ending.)",
    points = 10,
    trigger = game_state_is("Ending") && ending_index() == 1
)



// post-game progression (upgraded vehicles + evil crystals)

upgraded_vehicle__addr = 0x87e3
function upgraded_vehicle_unlock_sum(prev=-1) {
    if (prev > 0)
        arr = array_map(range(0, 3), a => prev(bit(a, upgraded_vehicle__addr)))
    else
        arr = array_map(range(0, 3), a => bit(a, upgraded_vehicle__addr))
    return sum_of(arr, a => a)
}

achievement(
    title = "Equipped to Explore Again",
    description = "Upgrade all vehicles by revisiting past friends.",
    points = 4,
    trigger = game_state_is("Play Area") && upgraded_vehicle_unlock_sum(prev=1) == 3 && measured(upgraded_vehicle_unlock_sum() == 4, when=file_is_selected())
)

function evil_crystals_sum(prev=-1) {
    if (prev > 0)
        arr = array_map(range(15500, 15541), a => prev(global_flag(a)))
    else
        arr = array_map(range(15500, 15541), a => global_flag(a))
    return sum_of(arr, a => a)
}

achievement(
    title = "Starting the Collection",
    description = "Complete any extra area to earn a second Evil Crystal.",
    points = 2,
    trigger = game_state_is("Clear")
        && evil_crystals_sum(prev=1) == 1 && evil_crystals_sum() == 2
)

achievement(
    title = "Ready to Confront Evil",
    description = "Gather 41 Evil Crystals.",
    points = 25,
    trigger = game_state_is("Clear")
        && evil_crystals_sum(prev=1) == 40 && measured(evil_crystals_sum() == 41, when=file_is_selected())
)

// GOOD END

achievement(
    title = "Peace in Pufftop, at Last",
    description = "Defeat Evil with at least 41 Evil Crystals.",
    points = 10,
    trigger = game_state_just_changed("Play Area", "Ending") && ending_index() == 5
)

achievement(
    title = "Cheers!",
    description = "Watch the conclusion of the first 3 Starfy games (best ending + 2nd staff credits) after beating Evil.",
    points = 1,
    trigger = once(game_state_just_changed("Play Area", "Ending") && ending_index() == 5) && never(game_state_is("Intro")) && trigger_when(repeated(7070, game_state_is("Staff Roll") && ending_index() == 1))
)

player_health_vs_boss__addr = 0x7b48
function player_health_vs_boss__mem() => byte(player_health_vs_boss__addr)
boss_health__addr = 0x7b49
function boss_health__mem() => byte(boss_health__addr)

function boss_movement_lock() => character_collision_bits["Boss Movement Lock"]

function boss_fight_just_started() => just_changed(boss_health__mem(), 4, 5) // no boss can heal...

function boss_defeat() => just_changed(boss_health__mem(), 1, 0)

function no_damage() => never(player_health_vs_boss__mem() < prev(player_health_vs_boss__mem()))

boss_room__conds = {
    1: in_room(11, 4, 7),
    2: in_room(12, 4, 8),
    3: in_room(13, 4, 12),
    4: in_room(14, 4, 10),
    5: in_room(15, 4, 14),
    6: in_room(16, 4, 12),
    7: in_room(17, 4, 16),
    8: (in_room(18, 4, 15) || in_room(8, 4, 15)),
    9: in_room(19, 4, 11),
    10: (in_room(10, 4, 6) || in_room(20, 4, 6)),
    11: in_room(20, 4, 10),
    12: in_room(20, 4, 13),
}

function boss_meta(title, description, points, conds) => {"title": title, "description": description, "points": points, "conds": conds}

bosses = {
    1: boss_meta("Starly's Starter Boss", "As Starly only, defeat Konk without taking damage.", 5, no_damage() && never(starly_active() == 0)),
    2: boss_meta("Weathering the Storm", "As Starly only, defeat Buirun without taking damage.", 5, no_damage() && never(starly_active() == 0)),
    3: boss_meta("Acrobatic Star", "As Starly only, defeat Mad Piero without taking damage.", 5, no_damage() && never(starly_active() == 0)),
    4: boss_meta("Re-Frozen", "As Starly only, defeat Pengod without taking damage.", 10, no_damage() && never(starly_active() == 0)),
    5: boss_meta("All Boxed In", "As Starly only, defeat Enbiraru without taking damage.", 10, no_damage() && never(starly_active() == 0)),
    6: boss_meta("Through Fire and Water", "As Starly only, defeat Amaenbi and Gyamuran without taking damage.", 10, no_damage() && never(starly_active() == 0)),
    7: boss_meta("Falling in Line", "As Starly only, defeat Bankiross without taking damage.", 10, no_damage() && never(starly_active() == 0)),
    8: boss_meta("Knighting Through", "Defeat Gachatakkoru without taking damage.", 10, no_damage()),
    9: boss_meta("Round and Round", "As Starly only, defeat Muga without taking damage. (switch characters when fight begins)", 10, no_damage() && never(repeated(150, boss_movement_lock() == 0 && starly_active() == 0)) && never(just_decreased(starly_active()))),
    10: boss_meta("Third Brawl with Ogura", "Defeat Altered Ogura without taking damage.", 10, no_damage()),
    11: boss_meta("The Face of Evil", "Defeat Evil's first form without taking damage.", 5, no_damage()),
    12: boss_meta("Vanquished Evil", "Defeat Evil's second form without taking damage.", 25, no_damage()),
}

for i in bosses {
    b = bosses[i]
    achievement(
        title = b["title"],
        description = b["description"],
        points = b["points"],
        trigger = unless(paused()) && boss_room__conds[i] && once(boss_fight_just_started()) && b["conds"] && never(area_exit()) && trigger_when(boss_defeat())
    )
}

// Bosses
// Konk: 11-4-7
// Buirun: 12-4-8
// Piero: 13-4-12
// pengod: 14-4-10
// 15-4-14
// 16-4-12
// bankiross: 17-4-16
// 18-4-15
// Muga: 19-4-11
// Ogura-3 rematch: 20-4-6
// Evil 1 - 20-4-10
// Evil 2 - 20-4-13

// Extra Tasks

function reached_goal() => just_increased(character_collision_bits["Goal Movement Lock"]) && just_increased(character_collision_bits["No Enemy Collision"])

function area_start(stage, area) => game_state_just_changed("Area Select", "Play Area") && in_room(stage, area, 1)

// PLANNED: 4-4 fork, 6-8 starly, 8-4 pearls, 9-7 no dmg?, 10-8 room 5

achievement(
    title = "An Old Enemy",
    description = "Help Moe fight off Fork and Fork's brother.",
    points = 1,
    trigger = in_room(14, 4) && global_flag(20) != 0 && just_increased(global_flag(400))
)

achievement(
    title = "Pink-Faced Volcanic Sprint",
    description = "As Starly only, complete Stage 6-8 in one go. (switch characters at beginning)",
    points = 5,
    trigger = once(area_start(16, 8)) && game_state_is("Play Area") && never(area_exit()) && never(repeated(120,starly_active() == 0)) && never(just_decreased(starly_active()))
    && trigger_when(reached_goal())
)

function darkness() => byte(0x776c)

achievement(
    title = "Let Them Sleep...",
    description = "Complete Stage 7-5 in one go without turning on the lights.",
    points = 5,
    trigger = once(area_start(17, 5)) && game_state_is("Play Area") && never(area_exit()) && never(just_changed(darkness(), 0x10, 0x0f)) && trigger_when(reached_goal())
)

function collected_pearls_sum(room, wario=1) {
    room_base = 0x8858 + (room - 1) * 0x40
    if (room == 11 && wario > 0)
        return sum_of(range(1, 7), a => bitcount(room_base + a))
    return sum_of(range(0, 7), a => bitcount(room_base + a))
}

function all_collected_pearls_sum(max_room) => sum_of(range(1, max_room), a => collected_pearls_sum(a))

achievement(
    title = "The Best Treasure Hunting Tag Team",
    description = "Revisit Stage 8-4 and collect all 216 naturally appearing big or small pearls.",
    points = 10,
    trigger = in_room(18, 4)
        && prev(all_collected_pearls_sum(15)) < 216
        && prev(all_collected_pearls_sum(15)) >= 210
        && measured(all_collected_pearls_sum(15) == 216)
)

achievement(
    title = "Up and Up and Up",
    description = "Complete Stage 9-8 in one go without taking damage.",
    points = 10,
    trigger = once(area_start(19, 8)) && game_state_is("Play Area") && never(area_exit()) && never(took_damage_regular()) && trigger_when(reached_goal())
)

//----------------------
//  Completion Stuffs
//----------------------

// Shop

function shop_meta(flag, cost) => {"flag": flag, "cost": cost}
shop_items = [
    shop_meta(flag=15101, cost=20),
    shop_meta(flag=15102, cost=20),
    shop_meta(flag=15103, cost=20),
    shop_meta(flag=15104, cost=30),
    shop_meta(flag=15105, cost=111),
    
    shop_meta(flag=15106, cost=45),
    shop_meta(flag=15107, cost=45),
    shop_meta(flag=15108, cost=70),
    shop_meta(flag=15109, cost=90),
    shop_meta(flag=15110, cost=1),
    
    shop_meta(flag=15112, cost=40),
    shop_meta(flag=15113, cost=120),
    shop_meta(flag=15114, cost=40),
    shop_meta(flag=15121, cost=60),
    shop_meta(flag=15116, cost=120),
    
    shop_meta(flag=15111, cost=40),
    shop_meta(flag=15117, cost=50),
    shop_meta(flag=15118, cost=60),
    shop_meta(flag=15119, cost=111),
    shop_meta(flag=15215, cost=30),
    shop_meta(flag=15115, cost=1000),
    
    shop_meta(flag=15146, cost=30),
    shop_meta(flag=15123, cost=60),
    shop_meta(flag=15124, cost=250),
    shop_meta(flag=15125, cost=98),
    shop_meta(flag=15120, cost=150),
    shop_meta(flag=15225, cost=30),
    
    shop_meta(flag=15126, cost=100),
    shop_meta(flag=15127, cost=150),
    shop_meta(flag=15128, cost=170),
    shop_meta(flag=15129, cost=170),
    shop_meta(flag=15130, cost=111),
    
    shop_meta(flag=15131, cost=60),
    shop_meta(flag=15132, cost=170),
    shop_meta(flag=15133, cost=90),
    shop_meta(flag=15134, cost=170),
    shop_meta(flag=15135, cost=260),
    
    shop_meta(flag=15136, cost=90),
    shop_meta(flag=15137, cost=180),
    shop_meta(flag=15138, cost=190),
    shop_meta(flag=15139, cost=240),
    shop_meta(flag=15140, cost=100),
    shop_meta(flag=15239, cost=100),
    
    shop_meta(flag=15141, cost=150),
    shop_meta(flag=15142, cost=160),
    shop_meta(flag=15143, cost=198),
    shop_meta(flag=15144, cost=380),
    shop_meta(flag=15145, cost=111),
    
    shop_meta(flag=15122, cost=666),
    shop_meta(flag=15147, cost=444),
    shop_meta(flag=15148, cost=108),
    shop_meta(flag=15149, cost=1300),
    shop_meta(flag=15150, cost=777),
    shop_meta(flag=15248, cost=1000),
    shop_meta(flag=15249, cost=5000),
    
    shop_meta(flag=15640, cost=500),
    shop_meta(flag=15644, cost=500),
    shop_meta(flag=15642, cost=500),
    shop_meta(flag=15645, cost=500),
    shop_meta(flag=15643, cost=500),
    shop_meta(flag=15641, cost=500),
    shop_meta(flag=15646, cost=1000),
    shop_meta(flag=15647, cost=1000),
    shop_meta(flag=15648, cost=1000),
    shop_meta(flag=15649, cost=1000),
    shop_meta(flag=15650, cost=1000),
    shop_meta(flag=15651, cost=1000),
    shop_meta(flag=15652, cost=1500),
    shop_meta(flag=15653, cost=1500),
    shop_meta(flag=15654, cost=1500),
    shop_meta(flag=15655, cost=1500),
    
    // unused shop_meta(flag=15656, cost=170)
]

function total_pearls_spent() => sum_of(shop_items, i => global_flag(i["flag"]) * i["cost"])

function shop_milestone_meta(title, threshold, points) => {"title": title,  "threshold": threshold, "points": points}
shop_milestones = [
    shop_milestone_meta("Another Shopping Spree", 5000, 5),
    shop_milestone_meta("More Clothes, More Music", 15000, 5)
]

for m in shop_milestones {
    achievement(
        title = m["title"],
        description = format("Buy {0} pearls' worth of items in Jojiro's shop.", m["threshold"]),
        trigger = game_state_is("Shop") && prev(total_pearls_spent()) < m["threshold"] && measured(total_pearls_spent() >= m["threshold"]),
        points = m["points"]
    )
}

achievement(
    title = "Lovely Would Be Proud",
    description = "Buy everything from Jojiro's shop and obtain an additional reward.",
    trigger = game_state_is("Shop") && just_increased(global_flag(15656)),
    points = 10
)

// Other Collectibles

function clothing_sum(prev=-1) {
    if (prev > 0)
        arr = merge_arrays(array_map(range(15101, 15150), a => prev(global_flag(a))),
            array_map(range(15201, 15249), a => prev(global_flag(a))))
    else
        arr = merge_arrays(array_map(range(15101, 15150), a => global_flag(a)),
            array_map(range(15201, 15249), a => global_flag(a)))
    return sum_of(arr, a => a)
}

achievement(
    title = "Full Wardrobe for Both Siblings",
    description = "Collect all 99 clothing and accessories.",
    points = 25,
    trigger = stayed_same(active_file()) && clothing_sum(prev=1) == 98 && measured(clothing_sum() == 99, when=file_is_selected())
)

function music_sum(prev=-1) {
    if (prev > 0)
        arr = merge_arrays(array_map(range(15600, 15638), a => prev(global_flag(a))),
            array_map(range(15640, 15656), a => prev(global_flag(a))))
    else
        arr = merge_arrays(array_map(range(15600, 15638), a => global_flag(a)),
            array_map(range(15640, 15656), a => global_flag(a)))
    return sum_of(arr, a => a)
}

achievement(
    title = "Legendary Sea Jams",
    description = "Collect all 56 music tracks.",
    points = 10,
    trigger = stayed_same(active_file()) && music_sum(prev=1) == 55 && measured(music_sum() == 56, when=file_is_selected())
)

trading_cards_arr = [bit(3, 0x8693) * 93, 
bitcount(0x8697),
bitcount(0x8698),
bitcount(0x8699),
bitcount(0x869A) - bit6(0x869A),
bitcount(0x869B) - bit7(0x869B),
bitcount(0x869C) - bit2(0x869C),
bitcount(0x869D),
bitcount(0x869E),
bitcount(0x869F),
bitcount(0x86A0),
bit0(0x86A1) + bit1(0x86A1),
bit4(0x86A3) + bit5(0x86A3) + bit6(0x86A3) + bit7(0x86A3),
bitcount(0x86A4),
bitcount(0x86A5),
bitcount(0x86A6) - bit1(0x86A6) - bit6(0x86A6),
bitcount(0x86A7) - bit1(0x86A7),
bitcount(0x86A8) - bit5(0x86A8) - bit6(0x86A8) - bit7(0x86A8),
bit5(0x86A9) + bit6(0x86A9) + bit7(0x86A9),
bit0(0x86AA),
bit7(0x86AF),
bit7(0x86C9),
bit7(0x86CD),
bit5(0x86CE),
bit0(0x86CF) + bit2(0x86CF) + bit5(0x86CF),
bit6(0x86D5) + bit7(0x86D5),
bit0(0x86D8),
bit1(0x86DC),
bit1(0x86E4),
bit2(0x86EB) + bit4(0x86EB),
bit7(0x86EF),
]

function trading_cards_sum(prev=-1) {
    if (prev > 0)
        arr = array_map(trading_cards_arr, a => prev(a))
    else
        arr = array_map(trading_cards_arr, a => a)
    return sum_of(arr, a => a)
}

achievement(
    title = "Complete Catalog",
    description = "Complete all 229 trading cards.",
    points = 25,
    trigger = stayed_same(active_file()) && trading_cards_sum(prev=1) < 229 && trading_cards_sum(prev=1) >= 220 && measured(trading_cards_sum() == 229, when=file_is_selected() && ending_bits[1] != 0)
)

// RP

//game_state__values = {
//    -"Play Area":        0x05,
//    -"Title Screen":     0x08,
//    -"Intro":            0x09,
//    -"File Select":      0x0A,
//    -"Area Select":      0x0B,
//    -"Minigame":         0x0D,
//    -"Clear":            0x0E,
//    -"Staff Roll":       0x0F,
//    -"Sea Jams":         0x10,
//    -"Shop":             0x12,
//    -"Moe House":        0x13,
//    -"Ending":           0x14,
//    -"World Map":        0x15,
//    -"Starfy Dance":     0x16,
//    -"Game Over":        0x18,
//    -"Stuff":            0x19, // only from world map / area select
//    -"Trading Cards":    0x1A
//}

simple_states = {
0x08: "is chilling on the title screen",  
0x09: "is in the intro movie",
0x0A: "is selecting a file",
0x0D: "is playing some minigames",
0x10: "is playing some music with his little band",
0x12: "is visiting Jojiro's shop",
0x13: "is visiting Moe's house",
0x15: "is on the world map",
0x18: "game overed X_X",
0x19: "is dressing up",
0x1A: "is viewing his trading card collection"
}

simple_state__lookup = rich_presence_lookup("SimpleStates", game_state__mem(), simple_states)

character_table = {
    0: "Starfy",
    1: "Starly"
}

char_lookups = {
    "Play Area": rich_presence_lookup("Character", starly_active(), character_table),
    "Starfy Dance": rich_presence_lookup("Character", bit0(0xC408), character_table),
    "Clear": rich_presence_lookup("Character", bit0(0xC554), character_table),
}

stage_nums = {}

for i in range(1, 20) {
    if (i > 10)
        stage_nums[i] = format("{0}", i - 10)
    else
        stage_nums[i] = format("{0}", i)
}

stage_num__lookup = rich_presence_lookup("StageNums", stage__mem(), stage_nums)

stage_names_rp = {}

for i in stages {
    stage_names_rp[i] = stages[i]["stage"]
}
stage_names_rp[10] = "Old Castle"

stage_name__lookup = rich_presence_lookup("StageNames", stage__mem(), stage_names_rp, "an unknown location")
stage_select_name__lookup = rich_presence_lookup("StageNames", byte(0xcda0), stage_names_rp, "an unknown location")

area__value = rich_presence_value("Number", area__mem())
heart__value = rich_presence_value("Number", regular_hearts__mem())
pearls_in_area__value = rich_presence_value("Number", pearls_in_area__mem())

ending_indeces = {
    1: "first",
    3: "first",
    4: "second",
    5: "third",
}

ending__lookup = rich_presence_lookup("Endings", ending_index(), ending_indeces)

credits = {
    0: "first",
    1: "second",
}

credits__lookup = rich_presence_lookup("Credits", ending_index(), credits)

rich_presence_conditional_display(mem_in(game_state__mem(), simple_states), "Starfy {0}", simple_state__lookup)
rich_presence_conditional_display(game_state_is("Play Area") && demo_id__mem() != 0, "Starfy is in a demo movie")
rich_presence_conditional_display(game_state_is("Play Area"), "{0} is in Stage {1}-{2}, {5} | ❤️{3} | ⍟{4}", char_lookups["Play Area"], stage_num__lookup, area__value, heart__value, pearls_in_area__value, stage_name__lookup)
rich_presence_conditional_display(game_state_is("Area Select"), "Starfy is selecting an area in {0}", stage_select_name__lookup)
rich_presence_conditional_display(game_state_is("Clear"), "{0} just cleared an area!", char_lookups["Clear"])
rich_presence_conditional_display(game_state_is("Starfy Dance"), "{0} just defeated a boss! ({0} Dance)", char_lookups["Starfy Dance"])
rich_presence_conditional_display(game_state_is("Ending"), "Starfy is in the {0} ending cutscene", ending__lookup)
rich_presence_conditional_display(game_state_is("Staff Roll"), "Starfy is in the {0} credits roll", credits__lookup)
rich_presence_display("Starfy and Starly are on a legendary adventure")
