// ~Hack~ Master Quest 2 Two: Best Buy Edition
// #ID = 24007
// Made in RATools 1.11.0 -> v1.12.0

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

function dict_lookup(dict, key) => dict[key]

offsets = {
    "SAVE DATA":    (0x207700 - 0x70),
    
    "MUSIC ID":     0x22261e,

    "CURRENT DEMO INPUT":   0x32d5f0,
    "COLLECTED STAR ID":    0x32dd87, // 1-indexed
    "FILE ID":              0x32ddf6,
    "MAP ID":               0x32ddfa,
    
    "CUTSCENE FOCUS":       0x32df24,
    
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
    "warp":             0x800EB900,
    "warp pipe":        0x800EB920,
    "purple box switch":0x800EC62C, // unchanged
    "grand star":       0x800EC894,
    
    "koopa shell":      0x800ED0BC,
    "big boo":          0x800ED8E8,
    
    "mission star manager": 0x800EE1C8,
    
    "stationary 1-up":  0x800EF1FC,
    "grabbable cork box":0x800EF398,
    "koopa flag checkpoint":0x800EF750,
    
    "eyerok manager":   0x800F0434,
}

// ---------------
//   m e m o r y
// ---------------

mario__struct = { // https://github.com/n64decomp/sm64/blob/master/include/types.h
    "input":              0x00,  // bitfield
    "hat bitflags":       0x04,  // byte
    "current action":     0x0c,  // dword
    "previous action":    0x10,  // dword
    "floor footstep type":0x14,  // word
    "action phase":       0x18,  // word
    "yaw":                0x2c,  // word
    "pitch":              0x2e,  // word
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
    "nof lives":          0xae,  // byte
    "hp increment":       0xb0,  // byte
    "hp decrement":       0xb1,  // byte
    "cap timer":          0xb4,  // word
    
    "timer running":      0xed,  // bool
    "coin display":       0xf0,  // word
}

function mario_field(field) => struct_field(mario__struct, mario__addr, field)

mario__addr = offsets["MARIO STRUCT"]
stood_on_object__addr = offsets["STOOD ON OBJECT"]

function in_toxic_gas() => bit0(mario_field("input") + 1) != 0

function hat_in_hand()        => bit5(mario_field("hat bitflags"))
function hat_on_head()        => bit4(mario_field("hat bitflags"))
function wearing_wing_cap()   => bit3(mario_field("hat bitflags"))
function wearing_metal_cap()  => bit2(mario_field("hat bitflags"))
function wearing_vanish_cap() => bit1(mario_field("hat bitflags"))

function pos_x() => float(mario_field("x"))
function pos_y() => float(mario_field("y"))
function pos_z() => float(mario_field("z"))

function angle_yaw() => word(mario_field("yaw"))
function angle_pitch() => word(mario_field("pitch"))

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
function nof_lives() => byte(mario_field("nof lives"))

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
    "disappeared":                 0x00001300,
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
    "wall kick":                   0x03000886,
    "air sitting":                 0x0300088E,
    
    "crouch sliding":              0x04808459,
    
    "dive slide":                  0x00880456,
    "butt slide":                  0x00840452,
    "hold butt slide":             0x00840454,
    
    "holding pole":                0x08100340,
    "climbing pole":               0x00100343,
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

function airborne() => bit3(mario_current_action__addr + 1)
function on_pole() => bit4(mario_current_action__addr + 2)

function wallkicked() => just_changed_any(angle_yaw()) && 
    !mario_action_was("climbing pole") && !mario_action_was("holding pole") && mario_action_is("wall kick")
// reference - SR6.25 set (doesn't check pole action)

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
    "koopa flag race started":0xf4, // dword
    "eyerok hands remaining":0xf8,  // dword
    "koopa flag ktq finished":0xf8, // dword
    "koopa flag race finished":0x104, // dword
    "behavior param 2":     0x144,  // dword?
    "action":               0x14c,  // dword
    "timer":                0x154,  // dword
    
    "home x":               0x164,  // float
    "home y":               0x168,  // float
    "home z":               0x16c,  // float
    
    "hp":                   0x184,  // dword
    "warp destination":     0x18a,  // word (actually 0x188, again, endianness...)
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
function object_changed_to(addr, name) => !object_was(addr, name) && object_is(addr, name)

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

