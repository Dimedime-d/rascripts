// ~Hack~ STUPID BALLZ 2.5: Remnant of Brown
// #ID = 22052
// Made in RATools 1.10.2

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

function just_changed_any(mem) => mem != prev(mem)
function just_changed(mem, from, to) => prev(mem) == from && mem == to
function just_changed_to(mem, to) => prev(mem) != to && mem == to
function just_changed_from(mem, from) => prev(mem) == from && mem != from

function struct_field(struct_def, base, field) => base + struct_def[field]

// return a sequence incrementing by 1 from a specified starting value, for a specified length. convert to badge id strings if necessary.
function sequence(start, length, badge=0) {
    arr = range(start, start+length-1, 1)
    if (badge != 0)
        arr = array_map(arr, a => format("{0}", a))
    return arr
}

offsets = {
    "SAVE DATA":    (0x207700 - 0x70),
    
    "MUSIC ID":     0x22261e,

    "CURRENT DEMO INPUT":   0x32d5f0,
    "COLLECTED STAR ID":    0x32dd87, // 1-indexed
    "FILE ID":              0x32ddf6,
    "MAP ID":               0x32ddfa,
    
    "STOOD ON OBJECT":      0x330e34,
    "DIALOGUE ID":          0x331486,
    
    "LEVEL INDEX":      0x33bac8,
    "WARP DEST":        0x33b248,
    
    "TIME COUNTING":    0x33b25e,
    "HUD FLAGS":        0x33b268,   //  https://github.com/n64decomp/sm64/blob/1372ae1bb7cbedc03df366393188f4f05dcfc422/src/game/level_update.h#L91
    "HUD TIMER":        0x33b26e,
    
    "WARP TRANSITION":  0x33bab0,
    "MISSION ACTIVE":   0x33baca,
    
    "MARIO STRUCT":     0x33b170,
    "OBJECT ARRAY":     0x33d488,
    
    "RED COINS COLLECTED":  0x3613fd,
}

// double-check this list between hacks, custom objects can shift things...
behaviour_script__values = { 
    "mr. i":            0x800EB1D4,
    "warp pipe":        0x800EB920,
    "purple switch":    0x800EC62C,
    "big boo":          0x800ED8E8,
    "scuttlebug":       0x800EDCDC,
    "king whomp":       0x800EDD38,
    
    "mission star manager": 0x800EE1C8,
    
    "impartial 1-up":   0x800EF15C, //
    "stationary 1-up":  0x800EF1FC,
    "running away 1-up":0x800EF190,
    "activator 1-up":   0x800EF26C, //
    "chasing 1-up":     0x800EF2C8,
    
    "wiggler":          0x800EFA18,
    "mr. blizzard":     0x800EFF3C,
    
    "regular star":     0x800EEFBC, // 
    "spawned star":     0x800EEFE4, //
    "box star":         0x800EB978,
    //"100 coin star":  0x800EB98C, shouldn't ever be used in this hack
}

// ---------------
//   m e m o r y
// ---------------

mario__struct = { // https://github.com/n64decomp/sm64/blob/master/include/types.h
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
    "ridden object":      0x84,  // dword (pointer to object) - like 
    "mario object":       0x88,  // dword (pointer to object)
    "controller":         0x9c,  // dword (pointer to controller struct)
    "nof stars":          0xa8,  // word, NOT HUD
    "nof coins":          0xaa,  // word
    "hp":                 0xac,  // byte / word
    "nof lives":              0xae,  // byte
    "hp increment":       0xb0,  // byte
    "hp decrement":       0xb1,  // byte
    "cap timer":          0xb4,  // word
    
    "timer running":      0xed,  // bool
    "coin display":       0xf0,  // word
}

function mario_field(field) => struct_field(mario__struct, mario__addr, field)

mario__addr = offsets["MARIO STRUCT"]
stood_on_object__addr = offsets["STOOD ON OBJECT"]

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

function mario_wall_tri() => tbyte(mario_field("wall triangle pointer"))
function mario_ceil_tri() => tbyte(mario_field("ceiling triangle pointer"))
function mario_floor_tri() => tbyte(mario_field("floor triangle pointer"))

function interaction_object() => tbyte(mario_field("interaction object"))
function held_object() => tbyte(mario_field("held object"))
function ridden_object() => tbyte(mario_field("ridden object"))
function used_object()  => tbyte(mario_field("used object"))
function mario_object() => tbyte(mario_field("mario object"))
function stood_on_object() => tbyte(stood_on_object__addr)

function controller() => tbyte(mario_field("controller"))

// https://github.com/n64decomp/sm64/blob/1372ae1bb7cbedc03df366393188f4f05dcfc422/include/PR/os_cont.h#L122

//and https://github.com/n64decomp/sm64/blob/1372ae1bb7cbedc03df366393188f4f05dcfc422/include/types.h#L23
function controller_a_button() => bit(15, controller() + 0x12)
function controller_b_button() => bit(14, controller() + 0x12)
function controller_z_button() => bit(13, controller() + 0x12)

function hp_int() => byte(mario_field("hp") + 1)

function just_took_damage() => prev(hp()) > hp() // no regard for water damage...

function hp() => word(mario_field("hp"))

function hp_increment() => byte(mario_field("hp increment"))
function hp_decrement() => byte(mario_field("hp decrement"))

function cap_time() => word(mario_field("cap timer"))

nof_lives__addr = mario_field("nof lives")

function nof_stars() => word(mario_field("nof stars"))
function nof_coins() => word(mario_field("nof coins"))

// need to trick the compiler to not optimize out an impossible condition
// your max hp is capped at 0x880
function impossible_condition() => hp() == 9001

function coin_display() => word(mario_field("coin display"))

function got_red_coin() => nof_coins() == prev(nof_coins()) + 2

mario_current_action__addr = mario_field("current action")
mario_previous_action__addr = mario_field("previous action")

mario_current_action__mem = dword(mario_field("current action"))
mario_previous_action__mem = dword(mario_field("previous action"))

mario_action__values = {
    "uninitialized":               0x00000000,
    "star dance ground (exit)":    0x00001302,
    "star dance water":            0x00001303,
    "star dance ground (no exit)": 0x00001307,
    "reading sign":                0x00001308,
    "warp door spawn":             0x00001322,
    "spawn spin landing":          0x00001325,
    "start teleporting":           0x00001336,
    "in cannon":                   0x00001371,
    "star grab fall":              0x00001904,
    "airborne spawn":              0x00001924,
    
    "death exit landing":          0x00020467,
    "burning ground":              0x00020449,
    "burning jump":                0x010208B4,
    "burning fall":                0x010208B5,
    
    "ground pound landing":        0x0080023C,
    "lava boost":                  0x010208B7,
    "twirl":                       0x108008A4,
    "slide kick":                  0x018008AA,
    "air kick":                    0x018008AC,
    "triple jump":                 0x01000882,
    "air sitting":                 0x0300088E,
    
    "dive slide":                  0x00880456,
    "butt slide":                  0x00840452,
    "hold butt slide":             0x00840454,
}

function mario_action_is(name) => mario_current_action__mem == mario_action__values[name]
function mario_action_was(name) => prev(mario_current_action__mem) == mario_action__values[name]
function mario_prev_action_is(name) => mario_previous_action__mem == mario_action__values[name]

function mario_action_changed_to(name) {
    return prev(mario_current_action__mem) != mario_action__values[name]
        && mario_current_action__mem == mario_action__values[name]
}

star_grab_actions = ["star dance ground (exit)", "star dance water", "star dance ground (no exit)", "star grab fall"]

