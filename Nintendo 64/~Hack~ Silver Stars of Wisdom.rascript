// ~Hack~ Silver Stars of Wisdom
// #ID = 24302
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
    
    "LEVEL INDEX":      0x33bac8,
    "WARP DEST":        0x33b248,
    "WARP OP":          0x33b250,
    "TIME COUNTING":    0x33b25e,
    "HUD FLAGS":        0x33b268,   //  https://github.com/n64decomp/sm64/blob/1372ae1bb7cbedc03df366393188f4f05dcfc422/src/game/level_update.h#L91
    "HUD TIMER":        0x33b26e,
    
    "WARP TRANSITION":  0x33bab0,
    "MISSION ACTIVE":   0x33baca,
    
    "MARIO STRUCT":     0x33b170,
    "OBJECT ARRAY":     0x33d488,
    
    "EFFECTIVE MARIO OBJECT":   0x361158,
    "RED COINS COLLECTED":  0x3613fd,
    
    "CHECKPOINT FLAG":  0x400010,
}

// double-check this list between hacks, custom objects can shift things...
behaviour_script__values = { 
    "purple switch structure":  0x800EC598,
    "purple switch boxes":      0x800EC5DC,
    "large cork box":           0x800EC610,

    "koopa shell":              0x800ED06C,
    "baby penguin":             0x800ED218,
    "blue coin for block":      0x800ED6B8,
    "mission star manager":     0x800EE178,
    "bob-omb":      0x800EE2A4,
    "secret number":0x800EF04C,

    "mr i":         0x800EB184, // does not distinguish between small or big

    "teleporter":   0x800EB88C,
    "warp":         0x800EB8B0,
    "warp pipe":    0x800EB8D0,
    
    "impartial 1-up":   0x800EF10C,
    "stationary 1-up":  0x800EF1AC,
    
    "file manager":     0x8008FD08,
    
    "spawned star":     0x800EEF94,
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
    "single jump":                 0x03000880,
    "double jump":                 0x03000881,
    "triple jump":                 0x01000882,
    "long jump":                   0x03000888, // slow or faste
    "air sitting":                 0x0300088E,
    
    "ledge grab":                  0x0800034B,
    
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

function airborne() => bit3(mario_current_action__addr + 1)
function on_pole() => bit4(mario_current_action__addr + 2)

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
    z_pos = pos_z()
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
    "Castle Grounds":      course_meta(0x10, [-1],   "the first overworld"), // Castle Grounds
    "Inside Castle":       course_meta(0x06, [-1], "the second overworld"), // Inside Castle
    "Castle Courtyard":    course_meta(0x1a, [-1], "the third overworld"), // Castle Courtyard
    
    "Course 1":         course_meta(0x09, [-1],   "Blue Valley of Solace"),
    "Course 2":         course_meta(0x18, [-1],   "Cold Cavern"),
    "Course 3":         course_meta(0x0c, [-1],   "Triassic Playground"),
    "Course 4":         course_meta(0x05, [-1],   "Cosmic Lounge"),
    "Course 5":         course_meta(0x04, [-1],   "Abandoned Excavation"),
    "Course 6":         course_meta(0x07, [-1],   "Forlorn Cove"),
    "Course 7":         course_meta(0x16, [-1],   "Skies of Hope"),
    "Course 8":         course_meta(0x08, [-1],   "Volcanic Midway"),
    "Course 9":         course_meta(0x17, [-1],   "Deserted Murky Factory"),
    "Course 10":        course_meta(0x0a, [-1],   "Remnant of the Boo"),
    "Course 11":        course_meta(0x0b, [-1],   "Dismal Industrial Basement"),
    "Course 12":        course_meta(0x24, [-1],   "Day of Endless Rain"),
    "Course 13":        course_meta(0x0d, [-1],   "Checkered Parkour Fortress"),
    "Course 14":        course_meta(0x0e, [-1],   "Illustrious Peril"),
    "Course 15":        course_meta(0x0f, [-1],   "Symmetrical Mossy Ruins"),
    
    "Slide":            course_meta(0x1b, [-1],   "Starry Night Slide"),
    "Aquarium":         course_meta(0x14, [-1],   "Ethereal Sunrise"),
    "End Cake Picture": course_meta(0x19, [-1],   "Gusty Giza"),
    "Clouds":           course_meta(0x1f, [-1],   "Chronomagic Cavern"),
    
    "Bowser 1":         course_meta(0x11, [-1],   "Bowser's Burning Junkyard"),
    "Key 1":            course_meta(0x1e, [-1],   "Bowser's Burning Junkyard"),
    "Bowser 2":         course_meta(0x13, [-1],   "Neo Ruined Kingdom"),
    "Key 2":            course_meta(0x21, [-1],   "Neo Ruined Kingdom"),
    "Bowser 3":         course_meta(0x15, [-1],   "Stronghold of Lost Wisdom"),
    "Final Fight":      course_meta(0x22, [-1],   "Stronghold of Lost Wisdom"),
    
    "Metal Cap":        course_meta(0x1c, [-1],   "Mournful Winterscape"),
    "Wing Cap":         course_meta(0x1d, [-1],   "Cap Training Grounds"),
    "Vanish Cap":       course_meta(0x12, [-1],   "Forest of Despair"),
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
    title = "Switcheroo Under 1 IQ - Completion Percentage Destruction",
    description = "Press the red, green, and blue !-switches in the Cap Training Grounds.",
    points = 0,
    trigger = all_switches_trigger() && in_level("Wing Cap"),
    id = 322232,
    badge = "359376"
)

