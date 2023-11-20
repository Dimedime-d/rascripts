// ~Hack~ Star Revenge 4.9: Adulterated Reality
// #ID = 24301
// Made in RATools v1.12.0

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
    "file manager":     0x8008FD58,

    "spring":           0x801163B4,
    "panel":            0x801163D8,
    "teleporter":       0x8011655C,
    "warp":             0x80116580,
    "warp pipe":        0x801165A0,
    
    "coin formation spawn": 0x8011671C,
    
    "purple box switch":0x801172AC,
    "koopa shell":      0x80117D3C,
    
    "big boo":          0x80118590,
    
    "mission star manager": 0x80118E48,
    
    "sign":             0x801190E0,
    
    "vanish cap":       0x80119C1C,
    "regular star":     0x80119C3C,
    "spawned star":     0x80119C64,
    "box star":         0x801165F8,
    
    "secret number":    0x80119D1C,
    "impartial 1-up":   0x80119DDC,
    "stationary 1-up":  0x80119E7C,
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
    "Castle Grounds":       course_meta(0x10, [0, 1],   "The Overworld"), // Castle Grounds (beware)
    "Ocean Temple":         course_meta(0x10, [2],   "Ocean Temple"),
    "Devour Realm":         course_meta(0x10, [3],   "Devour Realm"),
    
    "Inside Castle":        course_meta(0x06, [-1], "Overworld 2"),
    "Remnant Ending":       course_meta(0x06, [2],  "Remnant Ending"),
    "Scepter End":          course_meta(0x06, [3],  "Scepter End"),
    // Area 4: Warp pipe deaths
    "Castle Courtyard":      course_meta(0x1a, [-1], "Overworld 3"), // Castle Courtyard
    // OW3 is just star get/death areas, or shortcuts to gs/bs, or ow cannon
    
    "Course 1":         course_meta(0x09, [-1],   "Doubtful Creek Town"),
    "Course 2":         course_meta(0x18, [-1],   "Fading City"),
    "Course 3":         course_meta(0x0c, [-1],   "Firestar Canyon"),
    "Course 4":         course_meta(0x05, [-1],   "Timid Derped Town"),
    "Course 5":         course_meta(0x04, [-1],   "Acidic Marshland"),
    "Course 6":         course_meta(0x07, [-1],   "Frigid Factory"),
    "Course 7":         course_meta(0x16, [-1],   "Frostbite Swamp"),
    "Course 8":         course_meta(0x08, [-1],   "Collapsed Mines"),
    "Course 9":         course_meta(0x17, [-1],   "Atrophied Mansion"),
    "Course 10":        course_meta(0x0a, [-1],   "Ominous Excavation Town"),
    "Course 11":        course_meta(0x0b, [-1],   "Heat Rash Canyon"),
    "Course 12":        course_meta(0x24, [-1],   "Thunder Blaze Horizon"),
    "Course 13":        course_meta(0x0d, [-1],   "Plagued Cliffs"),
    "Course 14":        course_meta(0x0e, [-1],   "Mystified Mountains"),
    "Course 15":        course_meta(0x0f, [-1],   "Nightsky Citadel"),
    
    "Needle Blue Realm":         course_meta(0x14, [-1],   "Needle Blue Realm"), // Aquarium
    "Bloody Moon":      course_meta(0x1f, [-1],   "Eclipse of a Bloody Moon"), // Cloud Stage
    "End Cake Picture": course_meta(0x19, [-1],   "(Remnant Abyss Areas)"),
    "Slide":            course_meta(0x1b, [-1],   "Remnant Abyss"),
    "Remnant Abyss Start":            course_meta(0x1b, [1],   "the start area of Remnant Abyss"),
    
    "Bowser 1":         course_meta(0x11, [-1],   "Beautiful Skyscape"),
    "Key 1":            course_meta(0x1e, [-1],   "Beautiful Skyscape"),
    "Bowser 2":         course_meta(0x13, [-1],   "Frozen Dizzy Plant"),
    "Key 2":            course_meta(0x21, [-1],   "Frozen Dizzy Plant"),
    "Bowser 3":         course_meta(0x15, [-1],   "Scepter Sanctum"),
    "Final Fight":      course_meta(0x22, [-1],   "Scepter Sanctum"),
    
    "Dutish Prism":        course_meta(0x1c, [-1],   "Eclipse of a Dutish Prism"), // MC
    "Green Switch":         course_meta(0x1d, [1],   "Green Switch Palace"),
    "Blue Switch":          course_meta(0x1d, [2],   "Blue Switch Palace"),
    "Sizzling Sun":       course_meta(0x12, [-1],   "Eclipse of a Sizzling Sun"),
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

function dialog_meta(level_check, dialog, title, description, points=1, id=0, badge="0") => {"level check": level_check, "dialog": dialog, "title": title, "description": description, "points": points, "id": id, "badge": badge}
// probably 1 cheev per secret text