function collected_star_action_check(star_index=-1) {
    cond = none_of(star_grab_actions, a => mario_action_was(a)) && __ornext(any_of(star_grab_actions, a => mario_action_is(a)))
    if (star_index > 0)
        return cond && (last_star__mem == star_index)
    return cond
}
// reference - 74EE set: similar logic (includes deltas) but doesn't check star grab fall
// SR3 set - doesn't have deltas and doesn't check star dance ground (no exit)

burning_actions = ["burning ground", "burning jump", "burning fall"]

function airborne() => bit3(mario_current_action__addr + 1) != 0
function on_pole() => bit4(mario_current_action__addr + 2) != 0

// ------------------- //
//   s u r f a c e s   //
// ------------------- //
// (includes triangles)
// https://github.com/n64decomp/sm64/blob/1372ae1bb7cbedc03df366393188f4f05dcfc422/include/types.h#L218

surface__struct = {
    "type":             0x00, // word
    "related object":   0x2C // dword (pointer to object, if applicable)
}
surface__sizeof = 0x30

function surface_field(base, field) => struct_field(surface__struct, base, field)

function surface_type(addr) => word(surface_field(addr, "type"))
function surface_object(addr) => tbyte(surface_field(addr, "related object"))

// ----------------- //
//     w a r p s     //
// ----------------- //

//https://github.com/n64decomp/sm64/blob/1372ae1bb7cbedc03df366393188f4f05dcfc422/src/game/level_update.h#L73
warp_dest__struct = {
    "node":         0x00,
    "area id":      0x01, 
    "level id":     0x02,
    "type":         0x03,
}
warp_dest__addr = offsets["WARP DEST"]

function warp_dest_field(field, addr) {
    if (addr == -1)
        this_addr = warp_dest__addr
    else
        this_addr = addr
    struct_field(warp_dest__struct, this_addr, field)
    }

function warp_dest_node(addr=-1) => byte(warp_dest_field("node", addr))
function warp_dest_area(addr=-1) => byte(warp_dest_field("area id", addr))
function warp_dest_level(addr=-1) => byte(warp_dest_field("level id", addr))
function warp_dest_type(addr=-1) => byte(warp_dest_field("type", addr))
function warp_dest_level_area(addr=-1) => word(warp_dest_field("area id", addr)) // ! misaligned

// https://github.com/n64decomp/sm64/blob/1372ae1bb7cbedc03df366393188f4f05dcfc422/src/game/area.h#L104
warp_transition__struct = {
    "pause rendering":  0x00,
    "time":             0x01,
    "type":             0x02,
    "is active":        0x03,
}

warp_transition__addr = offsets["WARP TRANSITION"]

function warp_transition_field(field) => struct_field(warp_transition__struct, warp_transition__addr, field)

function warp_transition_pause_rendering() => byte(warp_transition_field("pause rendering"))
function warp_transition_time() => byte(warp_transition_field("time"))
function warp_transition_type() => byte(warp_transition_field("type"))
function warp_transition_active() => byte(warp_transition_field("is active"))

// constants https://github.com/n64decomp/sm64/blob/1372ae1bb7cbedc03df366393188f4f05dcfc422/src/game/area.h#L93
WARP_TRANSITION_FADE_INTO_CIRCLE = 0x0B

// ----------------- //
//   o b j e c t s   //
// ----------------- //

// https://github.com/n64decomp/sm64/blob/1372ae1bb7cbedc03df366393188f4f05dcfc422/include/types.h#L142

// and https://github.com/n64decomp/sm64/blob/1372ae1bb7cbedc03df366393188f4f05dcfc422/include/object_fields.h#L53
object__struct = {
    "graph node flags":      0x00,
    "animation":             0x3A,  // word (NEW)
    "active":                0x76,  // word https://github.com/n64decomp/sm64/blob/1372ae1bb7cbedc03df366393188f4f05dcfc422/include/object_constants.h#L7
    "num collided objects":  0x74,  // word
    "collided object 1":     0x78,  // dword (pointer to object)
    "collided object 2":     0x7c,  // dword (pointer to object)
    "collided object 3":     0x80,  // dword (pointer to object)
    "collided object 4":     0x84,  // dword (pointer to object)
    "boo death status":      0x88,  // dword (https://github.com/n64decomp/sm64/blob/1372ae1bb7cbedc03df366393188f4f05dcfc422/include/object_fields.h#L236)
    "behavior param 2":     0x144,  // dword?
    "action":               0x14c,  // dword
    "timer":                0x154,  // dword
    
    "home x":               0x164,  // float
    "home y":               0x168,  // float
    "home z":               0x16c,  // float
    
    "hp":                   0x184,  // dword
    "star mission":         0x18b,  // byte (actually 0x188, but weirdness...)
    "num coins":            0x198,  // dword
    "behaviour script":     0x20c,  // dword
}
object__sizeof = 0x260

function object_field(base, field) => struct_field(object__struct, base, field)

function object_graph_invisible(addr) => bit4(object_field(addr, "graph node flags"))
function object_graph_animation_active(addr) => bit5(object_field(addr, "graph node flags"))

// https://github.com/n64decomp/sm64/blob/1372ae1bb7cbedc03df366393188f4f05dcfc422/include/object_constants.h#L7
function object_active(addr) => bit(0, object_field(addr, "active"))


function object_just_deactivated(addr) => prev(object_active(addr)) != 0 && object_active(addr) == 0

function object_behav_script(addr) => dword(object_field(addr, "behaviour script"))
function object_is(addr, name) => object_behav_script(addr) == behaviour_script__values[name]
function object_was(addr, name) => prev(object_behav_script(addr)) == behaviour_script__values[name]

function object_num_collided_objects(addr) => word(object_field(addr, "num collided objects"))
function object_nth_collided_object(addr, n) => tbyte(object_field(addr, format("collided object {0}", n)))

function object_boo_death_status(addr) => dword(object_field(addr, "boo death status"))

function object_anim(addr) => word(object_field(addr, "animation"))
function object_action(addr) => dword(object_field(addr, "action"))

OBJ_ACTION_LAVA_DEATH = 100

function object_beh_param_2(addr) => dword(object_field(addr, "behavior param 2"))

function object_pos_home(addr) => 
    [float(object_field(addr, "home x")),
    float(object_field(addr, "home y")),
    float(object_field(addr, "home z"))]
    
function object_pos_home_at(addr, pos) {
    obj_home = object_pos_home(addr)
    
    return all_of(range(0, 2), i => obj_home[i] == pos[i])
}

function object_timer(addr) => dword(object_field(addr, "timer"))
function object_health(addr) => dword(object_field(addr, "hp"))
function object_num_coins(addr) => dword(object_field(addr, "num coins"))

// object specific
function object_star_mission(addr) => byte(object_field(addr, "star mission"))

function mario_collision_check(obj_addr, obj_name, nth_collided) {
    return object_num_collided_objects(mario_object()) >= nth_collided
            && (
                (obj_addr != prev(obj_addr)) 
                || (object_behav_script(obj_addr) != prev(object_behav_script(obj_addr)))
                || (object_num_collided_objects(mario_object()) != prev(object_num_collided_objects(mario_object())))
               )
            && object_is(obj_addr, obj_name)
}

// Interactions

// Unsolved problem - how to handle stale interaction_object() when a box/coin star loads into the same slot?
function collecting_star_object(obj_name, mission) {
    obj = interaction_object()
    return obj != 0
           && object_is(obj, obj_name)
           && object_star_mission(obj) == mission
}

// --------------------------- //
//   o b j e c t   a r r a y   //
// --------------------------- //

object_array__addr = offsets["OBJECT ARRAY"]

function nth_array_object(index) => object_array__addr + (index * object__sizeof)

function array_object_index_is(obj_addr, index) => ((obj_addr - object_array__addr) / object__sizeof) == index