achievement(
    title = "Search the Blazing Trashcan",
    description = "Obtain Key 1.",
    points = 25,
    trigger = in_level("Key 1") && collected_star_action_check(),
    id = 322233,
    badge = "359377"
)

achievement(
    title = "Kingdom's Lost Treasure",
    description = "Obtain Key 2.",
    points = 25,
    trigger = in_level("Key 2") && collected_star_action_check(),
    id = 322234,
    badge = "359378"
)

achievement(
    title = "Triumph Over Misery",
    description = "Collect the grand star after defeating Bowser.",
    points = 50,
    trigger = in_level("Final Fight") && just_increased(wearing_wing_cap()),
    id = 322235,
    badge = "359379"
)

// c o u r s e  s t a r s

// let's obfuscate the star names, just to be safe...

ordinals = ["first", "second", "third", "fourth", "fifth", "sixth", "seventh"]

blank = ""
course_star_cheev_titles = [
    {"Course 1": 
    ["Cabin Secrets for Good Mental Health", "Jammed Crevice", "Boxes Over the Patio", "Lost Gate Key in the Valley", "Way Too Precise for C1?", "Stupid Red Ballz Fun", "Ballsy Coin Collecting"]},
    {"Course 2":
    ["Cold Lumberjack Jumps", "Freezing Teamwork With the Enemy", "Crack in the Cavern", "So Far Down, the Camera Can't Keep Up", "Penguin Kidnapping", "Cherrified Crystal Coins", "Cold Hard Cash"]},
    {"Course 3":
    ["Thwomp's Unsightly Castle", "Conquer the Tree", "Wallkicks Up a Cool-Looking Thing", "Not Feeling Cubic Phobic", "Red Coin Playground Tour", "Take the Shell... or Not", "Tight Prehistoric Coins"]},
    {"Course 4":
    ["Ballsy Blocky Castle", "Throne of Greatness", "Alcove of Vile Language", "Big Alcove-Chan Returns", "Relaxing Reds", "Less Intense Magical Parkour", "Express Coin Delivery"]},
    {"Course 5":
    ["Dropped Vanish Cap", "The Blazing Staircase", "Pillar Above Spawn", "Fiery Dirt Path in the Far Corner", "Buried Buddies", "Twelve Rubies of Smart Excavation", "Struck Gold 100 Times"]},
    {"Course 6":
    ["Simple Slope Tricks", "Maximize Your Height", "Smart Box Busting", "These Coins Thankfully Don't Burn", "Forsaken Secrets", "Grandmas' Old Path", "Desecrated Coin Collection"]},
    {"Course 7":
    ["Top of the Skies", "Wallkicks in the Air", "A Growing Obsession", "Not-Bleeding Ring Chambers", "Coins of Hopium", "Passage Beneath the House", "Airy Stored Coins in 2022"]},
    {"Course 8":
    ["Not-So-Active Volcano Secrets", "Bully Box Battle", "Cubic Quadrivium", "Reds in the Exotic Danger", "Volcanic Exploration", "Not That Punishing", "Hotty Hot Coins"]},
    {"Course 9":
    ["Mini IQ Point Collection", "Overseeing the Factory", "Shell Ride of Intellect", "Leaking Through the Drain", "More Than One Way to Get", "SomeBro's Murky Ruby Rings", "Factory Plundering"]},
    {"Course 10":
    ["Smaller Hitboxes for the Win", "Fortress Without the Deadly Lights", "Storm the Other Red Building", "No Toxic Gas, Easy Platforming", "Love Those Lava Arches", "Reds in the Refined Glacial Ambient Nocturnal Shroomland Sanctum", "Boo's Doubloons"]},
    {"Course 11":
    ["Nuts and Bolts in the Basement", "The Room With Less Farts", "Smart Secrets", "Toxic Shell Ride", "Haunted Boo Battle", "Trial of Draw Distance", "Box is New, Jumps You Knew"]},
    {"Course 12":
    ["The Rainscape's Top", "Amps' Lava House", "High IQ Slippery Collection", "Other Tunnel of Wallkicks", "Driftwood Wallkicks", "Flurry Traveler After the Rain", "Morning Coin Storm"]},
    {"Course 13":
    ["All About Angles and Pillars", "More Bouncing on BALLZ", "This Rooftop is Transparent Now", "Return of the Double Double Arch", "Tower Climbing, Mirror Mode", "Precise Wallkicks at the Edge of the World", "Goomba-Propelled Human Accelerator (One-Time Use)"]},
    {"Course 14":
    ["Top of the Waterfall", "Ultimate Angle Control", "Hope You Picked a Good Order", "Precise Purple Platforming", "Ruinous Red Rampage", "Intelligent Plundering", "Right Under Your Feet"]},
    {"Course 15":
    ["Extraordinary Wallkicks", "Panel Jumps Really B2 Much Sometimes", "Find It With Your Mind Vision", "Underpass of the Ruins", "How to Get There?", "Gauntlet of the Smart Spheres", "Round Around Go the Coins"]},
    
    {"Metal Cap": // MW
    ["Manually Loading Cannon", "A 1-Up With a Purpose", "Thin Quicksnow Path", "Hot-Foot-It Up the Slopes", "Red Reserves in Overwintering"]},
    {"Vanish Cap": // FoD
    ["Acute Precision to the Two Lonely Trees", "Contained Forest Fire", "Red Evils Over the Forest"]},
    {"Wing Cap": // Caps
    ["Flying Around for Red Coins", "Stick the Landing on Timed Boxes", "Free Wallkick Star"]},
    
    {"Bowser 1":
    ["Top of the Junkyard", "Thin Collision Deathpixel Garbage", "Incinerator Secrets", "Precise Red Coin Platforming"]},
    {"Bowser 2":
    ["Kingdom's Ruinous Reds", "Apocalyptic Secrets", "Tower Top", "More Flying to the Side of the Kingdom"]},
    {"Bowser 3":
    ["Switch Jumps Just as Intense", "Good Old Wallkick Window", "Burning Misplaced Memory", "Breaking Through the High Tower", "Buddies Down the Pipes", "Final Red Test of Intellect"]},
    
    {"Slide": // SNS
    ["To the Fake Lava Arch", "Race to the Finish", "Preserving Speed on the Blue Slide", "Slippery Teamwork With the Enemy"]},
    {"Aquarium": // ES
    ["Lone Secret Down Under", "Express Crossover Elevator - Hurry Up!", "Other Deadly Rooftop", "Staircase of Enemies", "Vanish Time In and Out of the Castle", "Eternal Red Raindrops"]},
    {"End Cake Picture": // GG
    ["Get Past the Grate", "Pyramid Climbing", "Shell Riding in the Wind", "Sliding and Diving", "Great Crazy Box Leap of Wisdom", "Blowing Across Lava"]},
    {"Clouds": // CC
    ["Metal in the Pond", "Big Fan of This One", "Beyond Blue Coins", "Another Three-Way Autoscroller", "Strategic Timed Switch Magic", "Secrets' Test of Time"]},
    
    {"Castle Grounds": [blank, blank, blank, "No Stakes For These Reds", "I'm on a Tree"]},
    {"Inside Castle": ["Boo's Private Jails", "The Metal Cap's Purpose", "Reds in the Way Too Big Hub"]},
    {"Castle Courtyard": [blank, blank, blank, blank, blank, "Building Toxic Sprint", "Reds Outside the Stronghold"]},
]

