// ~Hack~ Disaster Quest Tree
// #ID = 23901
// Made in RATools 1.11.0

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
    "purple box switch":0x800EC62C, // unchanged
    "grand star":       0x800EC894,
    
    "mission star manager": 0x800EE1C8,
    
    "wing cap":         0x800EEF38,
    
    "stationary 1-up":  0x800EF1FC,
    
    "regular star":     0x800EEFBC,
    "spawned star":     0x800EEFE4,
    "box star":         0x800EB978,
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
    "Castle Grounds":      course_meta(0x10, [-1],   "the overworld"), // Castle Grounds

    "Course 1":         course_meta(0x09, [-1], "Foliage Field"),
    "Course 2":         course_meta(0x18, [-1], "Barkbuilt Barracks"),
    "Course 3":         course_meta(0x0c, [-1], "Ghostly Grotto"),
    "Course 4":         course_meta(0x05, [-1], "Driftwood Lake"),
    "Course 5":         course_meta(0x04, [-1], "Skyhigh Garden"),
    "Course 6":         course_meta(0x07, [-1], "Canopy Chaos"),
    "Course 7":         course_meta(0x16, [-1], "Ashember Alpine"), 
    
    "Bowser 1":         course_meta(0x11, [-1],   "Bowser's Arborial Promenade"),
    "Key 1":            course_meta(0x1e, [-1],   "Bowser's Arborial Promenade"),
    "Bowser 2":         course_meta(0x13, [-1],   "Bowser's Box Factory"),
    "Key 2":            course_meta(0x21, [-1],   "Bowser's Box Factory"),
    "Bowser 3":         course_meta(0x15, [-1],   "Bowser in the Core"),
    "Final Fight":      course_meta(0x22, [-1],   "Bowser in the Core"),
    
    "Metal Cap":        course_meta(0x1c, [-1],   "Evergreen Escalation"),
    "Wing Cap":         course_meta(0x1d, [-1],   "Florotoxin Cavern"),
    "Vanish Cap":       course_meta(0x12, [-1],   "Hawthorne Halls"),
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
    return measured(nof_stars() == num_stars, when=!in_title_or_file_select())
        && prev(nof_stars()) == num_stars - 1
        && level_id__mem == prev(level_id__mem) // to prevent switching files after the ending picture puts you back to the title screen...
}

function milestone_meta(title, description, stars, points, id=0, badge="0") => {"title": title, "description": description, "stars": stars, "points": points, "id": id, "badge": badge}

milestones = [
    milestone_meta("Take to the Stump",
        "Collect 10 stars.",
        stars=10, points=3, id=305911, badge="338752"),
    milestone_meta("Ascending the Trunk",
        "Collect 25 stars.",
        stars=25, points=5, id=305912, badge="338753"),
    milestone_meta("Crown Me",
        "Collect 45 stars.",
        stars=45, points=10, id=305913, badge="338754"),
    milestone_meta("Ultimate Tree Hugger",
        "Collect all 65 stars.",
        stars=65, points=10, id=305914, badge="338755"),
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
    title = "Tree Switches",
    description = "Press the red, green, and blue !-switches.",
    points = 3,
    trigger = rgb_trigger(),
    id=305915,
    badge="338756"
)

achievement(
    title = "I'm on a Tree",
    description = "Defeat Bowser in Arborial Promenade and collect the key.",
    points = 5,
    trigger = in_level("Key 1") && collected_star_action_check(),
    id=305916,
    badge="338757"
)

achievement(
    title = "Won't Leave Bowser Alone",
    description = "Defeat Bowser in Box Factory and collect the key.",
    points = 5,
    trigger = in_level("Key 2") && collected_star_action_check(),
    id=305917,
    badge="338758"
)