function array_object_is_active(index) => object_active(nth_array_object(index)) != 0
function array_object_was_active(index) => prev(object_active(nth_array_object(index))) != 0
function array_object_just_deactivated(index) => array_object_was_active(index) && !array_object_is_active(index)

function array_object_is(index, name) => object_is(nth_array_object(index), name)

function array_object_num_collided_objects(index)   => object_num_collided_objects(nth_array_object(index))
function array_object_nth_collided_object(index, n) => object_nth_collided_object(nth_array_object(index), n)

function array_object_action(index) => object_action(nth_array_object(index))

function array_object_bowser_hp(index) => object_bowser_hp(nth_array_object(index))

object_indexes = { // try to only use this as a fallback, as this can change between updates...
}

//
//  Additional Memory
//

timer_counting__addr = mario_field("timer running")

function int_seconds_to_frames(seconds) => seconds * 30

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

function pressed_switch__mem(color, delta=-1){
    switch_mem = always_false
    if color == "valid game"
        switch_mem = bit0(current_file__addr + 8)
    else if color == "red"
        switch_mem = bit1(current_file__addr + 8)
    else if color == "green"
        switch_mem = bit2(current_file__addr + 8)
    else if color == "blue"
        switch_mem = bit3(current_file__addr + 8)
    else if color == "key 1"
        switch_mem = sum_of([4, 6], a => bit(a, current_file__addr + 8))
    else if color == "key 2" // note: different bitflag is used to check if key 1/2 doors are open
        switch_mem = sum_of([5, 7], a => bit(a, current_file__addr + 8))
    else if color == "key 1 strict"
        switch_mem = bit4(current_file__addr + 8)
    else if color == "key 2 strict"
        switch_mem = bit5(current_file__addr + 8)
        
    if (delta > 0)
        return prev(switch_mem)
    else
        return switch_mem
}

function pressed_switch(color, delta){
    return pressed_switch__mem(color, delta) == 1
}

mission__addr = offsets["MISSION ACTIVE"]
mission__mem = byte(mission__addr)

// normal stars = 1-6; 100 coin star = 7
last_star__addr = offsets["COLLECTED STAR ID"]
last_star__mem = byte(last_star__addr)

sublevel_id__mem  = warp_dest_area()

level_id__addr = offsets["MAP ID"]
level_id__mem = byte(level_id__addr)

level_index__addr = offsets["LEVEL INDEX"]
level_index__mem = byte(level_index__addr)

music_id__addr = offsets["MUSIC ID"]
music_id__mem  = byte(music_id__addr)

dialog_id__addr = offsets["DIALOGUE ID"]
dialog_id__mem = word(dialog_id__addr)

dialog__values = {
    "Star Save Prompt":     0x0E,
    
    "Whomp Fight Start":    0x72,    
    "Whomp Fight Defeat":   0x73,
    
    "Eyerok Fight Start":   0x75,
    "Eyerok Fight Defeat":  0x76,
    
    "1 Star Message":       0x8D,
    "15 Star Message":      0x8E,
    "50 Star Message":      0x8F,
    "70 Star Message":      0x90,
    "90 Star Message":      0x91,
    "125 Star Message":     0x92,
    
    "Final Bowser Defeat (under 120 stars)": 0x79,
    "Final Bowser Defeat":  0xA3,
}

function dialog_id_is(name, delta=0) {
    dialog_value = dialog__values[name]
    if (delta == 0)
        return dialog_id__mem == dialog_value
    return prev(dialog_id__mem) == dialog_value
}

function dialog_just_ended(name) {
    return dialog_id_is(name, delta=1)
        && !dialog_id_is(name)
}

g_red_coins_collected__addr = offsets["RED COINS COLLECTED"]
g_red_coins_collected__mem = byte(g_red_coins_collected__addr)

g_current_demo_input__addr = offsets["CURRENT DEMO INPUT"]
g_current_demo_input__mem = dword(g_current_demo_input__addr)

function course_meta(value, sublevel_values, full_name, clean_name="0") {
    if (clean_name == "0")
        return {"value": value, "sublevel values": sublevel_values, "full name": full_name, "clean name": full_name}
    return {"value": value, "sublevel values": sublevel_values, "full name": full_name, "clean name": clean_name}
}

course_infos = {
    "Castle Grounds":      course_meta(0x10, [-1],   "the first overworld"), // Castle Grounds
    "Inside Castle":       course_meta(0x06, [-1], "the second overworld"), // Inside Castle
    "Castle Courtyard":    course_meta(0x1a, [-1], "the third overworld"), // Castle Courtyard
    
    "Course 1":         course_meta(0x09, [-1],   "Corn", "the first course"),
    "Course 2":         course_meta(0x18, [-1],   "Slippery Buttcrack Castle", "the second course"),
    "Course 3":         course_meta(0x0c, [-1],   "Kaizo Canada", "the third course"),
    "Course 4":         course_meta(0x05, [-1],   "Brown Soda Pits", "the fourth course"),
    "Course 5":         course_meta(0x04, [-1],   "Magical Girl Anime is Badass!", "the fifth course"),
    "Course 6":         course_meta(0x07, [-1],   "Plaguing the Patio", "the sixth course"),
    "Course 7":         course_meta(0x16, [-1],   "Vile Language", "the seventh course"),
    "Course 8":         course_meta(0x08, [-1],   "Ancestral Lands", "the eighth course"),
    "Course 9":         course_meta(0x17, [-1],   "Ballzy Ambience", "the ninth course"),
    "Course 10":        course_meta(0x0a, [-1],   "Boo's Private Schools", "the tenth course"),
    "Course 11":        course_meta(0x0b, [-1],   "Pubic Phobic", "the eleventh course"),
    "Course 12":        course_meta(0x24, [-1],   "Ballz Ballz Mountain", "the twelfth course"),
    "Course 13":        course_meta(0x0d, [-1],   "Snow", "the thirteenth course"),
    "Course 14":        course_meta(0x0e, [-1],   "Apocalyptic Sewers", "the fourteenth course"),
    "Course 15":        course_meta(0x0f, [-1],   "Refined Pleasant Gardening Paradox", "the fifteenth course"),
    
    "Slide":            course_meta(0x1b, [-1],   "Tsucnent's Doors"),
    "Aquarium":         course_meta(0x14, [-1],   "Eclipse of a Stupider Ball"),
    "End Cake Picture": course_meta(0x19, [-1],   "Brownerlasting BALLZcore"),
    "Clouds":           course_meta(0x1f, [-1],   "Browner Plane of Existence"),
    
    "Bowser 1":         course_meta(0x11, [-1],   "Defective Butt Graveyard", "the first BALLZer course"),
    "Key 1":            course_meta(0x1e, [-1],   "Defective Butt Graveyard", "the first BALLZer fight"),
    "Bowser 2":         course_meta(0x13, [-1],   "It Just B2 Much Sometimes", "the second BALLZer course"),
    "Key 2":            course_meta(0x21, [-1],   "It Just B2 Much Sometimes", "the second BALLZer fight"),
    "Bowser 3":         course_meta(0x15, [-1],   "Belluring Diadem", "the third BALLZer course"),
    "Final Fight":      course_meta(0x22, [-1],   "Belluring Diadem", "the third BALLZer fight"),
    
    "Metal Cap":        course_meta(0x1c, [-1],   "Blazing Corn Bath", "the metal cap course"),
    "Wing Cap":         course_meta(0x1d, [-1],   "Testicle Ascension", "the wing cap course"),
    "Vanish Cap":       course_meta(0x12, [-1],   "Path of the Grandmas", "the vanish cap course"),

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
    if (course_infos[name]["sublevel values"][0] == -1) {return always_true()}
    
    // used to be an any_of statement but RATools won't let me compare an array to an integer constant :|
    return any_of(course_infos[name]["sublevel values"], a => sublevel_id__mem == a)
}