course_star_titles = {
    "Course 1": ["Warm Up Inside the House", "Spam Your Way Up the Crevice", "Momentum Boxes", "The Gate Key is on the Roof", "The Impossible Slope", "Red Parkour in the Blue Valley"],
    "Course 2": ["Wooden Structure in the Cavern", "High in the Cavern", "Isolated Crevice", "Far Down Triple Jump", "Penguin Push", "Easier Preparation for Overwintering"],
    "Course 3": ["Top of the Castle?", "Parkour of the Chopped Tee", "A Poisonous Path", "Curious Ruins", "Prehistoric Tour", "Archaic Bunker"],
    "Course 4": ["Simple Blocky Tower", "Tall Poison Chair", "Timed Boxes Below", "Eye to Eye in the Secret Alcove", "Red Change in the Furniture Cushions", "Way Too Parkour for C4?"],
    "Course 5": ["Tour of the Magma Cave", "Lava Staircase", "BLJ to the Stone Podium", "Burning Dirt Path", "Secrets of the High Area", "Unearthed Red Gems"],
    "Course 6": ["Treacherous Sliding Cave", "Triple Jump Groundpound Challenge", "Unconventional !-Box Breaking", "Hot Coins of the Boiling Water Cave", "Secrets Around the Strange Building", "Top of the Boiling Water Cave"],
    "Course 7": ["Observation Tower of the Heavens", "Behind the House", "Within Fertile Ground", "Path of the Rings", "Red Coins of the Sky's Courtyard", "Beneath the Clouds"],
    "Course 8": ["Erupting Secrets", "Timed Bully Battle", "Lava Cube Parkour", "Spicier Red Coins", "Atop the Lavafall", "Punishing Precise Parkour"],
    "Course 9": ["Shining Secrets of the Marshy Pit", "Top of the Factory Ruins", "Tunnel Navigation With a Shell", "Down the Drain", "Tunnel Navigation With Wallkicks", "Red Coin Exploration"],
    "Course 10": ["Smaller Bob-ombs Are Stronger", "Recrudescence of the Fortress", "Hailstorm Tower's Flipside", "Not-so-Toxic Shroomland", "Logo Logistics", "Sentimental Inclination"],
    "Course 11": ["Across Rusted Bolts", "Hidden Biohazard Room", "Slippery Flooded Secrets", "Atop the Radioactive Mound", "The Battle of Geeheeb", "The Underground Switch"],
    "Course 12": ["Overlooking the Rainscape", "Into the Lava Chamber", "Sliding Around for Secrets", "Tunnel to the Impossible Box", "Unstable Wooden Crossovers", "Special Red Raindrops"],
    "Course 13": ["Purgatory Afterglow", "Subterranean Cap Combo", "Deadly Rooftop", "Around the Subterranean Complex", "The Fortified Tower's Top", "Edge of Sanity"],
    "Course 14": ["Atop Sky Blue Tower's Waterfall", "Silver Detour's Wallkick Challenge", "Don't Venture Far for Secrets", "Purple Tower's Perilous Parkour", "Storm the Big Red Building", "Raid the Golden Treasure Chest"],
    "Course 15": ["Brutal Wallkick Excursion", "Panels of the Mossy Slope", "Find the Metal Cap", "Treasure Under the Ruins", "The Impossible Alcove", "Gauntlet of Hope and Despair"],
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
    "Course 1":  stars_meta([4, 2, 5, 4, 10, 10, 5], ids=sequence(322236, 7), badge_ids=sequence(359380, 7, badge=1)),
    "Course 2":  stars_meta([3, 4, 3, 5, 5, 10, 5], ids=sequence(322243, 7), badge_ids=sequence(359387, 7, badge=1)),
    "Course 3":  stars_meta([5, 5, 10, 5, 25, 5, 50], ids=sequence(322250, 7), badge_ids=sequence(359394, 7, badge=1)),
    "Course 4":  stars_meta([3, 2, 5, 5, 10, 10, 10], ids=sequence(322257, 7), badge_ids=sequence(359401, 7, badge=1)),
    "Course 5":  stars_meta([5, 10, 10, 10, 25, 50, 25], ids=sequence(322264, 7), badge_ids=sequence(359408, 7, badge=1)),
    "Course 6":  stars_meta([5, 10, 10, 10, 10, 10, 25], ids=sequence(322271, 7), badge_ids=sequence(359415, 7, badge=1)),
    "Course 7":  stars_meta([5, 5, 5, 10, 10, 5, 10], ids=sequence(322278, 7), badge_ids=sequence(359422, 7, badge=1)),
    "Course 8":  stars_meta([5, 5, 10, 10, 10, 10, 10], ids=sequence(322285, 7), badge_ids=sequence(359429, 7, badge=1)),
    "Course 9":  stars_meta([10, 10, 10, 10, 5, 25, 10], ids=sequence(322292, 7), badge_ids=sequence(359436, 7, badge=1)),
    "Course 10": stars_meta([5, 10, 25, 10, 10, 25, 25], ids=sequence(322299, 7), badge_ids=sequence(359443, 7, badge=1)),
    "Course 11": stars_meta([10, 10, 10, 10, 5, 5, 5], ids=sequence(322306, 7), badge_ids=sequence(359450, 7, badge=1)),
    "Course 12": stars_meta([25, 5, 10, 10, 5, 25, 10], ids=sequence(322313, 7), badge_ids=sequence(359457, 7, badge=1)),
    "Course 13": stars_meta([10, 10, 25, 25, 25, 25, 10], ids=sequence(322320, 7), badge_ids=sequence(359464, 7, badge=1)),
    "Course 14": stars_meta([25, 25, 25, 50, 50, 10, 5], ids=sequence(322327, 7), badge_ids=sequence(359471, 7, badge=1)),
    "Course 15": stars_meta([25, 25, 10, 10, 10, 100, 50], ids=sequence(322334, 7), badge_ids=sequence(359478, 7, badge=1)),
    
    "Metal Cap": stars_meta([5, 2, 5, 10, 50], ids=sequence(322341, 5), badge_ids=sequence(359485, 5, badge=1)), // MW
    "Vanish Cap":stars_meta([10, 5, 50], ids=sequence(322346, 3), badge_ids=sequence(359490, 3, badge=1)), // FoD
    "Wing Cap":  stars_meta([5, 5, 2], ids=sequence(322349, 3), badge_ids=sequence(359493, 3, badge=1)),
    
    "Bowser 1":  stars_meta([10, 10, 10, 50], ids=sequence(322352, 4), badge_ids=sequence(359496, 4, badge=1)),
    "Bowser 2":  stars_meta([25, 25, 2, 2], ids=sequence(322356, 4), badge_ids=sequence(359500, 4, badge=1)),
    "Bowser 3":  stars_meta([10, 5, 5, 10, 25, 50], ids=sequence(322360, 6), badge_ids=sequence(359504, 6, badge=1)),
    
    "Slide":     stars_meta([10, 5, 10, 10], ids=sequence(322366, 4), badge_ids=sequence(359510, 4, badge=1)), // SNS
    "Aquarium":  stars_meta([5, 4, 5, 4, 4, 10], ids=sequence(322370, 6), badge_ids=sequence(359514, 6, badge=1)), // ES
    "End Cake Picture": stars_meta([10, 10, 10, 10, 4, 5], ids=sequence(322376, 6), badge_ids=sequence(359520, 6, badge=1)), // GG
    "Clouds":    stars_meta([5, 5, 5, 10, 10, 10], ids=sequence(322382, 6), badge_ids=sequence(359526, 6, badge=1)), // CC
    
    "Castle Grounds": stars_meta([-1, -1, -1, 3, 5], ids=[-1, -1, -1, 322389, 322388], badge_ids=["", "", "", "359533", "359322"]),
    "Inside Castle":  stars_meta([1, 3, 5], ids=[322390, 322391, 322392], badge_ids=["359534", "359535", "359536"]),
    "Castle Courtyard": stars_meta([-1, -1, -1, -1, -1, 4, 10],  ids=[-1, -1, -1, -1, -1, 322393, 322394], badge_ids=["", "", "", "", "", "359537", "359538"]),
}