function object_koopa_flag_race_started(addr) => dword(object_field(addr, "koopa flag race started"))
function object_koopa_flag_race_finished(addr) => dword(object_field(addr, "koopa flag race finished"))
function object_koopa_flag_ktq_finished(addr) => dword(object_field(addr, "koopa flag ktq finished"))

function object_eyerok_hands_remaining(addr) => dword(object_field(addr, "eyerok hands remaining"))
function object_warp_dest(addr) => word(object_field(addr, "warp destination"))

function mario_collision_check(obj_addr, obj_name, nth_collided) {
    return object_num_collided_objects(mario_object()) >= nth_collided
            && (
                (obj_addr != prev(obj_addr)) 
                || (object_behav_script(obj_addr) != prev(object_behav_script(obj_addr)))
                || (object_num_collided_objects(mario_object()) != prev(object_num_collided_objects(mario_object())))
               )
            && object_is(obj_addr, obj_name)
}

function collided_with_object(obj_name, count=1, extra_logic=always_true()) {
    obj_tally = []
    for i in range(1,4) {
        obj_addr = object_nth_collided_object(mario_object(), i)
        
        coll_check = mario_collision_check(obj_addr, obj_name, i)
        
        coll_check = coll_check && extra_logic
        array_push(obj_tally,
            repeated(count, coll_check))   
    }
    return tally(count, obj_tally)
}

// Interactions

// Unsolved problem - how to handle stale interaction_object() when a box/coin star loads into the same slot?
function collecting_star_object(obj_name, mission) {
    obj = interaction_object()
    return obj != 0
           && object_is(obj, obj_name)
           && object_star_mission(obj) == mission
}

function just_used_warp(id) {
    obj = interaction_object()
    return mario_action_changed_to("disappeared")
        && object_is(obj, "warp")
        && object_warp_dest(obj) == id
}

