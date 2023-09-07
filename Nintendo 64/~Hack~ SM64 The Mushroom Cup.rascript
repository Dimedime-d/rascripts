// ~Hack~ Super Mario 64: The Mushroom Cup
// #ID = 25359
// Made in RATools v1.12.1

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

function merge_arrays(arr1, arr2)
{
    newArr = arr1
    for i in arr2
    {
        array_push(newArr, i)
    }
    return newArr
}

offsets = {
    "TITLE SCREEN GEO":     0xE7CC0,

    "SAVE DATA":    (0x207700 - 0x70),
    
    "MUSIC ID":     0x22261e,

    "CURRENT DEMO INPUT":   0x32d5f0,
    "COLLECTED STAR ID":    0x32dd87, // 1-indexed
    "CURRENT AREA":         0x32ddcc,
    "FILE ID":              0x32ddf6,
    "MAP ID":               0x32ddfa,
    
    "CUTSCENE FOCUS":       0x32df24,
    
    "STOOD ON OBJECT":      0x330e34,
    "DIALOGUE ID":          0x331486,
    
    "CAMERA HUD STATUS":    0x33260a,
    "VBLANKS":              0x32d580,
    
    "LEVEL INDEX":      0x33bac8,
    "WARP DEST":        0x33b248,
    
    "TIME COUNTING":    0x33b25e,
    "HUD FLAGS":        0x33b268,   //  https://github.com/n64decomp/sm64/blob/1372ae1bb7cbedc03df366393188f4f05dcfc422/src/game/level_update.h#L91
    "HUD TIMER":        0x33b26e,
    
    "WARP TRANSITION":  0x33bab0,
    "MISSION ACTIVE":   0x33baca,
    
    "MARIO STRUCT":     0x33b170,

    "TIME STOP STATE":  0x33d480,
    "OBJECT ARRAY":     0x33d488,
    
    "EFFECTIVE MARIO OBJECT":   0x361158,
    "RED COINS COLLECTED":  0x3613fd,
    
    "MOP SWITCH":       0x400003,
    "CHECKPOINT FLAG":  0x400010,
}

