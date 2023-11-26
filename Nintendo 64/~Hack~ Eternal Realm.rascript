// ~Hack~ Eternal Realm
// #ID = 27406
// Made in RATools v1.12.2

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
    "TITLE SCREEN GEO":     0x104640,

    "SAVE DATA":    (0x207700 - 0x70),
    
    "MUSIC ID":     0x22261e,

    "CURRENT DEMO INPUT":   0x32d5f0,
    "COLLECTED COURSE ID":  0x32dd83,
    "COLLECTED STAR ID":    0x32dd87, // 1-indexed
    "CURRENT AREA":         0x32ddcc, // POINTER
    "CREDITS ENTRY":        0x32ddd0,
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
    "WARP OP":          0x33b250,
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
    
    "CHECKPOINT FLAG":  0x400010,
}

// double-check this list between hacks, custom objects can shift things...
behaviour_script__values = { 
    "koopa shell":              0x800ED0BC,
    "blue coin for block":      0x800ED708,
    
    "stationary 1-up":  0x800EF1FC,
    
    "file manager":     0x8008FD58,
    "mission star manager": 0x800EE1C8,
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

function in_toxic_gas() => bit0(mario_field("input") + 1)

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
    "neutral enter":               0x00001932,
    
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
    
    "heaved":                      0x010208BE,
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
    "type":             0x02, // word
    "related object":   0x2C // dword (pointer to object, if applicable)
}
surface__sizeof = 0x30

function surface_field(base, field) => struct_field(surface__struct, base, field)

function surface_type(addr) => word(surface_field(addr, "type"))
function surface_object(addr) => tbyte(surface_field(addr, "related object"))

function qslg() => mario_action_changed_to("ledge grab") && surface_type(mario_floor_tri()) == 0x23 // 0x23 = instant quicksand

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

warp_op__addr = offsets["WARP OP"]
warp_op__mem = word(warp_op__addr)
//https://github.com/n64decomp/sm64/blob/master/src/game/level_update.h#L14
function warp_op_death() => __ornext(any_of([0x12, 0x13], a => just_changed_to(warp_op__mem, a)))

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
    "pos x":                 0xA0,  // float (double check address)
    "pos y":                 0xA4,  // float (double check)
    "pos z":                 0xA8,  // float (double check)
    "vel x":                 0xAC,  // float (double check address)
    "vel y":                 0xB0,  // float (double check)
    "vel z":                 0xB4,  // float (double check)
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

function object_pos_x(addr) => float(object_field(addr, "pos x"))
function object_pos_y(addr) => float(object_field(addr, "pos y"))
function object_pos_z(addr) => float(object_field(addr, "pos z"))
function object_vel_x(addr) => float(object_field(addr, "vel x"))
function object_vel_y(addr) => float(object_field(addr, "vel y"))
function object_vel_z(addr) => float(object_field(addr, "vel z"))