function just_used_pipe(id) {
    obj = interaction_object()
    return mario_action_changed_to("disappeared")
        && object_is(obj, "warp pipe")
        && object_warp_dest(obj) == id
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
    "C11 Hint": 0x23,
    "C4 Hidden":0x00,
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

g_cutscene_focus__addr = offsets["CUTSCENE FOCUS"]
g_cutscene_focus__mem = tbyte(g_cutscene_focus__addr) // pointer to object

function course_meta(value, sublevel_values, full_name, clean_name="0") {
    if (clean_name == "0")
        return {"value": value, "sublevel values": sublevel_values, "full name": full_name, "clean name": full_name}
    return {"value": value, "sublevel values": sublevel_values, "full name": full_name, "clean name": clean_name}
}

course_infos = {
    "Castle Grounds":      course_meta(0x10, [-1],   "Overworld 1"), // Castle Grounds
    "Inside Castle": course_meta(0x06, [-1], "Overworld 2"), // 1-2-3: Lobby/Upstairs/Basement
    "Castle Courtyard":      course_meta(0x1a, [-1], "Overworld 3"), // Castle Courtyard
    
    "Course 1":         course_meta(0x09, [-1],   "Land Without Hadoo"),
    "Course 2":         course_meta(0x18, [-1],   "Pancake Land"),
    "Course 3":         course_meta(0x0c, [-1],   "Sad Metal Mire"),
    "Course 4":         course_meta(0x05, [-1],   "The Rehabilitated Forest of Crappiness"),
    "Course 5":         course_meta(0x04, [-1],   "Fake Cavin's Realm"),
    "Course 6":         course_meta(0x07, [-1],   "Less Fog Than More Fog Than the Fog"),
    "Course 7":         course_meta(0x16, [-1],   "Tohnu Sphere"),
    "Course 8":         course_meta(0x08, [-1],   "Flash Flood Towers"),
    "Course 9":         course_meta(0x17, [-1],   "Busted Bees Regret"),
    "Course 10":        course_meta(0x0a, [-1],   "Teardrop Cavern"),
    "Course 11":        course_meta(0x0b, [-1],   "Syndicate City"),
    "Course 12":        course_meta(0x24, [-1],   "Best Buy: A Metroidvania Adventure"),
    "Course 13":        course_meta(0x0d, [-1],   "Marble Realm"),
    "Course 14":        course_meta(0x0e, [-1],   "Neo Disco Space Base"),
    "Course 15":        course_meta(0x0f, [-1],   "Shredded Worlds in Puce"),
    
    "Aquarium":         course_meta(0x14, [-1],   "Abandoned Mountain Meltdown"),
    "Cloud Stage":      course_meta(0x1f, [-1],   "Cavin's Dream"),
    "End Cake Picture": course_meta(0x19, [-1],   "Ancient Attic"),
    "Slide":            course_meta(0x1b, [-1],   "Lifeless Swamp"),
    
    "Bowser 1":         course_meta(0x11, [-1],   "Lost Desert"),
    "Key 1":            course_meta(0x1e, [-1],   "Lost Desert"),
    "Bowser 2":         course_meta(0x13, [-1],   "Polar Castle"),
    "Key 2":            course_meta(0x21, [-1],   "Polar Castle"),
    "Bowser 3":         course_meta(0x15, [-1],   "Fake Cavin's Lair"),
    "Final Fight":      course_meta(0x22, [-1],   "Fake Cavin's Lair"),
    
    "Metal Cap":        course_meta(0x1c, [-1],   "Kydrelous Sphere"),
    "Wing Cap":         course_meta(0x1d, [-1],   "Gheltho Sphere"),
    "Vanish Cap":       course_meta(0x12, [-1],   "Sierydium Sphere"),
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
        return in_level(name) && once(prev(level_id__mem) != course_infos[name]["value"]) && never(level_changed(except_when_entering=name)) && !object_is(nth_array_object(0), "mission star manager")
    return in_level(name) && never(level_changed()) && !object_is(nth_array_object(0), "mission star manager")
    
    // remove pause on mission manager check
    // originally, pause was used to allow button presses during star select, but it blocked reset logic if you directly warped into a numbered course from a different course with a hit tracker
}

function in_intro_or_file_select() => any_of([0x02, 0x21], a => music_id__mem == a)

function common_in_file_check() => !in_intro_or_file_select() && level_id__mem != 1 && g_current_demo_input__mem == 0

//
//  Cheevs
//

// Milestones

function star_milestone_trigger(num_stars) {
    // remove measured here, it overrides other more important progress indicators
    return nof_stars() == num_stars
        && !in_title_or_file_select()
        && prev(nof_stars()) == num_stars - 1
        && level_id__mem == prev(level_id__mem) // to prevent switching files after the ending picture puts you back to the title screen...
}

function milestone_meta(title, description, stars, points, id=0, badge="0") => {"title": title, "description": description, "stars": stars, "points": points, "id": id, "badge": badge}

milestones = [
    milestone_meta("Door Knocking",
        "Collect 2 stars.",
        stars=2, points=1, id=308768, badge="341964"),
    milestone_meta("Sadness Awaits",
        "Collect 7 stars.",
        stars=7, points=2, id=308769, badge="341965"),
    milestone_meta("Bathroom Time",
        "Collect 12 stars.",
        stars=12, points=2, id=308770, badge="341966"),
    milestone_meta("To the Toy Room",
        "Collect 18 stars.",
        stars=18, points=2, id=308771, badge="341967"),
    milestone_meta("It Open Now",
        "Collect 26 stars.",
        stars=26, points=3, id=308772, badge="341968"),
    milestone_meta("Basically Full Access",
        "Collect 33 stars.",
        stars=33, points=5, id=308773, badge="341969"),
    milestone_meta("Ready for Bowser's Only Round",
        "Collect 83 stars. Now find the last star door.",
        stars=83, points=25, id=308774, badge="341970"),
    milestone_meta("End of Amazing Adventure",
        "Collect all 120 stars.",
        stars=120, points=50, id=308775, badge="341971"),
    
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

// caps / bowsers

achievement(
    title = "Where Could They Be?",
    description = "Press the red, green, and blue !-switches.",
    points = 10,
    trigger = rgb_trigger(),
    id=308776,
    badge="341702"
)

achievement(
    title = "Jump Down Somewhere...",
    description = "Obtain the first key.",
    points = 10,
    trigger = in_level("Key 1") && collected_star_action_check(),
    id=308777,
    badge="341703"
)

achievement(
    title = "Sliding Too Far",
    description = "Obtain the second key.",
    points = 10,
    trigger = in_level("Key 2") && collected_star_action_check(),
    id=308778,
    badge="341704"
)

achievement(
    title = "Escaped the Fake Dimension",
    description = "Defeat (real) Bowser and collect the grand star. Hope you got the lives.",
    points = 25,
    trigger = in_level("Final Fight") && interaction_object() != 0 && object_is(interaction_object(), "grand star"),
    id=308779,
    badge="341705"
)

// c o u r s e  s t a r s


function course_stars_meta(star_bits, points, title, description_add="", id=0, badge="0") => {"star bits": star_bits, "points": points, "title": title, "description add": description_add, "id": id, "badge": badge}

function sum_star_bits(file_offset, bits) {
    off = current_file__addr + file_offset
    if (length(bits) == 7 && none_of(bits, b => b == 7))
        return { // just hard-code optimization for 7 bits
            "mem": (bitcount(off) - bit(7, off)),
            "sum": 7
        }
    return {
        "mem": sum_of(bits, b => bit(b, off)),
        "sum": length(bits)
    }
}

// https://github.com/n64decomp/sm64/blob/master/levels/course_defines.h indexes (add 0x0c) (remember endian weirdness)
//and https://github.com/aglab2/SM64StarDisplay/blob/9d6c11e6af49a4f90a5d8020e8a94fdd611603d0/StarManager/LevelInfo.cs#L25
course_offsets = {
    "Course 1":  course_stars_meta(sum_star_bits(0x0f, range(0, 6)), 10, "Still a Generic Grassland", id=308785, badge="341711"), 
    "Course 2":  course_stars_meta(sum_star_bits(0x0e, range(0, 6)), 10, "Interdimensional Adventure", id=308792, badge="341718"),
    "Course 3":  course_stars_meta(sum_star_bits(0x0d, range(0, 6)), 25, "Shoutouts to Stars of the Beast", id=308793, badge="341719"),
    "Course 4":  course_stars_meta(sum_star_bits(0x0c, range(0, 6)), 10, "Some Zelda Hack You Don't Know", id=308794, badge="341720"),
    "Course 5":  course_stars_meta(sum_star_bits(0x13, range(5, 6)), 10, "Fake Cavin's Annoying Stars", id=308795, badge="341721"),
    "Course 6":  course_stars_meta(sum_star_bits(0x12, range(0, 6)), 25, "You Like Drowned Factory?", id=308796, badge="341722"),
    "Course 7":  course_stars_meta(sum_star_bits(0x11, range(0, 6)), 25, "I Love Rotated Geometry", id=308797, badge="341723"),
    "Course 8":  course_stars_meta(sum_star_bits(0x10, range(0, 5)), 25, "Tears Over Required Speedruns", id=308798, badge="341724"),
    "Course 9":  course_stars_meta(sum_star_bits(0x17, range(0, 1)), 3, "A Hollow Hive", id=308799, badge="341725"),
    "Course 10":  course_stars_meta(sum_star_bits(0x16, range(0, 6)), 10, "Your Generic Water Level", id=308786, badge="341712"),
    "Course 11":  course_stars_meta(sum_star_bits(0x15, range(0, 6)), 25, "Tale of Mafias", id=308787, badge="341713"),
    "Course 12":  course_stars_meta(sum_star_bits(0x14, range(0, 6)), 10, "Adventures in Best Buy", id=308788, badge="341714"),
    "Course 13":  course_stars_meta(sum_star_bits(0x1b, range(0, 6)), 10, "Phew, No Softlocks", id=308789, badge="341715"),
    "Course 14":  course_stars_meta(sum_star_bits(0x1a, range(0, 6)), 25, "Time For More Dancing", id=308790, badge="341716"),
    "Course 15":  course_stars_meta(sum_star_bits(0x19, range(0, 6)), 25, "Puce Is a Pretty Color", id=308791, badge="341717"),
    
    "Bowser 1":   course_stars_meta(sum_star_bits(0x18, range(0, 0)), 2, "Coarse. Rough. Irritating.", id=308781, badge="341707"),
    "Bowser 2":   course_stars_meta(sum_star_bits(0x1f, range(0, 1)), 5, "Wind, Please Go Away", id=308782, badge="341708"),
    "Bowser 3":   course_stars_meta(sum_star_bits(0x1e, range(0, 2)), 10, "Have Fun in the Maze", id=308783, badge="341709"),
    
    "Wing Cap":   course_stars_meta(sum_star_bits(0x23, range(0, 1)), 10, "How Many Variations of This Music?", id=308815, badge="341757"),
    "Metal Cap":  course_stars_meta(sum_star_bits(0x1c, range(0, 1)), 10, "More Deaths, More Backtracking", id=308800, badge="341727"),
    "Vanish Cap": course_stars_meta(sum_star_bits(0x22, range(0, 1)), 5, "Get Lost Mario in Cavin Sphere", id=308801, badge="341729"),
    
    "Aquarium": course_stars_meta(sum_star_bits(0x20, range(0, 1)), 10, "Violet Stars Vibes", id=308780, badge="341706"),
    "Cloud Stage": course_stars_meta(sum_star_bits(0x21, range(0, 6)), 25, "Cavin's Dreamy Promenade", id=308784, badge="341710"),
    
    "End Cake Picture": course_stars_meta(sum_star_bits(0x27, range(0, 0)), 1, "Okay, Where's the Warp?", id=308813, badge="341755"),
    "Slide": course_stars_meta(sum_star_bits(0x1d, range(0, 0)), 2, "They're Still Moving!", id=308814, badge="341756"),
    // end cake picture is attic (1 star)
    // slide is lifeless swamp (1 star)
}
function course_star_achievements(ignore_ids=0) {
    for c in course_offsets {
        info = course_offsets[c]
        bits = info["star bits"]["mem"]
        star_count = info["star bits"]["sum"]
        star_qty = dict_lookup({
            1: "the star",
            2: "both stars",
            3: "all 3 stars",
            4: "all 4 stars",
            5: "all 5 stars",
            6: "all 6 stars",
            7: "all 7 stars"
        }, star_count)
        
        title = info["title"]
        description = format("Collect {0} in {1}{2}.",
            star_qty,
            course_infos[c]["full name"],
            info["description add"])
            
        id = info["id"]
        badge = info["badge"]
        if (ignore_ids != 0) {
            id = 0
            badge = "0"
        }
        
        star_check = (prev(bits) == star_count - 1
            && measured(bits == star_count, when = common_in_file_check()))
        if (star_count == 1)
            star_check = (prev(bits) == 0 && bits == 1 && common_in_file_check())
            
        achievement(
            title=title,
            description=description,
            points=info["points"],
            trigger= in_level(c)
                && star_check,
            id = id,
            badge = badge
        )
    }
}

course_star_achievements(ignore_ids=0)

function add_star_bits(star_bits) {
    return sum_of(star_bits, s => s["mem"])
}

function star_collection_achievement(stars, total, title, description, points, id=0, badge="0") {
    achievement(
        title = title,
        description = description,
        points = points,
        trigger = (level_id__mem == prev(level_id__mem)
        && file_num__mem == prev(file_num__mem)
        && prev(add_star_bits(stars)) == total - 1
        && measured(add_star_bits(stars) == total, when = common_in_file_check())),
        id = id,
        badge = badge
    )
}

star_collection_achievement(
    stars=[sum_star_bits(0x0b, range(0, 2))], total = 3,
    title = "Secrets of the House",
    description = "Collect all 3 overworld stars.",
    points = 3,
    id=308802,
    badge="341731"
)

function sum_cannon_bits(offsets) {// cannons always bit7
    mems = []
    for o in offsets {
        off = current_file__addr + o
        array_push(mems, bit(7, off))
    }
    return {
        "mem": sum_of(mems, m => m),
        "sum": length(offsets)
    }
}

cannon_bits = sum_cannon_bits([0x0f, 0x15, 0x1b, 0x20])
star_collection_achievement(
    stars=[cannon_bits], total=4,
    title = "Permanent Progress, Only If You Save",
    description = "Open all 4 cannons.",
    points = 4,
    id=308816,
    badge="341758"
)

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
    mushies_meta("Course 4", "Check All Dem Corners",
        "Collect the 1-up mushroom in {0}.", 1,
        [{"type": "stationary", "count": 1}],
        level_check=remained_in_level("Course 4", hit=0), id=308817, badge="341759"),
    mushies_meta("Course 11", "A Steal in This Economy",
        "Collect both 1-up mushrooms in {0} (mission 6 only).", 2,
        [{"type": "stationary", "count": 2}],
        level_check=remained_in_level("Course 11", hit=0) && mission__mem == 6, id=308803, badge="341734"),
    mushies_meta("Course 15", "At Least There Are Coins Up Here",
        "Collect the 1-up mushroom in {0}.", 1,
        [{"type": "stationary", "count": 1}],
        level_check=remained_in_level("Course 15", hit=0), id=308818, badge="341760"),
    mushies_meta("Wing Cap", "You Still Don't Wanna Die Here",
        "Collect the 1-up mushroom in {0}.", 1,
        [{"type": "stationary", "count": 1}],
        level_check=remained_in_level("Wing Cap", hit=0), id=308804, badge="341736"),
    mushies_meta("Vanish Cap", "Haha, How Are You Getting Back Up?",
        "Collect the 1-up mushroom in {0}.", 1,
        [{"type": "stationary", "count": 1}],
        level_check=remained_in_level("Vanish Cap", hit=0), id=308819, badge="341761"),
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
                && collect_cond,
            id=dict["id"],
            badge=dict["badge"]
            )
    }
}

