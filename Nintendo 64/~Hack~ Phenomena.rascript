// ~Hack~ Phenomena
// #ID = 25309
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
    "TITLE SCREEN GEO":     0x104640,

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
    "file manager":         0x8008FD58,
    
    "purple box switch":    0x801072AC,
    
    "koopa shell":          0x80107D3C,
    
    "mission star manager": 0x80108E48,
    
    "stationary 1-up":      0x80109E7C,
    "activator 1-up":       0x80109EEC,
    "impartial 1-up":       0x80109DDC,
    "running away 1-up":    0x80109E10,
    
    "koopa flag checkpoint": 0x8010A3D0,
    
    "metal cap":            0x80109BD8,
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
    "slide kick":                  0x018008AA,
    "air kick":                    0x018008AC,
    "triple jump":                 0x01000882,
    "wall kick":                   0x03000886, // also pole jump
    "long jump":                   0x03000888, // slow or faste
    "shot from cannon":            0x00880898,
    "air sitting":                 0x0300088E,
    
    "crouch sliding":              0x04808459,
    
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
    "Overworld 1":          course_meta(0x10, [-1],   "The first overworld"), // Castle Grounds (beware)
    "Overworld 2":          course_meta(0x06, [-1],   "The second overworld"),
    "Overworld 3":          course_meta(0x1A, [-1],   "The third overworld"),
    "Overworld 4":          course_meta(0x11, [-1],   "the kaizo overworld"), // same as B1
    
    "Inside Castle":        course_meta(0x06, [-1], "Overworld 2"),
    "Remnant Ending":       course_meta(0x06, [2],  "Remnant Ending"),
    "Scepter End":          course_meta(0x06, [3],  "Scepter End"),
    // Area 4: Warp pipe deaths
    "Castle Courtyard":      course_meta(0x1a, [-1], "Overworld 3"), // Castle Courtyard
    // OW3 is just star get/death areas, or shortcuts to gs/bs, or ow cannon
    
    "Course 1":         course_meta(0x09, [-1],   "Abandoned Jungle Village"),
    "Course 2":         course_meta(0x18, [-1],   "Autumnal Architecture"),
    "Course 3":         course_meta(0x0c, [-1],   "Sandy City"),
    "Course 4":         course_meta(0x05, [-1],   "Swampy Spring"),
    "Course 5":         course_meta(0x04, [-1],   "Lava Situation"),
    "Course 6":         course_meta(0x07, [-1],   "System of a Rebuilt Town"),
    "Course 7":         course_meta(0x16, [-1],   "Ice Crystal Tower"),
    "Course 8":         course_meta(0x08, [-1],   "Glorious Summer Waterfall"),
    "Course 9":         course_meta(0x17, [-1],   "Zeta Sector"),
    "Course 10":        course_meta(0x0a, [-1],   "Olympian Summit"),
    "Course 11":        course_meta(0x0b, [-1],   "Flamedune Galaxy"),
    "Course 12":        course_meta(0x24, [-1],   "Experimental Generation"),
    "Course 13":        course_meta(0x0d, [-1],   "Zone of Happiness"),
    
    "Aquarium":         course_meta(0x14, [-1],   "The Secret Sky Castle"), // Aquarium
    "Slide":            course_meta(0x1b, [-1],   "Secret Slides"),
    
    "Bowser 3":         course_meta(0x15, [-1],   "Corrupted Castle"),
    "Final Fight":      course_meta(0x22, [-1],   "Corrupted Castle"),
    "End Cake Picture": course_meta(0x19, [-1],   "The Ending Picture"),
    
    "Metal Cap":         course_meta(0x1c, [-1],   "the metal cap level"), // MC
    "Wing Cap":          course_meta(0x1d, [-1],   "the wing cap level"), // WC
    "Vanish Cap":        course_meta(0x12, [-1],   "the vanish cap level"),
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
    milestone_meta("A One-Star Tour",
        "Collect your first star.",
        stars=1, points=0, id=342808, badge="386973"),
    milestone_meta("To the Remade Riverside",
        "Collect FIFTEEN stars.",
        stars=15, points=5, id=342809, badge="386974"),
    milestone_meta("Small Shortcut, Small Progress",
        "Collect 35 stars.",
        stars=35, points=10, id=342810, badge="386975"),
    milestone_meta("It Shouldn't Be Too Difficult...",
        "Collect 50 stars.",
        stars=50, points=10, id=342811, badge="386976"),
    milestone_meta("100 Percented",
        "Collect all 120 stars.",
        stars=120, points=50, id=342812, badge="386977"),
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