function in_3d_box(x1, x2, y1, y2, z1, z2, obj_addr=0, check_edges=0) {
    cond = always_true()
    
    x_pos = pos_x()
    y_pos = pos_y()
    z_pos = pos_z() // mario coords are default
    if (obj_addr != 0) { // assume check bounding box for object whose address is passed in
        x_pos = object_pos_x(obj_addr)
        y_pos = object_pos_y(obj_addr)
        z_pos = object_pos_z(obj_addr)
    }
    
    for coord in [[x_pos, x1, x2],
                  [y_pos, y1, y2],
                  [z_pos, z1, z2]] {
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
function object_teleporter_id(addr) => word(object_field(addr, "warp destination"))

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

music_tempo__mem = word(music_id__addr + 2)

dialog_id__addr = offsets["DIALOGUE ID"]
dialog_id__mem = word(dialog_id__addr)

g_red_coins_collected__addr = offsets["RED COINS COLLECTED"]
g_red_coins_collected__mem = byte(g_red_coins_collected__addr)

g_cutscene_focus__addr = offsets["CUTSCENE FOCUS"]
g_cutscene_focus__mem = tbyte(g_cutscene_focus__addr) // pointer to object

current_area__mem = tbyte(offsets["CURRENT AREA"])

function effective_mario_object() => tbyte(offsets["EFFECTIVE MARIO OBJECT"])

g_current_demo_input__addr = offsets["CURRENT DEMO INPUT"]
g_current_demo_input__mem = dword(g_current_demo_input__addr)

time_stop_state__addr = offsets["TIME STOP STATE"]
function time_stop_enabled() => bit(1, time_stop_state__addr)

checkpoint_flag__addr = offsets["CHECKPOINT FLAG"]
checkpoint_flag__mem = byte(checkpoint_flag__addr)

checkpoint_coord__mems = {
    "x": float(checkpoint_flag__addr + 4),
    "y": float(checkpoint_flag__addr + 8),
    "z": float(checkpoint_flag__addr + 12)
}

function course_meta(value, sublevel_values, full_name, clean_name="0") {
    if (clean_name == "0")
        return {"value": value, "sublevel values": sublevel_values, "full name": full_name, "clean name": full_name}
    return {"value": value, "sublevel values": sublevel_values, "full name": full_name, "clean name": clean_name}
}

course_infos = {
    "Castle Grounds":      course_meta(0x10, [-1],   "the overworld"), // Castle Grounds
    //"Inside Castle":       course_meta(0x06, [-1], "the second overworld"), // Inside Castle
    //"Castle Courtyard":    course_meta(0x1a, [-1], "the third overworld"), // Castle Courtyard
    
    "Course 1":         course_meta(0x09, [-1],   "Cliffside Townscape"),
    "Course 2":         course_meta(0x18, [-1],   "Glacial Island Outpost"),
    "Course 3":         course_meta(0x0c, [-1],   "Hot Spring Heights"),
    "Course 4":         course_meta(0x05, [-1],   "Violet Valley"),
    "Course 5":         course_meta(0x04, [-1],   "Collapsed Fortress"),
    //"Course 6":         course_meta(0x07, [-1],   "Forlorn Cove"),
    //"Course 7":         course_meta(0x16, [-1],   "Skies of Hope"),
    //"Course 8":         course_meta(0x08, [-1],   "Volcanic Midway"),
    //"Course 9":         course_meta(0x17, [-1],   "Deserted Murky Factory"),
    //"Course 10":        course_meta(0x0a, [-1],   "Remnant of the Boo"),
    //"Course 11":        course_meta(0x0b, [-1],   "Dismal Industrial Basement"),
    //"Course 12":        course_meta(0x24, [-1],   "Day of Endless Rain"),
    //"Course 13":        course_meta(0x0d, [-1],   "Checkered Parkour Fortress"),
    //"Course 14":        course_meta(0x0e, [-1],   "Illustrious Peril"),
    //"Course 15":        course_meta(0x0f, [-1],   "Symmetrical Mossy Ruins"),
    
    //"Slide":            course_meta(0x1b, [-1],   "Starry Night Slide"),
    //"Aquarium":         course_meta(0x14, [-1],   "Ethereal Sunrise"),
    "End Cake Picture": course_meta(0x19, [-1],   "the ending picture"),
    "Cloud Stage":      course_meta(0x1f, [-1],   "Cavern of Corruption"), // WC
    
    //"Bowser 1":         course_meta(0x11, [-1],   "Bowser's Burning Junkyard"),
    "Key":            course_meta(0x1e, [-1],   "Temple of the Shells"),
    //"Bowser 2":         course_meta(0x13, [-1],   "Neo Ruined Kingdom"),
    //"Key 2":            course_meta(0x21, [-1],   "Neo Ruined Kingdom"),
    "Bowser":         course_meta(0x15, [-1],   "Station Backlight"),
    //"Final Fight":      course_meta(0x22, [-1],   "Stronghold of Lost Wisdom"),
    
    "Metal Cap":        course_meta(0x1c, [-1],   "Pinksand Cavern"),
    //"Wing Cap":         course_meta(0x1d, [-1],   "Cap Training Grounds"),
    "Vanish Cap":       course_meta(0x12, [-1],   "Tiktok Burger"),
}

function in_title_screen() => area_geo_layout(current_area__mem) == offsets["TITLE SCREEN GEO"]
function in_file_select() => object_is(nth_array_object(1), "file manager")

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

function in_intro_or_file_select() => any_of([0x21], a => music_id__mem == a)

function common_in_file_check() => !in_intro_or_file_select() && level_id__mem != 1 && g_current_demo_input__mem == 0

//
//  Cheevs
//

// Milestones

function star_milestone_trigger(num_stars) {
    return measured(nof_stars() == num_stars, when=!in_file_select())
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
hack_switches = ["red", "blue", "green"]

function all_switches_trigger() {
    switches_now = sum_of(hack_switches, a => pressed_switch__mem(a))
    switches_prev = sum_of(hack_switches, a => pressed_switch__mem(a, delta=1))
    
    return level_id__mem == prev(level_id__mem) // to prevent switching files after the ending picture puts you back to the title screen...
    && file_num__mem == prev(file_num__mem)
    && measured(switches_now == length(hack_switches))
    && switches_prev == (length(hack_switches) - 1)
    && switches_prev != length(hack_switches)
}

achievement(
    title = "SomeBro Switcheroo",
    description = "Press the red, green, and blue !-switches.",
    points = 10,
    trigger = all_switches_trigger()
)

achievement(
    title = "Slain Shells",
    description = "Collect the key in Temple of the Shells.",
    points = 25,
    trigger = in_level("Key") && collected_star_action_check()
)

achievement(
    title="You Passed the Light Kaizo",
    description="Reach the ending screen beyond the key door.",
    points=10,
    trigger=never(level_changed())
        && tally(300, in_level("End Cake Picture")) // some timing so the screenshot happens when the pic is fully faded in
)

// c o u r s e  s t a r s

// let's obfuscate the star names, just to be safe...

ordinals = ["first", "second", "third", "fourth", "fifth", "sixth", "seventh"]

blank = ""
course_star_cheev_titles = [
    {"Course 1": 
    ["Great Town View", "Simple Slopes", "Inverted Cliffhouse Climb", "Sparkly Fiery Path", "Speedy Sand Ride", "Lock Yourself Inside With Vanish Cap", "The Seventh Path"]}, {"Course 2": 
    ["More Teamwork With the Enemy 👏", "Crystallized Wallkicks", "Stick the High-Speed Landings", "Crossing Over Wallkicks", "The Arrows Know", "Stony Wallkicks", "Disaster. Quest. Tree."]},
    {"Course 3": 
    ["Surfing in the Mine", "Blazing Hot Spring Bath", "Sliding to Victory", "The Exclusive Spring", "Only Red Coin Star of the Hack!!", "Close Enough to Geysers", "Abandoned Excavation"]},
    {"Course 4": 
    ["Butt-Sliding Bounce Party", "Slide-Kicking Bounce Party", "Gotta Go Through a Lot of Hoops for This One", "Sweeping Through the Pipeline", "Left Side Wallkicks", "Race Back to the Start!", "Look Up Somewhere"]},
    {"Course 5": 
    ["Kicking and Diving on Slopes", "Conquer the Tiny Slopes", "Preserving Speed on Quicksand", "QSLG Roller-Coaster", "Zooming by Hangable Ceilings", "The Speed Hanging Tunnel", "Simple Lavaboosts"]},
    
    
    {"Metal Cap":
    ["Bouncing on Exposed Lava Pipes", "Optimal Lavabounce Speed"]},
    {"Vanish Cap":
    ["Wallkicks Next to the Switch", "The Midair Cap Grab"]},
    {"Cloud Stage": 
    ["Follow Directions on the Wall", "Tight Tunnel Flying"]},

    {"Bowser":
    ["Cannon Firing", "Jumping Box Mayhem", "Triple Cap Triathlon"]},
    
    {"Castle Grounds": ["Knock Knock", "Boosting Through Lava Tunnels", "Flying Tunnel Trauma"]},
]

course_star_titles = {
    "Course 1": 
    ["Lone Town Stroll", "Bustling Skyscrapers", "Ridgeview Cliffhouse", "Glitter Road", "Cliffside Shelling", "Guarded by Bars"],
    "Course 2":
    ["Goomba Kidnapping", "Yummy Crystal Candy Spread", "Sliding N' Kicking Through the Towers", "Iceway Ascension", "Arrow Ascension", "Trail of Stone"],
    "Course 3":
    ["Shell of a Mine", "Metal Mario Waterfall Fun", "Relatively Cumbersome Construction", "Reserved Reservoir", "Cliffy Coins", "These are Supposed to be Geysers"],
    "Course 4":
    ["Slip Slidin' Away", "Slip Slidin' Away 2", "Serendipitous Scaffolding", "Piranha Plant Pipeline", "Slightly Less Serendipitous Scaffolding", "Famish Cap Required!"],
    "Course 5":
    ["Beams of Extreme", "Redslope Fortress", "Slowsand Laser Jumps", "Quicksand Laser Jumps", "Climbing and Kicking", "Climbing and Superjumping"],
}

function is_numbered_course(title) {
    for i in range(1, 15) {
        if (title == format("Course {0}", i))
            return true
    }
    return false
}

function stars_meta(points, ids=[0,0,0,0,0,0,0,0], badge_ids=["0","0","0","0","0","0","0","0"]) => { "points": points, "ids": ids, "badge_ids": badge_ids }

course_stars_meta = {
    "Course 1":  stars_meta([3, 4, 5, 4, 5, 5, 3], ids=sequence(322236, 7), badge_ids=sequence(359380, 7, badge=1)),
    "Course 2":  stars_meta([10, 10, 5, 10, 5, 10, 5], ids=sequence(322243, 7), badge_ids=sequence(359387, 7, badge=1)),
    "Course 3":  stars_meta([5, 3, 5, 5, 10, 3, 2], ids=sequence(322250, 7), badge_ids=sequence(359394, 7, badge=1)),
    "Course 4":  stars_meta([10, 10, 10, 5, 5, 10, 3], ids=sequence(322257, 7), badge_ids=sequence(359401, 7, badge=1)),
    "Course 5":  stars_meta([10, 10, 10, 10, 5, 5, 2], ids=sequence(322264, 7), badge_ids=sequence(359408, 7, badge=1)),
    
    "Metal Cap": stars_meta([5, 5], ids=sequence(322341, 5), badge_ids=sequence(359485, 5, badge=1)),
    "Vanish Cap":stars_meta([5, 5], ids=sequence(322346, 3), badge_ids=sequence(359490, 3, badge=1)),
    "Cloud Stage":    stars_meta([10, 10], ids=sequence(322382, 6), badge_ids=sequence(359526, 6, badge=1)), // WC

    "Bowser":  stars_meta([5, 10, 10], ids=sequence(322360, 6), badge_ids=sequence(359504, 6, badge=1)),
    
    "Castle Grounds": stars_meta([5, 5, 5]),
}

function course_star_achievements(disable_ids=0) {
    // put in func to avoid namespace pollution
    for inf in course_star_cheev_titles {
        for course in inf {
            title_arr = inf[course]
            
            for i in range(0, length(title_arr) - 1) {
            title = title_arr[i]
            
            if (title != blank) {
                
                desc = ""
                if (is_numbered_course(course)) {
                    base_desc = "Collect {0} in {1}."
                    if (i == 6) { // star 7
                        star_str = "the bonus star"
                        if (course == "Course 3")
                            star_str = "the bonus star (or 100s)"
                    } else {
                        star_str = format("the star '{0}'", course_star_titles[course][i])
                    }
                    desc = format(base_desc, star_str, course_infos[course]["clean name"])
                }
                else
                    desc = format("Collect this star in {0}.", course_infos[course]["clean name"])

                if (disable_ids == 0) {
                    achievement(
                    title = title,
                    description = desc,
                    points = course_stars_meta[course]["points"][i],
                    trigger = in_level(course) && collected_star_action_check(star_index = i+1),
                    id=course_stars_meta[course]["ids"][i],
                    badge=course_stars_meta[course]["badge_ids"][i]
                    )
                } else {
                    achievement(
                    title = title,
                    description = desc,
                    points = course_stars_meta[course]["points"][i],
                    trigger = in_level(course) && collected_star_action_check(star_index = i+1)
                    )
                }
                
                }
            }
        }
    }
}

course_star_achievements(disable_ids=1)

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
    mushies_meta("Course 1", "Lone Cliffside Shroom",
        "Collect the 1-up mushroom in {0}.", 1,
        [{"type": "stationary", "count": 1}],
        level_check=remained_in_level("Course 1", hit=0)),
    mushies_meta("Course 2", "Delicious Rock Candy Shroom",
        "Collect the 1-up mushroom in {0}.", 1,
        [{"type": "stationary", "count": 1}],
        level_check=remained_in_level("Course 2", hit=0)),
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

// side challenge time...

achievement(
    title = "You Can Tell That Coin Stars Were Scrapped",
    description = "Collect 70 coins in Course 1.",
    points = 10,
    trigger = in_level("Course 1")
            && prev(nof_coins()) < 70
            && nof_coins() >= 70
)

achievement(
    title = "Shell Smuggler",
    description = "Reach the Star 7 platform in Course 1 while riding a Koopa Shell.",
    points = 5,
    trigger = in_level("Course 1")
        && object_is(ridden_object(), "koopa shell")
        && trigger_when(airborne() == 0)
        && trigger_when(in_3d_box(13000.0, 11000.0, -800.0, -900.0, -1500.0, -4000.0))
)

achievement(
    title = "Heartless Ascension",
    description = "Collect the star 'Iceway Ascension' OR 'Arrow Ascension' in Course 2 without taking damage.",
    points = 10,
    trigger = remained_in_level("Course 2", hit=1)
        && never(just_increased(hp_decrement()))
        && never(any_of(burning_actions, a => mario_action_changed_to(a)))
        && ((trigger_when(collected_star_action_check(4))) || trigger_when(collected_star_action_check(5)))
)

achievement(
    title = "Real Enemy is the Camera",
    description = "Collect the star 'Goomba Kidnapping' in Course 2 using only Mario cam. (Switch cameras at beginning)",
    points = 10,
    trigger = remained_in_level("Course 2", hit=1)
        && never(repeated(120, in_level("Course 2") && !object_is(nth_array_object(0), "mission star manager") && camera_status_lakitu() != 0))
        && never(!mario_action_is("airborne spawn") && just_increased(camera_status_lakitu()))
        && never(time_stop_enabled() == 0 && just_increased(camera_status_fixed())) // reading signs won't fail the achievement
        && trigger_when(collected_star_action_check(1))
)

achievement(
    title = "Still a Metal Mining Mario",
    description = "Collect Star 7 in Course 3 while wearing a metal cap.",
    points = 5,
    trigger = in_level("Course 3")
        && prev(wearing_metal_cap()) != 0
        && trigger_when(collected_star_action_check(7))
)

achievement(
    title = "Clean Construction Sweep",
    description = "Collect the star 'Relatively Cumbersome Construction' in Course 3 without respawning at a checkpoint. (Must get star or 'Exit Course' in pause menu to remove checkpoint)",
    points = 5,
    trigger = remained_in_level_no_checkpoint("Course 3")
        && trigger_when(collected_star_action_check(3))
)

achievement(
    title = "Detour to the Pipeline",
    description = "Collect the star 'Piranha Plant Pipeline' in Course 4 without long jumping.",
    points = 10,
    trigger = remained_in_level("Course 4", hit=1)
        && never(mario_action_changed_to("long jump"))
        && trigger_when(collected_star_action_check(4))
)

achievement(
    title = "Up and Down the Valley",
    description = "Collect the star 'Slip Slidin' Away' in Course 4 without respawning at a checkpoint. (Must get star or 'Exit Course' in pause menu to remove checkpoint)",
    points = 10,
    trigger = remained_in_level_no_checkpoint("Course 4")
        && trigger_when(collected_star_action_check(1))
)

achievement(
    title = "Avoiding the Pillars",
    description = "Collect Star 7 in Course 5 without getting any blue coins.",
    points = 5,
    trigger = remained_in_level("Course 5", hit=1)
        && never(started_colliding_with_object("blue coin for block"))
        && trigger_when(collected_star_action_check(7))
)

achievement(
    title = "Timing Champion",
    description = "Collect the star 'Quicksand Laser Jumps' in Course 5 without respawning at a checkpoint. (Must get star or 'Exit Course' in pause menu to remove checkpoint) (Intended way only)",
    points = 10,
    trigger = remained_in_level_no_checkpoint("Course 5")
        && trigger_when(once(in_3d_box(-4000.0, -4300.0, 1800.0, 2300.0, -12000.0, -8000.0) && qslg()))
        && trigger_when(collected_star_action_check(4))
)

achievement(
    title = "Switch-less Exploration [m]",
    description = "Collect any star in Pinksand Cavern before having pressed the green !-switch.",
    points = 5,
    trigger = in_level("Metal Cap")
        && pressed_switch__mem("green") == 0
        && trigger_when(collected_star_action_check())
)

achievement(
    title = "Actually Follow the Walls",
    description = "Collect the cannon star in Station Backlight the intended way, by wallkicking through the entire structure.",
    points = 10,
    trigger = remained_in_level("Bowser", hit=0)
        && once(in_3d_box(-1500.0, -800.0, 0.0, 2500.0, 8000.0, 9000.0) && wallkicked())
        && collected_star_action_check(1)
)

general_level_dict = {
    0x0901: "on a leisurely stroll through Cliffside Townscape",
    0x1801: "checking up on the Glacial Island Outpost",
    0x0C01: "digging for stars in Hot Spring Heights",
    0x0501: "sliding around in Violet Valley",
    0x0401: "storming the Collapsed Fortress",
    
    0x0000: "in the galactic overworld",
    0x1001: "in the galactic overworld",

    0x1C01: "bouncing around in Pinksand Cavern", // MC
    0x1201: "doing vanishing parkour in Tiktok Burger", // VC
    0x1F01: "flying through the Chasm of Corruption", // WC
    
    0x1E01: "brawling with the shells",

    0x1501: "taking on Station Backlight",
    
    0x1901: "at the end of his journey through the Eternal Realm"
}

level__lookup = rich_presence_lookup("Levels", warp_dest_level_area(), general_level_dict, "in an unbeknownst location")

stars__value = rich_presence_value("Number", nof_stars())
lives__value = rich_presence_value("Number", (byte(nof_lives__addr) ) - (bit7(nof_lives__addr) * 256))
level_test__value = rich_presence_value("Number", warp_dest_level_area())

file__lookup  = rich_presence_lookup("File", file_num__mem, {
    0x01: "A", 0x02: "B", 0x03: "C", 0x04: "D"
}, "??")

coins__value = rich_presence_value("Number", nof_coins())

rich_presence_conditional_display(in_title_screen(), "Getting ready for a short light kaizo adventure. (Title Screen)")
rich_presence_conditional_display(in_file_select(), 
    "Getting ready for a short light kaizo adventure. (File Select)")
rich_presence_conditional_display(
    level_id__mem != 1 && music_id__mem != 0x21 || effective_mario_object() != 0, // both are false on file select, including after game over
      "Mario-{2} is {0} with {1}⭐ Switches:[{3}{4}{5}]", level__lookup, stars__value, file__lookup, 
        rich_presence_lookup("SwitchR", pressed_switch__mem("red"), {1:"🟥"}, ""),
        rich_presence_lookup("SwitchG", pressed_switch__mem("green"), {1:"🟩"}, ""),
        rich_presence_lookup("SwitchB", pressed_switch__mem("blue"), {1:"🟦"}, "")
    )
rich_presence_display("On a short light kaizo adventure.")