mushie_cheevs()

achievement(
    title = "Yay, No Backtacking Needed",
    description = "Collect the star 'Come Back With the Cruise Bubble' in Course 1 without using a metal cap.",
    points = 2,
    trigger = remained_in_level("Course 1", hit=1)
        && never(just_increased(wearing_metal_cap()))
        && trigger_when(collected_star_action_check(0x06)),
    id=308805,
    badge="341738"
)

function c2_warp_achievement() {
    
    c2_warps = [
        once(in_level("Castle Grounds") && just_used_warp(0x050C)),
        once(in_level("Aquarium")       && just_used_pipe(0x15)),
        once(in_level("Course 12")      && just_used_pipe(0x16)),
    ]
    
    achievement(
        title = "Pancake Adventure",
        description = "Use all 3 warps to Course 2 in 1 session.",
        points = 3,
        trigger = measured(tally(3, c2_warps)),
        id=308820,
        badge="341762"
    )
}

c2_warp_achievement()

achievement(
    title = "Poisonous Barracks",
    description = "Collect the star 'Toxic Bounderies' in Course 3 with at least 3 HP remaining.",
    points = 10,
    trigger = in_level("Course 3")
        && in_toxic_gas()
        && hp() > 0x300
        && trigger_when(collected_star_action_check(0x06)),
    id=308806,
    badge="341740"
)

