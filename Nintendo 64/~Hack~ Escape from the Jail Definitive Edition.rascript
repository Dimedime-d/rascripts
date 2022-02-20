// ~Hack~ Escape from the Jail Definitive Edition
// #ID = 18581
// Made in RATools v1.8.4

// ------------- //
//   u t i l s   //
// ------------- //

function DUMMY_ACHIEVEMENT(title="DUMMY", description="DUMMY", points=0, trigger=always_false()) {
    achievement(
        title=title, description=description, points=points, trigger=trigger
    )
}

function mem_in(mem, arr) {
    return any_of(arr, a => mem == a)
}

function just_increased(mem) => mem > prev(mem)

function just_changed_any(mem) => mem != prev(mem)
function just_changed(mem, from, to) => prev(mem) == from && mem == to
function just_changed_to(mem, to) => prev(mem) != to && mem == to
function just_changed_from(mem, from) => prev(mem) == from && mem != from

function struct_field(struct_def, base, field) => base + struct_def[field]

function object_field(base, field) => struct_field(object__struct, base, field)

// stuff all memory addresses up here, in case another version comes out and I gotta update every bloody address

offsets = {
    "SAVE DATA":    (0x0275a0 - 0x70),
    
    "MUSIC ID":     0x09e3c2,
    
    "GLOBAL TIMER": 0x182080,
    "GLOBAL TIMER OFFSET": 0x182104,
    "FILE ID":      0x182108,
    "MAP ID":       0x18210a,
    
    "DIALOGUE ID":  0x183906,
    "STOOD ON OBJECT":  0x185394,
    "COLLECTED STAR ID":    0x185417,
    
    "HACKTICE FLAG":    0x18b0a5,

    "LEVEL INDEX":  0x18f5a4,
    "MISSION SELECT":   0x18f5a6,
    
    "TIMER RUNNING":    0x1902e3,
    "TRANSITION TYPE":  0x1902ee,
    
    "SUBMAP ID":        0x1902f1,
    
    "HUD FLAGS":   0x190308,   //  https://github.com/n64decomp/sm64/blob/1372ae1bb7cbedc03df366393188f4f05dcfc422/src/game/level_update.h#L91
    "HUD TIMER":   0x19030e,
    
    "MARIO STRUCT": 0x190310,
    "OBJECT ARRAY": 0x190fa4,
    
    "SAVE DATA MODIFIED":   0x1b4be3
}

// ---------------
//   m e m o r y
// ---------------

mario__struct = {
    "hat bitflags":       0x04,  // byte
    "current action":     0x0c,  // dword
    "previous action":    0x10,  // dword
    "floor footstep type":0x14,  // word
    "action phase":       0x18,  // word
    "x":                  0x3c,  // dword (float)
    "y":                  0x40,  // dword (float)
    "z":                  0x44,  // dword (float)
    "wall triangle pointer":    0x60, // dword (pointer to tri)
    "ceiling triangle pointer": 0x64, // dword (pointer to tri)
    "floor triangle pointer":   0x68, // dword (pointer to tri)
    "interaction object": 0x78,  // dword (pointer to object)
    "held object":        0x7C,  // dword (pointer to object)
    "used object":        0x80,  // dword (pointer to object) - like 
    "mario object":       0x88,  // dword (pointer to object)
    "controller":         0x9c,  // dword (pointer to controller struct)
    "nof stars":          0xa8,  // word, NOT HUD
    "nof coins":          0xaa,  // word
    "hp":                 0xac,  // byte / word
    "hp increment":       0xb0,  // byte
    "hp decrement":       0xb1,  // byte
    "cap timer":          0xb4,  // word
}

mario__addr = offsets["MARIO STRUCT"]
stood_on_object__addr = offsets["STOOD ON OBJECT"]

function mario_field(field) => struct_field(mario__struct, mario__addr, field)

function hat_in_hand()        => bit5(mario_field("hat bitflags"))
function hat_on_head()        => bit4(mario_field("hat bitflags"))
function wearing_wing_cap()   => bit3(mario_field("hat bitflags"))
function wearing_metal_cap()  => bit2(mario_field("hat bitflags"))
function wearing_vanish_cap() => bit1(mario_field("hat bitflags"))

function pos_x() => float(mario_field("x"))
function pos_y() => float(mario_field("y"))
function pos_z() => float(mario_field("z"))