function in_area(name, area=-1) {
    area_check = always_true()
    if (area != -1)
        area_check = sublevel_id__mem == area
    
    return level_id__mem == course_infos[name]["value"] && area_check
}

function in_same_level_from_last_frame() => level_id__mem == prev(level_id__mem) && sublevel_id__mem == prev(sublevel_id__mem)

//function entered_level_from_star_select(name) => in_level(name) && just_changed_from(music_id__mem, 0x0D) // careful, specific to this hack (AMA)

function level_changed(except_when_entering="") {
    cond = just_changed_any(level_id__mem)
    if (except_when_entering != "")
        cond = cond && !in_level(except_when_entering)
    return cond
}
function screen_changed() => just_changed_any(level_id__mem) || just_changed_any(sublevel_id__mem)

// the hit is for challenges that, if failed, require re-entering the level
function remained_in_level(name, hit=1) {
    if (hit != 0)
        return in_level(name) && once(prev(level_id__mem) != course_infos[name]["value"]) && never(level_changed(except_when_entering=name)) && unless(object_is(nth_array_object(0), "mission star manager"))
    return in_level(name) && never(level_changed()) && unless(object_is(nth_array_object(0), "mission star manager"))
}

function in_intro_or_file_select() => any_of([0x02, 0x21], a => music_id__mem == a)

function common_in_file_check() => !in_intro_or_file_select() && level_id__mem != 1 && g_current_demo_input__mem == 0

//
//  Cheevs
//

// Milestones

function star_milestone_trigger(num_stars) {
    return measured(nof_stars() == num_stars, when=!in_title_or_file_select())
        && prev(nof_stars()) == num_stars - 1
        && level_id__mem == prev(level_id__mem) // to prevent switching files after the ending picture puts you back to the title screen...
}

function milestone_meta(title, description, stars, points, id=0, badge="0") => {"title": title, "description": description, "stars": stars, "points": points, "id": id, "badge": badge}

milestones = [
    //milestone_meta("Finished the Summer Collab",
        //"Collect all 28 stars.",
        //stars=28, points=10)
]

for milestone in milestones {
    achievement(
        title = milestone["title"],
        description = milestone["description"],
        points = milestone["points"],
        trigger = star_milestone_trigger(milestone["stars"]),
        id = milestone["id"],
        badge = milestone["badge"]
    )
}

// put milestones before course stars, so they stand out more.

// switches
function rgb_trigger() {
    // stupid RATools cannot "add Requirement to Requirement" (old addsource chain didn't work, revert to hit targets...)
    return level_id__mem == prev(level_id__mem) // to prevent switching files after the ending picture puts you back to the title screen...
    && file_num__mem == prev(file_num__mem)
    
    && tally(2, 
    [once(pressed_switch("red", delta=1)),
    once(pressed_switch("green", delta=1)),
    once(pressed_switch("blue", delta=1))
    ])
    
    && measured(tally(3, 
    [once(pressed_switch("red", delta=0)),
    once(pressed_switch("green", delta=0)),
    once(pressed_switch("blue", delta=0))
    ]), when = common_in_file_check())
    
    && never(tally(3, 
    [once(pressed_switch("red", delta=1)),
    once(pressed_switch("green", delta=1)),
    once(pressed_switch("blue", delta=1))
    ]))
}

achievement(
    title = "Ballsy Switcheroo",
    description = "Press the red, green, and blue !-switches.",
    points = 5,
    trigger = rgb_trigger(),
    id=278385,
    badge="308038"
)

achievement(
    title = "Defective Key",
    description = "Collect the key in the first BALLZer fight.",
    points = 5,
    trigger = in_level("Key 1") && collected_star_action_check(),
    id=278386,
    badge="308039"
)

achievement(
    title = "Take Care",
    description = "Collect the key in the second BALLZer fight.",
    points = 10,
    trigger = in_level("Key 2") && collected_star_action_check(),
    id=278387,
    badge="308040"
)

achievement(
    title = "Brown-ness Restored",
    description = "Collect the star in the final BALLZer fight.",
    points = 25,
    trigger = in_level("Final Fight") && collected_star_action_check(),
    id=278388,
    badge="308041"
)

// c o u r s e  s t a r s

// let's obfuscate the star names, just to be safe...

ordinals = ["first", "second", "third", "fourth", "fifth", "sixth", "seventh"]

blank = ""

course_star_titles = [
    {"Course 1": 
    ["Fortress Climbing", "Triangle-Shaped Hole", "Easy Tunnel", "Signs with Secret Numbers", "Battle with the King", "First Red Coins"]},
    {"Course 2":
    ["Chip Off the Old Block, Again", "The Usual Castle Climbing", "Race Through Toxic Gas", "Lavabouncing Upwards", "More Lavabouncing in a Hidden Alcove", "Slippery Red Coins"]},
    {"Course 3":
    ["Cliffside Platforms", "Cold Red Coins", "Hot Wallkicks", "Chuckya Couples", "Hexagonal Cutout in the Floor", "Rewarding Kaizo Trap"]},
    {"Course 4":
    ["Over the Triangle Obstacles", "Diving with the Vanish Cap", "A Tight Lava Passage", "Secrets of the Soda", "Not Quite Cherry Coins", "Flying for Panels"]},
    {"Course 5":
    ["Easy Eyeball Fight", "Hidden Grandma", "Filler Metal Cap Lavabouncing", "Low Wallkicks for Red Coins", "Tower of Tight Arches", "Intense Purple Switch Jumps"]},
    {"Course 6":
    ["Behind a Fake Wall", "Shell Riding on Top", "Spiral Shell Riding", "Trespassing on the Roof", "Dill Secrets", "Bon Dill Voyage!"]},
    {"Course 7":
    ["A Couple Precise Jumps", "Yet Another Wallkick Alcove", "A Switch and Some Wallkicks", "A Hiding !-Box Underneath", "Secrets Between Poorly Textured Geometry", "Darn, More Red Coins"]},
    {"Course 8":
    ["Metal to the Painting", "Panel Platforming", "Top of the BUPs", "Boxes to a Hidden Warp", "Ancestral Red Coins", "Box Jumps to a Cave"]},
    {"Course 9":
    ["The Floating Pipe Tower", "Under a Thin Ledge", "Ambience Wiggler Fight", "Constricted Corridor", "Top of the Ambience", "Ambient Red Coins"]},
    {"Course 10":
    ["Top of the School", "A Star Down Under", "Playing Basketball", "Race with Grandma", "Boos Without Hall Passes", "Educational Red Coins", "Spinny Secrets"]},
    {"Course 11":
    ["Up the 'Toilet' Bowl", "The Bounce on Quicksand Star", "Grandma Around", "Good Old Cube Jumps", "Reds Between the Walls", "Hazardous Panels", "Twirling Grandma"]},
    {"Course 12":
    ["Not That Tall a Mountain", "Big Bully With Enemy Spam, Go!", "Angle-Changing Wallkicks", "Two Precise Jumps", "Legend of Ketchupyoshi", "Good Old Alcove"]},
    {"Course 13":
    ["Wallkicks Down Under", "Yellow Snow Roof", "Follow the Arrow to Another Alcove", "Lost Buddies in the Snow", "Cold Quiz", "Long Line of Grandmas"]},
    {"Course 14":
    ["Tight Hexagon Jumps", "Firsty on Switches", "Slippery Corridor", "Slippery Secrets", "Big Boo Box Brawl", "Death Plane Mountain"]},
    {"Course 15":
    ["Gardening Panels", "Grandma Dive", "Smiley Face of the Garden", "Sideways Garden", "Top of the Garden", "22 Nerfed Red Coins"]},
    
    {"Metal Cap":
    ["Single Lavabunce Arch", "Roasted Fly Guys", "Blazing Corn Secrets"]},
    {"Vanish Cap":
    ["Beyond the Switch", "Chill Bully's Box Arena", "Grandma's Cold Secrets"]},
    {"Wing Cap":
    ["The Star Next to the Switch", "Top of the Tower", "Ascending Secrets"]},
    
    {"Bowser 1":
    ["Moderate Precision Required", "Tree Hopping", "Successful !-Box Break", "Defective Red Coins"]},
    {"Bowser 2":
    ["Star on Some Pillars", "The !-Box Above Quicksand", "Relax on Flipswitches", "CartoonBuffoon's Star", "Pentagonal Wallkicks"]},
    {"Bowser 3":
    ["Four Pipes for Secrets", "Outside a Window", "Lovely Little Octagons", "Alcove Past the Quicksand Hill", "Atop the Quicksand Hill", "Slopes, Walls, and a Cap Combo", "Red Coins of the Bell's Cult"]},
    
    {"Slide":
    ["Up the Crosses", "Door-Shaped Cutouts", "Sloped Door Blocks", "Secret Numbers, One Down Under"]},
    {"Aquarium":
    ["Thwomp's Tunnel", "A Well-Guarded Box", "Climb With Another Wallkick Section at the End", "Top of the Sun-Shaped Structure", "Hidden !-Box of the Eclipse", "Generic Secrets Star"]},
    {"End Cake Picture":
    ["Bouncing on the BALLZ", "Double Crossover Arch, Double Crossover Arch", "Tower Climbing", "Pillar Ascent", "Small Shell Ride"]},
    {"Clouds":
    ["Intense Precise Wallkicks", "Tight Jumps Between Snufits and Holes", "All About Angles", "Legendary Goomba Hop", "Crossovers and a Tight Box Switch"]},
    
    {"Castle Grounds": ["Toad in an Alcove", blank, blank, "Reds Around the Brown Pllars"]},
    {"Inside Castle": [blank, "Not-So Loud Monkey Boy", blank, blank, "More Red Coins"]},
    {"Castle Courtyard": [blank, blank, "Toad on a High Pillar", blank, blank, "Twirling for Red Coins"]},
]

