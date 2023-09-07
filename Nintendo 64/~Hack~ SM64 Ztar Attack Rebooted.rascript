// ~Hack~ Super Mario 64: Ztar Attack Rebooted
// #ID = 13112
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
    "TITLE SCREEN GEO":     0x98F80,

    "SAVE DATA":    (0x207700 - 0x70),
    
    "MUSIC ID":     0x22261e,

    "CURRENT DEMO INPUT":   0x32d5f0,
    "COLLECTED COURSE ID":  0x32dd83,
    "COLLECTED STAR ID":    0x32dd87, // 1-indexed
    "CURRENT AREA":         0x32ddcc, // POINTER
    "FILE ID":              0x32ddf6,
    "MAP ID":               0x32ddfa,
    
    "CUTSCENE FOCUS":       0x32df24,
    
    "STOOD ON OBJECT":      0x330e34,
    "DIALOGUE ID":          0x331486,
    "MENU MODE":            0x3314FA,
    
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
    "ZAR KILLSWITCH":   0x400043,
}

// double-check this list between hacks, custom objects can shift things...
// take behav script (lower 16 bits) in quad/rom manager, add 0x800EB180 to get run-time behav script pointer
// no wait, it is 0x80115E00!
behaviour_script__values = { 
    "file manager":     0x8008FD58,
    
    "teleporter":           0x800F19AC,
    "purple box switch":    0x800F26FC,
    
    "mission star manager": 0x800F4298,
    
    "stationary 1-up":  0x800F52CC,
    
    "baby penguin":     0x800F3338,
    "secret":           0x800F516C,
    "koopa flag checkpoint":    0x800F5820,
    "spawned star":     0x800F50B4,
    
    "big bully":        0x800F48B0,
    
    "koopa shell":      0x800F318C,
    
    "blue coin for block":  0x800F37D8,
    
    "final Bowser":     0x800F2AA0,
    
    "red star":         0x8040C000,
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
    "pulling door":                0x00001320,
    "warp door spawn":             0x00001322,
    "spawn spin landing":          0x00001325,
    "start teleporting":           0x00001336,
    "in cannon":                   0x00001371,
    "star grab fall":              0x00001904,
    "exit warp pipe":              0x00001923,
    "airborne spawn":              0x00001924,
    "death exit freefall":         0x00001929,
    
    "death exit landing":          0x00020467,
    "burning ground":              0x00020449,
    "burning jump":                0x010208B4,
    "burning fall":                0x010208B5,
    
    "ground pound landing":        0x0080023C,
    "lava boost":                  0x010208B7,
    "vertical wind":               0x1008089C,
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
    
    "text / cutscene":             0x20001306,
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
    "index":            0x03, // 8-bit
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
    "1up text pointer":     0x188,  // dword
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

function object_1up_text_pointer(addr) => dword(object_field(addr, "1up text pointer"))

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

last_star_course__addr = offsets["COLLECTED COURSE ID"]
last_star_couse__mem = byte(last_star__addr)

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
    "Castle Grounds":       course_meta(0x10, [-1],   "The Castle Grounds"),
    "Inside Castle":        course_meta(0x06, [-1],   "Inside the Castle"),
    "Castle Courtyard":     course_meta(0x1A, [-1],   "The Castle Courtyard"),
    
    
    "Course 1":         course_meta(0x09, [-1],   "Ztar Meadows"),
    "Course 2":         course_meta(0x18, [-1],   "Desolate Desert"),
    "Course 3":         course_meta(0x0c, [-1],   "Sunset Coastline"),
    "Course 4":         course_meta(0x05, [-1],   "Crystal Creek"),
    "Course 5":         course_meta(0x04, [-1],   "Mansion in the Woods"),
    "Course 6":         course_meta(0x07, [-1],   "Drowned Village"),
    "Course 7":         course_meta(0x16, [-1],   "Creezie Mountain"),
    "Course 8":         course_meta(0x08, [-1],   "Chillheat Temple"),
    "Course 9":         course_meta(0x17, [-1],   "Aquatic Pit"),
    "Course 10":        course_meta(0x0a, [-1],   "Piranha Swamp"),
    "Course 11":        course_meta(0x0b, [-1],   "Skyhigh Gorges"),
    "Course 12":        course_meta(0x24, [-1],   "Daredevil Heights"),
    "Course 13":        course_meta(0x0d, [-1],   "Polluted Lakes"), //THI
    "Course 14":        course_meta(0x0e, [-1],   "Desertic Industries"), //TTC
    "Course 15":        course_meta(0x0f, [5],    "Negative Realm: Forbidden Universe"),
    "Ztar's Dream":     course_meta(0x0f, [1, 2, 3, 4],   "Ztar's Dream"),
    "Negative Space":   course_meta(0x0f, [6],   "Negative Space"),
    "Normal Ending":    course_meta(0x0f, [7],   "Normal Ending"),
    
    "Aquarium":         course_meta(0x14, [-1],   "The Daylight Sanctuary"),
    "Cloud Stage":      course_meta(0x1f, [-1],   "Fireball Fright"), // all 4 areas
    "Slide":            course_meta(0x1b, [-1],   "Ol'Good Slides"),
    "End Cake Picture": course_meta(0x19, [-1],   "Ruined Plants' Domain"),

    "Bowser 1":         course_meta(0x11, [-1],   "The Nightdark Haven"),
    "Key 1":            course_meta(0x1e, [-1],   "The Nightdark Haven"),
    "Bowser 2":         course_meta(0x13, [-1],   "Bowser in the Melting Ice Tower"),
    "Key 2":            course_meta(0x21, [-1],   "Bowser in the Melting Ice Tower"),
    "Bowser 3":         course_meta(0x15, [-1],   "Bowser's Aerial Castle"),
    "Final Fight":      course_meta(0x22, [-1],   "Bowser's Aerial Castle"),
    
    "Metal Cap":         course_meta(0x1c, [-1],   "Skyover Maze Castle"), // MC
    "Wing Cap":          course_meta(0x1d, [-1],   "Valley of Dreams"), // WC
    "Vanish Cap":        course_meta(0x12, [-1],   "Diedol Factory"),
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

function remained_in_level_area_from_warp(name, area, node) {
    return in_level(name)
        && once(prev(level_id__mem) != course_infos[name]["value"]
            && warp_dest_area() == area
            && warp_dest_node() == node
            && warp_dest_level() == course_infos[name]["value"]) 
        && never(level_changed(except_when_entering=name)) // need an exception for the current level to stop the checkpoint hit from resetting
        && !object_is(nth_array_object(0), "mission star manager") // just to hide challenge indicator on star select
}

function in_intro_or_file_select() => any_of([0x21], a => music_id__mem == a) // 0x02 is used (devour realm music)

function common_in_file_check() => !in_intro_or_file_select() && level_id__mem != 1 && g_current_demo_input__mem == 0

dialog_id__addr = offsets["DIALOGUE ID"]
dialog_id__mem = word(dialog_id__addr)

g_menu_mode__addr = offsets["MENU MODE"]
g_menu_mode__mem = word(g_menu_mode__addr)

function in_pause_menu() => g_menu_mode__mem == 1

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
    milestone_meta("Bowser's Renovations",
        "Collect your first Ztar.",
        stars=1, points=0), // id=344836, badge="389923"),
    milestone_meta("Same Unlocks as Vanilla, Basically",
        "Collect 10 Ztars.",
        stars=10, points=3), // id=344837, badge="389924"),
    milestone_meta("Diminishing Star Power",
        "Collect 30 Ztars.",
        stars=30, points=5), // id=344838, badge="389925"),
    milestone_meta("Still a Long Road to Bowser",
        "Collect 50 Ztars.",
        stars=50, points=5), // id=344839, badge="389926"),
    milestone_meta("The Last Stand",
        "Collect 95 Ztars.",
        stars=95, points=10), // id=344840, badge="389927"),
    milestone_meta("Ztar Dream Catcher",
        "Collect all 170 Ztars.",
        stars=170, points=50), // id=344840, badge="389927"),
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
    title = "Negative Switcheroo",
    description = "Press the red, green, and blue !-switches.",
    points = 5,
    trigger = all_switches_trigger()
)