function in_3d_box(x1, x2, y1, y2, z1, z2, check_edges=0) {
    cond = always_true()
    
    for coord in [[pos_x(), x1, x2],
                  [pos_y(), y1, y2],
                  [pos_z(), z1, z2]] {
        mem = coord[0]
        c1 = coord[1]
        c2 = coord[2]
        
        if (c1 != c2) {
            if (c1 < c2)
                if (check_edges != 0)
                    cond = cond && mem >= c1 && mem <= c2
                else
                    cond = cond && mem > c1 && mem < c2
            else
                if (check_edges != 0)
                    cond = cond && mem >= c2 && mem <= c1
                else
                    cond = cond && mem > c2 && mem < c1
        }
    }
    return cond
}

function interaction_object() => tbyte(mario_field("interaction object"))
function held_object() => tbyte(mario_field("held object"))
function used_object()  => tbyte(mario_field("used object"))
function mario_object() => tbyte(mario_field("mario object"))
function stood_on_object() => tbyte(stood_on_object__addr)

function controller() => tbyte(mario_field("controller"))

function controller_a_button() => bit(15, controller() + 0x12)

function hp_int() => byte(mario_field("hp") + 1)

function just_took_damage() => prev(hp()) > hp() // no regard for water damage...

function hp() => word(mario_field("hp"))

function hp_increment() => byte(mario_field("hp increment"))
function hp_decrement() => byte(mario_field("hp decrement"))

function cap_time() => word(mario_field("cap timer"))

function nof_stars() => word(mario_field("nof stars"))
function nof_coins() => word(mario_field("nof coins"))

function mario_current_action() => dword(mario_field("current action"))
function mario_previous_action() => dword(mario_field("previous action"))

mario_action__values = {
    "uninitialized":               0x00000000,
    "star dance ground (exit)":    0x00001302,
    "star dance water":            0x00001303,
    "star dance ground (no exit)": 0x00001307,
    "reading sign":                0x00001308,
    "start teleporting":           0x00001336,
    "star grab fall":              0x00001904,
    "airborne spawn":              0x00001924,
    "death exit landing":          0x00020467,
    
    "ground pound landing":        0x0080023C,
    "lava boost":                  0x010208B7,
    "slide kick":                  0x018008AA,
    "air kick":                    0x018008AC,
    "air sitting":                 0x0300088E,
}

function mario_action_is(name) => mario_current_action() == mario_action__values[name]
function mario_prev_action_is(name) => mario_previous_action() == mario_action__values[name]

function mario_action_changed_to(name) {
    return prev(mario_current_action()) != mario_action__values[name]
        && mario_current_action() == mario_action__values[name]
}

star_grab_actions = ["star dance ground (exit)", "star dance water", "star dance ground (no exit)", "star grab fall"]

function airborne() => bit3(mario_action__addr + 1) != 0
function on_pole() => bit4(mario_action__addr + 2) != 0

// ----------------- //
//   o b j e c t s   //
// ----------------- //


// https://github.com/n64decomp/sm64/blob/1372ae1bb7cbedc03df366393188f4f05dcfc422/include/types.h#L142

// and https://github.com/n64decomp/sm64/blob/1372ae1bb7cbedc03df366393188f4f05dcfc422/include/object_fields.h#L53
object__struct = {
    "graph node flags":      0x00,
    "animation":             0x3A,  // word (NEW)
    "active":                0x76,  // word
    "num collided objects":  0x74,  // word
    "collided object 1":     0x78,  // dword (pointer to object)
    "collided object 2":     0x7c,  // dword (pointer to object)
    "collided object 3":     0x80,  // dword (pointer to object)
    "collided object 4":     0x84,  // dword (pointer to object)
    "speedy trials end time":0xf4,  // dword
    "eyerok hands remaining":0xf8,  // dword
    "action":               0x14c,  // dword
    "timer":                0x154,  // dword
    "hp":                   0x184,  // dword
    "behaviour script":     0x20c,  // dword
}
object__sizeof = 0x260

behaviour_script__values = {
    "music switcher":       0x80263040,
    "red coin radar":       0x80263068,
    "speedy trials timer":  0x80263210,
    "goomba from triplet":  0x8026429c,
    "naked koopa":          0x8026443c,
    "small bully":          0x80265468,
    "king bobomb":          0x8026884c,
}

function object_graph_invisible(addr) => bit4(object_field(addr, "graph node flags"))
function object_graph_animation_active(addr) => bit5(object_field(addr, "graph node flags"))

function object_is_active(addr) => word(object_field(addr, "active")) == 0x0101
function object_was_active(addr) => prev(word(object_field(addr, "active"))) == 0x0101
function object_just_deactivated(addr) => object_was_active(addr) && !object_active(addr)