function is_numbered_course(title) {
    for i in range(1, 15) {
        if (title == format("Course {0}", i))
            return true
    }
    return false
}

function stars_meta(points, ids=[0,0,0,0,0,0,0,0], badge_ids=["0","0","0","0","0","0","0","0"]) => { "points": points, "ids": ids, "badge_ids": badge_ids }

course_stars_meta = {
    "Course 1":  stars_meta([3, 1, 1, 2, 2, 2], ids=sequence(278389, 6), badge_ids=sequence(308042, 6, badge=1)),
    "Course 2":  stars_meta([2, 3, 4, 2, 3, 5], ids=sequence(278395, 6), badge_ids=sequence(308048, 6, badge=1)),
    "Course 3":  stars_meta([2, 4, 5, 5, 1, 0], ids=sequence(278401, 6), badge_ids=sequence(308054, 6, badge=1)),
    "Course 4":  stars_meta([3, 2, 2, 3, 4, 3], ids=sequence(278407, 6), badge_ids=sequence(308060, 6, badge=1)),
    "Course 5":  stars_meta([3, 2, 2, 3, 10, 10], ids=sequence(278413, 6), badge_ids=sequence(308066, 6, badge=1)),
    "Course 6":  stars_meta([1, 4, 3, 3, 5, 10], ids=sequence(278419, 6), badge_ids=sequence(308072, 6, badge=1)),
    "Course 7":  stars_meta([4, 3, 5, 1, 5, 5], ids=sequence(278425, 6), badge_ids=sequence(308078, 6, badge=1)),
    "Course 8":  stars_meta([4, 5, 3, 3, 10, 5], ids=sequence(278431, 6), badge_ids=sequence(308084, 6, badge=1)),
    "Course 9":  stars_meta([10, 2, 10, 5, 10, 10], ids=sequence(278437, 6), badge_ids=sequence(308090, 6, badge=1)),
    "Course 10": stars_meta([5, 5, 5, 4, 10, 10, 3], ids=sequence(278443, 7), badge_ids=sequence(308096, 7, badge=1)),
    "Course 11": stars_meta([4, 2, 5, 10, 10, 5, 2], ids=sequence(278450, 7), badge_ids=sequence(308103, 7, badge=1)),
    "Course 12": stars_meta([5, 5, 10, 25, 25, 5], ids=sequence(278457, 6), badge_ids=sequence(308110, 6, badge=1)),
    "Course 13": stars_meta([10, 2, 3, 10, 5, 3], ids=sequence(278463, 6), badge_ids=sequence(308116, 6, badge=1)),
    "Course 14": stars_meta([10, 5, 10, 10, 10, 10], ids=sequence(278469, 6), badge_ids=sequence(308122, 6, badge=1)),
    "Course 15": stars_meta([5, 10, 10, 10, 10, 25], ids=sequence(278475, 6), badge_ids=sequence(308128, 6, badge=1)),
    
    "Metal Cap": stars_meta([5, 3, 10], ids=sequence(278481, 3), badge_ids=sequence(308134, 6, badge=1)),
    "Vanish Cap":stars_meta([5, 4, 10], ids=sequence(278484, 3), badge_ids=sequence(308137, 6, badge=1)),
    "Wing Cap":  stars_meta([5, 4, 5], ids=sequence(278487, 3), badge_ids=sequence(308140, 6, badge=1)),
    
    "Bowser 1":  stars_meta([10, 4, 4, 5], ids=sequence(278490, 4), badge_ids=sequence(308143, 4, badge=1)),
    "Bowser 2":  stars_meta([2, 2, 5, 2, 4], ids=sequence(278494, 5), badge_ids=sequence(308147, 5, badge=1)),
    "Bowser 3":  stars_meta([25, 5, 5, 10, 10, 5, 25], ids=sequence(278499, 7), badge_ids=sequence(308152, 7, badge=1)),
    
    "Slide":     stars_meta([2, 5, 2, 2], ids=sequence(278506, 4), badge_ids=sequence(308159, 4, badge=1)), // TD
    "Aquarium":  stars_meta([4, 2, 5, 5, 5, 5], ids=sequence(278510, 6), badge_ids=sequence(308163, 6, badge=1)), // ES
    "End Cake Picture": stars_meta([10, 25, 25, 10, 10], ids=sequence(278516, 5), badge_ids=sequence(308169, 5, badge=1)), // BB
    "Clouds":    stars_meta([25, 10, 25, 25, 25], ids=sequence(278521, 5), badge_ids=sequence(308174, 5, badge=1)), // BP
    
    "Castle Grounds": stars_meta([1, -1, -1, 3], ids=[278526, -1, -1, 278527], badge_ids=["308179", "", "", "308180"]),
    "Inside Castle":  stars_meta([-1, 2, -1, -1, 3], ids=[-1, 278528, -1, -1, 278529], badge_ids=["", "308181", "", "", "308182"]),
    "Castle Courtyard": stars_meta([-1, -1, 1, -1, -1, 3],  ids=[-1, -1, 278530, -1, -1, 278531], badge_ids=["", "", "308183", "", "", "308184"]),
}