achievement(
    title = "Twilight Domination",
    description = "Collect the key in the first Bowser fight.",
    points = 10,
    trigger = in_level("Key 1")
        && collected_star_action_check()
)

achievement(
    title = "Pretend There's an Invisible Bomb at the End",
    description = "Collect the key in the second Bowser fight.",
    points = 10,
    trigger = in_level("Key 2")
        && collected_star_action_check()
)

achievement(
    title = "Big Bad's Gone, But Where's Peach?",
    description = "Collect the Normal Ending Ztar.",
    points = 10,
    trigger = in_level("Normal Ending")
        && collected_star_action_check(5)
)

achievement(
    title = "Negrowser's Last Laugh",
    description = "Collect the Negative Ending Ztar.",
    points = 10,
    trigger = in_level("Negative Space")
        && collected_star_action_check(6)
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
    course_stars_meta("Course 1", sum_star_bits(0x0f, range(0,6)), 5, "Start to a True Diorama Hack", id=344846, badge="389933"), 
    course_stars_meta("Course 2", sum_star_bits(0x0e, range(0,6)), 5, "Much Abandoned Oasis, Temple, Railways", id=344847, badge="389934"),
    course_stars_meta("Course 3", sum_star_bits(0x0d, range(0,6)), 5, "Not Much of a Coastline Now", id=344848, badge="389935"),
    course_stars_meta("Course 4", sum_star_bits(0x0c, range(0,6)), 5, "Cooler Cool Mountain", id=344849, badge="389936"),
    course_stars_meta("Course 5", sum_star_bits(0x13, range(0,6)), 5, "Better Than Luigi's", id=344850, badge="389937"),
    course_stars_meta("Course 6", sum_star_bits(0x12, range(0,6)), 5, "You Should Check Out ASAEE Course 2", id=344851, badge="389938"),
    course_stars_meta("Course 7", sum_star_bits(0x11, range(0,6)), 5, "Negative Draft Ascent", id=344852, badge="389939"),
    course_stars_meta("Course 8", sum_star_bits(0x10, range(0,6)), 5, "Anti-Entropy Excursion", id=344853, badge="389940"),
    course_stars_meta("Course 9", sum_star_bits(0x17, range(0,6)), 5, "Water Star Adventures", id=344854, badge="389941"),
    course_stars_meta("Course 10", sum_star_bits(0x16, range(0,6)), 10, "Darkwood Barracks", id=344855, badge="389942"),
    course_stars_meta("Course 11", sum_star_bits(0x15, range(0,6)), 10, "Whomp's Skyover Kingdom", id=344856, badge="389943"),
    course_stars_meta("Course 12", sum_star_bits(0x14, range(0,6)), 10, "Ztar's Infernal Prison", id=344857, badge="389944"),
    course_stars_meta("Course 13", sum_star_bits(0x1b, range(0,6)), 10, "The Damage Has Been Done", id=344858, badge="389945"),
    course_stars_meta("Course 14", sum_star_bits(0x1a, range(0,6)), 10, "Manufacturing Boom", id=344859, badge="389946"),
    course_stars_meta("Course 15", sum_star_bits(0x19, [0, 1, 2, 6]), 10, "Ztar Realm Invasion", id=344860, badge="389947"), // Split C15 into the different endings
    
    //course_stars_meta("Bowser 1",  sum_star_bits(0x18, range(0,0)), 2, "Same Colored Star", id=344861, badge="389948"), put B1 + aquarium (day) together
    course_stars_meta("Bowser 2",  sum_star_bits(0x1f, range(0,6)), 10, "New Tick Tock Tower", id=344862, badge="389949"),
    course_stars_meta("Bowser 3",  sum_star_bits(0x1e, range(0,4)), 10, "Topped Off Ztar Power", id=344863, badge="389950"),
    
    course_stars_meta("Metal Cap",  sum_star_bits(0x1c, range(0,4)), 5, "Cap Jamboree in the Castle", id=344864, badge="389951"),
    course_stars_meta("Vanish Cap", sum_star_bits(0x22, range(0,4)), 10, "Mario and the Evil Factory", id=344865, badge="389952"),
    course_stars_meta("Wing Cap",   sum_star_bits(0x23, range(0,4)), 5, "Dreaming of Ztar 172", id=344866, badge="389953"),
    
    course_stars_meta("Slide",      sum_star_bits(0x1d, range(0,6)), 5, "Retro Kingdom", id=344867, badge="389954"), // GS
    //course_stars_meta("Aquarium",   sum_star_bits(0x20, range(0,2)), 5, "The Crustiest Slide", id=344868, badge="389955"), // B1 Day
    course_stars_meta("Cloud Stage",sum_star_bits(0x21, range(0,6)), 10, "Ztars Blending In", id=344869, badge="389956"), // FF
    course_stars_meta("End Cake Picture", sum_star_bits(0x27, range(0, 5)), 5, "Bombed-On Battlefield, Wait, Wrong Game")
    
]
function course_star_achievements(ignore_ids=0) {
    for info in course_offsets {
        course = info["course"]
        bits = info["star bits"]["mem"]
        star_count = info["star bits"]["sum"]
        star_qty = dict_lookup({
            1: "the Ztar",
            2: "both Ztars",
            3: "all 3 Ztars",
            4: "all 4 Ztars",
            5: "all 5 Ztars",
            6: "all 6 Ztars",
            7: "all 7 Ztars"
        }, star_count)
        
        //if (course == "Bowser 2") {
        //    star_qty = format("{0} (that count towards total)", star_qty)
        //}
        
        if (course == "Course 15") {
            star_qty = "the first 3 Ztars + 100 coin Ztar"
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

course_star_achievements(ignore_ids=1)

function add_star_bits(star_bits) {
    return sum_of(star_bits, s => s["mem"])
}

overworld_stars = [
    sum_star_bits(0x0b, range(0, 6))
]

b1_stars = [
    sum_star_bits(0x18, range(0, 5)),
    sum_star_bits(0x20, range(0, 4))
]

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
    stars = overworld_stars, total=7,
    title = "Low-Hanging Ztars",
    description = "Collect all 7 overworld Ztars.",
    points = 5
)

star_collection_achievement(
    stars = b1_stars, total=11,
    title = "Timeless Temple",
    description = "Collect all 11 Ztars across both Nightdark Haven and Daylight Sanctuary",
    points = 10
)

cannon_bits = sum_cannon_bits([0x0c, 0x11, 0x16, 0x1d, 0x1e, 0x20])

star_collection_achievement(
    stars=[cannon_bits], total=6,
    title = "Negative Energy Cannoneer",
    description = "Open all 6 cannons.",
    points = 5
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

// like AMA, re-wire logic for single 1-ups
function collected_1up(type="stationary", text_ptr=0) {
    mushie_tally = []
    
    obj_name = format("{0} 1-up", type)
    
    for i in range(1,4) {
            obj_addr = object_nth_collided_object(mario_object(), i)
            
            coll_check = mario_collision_check(obj_addr, obj_name, i)
            if (text_ptr != 0) {
                coll_check = coll_check && object_1up_text_pointer(obj_addr) == text_ptr
            }
            
            // these 1-ups are tangible (recognized as colliding with mario) while they are sparkling, so need additional action check
            if (obj_name == "chasing 1-up" || obj_name == "activator 1-up") {
            // https://github.com/n64decomp/sm64/blob/master/src/game/behaviors/mushroom_1up.inc.c
                // even if you are on top of the 1-up while handstanding, this will still hit
                coll_check1 = coll_check && object_action(obj_addr) == 1
                //coll_check2 = coll_check && object_action(obj_addr) == 3&& object_timer(obj_addr) >= 37
                array_push(mushie_tally, repeated(1, coll_check1))
                //array_push(mushie_tally, repeated(t["count"], coll_check2))
                
                if (obj_name == "activator 1-up") {
                    coll_check2 = coll_check && object_action(obj_addr) == 2
                    array_push(mushie_tally, repeated(1, coll_check2))
                }
            }
            else {
                array_push(mushie_tally,
                    repeated(1, coll_check))   
            }
        }
        
    return tally(1, mushie_tally)
}

function mushie_meta(title="", description="", points=1, type="stationary", text_ptr=0, level_check=always_true(), id=0, badge="0") => {"title": title, "description": description, "points": points, "collect check": collected_1up(type, text_ptr), "level check": level_check, "id": id, "badge": badge}

mushie_infos = [
    mushie_meta("Another Mario Adventure With These Mushrooms", 
        "Course 1 - Collect a 1-up mushroom atop a hill.",
        1, "stationary", 0, in_level("Course 1")),    
    mushie_meta("Unjustifiable Search", 
        "Course 2 - Collect a cold 1-up mushroom. You bet it is possible!",
        2, "stationary", 0, in_level("Course 2")),    
    mushie_meta("Only Good if You're Paying Attention", 
        "Course 5 - Collect a 1-up mushroom outside.",
        1, "stationary", 0, in_level("Course 5")),    
    mushie_meta("You Tried", 
        "Course 6 - Collect a 1-up mushroom above the cannon bob-omb.",
        1, "stationary", 0, in_level("Course 6")),    
    mushie_meta("Not Fun in Speedruns", 
        "Course 8 - Collect a 1-up mushroom by a lavafall.",
        1, "stationary", 0, in_level("Course 8")),    
    mushie_meta("Yar Har Ho! Yo Ho Har!", 
        "Course 9 - Collect a 1-up mushroom on a ship.",
        1, "stationary", 0, in_level("Course 9")),    
    mushie_meta("Disastrous Quest Tree", 
        "Course 10 - Collect a 1-up mushroom somewhere you can't get back up.",
        1, "stationary", 0, in_level("Course 10")),    
    mushie_meta("You Won't Find Me!", 
        "Course 12 - Collect a 1-up mushroom on top of some lava.",
        2, "stationary", 0, in_level("Course 12")),    
    mushie_meta("The Ztar Should've Been Here", 
        "Course 14 - Collect a 1-up mushroom above a high-flying Ztar.",
        1, "stationary", 0, in_area("Course 14", 1)),    
    mushie_meta("Stupid Ballz", 
        "Course 14 - Collect a 1-up mushroom on an unused slope in the ball factory.",
        1, "stationary", 0, in_area("Course 14", 2)),
        
    mushie_meta("Shower is Mine", 
        "Mario's House - Collect a 1-up mushroom in a bathtub.",
        1, "stationary", 0, in_level("Castle Courtyard")),       
    mushie_meta("Dime a Dozen", 
        "Fireball Fright - Collect a 1-up mushroom on a hill top (cannon optional).",
        1, "stationary", 0, in_level("Cloud Stage")),       
    mushie_meta("I Wanna See What I'm Doing!", 
        "Diedol Factory - Collect a 1-up mushroom where the camera is bad.",
        1, "stationary", 0, in_level("Vanish Cap")),        
    mushie_meta("Nobody I Know", 
        "The Daylight Sanctuary - Collect a 1-up mushroom where a corresponding nighttime Ztar is.",
        1, "stationary", 0, in_level("Aquarium")),          
    mushie_meta("Easier With a Different Camera", 
        "Bowser 1 Fight - Collect a 1-up mushroom on a different path from the key.",
        1, "stationary", 0, in_level("Key 1")),          
    mushie_meta("No Stone Unturned", 
        "Bowser's Aerial Castle - Collect a 1-up mushroom inside a breakable crate.",
        1, "stationary", 0, in_level("Bowser 3")),   
]

function mushie_cheevs() {
    for dat in mushie_infos {

    achievement(
        title = dat["title"],
        description = dat["description"],
        points = dat["points"],
        trigger = never(screen_changed()) && dat["level check"] && dat["collect check"]
        )
    }
}

mushie_cheevs()

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

c1_race = nth_array_object(66)

// Side challenge time... (remember, collected_star_action_check's star ID is 1-indexed)
achievement(
    title = "About Eight Times Faster Than the Original",
    description = "Win the Koopa race in Course 1 in under 11 seconds.",
    points = 5,
    trigger = remained_in_level("Course 1", hit=0)
        && hud_timer_shown() != 0
        && hud_timer() < int_seconds_to_frames(11)
        && object_koopa_race_started_and_won(c1_race, trig=1)
)

leaderboard(
    title = "Ztar Meadows Race",
    description = "Win the race with Koopa the Quick in Course 1 as fast as possible.",
    start = in_level("Course 1") && object_koopa_race_started_and_won(c1_race, trig=0),
    cancel=always_false(),
    submit=always_true(),
    value=hud_timer()*2,
    
    format="FRAMES",
    lower_is_better=true,
    id = 77226
)

achievement(
    title = "The Long Way Or...",
    description = "Collect the Ztar 'Over the Railways' in Course 2 in 3 A presses or under.",
    points = 3,
    trigger = never(level_changed())
        && sublevel_id__mem < 3
        && ((in_level("Course 2") && (trigger_when(collected_star_action_check(2))) && unless(object_is(nth_array_object(0), "mission star manager")) && disable_when(repeated(4, just_increased(controller_a_button()))))
        || (unless(object_is(nth_array_object(0), "mission star manager")) && measured(repeated(3, just_increased(controller_a_button())), when=in_level("Course 2") && sublevel_id__mem < 3) && impossible_condition()))
)

achievement(
    title = "Silver Stars of Wisdom",
    description = "Collect the Ztar 'The Hot Lava Pit' in Course 2 without taking damage.",
    points = 5,
    trigger = remained_in_level("Course 2", hit=1)
        && sublevel_id__mem == 1
        && never(just_increased(hp_decrement()))
        && never(any_of(burning_actions, a => mario_action_changed_to(a)))
        && trigger_when(collected_star_action_check(3))
)

achievement(
    title = "Nobody Got Time to Backtrack",
    description = "Collect the Ztar 'Panels in the House' in Course 2 without getting a metal cap.",
    points = 5,
    trigger = remained_in_level("Course 2", hit=1)
        && sublevel_id__mem == 2
        && never(just_increased(wearing_metal_cap()))
        && trigger_when(collected_star_action_check(5))
)

c3_secrets = array_map([13, 14, 15, 16, 17], a => nth_array_object(a))

achievement(
    title = "This Makes More Sense in the Original",
    description = "Collect all 5 secrets in Course 3 while in the air from cannon shots (not bonking).",
    points = 4,
    trigger = remained_in_level("Course 3", hit=0)
        && measured(collided_with_object("secret", 5, extra_logic=mario_action_was("shot from cannon")))
)

achievement(
    title = "First of Many Useless Cannons",
    description = "Collect the Ztar 'Shoot Up the Sky' in Course 3 without using a cannon.",
    points = 3,
    trigger = remained_in_level("Course 3", hit=1)
        && never(mario_action_changed_to("in cannon"))
        && trigger_when(collected_star_action_check(6))
)

achievement(
    title = "Cold Snapped Mountain",
    description = "Collect the Ztar 'Another Mountain Top' in Course 4 without getting a metal cap.",
    points = 4,
    trigger = remained_in_level("Course 4", hit=1)
        && sublevel_id__mem != 2
        && never(just_increased(wearing_metal_cap()))
        && trigger_when(collected_star_action_check(4))
)

achievement(
    title = "Penguin Detour in the Snow",
    description = "Collect all 5 secrets in Course 4 while holding the baby penguin. Don't take it outside.",
    points = 5,
    trigger = remained_in_level("Course 4", hit=0)
        && measured(collided_with_object("secret", 5, extra_logic=object_is(held_object(), "baby penguin")))
)

achievement(
    title = "Nonmetal-Head Mario Can Move",
    description = "Collect the Ztar 'King Boo Revenge' in Course 5 without getting a metal cap.",
    points = 5,
    trigger = remained_in_level("Course 5", hit=1)
        && sublevel_id__mem == 1
        && never(just_increased(wearing_metal_cap()))
        && trigger_when(collected_star_action_check(6))
)

achievement(
    title = "Other Secret of the House",
    description = "Collect the Ztar 'Shoot to the Other House Side' in Course 6 without using a cannon.",
    points = 5,
    trigger = remained_in_level("Course 6", hit=1)
        && never(mario_action_changed_to("in cannon"))
        && trigger_when(collected_star_action_check(4))
)

achievement(
    title = "Actually No Wiggle Room",
    description = "Collect the Ztar 'When a Wiggler Attacks a Town...' in Course 6 without pressing the A button (star select/text OK).",
    points = 10,
    trigger = remained_in_level("Course 6", hit=1)
        && mission__mem == 5
        && never(!object_is(nth_array_object(0), "mission star manager") && !mario_action_is("text / cutscene") && just_increased(controller_a_button()))
        && trigger_when(collected_star_action_check(5))
)

achievement(
    title = "Still a Cr-EZ Fight",
    description = "Defeat the Big Bully in Course 7 without taking damage or pressing the A button after starting the fight (boss music).",
    points = 5,
    trigger = remained_in_level("Course 7", hit=1)
        && ((disable_when(once(mario_action_is("airborne spawn") || once(mario_action_is("exit warp pipe"))), until=(just_changed_to(music_id__mem, 22))) && never(just_increased(hp_decrement()))
        && never(any_of(burning_actions, a => mario_action_changed_to(a)))
        && never(warp_dest_type() == 0 && just_increased(controller_a_button()))
        && trigger_when(object_changed_to(g_cutscene_focus__mem, "spawned star")
        && object_star_mission(g_cutscene_focus__mem) == 3)) || (always_false()))
)

achievement(
    title = "Blargg's Lava House",
    description = "Collect the Ztar 'Hot Lava Cavern' in Course 7 without getting a metal cap.",
    points = 5,
    trigger = remained_in_level("Course 7", hit=1)
        && never(just_increased(wearing_metal_cap()))
        && trigger_when(collected_star_action_check(1))
)

achievement(
    title = "Vanish Cap Still Sucks",
    description = "Collect the Ztar 'Behind the Bars' in Course 7 without entering Course 3.",
    points = 3,
    trigger = disable_when(once(in_level("Course 3")), until=just_changed_to(music_id__mem, 4))
        && in_level("Course 7")
        && collected_star_action_check(6)
)

achievement(
    title = "Hidden Behind Wind",
    description = "Collect the Ztar 'Hidden Behind the Mountain' in Course 7 without riding the wind.",
    points = 3,
    trigger = remained_in_level("Course 7", hit=1)
        && never(mario_action_changed_to("vertical wind"))
        && trigger_when(collected_star_action_check(5))
)

achievement(
    title="Cold Rocky Secret Hunt",
    description = "Collect the Ztar 'Touch Rocks in the Lavafall' in Course 8 without getting a wing cap.",
    points = 10,
    trigger = remained_in_level("Course 8", hit=1)
        && sublevel_id__mem == 2
        && never(just_increased(wearing_wing_cap()))
        && trigger_when(collected_star_action_check(4))
)

achievement(
    title = "How to Get Up Here?",
    description = "Get on top of the pillars in the hot side of Course 8. No, the 1-up is not here.",
    points = 5,
    trigger = in_area("Course 8", 1)
        && airborne() == 0
        && pos_y() > 3000.0 && pos_y() < 3500.0
)

achievement(
    title = "Way Too Small Level to Use Cannon",
    description = "Collect the Ztar 'Behind the Vines' in Course 9, starting from the main entrance, without using a cannon.",
    points = 4,
    trigger = remained_in_level_area_from_warp("Course 9", 1, 0x0A)
        && never(mario_action_changed_to("in cannon"))
        && trigger_when(collected_star_action_check(6))
)

function luke_saward_door() {
    return in_area("Course 9", 2)
        && in_3d_box(2500.0, 3000.0, -100.0, 100.0, -4000.0, -4500.0)
        && mario_action_changed_to("pulling door")
}

achievement(
    title = "No, He Did Not Get a 1:39",
    description = "Enter the Luke Saward Door in Course 9.",
    points = 1,
    trigger = luke_saward_door()
)

leaderboard(
    title = "Luke Saward%",
    description = "Starting from a new file, enter the Luke Saward door in Course 9 as fast as possible.",
    start = new_file_hit() && luke_saward_door(),
    cancel = always_false(),
    submit = always_true(),
    value = num_vblanks__mem,
    
    format="FRAMES",
    lower_is_better = true,
    id = 77227
)

achievement(
    title = "Sick Tree Moves",
    description = "Collect the Ztar 'Inside the Big Tree' in Course 10 in 2 A presses or under.",
    points = 4,
    trigger = never(level_changed())
        && ((in_level("Course 10") && (trigger_when(collected_star_action_check(2))) && unless(object_is(nth_array_object(0), "mission star manager")) && disable_when(repeated(3, just_increased(controller_a_button()))))
        || (unless(object_is(nth_array_object(0), "mission star manager")) && measured(repeated(2, just_increased(controller_a_button())), when=in_level("Course 10")) && impossible_condition()))
)

achievement(
    title = "Explore Outside the House",
    description = "Collect the Ztar 'Explore the Blue House' in Course 10 without pressing the blue switch or getting a wing cap.",
    points = 5,
    trigger = remained_in_level("Course 10", hit=1)
        && sublevel_id__mem == 1
        && never(just_increased(wearing_wing_cap()))
        && never(just_changed_to(mop_switch__mem, 2))
        && trigger_when(collected_star_action_check(1))
)

achievement(
    title = "Skyhigh Coin Diamonds",
    description = "Collect all 12 switch blue coins in Course 11.",
    points = 5,
    trigger = never(level_changed())
            && measured(collided_with_object("blue coin for block", 12), when=in_level("Course 11"))
)

achievement(
    title = "Don't Need to Jump to Flip-Swap",
    description = "Collect the Ztar 'Explore the House' in Course 11 without pressing the A button.",
    points = 10,
    trigger = remained_in_level("Course 11", hit=1)
        && sublevel_id__mem == 2
        && never(warp_dest_type() == 0 && just_increased(controller_a_button()))
        && trigger_when(collected_star_action_check(5))
)

achievement(
    title = "Zanctuary Remnant",
    description = "Collect the Ztar 'Secrets of the Ztar Zanctuary' in Course 12 without standing on a red star.",
    points = 5,
    trigger = remained_in_level("Course 12", hit=1)
        && sublevel_id__mem == 1
        && mission__mem > 1
        && never(object_changed_to(stood_on_object(), "red star"))
        && trigger_when(collected_star_action_check(2))
)

achievement(
    title = "Lock On to Me!",
    description = "Collect the Ztar 'Dorrie Ride and Eye Fight' in Course 12 without taking damage in the fight. (Must get Ztar)",
    points = 10,
    trigger = remained_in_level_area("Course 12", 2)
        && never(just_increased(hp_decrement()))
        && never(any_of(burning_actions, a => mario_action_changed_to(a)))
        && trigger_when(collected_star_action_check(4))
)

achievement(
    title = "Ztar's Nuclear Capital",
    description = "Collect the Ztar 'The Burning Redhead Hill' in Course 12 without riding a Koopa Shell or using a metal cap.",
    points = 5,
    trigger = remained_in_level("Course 12", hit=1)
        && mission__mem > 1
        && sublevel_id__mem == 1
        && never(object_changed_to(ridden_object(), "koopa shell"))
        && never(just_increased(wearing_metal_cap()))
        && trigger_when(collected_star_action_check(5))
)

achievement(
    title = "Lava Evader",
    description = "Collect the Ztar 'The Lava-Inonded Slides' in Course 12 without taking damage.",
    points = 5,
    trigger = remained_in_level("Course 12", hit=1)
        && __ornext(sublevel_id__mem == 4 || sublevel_id__mem == 5)
        && never(just_increased(hp_decrement()))
        && never(any_of(burning_actions, a => mario_action_changed_to(a)))
        && trigger_when(collected_star_action_check(6))
)

achievement(
    title = "Big Boss on Even Ground",
    description = "Defeat King Bob-omb in Course 13 without taking damage or pressing the A button in the fight area. (Re-enter to retry)",
    points = 5,
    trigger = remained_in_level_area("Course 13", 2)
        && never(just_increased(hp_decrement()))
        && never(any_of(burning_actions, a => mario_action_changed_to(a)))
        && never(warp_dest_type() == 0 && !mario_action_is("text / cutscene") && just_increased(controller_a_button()))
        && trigger_when(just_changed_to(dialog_id__mem, 116))
)

achievement(
    title = "Color Blocks Detour",
    description = "Collect the Ztar 'Color Blocks and Toxic Waste' in Course 13 from any entrance, without pressing the blue switch.",
    points = 5,
    trigger = remained_in_level("Course 13", hit=1)
        && sublevel_id__mem == 1
        && never(just_changed_to(mop_switch__mem, 2))
        && trigger_when(collected_star_action_check(5))
)

achievement(
    title = "Shiny Metal Speedrun Madness",
    description = "Collect the Ztar 'Wallkicks to the Shiny Top' in Course 14 (select star 5/6) while wearing a metal cap. Can you do it blink-less?",
    points = 10,
    trigger = in_area("Course 14", 1)
        && prev(wearing_metal_cap()) != 0
        && trigger_when(collected_star_action_check(4))
)

achievement(
    title = "Hot Desertic Collect",
    description = "Collect all 8 red coins and the Ztar in Course 14 without taking damage.",
    points = 5,
    trigger = remained_in_level("Course 14", hit=1)
        && never(just_increased(hp_decrement()))
        && never(any_of(burning_actions, a => mario_action_changed_to(a)))
        && trigger_when(repeated(8, got_red_coin()))
        && trigger_when(collected_star_action_check(5))
)

achievement(
    title = "The Dropper: Negative Edition",
    description = "Collect the Ztar 'Blue Tower Lava Fall' in Course 15 without taking damage.",
    points = 5,
    trigger = remained_in_level("Course 15", hit=1)
        && sublevel_id__mem == 5
        && never(just_increased(hp_decrement()))
        && never(any_of(burning_actions, a => mario_action_changed_to(a)))
        && trigger_when(collected_star_action_check(2))
)

achievement(
    title = "Blazing Lava Bath",
    description = "Collect the Ztar beyond the lava spiral and pillars in Bowser in the Melting Ice Tower without getting a metal cap.",
    points = 5,
    trigger = remained_in_level("Bowser 2", hit=1)
        && sublevel_id__mem == 1
        && never(just_increased(wearing_metal_cap()))
        && trigger_when(collected_star_action_check(4))
)

achievement(
    title = "Command Disregard",
    description = "Collect the Ztar on the left path of Bowser's Aerial Castle without riding a Koopa Shell or getting a metal cap.",
    points = 5,
    trigger = remained_in_level("Bowser 3", hit=1)
        && sublevel_id__mem == 2
        && byte(0x400037) != 0x7B // no negative ending
        && never(object_changed_to(ridden_object(), "koopa shell"))
        && never(just_increased(wearing_metal_cap()))
        && trigger_when(collected_star_action_check(3))
)

achievement(
    title = "This is Still Better Than Doing Bowser Throws",
    description = "Defeat the final Bowser without taking damage.",
    points = 25,
    trigger = remained_in_level("Final Fight", hit=1)
        && object_is(nth_array_object(1), "final Bowser")
        && never(just_increased(hp_decrement()))
        && never(any_of(burning_actions, a => mario_action_changed_to(a)))
        && trigger_when(just_changed_to(object_action(nth_array_object(1)), 4))
        // action 4 = bowser ded
)

achievement(
    title = "One Clean Slide Down",
    description = "Collect the Ztar on the mini slide underground in Ol' Good Slides without pressing the A button or taking damage.",
    points = 5,
    trigger = remained_in_level("Slide", hit=1)
        && never(warp_dest_type() == 0 && just_increased(controller_a_button()))
        && never(just_increased(hp_decrement()))
        && never(any_of(burning_actions, a => mario_action_changed_to(a)))
        && trigger_when(collected_star_action_check(7))
)

achievement(
    title = "Where's the Shell? Not Important",
    description = "Collect the Ztar on the sandy spiral in Fireball Fright without riding a Koopa Shell or taking damage.",
    points = 5,
    trigger = remained_in_level("Cloud Stage", hit=1)
        && sublevel_id__mem == 1
        && never(object_changed_to(ridden_object(), "koopa shell"))
        && never(just_increased(hp_decrement()))
        && never(any_of(burning_actions, a => mario_action_changed_to(a)))
        && trigger_when(collected_star_action_check(3))
)

achievement(
    title = "Yeah, Who Needs Assist?",
    description = "Collect the panel Ztar in Fireball Fright without standing on the purple switch or using the warp at the bottom.",
    points = 5,
    trigger = remained_in_level_area("Cloud Stage", 2)
        && never(object_changed_to(stood_on_object(), "purple box switch"))
        && never(just_used_teleporter(0x0c))
        && trigger_when(collected_star_action_check(5))
)

rp_race = nth_array_object(16)

achievement(
    title = "Race Like Old Times",
    description = "Win the Koopa race in Ruined Plains' Domain in under 15 seconds.",
    points = 5,
    trigger = remained_in_level("End Cake Picture", hit=0)
        && hud_timer_shown() != 0
        && hud_timer() < int_seconds_to_frames(15)
        && object_koopa_race_started_and_won(rp_race, trig=1)
)

leaderboard(
    title = "Ruined Plains' Domain Race",
    description = "Win the race with Koopa the Quick in Ruined Plains' Domain as fast as possible.",
    start = in_level("End Cake Picture") && object_koopa_race_started_and_won(rp_race, trig=0),
    cancel=always_false(),
    submit=always_true(),
    value=hud_timer()*2,
    
    format="FRAMES",
    lower_is_better=true,
    id = 77228
)

achievement(
    title = "ABC Across the Lost Cannons",
    description = "Collect the secrets Ztar in Ruined Plains' Domain without pressing the A button.",
    points = 10,
    trigger = remained_in_level("End Cake Picture", hit=1)
        && never(warp_dest_type() == 0 && just_increased(controller_a_button()))
        && trigger_when(collected_star_action_check(3))
)

achievement(
    title = "Gates of Hell",
    description = "Collect the Ztar between the 2 gates in Ruined Plains' Domain without getting a metal cap.",
    points = 5,
    trigger = remained_in_level("End Cake Picture", hit=1)
        && never(just_increased(wearing_metal_cap()))
        && trigger_when(collected_star_action_check(5))
)

achievement(
    title = "Avoid the Green Lavabounces",
    description = "Collect the Ztar up the Fake Slide in Skyover Maze Castle without getting a metal cap or taking damage.",
    points = 5,
    trigger = remained_in_level("Metal Cap", hit=1)
        && never(just_increased(wearing_metal_cap()))
        && never(just_increased(hp_decrement()))
        && never(any_of(burning_actions, a => mario_action_changed_to(a)))
        && trigger_when(collected_star_action_check(4))
)

achievement(
    title = "Capless Ceiling",
    description = "Collect the Ztar above lava pillars and overhangs in Skyover Maze Castle without getting a metal or wing cap.",
    points = 5,
    trigger = remained_in_level("Metal Cap", hit=1)
        && never(just_increased(wearing_metal_cap()))
        && never(just_increased(wearing_wing_cap()))
        && trigger_when(collected_star_action_check(2))
)

achievement(
    title = "Jumping Against Wind",
    description = "Collect the Ztar across windy bridges in Valley of Dreams without getting a wing cap.",
    points = 4,
    trigger = remained_in_level("Wing Cap", hit=1)
        && sublevel_id__mem == 1
        && never(just_increased(wearing_wing_cap()))
        && trigger_when(collected_star_action_check(3))
)

achievement(
    title = "Wingless Odyssey",
    description = "Collect the panel Ztar in Valley of Dreams without getting a wing cap.",
    points = 5,
    trigger = remained_in_level("Wing Cap", hit=1)
        && sublevel_id__mem == 1
        && never(just_increased(wearing_wing_cap()))
        && trigger_when(collected_star_action_check(1))
)

achievement(
    title = "Can't See the Switch",
    description = "Collect the Ztar inside wire meshes in Diedol Factory without pressing the blue switch.",
    points = 10,
    trigger = remained_in_level("Vanish Cap", hit=1)
        && sublevel_id__mem == 1
        && never(just_changed_to(mop_switch__mem, 2))
        && trigger_when(collected_star_action_check(3))
)

state_mario_x = float(0x78003C)
state_mario_y = float(0x780040)
state_mario_z = float(0x780044)
state_mario_timer = dword(0x444FE4) // 7839cc - 33e9e8, static marioobj location

achievement(
    title = "Yeah, Who Needs It?",
    description = "BLJ in the Normal Ending to read a secret sign behind the upstairs door.",
    points = 1,
    trigger = in_level("Normal Ending")
        && just_changed_from(dialog_id__mem, 165)
)

achievement(
    title = "The Penguin Race Was Removed For This",
    description = "Collect the Negative Ending Ztar without loading an in-game save state. (Die to retry)",
    points = 10,
    trigger = in_level("Negative Space")
        && once(__ornext(mario_action_is("spawn spin landing") || mario_action_is("death exit freefall")))
        && never(g_menu_mode__mem != 1
            && prev(g_menu_mode__mem) != 1
            && object_timer(mario_object()) == state_mario_timer
            && controller_l_button() != 0)
        && trigger_when(collected_star_action_check(6))
)

// please test me...



c7_bully = nth_array_object(62)




// RP

general_level_dict = {
    0x0000: "outside Peach's Castle taken over by Bowser", // OW1
    0x1001: "outside Peach's Castle taken over by Bowser", // OW1
    0x0601: "in the castle lobby", // OW2
    0x0602: "upstairs in the castle", // OW2
    0x0603: "in the castle basement", // OW2
    0x1A01: "rummaging the expanded courtyard", // OW3
    0x1A02: "inside his house", // OW3
    
    0x0901: format("frolicking through a heavily down-scaled {0}", course_infos["Course 1"]["full name"]),
    0x1801: format("beating the heat in {0}", course_infos["Course 2"]["full name"]),
    0x1802: format("exploring the temple in {0}", course_infos["Course 2"]["full name"]),
    0x1803: format("exploring the cold temple in {0}", course_infos["Course 2"]["full name"]),
    0x0C01: format("on a relaxing platforming adventure in {0}", course_infos["Course 3"]["full name"]),
    0x0501: format("visiting the penguins in {0}", course_infos["Course 4"]["full name"]),
    0x0502: format("excavating the caverns in {0}", course_infos["Course 4"]["full name"]),
    0x0503: format("ascending the cold mountain in {0}", course_infos["Course 4"]["full name"]),
    0x0401: format("outside the {0}", course_infos["Course 5"]["full name"]),
    0x0402: format("uncovering secrets inside the {0}", course_infos["Course 5"]["full name"]),
    0x0701: format("keeping his head above water in {0}", course_infos["Course 6"]["full name"]),
    0x0702: format("opening the cannon in {0}", course_infos["Course 6"]["full name"]),
    0x1601: format("climbing {0}", course_infos["Course 7"]["full name"]),
    0x0801: format("on a hot-footed adventure in {0}", course_infos["Course 8"]["full name"]),
    0x0802: format("freezing {0} against Eyerok's will", course_infos["Course 8"]["full name"]),
    0x0803: format("on a hot-footed adventure in {0}", course_infos["Course 8"]["full name"]),
    0x0804: format("freezing {0} against Eyerok's will", course_infos["Course 8"]["full name"]),
    0x1701: format("taking a quick dive in {0}", course_infos["Course 9"]["full name"]),
    0x1702: format("testing his knowledge in {0}", course_infos["Course 9"]["full name"]),
    0x1703: format("plundering the ship in {0}", course_infos["Course 9"]["full name"]),
    0x0A01: format("tip-toeing around the {0}", course_infos["Course 10"]["full name"]),
    0x0A02: format("scampering up a big tree in {0}", course_infos["Course 10"]["full name"]),
    0x0A03: format("flying through Piranha Plants in in {0}", course_infos["Course 10"]["full name"]),
    0x0B01: format("not looking down in {0}", course_infos["Course 11"]["full name"]),
    0x0B02: format("jumping across flipswap panels in {0}", course_infos["Course 11"]["full name"]),
    0x0B03: format("outside castle's secret exit in {0}", course_infos["Course 11"]["full name"]),
    0x2401: format("taking risks over lava in {0}", course_infos["Course 12"]["full name"]),
    0x2402: format("fighting an excellent eyeball in {0}", course_infos["Course 12"]["full name"]),
    0x2403: format("maneuvering around a hot crater in {0}", course_infos["Course 12"]["full name"]),
    0x2404: format("sliding around {0}", course_infos["Course 12"]["full name"]),
    0x2405: format("sliding around {0}", course_infos["Course 12"]["full name"]),
    0x0D01: format("staying healthy in the {0}", course_infos["Course 13"]["full name"]),
    0x0D02: format("fighting the big guy in {0}", course_infos["Course 13"]["full name"]),
    0x0D03: format("going across the dream world in {0}", course_infos["Course 13"]["full name"]),
    0x0E01: format("shutting down the {0}", course_infos["Course 14"]["full name"]),
    0x0E02: format("ascending the ballz factory in {0}", course_infos["Course 14"]["full name"]),
    0x0E03: format("dancing with the Heave-Ho's {0}", course_infos["Course 14"]["full name"]),
    0x0F01: format("conquering Ztar's Dream", course_infos["Course 15"]["full name"]),
    0x0F02: format("conquering Ztar's Dream", course_infos["Course 15"]["full name"]),
    0x0F03: format("conquering Ztar's Dream", course_infos["Course 15"]["full name"]),
    0x0F04: format("conquering Ztar's Dream", course_infos["Course 15"]["full name"]),
    0x0F05: format("finding lost Ztars in {0}", course_infos["Course 15"]["full name"]),
    0x0F06: format("chasing Negrowser in the negative ending", course_infos["Course 15"]["full name"]),
    0x0F07: format("hearing bad news in the normal ending", course_infos["Course 15"]["full name"]),
    
    0x1C01: format("running a cap triathlon in {0}", course_infos["Metal Cap"]["full name"]),
    0x1C02: format("bumping into invisible walls in {0}", course_infos["Metal Cap"]["full name"]),
    0x1D01: format("flying through the {0}", course_infos["Wing Cap"]["full name"]),
    0x1D02: format("climbing a polluted tower in {0}", course_infos["Wing Cap"]["full name"]),
    0x1201: format("vanishing through {0}", course_infos["Vanish Cap"]["full name"]),
    0x1202: format("hopping over fake towers in {0}", course_infos["Vanish Cap"]["full name"]),
    0x1203: format("collecting dark red coins in {0}", course_infos["Vanish Cap"]["full name"]),
    
    0x1B01: format("admiring the retro landscape in in {0}", course_infos["Slide"]["full name"]),
    0x1401: format("gathering Ztars before nighttime {0}", course_infos["Aquarium"]["full name"]),
    0x1F01: format("dodging flames in {0}", course_infos["Cloud Stage"]["full name"]),
    0x1F02: format("pressing lost panels in {0}", course_infos["Cloud Stage"]["full name"]),
    0x1F03: format("pushing through a fiery pipe in {0}", course_infos["Cloud Stage"]["full name"]),
    0x1F04: format("gathering secret secrets in {0}", course_infos["Cloud Stage"]["full name"]),
    0x1901: format("going through a ruined battlefield in {0}", course_infos["End Cake Picture"]["full name"]),

    0x1101: format("gathering Ztars past bedtime in {0}", course_infos["Bowser 1"]["full name"]),
    0x1E01: format("fighting block master Bowser in {0}", course_infos["Key 1"]["full name"]),
    0x1301: format("taking a tick-tock traumatic climb in {0}", course_infos["Bowser 2"]["full name"]),
    0x1302: format("finding warmth indoors in {0}", course_infos["Bowser 2"]["full name"]),
    0x2101: format("luring Bowser in {0}", course_infos["Key 2"]["full name"]),
    0x1501: format("outside {0}", course_infos["Bowser 3"]["full name"]),
    0x1502: format("storming the interior of {0}", course_infos["Bowser 3"]["full name"]),
    0x1503: format("taking risky lavabounces in {0}", course_infos["Bowser 3"]["full name"]),
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

rich_presence_conditional_display(in_title_screen(), "Getting ready for a Ztar adventure. (Title Screen)")
rich_presence_conditional_display(in_file_select(), 
    "Getting ready for a Ztar adventure. (File Select)")
rich_presence_conditional_display(
    new_file_hit() && level_id__mem != 1 && (music_id__mem != 0x21 || effective_mario_object() != 0), // both are false on file select, including after game over
      "[New File] {6}Mario-{2} is {0} with {1}★ [🔴{3}] [🟢{4}] [🔵{5}]", level__lookup, stars__value, file__lookup, 
        rich_presence_lookup("Switch", pressed_switch__mem("red"), {1:"▣"}, "▢"),
        rich_presence_lookup("Switch", pressed_switch__mem("green"), {1:"▣"}, "▢"),
        rich_presence_lookup("Switch", pressed_switch__mem("blue"), {1:"▣"}, "▢"),
        rich_presence_lookup("Desat", bit(0, offsets["ZAR KILLSWITCH"]), {1:"[Negative Ending] "}, "")
    )
rich_presence_conditional_display(
    level_id__mem != 1 && (music_id__mem != 0x21 || effective_mario_object() != 0), // both are false on file select, including after game over
      "{6}Mario-{2} is {0} with {1}★ [🔴{3}] [🟢{4}] [🔵{5}]", level__lookup, stars__value, file__lookup, 
        rich_presence_lookup("Switch", pressed_switch__mem("red"), {1:"▣"}, "▢"),
        rich_presence_lookup("Switch", pressed_switch__mem("green"), {1:"▣"}, "▢"),
        rich_presence_lookup("Switch", pressed_switch__mem("blue"), {1:"▣"}, "▢"),
        rich_presence_lookup("Desat", bit(0, offsets["ZAR KILLSWITCH"]), {1:"[Negative Ending] "}, "")
    )
rich_presence_display("On a large small Ztar adventure.")