function object_is(addr, name) => dword(object_field(addr, "behaviour script")) == behaviour_script__values[name]

function object_num_collided_objects(addr) => word(object_field(addr, "num collided objects"))
function object_nth_collided_object(addr, n) => tbyte(object_field(addr, format("collided object {0}", n)))

function object_anim(addr) => word(object_field(addr, "animation"))
function object_action(addr) => dword(object_field(addr, "action"))

OBJ_ACTION_LAVA_DEATH = 100

function object_timer(addr) => dword(object_field(addr, "timer"))

// object specific
function object_king_bobomb_hp(addr) => dword(object_field(addr, "hp"))

function object_king_bobomb_fight_started(addr) => prev(object_action(addr)) == 0 && object_action(addr) == 2
// we don't need to consider if the fight ended, as there is almost no height variation in the boss arena

// https://github.com/aglab2/HackerSM64/blob/a2f94e79fa0a6458d74cdd14f70985f5d9d5f629/src/game/behaviors/aglab.inc.c#L171
function object_speedy_trials_started(addr) => prev(object_action(addr)) == 0 && object_action(addr) == 1
function object_speedy_trials_finished(addr) => prev(object_action(addr)) == 1 && object_action(addr) == 2
function object_speedy_trials_time_left(addr) => 3600 - object_timer(addr) * 2
function object_speedy_trials_end_time(addr) => dword(object_field(addr, "speedy trials end time"))

// Mario Object specific stuff

// watch out for animation value collisions (ex: airborne spawn and falling out of water both use general fall, 0x56)
mario_anim__values = {
    "Water Star Dance": 0xB3,
    "Star Dance":       0xCD,
}

function mario_anim() => object_anim(mario_object())

function mario_anim_is(name) => mario_anim() == mario_anim__values[name]
function mario_anim_changed_to(name) => prev(mario_anim()) != mario_anim__values[name] && mario_anim_is(name)

star_dance_anim_values = ["Water Star Dance", "Star Dance"]

// note: really shitty hacks might have death floors near stars, 
// or you can fade-to-black from a death floor before the star dance animation (see: the TAS for the monkey star in vanilla TTM)
// this animation check should nevertheless work in most cases...

function just_collected_star(star_index=-1, trigger=0) {
    cond = any_of(star_dance_anim_values, a => mario_anim_changed_to(a))
    if (trigger != 0)
        cond = any_of(star_dance_anim_values, a => trigger_when(mario_anim_changed_to(a)))
    if (star_index != -1)
        return cond && trigger_when(last_star__mem == star_index)
    return cond
}

// --------------------------- //
//   o b j e c t   a r r a y   //
// --------------------------- //

object_array__addr = offsets["OBJECT ARRAY"]

function nth_array_object(index) => object_array__addr + (index * object__sizeof)

function array_object_index_is(obj_addr, index) => ((obj_addr - object_array__addr) / object__sizeof) == index

function array_object_is_active(index) => object_is_active(nth_array_object(index))
function array_object_was_active(index) => object_was_active(nth_array_object(index))
function array_object_just_deactivated(index) => array_object_was_active(index) && !array_object_is_active(index)

function array_object_is(index, name) => object_is(nth_array_object(index), name)

function array_object_num_collided_objects(index)   => object_num_collided_objects(nth_array_object(index))
function array_object_nth_collided_object(index, n) => object_nth_collided_object(nth_array_object(index), n)

function array_object_action(index) => object_action(nth_array_object(index))

function array_object_bowser_hp(index) => object_bowser_hp(nth_array_object(index))

object_indexes = { // try to only use this as a fallback, as this can change between updates...
    "Speedy Trials": {"Speedy Trials Timer": 13},
    "Rainbow Heavens": {"Red Coin Radar": 86},
    "Lava Wasteland": {"Music Switcher": 110},
    "VS King Bob-omb": {"King Bob-omb": 2}
}

// ---------------
//   m e m o r y
// ---------------

hacktice__addr = offsets["HACKTICE FLAG"]

function hacktice_enabled() => bit0(hacktice__addr)

function pause_lock_hacktice_in_level(name) => disable_when(hacktice_enabled() == 1, until=!in_level(name))

timer_counting__addr = offsets["TIMER RUNNING"]

function hud_timer_counting() => bit0(timer_counting__addr)

function hud_timer_started_counting() => prev(hud_timer_counting()) == 0
    && hud_timer_counting() == 1
    
function hud_timer_stopped_counting() => prev(hud_timer_counting()) == 1
    && hud_timer_counting() == 0

hud_flags__addr = offsets["HUD FLAGS"]