hack_switches = ["red", "blue", "green"] // all 4 used

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
    title = "Good Ol' Switcheroo",
    description = "Press the red, green, and blue !-switches.",
    points = 5,
    trigger = all_switches_trigger(),
    id=342813,
    badge="386978"
)

achievement(
    title="It's Ogre Again",
    description="Reach the ending screen after defeating Bowser.",
    points=10,
    trigger=in_level("End Cake Picture")
        && trigger_when(tally(300, in_level("End Cake Picture"))), // some timing so the screenshot happens when the pic is fully faded in
    id=342814,
    badge="386979"
)

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

// https://github.com/n64decomp/sm64/blob/master/levels/course_defines.h indexes (add 0x0c) (remember endian weirdness)
//and https://github.com/aglab2/SM64StarDisplay/blob/9d6c11e6af49a4f90a5d8020e8a94fdd611603d0/StarManager/LevelInfo.cs#L25
course_offsets = [
    course_stars_meta("Course 1", sum_star_bits(0x0f, range(0,6)), 10, "Jungle Explorer", id=342815, badge="386980"), 
    course_stars_meta("Course 2", sum_star_bits(0x0e, range(0,6)), 10, "A Lot of Lava for an Autumn Level", id=342816, badge="386981"),
    course_stars_meta("Course 3", sum_star_bits(0x0d, range(0,6)), 10, "Realm of Sand", id=342817, badge="386982"),
    course_stars_meta("Course 4", sum_star_bits(0x0c, range(0,6)), 10, "Shining Star Wetlands", id=342818, badge="386983"),
    course_stars_meta("Course 5", sum_star_bits(0x13, range(0,6)), 10, "Lava (and Jungle, and Snow) Situation", id=342819, badge="386984"),
    course_stars_meta("Course 6", sum_star_bits(0x12, range(0,6)), 10, "Your Friendly Neighborhood", id=342820, badge="386985"),
    course_stars_meta("Course 7", sum_star_bits(0x11, range(0,6)), 10, "A Slippery Residence", id=342821, badge="386986"),
    course_stars_meta("Course 8", sum_star_bits(0x10, range(0,6)), 10, "Glimmering Falls", id=342822, badge="386987"),
    course_stars_meta("Course 9", sum_star_bits(0x17, range(0,6)), 10, "Galactic Adventure", id=342823, badge="386988"),
    course_stars_meta("Course 10", sum_star_bits(0x16, range(0,6)), 10, "Athletic Royal Legacy", id=342824, badge="386989"),
    course_stars_meta("Course 11", sum_star_bits(0x15, range(0,6)), 10, "Galaxy With the Good Physics", id=342825, badge="386990"),
    course_stars_meta("Course 12", sum_star_bits(0x14, range(0,6)), 10, "Fragments of Hackers", id=342826, badge="386991"),
    course_stars_meta("Course 13", sum_star_bits(0x1b, range(0,6)), 10, "Hyperjump Heights", id=342827, badge="386992"),
    
    course_stars_meta("Overworld 4", sum_star_bits(0x18, range(0, 5)), 5, "Eternal Path", id=342828, badge="386993"),
    
    course_stars_meta("Metal Cap", sum_star_bits(0x1c, range(0, 6)), 25, "Bubby's Lost Universe", id=342829, badge="386994"),
    course_stars_meta("Slide",     sum_star_bits(0x1d, range(0, 1)), 5, "Sliding On", id=342830, badge="386995"),
    course_stars_meta("Bowser 3",  sum_star_bits(0x1e, range(0, 1)), 5, "Bowser's Makeover", id=342831, badge="386996"),
    
    course_stars_meta("Aquarium",   sum_star_bits(0x20, range(0, 0)), 3, "Sky Castle Master Quest", id=342832, badge="386997"),
    course_stars_meta("Vanish Cap", sum_star_bits(0x22, range(0, 2)), 5, "Crystal Cave", id=342833, badge="386998"),
    course_stars_meta("Wing Cap",   sum_star_bits(0x23, range(0, 1)), 3, "Flying Off Into the Sunset", id=342834, badge="386999"),
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

star_collection_achievement(
    stars=[sum_star_bits(0x0b, range(0, 5))], total = 6,
    title = "Filler Freebies",
    description = "Collect all 6 stars across the first 3 overworlds.",
    points = 5,
    id = 342835,
    badge = "387000"
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
    mushies_meta("Course 1", "Obsolete Lifesaver",
        "Collect the 1-up mushroom in {0}.", 1,
        [{"type": "stationary", "count": 1}],
        level_check=remained_in_level("Course 1", hit=0), id=342836, badge="387001"),
    mushies_meta("Aquarium", "Chunk Scavenger Hunt",
        "Collect all 4 1-up mushrooms in {0}.", 4,
        [{"type": "stationary", "count": 1},
         {"type": "impartial",  "count": 2},
         {"type": "running away", "count": 1}],
        level_check=remained_in_level("Aquarium", hit=0), id=342837, badge="387002"),
    mushies_meta("Course 4", "11-Year Present",
        "Collect the 1-up mushroom in {0}.", 1,
        [{"type": "stationary", "count": 1}],
        level_check=remained_in_level("Course 4", hit=0), id=342838, badge="387003"),
    mushies_meta("Course 7", "Ice Shrooms",
        "Collect all 3 1-up mushrooms in {0}. Check the windows.", 3,
        [{"type": "activator", "count": 1},
         {"type": "stationary", "count": 2}],
        level_check=remained_in_level("Course 7", hit=0), id=342839, badge="387004"),
    mushies_meta("Course 10", "Relics of the Cactus",
        "Collect all 4 1-up mushrooms in {0}. (Only possible during mission 6)", 4,
        [{"type": "impartial", "count": 1},
         {"type": "stationary", "count": 3}],
        level_check=remained_in_level("Course 10", hit=0), id=342840, badge="387005"),
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

// Side challenge time...

achievement(
    title = "Jump Isn't Worth: Asta Edition",
    description = "Collect the star 'Violent Volcano' in Course 1 without pressing the A button.",
    points = 5,
    trigger = remained_in_level("Course 1", hit=1)
        && never(warp_dest_type() == 0 && just_increased(controller_a_button()))
        && trigger_when(collected_star_action_check(1)),
    id=342841,
    badge="387006"
)

achievement(
    title = "Don't Over-think This One",
    description = "Collect the star 'Shell Ride Over the Molten River' in Course 2 without riding a Koopa Shell or taking damage.",
    points = 5,
    trigger = remained_in_level("Course 2", hit=1)
        && never(just_increased(hp_decrement()))
        && never(any_of(burning_actions, a => mario_action_changed_to(a)))
        && never(object_changed_to(ridden_object(), "koopa shell"))
        && trigger_when(collected_star_action_check(3)),
    id=342842,
    badge="387007"
)

achievement(
    title = "Perfect Platformer",
    description = "Collect the star 'Rooftop Timed Challenge' in Course 3 without grabbing any ledge.",
    points = 5,
    trigger = remained_in_level("Course 3", hit=1)
        && never(mario_action_changed_to("ledge grab"))
        && trigger_when(collected_star_action_check(1)),
    id=342843,
    badge="387008"  
)

c4_switch = nth_array_object(12)
achievement(
    title = "What Timed Boxes?",
    description = "Collect the star 'High-Up Timed Boxes!' in Course 4 without pressing the purple switch near that star.",
    points = 5,
    trigger = remained_in_level("Course 4", hit=1)
        && object_is(c4_switch, "purple box switch")
        && never(just_changed_to(object_action(c4_switch), 1))
        && trigger_when(collected_star_action_check(5)),
    id=342844,
    badge="387009"
)

// need koopa cheevs to be object-generic (sub-area scrambles objects :c)
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

achievement(
    title = "Same Old Race With a Better Ride",
    description = "Win the Koopa race in Course 4 while riding a Koopa Shell.",
    points = 5,
    trigger = remained_in_level("Course 4", hit=0)
        && object_is(ridden_object(), "koopa shell")
        && object_koopa_race_started_and_won(nth_array_object(67), trig=1),
    id=342845,
    badge="387010"
)

leaderboard(
    title = "Swampy Koopa Race",
    description = format("Win the race with Koopa the Quick in {0}.", course_infos["Course 4"]["full name"]),
    start = in_area("Course 4", 1) && object_koopa_race_started_and_won(nth_array_object(67), trig=0),
    cancel = always_false(),
    submit = always_true(),
    value = hud_timer()*2,
    
    format="FRAMES",
    lower_is_better = true,
    id=72797
)

achievement(
    title = "Unneeded Star-Specific Stuff",
    description = "Collect the star 'In the Burning Heart' in Course 5 without riding a Koopa Shell.",
    points = 5,
    trigger = remained_in_level("Course 5", hit=1)
        && never(object_changed_to(ridden_object(), "koopa shell"))
        && trigger_when(collected_star_action_check(2)),
    id=342846,
    badge="387011"
)

achievement(
    title = "Downtown Blues",
    description = "Read the sign at the end (wrong way) of the old town.",
    points = 1,
    trigger = in_area("Course 6", 2)
        && just_changed_from(dialog_id__mem, 0x89),
    id=342847,
    badge="387012"
)

achievement(
    title = "Sanitary Collection",
    description = "Collect the star 'Silver Stars in the Sewers' in Course 6 without going below full displayed HP.",
    points = 5,
    trigger = remained_in_level("Course 6", hit=1)
        && sublevel_id__mem == 1
        && never(hp() < 0x800)
        && trigger_when(collected_star_action_check(5)),
    id=342848,
    badge="387013"
)

achievement(
    title = "Flotation in Nothing Form",
    description = "Collect the star 'Icy Athletics on the Third Floor' in Course 7 without standing on the purple switches.",
    points = 5,
    trigger = remained_in_level("Course 7", hit=1)
        && sublevel_id__mem == 1
        && never(object_changed_to(stood_on_object(), "purple box switch"))
        && trigger_when(collected_star_action_check(3)),
    id=342849,
    badge="387014"
)

achievement(
    title = "Meticulously Jump Through the Tunnel",
    description = "Collect the star 'Cruise Through the Quicksand Tunnel' in Course 8 without getting a wing cap or riding a Koopa Shell.",
    points = 10,
    trigger = remained_in_level("Course 8", hit=1)
        && never(just_increased(wearing_wing_cap()))
        && never(object_changed_to(ridden_object(), "koopa shell"))
        && trigger_when(collected_star_action_check(1)),
    id=342850,
    badge="387015"
)

achievement(
    title = "Tri Harder",
    description = "Collect the star 'Try Angle' in Course 8 without getting a wing cap or twirling.",
    points = 5,
    trigger = remained_in_level("Course 8", hit=1)
        && never(just_increased(wearing_wing_cap()))
        && never(mario_action_changed_to("twirl"))
        && trigger_when(collected_star_action_check(5)),
    id=342851,
    badge="387016"
)

achievement(
    title = "Sign Command Disregard",
    description = "Collect the star 'Red Coins of the Botanical Gardens' in Course 10 without triple jumping.",
    points = 5,
    trigger = remained_in_level("Course 10", hit=1)
        && sublevel_id__mem == 1
        && never(mario_action_changed_to("triple jump"))
        && trigger_when(collected_star_action_check(4)),
    id=342852,
    badge="387017"
)

leaderboard(
    title = "Olympian Koopa Race",
    description = format("Win the race with Koopa the Quick in {0}.", course_infos["Course 10"]["full name"]),
    start = in_area("Course 10", 1) && any_of(array_map(range(0, 239), a => object_koopa_race_started_and_won(nth_array_object(a), trig=0)), b => b),
    cancel = always_false(),
    submit = always_true(),
    value = hud_timer()*2,
    
    format="FRAMES",
    lower_is_better = true,
    id=72798
)

achievement(
    title = "Yes.",
    description = "Stand on a suspicious wooden peg in Course 10, get warped, then read the sign there.",
    points = 1,
    trigger = in_area("Course 10", 4)
        && just_changed_from(dialog_id__mem, 0x5E),
    id=342858,
    badge="387023"
)

achievement(
    title = "Still Desire to Not Get Burnt",
    description = "Collect the star 'Burning Secrets Desire' in Course 11 without taking damage.",
    points = 5,
    trigger = remained_in_level("Course 11", hit=1)
        && never(just_increased(hp_decrement()))
        && never(any_of(burning_actions, a => mario_action_changed_to(a)))
        && trigger_when(collected_star_action_check(6)),
    id=342853,
    badge="387018"
)

achievement(
    title = "Experimental Level Part Warps",
    description = "Collect all 7 red coins in Course 12 in one go. (They indicate warps).",
    points = 3,
    trigger = never(level_changed())
        && measured(repeated(7, got_red_coin()), when=in_level("Course 12")),
    id=342854,
    badge="387019"
)

achievement(
    title = "Flightless Coinage",
    description = "Collect the 100 coin star in Course 13 without getting a wing cap.",
    points = 10,
    trigger = remained_in_level("Course 13", hit=1)
        && never(just_increased(wearing_wing_cap()))
        && trigger_when(collected_star_action_check(7)),
    id=342855,
    badge="387020"
)

achievement(
    title = "Lava Tunnel Sprint",
    description = "Collect the lava tunnel star in the metal cap level, picking up no more than one metal cap.",
    points = 5,
    trigger = remained_in_level("Metal Cap", hit=1)
        && sublevel_id__mem == 1
        && never(collided_with_object("metal cap", count=2))
        && trigger_when(collected_star_action_check(6)),
    id=342856,
    badge="387021"
)

achievement(
    title = "Where Are You Going?",
    description = "Read a secret sign in Corrupted Castle.",
    points = 1,
    trigger = in_level("Bowser 3")
        && just_changed_from(dialog_id__mem, 0x54),
    id=342857,
    badge="387022"
)

// RP

general_level_dict = {
    0x0000: "admiring his statue in the first overworld", // OW1
    0x1001: "admiring his statue in the first overworld", // OW1
    0x0601: "continuing his collect-a-thon in the second overworld", // OW2
    0x1a01: "venturing through more hack creator levels in the third overworld", // OW3
    0x1101: "getting free stars in the 'kaizo' overworld",
    0x1102: "inside the castle in the 'kaizo' overworld",
    
    0x0901: "rummaging for stars in Abandoned Jungle Village",
    0x0902: "jumping through a temple in Abandoned Jungle Village",
    0x1801: "platforming on pillars in Autumnal Architecture",
    0x0C01: "relaxing in Sandy City",
    0x0501: "revisiting the Swampy Spring",
    0x0401: "on a hotty hot adventure in Lava Situation",
    0x0701: "climbing more houses in System of a Rebuilt Town",
    0x0702: "exploring the ruined downtown system",
    0x1601: "ascending the Ice Crystal Tower",
    0x1602: "breaking through the top of Ice Crystal Tower",
    0x0801: "finding some shade in Glorious Summer Waterfall",
    0x1701: "researching in Zeta Sector",
    0x0A01: "training in Olympian Summit",
    0x0A02: "doing some 2D gymnastics in Olympian Summit",
    0x0A03: "taking a dive in Olympian Summit",
    0x0A04: "getting rickrolled in Olympian Summit",
    0x0B01: "on a 2-sided planetary adventure in Flamedune Galaxy",
    0x2401: "on an astounding pace through Experimental Generation",
    0x0D01: "jumping at high speeds in Zone of Happiness",
    
    0x1C01: "playing actually good level design in the metal cap level",
    0x1C02: "pressing the metal cap switch for free",
    0x1D01: "flying high in the wing cap level",
    0x1201: "vanishing through crystals in the vanish cap level",
    
    0x1B01: "sliding through cherry blossoms", // slide
    0x1B02: "sliding through an icy sanctuary", // slide
    0x1401: "on a mini sky castle adventure", // aquarium
    0x1901: "at the end of his journey", // end cake picture

    0x1501: "on a Corrupted Castle Adventure",
    0x2201: "fighting Bowser in an easy arena"
}

level__lookup = rich_presence_lookup("Levels", warp_dest_level_area(), general_level_dict, "in an unbeknownst location")

stars__value = rich_presence_value("Number", nof_stars())
lives__value = rich_presence_value("Number", (byte(nof_lives__addr) ) - (bit7(nof_lives__addr) * 256))
level_test__value = rich_presence_value("Number", warp_dest_level_area())

file__lookup  = rich_presence_lookup("File", file_num__mem, {
    0x01: "A", 0x02: "B", 0x03: "C", 0x04: "D"
}, "??")

rich_presence_conditional_display(in_title_screen(), "Getting ready for yet another collab adventure. (Title Screen)")
rich_presence_conditional_display(in_file_select(), 
    "Getting ready for a yet another collab adventure. (File Select)")
rich_presence_conditional_display(
    level_id__mem != 1 && (music_id__mem != 0x21 || effective_mario_object() != 0), // both are false on file select, including after game over
      "Mario-{2} is {0} with {1}⭐ [🔴{3}] [🟢{4}] [🔵{5}]", level__lookup, stars__value, file__lookup, 
        rich_presence_lookup("Switch", pressed_switch__mem("red"), {1:"▣"}, "▢"),
        rich_presence_lookup("Switch", pressed_switch__mem("green"), {1:"▣"}, "▢"),
        rich_presence_lookup("Switch", pressed_switch__mem("blue"), {1:"▣"}, "▢")
    )
rich_presence_display("On a legendary collab adventure.")