function boo_achievement() {
    big_boo = nth_array_object(4)

    boo_tally = []
    for i in range(1, 4) {
        array_push(boo_tally, repeated(3,
            object_is(big_boo, "big boo")
            && just_decreased(object_health(big_boo))
            && mario_action_is("crouch sliding")
            && prev(object_num_collided_objects(big_boo)) >= i
            && prev(object_num_collided_objects(big_boo)) <= 4
            && prev(object_nth_collided_object(big_boo, i)) == mario_object()
        ))
    }

    achievement(
    title = "Eat My Hat",
    description = "Defeat Marog's Mirage in Course 4 using only crouch-slides.",
    points = 4,
    trigger = never(level_changed()) && !object_is(nth_array_object(0), "mission star manager")
        && object_is(big_boo, "big boo")
        && never(object_is(big_boo, "big boo") && object_just_deactivated(big_boo))
        && measured(
            tally(3, boo_tally), when=in_level("Course 4")),
        id=308821,
        badge="341763"
    )
}

boo_achievement()

achievement(
    title = "I Have to Solve Puzzles???",
    description = "Read the hidden sign in Course 4, inside dead trees.",
    points = 1,
    trigger = in_level("Course 4")
        && dialog_just_ended("C4 Hidden"),
    id=308807,
    badge="341742"
)