function hud_stars_shown() => bit2(hud_flags__addr)
function hud_timer_shown() => bit6(hud_flags__addr)

hud_timer__addr = offsets["HUD TIMER"]

function hud_timer() => word(hud_timer__addr)

file_num__addr = offsets["FILE ID"]
file_num__mem = byte(file_num__addr)

save_data_base__addr = offsets["SAVE DATA"]
current_file__addr = save_data_base__addr + 0x70 * file_num__mem

function pressed_switch__mem(color, delta="f"){
    switch_mem = always_false
    if color == "red"
        switch_mem = bit1(current_file__addr + 8)
    else if color == "green"
        switch_mem = bit2(current_file__addr + 8)
    else if color == "blue"
        switch_mem = bit3(current_file__addr + 8)
     
    if delta == "true"
        return prev(switch_mem)
    else
        return switch_mem
}

function pressed_switch(color, delta){
    return pressed_switch__mem(color, delta) == 1
}

global_timer__addr = offsets["GLOBAL TIMER"]
global_timer_offset__addr = offsets["GLOBAL TIMER OFFSET"]

function global_timer() => dword(global_timer__addr)
function global_timer_offset() => dword(global_timer_offset__addr)

function saved_time() => dword(current_file__addr + 4) // OK for LB's, RP must be updated in real-time
function global_real_time() => saved_time() + global_timer() - global_timer_offset()

mission_id__addr = offsets["MISSION SELECT"]
mission_id__mem = byte(mission_id__addr)

// normal starts = 1-6; 100 coin star = 7
last_star__addr = offsets["COLLECTED STAR ID"]
last_star__mem = byte(last_star__addr)

sublevel_id__addr = offsets["SUBMAP ID"]
sublevel_id__mem  = byte(sublevel_id__addr)

level_id__addr = offsets["MAP ID"]
level_id__mem = byte(level_id__addr)

function course_meta(value, sublevel_values, full_name) => {"value": value, "sublevel values": sublevel_values, "full name": full_name}

course_infos = {
    "Overworld 1":      course_meta(0x06, -1,   "Inside the Jail"), // Inside Castle
    "Overworld 2":      course_meta(0x1a, -1,   "Outside the Jail"),
    
    "Course 1":         course_meta(0x09, -1,   "Goomba Valley"),
    "Course 2":         course_meta(0x18, -1,   "Poisoned Winter"),
    "Course 3":         course_meta(0x0c, -1,   "Bitter Badlands"),
    "Course 4":         course_meta(0x05, -1,   "Strange Sewers"),
    "Course 5":         course_meta(0x04, -1,   "Ampersand Furnace"),

    "MIPS Area":        course_meta(0x10,  1,   "Outside the Speedy Trial"),
    "Runaway Star":     course_meta(0x10,  2,   "Runaway Star"),
    
    "Slide":            course_meta(0x1b, -1,   "Scary Secret Slide"),
    "Tropical Resort":  course_meta(0x1c, -1,   "Tropical Resort"),
    "Rainbow Heavens":  course_meta(0x1d, -1,   "Rainbow Heavens"),
    "Lava Wasteland":   course_meta(0x1f, -1,   "100 Coins in a Lava Wasteland"),

    "VS Bully":         course_meta(0x13, -1,   "VS Bully"),
    "VS Mr. I":         course_meta(0x14, -1,   "VS Mr. I"),
    
    "Speedy Trials":    course_meta(0x1e, -1,   "Speedy Trials Challenge"), // B1 fight
    "VS King Bob-omb":  course_meta(0x22, -1,   "VS King Bob-omb"), // B3 fight
    
    "Bowser 3":         course_meta(0x15, -1,   "King Bob-omb's Fortress"), // B3 course
    
    "Credits":          course_meta(0x16, -1,   "Credits Scene"), // actually LLL
}

function in_title_or_file_select() => level_id__mem == 1

function in_level(name, check_sublevels=1, delta=0) {
    course_mem = level_id__mem
    if (delta != 0) {
        course_mem = prev(level_id__mem)
    }
    course_value = course_infos[name]["value"]
    cond = course_mem == course_value
    if (check_sublevels != 0) {
        return cond && in_sublevel(name)
    }
    return cond
}

function in_sublevel(name) {
    if (course_infos[name]["sublevel values"] == -1) {return always_true()}
    
    // used to be an any_of statement but RATools won't let me compare an array to an integer constant :|
    return sublevel_id__mem == course_infos[name]["sublevel values"]
}

function in_same_level_from_last_frame() => level_id__mem == prev(level_id__mem) && sublevel_id__mem == prev(sublevel_id__mem)