achievement(
    title = "The Treehouse is Mine",
    description = "Defeat Bowser in the Core and collect the grand star.",
    points = 10,
    trigger = in_level("Final Fight") && interaction_object() != 0 && object_is(interaction_object(), "grand star"),
    id=305918,
    badge="338759"
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

// https://github.com/n64decomp/sm64/blob/master/levels/course_defines.h indexes (add 0x0c) (remember endian weirdness)
//and https://github.com/aglab2/SM64StarDisplay/blob/9d6c11e6af49a4f90a5d8020e8a94fdd611603d0/StarManager/LevelInfo.cs#L25
course_offsets = {
    "Course 1":  course_stars_meta(sum_star_bits(0x0f, range(0, 6)), 5, "Your Generic Grassland", id=305922, badge="338763"), 
    "Course 2":  course_stars_meta(sum_star_bits(0x0e, range(0, 6)), 5, "Wooden Fortress", id=305923, badge="338764"),
    "Course 3":  course_stars_meta(sum_star_bits(0x0d, range(0, 6)), 5, "Haunted (Autumn) Forest", id=305924, badge="338765"),
    "Course 4":  course_stars_meta(sum_star_bits(0x0c, range(0, 6)), 10, "Soaked Trees", id=305925, badge="338766"),
    "Course 5":  course_stars_meta(sum_star_bits(0x13, range(0, 6)), 10, "Trees Touching the Rainbow", id=305926, badge="338767"),
    "Course 6":  course_stars_meta(sum_star_bits(0x12, range(0, 6)), 10, "Summit of the Trees", id=305927, badge="338768"),
    "Course 7":  course_stars_meta(sum_star_bits(0x11, range(0, 6)), 10, "End of the Tree's Life Cycle", id=305928, badge="338769"),
    
    "Bowser 1":   course_stars_meta(sum_star_bits(0x18, range(0, 1)), 3, "Walk of Fame", id=305919, badge="338760"),
    "Bowser 2":   course_stars_meta(sum_star_bits(0x1f, range(0, 1)), 3, "Factory Treasures", id=305920, badge="338761"),
    "Bowser 3":   course_stars_meta(sum_star_bits(0x1e, range(0, 1)), 4, "Stars in the Really Old Tree", id=305921, badge="338762"),
    
    "Wing Cap":   course_stars_meta(sum_star_bits(0x23, range(0, 2)), 3, "Fly Above Toxic Plants", id=305931, badge="338772"),
    "Metal Cap":  course_stars_meta(sum_star_bits(0x1c, range(0, 2)), 3, "Metal Climbing", id=305929, badge="338770"),
    "Vanish Cap": course_stars_meta(sum_star_bits(0x22, range(0, 2)), 3, "Get Lost Mario in Halls", id=305930, badge="338771"),
}
function course_star_achievements() {
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
            
        achievement(
            title=title,
            description=description,
            points=info["points"],
            trigger= in_level(c)
                && prev(bits) == star_count - 1
                && measured(bits == star_count, when = common_in_file_check()),
            id = info["id"],
            badge = info["badge"]
        )
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
    mushies_meta("Course 1", "No Reason to Come Up Here",
        "Collect the 1-up mushroom in {0}.", 1,
        [{"type": "stationary", "count": 1}],
        level_check=remained_in_level("Course 1", hit=0),
        id=305932, badge="338773"),
    mushies_meta("Course 4", "No Reason to Come Up Here Either",
        "Collect the 1-up mushroom in {0}.", 1,
        [{"type": "stationary", "count": 1}],
        level_check=remained_in_level("Course 4", hit=0),
        id=305933, badge="338774"),
    mushies_meta("Metal Cap", "Evergreen Fungus",
        "Collect the 1-up mushroom in {0}.", 1,
        [{"type": "stationary", "count": 1}],
        level_check=remained_in_level("Metal Cap", hit=0),
        id=305934, badge="338775"),
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

// lbs

leaderboard(
    title="Barkbuilt Race Time",
    description="Complete the timed race in Course 2 as fast as possible.",
    start = in_level("Course 2")
        && hud_timer_started_counting()
        && hud_timer_shown() == 1,
    cancel = !in_level("Course 2") || hud_timer_shown() == 0,
    submit = hud_timer_stopped_counting()
        && hud_timer_shown() == 1
        && hud_timer() > 0,
    value = 2*hud_timer(),
    format = "FRAMES",
    lower_is_better=true
)

// side challenges

achievement(
    title="Let's Not",
    description="Collect the star 'Climb the Tree' in Foliage Fields without grabbing any tree.",
    points=2,
    trigger=remained_in_level("Course 1", hit=1)
        && never(just_increased(on_pole()))
        && trigger_when(collected_star_action_check(1)),
    id=305935,
    badge="338776"
)

achievement(
    title="Double Timer Action",
    description="Finish the timed race in Barkbuilt Barracks while still wearing your metal cap (must spawn timer star).",
    points=5,
    trigger=in_level("Course 2")
        && wearing_metal_cap() != 0
        && object_changed_to(g_cutscene_focus__mem, "spawned star")
        && object_star_mission(g_cutscene_focus__mem) == 1,
    id=305936,
    badge="338777"
)

achievement(
    title="Make No Noise",
    description="Collect the star 'Scare Off the Resident' in Ghostly Grotto without pressing the purple switch.",
    points=3,
    trigger=remained_in_level("Course 3", hit=1)
        && never(object_changed_to(stood_on_object(), "purple box switch"))
        && trigger_when(collected_star_action_check(1)),
    id=305937,
    badge="338778"
)

achievement(
    title="I-Frame Teamwork With the Enemy",
    description="Collect the star 'Beneath the Burning Box' in Driftwood Lake without getting a metal cap.",
    points=2,
    trigger=remained_in_level("Course 4", hit=1)
        && never(just_increased(wearing_metal_cap()))
        && trigger_when(collected_star_action_check(4)),
    id=305938,
    badge="338779"
)

achievement(
    title="A Few Will Do",
    description="Collect the star 'Wallkicks Hopefully Work' in Skyhigh Garden, wallkicking no more than 4 times.",
    points=5,
    trigger=never(level_changed())
        && ((in_level("Course 5") && hud_stars_shown() != 0 && 
        (trigger_when(collected_star_action_check(4))) && disable_when(repeated(5, wallkicked())))
        || (measured(repeated(4, wallkicked()), when=in_level("Course 5")) && impossible_condition())),
    id=305939,
    badge="338780"
)

achievement(
    title="Let's Cheese",
    description="Collect the star 'Sloped Shenanigans' in Canopy Chaos while still wearing your wing cap.",
    points=2,
    trigger=in_level("Course 6")
        && prev(wearing_wing_cap()) != 0
        && trigger_when(collected_star_action_check(3)),
    id=305940,
    badge="338781"
)

achievement(
    title="No Fire Protection Needed",
    description="Collect the star 'Inside the Tree' in Ashember Alpine without getting a metal cap.",
    points=3,
    trigger=remained_in_level("Course 7", hit=1)
        && never(just_increased(wearing_metal_cap()))
        && trigger_when(collected_star_action_check(2)),
    id=305941,
    badge="338782"
)

achievement(
    title="Bull(y) Economy Amirite Fellas",
    description="Collect 100 coins in Ashember Alpine.",
    points=10,
    trigger=prev(nof_coins()) < 100
        && measured(nof_coins() >= 100, when=in_level("Course 7")),
    id=305942,
    badge="338783"
)

achievement(
    title="See Me",
    description="Collect the star from the big Mr. I in Hawthorne Halls while still wearing your vanish cap.",
    points=3,
    trigger=in_level("Vanish Cap")
        && prev(wearing_vanish_cap()) != 0
        && trigger_when(collected_star_action_check(2)),
    id=305943,
    badge="338784"
)

achievement(
    title="Climb With Feet, Not Boxes",
    description="Collect the star on the mountain top of Evergreen Escalation (above switch boxes) without standing on the purple switch.",
    points=3,
    trigger=remained_in_level("Metal Cap", hit=1)
        && never(object_changed_to(stood_on_object(), "purple box switch"))
        && trigger_when(collected_star_action_check(2)),
    id=305944,
    badge="338785"
)

achievement(
    title="Flying Kinda Fast But Not Really",
    description="Collect the red coin star in Florotoxin Cavern without picking up more than one additional wing cap.",
    points=4,
    trigger=remained_in_level("Wing Cap", hit=1)
        && never(collided_with_object("wing cap", 2))
        && trigger_when(collected_star_action_check(3)),
    id=305945,
    badge="338786"
)

// RP

meta_descriptions = {
    0x00: "Starting up the game",
    0x02: "Playing with Mario head",
    0x21: "In File Select",
}

general_level_dict = {
    0x0901: "frolicking in Foliage Fields",
    0x1801: "hitting invisible walls in Barkbuilt Barracks",
    0x0C01: "being spooky in Ghostly Grotto",
    0x0501: "visiting penguin's home in Driftwood Lake",
    0x0401: "fighting evil plants in Skyhigh Garden",
    0x0701: "rummaging the top of the tree in Canopy Chaos",
    0x1601: "on a hot-footed adventure in Ashember Alpine",
    
    0x1C01: "feeling chilly in Evergreen Escalation",
    0x1201: "getting lost in Hawthorne Halls",
    0x1D01: "avoiding deadly plants in Florotoxin Cavern",
    
    0x1101: "walking through Arborial Promenade",
    0x1E01: "not stumping for Bowser",
    0x1301: "working his way up the Box Factory",
    0x2101: "taking down Bowser in Box Factory",
    0x1501: "ascending in the Core",
    0x2201: "fighting Bowser for the treehouse",
    
    0x1001: "outside the Big Tree",
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
      "Mario-{2} is {0} with {1}⭐ and {6}🚶", level__lookup, stars__value, file__lookup, 
        rich_presence_lookup("Switch", pressed_switch__mem("red"), {1:"▣"}, "▢"),
        rich_presence_lookup("Switch", pressed_switch__mem("green"), {1:"▣"}, "▢"),
        rich_presence_lookup("Switch", pressed_switch__mem("blue"), {1:"▣"}, "▢"), lives__value
)
rich_presence_display("On a tree-ly amazing quest.", level_test__value)