achievement(
    title = "Slam Dunk",
    description = "Collect the star 'A Magicians Warning' (vanish cap) in Course 6 while holding a small cork box.",
    points = 5,
    trigger = in_level("Course 6")
        && object_was(held_object(), "grabbable cork box")
        && trigger_when(collected_star_action_check(0x05)),
    id=308822,
    badge="341764"
)

achievement(
    title = "Blind Jump? No, Just Use Music",
    description = "Collect the star 'The End of the World' in Course 7 without taking damage.",
    points = 5,
    trigger = remained_in_level("Course 7")
        && never(hp_decrement() > 0)
        && never(any_of(burning_actions, a => mario_action_is(a)))
        && trigger_when(collected_star_action_check(0x06)),
    id=308808,
    badge="341744"
)

achievement(
    title = "Coins Are Cues, Better Leave Them",
    description = "Collect the star 'Top of the Tall Tower' in Course 8 without getting any coins.",
    points = 10,
    trigger = in_level("Course 8")
        && hud_stars_shown() != 0
        && nof_coins() == 0
        && trigger_when(collected_star_action_check(0x02)),
    id=308823,
    badge="341765"
)

achievement(
    title = "Slippery Jumping Simulator",
    description = "Collect the star 'Five Floating Fish' in Course 10 without getting a wing cap.",
    points = 10,
    trigger = remained_in_level("Course 10", hit=1)
        && never(just_increased(wearing_wing_cap()))
        && trigger_when(collected_star_action_check(0x04)),
    id=308809,
    badge="341746"
)