function remained_in_level(name) => never(!in_level(name)) && once(prev(level_id__mem) != course_infos[name]["value"]) && hud_stars_shown() == 1 // beware for open-world type hacks...
function remained_in_sublevel(name) => never(!in_sublevel(name)) && once(prev(sublevel_id__mem) != course_infos[name]["sublevel values"]) && hud_stars_shown() == 1

// safety for checking "killed all enemies" challenges
function level_loaded() => repeated(2, hud_stars_shown() == 1) && unless(hud_stars_shown() == 0)

function course_stars_meta(save_offset, points, title, id=0, badge="0") => {"save offset": save_offset, "points": points, "title": title, "id": id, "badge": badge}

course_offsets = { // bytes offset from start of EEPROM, handle secret stars separately...
    1:  course_stars_meta(0x0f, 10, "Lots of Enemies in this Valley", id=198863, badge="220971"),
    2:  course_stars_meta(0x0e, 10, "Ruined Snowscape",               id=198864, badge="220972"),
    3:  course_stars_meta(0x0d, 10, "Conquered the Badlands",         id=198865, badge="220973"),
    4:  course_stars_meta(0x0c, 10, "Plumbing Work",                  id=198866, badge="220974"),
    5:  course_stars_meta(0x13, 10, "Hotty Hot Exploration",          id=198867, badge="220975"),
}

function course_stars_count(course_num, is_delta) {
    off = current_file__addr + course_offsets[course_num]["save offset"]
    mem = bitcount(off) - bit(7, off)
    if is_delta == "True"
        return prev(mem)
    return mem
}

for num in course_offsets {
    tot = 7
    course_info = course_infos[format("Course {0}", num)]
    achievement(
        title = course_offsets[num]["title"],
        description = format("Collect all 7 stars in {0}.", course_info["full name"]),
        points = course_offsets[num]["points"],
        trigger = in_level(format("Course {0}", num))        
            && course_stars_count(num, "True") == tot - 1
            && measured(course_stars_count(num, "False") == tot),
        id = course_offsets[num]["id"],
        badge = course_offsets[num]["badge"]
    )
}

// 
// Other Achievements (all course stars are above...)
//

// "challenges"

achievement(
    title="How to Cross the Lava",
    description="In Course 1 (mission 4, 5, or 6), collect the star 'At the End of the Lava Source' without taking damage.",
    points=4,
    trigger=remained_in_level("Course 1")
        && pause_lock_hacktice_in_level("Course 1")
        && mission_id__mem >= 4 && mission_id__mem <= 6
        && never(just_took_damage())
        && just_collected_star(4, trigger=1),
    id=198872,
    badge="220980"
)

achievement(
    title="Quick Capless Star",
    description="In Course 2, collect the star 'Check the Ice Cap' without getting an ice cap.",
    points=5,
    trigger=remained_in_level("Course 2")
        && pause_lock_hacktice_in_level("Course 2")
        && never(wearing_metal_cap() == 1)
        && just_collected_star(5, trigger=1),
    id=198873,
    badge="220981"
)

function all_bullies_died() {
    dead_bullies = []
    for i in range(0, 239) {
        nth_obj = nth_array_object(i)
        array_push(dead_bullies,
            repeated(8, object_is(nth_obj, "small bully")
            && object_is_active(nth_obj)
            && just_changed_to(object_action(nth_obj), OBJ_ACTION_LAVA_DEATH)))
    }
    
    return measured(tally(8, dead_bullies))
}

achievement(
    title="Bully Eliminator",
    description="In Course 3, boil all eight bullies (requires ice cap, bullies boiling themselves count).",
    points=5,
    trigger=never(!in_level("Course 3")) && unless(in_level("Course 3") && sublevel_id__mem != 1)
        && pause_lock_hacktice_in_level("Course 3")
        && all_bullies_died(),
    id=198874,
    badge="220982"
)

a = []
for i in range(0, 239) {
    nth_obj = nth_array_object(i)
    array_push(a, once(object_is(nth_obj, "small bully")))
}

achievement(
    title="Struck Gold in the Sewers",
    description="Collect 200 coins in Strange Sewers.",
    points=5,
    trigger=in_level("Course 4") 
        && pause_lock_hacktice_in_level("Course 4")
        && in_same_level_from_last_frame() && measured(nof_coins() >= 200, when=in_level("Course 4")),
    id=198875,
    badge="220983"
)