function course_star_achievements() {
    // put in func to avoid namespace pollution
    for inf in course_star_titles {
        for course in inf {
            title_arr = inf[course]
            
            for i in range(0, length(title_arr) - 1) {
            title = title_arr[i]
            
            if (title != blank) {
                
                desc = ""
                if (is_numbered_course(course))
                    desc = format("Collect the {0} star in {1}.", ordinals[i], course_infos[course]["clean name"])
                else
                    desc = format("Collect this star in {0}.", course_infos[course]["clean name"])
                
                if (course == "Course 13" && i == 4)
                    desc = format("{0} Answers are 100% factual!", desc)
                
                achievement(
                    title = title,
                    description = desc,
                    points = course_stars_meta[course]["points"][i],
                    trigger = in_level(course) && collected_star_action_check(star_index = i+1),
                    id=course_stars_meta[course]["ids"][i],
                    badge=course_stars_meta[course]["badge_ids"][i]
                    )
                }
            }
        }
    }
}

course_star_achievements()

// 1-ups

// Let tallies be a list of dicts of form
// {"type": (type of 1up), "count": (number of this type to count)}
// 
function tally_all_1ups(tallies=[], total_count=0)
{
    mushie_tally = []
    
    for t in tallies {
        obj_name = format("{0} 1-up", t["type"])

        for i in range(1,4) {
            obj_addr = object_nth_collided_object(mario_object(), i)
            
            coll_check = mario_collision_check(obj_addr, obj_name, i)
            
            // these 1-ups are tangible (recognized as colliding with mario) while they are sparkling, so need additional action check
            if (obj_name == "chasing 1-up" || obj_name == "activator 1-up") {
            // https://github.com/n64decomp/sm64/blob/master/src/game/behaviors/mushroom_1up.inc.c
                // even if you are on top of the 1-up while handstanding, this will still hit
                coll_check1 = coll_check && object_action(obj_addr) == 1
                //coll_check2 = coll_check && object_action(obj_addr) == 3&& object_timer(obj_addr) >= 37
                array_push(mushie_tally, repeated(t["count"], coll_check1))
                //array_push(mushie_tally, repeated(t["count"], coll_check2))
                
                if (obj_name == "activator 1-up") {
                    coll_check2 = coll_check && object_action(obj_addr) == 2
                    array_push(mushie_tally, repeated(t["count"], coll_check2))
                }
            }
            else {
                array_push(mushie_tally,
                    repeated(t["count"], coll_check))   
            }
        }
    }
    return tally(total_count, mushie_tally)
}

function mushies_meta(course="", title="", description="", points=0, tallies=[], level_check=always_true(), id=0, badge="0") => {"course": course, "title": title, "description": description, "points": points, "tallies": tallies, "level check":level_check, "id": id, "badge": badge}

mushies_data = [
    mushies_meta("Course 3", "Canada Life",
        "Collect the 1-up mushroom in {0}.", 1,
        [{"type": "impartial", "count": 1}],
        level_check=remained_in_level("Course 3", hit=0),
        id=278532, badge="308185"),
    mushies_meta("Bowser 1", "Defective Life",
        "Collect the 1-up mushroom in {0}.", 1,
        [{"type": "stationary", "count": 1}],
        level_check=remained_in_level("Bowser 1", hit=0),
        id=278533, badge="308186"),
    mushies_meta("Vanish Cap", "Grandma's Mushrooms",
        "Collect both 1-up mushroom in {0}.", 2,
        [{"type": "stationary", "count": 2}],
        level_check=remained_in_level("Vanish Cap", hit=0),
        id=278534, badge="308187"),
    mushies_meta("Metal Cap", "Corny Life",
        "Collect the 1-up mushroom in {0}.", 1,
        [{"type": "impartial", "count": 1}],
        level_check=remained_in_level("Metal Cap", hit=0),
        id=278535, badge="308188"),
        
    mushies_meta("Inside Castle", "Patio Life",
        "Collect the 1-up mushroom in {0}.", 1,
        [{"type": "stationary", "count": 1}],
        level_check=remained_in_level("Inside Castle", hit=0),
        id=278536, badge="308189"),
    mushies_meta("Course 5", "Magical Lives",
        "Collect all 4 1-up mushrooms in {0}.", 4,
        [{"type": "stationary", "count": 3},
         {"type": "impartial",  "count": 1}],
        level_check=remained_in_level("Course 5", hit=0),
        id=278537, badge="308190"),
    mushies_meta("Course 7", "Drat, a Lost Life",
        "Collect the 1-up mushroom in {0} on a quicksand slope.", 1,
        [{"type": "stationary", "count": 1}],
        level_check=remained_in_level("Course 7", hit=0) && pos_x() > 3000.0,
        id=278538, badge="308191"),
    mushies_meta("Course 7", "Blast, Another Lost Life",
        "Collect the 1-up mushroom in {0} between two walls.", 1,
        [{"type": "stationary", "count": 1}],
        level_check=remained_in_level("Course 7", hit=0) && pos_x() < 3000.0,
        id=278539, badge="308192"),
    mushies_meta("Course 8", "Ancestral Lives",
        "Collect both 1-up mushrooms in {0}.", 2,
        [{"type": "stationary", "count": 2}],
        level_check=remained_in_level("Course 8", hit=0),
        id=278540, badge="308193"),
    mushies_meta("Aquarium", "Ballsy Life",
        "Collect the 1-up mushroom in {0}.", 1,
        [{"type": "stationary", "count": 1}],
        level_check=remained_in_level("Aquarium", hit=0),
        id=278541, badge="308194"),
        
    mushies_meta("Course 11", "Toilet Bowl Life",
        "Collect the 1-up mushroom in {0}.", 1,
        [{"type": "impartial", "count": 1}],
        level_check=remained_in_level("Course 11", hit=0),
        id=278542, badge="308195"),   
    mushies_meta("Course 12", "Cliffside Life",
        "Collect the 1-up mushroom in {0}.", 1,
        [{"type": "stationary", "count": 1}],
        level_check=remained_in_level("Course 12", hit=0),
        id=278543, badge="308196"),
    mushies_meta("Course 15", "Gardening Mushrooms",
        "Collect all 20 1-up mushrooms in {0}.", 10,
        [{"type": "stationary", "count": 18},
         {"type": "impartial",  "count": 2}],
        level_check=remained_in_level("Course 15", hit=0),
        id=278544, badge="308197"),
    mushies_meta("Final Fight", "BALLZer's Lost Mushroom",
        "Collect the 1-up mushroom in the final BALLZer fight.", 1,
        [{"type": "impartial", "count": 2}],
        level_check=remained_in_level("Final Fight", hit=0),
        id=278545, badge="308198")
]

function mushie_cheevs() {
    for dict in mushies_data {
        course = dict["course"]
        
        mushie_count = sum_of(dict["tallies"], t => t["count"])
        
        mushie_tally = tally_all_1ups(tallies = dict["tallies"], total_count = mushie_count)
        trigger_tally = tally_all_1ups(tallies = dict["tallies"], total_count = 1)
        
        collect_cond = always_true()
        
        if (mushie_count == 1) {
            collect_cond = mushie_tally
        }
        else {
            collect_cond = measured(mushie_tally, when=in_level(course)) || (trigger_tally && trigger_when(impossible_condition()))
        }

        
        achievement(
            title = dict["title"],
            description = format(dict["description"], course_infos[course]["clean name"]),
            points = dict["points"],
            trigger = dict["level check"]
                && collect_cond
            )
    }
}

mushie_cheevs()

// 1ups -
// ow1 - 0 
// c1 - 0
// c2 - 0
// c3 - 1 (box impartial)
// c4 - 0
// b1 - 1 (stationary)
// td - 0

// vc - 2 (stationary)
// wc - 0
// mc - 1 (box impartial)