achievement(
    title = "Find the Hint",
    description = "Talk to the NPC in Course 11 who gives away where the Whomp Boss is.",
    points = 1,
    trigger = in_level("Course 11")
        && dialog_just_ended("C11 Hint"),
    id=308824,
    badge="341766"
)

function object_koopa_race_started_and_won(addr, trig=1) {
    cond = object_is(addr, "koopa flag checkpoint")
        && object_koopa_flag_race_started(addr) != 0
        && prev(object_koopa_flag_race_finished(addr)) == 0
        && object_koopa_flag_ktq_finished(addr) == 0
    if (trig > 0)
        return cond && trigger_when(
            just_increased(object_koopa_flag_race_finished(addr)))
    return cond && just_increased(object_koopa_flag_race_finished(addr))
}

leaderboard(
    title = "Stolen Star Race",
    description = format("Win the race with Koopa the Quick in {0}.", course_infos["Course 11"]["full name"]),
    start = in_area("Course 11", 1) && any_of(array_map([88, 89, 93], a => object_koopa_race_started_and_won(nth_array_object(a), trig=0)), b => b),
    cancel = always_false(),
    submit = always_true(),
    value = hud_timer()*2,
    
    format="FRAMES",
    lower_is_better = true,
    id=62731
)

function c12_challenge_achievement() {
    collected_stars = array_map(range(1, 7), a => once(collected_star_action_check(a)))

    achievement(
        title = "All Items Like a True Metroidvania",
        description = "Collect all 7 stars in Course 12 in one go.",
        points = 25,
        trigger = remained_in_level("Course 12", hit=0)
            && ((tally(1, collected_stars) && trigger_when(tally(7, collected_stars)))
                || (impossible_condition() && measured(tally(7, collected_stars), when=in_level("Course 12")))),
        id=308810,
        badge="341748"
    )

}

c12_challenge_achievement()


achievement(
    title = "Invisible Marbler",
    description = "Collect star 2 (highest star) in Course 13 while still wearing a vanish cap but not a metal cap.",
    points = 3,
    trigger = in_level("Course 13")
        && prev(wearing_vanish_cap()) != 0
        && prev(wearing_metal_cap()) == 0
        && trigger_when(collected_star_action_check(0x02)),
    id=308825,
    badge="341767"
)

got_one_red = nof_coins() == prev(nof_coins()) + 2

achievement(
    title = "Easy Shell Smuggle",
    description = "Collect 7 red coins in Course 14 while riding a Koopa Shell in one go.",
    points = 5,
    trigger = never(level_changed()) && !object_is(nth_array_object(0), "mission star manager")
        && never(object_just_deactivated(ridden_object()))
        && measured(repeated(7, object_is(ridden_object(), "koopa shell") && got_one_red), when=in_level("Course 14")),
    id=308826,
    badge="341768"
)