achievement(
    title="It Is About Health Management",
    description="In Course 5, collect the star 'It Is About Burning' without going below half HP.",
    points=5,
    trigger=remained_in_level("Course 5")
        && pause_lock_hacktice_in_level("Course 5")
        && never(hp() < 0x400)
        && just_collected_star(3, trigger=1),
    id=198876,
    badge="220984"
)

achievement(
    title="More Than 100 Coin Comet",
    description="Collect 104 coins in the Lava Wasteland.",
    points=3,
    trigger=in_level("Lava Wasteland") 
        && pause_lock_hacktice_in_level("Lava Wasteland") 
        && (trigger_when(prev(nof_coins()) < 104 && nof_coins() >= 104) || (prev(nof_coins()) < 104 && measured(nof_coins() >= 104, when=in_level("Lava Wasteland")))),
    id=198877,
    badge="220985"
)

red_radar = nth_array_object(object_indexes["Rainbow Heavens"]["Red Coin Radar"])

achievement(
    title="No Backseating Needed",
    description="In Ranbow Heavens, collect the red coin star without the red coin radar (turn off radar within 1 sec of entering).",
    points=3,
    trigger=remained_in_level("Rainbow Heavens")
        && pause_lock_hacktice_in_level("Rainbow Heavens")
        && never(repeated(60, object_is(red_radar, "red coin radar")
            && object_is_active(red_radar)
            && object_graph_invisible(red_radar) == 0)) // level entry
        && never(object_is(red_radar, "red coin radar")
            && object_is_active(red_radar)
            && prev(object_graph_invisible(red_radar)) == 1
            && object_graph_invisible(red_radar) == 0)
        && just_collected_star(1, trigger=1),
    id=198878,
    badge="220986"
)

achievement(
    title="An Easy Resort",
    description="Collect the red coin star in Tropical Resort without taking damage.",
    points=2,
    trigger=remained_in_level("Tropical Resort")
        && pause_lock_hacktice_in_level("Tropical Resort")
        && never(hp_decrement() > 0)
        && just_collected_star(2, trigger=1),
    id=198879,
    badge="220987"
)

achievement(
    title="Lava Evader",
    description="Collect the runaway star in the jail without taking damage.",
    points=5,
    trigger= remained_in_level("Runaway Star")
        && pause_lock_hacktice_in_level("Runaway Star")
        && never(just_took_damage())
        && just_collected_star(trigger=1),
    id=198888,
    badge="220996"
)

king_bobomb = nth_array_object(object_indexes["VS King Bob-omb"]["King Bob-omb"])

achievement(
    title="A Fairer Fight",
    description="Defeat King Bob-omb without pressing the A button during the fight.",
    points=10,
    trigger=never(!in_level("VS King Bob-omb"))
        && pause_lock_hacktice_in_level("VS King Bob-omb")
        && once(object_is(king_bobomb, "king bobomb") && object_king_bobomb_fight_started(king_bobomb))
        && never(controller_a_button() != 0)
        && trigger_when(object_is(king_bobomb, "king bobomb") && prev(object_king_bobomb_hp(king_bobomb)) == 1 && object_king_bobomb_hp(king_bobomb) == 0),
    id=198880,
    badge="220988"
)

// m i l e s t o n e s

achievement(
    title="The First Jail Guardian",
    description="Defeat the big Mr. I and collect its star.",
    points=1,
    trigger=in_level("VS Mr. I") && just_collected_star(),
    id=198881,
    badge="220989"
)

achievement(
    title="Escaped the Speedy Trials",
    description="Collect the star that's actually a key in the Speedy Trials Challenge.",
    points=5,
    trigger=in_level("Speedy Trials") && just_collected_star(),
    id=198889,
    badge="220997"
)

achievement(
    title="The Key Outta Here",
    description="Defeat the big bully and collect its star.",
    points=3,
    trigger=in_level("VS Bully") && just_collected_star(),
    id=198882,
    badge="220990"
)

function beat_game() => in_level("VS King Bob-omb", delta=1) && in_level("Credits")

achievement(
    title="Successful Escapee",
    description="Make it to Peach's Castle after the final boss. To be continued in Ztar Attack!",
    points=10,
    trigger = beat_game(),
    id=198868,
    badge="220976"
)

function star_milestone_trigger(num_stars) {
    return measured(nof_stars() == num_stars, when=!in_title_or_file_select())
        && prev(nof_stars()) == num_stars - 1
        && level_id__mem == prev(level_id__mem) // to prevent switching files after the ending picture puts you back to the title screen...
}

achievement(
    title="Full Exploration",
    description="Collect all 50 stars in the jail.",
    points=10,
    trigger = star_milestone_trigger(50),
    id=198887,
    badge="220995"
)