// ow2 - 1 (stationary)
// c5 - 4 (stationary)
// c6 - (1) unobtainable (box impartial)
// c7 - 2 (stationary, must be separate)
// c8 - 2 (stationary)
// c9 - 0
// c10 - 0
// ES - 1 (stationary) + (secret warp)
// b2 - 0

// ow3 - 0
// c11 - 1 (impartial box)
// c12 - 1 (stationary)
// c13 - 0
// c14 - 0
// c15 - 20 (18 stationary, 2 box impartial)
// B3 - 0
// final fight - 1 (box impartial)
// BP - 0
// BB - 0


// challenge ideas

// c1 100s
// c2 whomp no dmg
// c3s5 no A
// c4s6 no wc
// c5 mr i while wearing vc
// c6 scuts
// c8s1 no damage
// c9 wiggler no dmg (HP 2 -> 1)
// c10s5 no dmg (hall  pass)
// vc chill bully vc
// ow3 all 17 reds

achievement(
    title = "Brown Gold",
    description = "Collect 100 coins in the first course.",
    points = 3,
    trigger = prev(coin_display()) == 99 && measured(coin_display() == 100, when=in_level("Course 1")),
    id=278546,
    badge="308199"
)

c2_whomp = nth_array_object(76)

// fortunately, c2 is all 1 area
achievement(
    title = "Notice Me Senpai",
    description = "Defeat the Whomp King in the second course without taking damage during the fight.",
    points = 5,
    trigger = remained_in_level("Course 2", hit=0)
        && once(dialog_just_ended("Whomp Fight Start"))
        && object_is(c2_whomp, "king whomp")
        && object_active(c2_whomp) != 0
        && never(hp() < prev(hp())) // no water damage to take...
        && never(object_is(c2_whomp, "king whomp") && just_changed_to(object_action(c2_whomp), 0)) // fight deactivated
        && trigger_when(just_changed(object_health(c2_whomp), 1, 0)),
    id=278547,
    badge="308200"
)

c2_pipe = nth_array_object(93)

achievement(
    title = "Can't Take This With You",
    description = "Enter the warp pipe to the toxic gas room in the second course while still wearing your metal cap.",
    points = 10,
    trigger = in_level("Course 2")
        && object_is(c2_pipe, "warp pipe")
        && prev(wearing_metal_cap()) != 0
        && (used_object() == c2_pipe && interaction_object() == c2_pipe),
    id=278548,
    badge="308201"
)

achievement(
    title = "Jumpless Cornhole",
    description = "Collect the fifth star in the third course without pressing the A button.",
    points = 1,
    trigger = remained_in_level("Course 3", hit=1)
        && never(just_increased(controller_a_button()))
        && trigger_when(collected_star_action_check(0x05)),
    id=278549,
    badge="308202"
)

achievement(
    title = "No Abuse Needed",
    description = "Collect the sixth star of the fourth course without getting a wing cap (mission 6 only).",
    points = 10,
    trigger = remained_in_level("Course 4", hit=1)
        && mission__mem == 6
        && never(just_increased(wearing_wing_cap()))
        && trigger_when(collected_star_action_check(0x06)),
    id=278550,
    badge="308203"
)

c5_eyeball = nth_array_object(27)

achievement(
    title = "Can't See Me",
    description = "Defeat the big Mr. I and collect its star in the fifth course while still wearing your vanish cap, before your cap runs out.",
    points = 10,
    trigger = remained_in_level("Course 5", hit=0)
        && prev(wearing_vanish_cap()) != 0
        && never(just_changed(cap_time(), 1, 0))
        && once(wearing_vanish_cap() != 0
            && object_is(c5_eyeball, "mr. i")
            && object_beh_param_2(c5_eyeball) == 1 // big
            && just_changed(object_action(c5_eyeball), 2, 3))
        && trigger_when(collecting_star_object("spawned star", 0)),
    id=278551,
    badge="308204"
)

c6_scuts = array_map([33, 34, 35, 36], a => nth_array_object(a))
function tally_dead_scuts(count) {
    dead_scuts = array_map(c6_scuts, i =>
        once(object_is(i, "scuttlebug")
        && object_just_deactivated(i)
        && object_num_collided_objects(i) != 0)) // simple enough for a mario / bob-omb kill
    return tally(count, dead_scuts)
}

achievement(
    title = "Scuttlebug Extinction",
    description = "Defeat all 4 scuttlebugs in the sixth course in one go.",
    points = 2,
    trigger = remained_in_level("Course 6", hit=0)
        && ((measured(tally_dead_scuts(4)))
        || (tally_dead_scuts(1) && trigger_when(impossible_condition()))),
    id=278552,
    badge="308205"
)

c7_switch = nth_array_object(41)

achievement(
    title = "Heck, a Blind Jump",
    description = "While the purple switch is pressed, collect the star 'Darn' in the seventh course.",
    points = 5,
    trigger = in_level("Course 7")
        && object_is(c7_switch, "purple switch")
        && object_action(c7_switch) == 2
        && trigger_when(collected_star_action_check(0x02)),
    id=278553,
    badge="308206"
)

achievement(
    title = "Ancestral Cap Cycle",
    description = "Collect the star 'A Painting Honoring Our Ancestors' in the eighth course without taking damage.",
    points = 5,
    trigger = remained_in_level("Course 8", hit=1)
        && never(just_increased(hp_decrement()))
        && never(any_of(burning_actions, a => mario_action_changed_to(a)))
        && trigger_when(collected_star_action_check(0x01)),
    id=278554,
    badge="308207"
)

c9_wiggler = nth_array_object(99)

achievement(
    title = "Ow, My Balls",
    description = "Defeat Wiggler in the ninth course without taking damage.",
    points = 10,
    trigger = remained_in_level("Course 9", hit=1)
        && never(just_increased(hp_decrement()))
        && never(any_of(burning_actions, a => mario_action_changed_to(a)))
        && object_is(c9_wiggler, "wiggler")
        && trigger_when(object_health(c9_wiggler) == 2
            && just_changed_to(object_action(c9_wiggler), 3)),
    id=278555,
    badge="308208" // wiggler act jumped on
        // wiggler doesn't die, just shrinks at 1 hp
)

achievement(
    title = "Short Stack Shooter",
    description = "Collect the star 'Shootin' Stupid Hoopz at Recess' in the tenth course without triple jumping.",
    points = 10,
    trigger = remained_in_level("Course 10", hit=1)
        && never(mario_action_changed_to("triple jump"))
        && trigger_when(collected_star_action_check(0x03)),
    id=278556,
    badge="308209"
)

achievement(
    title = "Convenient Coins",
    description = "Collect the star 'Cubic Phobic' in the eleventh course without going below full displayed HP (indicator appears on that star's path).",
    points = 4,
    trigger = remained_in_level("Course 11", hit=1)
        && never(hp() < 0x800)
        && pos_x() < -2000.0
        && pos_z() > -5000.0
        && pos_z() < 7000.0
        && trigger_when(collected_star_action_check(4)),
    id=278557,
    badge="308210"
)

achievement(
    title = "Cavern Conqueror",
    description = "Collect the star 'Cavern' in the twelfth course without taking damage (indicator appears near mountain).",
    points = 10,
    trigger = remained_in_level("Course 12", hit=1)
        && in_3d_box(-3000.0, 2000.0, 500.0, -6500.0, -7000.0, -2000.0)
        && never(just_increased(hp_decrement()))
        && never(any_of(burning_actions, a => mario_action_changed_to(a)))
        && trigger_when(collected_star_action_check(2)),
    id=278558,
    badge="308211"
)

c13_switch_near_alcove = nth_array_object(54)