dialogs = [
    dialog_meta(in_area("Course 1", 1), 0x64, "Lost You Gotten", "Read the secret (invisible) sign in Course 1 above a former course entrance.", id=322118, badge="359145"),
    dialog_meta(in_area("Course 2", 1), 0x9E, "Abandoned Resident", "Read a secret sign in Course 2 in a white building.", id=322119, badge="359146"),
    dialog_meta(in_area("Course 3", 1), 0x8D, "Duplicate Hint...", "Read a secret sign in Course 3 above a star.", id=322120, badge="359147"),
    dialog_meta(in_area("Course 4", 1), 0x7B, "Don't Go :(", "Talk to a Bob-omb Buddy in Course 4 at the end of a road, before it falls off.", id=322121, badge="359148"),
    dialog_meta(in_area("Course 5", 1), 0x63, "The Switch Is Optional", "Read a secret sign in Course 5. Shoutouts.", id=322122, badge="359149"),
    dialog_meta(in_area("Bowser 1", 1), 0x29, "You Got This One Already?", "Read a secret sign in Beautiful Skyscape.", id=322123, badge="359150"),
    
    // c7, c8
    dialog_meta(in_area("Course 7", 1), 0x95, "Push Everywhere", "Read a secret sign in Course 7, behind a fake wall.", id=322124, badge="359151"),
    dialog_meta(in_area("Course 7", 1), 0x5C, "Overseeing the Needles", "Read another secret sign in Course 7, somewhere high.", id=322125, badge="359152"),
    dialog_meta(in_area("Course 8", 1), 0x2C, "It's Not That Hard...", "Read a secret sign in Course 8. (Must get on platform from below.)", 2, id=322126, badge="359153"),
    
    dialog_meta(in_area("Course 9", 1), 0x33, "All for Nothing...", "Read a secret sign in Course 9, up some wide walls. (Also get the life shroom if you wish)", 2, id=322127, badge="359154"),
    dialog_meta(in_area("Course 10", 1), 0x5A, "Language Unknown", "Read a secret sign in Course 10 near a pyramid.", id=322128, badge="359155"),
    // C11?
    dialog_meta(in_area("Course 11", 1), 0x67, "Disaster Quest Tree", "Read a secret sign in Course 11, behind a fake wall.", id=322129, badge="359156"),
    dialog_meta(in_area("Course 11", 1), 0x9D, "Old Jokes", "Read another secret sign in Course 11, on top of an unused cliff.", id=322130, badge="359157"),
    dialog_meta(in_area("Course 12", 1), 0x56, "The Next One", "Read a secret sign in Course 12 above some walls.", 2, id=322131, badge="359158"),
    dialog_meta(in_area("Course 14", 1), 0x83, "Answer to Everything", "Read a secret sign in Course 14 somewhere up high.", id=322132, badge="359159"),
    
    dialog_meta(in_area("Needle Blue Realm", 1), 0x7A, "Star-Enemy Shenanigans", "Read a secret sign in Needle Blue Realm behind some glass.", id=322133, badge="359160"),
    // check bloody moon dialogs
    dialog_meta(in_level("Bloody Moon"), 0x5F, "Counter-Espionage", "Talk to the Sign Lord's brother in Eclipse of a Bloody Moon.", id=322134, badge="359161"),
    dialog_meta(in_level("Bloody Moon"), 0x57, "Soon™", "Talk to the Sign Lord in Eclipse of a Bloody Moon.", id=322135, badge="359162"),
    dialog_meta(in_level("Devour Realm"), 0xA3, "The Link is Dead :(", "Talk to a secret NPC in the Devour Realm.", id=322136, badge="359163"),
    
    
    dialog_meta(in_level("Remnant Ending"), 0x69, "Journey Has Started (to End) - Start of Hint Chain", "Read a secret sign in restored Peach's Castle behind some doors.", id=322137, badge="359164"),
    // probably have some alternate level check to avoid snooping, or don't have any check, lel
    dialog_meta(time_stop_enabled() != 0, 0xA4, "Hint Chain Part 2", "Follow the hint from the previous achievement to read a secret sign.", id=322138, badge="359165"), // c13
    dialog_meta(time_stop_enabled() != 0, 0x2E, "Hint Chain Part 3", "Follow the hint from the previous achievement to read a secret sign.", id=322139, badge="359166"), // c9
    dialog_meta(time_stop_enabled() != 0, 0x4E, "Hint Chain Part 4", "Follow the hint from the previous achievement to talk to a hidden buddy.", id=322140, badge="359167"), // c12
    dialog_meta(time_stop_enabled() != 0, 0x6E, "Hint Chain Part 5", "Follow the hint from the previous achievement to read a secret sign.", id=322141, badge="359168") // b2
]

function dialog_achievements() {
    for d in dialogs {
        
        d_trigger = d["level check"] && just_changed_from(dialog_id__mem, d["dialog"])
        if (d["dialog"] == 0x2C) {
            d_trigger = remained_in_level("Course 8", hit=0)
                && once(just_increased(on_pole()) && in_3d_box(3300.0, 3350.0, 3000.0, 5200.0, -14575.0, -14625.0) )
                && never(just_decreased(airborne()) && in_3d_box(4700.0, 10000.0, 2500.0, 8000.0, -17000.0, -11000.0))
                && trigger_when(just_changed_from(dialog_id__mem, d["dialog"]))
        }
        
        achievement(
            title = d["title"],
            description = d["description"],
            trigger = d_trigger,
            points = d["points"],
            id = d["id"],
            badge = d["badge"]
        )
    }
}

dialog_achievements()

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
    milestone_meta("Small Needle Collection",
        "Collect 13 stars.",
        stars=13, points=5, id=322079, badge="359107"),
    milestone_meta("Freezing Sanctuary",
        "Collect 40 stars.",
        stars=40, points=5, id=322080, badge="359108"),
    milestone_meta("Sum of a Lost Sacrifice",
        "Collect 60 stars.",
        stars=60, points=10, id=322081, badge="359109"),
    milestone_meta("Journey to the Stars",
        "Collect 95 stars.",
        stars=95, points=25, id=322082, badge="359110"),
    milestone_meta("Needle's Haven",
        "Collect all 150 stars.",
        stars=150, points=50, id=322083, badge="359111"),
    
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

hack_switches = ["red", "blue", "green", "yellow"] // all 4 used

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
    title = "Technically Separate From Any%",
    description = "Press the green, blue, yellow, and red !-switches.",
    points = 10,
    trigger = all_switches_trigger(),
    id = 322084,
    badge = "359112"
)

achievement(
    title = "Skies of Hope",
    description = "Obtain the first key.",
    points = 10,
    trigger = in_level("Key 1") && collected_star_action_check(),
    id = 322085,
    badge = "359113"
)

achievement(
    title = "Still Making Dem Colors",
    description = "Obtain the second key.",
    points = 10,
    trigger = in_level("Key 2") && collected_star_action_check(),
    id = 322086,
    badge = "359114"
)

achievement(
    title = "Can BroDute Sort Things Out?",
    description = "Complete the trial in Scepter Sanctum.",
    points = 25,
    trigger = in_level("Final Fight") && collected_star_action_check(),
    id = 322087,
    badge = "359115"
)