// switches
function rgb_trigger() {
    return level_id__mem == prev(level_id__mem) // to prevent switching files after the ending picture puts you back to the title screen...
    
    && tally(2, 
    [once(pressed_switch("red", "true")),
    once(pressed_switch("green", "true")),
    once(pressed_switch("blue", "true"))
    ])
    
    && measured(tally(3, 
    [once(pressed_switch("red", "f")),
    once(pressed_switch("green", "f")),
    once(pressed_switch("blue", "f"))
    ]), when=!in_title_or_file_select())
    
    && never(tally(3, 
    [once(pressed_switch("red", "true")),
    once(pressed_switch("green", "true")),
    once(pressed_switch("blue", "true"))
    ]))
}

achievement(
    title = "Powerups of the Jail",
    description = "Press the wing, ice, and vanish cap switches.",
    points = 5,
    trigger = rgb_trigger(),
    id=198869,
    badge="220977"
)

// funny stuff

function jail_softlock_trigger() {
    boxes = [ // when you go back to spawn... (note: y-coord is just a placeholder)
        [-2499.0, -4975.0, 200, 100, 382.0, 717.0], // two cells to left
        [-2687.0, -5683.0, 200, 100, -1279.0, -542.0], // two cells to right
        [-6576.0, -6965.0, 200, 100, 2460.0, 152.0], // two cells in the back
        [-5315.0, -5603.0, 200, 100, 1062.0, 3592.0] // two cells opposite spawn cell
    ]
    
    return in_level("Overworld 1") && sublevel_id__mem == 1
        && wearing_vanish_cap() == 0 
        && any_of(boxes, b => in_3d_box(b[0], b[1], 165.0, 1200.0, b[4], b[5], check_edges=1)) 
}

achievement(
    title = "Stuck Forever?",
    description = "Lock yourself inside of one of the jail cells in the starting area (see comment).",
    points = 3,
    trigger = jail_softlock_trigger(),
    id=198870,
    badge="220978"
)

music_switcher = nth_array_object(object_indexes["Lava Wasteland"]["Music Switcher"])

achievement(
    title = "What's Taking You so Long?",
    description = "In Lava Wasteland, let the music fully loop for some funny text to briefly appear.",
    points = 1,
    trigger = in_level("Lava Wasteland")
    && trigger_when(object_action(music_switcher) == 3
    && object_timer(music_switcher) == 1330),
    id=198871,
    badge="220979"
)

// LB's / speedrun cheevs

function int_seconds_to_frames(sec) => sec * 30

speedy_timer = nth_array_object(object_indexes["Speedy Trials"]["Speedy Trials Timer"])

leaderboard(
    title = "Speedy Trials - Remaining Time",
    description="Collect the star in Speedy Trials Challenge as fast as possible",
    start = in_level("Speedy Trials")
        && object_speedy_trials_started(speedy_timer),
    cancel = !in_level("Speedy Trials") || hacktice_enabled() == 1,
    submit = object_speedy_trials_finished(speedy_timer),
    value = max_of(
        measured(2*object_speedy_trials_time_left(speedy_timer), when=object_action(speedy_timer) == 1),
        measured(2*object_speedy_trials_end_time(speedy_timer), when=object_action(speedy_timer) == 2)),
    format = "FRAMES",
    lower_is_better = false
)

achievement(
    title= "A Speedy Sprint",
    description= "Complete the Speedy Trials Challenge with at least one minute remaining.",
    points= 10,
    trigger = pause_lock_hacktice_in_level("Speedy Trials")
        && object_action(speedy_timer) > 0
        && prev(object_timer(speedy_timer)) <= 0x708
        && trigger_when(object_speedy_trials_finished(speedy_timer)
        && object_speedy_trials_end_time(speedy_timer) >= int_seconds_to_frames(60)),
    id=198883,
    badge="220991"
)

leaderboard(
    title="Scary Secret Slide Time",
    description="Cross the finish line in Scary Secret Slide as fast as possible",
    start = in_level("Slide")
        && hud_timer_started_counting()
        && hud_timer_shown() == 1,
    cancel = !in_level("Slide") || hud_timer_shown() == 0 ||    hacktice_enabled() == 1,
    submit = hud_timer_stopped_counting()
        && hud_timer_shown() == 1
        && hud_timer() > 0,
    value = 2*hud_timer(),
    format = "FRAMES",
    lower_is_better=true
)