// double-check this list between hacks, custom objects can shift things...
// take behav script (lower 16 bits) in quad/rom manager, add 0x800EB180 to get run-time behav script pointer
// no wait, it is 0x80115E00!
behaviour_script__values = { 
    "file manager":     0x8008FD58,
    
    "mission star manager": 0x800EE1C8,
    
    "grand star":       0x800EC894,
    
    "stationary 1-up":  0x800EF1FC,
    "impartial 1-up":   0x800EF15C,
    "chasing 1-up":     0x800EF2C8,
    "running away 1-up":0x800EF190,
    "activator 1-up":   0x800EF26C,
    
    "purple switch":    0x800EC62C,
    "warp pipe":        0x800EB920,
    "koopa shell":      0x800ED0BC,
    "blue coin for block":  0x800ED708,
    
    "single goomba":    0x800EF8AC,
    
    "metal box":        0x800EC698,
    
    "warp":             0x800EB900,
    
    "falling plank":    0x800EB7EC,
    "koopa flag checkpoint":    0x800EF750,
    
    "crazy box":        0x800EC7D0,
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
    "area":               0x90,  // dword (pointer to area)
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

function in_toxic_gas() => bit0(mario_field("input") + 1)

function hat_in_hand()        => bit5(mario_field("hat bitflags"))
function hat_on_head()        => bit4(mario_field("hat bitflags"))
function wearing_wing_cap()   => bit3(mario_field("hat bitflags"))
function wearing_metal_cap()  => bit2(mario_field("hat bitflags"))
function wearing_vanish_cap() => bit1(mario_field("hat bitflags"))

function capless() {
    caps = (wearing_wing_cap() + wearing_metal_cap() + wearing_vanish_cap())
    return never(caps > prev(caps))
}

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
function mario_area() => tbyte(mario_field("area"))
function stood_on_object() => tbyte(stood_on_object__addr)

function controller() => tbyte(mario_field("controller"))

// https://github.com/n64decomp/sm64/blob/1372ae1bb7cbedc03df366393188f4f05dcfc422/include/PR/os_cont.h#L122

//and https://github.com/n64decomp/sm64/blob/1372ae1bb7cbedc03df366393188f4f05dcfc422/include/types.h#L23
function controller_a_button() => bit(15, controller() + 0x12)
function controller_b_button() => bit(14, controller() + 0x12)
function controller_z_button() => bit(13, controller() + 0x12)
function controller_l_button() => bit(5, controller() + 0x12)

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

//https://github.com/n64decomp/sm64/blob/66018e9f3caaa67399218971d61366cb3f7ba7d7/include/sm64.h#L140
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
    "twirl in tornado":            0x10020372,
    "slide kick":                  0x018008AA,
    "air kick":                    0x018008AC,
    "triple jump":                 0x01000882,
    "wall kick":                   0x03000886, // also pole jump
    "long jump":                   0x03000888, // slow or faste
    "shot from cannon":            0x00880898,
    "air sitting":                 0x0300088E,
    
    "crouch sliding":              0x04808459,
    "walking":                     0x04000440,
    
    "ledge grab":                  0x0800034B,
    
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
function intangible() => bit4(mario_current_action__addr + 1)
function on_pole() => bit4(mario_current_action__addr + 2)

function wallkicked() => just_changed_any(angle_yaw()) && 
    !mario_action_was("climbing pole") && !mario_action_was("holding pole") && mario_action_is("wall kick")
// reference - SR6.25 set (doesn't check pole action)

// ----------------------------- //
//   o t h e r   s t r u c t s   //
// ----------------------------- //
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
//     a r e a s     //
// ----------------- //

area__struct = {
    "index":            0x00, // 8-bit
    "geo layout":       0x04, // pointer
    "camera":           0x24, // pointer
}
area__sizeof = 0x40

function area_field(base, field) => struct_field(area__struct, base, field)

function area_index(addr) => byte(area_field(addr, "index"))
function area_camera(addr) => tbyte(area_field(addr, "camera"))
function area_geo_layout(addr) => tbyte(area_field(addr, "geo layout")) // don't make this a dword in case you wanna follow this pointer...

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
    "graphics timer":        0xf0,  // dword
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

function object_graphics_timer(addr) => dword(object_field(addr, "graphics timer"))

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
function object_teleporter_id(addr) => word(object_field(addr, "warp destination"))

function object_koopa_flag_race_started(addr) => dword(object_field(addr, "koopa flag race started"))
function object_koopa_flag_race_finished(addr) => dword(object_field(addr, "koopa flag race finished"))
function object_koopa_flag_ktq_finished(addr) => dword(object_field(addr, "koopa flag ktq finished"))

function object_eyerok_hands_remaining(addr) => dword(object_field(addr, "eyerok hands remaining"))
function object_warp_dest(addr) => word(object_field(addr, "warp destination"))

function mario_collision_check(obj_addr, obj_name, nth_collided) {
    return object_num_collided_objects(mario_object()) >= nth_collided
            && (
                object_just_deactivated(obj_addr)
                || (obj_addr != prev(obj_addr)) 
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

function started_colliding_with_object(obj_name){
    obj_tally = []
    for i in range(1,4) {
        obj_addr = object_nth_collided_object(mario_object(), i)
        
        coll_check = object_num_collided_objects(mario_object()) >= i && object_changed_to(obj_addr, obj_name)
        array_push(obj_tally,
            repeated(1, coll_check))   
    }
    return tally(1, obj_tally)
}

// Interactions

// Unsolved problem - how to handle stale interaction_object() when a box/coin star loads into the same slot?
//function collecting_star_object(obj_name, mission) {
//    obj = interaction_object()
//    return obj != 0
//           && object_is(obj, obj_name)
//           && object_star_mission(obj) == mission
//}

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

function just_used_teleporter(id) {
    obj = interaction_object()
    return obj != 0
        && mario_action_changed_to("start teleporting")
        && object_is(obj, "teleporter")
        && object_teleporter_id(obj) == id
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

camera_hud_status__addr = offsets["CAMERA HUD STATUS"]
//https://github.com/n64decomp/sm64/blob/66018e9f3caaa67399218971d61366cb3f7ba7d7/src/game/camera.h#L161
function camera_status_mario()  => bit(0, camera_hud_status__addr)
function camera_status_lakitu() => bit(1, camera_hud_status__addr)
function camera_status_fixed()  => bit(2, camera_hud_status__addr)
function camera_status_c_down() => bit(3, camera_hud_status__addr)

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
    else if color == "key 1 door"
        switch_mem = bit6(current_file__addr + 8)
    else if color == "key 2 door"
        switch_mem = bit7(current_file__addr + 8)
    else if color == "yellow"
        switch_mem = bit1(current_file__addr + 9) // CHECK me        
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

g_red_coins_collected__addr = offsets["RED COINS COLLECTED"]
g_red_coins_collected__mem = byte(g_red_coins_collected__addr)

g_current_demo_input__addr = offsets["CURRENT DEMO INPUT"]
g_current_demo_input__mem = dword(g_current_demo_input__addr)

g_cutscene_focus__addr = offsets["CUTSCENE FOCUS"]
g_cutscene_focus__mem = tbyte(g_cutscene_focus__addr) // pointer to object

function effective_mario_object() => tbyte(offsets["EFFECTIVE MARIO OBJECT"])

num_vblanks__mem = dword(offsets["VBLANKS"])

current_area__mem = tbyte(offsets["CURRENT AREA"])

time_stop_state__addr = offsets["TIME STOP STATE"]
function time_stop_enabled() => bit(1, time_stop_state__addr)

mop_switch__addr = offsets["MOP SWITCH"]
mop_switch__mem = byte(mop_switch__addr)

checkpoint_flag__addr = offsets["CHECKPOINT FLAG"]
checkpoint_flag__mem = byte(checkpoint_flag__addr)

function course_meta(value, sublevel_values, full_name, clean_name="0") {
    if (clean_name == "0")
        return {"value": value, "sublevel values": sublevel_values, "full name": full_name, "clean name": full_name}
    return {"value": value, "sublevel values": sublevel_values, "full name": full_name, "clean name": clean_name}
}

course_infos = {
    "Castle Grounds":       course_meta(0x10, [-1],   "The mushroom shrine"), // OW1
    "Castle Courtyard":     course_meta(0x1A, [-1],   "The old overworld"), // OW2
    "Inside Castle":        course_meta(0x06, [-1],   "The ending area"), // ending, has indigo island OW
    
    "Course 1":         course_meta(0x09, [-1],   "Pirahanna Plant Marsh"),
    "Course 2":         course_meta(0x18, [-1],   "Cyan Reaper Resovoir"),
    "Course 3":         course_meta(0x0c, [-1],   "Rocky Blue Barrel"),
    "Course 4":         course_meta(0x05, [-1],   "Grandma's Candyland"),
    "Course 5":         course_meta(0x04, [-1],   "Puffy Parachute Palace"),
    "Course 6":         course_meta(0x07, [-1],   "Mars-Magmatic Mesh"),
    "Course 7":         course_meta(0x16, [-1],   "Blazing Flora Basin"),
    "Course 8":         course_meta(0x08, [-1],   "Hazy Jungle Jape"),
    "Course 9":         course_meta(0x17, [-1],   "Parched Woods"),
    "Course 10":        course_meta(0x0a, [-1],   "Springtime Brightlight Golf Fight"),
    "Course 11":        course_meta(0x0b, [-1],   "Orange Branch Basket"),
    "Course 12":        course_meta(0x24, [-1],   "Rocky Twilight Range"),
    "Course 13":        course_meta(0x0e, [-1],   "Atlas Station"), //TTC
    "Course 6B":        course_meta(0x0d, [-1],   "Frozen Moon Deimos"), //THI
    "Course 2B":        course_meta(0x0f, [-1],   "Sunken Ghost Ship"), // RR
    
    "Aquarium":         course_meta(0x14, [-1],   "Crusty Crator"), // Aquarium
    "Cloud Stage":      course_meta(0x1f, [-1],   "Shrine of the Mushroom"),
    "Slide":            course_meta(0x1b, [-1],   "Drout Jungle"),

    "Bowser 1":         course_meta(0x11, [-1],   "Ancient Amber Ambessy"),
    "Key 1":            course_meta(0x1e, [-1],   "Ancient Amber Ambessy"),
    "Bowser 2":         course_meta(0x13, [-1],   "Cloudy Construction Zone"),
    "Key 2":            course_meta(0x21, [-1],   "Cloudy Construction Zone"),
    "Bowser 3":         course_meta(0x15, [-1],   "Master's Ascent"),
    "Final Fight":      course_meta(0x22, [-1],   "Master's Ascent"),
    "End Cake Picture": course_meta(0x19, [-1],   "The Ending Picture"),
    
    "Metal Cap":         course_meta(0x1c, [-1],   "Sewer Section"), // MC
    "Wing Cap":          course_meta(0x1d, [-1],   "Goomba Village"), // WC
    "Vanish Cap":        course_meta(0x12, [-1],   "Secret Silver Lake"),
}

function in_title_screen() => area_geo_layout(current_area__mem) == offsets["TITLE SCREEN GEO"]
function in_file_select() => object_is(nth_array_object(1), "file manager")
function new_file_hit() => once(pressed_switch__mem("valid game") == 0) && never(just_changed_any(file_num__mem))

function in_level(name, check_sublevels=1) {
    course_mem = level_id__mem
    course_value = course_infos[name]["value"]
    cond = always_true()
    if (course_value != 0x10) { // account for castle grounds initializing to 0
        cond = cond && (warp_dest_level() == course_value)
    } 
    cond = cond && (course_mem == course_value)
    
    if (check_sublevels != 0) {
        return cond && in_sublevel(name)
    }
    return cond
}

function in_sublevel(name) {
    if (course_infos[name]["sublevel values"][0] == -1) {return always_true()}
    
    // used to be an any_of statement but RATools won't let me compare an array to an integer constant :|
    return __ornext(any_of(course_infos[name]["sublevel values"], a => sublevel_id__mem == a))
}


function in_area(name, area=-1) {
    area_check = always_true()
    if (area != -1)
        area_check = sublevel_id__mem == area
    
    return in_level(name) && area_check
}

function level_changed(except_when_entering="") {
    cond = just_changed_any(warp_dest_level())
    if (except_when_entering != "")
        cond = cond && !in_level(except_when_entering)
    return cond
}
function screen_changed() => just_changed_any(warp_dest_level_area())

// the hit is for challenges that, if failed, require re-entering the level
function remained_in_level(name, hit=1) {
    if (hit != 0)
        return in_level(name) && once(prev(level_id__mem) != course_infos[name]["value"]) && never(level_changed(except_when_entering=name)) && !object_is(nth_array_object(0), "mission star manager")
    return in_level(name) && never(level_changed()) && !object_is(nth_array_object(0), "mission star manager")
    
    // remove pause on mission manager check
    // originally, pause was used to allow button presses during star select, but it blocked reset logic if you directly warped into a numbered course from a different course with a hit tracker
}

function remained_in_level_no_checkpoint(name, warp=-1) {
    checkpoint_hit = once(prev(level_id__mem) != course_infos[name]["value"] && checkpoint_flag__mem == 0)
    if (warp >= 0) {
        checkpoint_hit = once(prev(level_id__mem) != course_infos[name]["value"] && checkpoint_flag__mem == 0    && warp_dest_node() == warp
            && warp_dest_level() == course_infos[name]["value"])
    }
    return in_level(name) && checkpoint_hit && never(level_changed(except_when_entering=name)) && !object_is(nth_array_object(0), "mission star manager") // you're allowed to activate checkpoints, but not respawn at them. kinda like a save state vs load state scenario
}

// for submap-specific challenges
function remained_in_level_area(name, area, hit=1) {
    level_area_value = (course_infos[name]["value"]*0x100) + area
    if (hit != 0)
        return in_area(name, area) && once(just_changed_to(warp_dest_level_area(), level_area_value)) && never(screen_changed() && sublevel_id__mem != area)
    else
        return always_true()
}

// NEW - check certain level entrances
function remained_in_level_from_warp(name, node) {
    return in_level(name) 
        && once(prev(level_id__mem) != course_infos[name]["value"]
            && warp_dest_node() == node
            && warp_dest_level() == course_infos[name]["value"]) 
        && never(level_changed(except_when_entering=name)) // need an exception for the current level to stop the checkpoint hit from resetting
        && !object_is(nth_array_object(0), "mission star manager") // just to hide challenge indicator on star select
}

function in_intro_or_file_select() => any_of([0x21], a => music_id__mem == a) // 0x02 is used (devour realm music)

function common_in_file_check() => !in_intro_or_file_select() && level_id__mem != 1 && g_current_demo_input__mem == 0

dialog_id__addr = offsets["DIALOGUE ID"]
dialog_id__mem = word(dialog_id__addr)

//
//  Cheevs
//

// Milestones

function star_milestone_trigger(num_stars) {
    // remove measured here, it overrides other more important progress indicators
    return nof_stars() == num_stars
        && !in_file_select()
        && prev(nof_stars()) == num_stars - 1
        && level_id__mem == prev(level_id__mem) // to prevent switching files after the ending picture puts you back to the title screen...
}

function milestone_meta(title, description, stars, points, id=0, badge="0") => {"title": title, "description": description, "stars": stars, "points": points, "id": id, "badge": badge}

milestones = [
    milestone_meta("A Peek in the Shrine",
        "Collect your first star.",
        stars=1, points=0, id=344836, badge="389923"),
    milestone_meta("When the Star Door is After the Key Door",
        "Collect FIFTEEN stars.",
        stars=15, points=5, id=344837, badge="389924"),
    milestone_meta("Shortcut Unlocked",
        "Collect 71 stars.",
        stars=71, points=10, id=344838, badge="389925"),
    milestone_meta("Canonical Any% But You Can Go Lower",
        "Collect 99 stars.",
        stars=99, points=25, id=344839, badge="389926"),
    milestone_meta("Complete Shrine Collection",
        "Collect all 130 stars.",
        stars=130, points=50, id=344840, badge="389927"),
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

hack_switches = ["red", "blue", "green"] // 3 used

function all_switches_trigger() {
    switches_now = sum_of(hack_switches, a => pressed_switch__mem(a))
    switches_prev = sum_of(hack_switches, a => pressed_switch__mem(a, delta=1))
    
    return level_id__mem == prev(level_id__mem) // to prevent switching files after the ending picture puts you back to the title screen...
    && file_num__mem == prev(file_num__mem)
    && measured(switches_now == length(hack_switches))
    && switches_prev == (length(hack_switches) - 1)
    && switches_prev != length(hack_switches)
}

// caps / bowsers

achievement(
    title = "Shroomy Switcheroo",
    description = "Press the red, green, and blue !-switches.",
    points = 5,
    trigger = all_switches_trigger(), id=344841, badge="389928"
)

achievement(
    title = "Bowser's New Look",
    description = "Defeat Bowser in Ancient Amber Ambessy and obtain Key 1.",
    points = 10,
    trigger = in_level("Key 1") && collected_star_action_check(), id=344842, badge="389929"
)

achievement(
    title = "Not Another Arena",
    description = "Complete Cloudy Construction Zone (both parts) and obtain Key 2.",
    points = 10,
    trigger = in_level("Key 2") && collected_star_action_check(), id=344843, badge="389930"
)

achievement(
    title = "Still Stuck in the Shrine",
    description = "Defeat Bowser in Master's Ascent and collect the grand star.",
    points = 10,
    trigger = in_level("Final Fight") && interaction_object() != 0 && object_is(interaction_object(), "grand star"), id=344844, badge="389931"
)

achievement(
    title = "From Orange To Indigo",
    description = "Get to the indigo castle (ending warp) after escaping from the mushroom shrine.",
    points = 10,
    trigger = in_level("Inside Castle") && just_used_warp(5120), id=344845, badge="389932"
)

// another cheev for best ending

// c o u r s e  s t a r s


function course_stars_meta(course, star_bits, points, title, description_add="", id=0, badge="0") => {"course": course, "star bits": star_bits, "points": points, "title": title, "description add": description_add, "id": id, "badge": badge}

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
course_offsets = [
    course_stars_meta("Course 1", sum_star_bits(0x0f, range(0,6)), 10, "Unfriendly Terrain Marsh", id=344846, badge="389933"), 
    course_stars_meta("Course 2", sum_star_bits(0x0e, range(0,6)), 10, "Taking Treasures Back From Ghosts", id=344847, badge="389934"),
    course_stars_meta("Course 3", sum_star_bits(0x0d, range(0,6)), 10, "Big Blue Sand Cavern", id=344848, badge="389935"),
    course_stars_meta("Course 4", sum_star_bits(0x0c, range(0,6)), 10, "Dark Chocolate Adventure", id=344849, badge="389936"),
    course_stars_meta("Course 5", sum_star_bits(0x13, range(0,6)), 10, "Familiar Castle Jumps", id=344850, badge="389937"),
    course_stars_meta("Course 6", sum_star_bits(0x12, range(0,6)), 10, "Martian Invasion", id=344851, badge="389938"),
    course_stars_meta("Course 7", sum_star_bits(0x11, range(0,6)), 10, "Other Fire Flower Fields", id=344852, badge="389939"),
    course_stars_meta("Course 8", sum_star_bits(0x10, range(0,6)), 10, "Cold Toxic Jape's End", id=344853, badge="389940"),
    course_stars_meta("Course 9", sum_star_bits(0x17, range(0,6)), 10, "Bleached Terrain", id=344854, badge="389941"),
    course_stars_meta("Course 10", sum_star_bits(0x16, range(0,6)), 10, "Shooting Flying Battery", id=344855, badge="389942"),
    course_stars_meta("Course 11", sum_star_bits(0x15, range(0,6)), 10, "Matching Color Water and Lava Falls", id=344856, badge="389943"),
    course_stars_meta("Course 12", sum_star_bits(0x14, range(0,6)), 10, "Challenger Under Cover of Darkness", id=344857, badge="389944"),
    course_stars_meta("Course 6B", sum_star_bits(0x1b, range(0,6)), 10, "Still A Rocky Ridge", id=344858, badge="389945"),
    course_stars_meta("Course 13", sum_star_bits(0x1a, range(0,6)), 10, "Rainbow Rides", id=344859, badge="389946"),
    course_stars_meta("Course 2B", sum_star_bits(0x19, range(0,6)), 10, "More Sunken Ship Plundering", id=344860, badge="389947"),
    
    course_stars_meta("Bowser 1",  sum_star_bits(0x18, range(0,0)), 2, "Same Colored Star", id=344861, badge="389948"),
    course_stars_meta("Bowser 2",  sum_star_bits(0x1f, range(0,1)), 4, "Construction Treasures", id=344862, badge="389949"),
    course_stars_meta("Bowser 3",  sum_star_bits(0x1e, range(0,0)), 3, "The Prize for Making It Up This High", id=344863, badge="389950"),
    
    course_stars_meta("Metal Cap",  sum_star_bits(0x1c, range(0,6)), 10, "More Plumbing Work", id=344864, badge="389951"),
    course_stars_meta("Vanish Cap", sum_star_bits(0x22, range(0,2)), 5, "Vanishing Lake", id=344865, badge="389952"),
    course_stars_meta("Wing Cap",   sum_star_bits(0x23, range(0,2)), 5, "False Mushroom Idols", id=344866, badge="389953"),
    
    course_stars_meta("Slide",      sum_star_bits(0x1d, range(0,3)), 10, "Dried-Out Half-Dead Jungle", id=344867, badge="389954"), // DJ
    course_stars_meta("Aquarium",   sum_star_bits(0x20, range(0,2)), 5, "The Crustiest Slide", id=344868, badge="389955"), // CC
    course_stars_meta("Cloud Stage",sum_star_bits(0x21, range(0,0)), 3, "Finally a Way Out?", id=344869, badge="389956"), // MS
    
]
function course_star_achievements(ignore_ids=0) {
    for info in course_offsets {
        course = info["course"]
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
        
        if (course == "Bowser 2") {
            star_qty = format("{0} (that count towards total)", star_qty)
        }
        
        title = info["title"]
        description = format("Collect {0} in {1}{2}.",
            star_qty,
            course_infos[course]["full name"],
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
            trigger= in_level(course)
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

cannon_bits = sum_cannon_bits([0x0c, 0x0d, 0x0f, 0x10, 0x11, 0x1b, 0x1c, 0x20])
star_collection_achievement(
    stars=[cannon_bits], total=8,
    title = "Open All the Holes",
    description = "Open all 8 cannons.",
    points = 10, id=344870, badge="389957"
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
    mushies_meta("Course 1", "Piranha Shrooms",
        "Collect all 6 1-up mushrooms in {0}. (Needs vanish cap)", 5,
        [{"type": "stationary", "count": 4},
        {"type":  "impartial", "count": 2}],
        level_check=remained_in_level("Course 1", hit=0), id=344871, badge="389958"),
    mushies_meta("Course 3", "Around the Bullseye",
        "Collect all 5 1-up mushrooms in {0}.", 10,
        [{"type": "stationary", "count": 5}],
        level_check=remained_in_level("Course 3", hit=0), id=344872, badge="389959"),
    mushies_meta("Course 4", "Fudge Shroom",
        "Collect the 1-up mushroom in {0}.", 1,
        [{"type": "stationary", "count": 1}],
        level_check=remained_in_level("Course 4", hit=0), id=344873, badge="389960"),
    mushies_meta("Course 5", "Parachute Lifesaver",
        "Collect all 7 1-up mushrooms in {0}. Go down the slide last.", 10,
        [{"type": "stationary", "count": 5},
        {"type": "impartial", "count": 1},
        {"type": "chasing", "count": 1}],
        level_check=remained_in_level("Course 5", hit=0), id=344874, badge="389961"),
    mushies_meta("Course 6", "Magmatic Mushrooms",
        "Collect all 3 1-up mushrooms in {0}.", 3,
        [{"type": "stationary", "count": 1},
        {"type": "impartial", "count": 1},
        {"type": "running away", "count": 1}],
        level_check=remained_in_level("Course 6", hit=0), id=344875, badge="389962"),
    mushies_meta("Course 7", "Lone Life Surviving the Blaze",
        "Collect the 1-up mushroom in {0}.", 1,
        [{"type": "running away", "count": 1}],
        level_check=remained_in_level("Course 7", hit=0), id=344876, badge="389963"),
    mushies_meta("Course 8", "Cold Tomb Shrooms",
        "Collect all 3 1-up mushrooms in {0}. (Wing cap)", 3,
        [{"type": "stationary", "count": 2},
        {"type": "impartial", "count": 1}],
        level_check=remained_in_level("Course 8", hit=0), id=344877, badge="389964"),
    mushies_meta("Course 10", "Hole-in-One",
        "Collect the 1-up mushroom in {0}.", 1,
        [{"type": "impartial", "count": 1}],
        level_check=remained_in_level("Course 10", hit=0), id=344878, badge="389965"),
    mushies_meta("Course 11", "Orange Lifesaver",
        "Collect both 1-up mushrooms in {0}.", 2,
        [{"type": "stationary", "count": 1},
        {"type": "impartial", "count": 1}],
        level_check=remained_in_level("Course 11", hit=0), id=344879, badge="389966"),
    mushies_meta("Course 12", "Mushrooms in Twilight",
        "Collect all 3 1-up mushrooms in {0}.", 3,
        [{"type": "stationary", "count": 1},
        {"type": "impartial", "count": 1},
        {"type": "chasing", "count": 1}],
        level_check=remained_in_level("Course 12", hit=0), id=344880, badge="389967"),
    mushies_meta("Course 6B", "Frozen But Still Good to Eat",
        "Collect the 1-up mushroom in {0}.", 1,
        [{"type": "stationary", "count": 1}],
        level_check=remained_in_level("Course 6B", hit=0), id=344881, badge="389968"),
    mushies_meta("Course 13", "Stardust Lifesaver",
        "Collect both 1-up mushrooms in {0}.", 2,
        [{"type": "impartial", "count": 1},
        {"type": "chasing", "count": 1}],
        level_check=remained_in_level("Course 13", hit=0), id=344882, badge="389969"),
        
    mushies_meta("Castle Courtyard", "Remnants of the Old Hub",
        "Collect all 12 1-up mushrooms in {0}.", 4,
        [{"type": "stationary", "count": 12}],
        level_check=remained_in_level("Castle Courtyard", hit=0), id=344883, badge="389970"),
    mushies_meta("Bowser 1", "Lavafall Party",
        "Collect all 5 1-up mushrooms in {0}.", 1,
        [{"type": "stationary", "count": 5}],
        level_check=remained_in_level("Bowser 1", hit=0), id=344884, badge="389971"),
    mushies_meta("Bowser 2", "One Cloudy Shroom to Rule Them All",
        "Collect the 1-up mushroom in the first part of {0}.", 1,
        [{"type": "running away", "count": 1}],
        level_check=remained_in_level("Bowser 2", hit=0), id=344885, badge="389972"),
    mushies_meta("Bowser 3", "Heaven Ascension",
        "Collect both 1-up mushrooms in {0}.", 2,
        [{"type": "impartial", "count": 1},
        {"type": "stationary", "count": 1}],
        level_check=remained_in_level("Bowser 3", hit=0), id=344886, badge="389973"),
    mushies_meta("Key 2", "Hope You Don't Run Out",
        "Collect all 4 1-up mushrooms in the second part of {0}.", 1,
        [{"type": "stationary", "count": 4}],
        level_check=remained_in_level("Key 2", hit=0), id=344887, badge="389974"),
        
    mushies_meta("Metal Cap", "Dropped Sewer Shroom",
        "Collect the 1-up mushroom in {0}.", 1,
        [{"type": "stationary", "count": 1}],
        level_check=remained_in_level("Metal Cap", hit=0), id=344888, badge="389975"),
    mushies_meta("Wing Cap", "House Mushrooms",
        "Collect all 5 1-up mushrooms in {0}. Check the waterfall top.", 5,
        [{"type": "stationary", "count": 3},
        {"type": "impartial", "count": 1},
        {"type": "chasing", "count": 1}],
        level_check=remained_in_level("Wing Cap", hit=0), id=344890, badge="389976"),
    mushies_meta("Vanish Cap", "One Sunken Shroom",
        "Collect the 1-up mushroom in {0}. Keep swimming around.", 1,
        [{"type": "activator", "count": 1}],
        level_check=remained_in_level("Vanish Cap", hit=0), id=344891, badge="389977"),
        
    mushies_meta("Cloud Stage", "Shrine Tribute",
        "Collect the 1-up mushroom in {0}.", 1,
        [{"type": "stationary", "count": 1}],
        level_check=remained_in_level("Cloud Stage", hit=0), id=344892, badge="389978"),
    mushies_meta("Slide", "Dried Shrooms",
        "Collect all 3 1-up mushrooms in {0}. Check all the wooden posts.", 3,
        [{"type": "stationary", "count": 1},
        {"type": "impartial", "count": 1},
        {"type": "activator", "count": 1}],
        level_check=remained_in_level("Slide", hit=0), id=344893, badge="389979")
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

// Side challenge time... (remember, collected_star_action_check's star ID is 1-indexed)

function challenge_cheevs() {
    
    achievement(
        title = "Bored Run Around the Shrine",
        description = "Collect all 4 switch blue coins inside the mushroom shrine (1st overworld).",
        points = 5,
        trigger = never(level_changed())
            && measured(tally_of(range(1, 4), 4, a => repeated(4 ,mario_collision_check(object_nth_collided_object(mario_object(), a), "blue coin for block", a))), when=in_level("Castle Grounds")),
        id=344894, badge="389980"
    )
    
    achievement(
        title = "Not That Path",
        description = "Collect the star 'Follow the Path' in Course 1 without standing on any of the blue box switches.",
        points = 5,
        trigger = remained_in_level("Course 1", hit=1)
            && never(object_changed_to(stood_on_object(), "purple switch"))
            && trigger_when(collected_star_action_check(1)),
        id=344895, badge="389981"
    )
    
    achievement(
        title = "This Star Name Doesn't Help",
        description = "Collect the star 'Submerged Switch' in Course 2 without getting a metal cap.",
        points = 5,
        trigger = remained_in_level("Course 2", hit=1)
            && never(just_increased(wearing_metal_cap()))
            && trigger_when(collected_star_action_check(5)),
        id=344896, badge="389982"
    )
    
    c2_goombas = array_map([9, 11, 12], a => nth_array_object(a))
    
    achievement(
        title = "Nice Challenge",
        description = "Collect the alternate star to the star '5 Boxes in the Abandoned Plant Or...' in Course 2 without touching a goomba.",
        points = 5,
        trigger = remained_in_level("Course 2", hit=1)
            && all_of(c2_goombas, a => object_is(a, "single goomba"))
            && never(any_of([1, 100, 102], a => any_of(c2_goombas, b => just_changed_to(object_action(b), a))))
            && trigger_when(collected_star_action_check(2) && pos_y() > 3000.0),
        id=344897, badge="389983"
    )
    
    achievement(
        title = "Spooky Nonlinearity",
        description = "Collect the star 'Rooftop Climb' in Course 2B without standing on the box switch.",
        points = 5,
        trigger = remained_in_level("Course 2B", hit=1)
            && never(object_changed_to(stood_on_object(), "purple switch"))
            && trigger_when(collected_star_action_check(5)),
        id=344898, badge="389984"
    )
    
    achievement(
        title = "Skip the Secret",
        description = "Collect the star 'Sand Canyon Hike' in Course 3 at the very end of the canyon.",
        points = 2,
        trigger = in_level("Course 3")
            && collected_star_action_check(4)
            && pos_x() > -3000.0,
        id=344899, badge="389985"
    )
    
    achievement(
        title = "Still Don't Need to Backtrack",
        description = "Collect the star 'Goolagh Geiser' in Course 4 without getting a metal cap.",
        points = 5,
        trigger = remained_in_level("Course 4", hit=1)
            && never(just_increased(wearing_metal_cap()))
            && trigger_when(collected_star_action_check(5)),
        id=344924, badge="390010"
    )
    
    achievement(
        title = "Wallkick or Walljump, You Don't Need It",
        description = "Collect the star 'Underground Wall Jump Dungeon' in Course 4 without wallkicking.",
        points = 5,
        trigger = remained_in_level("Course 4", hit=1)
            && never(wallkicked())
            && trigger_when(collected_star_action_check(2)),
        id=344900, badge="389986"
    )
    
    achievement(
        title = "The Achievement That Makes You Skip Content",
        description = "Use the dev pipe in Ancient Amber Ambessy.",
        points = 1,
        trigger = in_level("Bowser 1")
            && just_used_pipe(0x02),
        id=344901, badge="389987"
    )
    
    achievement(
        title = "Leave the Sandbox the Way You Found It",
        description = "Collect the star 'Scavenger Hunt in the Sandbox' in Course 5 without pushing any of the boxes.",
        points = 5,
        trigger = remained_in_level("Course 5", hit=1)
            && never(mario_action_is("walking") && object_changed_to(surface_object(mario_wall_tri()), "metal box"))
            && never(mario_action_changed_to("walking") && object_is(surface_object(mario_wall_tri()), "metal box"))
            && trigger_when(collected_star_action_check(5)),
        id=344902, badge="389988"
    )
    
    //achievement(
    //    title = "Bouncing Without Boxes",
    //    description = "Collect the star 'Binary Mushroom Bouncing' in Course 5 without grabbing a crazy box or wing cap.",
    //    points = 10,
    //    trigger = remained_in_level("Course 5", hit=1)
    //        && never(object_changed_to(held_object(), "crazy box"))
    //        && never(just_increased(wearing_wing_cap()))
    //        && trigger_when(collected_star_action_check(2))
    //)
    
    achievement(
        title = "Plutonic Sewers",
        description = "Collect 99 coins in Sewer Section.",
        points = 5,
        trigger = in_level("Metal Cap")
            && prev(nof_coins()) < 99
            && nof_coins() >= 99,
        id=344903, badge="389989"
    )
    
    achievement(
        title = "No Time to Twirl",
        description = "Collect the star 'Twisters and Down' in Course 6 without twirling.",
        points = 5,
        trigger = remained_in_level("Course 6", hit=1)
            && never(mario_action_changed_to("twirl"))
            && never(mario_action_changed_to("twirl in tornado"))
            && trigger_when(collected_star_action_check(3)),
        id=344904, badge="389990"
    )
    
    achievement(
        title = "15 Reasons to Leave the Troll Stars Alone",
        description = "Collect all 15 switch blue coins in Course 6.",
        points = 10,
        trigger = never(level_changed())
            && measured(tally_of(range(1, 4), 15, a => repeated(15 ,mario_collision_check(object_nth_collided_object(mario_object(), a), "blue coin for block", a))), when=in_level("Course 6")),
        id=344905, badge="389991"
    )
    
    achievement(
        title = "Truly Missing Caps",
        description = "Collect the star 'The Missing Vanish Cap' in Course 6B without getting a vanish or wing cap.",
        points = 5,
        trigger = remained_in_level("Course 6B", hit=1)
            && never(just_increased(wearing_vanish_cap()))
            && never(just_increased(wearing_wing_cap()))
            && trigger_when(collected_star_action_check(5)),
        id=344906, badge="389992"
    )
    
    achievement(
        title = "No Shell For This Ride",
        description = "Collect the star 'Lava Boats Above the Basin' in Course 7 without riding on a Koopa Shell.",
        points = 5,
        trigger = remained_in_level("Course 7", hit=1)
            && never(object_changed_to(ridden_object(), "koopa shell"))
            && trigger_when(collected_star_action_check(4)),
        id=344907, badge="389993"
    )
    
    wc_planks = array_map(range(14, 16), a => nth_array_object(a))
    achievement(
        title = "Standing Pretty",
        description = "Collect the star inside the cave in Goomba Village without knocking over any of the planks.",
        points = 5,
        trigger = remained_in_level("Wing Cap", hit=1)
            && all_of(wc_planks, a => object_is(a, "falling plank"))
            && never(any_of(wc_planks, a => just_changed_to(object_action(a), 3)))
            && trigger_when(collected_star_action_check(2)),
        id=344908, badge="389994"
    )
    
    achievement(
        title = "Why So Slippery?",
        description = "Collect the star 'Icey Sliding' in Course 8 without getting a wing cap or getting burned.",
        points = 5,
        trigger = remained_in_level("Course 8", hit=1)
            && never(just_increased(wearing_wing_cap()))
            && never(mario_action_changed_to("lava boost"))
            && never(any_of(burning_actions, a => mario_action_changed_to(a)))
            && trigger_when(collected_star_action_check(3)),
        id=344909, badge="389995"
    )
    
    achievement(
        title = "Quick Underside Stroll",
        description = "Collect the star 'C8 Cavern Underside or C7 Troll' in Course 8 without going below half HP.",
        points = 5,
        trigger = remained_in_level("Course 8", hit=1)
            && never(hp() < 0x400)
            && trigger_when(collected_star_action_check(4)),
        id=344910, badge="389996"
    )
    
    c10_pars = [
        {"id": 1, "points": 5, "cheev id":344911, "badge":"389997", "name": "Carpet Ride Over the Windy Bridge", "title": "Go Away, Fly Guys", "par": 14},
        {"id": 2, "points": 5, "cheev id":344912, "badge":"389998", "name": "4 Golf Courses", "title": "Many Forced Cannons", "par": 34},
        {"id": 3, "points": 3, "cheev id":344913, "badge":"389999", "name": "A Complex Castle", "title": "Way More Than You Need", "par": 25},
        {"id": 4, "points": 3, "cheev id":344914, "badge":"390000", "name": "Rings of the Valley", "title": "Tight Flying", "par": 8},
        {"id": 5, "points": 5, "cheev id":344915, "badge":"390001", "name": "Mini-Desrt of the Rank", "title": "Can Still Skip Without Wings" , "par": 20},
        {"id": 6, "points": 10,"cheev id":344916, "badge":"390002",  "name": "Sandy Slides", "title": "Super Mario Can't Stop Shell Shredding", "par": 10},
    ]
    
    for c in c10_pars {
        logic = remained_in_level("Course 10", hit=1)
            && never(repeated(c["par"] + 1, warp_dest_type() == 0 && just_increased(controller_a_button())))
            && trigger_when(collected_star_action_check(c["id"]))
        desc = format("Collect the star '{0}' in Course 10 in {1} A presses or under. (See RP for count)", c["name"], c["par"])
        
        if (c["id"] != 4) {
            desc = format("{0} (No wing cap)", desc)
            logic = logic && never(just_increased(wearing_wing_cap()))
        }
        
        achievement(
            title = c["title"],
            description = desc,
            trigger = logic,
            points = c["points"],
            id = c["cheev id"],
            badge = c["badge"]
        )
    }
    
    achievement(
        title = "Old Fashioned Boosting",
        description = "Collect the star 'Hoppin' on Lave Once Again' in Course 11 without getting a wing cap.",
        points = 3,
        trigger = remained_in_level("Course 11", hit=1)
            && never(just_increased(wearing_wing_cap()))
            && collected_star_action_check(5),
        id=344917, badge="390003"
    )
    
    achievement(
        title = "Tri-Dive Hi Jumper Jr.",
        description = "Collect the star 'Overflowing Mountain' in Course 11 without standing on the box switch or taking damage.",
        points = 10,
        trigger = remained_in_level("Course 11", hit=1)
            && never(object_changed_to(stood_on_object(), "purple switch"))
            && never(just_increased(hp_decrement()))
            && never(any_of(burning_actions, a => mario_action_changed_to(a)))
            && trigger_when(collected_star_action_check(6)),
        id=344918, badge="390004"
    )
    
    achievement(
        title = "Boosting Crusade",
        description = "Collect the star 'Volcano Crusader' in Course 12 without getting a metal cap.",
        points = 3,
        trigger = remained_in_level("Course 12", hit=1)
            && never(just_increased(wearing_metal_cap()))
            && trigger_when(collected_star_action_check(1)),
        id=344919, badge="390005"
    )
    
    achievement(
        title = "Precise Aim",
        description = "Collect the star 'Precision' in Course 12 without using the cannon.",
        points = 5,
        trigger = remained_in_level("Course 12", hit=1)
            && never(mario_action_changed_to("in cannon"))
            && trigger_when(collected_star_action_check(6)),
        id=344920, badge="390006"
    )
    
    achievement(
        title = "Homing Amp Parade",
        description = "Collect the star 'Electric Challenge' in Course 13 without taking damage.",
        points = 5,
        trigger = remained_in_level("Course 13", hit=1)
            && never(just_increased(hp_decrement()))
            && trigger_when(collected_star_action_check(1)),
        id=344921, badge="390007"
    )
    
    achievement(
        title = "Cloudy Red Evils",
        description = "Obtain Key 2 (the star) in the second part of Cloudy Construction Zone that appears after getting all 8 red coins.",
        points = 5,
        trigger = in_level("Key 2")
            && collected_star_action_check(1)
            && pos_z() < 0.0,
        id=344922, badge="390008"
    )
    
    achievement(
        title = "There You Are",
        description = "Read a secret sign on an indigo island in the ending area.",
        points = 1,
        trigger = in_level("Inside Castle")
            && just_changed_from(dialog_id__mem, 133),
        id=344923, badge="390009"
    )
}

challenge_cheevs()

// LBs
leaderboard(
    title="Rugged Race",
    description="Complete the timed race in Crusty Crator as fast as possible.",
    start = in_level("Aquarium")
        && just_decreased(hud_timer_counting())
        && hud_timer_shown() == 1
        && hud_timer() > 0,
    cancel = always_false(),
    submit = always_true(),
    value = 2*hud_timer(),
    format = "FRAMES",
    lower_is_better=true,
    id = 73550
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

dj_race = nth_array_object(76)

leaderboard(
    title = "Dry Koopa Race",
    description = format("Win the race with Koopa the Quick in {0}.", course_infos["Slide"]["full name"]),
    start = in_area("Slide", 1) && object_koopa_race_started_and_won(dj_race, trig=0),
    cancel = always_false(),
    submit = always_true(),
    value = hud_timer()*2,
    format="FRAMES",
    lower_is_better = true,
    id = 73551
)

wc_race = nth_array_object(3)

leaderboard(
    title = "Race Through Goombas",
    description = format("Win the race with Koopa the Quick in {0}.", course_infos["Wing Cap"]["full name"]),
    start = in_area("Wing Cap", 1) && object_koopa_race_started_and_won(wc_race, trig=0),
    cancel = always_false(),
    submit = always_true(),
    value = hud_timer()*2,
    format="FRAMES",
    lower_is_better = true,
    id = 73552
)

// RP

general_level_dict = {
    0x0000: "stuck inside the mushroom shrine", // OW1
    0x1001: "stuck inside the mushroom shrine", // OW1
    0x0601: "nearing the end of the mushroom adventure", // OW2
    0x1a01: "exploring the old overworld", // OW3
    
    0x0901: format("sneaking around enemies in {0}", course_infos["Course 1"]["full name"]),
    0x1801: format("taking a spooky swim in {0}", course_infos["Course 2"]["full name"]),
    0x0C01: format("jumping with pockets full of sand in {0}", course_infos["Course 3"]["full name"]),
    0x0501: format("taking his sweet time in {0}", course_infos["Course 4"]["full name"]),
    0x0401: format("conquering the {0}", course_infos["Course 5"]["full name"]),
    0x0701: format("looking for camouflaged stars in {0}", course_infos["Course 6"]["full name"]),
    0x1601: format("scouring the burning flowers in {0}", course_infos["Course 7"]["full name"]),
    0x0801: format("feeling chilled and short of breath in {0}", course_infos["Course 8"]["full name"]),
    0x1701: format("climbing dried out woods in {0}", course_infos["Course 9"]["full name"]),
    // 0x0A01: "training in Olympian Summit", C10 - track A Presses
    0x0B01: format("surrounded by waterfalls in {0}", course_infos["Course 11"]["full name"]),
    0x2401: format("excavating the {0}", course_infos["Course 12"]["full name"]),
    0x0D01: format("landing on a familiar {0}", course_infos["Course 6B"]["full name"]),
    0x0E01: format("traveling on rainbows in {0}", course_infos["Course 13"]["full name"]),
    0x0F01: format("plundering the {0}", course_infos["Course 2B"]["full name"]),
    
    0x1C01: format("exploring endless pipes in {0}", course_infos["Metal Cap"]["full name"]),
    0x1D01: format("peacefully visiting the {0}", course_infos["Wing Cap"]["full name"]),
    0x1201: format("taking a quick dive through {0}", course_infos["Vanish Cap"]["full name"]),
    
    0x1B01: format("jumping around the dried valley in {0}", course_infos["Slide"]["full name"]),
    0x1401: format("sliding around in {0}", course_infos["Aquarium"]["full name"]),
    0x1F01: format("paying his tribute to the {0}", course_infos["Cloud Stage"]["full name"]),
    0x1901: "at the end of his journey", // end cake picture

    0x1101: format("leaping to meet Bowser in {0}", course_infos["Bowser 1"]["full name"]),
    0x1E01: format("fighting shroom-covered Bowser in {0}", course_infos["Key 1"]["full name"]),
    0x1301: format("collecting key fragments in {0}", course_infos["Bowser 2"]["full name"]),
    0x2101: format("looking for reds in the ravaged {0}", course_infos["Key 2"]["full name"]),
    0x1501: format("rising to the peak of {0}", course_infos["Bowser 3"]["full name"]),
    0x2201: format("fighting Bowser one last time in {0}", course_infos["Final Fight"]["full name"]),
}

level__lookup = rich_presence_lookup("Levels", warp_dest_level_area(), general_level_dict, "in an unbeknownst location")

stars__value = rich_presence_value("Number", nof_stars())
lives__value = rich_presence_value("Number", (byte(nof_lives__addr) ) - (bit7(nof_lives__addr) * 256))
level_test__value = rich_presence_value("Number", warp_dest_level_area())

file__lookup  = rich_presence_lookup("File", file_num__mem, {
    0x01: "A", 0x02: "B", 0x03: "C", 0x04: "D"
}, "??")

a_presses__value = rich_presence_value("Number", never(level_changed()) && measured(repeated(0, warp_dest_type() == 0 && just_increased(controller_a_button()))))

rich_presence_conditional_display(in_title_screen(), "Getting ready for a mushroom adventure. (Title Screen)")
rich_presence_conditional_display(in_file_select(), 
    "Getting ready for a mushroom adventure. (File Select)")
rich_presence_conditional_display(in_level("Course 10"),
      "Mario-{0} is going golfing! {1}⭐ {2}🚶 {3}xA Presses", file__lookup, stars__value, lives__value, a_presses__value)
rich_presence_conditional_display(
    level_id__mem != 1 && (music_id__mem != 0x21 || effective_mario_object() != 0), // both are false on file select, including after game over
      "Mario-{2} is {0} with {1}⭐ and {6}🚶 [🔴{3}] [🟢{4}] [🔵{5}]", level__lookup, stars__value, file__lookup, 
        rich_presence_lookup("Switch", pressed_switch__mem("red"), {1:"▣"}, "▢"),
        rich_presence_lookup("Switch", pressed_switch__mem("green"), {1:"▣"}, "▢"),
        rich_presence_lookup("Switch", pressed_switch__mem("blue"), {1:"▣"}, "▢"),
        lives__value
    )
rich_presence_display("Venturing through a mushroom shrine with a minimalist story.")