achievement(
    title = "Devourer Eclipsed",
    description = "Collect the (troll) star at the end of the Devour Realm.",
    points = 25,
    trigger = in_level("Devour Realm") && collected_star_action_check(),
    id = 322088,
    badge = "359116"
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
    course_stars_meta("Course 1", sum_star_bits(0x0f, range(0, 5)), 5, "A Barely Different Level to Start You Off", id=322089, badge="359117"), 
    course_stars_meta("Course 2", sum_star_bits(0x0e, range(0, 5)), 10, "Purpler Plane of Existence", id=322090, badge="359118"),
    course_stars_meta("Course 3", sum_star_bits(0x0d, range(0, 5)), 10, "Overheated Orange Ochre Pits", id=322091, badge="359119"),
    course_stars_meta("Course 4", sum_star_bits(0x0c, range(0, 5)), 10, "Twilight Coast", id=322092, badge="359120"),
    course_stars_meta("Course 5", sum_star_bits(0x13, range(0, 5)), 10, "Lethal Corridor", id=322093, badge="359121"),
    course_stars_meta("Course 6", sum_star_bits(0x12, range(0, 5)), 10, "Miss the Ultra Blocks?", id=322094, badge="359122"),
    course_stars_meta("Course 7", sum_star_bits(0x11, range(0, 5)), 10, "Mortal Blood Enveloped by the Snowfall of Purification", id=322095, badge="359123"),
    course_stars_meta("Course 8", sum_star_bits(0x10, range(0, 5)), 10, "Needs More Deadly Gas", id=322096, badge="359124"),
    course_stars_meta("Course 9", sum_star_bits(0x17, range(0, 5)), 25, "Not-So Cancerous Design Castle", id=322097, badge="359125"),
    course_stars_meta("Course 10", sum_star_bits(0x16, range(0, 5)), 25, "Stupid Construction Workers Dug Out the Ground", id=322098, badge="359126"),
    course_stars_meta("Course 11", sum_star_bits(0x15, range(0, 5)), 25, "Warmed, Warned Cliffs", id=322099, badge="359127"),
    course_stars_meta("Course 12", sum_star_bits(0x14, range(0, 5)), 25, "Blaze Craze Parkour", id=322100, badge="359128"),
    course_stars_meta("Course 13", sum_star_bits(0x1b, range(0, 5)), 25, "Old Music Was Better", id=322101, badge="359129"),
    course_stars_meta("Course 14", sum_star_bits(0x1a, range(0, 5)), 25, "Discolored Majestic Madness", id=322102, badge="359130"),
    course_stars_meta("Course 15", sum_star_bits(0x19, range(0, 5)), 25, "Refined Moustache Moon Paradox", id=322103, badge="359131"),
    
    course_stars_meta("Bowser 1", sum_star_bits(0x18, range(0, 2)), 10, "Riding Rainbows", id=322104, badge="359132"),
    course_stars_meta("Bowser 2", sum_star_bits(0x1f, range(0, 2)), 10, "All Blue Here", id=322105, badge="359133"),
    course_stars_meta("Bowser 3", sum_star_bits(0x1e, range(0, 0)), 3, "Secrets Lost in Time", id=322106, badge="359134"),
    
    course_stars_meta("Green Switch", sum_star_bits(0x23, range(0, 2)), 10, "Lump Jumps", id=322107, badge="359135"),
    course_stars_meta("Blue Switch",  sum_star_bits(0x23, range(3, 6)), 10, "Sepia Skyscape", id=322108, badge="359136"),
    
    course_stars_meta("Dutish Prism", sum_star_bits(0x1c, range(0, 6)), 25, "Trials of Triangle Land", id=322109, badge="359137"),
    course_stars_meta("Sizzling Sun", sum_star_bits(0x22, range(0, 6)), 25, "Day of Endless Sunshine", id=322110, badge="359138"),
    course_stars_meta("Bloody Moon",  sum_star_bits(0x21, range(0, 6)), 25, "Blood-Stained Parkour Fortress", id=322111, badge="359139"),
    
    course_stars_meta("Needle Blue Realm", sum_star_bits(0x20, range(0, 3)), 10, "Realm of Blue Star Dimensions", id=322112, badge="359140"),
    
    
    //"End Cake Picture": course_stars_meta(sum_star_bits(0x27, range(0, 0)), 1, "Okay, Where's the Warp?", id=308813, badge="341755"),
    //"Slide": course_stars_meta(sum_star_bits(0x1d, range(0, 0)), 2, "They're Still Moving!", id=308814, badge="341756"),
    // handle remnant abyss separately
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
        
        if (substring(course, 0, 6) == "Course") {
            star_qty = "the 6 regular stars"
        }
        if (course == "Bowser 3") {
            star_qty = "the star (that counts towards total)"
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

star_collection_achievement(
    stars=[sum_star_bits(0x0b, range(1, 2))], total = 2,
    title = "Peach's Castle Has Seen Better Days",
    description = "Collect both overworld stars.",
    points = 2,
    id=322113,
    badge="359141"
)

remnant_ending_stars = [
    sum_star_bits(0x1d, [0]), // boss 1
    sum_star_bits(0x27, [0, 1]), // boss 2/3
    sum_star_bits(0xb,  [0]), // 100% ending
]

star_collection_achievement(
    stars = remnant_ending_stars, total=4,
    title = "Back With the Timeline",
    description = "Collect all stars in the Remnant Abyss, and also the ending star.",
    points = 50,
    id=322114,
    badge="359142"
)

hidden_box_stars = array_map(merge_arrays(range(0x0c, 0x17, 1), range(0x19, 0x1b, 1)), a => sum_star_bits(a, [6]))

star_collection_achievement(
    stars = hidden_box_stars, total=15,
    title = "15 15 15 15 15 15 15 15 15 15 15 15 15 15 15",
    description = "Collect all FIFTEEN rainbow stars (star 7 across all 15 courses).",
    points = 10,
    id=322115,
    badge="359143"
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

cannon_bits = sum_cannon_bits([0x0c, 0x0f, 0x10, 0x12, 0x15, 0x16, 0x19, 0x1a, 0x1d, 0x27]) // somehow, bit in c12 got flipped???
star_collection_achievement(
    stars=[cannon_bits], total=10,
    title = "You're Keeping Track, Right?",
    description = "Open all 10 cannons.",
    points = 10,
    id=322116,
    badge="359144"
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
    mushies_meta("Course 1", "Doubtful These Will Do Anything",
        "Collect all 3 life shrooms in {0}.", 3,
        [{"type": "stationary", "count": 3}],
        level_check=remained_in_level("Course 1", hit=0), id=322443, badge="359587"),
    mushies_meta("Course 3", "Blazing Hot Shrooms",
        "Collect all 3 life shrooms in {0}. Check for an invisible box somewhere...", 3,
        [{"type": "stationary", "count": 2},
         {"type": "impartial",  "count": 1}],
        level_check=remained_in_level("Course 3", hit=0), id=322444, badge="359588"),
    mushies_meta("Course 4", "Thwomp Treasure",
        "Collect the life shroom in {0}.", 1,
        [{"type": "stationary", "count": 1}],
        level_check=remained_in_level("Course 4", hit=0), id=322445, badge="359589"),
    mushies_meta("Course 5", "Safe to Eat?",
        "Collect the life shroom in {0}.", 1,
        [{"type": "impartial", "count": 1}],
        level_check=remained_in_level("Course 5", hit=0), id=322446, badge="359590"),
    mushies_meta("Course 6", "Shouldn't Need This Spare Healing",
        "Collect all 3 life shrooms in {0}.", 3,
        [{"type": "impartial", "count": 2},
         {"type": "stationary", "count": 1}],
        level_check=remained_in_level("Course 6", hit=0) && sublevel_id__mem == 1, id=322447, badge="359591"),
    mushies_meta("Course 7", "A Feast You Shall Receive",
        "Collect all 7 life shrooms in {0}. Yes, 7.", 4,
        [{"type": "stationary", "count": 7}],
        level_check=remained_in_level("Course 7", hit=0), id=322448, badge="359592"),
    // skip c9
    mushies_meta("Course 10", "Deserted Food Reserves",
        "Collect both life shrooms in {0}.", 2,
        [{"type": "stationary", "count": 2}],
        level_check=remained_in_level("Course 10", hit=0), id=322449, badge="359593"),    
    mushies_meta("Course 11", "Shouldn't Even Need This One",
        "Collect the life shroom in {0}.", 0,
        [{"type": "stationary", "count": 1}],
        level_check=remained_in_level("Course 11", hit=0), id=322450, badge="359594"),
    mushies_meta("Course 12", "Imagine If These Were Reds",
        "Collect all 8 life shrooms in {0}.", 10,
        [{"type": "stationary", "count": 8}],
        level_check=remained_in_level("Course 12", hit=0), id=322451, badge="359595"),
    mushies_meta("Course 13", "Probably Not Shroob Food",
        "Collect all 4 life shrooms in {0}.", 5,
        [{"type": "stationary", "count": 4}],
        level_check=remained_in_level("Course 13", hit=0), id=322452, badge="359596"),
    mushies_meta("Course 14", "For the Inverted Road",
        "Collect all 3 life shrooms in {0}.", 2,
        [{"type": "stationary", "count": 3}],
        level_check=remained_in_level("Course 14", hit=0), id=322453, badge="359597"),
    mushies_meta("Course 15", "Nothing But Space Junk",
        "Collect all 4 life shrooms in {0}. (Enter the moon last)", 3,
        [{"type": "stationary", "count": 4}],
        level_check=remained_in_level("Course 15", hit=0) && once(sublevel_id__mem == 1), id=322454, badge="359598"),
    mushies_meta("Castle Grounds", "Memories of a Rewritten Past",
        "Collect both life shrooms in {0}. Can you even take damage here?", 2,
        [{"type": "stationary", "count": 2}],
        level_check=__ornext(any_of([0, 0x10], a => warp_dest_level() == a)) && __ornext(any_of([0, 1], a => warp_dest_area() == a)) && never(just_changed_from(level_id__mem, 0x10)), id=322455, badge="359599"),
    // ocean temple, devour realm are gimmes
    
    mushies_meta("Bowser 1", "Cloudy Shrooms",
        "Collect both life shrooms in the first part of {0}.", 2,
        [{"type": "stationary", "count": 2}],
        level_check=remained_in_level("Bowser 1", hit=0), id=322456, badge="359600"),    
    mushies_meta("Key 1", "Replaced Easter Egg",
        "Collect the life shroom in the second part of {0}.", 1,
        [{"type": "stationary", "count": 1}],
        level_check=remained_in_level("Key 1", hit=0), id=322457, badge="359601"),
    mushies_meta("Bowser 2", "Lost Worker Food",
        "Collect both life shrooms in the first part of {0}.", 2,
        [{"type": "stationary", "count": 2}],
        level_check=remained_in_level("Bowser 2", hit=0), id=322458, badge="359602"),   
    mushies_meta("Bowser 3", "I Wanna Go Golfing...",
        "Collect the life shroom in the first part of {0}.", 1,
        [{"type": "stationary", "count": 1}],
        level_check=remained_in_level("Bowser 3", hit=0), id=322459, badge="359603"),   
    mushies_meta("Final Fight", "Convenient Heal Spots",
        "Collect all 3 life shrooms in the second part of {0}.", 3,
        [{"type": "stationary", "count": 3}],
        level_check=remained_in_level("Final Fight", hit=0), id=322460, badge="359604"),   
        
    mushies_meta("Blue Switch", "Sightseeing Atrophied Skies",
        "Collect both life shrooms in {0}.", 2,
        [{"type": "stationary", "count": 2}],
        level_check=remained_in_level("Blue Switch", hit=0), id=322461, badge="359605"),  
    mushies_meta("Bloody Moon", "A Long-ish Way Up",
        "Collect the life shroom in {0}.", 1,
        [{"type": "stationary", "count": 1}],
        level_check=remained_in_level("Bloody Moon", hit=0), id=322462, badge="359606"),  
        
    mushies_meta("Remnant Abyss Start", "Here's a Point",
        "Collect the life shroom in {0}.", 1,
        [{"type": "stationary", "count": 1}],
        level_check=remained_in_level("Remnant Abyss Start", hit=0), id=322463, badge="359607")
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

function challenge_achievements_1() {
    
    achievement(
        title = "(Zero) Wallkick Challenge",
        description = "Collect the star 'High View From the Doomed Town' in Course 1 without wallkicking.",
        points = 3,
        trigger = remained_in_level("Course 1", hit=1)
            && never(wallkicked())
            && trigger_when(collected_star_action_check(0x02)),
        id=322464,
        badge="359608"
    )
    
    // reset no longer activates over trigger condition
    achievement(
        title = "In-n-Out Vanish Time",
        description = "Collect the secret and the star 'Top Tiny Parkour' in Course 2 while wearing a vanish cap, in one go.",
        points = 5,
        trigger = remained_in_level("Course 2", hit=0)
            && once(object_changed_to(g_cutscene_focus__mem, "spawned star")
                && object_star_mission(g_cutscene_focus__mem) == 3
                && wearing_vanish_cap() != 0)
            && never(just_decreased(wearing_vanish_cap()) && !mario_action_is("star grab fall"))
            && trigger_when(collected_star_action_check(4)),
        id=322465,
        badge="359609"
    )
    
    achievement(
        title = "What Heart?",
        description = "Collect the star 'Pillars of Precision' in Course 3 while still in air from a cannon shot (not lava boost).",
        points = 5,
        trigger = in_level("Course 3")
            && mario_action_was("shot from cannon")
            && collected_star_action_check(6),
        id=322466,
        badge="359610"
    )
    
    achievement(
        title = "What is a Crossover?",
        description = "Collect the star 'Flowery Arch Doom' in Course 4, wallkicking no more than three times.",
        points = 10,
        trigger=never(level_changed())
        && ((in_level("Course 4") && hud_stars_shown() != 0 && 
        (trigger_when(collected_star_action_check(1))) && disable_when(repeated(4, wallkicked())))
        || (measured(repeated(3, wallkicked()), when=in_level("Course 4")) && impossible_condition())),
        id=322467,
        badge="359611"
    )
    
    achievement(
        title = "Maximum Toxicity Coins",
        description = "Collect the star 'A Trial in Toxicity' in Course 5 after getting all 8 red coins.",
        points = 5,
        trigger = remained_in_level("Course 5", hit=0)
        && repeated(8, got_red_coin())
        && trigger_when(collected_star_action_check(3)),
        id=322468,
        badge="359612"
    )
    
    achievement(
        title = "Do It",
        description = "Complete the sign challenge in Course 6. (all 8 reds + star, no yellow coins, >=5 HP in the cold pipe)",
        points = 10,
        trigger = in_area("Course 6", 2) && disable_when(nof_coins() == (prev(nof_coins()) + 1)) && disable_when(hp() < 0x500 && prev(hp()) >= 0x500)
            && (trigger_when(repeated(8, got_red_coin())) && (trigger_when(collected_star_action_check(4))))
            || (measured(repeated(8, got_red_coin()), when=in_area("Course 6", 2)) && impossible_condition() && disable_when(nof_coins() == (prev(nof_coins()) + 1)) && disable_when(hp() < 0x500 && prev(hp()) >= 0x500)) || (never(screen_changed()) && impossible_condition()),
        id=322469,
        badge="359613"
    )
    
    achievement(
        title = "Grief Gimmick",
        description = "Collect the star 'Perilous Mountain Top' in Course 7 without getting any coins or caps, or using a cannon.",
        points = 5,
        trigger = remained_in_level("Course 7", hit=1)
            && nof_coins() == 0
            && capless()
            && never(mario_action_changed_to("in cannon"))
            && trigger_when(collected_star_action_check(6)),
        id=322470,
        badge="359614"
    )
    
    achievement(
        title = "We're Not Sonic",
        description = "Collect the star 'Sides of the Building' in Course 8 without using a bouncer.",
        points = 5,
        trigger = remained_in_level("Course 8", hit=1)
            && never(started_colliding_with_object("spring"))
            && trigger_when(collected_star_action_check(4)),
        id=322471,
        badge="359615"
    )
    
    achievement(
        title = "Stay in Your Box, Friend",
        description = "Collect the star 'Return to the Roof' in Course 9 without using a cannon.",
        points = 5,
        trigger = remained_in_level("Course 9", hit=1)
            && sublevel_id__mem == 1
            && never(mario_action_changed_to("in cannon"))
            && trigger_when(collected_star_action_check(6)),
        id=322472,
        badge="359616"
    )
    
    achievement(
        title = "Only One Side is Solid",
        description = "Starting from the star 6 platform in Course 10 (!-box tower), get to the star 5 platform (temple) without falling down.",
        points = 3,
        trigger = remained_in_level("Course 10", hit=0)
            && once(in_3d_box(-12400.0, -11500.0, 3800.0, 5000.0, -1500.0, -2100.0) && airborne() == 0)
            && never(prev(pos_y()) >= 2500.0 && pos_y() < 2500.0)
            && trigger_when(in_3d_box(-6700.0, -5700.0, 3600.0, 4500.0,-5000.0, -4000.0) && airborne() == 0),
        id=322473,
        badge="359617"
    )
    
    achievement(
        title = "Mysterious Green Box",
        description = "Collect star 7 in Course 11 without getting a metal cap.",
        points = 5,
        trigger = remained_in_level("Course 11", hit=1)
            && never(just_increased(wearing_metal_cap()))
            && trigger_when(collected_star_action_check(7)),
        id=322474,
        badge="359618"
    )
    
    achievement(
        title = "Storm the Big Inverted Building",
        description = "Collect the star 'The Castle's Legacy' in Course 12 without taking damage.",
        points = 10,
        trigger = remained_in_level("Course 12", hit=1)
            && never(just_increased(hp_decrement()))
            && never(any_of(burning_actions, a => mario_action_changed_to(a)))
            && never(just_increased(in_toxic_gas()) && wearing_metal_cap() == 0)
            && trigger_when(collected_star_action_check(1)),
        id=322475,
        badge="359619"
    )
    
    achievement(
        title = "Move Faster, Grandma!",
        description = "Collect the star 'Vanishing Race Quick!' in Course 13 without getting more than one vanish cap.",
        points = 10,
        trigger = remained_in_level("Course 13", hit=1)
            && never(collided_with_object("vanish cap", 2))
            && trigger_when(collected_star_action_check(3)),
        id=322476,
        badge="359620"
    )
    
    achievement(
        title = "Follow the Sign Again",
        description = "Get in the star 1 pipe in Course 14 without using a cannon.",
        points = 5,
        trigger = remained_in_level("Course 14", hit=1) // dying/getting stars in sub-areas will not reinitialize this hit
            && sublevel_id__mem == 1
            && never(mario_action_changed_to("in cannon"))
            && trigger_when(just_used_pipe(0x02)),
        id=322477,
        badge="359621"
    )
    
    achievement(
        title = "Jumping in the Night, Hopefully Not Re-climbing",
        description = "Collect the star 'Surfing in the Night' in Course 15 without riding a Koopa Shell.",
        points = 10,
        trigger = remained_in_level("Course 15", hit=1)
            && sublevel_id__mem == 1
            && never(object_changed_to(ridden_object(), "koopa shell"))
            && trigger_when(collected_star_action_check(3)),
        id=322478,
        badge="359622"
    )
}

challenge_achievements_1()

function challenge_achievements_2() {
    
    achievement(
    title = "Cold Tomb",
    description = "Collect the star 'Deep Dive in the Sewers' in Course 1 without riding a Koopa Shell.",
    points = 5,
    trigger = remained_in_level("Course 1", hit=1)
        && never(object_changed_to(ridden_object(), "koopa shell"))
        && trigger_when(collected_star_action_check(6)),
        id=322481,
        badge="359625"
    )
    
    achievement(
        title = "Go Everywhere Except the Intended Path",
        description = "Collect 6 red coins and the star in Course 2 while riding a Koopa Shell, all in one go.",
        points = 10,
        trigger = never(level_changed())
            && never(object_just_deactivated(ridden_object()) && intangible() == 0)
            && measured(repeated(6, object_is(ridden_object(), "koopa shell") && got_red_coin()), when=in_level("Course 2"))
            && trigger_when(object_was(ridden_object(), "koopa shell")) 
            && trigger_when(collecting_star_object("spawned star", 6)),
        id=322482,
        badge="359626"
    )
    
    c3_switch_tunnel = nth_array_object(166) // shouldn't be act dependent
    achievement(
        title = "Wondering Wallkick Tunnel",
        description = "Collect the star 'Enter the Ravaged Tunnel' in Course 3 without pressing the purple switch by the tunnel. (Return to shell block platform to try again).",
        points = 10,
        trigger = in_level("Course 3") && once(prev(level_id__mem) != course_infos["Course 3"]["value"] || (in_3d_box(12200.0, 12700.0, -1200.0, -1300.0, -1600.0, -900.0) && airborne() == 0) && object_action(c3_switch_tunnel) == 0) && never(level_changed(except_when_entering="Course 3")) && !object_is(nth_array_object(0), "mission star manager")
        && object_is(c3_switch_tunnel, "purple box switch")
        && never(just_changed(object_action(c3_switch_tunnel), 0, 1))
        && trigger_when(collected_star_action_check(4)),
        id=322483,
        badge="359627"
    )
    
    achievement(
        title = "Unblocked",
        description = "Collect star 7 in Course 3 without collecting any coins.",
        points = 10,
        trigger = remained_in_level("Course 3", hit=0)
            && nof_coins() == 0
            && trigger_when(collected_star_action_check(7)),
        id=322484,
        badge="359628"
    )
    
    achievement(
        title = "Having None of Puce",
        description = "Collect the star 'A Pinky Expedition' in Course 5 without taking damage.",
        points = 5,
        trigger = remained_in_level("Course 5", hit=1)
            && never(just_increased(hp_decrement()))
            && never(any_of(burning_actions, a => mario_action_changed_to(a)))
            && never(just_increased(in_toxic_gas()))
            && trigger_when(collected_star_action_check(1)),
        id=322485,
        badge="359629" 
    )
    
    achievement(
        title = "Victorious Ascent",
        description = "Collect the star 'Careful Footing in the Factory' in Course 6 without pressing the blue switch.",
        points = 5,
        trigger = remained_in_level("Course 6", hit=1)
            && sublevel_id__mem == 1
            && never(just_changed_to(mop_switch__mem, 2))
            && trigger_when(collected_star_action_check(6)),
        id=322486,
        badge="359630"
    )
    
    achievement(
        title = "Whynut Go the Intended Path?",
        description = "Collect the star 'Whynut at the Darknut Ruins?' in Course 7, wallkicking no more than two times. (Must enter from C6 spot)",
        points = 10,
        trigger = remained_in_level_from_warp("Course 7", 0x0A)
        && ((trigger_when(collected_star_action_check(4)) && disable_when(repeated(3, wallkicked())))
        || (measured(repeated(2, wallkicked()), when=in_level("Course 7")) && impossible_condition())),
        id=322487,
        badge="359631"
    )
    
    achievement(
        title = "Invader of Chaos",
        description = "Reach the warp walls area in Course 8 while riding a Koopa Shell.",
        points = 5,
        trigger = in_level("Course 8")
            && object_is(ridden_object(), "koopa shell")
            && trigger_when(in_3d_box(-5900.0, -6600.0, 3100.0, 3600.0, -3400.0, -4000.0)),
        id=322488,
        badge="359632"
    )
    
    achievement(
        title = "Fragments of Corroded Stardust",
        description = "Collect all 8 red coins and the star in Course 9 without using any warp.",
        points = 10,
        trigger = sublevel_id__mem == 1
            && !object_is(nth_array_object(0), "mission star manager")
            && ((disable_when(mario_action_changed_to("start teleporting"))
            && measured(repeated(8, got_red_coin()), when=in_level("Course 9"))
            && trigger_when(collected_star_action_check(3))) || (never(level_changed()) && impossible_condition())),
        id=322489,
        badge="359633"
    )
    
    achievement(
        title = "Wrong Way Wings",
        description = "Use the warp to Blue Switch Palace in Course 9 while still wearing a wing cap.",
        points = 5,
        trigger = in_level("Course 9")
            && wearing_wing_cap() != 0
            && just_used_teleporter(0x01),
        id=322490,
        badge="359634"
    )
    
    achievement(
        title = "Defective Duct",
        description = "Collect the star 'In the Dark Abyss' in Course 11 without long jumping, taking damage, or climbing on top. (Must enter from C10 spot)",
        points = 10,
        trigger = remained_in_level_from_warp("Course 11", 0x0A)
            && never(mario_action_changed_to("long jump"))
            && never(just_increased(hp_decrement()))
            && never(any_of(burning_actions, a => mario_action_changed_to(a)))
            && never(pos_y() > 7800.0 && pos_y() < 10000.0 && just_decreased(airborne()))
            && trigger_when(collected_star_action_check(3)),
        id=322491,
        badge="359635"
    )
    
    c12_panels = array_map([61, 62, 63], a => nth_array_object(a)) // independent of acts
    
    achievement(
        title = "Fast Cheese",
        description = "Press all 3 panels in Course 12 while wearing a metal cap in one go. (Must spawn panel star, cannot refresh metal cap)",
        points = 10,
        trigger = remained_in_level("Course 12", hit=0)
            && never(just_decreased(wearing_metal_cap()))
            && never(prev(wearing_metal_cap()) == 1 && just_increased(cap_time()))
            && once(wearing_metal_cap() != 0 && all_of(c12_panels, a => object_graphics_timer(a) == 0))
            && trigger_when(all_of(c12_panels, a => object_graphics_timer(a) == 2)),
        id=322492,
        badge="359636"
    )
    
    achievement(
        title = "Metal Madness",
        description = "Collect any 6 red coins in Course 13 while wearing a metal cap in one go. (Cannot refresh metal cap)",
        points = 10,
        trigger = never(level_changed())
            && never(just_decreased(wearing_metal_cap()))
            && never(prev(wearing_metal_cap()) == 1 && just_increased(cap_time())) 
            && measured(repeated(6, wearing_metal_cap() != 0 && got_red_coin()), when=in_level("Course 13")),
        id=322493,
        badge="359637"
    )
    
    achievement(
        title = "Obsolete Obstacle",
        description = "Collect the star 'An Upstairs Stroll' in Course 14 without going on the slope.",
        points = 5,
        trigger = remained_in_level("Course 14", hit=0)
            && sublevel_id__mem == 1
            && once(airborne() == 0 && in_3d_box(-3700.0, 700.0, 4750.0, 5100.0, -9600.0, -7300.0)) // checkpoint hit
            && never(just_decreased(airborne()) && in_3d_box(-300.0, -2300.0, 5100.0, 6600.0, -9600.0, -8000.0))
            && trigger_when(collected_star_action_check(4)),
        id=322494,
        badge="359638"
    )
    
    c15_switch = nth_array_object(48)
    
    achievement(
        title = "Make the Impossible Possible",
        description = "Press the purple switch in Course 15 (main area) while wearing a metal cap.",
        points = 10,
        trigger = in_area("Course 15", 0x01)
            && wearing_metal_cap() != 0
            && object_is(c15_switch, "purple box switch")
            && trigger_when(just_changed(object_action(c15_switch), 0, 1)),
        id=322495,
        badge="359639"
    )
    
    achievement(
        title = "I Can't See! I Wanna See! Hello!",
        description = "Defeat Big Boo in Course 15 using only zoomed in Mario cam inside the moon. (Switch camera at beginning, C-Up allowed)",
        points = 25,
        trigger = remained_in_level_area("Course 15", 2)
            && never(repeated(120, in_area("Course 15", 2) && !object_is(nth_array_object(0), "mission star manager") && camera_status_lakitu() != 0))
            && never(just_increased(camera_status_lakitu()))
            && never(just_increased(camera_status_c_down()))
            && never(time_stop_enabled() == 0 && just_increased(camera_status_fixed()))
            && trigger_when(object_changed_to(g_cutscene_focus__mem, "spawned star")
                && object_star_mission(g_cutscene_focus__mem) == 5),
        id=322496,
        badge="359640"
    )
    
    achievement(
        title = "Unnecessary Nerf",
        description = "Follow the sign challenge in Needle Blue Realm. (Get momentum jump star without touching floors or walls surrounding star, return to sign platform to retry)",
        points = 10,
        trigger = remained_in_level("Needle Blue Realm", hit=0)
            && once(airborne() == 0 && in_3d_box(-3800.0, -4200.0, 12500.0, 12600.0, -900.0, -3000.0)) // checkpoint hit
            && never(just_decreased(airborne()) && in_3d_box(500.0, 1400.0, 14000.0, 14300.0, -4600.0, -3800.0))
            && never(prev(pos_x()) < 1300.0 && pos_x() > 1300.0 && pos_y() > 14000.0)
            && trigger_when(collected_star_action_check(4)),
        id=322497,
        badge="359641"
    )
    
    // cp-less
    achievement(
        title = "Good End Bully World",
        description = "Complete the first part of Beautiful Skyscape (use end warp) without respawning at a checkpoint. (Go to black pipe to remove checkpoint)",
        points = 10,
        trigger = remained_in_level_no_checkpoint("Bowser 1", warp=0x0A)
            && trigger_when(just_used_teleporter(0x12)),
        id=322498,
        badge="359642"
    )
    
    achievement(
        title = "Permafrost Parkour",
        description = "Complete the first part of Frozen Dizzy Plant (use end warp) without respawning at a checkpoint OR taking damage. (Go to door in C6 to remove checkpoint)",
        points = 25,
        trigger = remained_in_level_no_checkpoint("Bowser 2", warp=0x0A)
            && never(just_increased(hp_decrement()))
            && never(any_of(burning_actions, a => mario_action_changed_to(a)))
            && trigger_when(just_used_teleporter(0x01)),
        id=322499,
        badge="359643"
    )
    
    achievement(
        title = "How to Get Around?",
        description = "Complete the second part of Scepter Sanctum (panel trial) without using a cannon.",
        points = 10,
        trigger = remained_in_level("Final Fight", hit=1)
            && never(mario_action_changed_to("in cannon"))
            && trigger_when(collected_star_action_check()),
        id=322500,
        badge="359644"
    )
    
    achievement(
        title = "Actual Checkpointless God",
        description = "Complete the Devour Realm (get star) without respawning at a checkpoint. (Must reset game to remove checkpoint)",
        points = 50,
        trigger = remained_in_level_no_checkpoint("Devour Realm")
            && trigger_when(collected_star_action_check()),
        id=322501,
        badge="359645"
    )
    
    hundred_coin_courses = ["Dutish Prism", "Sizzling Sun", "Bloody Moon"]
    hundred_coin_titles = ["BroDute Retirement Fund", "Divine-Demonic Doubloons of Hellfire", "Climax of the Bloody Dream"]
    hundred_coin_ids = [322502, 322503, 322504]
    hundred_coin_badges=["359646", "359647", "359648"]
    
    for i in range(0, 2) {
        achievement(
            title = hundred_coin_titles[i],
            description = format("Collect 100 coins in {0}.", course_infos[hundred_coin_courses[i]]["full name"]),
            points = 10,
            trigger = in_level(hundred_coin_courses[i])
                && prev(nof_coins()) < 100
                && nof_coins() >= 100,
            id=hundred_coin_ids[i],
            badge=hundred_coin_badges[i]
        )
    }
    
    achievement(
        title = "Don't Follow the Sign",
        description = "Defeat Remnant Whomp without healing. (Must get star)",
        points = 10,
        trigger = remained_in_level_area("End Cake Picture", 0x03)
            && never(hp() > prev(hp()))
            && trigger_when(collected_star_action_check()),
        id=322505,
        badge="359649"
    )
    
    achievement(
        title = "Nontrivial Path",
        description = "In Course 5, touch the sign that tells you to wallkick up to the yellow coin, then do as it says. (Must land on the side with the coin)",
        points = 5,
        trigger = remained_in_level("Course 5", hit=0)
            && once(object_num_collided_objects(mario_object()) >= 1
                && object_is(object_nth_collided_object(mario_object(), 1), "sign")
                && object_beh_param_2(object_nth_collided_object(mario_object(), 1)) == 0x1E)
            && never(pos_y() > 4150.0 && pos_x() > -700.0 && just_decreased(airborne()))
            && trigger_when(in_3d_box(-2450.0, -1200.0, 5700.0, 5800.0, -7050.0, -6200.0) && just_decreased(airborne())),
        id=322479,
        badge="359623"
    )
    
    achievement(
        title = "In the Back of the Desert",
        description = "Collect the star 'Pyramidal Return' in Course 10 without respawning at a checkpoint.",
        points = 5,
        trigger = remained_in_level_no_checkpoint("Course 10")
            && trigger_when(collected_star_action_check(1)),
        id=322480,
        badge="359624"
    )
}

challenge_achievements_2()

// LBs
leaderboard(
    title = "Scepter Sanctum Panels Speedrun",
    description = "Starting from the 2nd part of Scepter Sanctum (no checkpoints), collect the (fake) star as fast as possible.",
    start = remained_in_level_no_checkpoint("Final Fight"),
    cancel = level_changed(),
    submit = in_level("Final Fight") && collected_star_action_check(),
    value = measured(effective_mario_object() != 0),
    
    format="FRAMES",
    lower_is_better = true,
    id=66273
)

leaderboard(
    title = "Devour Realm Speedrun",
    description = "Complete the Devour Realm as fast as possible, without respawning at a checkpoint.",
    start = remained_in_level_no_checkpoint("Devour Realm"),
    cancel = level_changed(),
    submit = in_level("Devour Realm") && collected_star_action_check(),
    value = measured(effective_mario_object() != 0),
    
    format="FRAMES",
    lower_is_better = true,
    id=66274
)

leaderboard(
    title = "Cheater%",
    description = "Attempt to open the Key 2 door while having only Key 1, or the Key 1 door while having only Key 2. (Must trigger textbox) (Timer begins on start-up, shown on key get) (New file only) (Keys are lost when opening their respective doors)",
    start = new_file_hit() && warp_dest_level_area() > 0 && ((pressed_switch__mem("key 2 door") == 0 && just_increased(pressed_switch__mem("key 1 strict"))) || (pressed_switch__mem("key 1 door") == 0 && just_increased(pressed_switch__mem("key 2 strict")))),
    cancel = __ornext(just_changed_any(file_num__mem) || just_decreased(pressed_switch__mem("key 1 strict")) || just_decreased(pressed_switch__mem("key 2 strict"))),
    submit = just_changed_to(dialog_id__mem, 0x17),
    value = num_vblanks__mem,
    
    format="FRAMES",
    lower_is_better = true,
    id=66294
)

// RP

general_level_dict = {
    0x0000: "outside ruined Peach's Castle", // OW1
    0x1001: "outside ruined Peach's Castle", // OW1
    0x1002: "visiting the Ocean Temple", // OW1
    0x1003: "in a rift between time and space", // OW1
    0x0601: "in the fast travel area", // OW2
    0x0602: "in restored Peach's Castle",
    0x0603: "at the end of Scepter Sanctum",
    0x0604: "respawning somewhere",
    0x1a01: "either respawning or celebrating getting a star", // OW3
    0x1a02: "in the green switch fast travel area",
    0x1a03: "in the blue switch fast travel area",
    0x1a04: "about to open the overworld cannon",
    
    0x0901: "platforming in Doubtful Creek Town",
    0x1801: "hopefully not getting lost in Fading City",
    0x0C01: "not getting snowed in Firestar Canyon",
    0x0501: "visiting Thwomps in Timid Derped Town",
    0x0401: "exploring the corroded Acidic Marshland",
    0x0701: "thinking about Ultra Blocks in Frigid Factory",
    0x0702: "on the verge of freezing in a cold pipe",
    0x1601: "purifying his soul in Frostbite Swamp",
    0x0801: "excavating the Collapsed Mines",
    0x1701: "rummaging what's left of Atrophied Mansion",
    0x1702: "in somewhere secret",
    0x0A01: "doing spooky jumps in Ominous Excavation Town",
    0x0B01: "ascending the up-scaled Heat Rash Canyon",
    0x2401: "storming through Thunder Blaze Horizon",
    0x0D01: "in Plagued Cliffs taken over by Shroobs",
    0x0E01: "at the broken Dream Fountain in Mystified Mountains",
    0x0E02: "taking the star needle quiz",
    0x0E03: "on an inverted journey",
    0x0E04: "on an inverted journey",
    0x0F01: "getting stars in outer space in Nightsky Citadel",
    0x0F02: "on a ghost hunt inside the moon",
    
    0x1C02: "triangulating his jumps in Dutish Prism",
    0x1D01: "on a plagued moon in Green Switch Palace",
    0x1D02: "in the gloomy Blue Switch Palace",
    0x1201: "sunsetting his journey in Sizzling Sun",
    
    0x1B01: "in the Remnant Abyss", // slide
    0x1B02: "in the Remnant Abyss", // slide
    0x1B03: "fighting Remnant Wiggler", // slide
    0x1B05: "in the Remnant Abyss", // slide
    0x1B06: "in the Remnant Abyss", // slide
    0x1401: "traversing a shredded world in blue (Needle Blue Realm)", // aquarium
    0x1F02: "enacting revenge on King Boo in Bloody Moon", // clouds
    0x1903: "fighting Remnant Whomp", // end cake picture
    0x1904: "fighting Remnant Bob-omb",
    0x1907: "in the Remnant Abyss",
    
    0x1101: "above the clouds in Beautiful Skyscape",
    0x1E01: "about to get Key 1 in Beautiful Skyscape",
    0x1301: "making colors work in Frozen Dizzy Plant",
    0x2101: "fighting corrupted Eyerok in Frozen Dizzy Plant",
    0x1502: "in an overworld lost in time",
    0x2201: "facing the trials of Scepter Sanctum"
}

level__lookup = rich_presence_lookup("Levels", warp_dest_level_area(), general_level_dict, "in an unbeknownst location")

stars__value = rich_presence_value("Number", nof_stars())
lives__value = rich_presence_value("Number", (byte(nof_lives__addr) ) - (bit7(nof_lives__addr) * 256))
level_test__value = rich_presence_value("Number", warp_dest_level_area())

file__lookup  = rich_presence_lookup("File", file_num__mem, {
    0x01: "A", 0x02: "B", 0x03: "C", 0x04: "D"
}, "??")

rich_presence_conditional_display(in_title_screen(), "Getting ready for a legendary collab adventure. (Title Screen)")
rich_presence_conditional_display(in_file_select(), 
    "Getting ready for a legendary collab adventure. (File Select)")
rich_presence_conditional_display(
    new_file_hit() && level_id__mem != 1 && __ornext(music_id__mem != 0x21 || effective_mario_object() != 0), // both are false on file select, including after game over
      "(New File) Mario-{2} is {0} with {1}⭐ [🟢{4}] [🔵{5}] [🟡{6}] [🔴{3}] {7}", level__lookup, stars__value, file__lookup, 
        rich_presence_lookup("Switch", pressed_switch__mem("red"), {1:"▣"}, "▢"),
        rich_presence_lookup("Switch", pressed_switch__mem("green"), {1:"▣"}, "▢"),
        rich_presence_lookup("Switch", pressed_switch__mem("blue"), {1:"▣"}, "▢"),
        rich_presence_lookup("Switch", pressed_switch__mem("yellow"), {1:"▣"}, "▢"),
        rich_presence_lookup("Checkpoint", checkpoint_flag__mem, {1: "(Checkpoint active)"}, "")
    )
rich_presence_conditional_display(
    level_id__mem != 1 && (music_id__mem != 0x21 || effective_mario_object() != 0), // both are false on file select, including after game over
      "Mario-{2} is {0} with {1}⭐ [🟢{4}] [🔵{5}] [🟡{6}] [🔴{3}] {7}", level__lookup, stars__value, file__lookup, 
        rich_presence_lookup("Switch", pressed_switch__mem("red"), {1:"▣"}, "▢"),
        rich_presence_lookup("Switch", pressed_switch__mem("green"), {1:"▣"}, "▢"),
        rich_presence_lookup("Switch", pressed_switch__mem("blue"), {1:"▣"}, "▢"),
        rich_presence_lookup("Switch", pressed_switch__mem("yellow"), {1:"▣"}, "▢"),
        rich_presence_lookup("Checkpoint", checkpoint_flag__mem, {1: "(Checkpoint active)"}, "")
    )
rich_presence_display("On a legendary collab adventure.")