achievement(
    title="Impressed the Sign",
    description="Complete the Scary Secret Slide in under 22 seconds.",
    points=10,
    trigger = pause_lock_hacktice_in_level("Slide")
        && hud_timer_shown() == 1
        && hud_timer() > 0
        && hud_timer() < int_seconds_to_frames(22)
        && trigger_when(hud_timer_stopped_counting()),
    id=198884,
    badge="220992"
)

leaderboard(
    title = "Any% Speedrun",
    description = "Beat the game as fast as possible (minimum 20 stars, reloading allowed)",
    start = beat_game(),
    cancel = always_false(),
    submit = always_true(),
    value = 2*saved_time(),
    format = "FRAMES",
    lower_is_better = true
)

achievement(
    title = "A Rapid Escape",
    description = "Beat the game in under 30 minutes (reloading allowed, see RP for time).",
    points = 10,
    trigger = beat_game() && saved_time() < int_seconds_to_frames(30 * 60),
    id=198885,
    badge="220993"
)

leaderboard(
    title = "100% Speedrun",
    description = "Collect all 50 stars, then beat the game as fast as possible (reloading allowed)",
    start = beat_game() && nof_stars() >= 50,
    cancel = always_false(),
    submit = always_true(),
    value = 2*saved_time(),
    format = "FRAMES",
    lower_is_better = true
)

achievement(
    title = "Cleaned Out the Jail",
    description = "Beat the game with all 50 stars in under 1 hour 15 minutes (reloading allowed, see RP for time).",
    points = 25,
    trigger = beat_game() && nof_stars() >= 50 && saved_time() < int_seconds_to_frames(75 * 60),
    id=198886,
    badge="220994"
)

// RP

general_level_dict = {
    0x06:   "planning his escape from inside the jail",
    0x1a:   "in a strange forest outside the jail",
    
    0x09:   "facing familiar enemies in Goomba Valley",
    0x18:   "looking for lost stars in Poisoned Winter",
    0x0c:   "taking on the Bitter Badlands",
    0x05:   "being an ordinary plumber in the Strange Sewers",
    0x04:   "facing the trials of Ampersand Furnace",
    
    0x1b:   "exploring the Scary Secret Slide",
    0x1c:   "chilling in the Tropical Resort",
    0x1d:   "platforming up high in Rainbow Heavens",
    0x1f:   "collecting coins in a lava wasteland",
    
    0x13:   "fighting the Bully jail guardian",
    0x14:   "fighting the Mr. I jail guardian",
    
    0x1e:   "running for his life in Speedy Trials",
    0x22:   "fighting King Bob-omb",
    
    0x15:   "within King Bob-omb's Fortress",
}

level__lookup = rich_presence_lookup("GeneralLevels", level_id__mem, general_level_dict, "in an unbeknownst location")

level_10__lookup = rich_presence_lookup("Level10", sublevel_id__mem, {
    0x01:   "outside the Speedy Trials",
    0x02:   "chasing a runaway star in the jail"
})

stars__value = rich_presence_macro("Number", nof_stars())

// avoid repetitious code
// cond: condition specific to this RP string
// lookup: rich presence lookup detailing Mario's actions in a particular level
function rp_cond_display_same_display(cond, lookup) {
    rich_presence_conditional_display(cond, 
    "Mario is {0} [{1}⭐] Caps: [{2}{3}{4}] [⏰{5}]", lookup, stars__value,
        rich_presence_lookup("VanishCap", pressed_switch__mem("blue"), {1:"🔵"}),
        rich_presence_lookup("IceCap", pressed_switch__mem("green"), {1:"⚪"}),
        rich_presence_lookup("WingCap", pressed_switch__mem("red"), {1:"🔴"}),
        rich_presence_macro("Seconds", global_real_time() / 30))   
        // RATools is a dumbo and replaces this with * 0.333333333333, so replace that accessor with B:0xX182104/30_I:0xH182108*112_A:0xX027534/30_M:0xX182080/30
}

cond_displays = {
    "general": {"cond": mem_in(level_id__mem, general_level_dict), "lookup": level__lookup},
    "level10": {"cond": (level_id__mem == 0x10), "lookup": level_10__lookup}
}

rich_presence_conditional_display(
    (in_level("VS King Bob-omb") && any_of(star_grab_actions, ac => mario_action_is(ac))) || in_level("Credits"),
    "Mario has escaped from the jail [⭐{0}] [⏰{1}]", stars__value, rich_presence_value("TimeFrames", saved_time()*2, "FRAMES")
)
for k in cond_displays {
    rp_cond_display_same_display(cond_displays[k]["cond"], cond_displays[k]["lookup"])
}
rich_presence_display("Mario is beginning is adventure to escape from the jail")