achievement(
    title = "Rodeo Without Another Ride",
    description = "Collect the star 'Dorrie's Cosmic Rodeo' in Course 14 without riding a Koopa Shell.",
    points = 10,
    trigger = remained_in_level("Course 14", hit=1)
        && never(object_changed_to(ridden_object(), "koopa shell"))
        && trigger_when(collected_star_action_check(4)),
    id=308811,
    badge="341751"
)

leaderboard(
    title = "Puce Speedrun",
    description = "Activate the timer in Course 15, then collect the star 'A Nebulous Realm' as fast as possible.",
    start = in_level("Course 15") && hud_timer_shown() != 0 && hud_timer_counting() != 0 && collected_star_action_check(1),
    cancel = always_false(),
    submit = always_true(),
    value = 2*hud_timer(),
    format = "FRAMES",
    lower_is_better = true,
    id=627732
)

achievement(
    title = "A Nebulous Speedrun",
    description = "Activate the timer in Course 15, then collect the star 'A Nebulous Realm' in under 1 minute.",
    points = 10,
    trigger = remained_in_level("Course 15", hit=0)
        && hud_timer_shown() != 0
        && hud_timer() > 0
        && hud_timer() < int_seconds_to_frames(60)
        && trigger_when(collected_star_action_check(1)),
    id=308812,
    badge="341752"
)

eyeroks = array_map([4, 5], a => nth_array_object(a))
eyeroks_ded = array_map(eyeroks, a => object_is(a, "eyerok manager") && just_changed(object_eyerok_hands_remaining(a), 1, 0))

achievement(
    title = "Double Star Spawn???",
    description = "Defeat both bosses in Lost Desert in one go.",
    points = 10,
    trigger =never(level_changed()) && !object_is(nth_array_object(0), "mission star manager")
        && measured(tally(2, eyeroks_ded), when=in_level("Key 1")),
    id=308827,
    badge="341769"
)

achievement(
    title = "Does it Make it Easier or Harder?",
    description = "Collect the secrets star in Polar Castle without getting a wing cap.",
    points = 10,
    trigger = remained_in_level("Bowser 2", hit=1)
        && never(just_increased(wearing_wing_cap()))
        && trigger_when(collected_star_action_check(0x00)),
    id=308828,
    badge="341770"
)

// RP

meta_descriptions = {
    0x00: "Starting up the game",
    0x02: "Playing with Mario head",
    0x21: "In File Select",
}

general_level_dict = {
    0x1000: "contemplating his existence in living room",
    0x1001: "contemplating his existence in living room",
    0x0601: "getting lost in house hallway",
    0x1a01: "in a black room down waste disposal",
    
    0x0901: "in a generic grassland",
    0x1801: "figuring out how to navigate Pancake Land",
    0x0C01: "probably coin collecting in Sad Metal Mire",
    0x0501: "trying to be Link",
    0x0401: "outside Fake Cavin's Lair",
    0x0701: "not able to see anything in fog",
    0x1601: "finding free stars in Tohnu Sphere",
    0x0801: "running for his life in Flash Flood Towers",
    0x1701: "in an empty beehive",
    0x0A01: "swimming through Teardrop Cavern",
    0x0B01: "making his way through Syndicate City",
    0x2401: "on a non-stop adventure in Best Buy",
    0x0D01: "trying not to die in Marble Realm",
    0x0E01: "dancing in Neo Disco Space Base",
    0x0F01: "revisiting familiar worlds in puce",
    
    0x1C01: "traversing a difficult Metal Cap Sphere",
    0x1D01: "cheesing a Wing Cap Sphere",
    0x1201: "in a sandy Vanish Cap Sphere",
    
    0x1B01: "looking for reds in Lifeless Swamp",
    0x1401: "exploring Abandoned Mountain Meltdown",
    0x1F01: "trying to make sense of Cavin's Dream",
    0x1901: "deciphering hints in the Ancient Attic",
    
    0x1101: "can't tell floor from sky in Lost Desert",
    0x1E01: "fighting Ancient Stone Guardians in Lost Desert",
    0x1301: "struggling through wind in Polar Castle",
    0x2101: "fighting the guardian of Polar Castle",
    0x1501: "probably getting lost in Fake Cavin's Lair",
    0x2201: "fighting Fake Cavin?"
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
rich_presence_display("On a multi-faceted adventure through Cavin's creations.", level_test__value)