achievement(
    title = "Alcove Dash",
    description = "While the purple switch near the Mr. Blizzards is pressed, collect the star 'Below' in the thirteenth course.",
    points = 5,
    trigger = in_level("Course 13")
        && object_is(c13_switch_near_alcove, "purple switch")
        && object_action(c13_switch_near_alcove) == 2
        && trigger_when(collected_star_action_check(0x03)),
    id=278559,
    badge="308212"
)

c14_entered_fight = in_3d_box(5500.0, 6500.0, 2000.0, 1000.0, -7000.0, -7500.0)
c14_challenge_fail = in_3d_box(4700.0, 7200.0, 3000.0, 1000.0, -8620.0, -10000.0)
c14_big_boo = nth_array_object(33)

achievement(
    title = "Battle of Draw Distance",
    description = "Defeat the Big Boo in the fourteenth course while staying on only the back half of the platform (no going past the fire spewers).",
    points = 5,
    trigger = remained_in_level("Course 14", hit=1)
        && once(c14_entered_fight)
        && never(c14_challenge_fail)
        && trigger_when(object_is(c14_big_boo, "big boo") && just_changed(object_health(c14_big_boo), 1, 0)),
    id=278560,
    badge="308213"
)

achievement(
    title = "Sudden Death Star Grab",
    description = "Collect the sixth star in the fourteenth course after going over a death plane, before getting kicked out of the level.",
    points = 5,
    trigger = in_level("Course 14")
        && warp_transition_active() != 0
        && warp_transition_type() == WARP_TRANSITION_FADE_INTO_CIRCLE
        && trigger_when(collecting_star_object("regular star", 5)),
    id=278561,
    badge="308214"
)

c15_snowmen = array_map([42, 43, 44], a => nth_array_object(a))

function object_snowman_died(addr) => object_is(addr, "mr. blizzard") && object_active(addr) != 0 && just_changed(object_num_coins(addr), 3, 0)

function tally_snowmen_dead(count) {
    dead_snowmen = array_map(c15_snowmen, i => once(object_snowman_died(i)))
    return tally(count, dead_snowmen)
}

achievement(
    title = "Melt the Snow Away",
    description = "Defeat all 3 Mr. Blizzards in the fifteenth course at least once, in one go.",
    points = 5,
    trigger = remained_in_level("Course 15", hit=0)
        && (measured(tally_snowmen_dead(length(c15_snowmen)))
            || (tally_snowmen_dead(1) && trigger_when(impossible_condition()))),
    id=278562,
    badge="308215"
)

achievement(
    title = "Panel Jumps Just B2 Much Sometimes",
    description = "Collect the panel star in the second BALLZer course without taking damage.",
    points = 10,
    trigger = remained_in_level("Bowser 2", hit=1)
        && never(hp_decrement() > 0)
        && never(any_of(burning_actions, a => mario_action_is(a)))
        && trigger_when(collected_star_action_check(0x03)),
    id=278563,
    badge="308216"
)

achievement(
    title = "Great Brown Battle",
    description = "Collect the star in the final BALLZer fight without taking damage.",
    points = 50,
    trigger = remained_in_level("Final Fight", hit=1)
        && never(hp_decrement() > 0)
        && never(any_of(burning_actions, a => mario_action_is(a)))
        && trigger_when(collected_star_action_check(0x0B)),
    id=278564,
    badge="308217" // troll star
)

achievement(
    title = "Flying Around the Brown Pillars",
    description = "Collect the red coin star in the first overworld without dying after getting the first red.",
    points = 5,
    trigger = remained_in_level("Castle Grounds", hit=0)
        && once(just_changed(g_red_coins_collected__mem, 0, 1))
        && never(mario_action_changed_to("death exit landing"))
        && trigger_when(collected_star_action_check(0x04)),
    id=278565,
    badge="308218"
)

got_one_red = nof_coins() == prev(nof_coins()) + 2

achievement(
    title = "Twirling Forever",
    description = "Collect all 17 red coins in the third overworld.",
    points = 10,
    trigger = remained_in_level("Castle Courtyard", hit=0)
        && (measured(repeated(17, got_one_red), when=in_level("Castle Courtyard")) || (once(got_one_red) && trigger_when(impossible_condition()))),
    id=278566,
    badge="308219"
)

// RP

meta_descriptions = {
    0x00: "Starting up the game",
    0x02: "Playing with Mario head",
    0x21: "In File Select",
}

general_level_dict = {
    0x0901: "not chilling with corn",
    0x0902: "looking for corn flakes",
    0x1801: "on a slippery adventure through Whomp's castle",
    0x0C01: "in a hostile environment in Canada",
    0x0C02: "interrupting Chuckya couples' making out",
    0x0501: "excavating the Brown Soda Pits",
    0x0401: "on a rainbow anime adventure",
    0x0701: "infiltrating the Bob-omb Buddy's patio",
    0x1601: "is trying not to swear",
    0x0801: "honoring his ancestors",
    0x1701: "feeling uneasy in the ambience",
    0x0A01: "getting an education in Boo's Private Schools",
    0x0B01: "fixing a toilet, feeling Pubic Phobic",
    0x2401: "climbing a mountain",
    0x0D01: "not eating the yellow snow",
    0x0D02: "horrified at Grandma",
    0x0E01: "doing apocalyptic plumbing work in the sewers",
    0x0F01: "gardening in peace",
    
    0x1001: "in the first overworld stabilized by brown pillars",
    0x0601: "on his journey to Brown greatness in the second overworld",
    0x1A01: "on his way to stop BALLZer in the third overworld",
    
    0x1401: "feeling stupider in an eclipse", // aquarium - ES
    0x1B01: "opening many of Tsucnent's Doors", // slide - TD
    0x1F01: "feeling browner at the edge of existence", // clouds - BP
    0x1901: "brownerlasting in the BALLZcore", // end cake - BB
    
    0x1C01: "bathing in blazing corn",
    0x1201: "ascending the Path of the Grandmas",
    0x1D01: "flying high in the sky",
    
    0x1101: "paying his respects in the Defective Graveyard",
    0x1E01: "on a fierce first battle with BALLZer",
    0x1301: "easing his mental health",
    0x2101: "talking about his feelings with BALLZer in the second fight",
    0x1501: "giving all his support to the great Bellring",
    0x1502: "enjoying his reward after defeating BALLZer",
    0x2201: "fighting BALLZer for the last time"
}

level__lookup = rich_presence_lookup("Levels", warp_dest_level_area(), general_level_dict, "in an unbeknownst location")

stars__value = rich_presence_value("Number", nof_stars())
lives__value = rich_presence_value("Number", (byte(nof_lives__addr) ) - (bit7(nof_lives__addr) * 256))
level_test__value = rich_presence_value("Number", warp_dest_level_area())

file__lookup  = rich_presence_lookup("File", file_num__mem, {
    0x01: "A", 0x02: "B", 0x03: "C", 0x04: "D"
}, "??")

rich_presence_conditional_display(in_title_or_file_select(), 
    "{0}", rich_presence_lookup("Fileless", music_id__mem, meta_descriptions))
rich_presence_conditional_display(g_current_demo_input__mem != 0, "Mario is in a demo!")
rich_presence_conditional_display(
    warp_dest_level_area() > 0,
      "Mario-{2} is {0} with {1}⭐ and {6}🚶 [🔴{3}] [🟢{4}] [🔵{5}]", level__lookup, stars__value, file__lookup, 
        rich_presence_lookup("Switch", pressed_switch__mem("red"), {1:"▣"}, "▢"),
        rich_presence_lookup("Switch", pressed_switch__mem("green"), {1:"▣"}, "▢"),
        rich_presence_lookup("Switch", pressed_switch__mem("blue"), {1:"▣"}, "▢"), lives__value
)
rich_presence_display("Trying to restore the great Brown-ness.", level_test__value)