function course_star_achievements() {
    // put in func to avoid namespace pollution
    for inf in course_star_cheev_titles {
        for course in inf {
            title_arr = inf[course]
            
            for i in range(0, length(title_arr) - 1) {
            title = title_arr[i]
            
            if (title != blank) {
                
                desc = ""
                if (is_numbered_course(course)) {
                    base_desc = "Collect the {0} in {1}."
                    if (i == 6) { // star 7
                        star_str = "the 100 coin star"
                        if (any_of(["Course 11", "Course 13", "Course 14"], a => course == a))
                            star_str = "the bonus star"
                    } else {
                        star_str = format("the star '{0}'", course_star_titles[course][i])
                    }
                    desc = format(base_desc, star_str, course_infos[course]["clean name"])
                }
                else
                    desc = format("Collect this star in {0}.", course_infos[course]["clean name"])

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
    mushies_meta("Course 6", "Lucky Shrooms in the Cove",
        "Collect all 3 1-up mushrooms in {0}.", 5,
        [{"type": "impartial", "count": 3}],
        level_check=remained_in_level("Course 6", hit=0), id=322407, badge="359551"),
    mushies_meta("Course 7", "Boxes' Company",
        "Collect the 1-up mushroom in {0}.", 1,
        [{"type": "impartial", "count": 1}],
        level_check=remained_in_level("Course 7", hit=0), id=322408, badge="359552"),
    mushies_meta("Course 13", "Tower's Small Gift",
        "Collect the 1-up mushroom in {0}.", 1,
        [{"type": "impartial", "count": 1}],
        level_check=remained_in_level("Course 13", hit=0), id=322409, badge="359553"),
    mushies_meta("Slide", "Tricky High Place",
        "Collect the 1-up mushroom in {0}.", 4,
        [{"type": "stationary", "count": 1}],
        level_check=remained_in_level("Slide", hit=0), id=322410, badge="359554"),
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

function challenge_achievements() {
    
    achievement(
        title = "Cold Champion",
        description = "Collect the star 'Easier Preparation for Overwintering' (reds) in Course 2 without taking damage.",
        points = 10,
        trigger = remained_in_level("Course 2", hit=1)
            && never(just_increased(hp_decrement()))
            && never(any_of(burning_actions, a => mario_action_changed_to(a)))
            && trigger_when(collected_star_action_check(6)),
        id=322411,
        badge="359555"
    )
    
    achievement(
        title = "My Hands are Technically Off Your Baby",
        description = "Get to the mother penguin in Course 2 while holding the baby penguin hands-free.",
        points = 10,
        trigger = in_level("Course 2")
            && object_is(held_object(), "baby penguin")
            && in_3d_box(4700.0, 2500.0, 2300.0, 3000.0, 7700.0, 8700.0)
            && __ornext(any_of(["single jump", "double jump", "triple jump", "air kick"], a => mario_action_is(a))),
        id=322412,
        badge="359556"
    )
    
    achievement(
        title = "Hope You Practiced This Way",
        description = "Collect the star 'Top of the Castle?' in Course 3 without taking damage.",
        points = 10,
        trigger = remained_in_level("Course 3", hit=1)
            && never(just_increased(hp_decrement()))
            && never(any_of(burning_actions, a => mario_action_changed_to(a)))
            && trigger_when(collected_star_action_check(1)),
        id=322413,
        badge="359557"
    )
    
    c4_eyeball = nth_array_object(84)
    achievement(
        title = "Quicksand Bad",
        description = "Defeat the big Mr. I in Course 4 without ledge-grabbing quicksand.",
        points = 5,
        trigger = remained_in_level("Course 4", hit=1)
            && never(qslg())
            && object_is(c4_eyeball, "mr i")
            && trigger_when(just_changed_to(object_action(c4_eyeball), 3)),
        id=322414,
        badge="359558"
    )
    
    achievement(
        title = "Fiery Dirty Precision",
        description = "Collect the star 'Burning Dirt Path' in Course 5 without long jumping or ledge-grabbing quicksand.",
        points = 25,
        trigger = remained_in_level("Course 5", hit=1)
            && never(qslg())
            && never(mario_action_changed_to("long jump"))
            && trigger_when(collected_star_action_check(4)),
        id=322415,
        badge="359559"
    )
    
    achievement(
        title = "Pretend There Are Extra Grates",
        description = "Collect 3 secrets in Course 6 while wearing a vanish cap (does not have to be in one go).",
        points = 10,
        trigger = remained_in_level("Course 6", hit=0)
            && measured(collided_with_object("secret number", count=3, extra_logic=wearing_vanish_cap() != 0)),
        id=322416,
        badge="359560"
    )
    
    achievement(
        title = "Unscathed Underpass",
        description = "Collect the star 'Beneath the Clouds' in Course 7 while having full displayed HP.",
        points = 5,
        trigger = in_level("Course 7")
            && hp() >= 0x800
            && collected_star_action_check(6),
        id=322417,
        badge="359561"
    )
    
    achievement(
        title = "Fiery Wrath",
        description = "Collect the star 'Timed Bully Battle' in Course 8 without taking damage.",
        points = 5,
        trigger = remained_in_level("Course 8", hit=1)
            && never(just_increased(hp_decrement()))
            && never(any_of(burning_actions, a => mario_action_changed_to(a)))
            && trigger_when(collected_star_action_check(2)),
        id=322418,
        badge="359562"
    )
    
    achievement(
        title = "Hard-Working Metalsmith",
        description = "Collect the star 'Top of the Factory Ruins' in Course 9 while still wearing a metal cap.",
        points = 5,
        trigger = in_level("Course 9")
            && prev(wearing_metal_cap()) != 0
            && trigger_when(collected_star_action_check(2)),
        id=322419,
        badge="359563"
    )
    
    achievement(
        title = "Actually Wallkick Through the Tunnel",
        description = "Collect the star 'Tunnel Navigation With Wallkicks' in Course 9 without riding a Koopa Shell.",
        points = 5,
        trigger = remained_in_level("Course 9", hit=1)
            && never(object_changed_to(ridden_object(), "koopa shell"))
            && trigger_when(collected_star_action_check(5)),
        id=322420,
        badge="359564"
    )
    
    c10_box = nth_array_object(109)
    
    achievement(
        title = "An Explosive Climb",
        description = "Collect the star 'Smaller Bob-ombs Are Stronger' in Course 10 the intended way, by exploding the box with a bob-omb.",
        points = 10,
        trigger = remained_in_level("Course 10", hit=0)
            && once(
                object_is(c10_box, "large cork box")
                && object_num_collided_objects(c10_box) >= 1
                && object_is(object_nth_collided_object(c10_box, 1), "bob-omb")
            )
            && trigger_when(collected_star_action_check(1)),
        id=322421,
        badge="359565"
    )
    
    achievement(
        title = "I Don't Miss the Fire Spam",
        description = "Collect the star 'Not-so-Toxic Shroomland' in Course 10 without taking damage.",
        points = 25,
        trigger = remained_in_level("Course 10", hit=1)
            && never(just_increased(hp_decrement()))
            && never(any_of(burning_actions, a => mario_action_changed_to(a)))
            && trigger_when(collected_star_action_check(4)),
        id=322422,
        badge="359566"
    )
    
    function kbr2_sign_meta(id, title, hint, cheev_id=0, cheev_badge="0") => {"id": id, "title": title, "hint": hint, "cheev id": cheev_id, "cheev badge": cheev_badge}
    
    kbr2_signs = [
        kbr2_sign_meta(0x00, "Fun Fact: SM64 Hack ROMs are Mostly Empty Space, Usually (1/4)", "beneath a fake floor", 322423, "359567"),
        kbr2_sign_meta(0x02, "KBR1 Flashbacks (2/4)", "along the toxic outskirts", 322424, "359568"),
        kbr2_sign_meta(0x03, "The Greatest C15 of All Time (3/4)", "on a sizzling lava bath", 322425, "359569"),
        kbr2_sign_meta(0x34, "No Shade to Skelux, But... (4/4)", "behind a nocturnal fortress", 322426, "359570")
    ]
    
    for s in kbr2_signs{
        achievement(
            title = s["title"],
            description = format("Read a secret sign in Course 10, {0}.", s["hint"]),
            points = 2,
            trigger = in_level("Course 10")
                && just_changed_from(dialog_id__mem, s["id"]),
            id=s["cheev id"],
            badge=s["cheev badge"]
        )
    }
    
    achievement(
        title = "Sudden Death Toxic Sprint",
        description = "Collect the star 'Atop the Radioactive Mound' in Course 11 with at least 6 HP remaining. (Indicator appears in toxic gas)",
        points = 10,
        trigger = in_level("Course 11")
            && in_toxic_gas() != 0
            && hp() >= 0x600
            && trigger_when(collected_star_action_check(4)),
        id=322427,
        badge="359571"
    )
    
    achievement(
        title = "No Homing Amps is Good Level Design",
        description = "Collect the star 'The Battle of Geeheeb' in Course 11 without taking damage.",
        points = 5,
        trigger = remained_in_level("Course 11", hit=1)
            && never(just_increased(hp_decrement()))
            && never(any_of(burning_actions, a => mario_action_changed_to(a)))
            && never(just_increased(in_toxic_gas()))
            && trigger_when(collected_star_action_check(5)),
        id=322428,
        badge="359572"
    )
    
    achievement(
        title = "Rusted Metal Meltdown",
        description = "Collect the star 'Into the Lava Chamber' in Course 12 while still wearing a metal cap.",
        points = 10,
        trigger = in_level("Course 12")
            && prev(wearing_metal_cap()) != 0
            && trigger_when(collected_star_action_check(2)),
        id=322429,
        badge="359573"
    )
    
    achievement(
        title = "Sprint Back to the Start",
        description = "Collect star 7 in Course 14 while still wearing a vanish cap.",
        points = 10,
        trigger = in_level("Course 14")
            && prev(wearing_vanish_cap()) != 0
            && trigger_when(collected_star_action_check(7)),
        id=322430,
        badge="359574"
    )
    
    es_switches = array_map([5, 59, 61, 62, 73, 83, 84, 85, 103], a => nth_array_object(a))
    
    achievement(
        title = "Versatile Objects",
        description = "Stand on all 9 purple switches in Ethereal Sunrise in one go.",
        points = 10,
        trigger = never(level_changed())
            && measured(tally(length(es_switches), array_map(es_switches, a => once(__ornext(object_is(a, "purple switch boxes") || object_is(a, "purple switch structure")) && just_changed_to(stood_on_object(), a)))), when=in_level("Aquarium")),
        id=322431,
        badge="359575"
    )
    
    achievement(
        title = "An Imperfect Run",
        description = "Reach the warp to the boss fight in Neo Ruined Kingdom starting from the first checkpoint in one go. (Must reset game to reset checkpoint)",
        points = 25,
        trigger = remained_in_level("Bowser 2", hit=0)
            && once(in_3d_box(-200.0, 200.0, -4500.0, -5500.0, 26300.0, 26600.0) && airborne() == 0)
            && trigger_when(just_used_warp(0x3C01)),
        id=322432,
        badge="359576"
    )
    
    function slide_boxes_check() {
        slide_boxes = [
        in_3d_box(12000.0, 14000.0, 5000.0, 15000.0, 15000.0, 18000.0), // in order
        in_3d_box(13000.0, 21000.0, 5000.0, 15000.0, 11000.0, 14500.0),
        in_3d_box(21100.0, 23500.0, 5000.0, 15000.0, 12000.0, 16000.0),
        in_3d_box(23000.0, 24000.0, 5000.0, 15000.0,  9000.0, 11000.0),
        in_3d_box(22800.0, 21600.0, 5000.0, 15000.0,  7500.0, 10000.0),
        in_3d_box(23000.0, 24000.0, 5000.0, 15000.0,  8300.0,  5500.0),
        ]
        return tally(6, array_map(slide_boxes, a => once(a && airborne() == 0)))
    }
    
    achievement(
        title = "The Caas Way",
        description = "Collect the timer star in Starry Night Slide the intended way, by sliding on all 6 slopes after the starting line.",
        points = 10,
        trigger = remained_in_level("Slide", hit=0)
            && once(just_increased(hud_timer_counting()))
            && ((trigger_when(collected_star_action_check(2)) && slide_boxes_check()) || (measured(slide_boxes_check(), when=in_level("Slide")) && impossible_condition())),
        id=322441,
        badge="359585"
    )
    
    achievement(
        title = "Really Light Metal",
        description = "Collect the wind star in Chronomagic Cavern while still wearing a metal cap.",
        points = 5,
        trigger = in_level("Clouds")
            && prev(wearing_metal_cap()) != 0
            && trigger_when(collected_star_action_check(2)),
        id=322433,
        badge="359577"
    )
    
    achievement(
        title = "Don't Need to Replenish Health That Way",
        description = "Collect the indoor star in Chronomagic Cavern without getting any blue coins.",
        points = 5,
        trigger = remained_in_level("Clouds", hit=1)
            && never(started_colliding_with_object("blue coin for block"))
            && trigger_when(collected_star_action_check(3)),
        id=322434,
        badge="359578"
    )
    
    // 2 options - music tempo or object 92 in CC.
    
    achievement(
        title = "Get Around the Gimmick",
        description = "Collect the three-way autoscroller star in Chronomagic Cavern without rewinding time.",
        points = 10,
        trigger = remained_in_level("Clouds", hit=1)
            && never(just_changed_to(music_tempo__mem, 0x1e00))
            && trigger_when(collected_star_action_check(4)),
        id=322435,
        badge="359579"
    )
    
    achievement(
        title = "Firefighting Metal Mario",
        description = "Collect the lavabounce star in Forest of Despair while still wearing a metal cap.",
        points = 5,
        trigger = in_level("Vanish Cap")
            && prev(wearing_metal_cap()) != 0
            && trigger_when(collected_star_action_check(2)),
        id=322436,
        badge="359580"
    )
    
    achievement(
        title = "Keep Your Head Up",
        description = "Collect the star beyond the quicksnow path (checkpoint allowed) in Mournful Winterscape without using the Z button.",
        points = 10,
        trigger = remained_in_level("Metal Cap", hit=1)
            && never(just_increased(controller_z_button()))
            && trigger_when(collected_star_action_check(3)),
        id=322437,
        badge="359581"
    )
    
    mw_bobombs = array_map([66, 67, 68], a => nth_array_object(a))

    achievement(
        title="Three for Three",
        description="Get all 3 bob-ombs into the hole in Mournful Winterscape in one go.",
        points=10,
        trigger=remained_in_level("Metal Cap", hit=0)
            && measured(tally(3, array_map(mw_bobombs, a => once(
                object_is(a, "bob-omb")
                && in_3d_box(-600.0, -250.0, 2250.0, 2550.0, -13600.0, -13900.0, obj_addr=a)
                && object_vel_y(a) < 0.001
                && object_vel_y(a) > -0.001
                && held_object() == 0
            )))),
        id=322442,
        badge="359586"
    )
    
    achievement(
        title = "Intellectual Coin Hunt",
        description = "Collect the red coin star in the first overworld without dying after getting the first red.",
        points = 10,
        trigger = remained_in_level("Castle Grounds", hit=0)
            && once(just_changed(g_red_coins_collected__mem, 0, 1))
            && never((warp_op_death()))
            && trigger_when(collected_star_action_check(0x04)),
        id=322438,
        badge="359582"
    )
    
    achievement(
        title = "Reds of the Shining Moon",
        description = "Collect the red coin star in the second overworld without dying after getting the first red.",
        points = 10,
        trigger = remained_in_level("Inside Castle", hit=0)
            && once(just_changed(g_red_coins_collected__mem, 0, 1))
            && never((warp_op_death()))
            && trigger_when(collected_star_action_check(0x03)),
        id=322439,
        badge="359583"
    )
    
    achievement(
        title = "Coin Collecting Test of Wits",
        description = "Collect the red coin star in the third overworld without dying after getting the first red.",
        points = 25,
        trigger = remained_in_level("Castle Courtyard", hit=0)
            && once(just_changed(g_red_coins_collected__mem, 0, 1))
            && never((warp_op_death()))
            && trigger_when(collected_star_action_check(0x07)),
        id=322440,
        badge="359584"
    )
}

function blue_coin_achievements() {
    function blue_coin_meta(title, level, points, coin_count, id=0, badge="") => {"title": title, "level": level, "points": points, "count": coin_count, "id":id, "badge":badge}

    blue_coins = [
        blue_coin_meta("Vanishing Blues in the Valley", "Course 1", 5, 4, id=322395, badge="359539"),
        blue_coin_meta("Cold Blue Pits",                "Course 2", 3, 3, id=322396, badge="359540"),
        blue_coin_meta("Prehistoric Sprint",            "Course 3", 10, 3, id=322397, badge="359541"),
        blue_coin_meta("Blue Comet Shards",             "Course 4", 5, 7, id=322398, badge="359542"),
        // no c5
        blue_coin_meta("Bouncing Blues",                "Course 6", 10, 5, id=322399, badge="359543"),
        blue_coin_meta("Permanent Sky Battle",          "Course 7", 10, 7, id=322400, badge="359544"),
        blue_coin_meta("Dropped Volcanic Blues",        "Course 8", 5, 9, id=322401, badge="359545"),
        blue_coin_meta("Can You Make It Back?",         "Course 9", 5, 4, id=322402, badge="359546"),
        blue_coin_meta("Boo Felt Generous",            "Course 10", 5, 6, id=322403, badge="359547"),
        blue_coin_meta("Maneuvering Around Triangles", "Course 12", 5, 3, id=322404, badge="359548"),
        blue_coin_meta("Single-Use Passageway",        "Course 15", 3, 3, id=322405, badge="359549"),
        blue_coin_meta("Not Really Needed Coins",       "Wing Cap", 5, 3, id=322406, badge="359550"),
    ]
    
    for bc in blue_coins {
        bc_title = bc["title"]
        bc_description = format("Collect all {0} switch blue coins in {1}.", bc["count"], course_infos[bc["level"]]["full name"])
        extra_logic = always_true()
        if (bc["level"] == "Course 1") {
            bc_description = format("Collect all {0} switch blue coins in {1} while wearing a vanish cap.", bc["count"], course_infos[bc["level"]]["full name"])
            extra_logic = wearing_vanish_cap() != 0
        } else if (bc["level"] == "Course 4" || bc["level"] == "Course 8") {
            bc_description = bc_description + " (2 switches)"
        } else if (bc["level"] == "Course 7") {
            bc_description = format("Collect {0} out of the {2} switch blue coins in {1}. (2 switches)", bc["count"], course_infos[bc["level"]]["full name"], bc["count"]+1)
        }
        
        bc_points = bc["points"]
        bc_trigger = never(level_changed())
            && measured(collided_with_object("blue coin for block", count=bc["count"], extra_logic=extra_logic), when=in_level(bc["level"]))
            
        achievement(
            title=bc_title,
            description=bc_description,
            points=bc_points,
            trigger=bc_trigger,
            id=bc["id"],
            badge=bc["badge"]
        )
    }
}

blue_coin_achievements()

challenge_achievements()

// LB
leaderboard(
    title="Starry Night Slide Race Time",
    description="Complete the timed race in Starry Night Sky as fast as possible. (Must spawn star)",
    start = in_level("Slide")
        && just_increased(hud_timer_counting())
        && hud_timer_shown() != 0,
    cancel = level_changed() || just_decreased(hud_timer_shown()),
    submit = object_changed_to(g_cutscene_focus__mem, "spawned star")
        && object_star_mission(g_cutscene_focus__mem) == 1,
    value = 2*hud_timer(),
    format = "FRAMES",
    lower_is_better=true
)

// RP

general_level_dict = {
    0x0901: "relieved in Blue Valley ahead of incoming challenges",
    0x1801: "on a slippery adventure in Cold Cavern",
    0x0C01: "collecting prehistoric stars in Triassic Playground",
    0x0501: "chilling out on reused level parts in Cosmic Lounge",
    0x0401: "avoiding common death in Abandoned Excavation",
    0x0701: "having an easier time in Forlorn Cove",
    0x0702: "inside a boiling cave of grandmas in Forlorn Cove",
    0x0703: "figuring out how to break !-boxes in Forlorn Cove",
    0x1601: "feeling hopeful in the skies",
    0x0801: "getting burnt once again in Volcanic Midway",
    0x1701: "retrieving lost stars in Deserted Murky Factory",
    0x0A01: "basically playing King Boo's Revenge 2 again",
    0x0B01: "doing plumbing work in Dismal Industrial Basement",
    0x2401: "relaxing in the Day of Endless Rain",
    0x0D01: "taking a brownerlasting trip through Checkered Parkour Fortress",
    0x0E01: "facing trials of faith in Illustrious Peril",
    0x0F01: "facing his reckoning in Symmetrical Mossy Ruins",
    
    0x0000: "in the skyover kingdom of Overworld 1",
    0x1001: "in the skyover kingdom of Overworld 1",
    0x0601: "going through the shiny Overworld 2",
    0x1A01: "outside the final fortress in Overworld 3",
    
    0x1401: "able to see the Ethereal Sunrise", // aquarium - ES
    0x1B01: "on a dark Starry Night Slide adventure", // slide - SNS
    0x1F01: "turning back time in Chronomagic Cavern", // clouds - CC
    0x1901: "getting blown away in Gusty Giza", // end cake - GG
    0x1902: "inside the windy trials of Gusty Giza", // end cake - GG
    
    0x1C01: "on a cursed X-Mas adventure in Mournful Winterscape", // MW
    0x1201: "eclipsing a smarter sphere in Forest of Despair", // FoD
    0x1D01: "taking it easy in the Cap Level", // Caps
    
    0x1101: "taking a Master Quest in Bowser's Burning Junkyard",
    0x1E01: "brawling with Wiggler",
    0x1301: "on an apocalyptic journey through Neo Ruined Kingdom",
    0x2101: "fighting Piranha Plants on platforms with weird draw distance",
    0x1501: "channeling Bellring's energy in Stronghold of Lost Wisdom",
    0x2201: "triumphing over misery in the Bowser Fight"
}

level__lookup = rich_presence_lookup("Levels", warp_dest_level_area(), general_level_dict, "in an unbeknownst location")

stars__value = rich_presence_value("Number", nof_stars())
lives__value = rich_presence_value("Number", (byte(nof_lives__addr) ) - (bit7(nof_lives__addr) * 256))
level_test__value = rich_presence_value("Number", warp_dest_level_area())

file__lookup  = rich_presence_lookup("File", file_num__mem, {
    0x01: "A", 0x02: "B", 0x03: "C", 0x04: "D"
}, "??")

coins__value = rich_presence_value("Number", nof_coins())

rich_presence_conditional_display(in_title_screen(), "Getting ready for a big extreme hack collab adventure.(Title Screen)")
rich_presence_conditional_display(in_file_select(), 
    "Getting ready for a big extreme hack collab adventure. (File Select)")
rich_presence_conditional_display(
    level_id__mem != 1 && music_id__mem != 0x21 || effective_mario_object() != 0, // both are false on file select, including after game over
      "Mario-{2} is {0} with {1} IQ points and {3}💰 [🔑1{4}] [🔑2{5}]", level__lookup, stars__value, file__lookup, coins__value, 
      rich_presence_lookup("Switch", pressed_switch__mem("key 1"), {1:"▣"}, "▢"),
      rich_presence_lookup("Switch", pressed_switch__mem("key 2"), {1:"▣"}, "▢")
    )
rich_presence_display("On a big extreme hack collab adventure.")