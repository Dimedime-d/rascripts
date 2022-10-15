// ~Hack~ Super Mario Parallel Stars
// #ID = 20594
// Made in RATools v1.9.1

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

function mem_access(addr, type, delta=0, bit_ind=-1) {
    mem = 0
    if (type == "dword") mem = dword(addr)
    else if (type == "word")  mem = word(addr)
    else if (type == "byte")  mem = byte(addr)
    else if (type == "bit")   mem = bit(bit_ind, addr)
    else if (type == "bitcount") mem = bitcount(addr)
    else if (type == "float")    mem = float(addr)
    else if (type == "word_be")  mem = word_be(addr)
    else if (type == "tbyte_be") mem = tbyte_be(addr)
    else if (type == "dword_be") mem = dword_be(addr)
    
    if (delta > 0)
        return prev(mem)
    else
        return mem
}

ordinals = {
    1: "first",
    2: "second",
    3: "third",
    4: "fourth",
    5: "fifth",
    6: "sixth"
}

offsets = {
    "SAVE DATA":    (0x207700 - 0x70),
    
    "MUSIC ID":     0x22261e,

    "COLLECTED STAR ID":    0x32dd87, // 1-indexed
    "FILE ID":              0x32ddf6,
    "MAP ID":               0x32ddfa,
    "CURRENT DEMO INPUT":   0x32d5f0,
    
    "STOOD ON OBJECT":      0x330e34,
    "DIALOGUE ID":          0x331486,
    
    "LEVEL INDEX":      0x33bac8,
    "SUBMAP ID":        0x33b249,
    
    "TIME COUNTING":    0x33b25e,
    "HUD FLAGS":        0x33b268,   //  https://github.com/n64decomp/sm64/blob/1372ae1bb7cbedc03df366393188f4f05dcfc422/src/game/level_update.h#L91
    "HUD TIMER":        0x33b26e,
    
    "TRANSITION TYPE":  0x33bab2,
    "MISSION ACTIVE":   0x33baca,
    
    "MARIO STRUCT":     0x33b170,
    "OBJECT ARRAY":     0x33d488,
    
    "TTC SPEED SETTING":    0x36125a,
    "RED COINS COLLECTED":  0x3613fd,
}

// double-check this list between hacks, custom objects can shift things...
behaviour_script__values = { 
    "Mr. I body":       0x800EB1D4,
    "timed star":       0x800EB2F4,

    "cannon base":      0x800EB628,
    //"TTM slide exit":   0x800EB8A0,
    "teleporter":       0x800EB8DC, //
    //"coin formation":   0x800EBA6C,
    "box star":         0x800EB978,
    "100 coin star":    0x800EB98C,
    
    "purple box switch":0x800EC62C, // 
    "grand star":       0x800EC894, // 
    "koopa shell":      0x800ED0BC, //
    "exclamation box":  0x800ED3D0, // 
    "crystal tap":      0x800ED778,
    "king whomp":       0x800EDD38,
    //"grabbable cork box":   0x800EF398, //
    //"carpet":               0x800EFC30, //
    //"blue coin for block":  0x800ED708, //
    
    //"bowser 3":         0x800EC9D0,
    //"blue coin switch": 0x800ED6E8,
    
    "bob-omb":          0x800EE2F4,
    
    "metal cap":        0x800EEF58,
    "vanish cap":       0x800EEF9C,
    
    "regular star":     0x800EEFBC, // 
    "spawned star":     0x800EEFE4, // 

    "impartial 1-up":   0x800EF15C, // same as butterfly / exclam box
    "stationary 1-up":  0x800EF1FC,
    "running away 1-up":0x800EF190,
    "activator 1-up":   0x800EF26C, //
    "chasing 1-up":     0x800EF2C8,
    
    "koopa flag checkpoint":    0x800EF750,
    "eyerok manager":   0x800F0434,
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
    "floor yaw":          0x76,
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

function mario_floor_yaw() => word(mario_field("floor yaw"))

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
    "BBH enter jump":              0x00001934,
    
    "death exit landing":          0x00020467,
    "burning ground":              0x00020449,
    "burning jump":                0x010208B4,
    "burning fall":                0x010208B5,
    
    "ground pound landing":        0x0080023C,
    "lava boost":                  0x010208B7,
    "twirl":                       0x108008A4,
    "slide kick":                  0x018008AA,
    "air kick":                    0x018008AC,
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

burning_actions = ["burning ground", "burning jump", "burning fall"]

airborne__mem = bit3(mario_current_action__addr + 1)
butt_or_belly_sliding__mem = bit2(mario_current_action__addr + 2)
on_pole__mem = bit4(mario_current_action__addr + 2)

// ------------------- //
//   s u r f a c e s   //
// ------------------- //
// (includes triangles)
// https://github.com/n64decomp/sm64/blob/1372ae1bb7cbedc03df366393188f4f05dcfc422/include/types.h#L218

surface__struct = {
    "type":             0x00, // word
    "normal Y":         0x20, // float
    "related object":   0x2C // dword (pointer to object, if applicable)
}
surface__sizeof = 0x30

function surface_field(base, field) => struct_field(surface__struct, base, field)

function surface_type(addr) => word(surface_field(addr, "type"))
function surface_normal_y(addr) => float(surface_field(addr, "normal Y"))
function surface_object(addr) => tbyte(surface_field(addr, "related object"))

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
    "koopa flag race started":0xF4, // dword
    "eyerok hands remaining": 0xF8, // dword
    "koopa flag ktq finished":0xF8, // dword
    "crystal tap water level":0xF8, // dword
    "koopa flag race finished":0x104, // dword
    
    "behavior param 2":     0x144,  // dword?
    "subtype":              0x144,  // dword
    "action":               0x14c,  // dword
    "timer":                0x154,  // dword
    
    "home x":               0x164,  // float
    "home y":               0x168,  // float
    "home z":               0x16c,  // float
    
    "hp":                   0x184,  // dword
    "teleporter id":        0x18a,  // short
    "star mission":         0x18b,  // byte (actually 0x188, but weirdness...) 0-indexed
    "behaviour script":     0x20c,  // dword
    
    "collected coins":       0xf4,  // bitfield
}
object__sizeof = 0x260

function object_field(base, field) => struct_field(object__struct, base, field)

// really only used when I need to look up object field in a dict (see: collided_with_object()) and need a generic function to check)
// verrry limited - TODO add other mathematical operators
function check_object_field(obj_addr, field, value, delta=-1) {
    mem = byte(0x00)
    if (field == "action") mem = object_action(obj_addr)
    if (field == "crystal tap water level") mem = object_crystal_tap_water_level(obj_addr)
        
    if (delta > 0)
        return prev(mem) == value
    else
        return mem == value
}

function object_graph_invisible(addr) => bit4(object_field(addr, "graph node flags"))
function object_graph_animation_active(addr) => bit5(object_field(addr, "graph node flags"))

// https://github.com/n64decomp/sm64/blob/1372ae1bb7cbedc03df366393188f4f05dcfc422/include/object_constants.h#L7
function object_active(addr) => bit(0, object_field(addr, "active"))


function object_just_deactivated(addr) => prev(object_active(addr)) != 0 && object_active(addr) == 0

function object_behav_script(addr) => dword(object_field(addr, "behaviour script"))
function object_is(addr, name) => object_behav_script(addr) == behaviour_script__values[name]
function object_was(addr, name) => prev(object_behav_script(addr)) == behaviour_script__values[name]
function object_changed_to(addr, name) => !object_was(addr, name) && object_is(addr, name)
function object_changed_from(addr, name) => object_was(addr, name) && !object_is(addr, name)

function object_num_collided_objects(addr) => word(object_field(addr, "num collided objects"))
function object_nth_collided_object(addr, n) => tbyte(object_field(addr, format("collided object {0}", n)))

// object specific
function object_king_whomp_hp(addr) => dword(object_field(addr, "hp"))
function object_boo_death_status(addr) => dword(object_field(addr, "boo death status"))
function object_crystal_tap_water_level(addr) => dword(object_field(addr, "crystal tap water level"))

function object_koopa_flag_race_started(addr) => dword(object_field(addr, "koopa flag race started"))
function object_koopa_flag_race_finished(addr) => dword(object_field(addr, "koopa flag race finished"))
function object_koopa_flag_ktq_finished(addr) => dword(object_field(addr, "koopa flag ktq finished"))

function object_eyerok_hands_remaining(addr) => dword(object_field(addr, "eyerok hands remaining"))

function object_anim(addr) => word(object_field(addr, "animation"))
function object_subtype(addr) => dword(object_field(addr, "subtype"))
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

// object specific
function object_star_mission(addr) => byte(object_field(addr, "star mission"))
function object_teleporter_id(addr) => word(object_field(addr, "teleporter id"))

function object_coin_formation_collects(addr) => bitcount(object_field(addr, "collected coins"))

// Mario Object specific stuff

// watch out for animation value collisions (ex: airborne spawn and falling out of water both use general fall, 0x56)
mario_anim__values = {
    "Water Star Dance": 0xB3, //https://github.com/n64decomp/sm64/blob/1372ae1bb7cbedc03df366393188f4f05dcfc422/include/mario_animation_ids.h#L186
    "Star Dance":       0xCD,
    "Breakdance Kick":  0x71,
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
    if (star_index > 0)
        if (trigger != 0)
            return cond && trigger_when(last_star__mem == star_index)
        else
            return cond && (last_star__mem == star_index)
    return cond
}

function is_collecting_star() {
    return any_of(star_dance_anim_values, a => mario_anim_is(a))
}

collected_any_star_on_star_dance_arr = []
for val in star_dance_anim_values {
    array_push(collected_any_star_on_star_dance_arr, mario_anim_changed_to(val))
}

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

// field_checks is a dict of the form {object field, field value}
function collided_with_object(obj_name, count=1, field_checks={}, extra_logic=always_true()) {
    obj_tally = []
    for i in range(1,4) {
        obj_addr = object_nth_collided_object(mario_object(), i)
        
        coll_check = mario_collision_check(obj_addr, obj_name, i)
        
        if (length(field_checks) > 0)
            for field in field_checks {
                coll_check = coll_check && check_object_field(obj_addr, field, field_checks[field])
            }
        
        coll_check = coll_check && extra_logic
        array_push(obj_tally,
            repeated(count, coll_check))   
    }
    return tally(count, obj_tally)
}

function collided_with_star_exit(star_obj_name, mission=-1) {
    star_tallies = []
    for i in range(1, 4) {
        obj_addr = object_nth_collided_object(mario_object(), i)
        if (mission != -1) {
            array_push(star_tallies, 
                once(object_num_collided_objects(mario_object()) >= i
                && object_is(obj_addr, star_obj_name)
                && object_star_mission(obj_addr) == mission)
            )
        } else {
            array_push(star_tallies, 
                once(object_num_collided_objects(mario_object()) >= i
                && object_is(obj_addr, star_obj_name))
            )
        }
    }
    return tally(1, star_tallies)
}

// Interactions

function collecting_star_object(obj_name, mission) {
    obj = interaction_object()
    return obj != 0
           && object_is(obj, obj_name)
           && object_star_mission(obj) == mission
}

// tkt 50250 - add a delta for obj != teleporter to prevent popping during level transition
// note: interaction object is cleared upon switching screens (generally set to Mario Spawn / Pipe)

// yeah, this also pops if you're teleporting from the warp, don't worry about 3-way warps, for now...
function just_used_teleporter(id) {
    obj = interaction_object()
    return obj != 0
        && just_changed_any(obj)
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

function hud_timer_started_counting() => prev(hud_timer_counting()) == 0
    && hud_timer_counting() == 1
    
function hud_timer_stopped_counting() => prev(hud_timer_counting()) == 1
    && hud_timer_counting() == 0

hud_flags__addr = offsets["HUD FLAGS"]

function hud_stars_shown() => bit2(hud_flags__addr)
function hud_timer_shown() => bit6(hud_flags__addr)

hud_timer__addr = offsets["HUD TIMER"]
hud_timer__mem = word(hud_timer__addr)

file_num__addr = offsets["FILE ID"]
file_num__mem = byte(file_num__addr)

save_data_base__addr = offsets["SAVE DATA"]
current_file__addr = save_data_base__addr + 0x70 * file_num__mem

function pressed_switch__mem(color, delta=-1){
    switch_mem = always_false
    if color == "red"
        switch_mem = bit1(current_file__addr + 8)
    else if color == "green"
        switch_mem = bit2(current_file__addr + 8)
    else if color == "blue"
        switch_mem = bit3(current_file__addr + 8)
     
    if (delta > 0)
        return prev(switch_mem)
    else
        return switch_mem
}

function pressed_switch(color, delta=-1){
    return pressed_switch__mem(color, delta) == 1
}

mission__addr = offsets["MISSION ACTIVE"]
mission__mem = byte(mission__addr)

// normal stars = 1-6; 100 coin star = 7
last_star__addr = offsets["COLLECTED STAR ID"]
last_star__mem = byte(last_star__addr)

sublevel_id__addr = offsets["SUBMAP ID"]
sublevel_id__mem  = byte(sublevel_id__addr)

level_id__addr = offsets["MAP ID"]
level_id__mem = byte(level_id__addr)

level_index__addr = offsets["LEVEL INDEX"]
level_index__mem = byte(level_index__addr)

music_id__addr = offsets["MUSIC ID"]
music_id__mem  = byte(music_id__addr)

function boss_music_ended() => prev(music_id__mem) == 0x16 && music_id__mem != 0x16 // be careful of other things (cap blocks, etc.) that overwrite current music...

dialog_id__addr = offsets["DIALOGUE ID"]
dialog_id__mem = word(dialog_id__addr)

transition_type__addr = offsets["TRANSITION TYPE"]
transition_type__mem = word(transition_type__addr)

function transition_active() => transition_type__mem >= 0x100

TRANSITION_COLOR_FADE_IN = 0x101

ttc_speed_setting__addr = offsets["TTC SPEED SETTING"]
ttc_speed_setting__mem =  word(ttc_speed_setting__addr)

g_red_coins_collected__addr = offsets["RED COINS COLLECTED"]
g_red_coins_collected__mem = byte(g_red_coins_collected__addr)

g_current_demo_input__addr = offsets["CURRENT DEMO INPUT"]
g_current_demo_input__mem = dword(g_current_demo_input__addr)

custom_timer__addr = 0x37006c
custom_timer__mem = word(custom_timer__addr)

function course_meta(value, sublevel_values, full_name) => {"value": value, "sublevel values": sublevel_values, "full name": full_name}

// https://github.com/n64decomp/sm64/blob/master/levels/level_defines.h level id's
course_infos = {
    "Castle Grounds":      course_meta(0x10, [-1],   "the first overworld"), // Castle Grounds
    "Inside Castle": course_meta(0x06, [-1], "the third overworld"), // 1-2-3: Lobby/Upstairs/Basement
    "Castle Courtyard":      course_meta(0x1a, [-1], "the second overworld"), // Castle Courtyard
    
    "Course 1":         course_meta(0x09, [-1],   "Bloomin' Garden"),
    "Course 2":         course_meta(0x18, [-1],   "Cubic Ruin"),
    "Course 3":         course_meta(0x0c, [-1],   "Emerald Night Bay"),
    "Course 4":         course_meta(0x05, [-1],   "Snowy Mountain"),
    "Course 5":         course_meta(0x04, [-1],   "Nightmare Rooms"),
    "Course 6":         course_meta(0x07, [-1],   "Forest of Dreams"),
    "Course 7":         course_meta(0x16, [-1],   "Burning Heat Land"),
    "Course 8":         course_meta(0x08, [-1],   "Toast 'N' Cheese"),
    "Course 9":         course_meta(0x17, [-1],   "Copula City"),
    "Course 10":        course_meta(0x0a, [-1],   "Freezy Riverside"),
    "Course 11":        course_meta(0x0b, [-1],   "Flooded Harbor"),
    "Course 12":        course_meta(0x24, [-1],   "Sky Hexa Fortress"),
    "Course 13":        course_meta(0x0d, [-1],   "Abandoned Room"),
    "Course 14":        course_meta(0x0e, [-1],   "Imitative Sphere"),
    "Course 15":        course_meta(0x0f, [-1],   "Parallel Portal"),
    
    "Aquarium":         course_meta(0x14, [-1],   "Mese's Trick Garden"),
    "Cloud Stage":      course_meta(0x1f, [-1],   "Final Act - In the Rainbow"),
    "Slide":            course_meta(0x1b, [-1],   "Toasty Timed Race"),
    
    "Bowser 1":         course_meta(0x11, [-1],   "Bowser in tha Underground"),
    "Key 1":            course_meta(0x1e, [-1],   "Bowser in tha Underground"),
    "Bowser 2":         course_meta(0x13, [-1],   "Bowser's Time Factory"),
    "Key 2":            course_meta(0x21, [-1],   "Bowser's Time Factory"),
    "Bowser 3":         course_meta(0x15, [-1],   "Rainbow Spiral"),
    "Final Fight":      course_meta(0x22, [-1],   "Rainbow Spiral"),
    
    "Metal Cap":        course_meta(0x1c, [-1],   "Melt-Down Volcano"),
    "Wing Cap":         course_meta(0x1d, [-1],   "Skyward Towers"),
    "Vanish Cap":       course_meta(0x12, [-1],   "Trapped in the Cage"),
}

function in_intro_or_file_select() => any_of([0x02, 0x21], a => music_id__mem == a)

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
        return in_level(name) && once(prev(level_id__mem) != course_infos[name]["value"]) && never(level_changed(except_when_entering=name)) && hud_stars_shown() == 1
    return in_level(name) && never(level_changed()) && hud_stars_shown() == 1
}

function common_in_file_check() => !in_intro_or_file_select() && level_id__mem != 1 && g_current_demo_input__mem == 0

//
//  Cheevs
//

// switches
function rgb_trigger() {
    sum_switches_now = sum_of(["red", "green", "blue"], a => pressed_switch(a, delta=0))
    sum_switches_del = sum_of(["red", "green", "blue"], a => pressed_switch(a, delta=1))
    
    return level_id__mem == prev(level_id__mem) // to prevent switching files after the ending picture puts you back to the title screen...
    && file_num__mem == prev(file_num__mem)
    
    && sum_switches_now == 3
    && sum_switches_del == 2
    && sum_switches_del != 3
}

// caps / bowsers

achievement(
    title = "Parallel Switcheroo",
    description = "Press the red, green, and blue !-switches.",
    points = 5,
    trigger = rgb_trigger(),
    id = 256465,
    badge = "284400"
)

achievement(
    title = "Join the Ghosts",
    description = "Defeat the Big Boo in Tha Underground and collect the key.",
    points = 5,
    trigger = in_level("Key 1") && just_collected_star(),
    id = 256466,
    badge = "284401"
)

achievement(
    title = "Escaped the Seal of Orichalcos",
    description = "Defeat the Big Boo in Bowser's Time Factory and collect the key.",
    points = 5,
    trigger = in_level("Key 2") && just_collected_star(),
    id = 256467,
    badge = "284402"
)

achievement(
    title = "Defeat is Life",
    description = "Defeat Bowser in Rainbow Spiral collect the grand star.",
    points = 10,
    trigger = in_level("Final Fight") && interaction_object() != 0 && object_is(interaction_object(), "grand star"),
    id = 256468,
    badge = "284403"
)

//-------------
// course stars
//-------------

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
    "Course 1":  course_stars_meta(sum_star_bits(0x0f, range(0, 6)), 10, "Tending to the Plants", id=256472, badge="284407"), 
    "Course 2":  course_stars_meta(sum_star_bits(0x0e, range(0, 6)), 10, "Cube Climb", id=256479, badge="284414"),
    "Course 3":  course_stars_meta(sum_star_bits(0x0d, range(0, 6)), 10, "Familiar Shipwreck", id=256480, badge="284415"),
    "Course 4":  course_stars_meta(sum_star_bits(0x0c, range(0, 6)), 10, "Slipping and Sliding Again", id=256481, badge="284416"),
    "Course 5":  course_stars_meta(sum_star_bits(0x13, range(0, 6)), 10, "Solved the Mystery", id=256482, badge="284417"),
    "Course 6":  course_stars_meta(sum_star_bits(0x12, range(0, 6)), 10, "Hazy Maze Forest", id=256483, badge="284418"),
    "Course 7":  course_stars_meta(sum_star_bits(0x11, range(0, 6)), 10, "A Lava Land Just as Lethal", id=256484, badge="284419"),
    "Course 8":  course_stars_meta(sum_star_bits(0x10, range(0, 6)), 10, "Cheesy Coast", id=256485, badge="284420"),
    "Course 9":  course_stars_meta(sum_star_bits(0x17, range(0, 6)), 10, "A Not-So Topical City", id=256486, badge="284421"),
    "Course 10":  course_stars_meta(sum_star_bits(0x16, range(0, 6)), 10, "Rambi's Air Ride on the Riverside", id=256473, badge="284408"),
    "Course 11":  course_stars_meta(sum_star_bits(0x15, range(0, 6)), 10, "Flooding Reparations", id=256474, badge="284409"),
    "Course 12":  course_stars_meta(sum_star_bits(0x14, range(0, 6)), 10, "Not-Whomp's Fortress", id=256475, badge="284410"),
    "Course 13":  course_stars_meta(sum_star_bits(0x1b, range(0, 6)), 10, "Cleaning Up Mese's Room", id=256476, badge="284411"),
    "Course 14":  course_stars_meta(sum_star_bits(0x1a, range(0, 6)), 25, "Danger Dice Dioramas", id=256477, badge="284412"),
    "Course 15":  course_stars_meta(sum_star_bits(0x19, range(0, 6)), 25, "Perilous Parallel Platforming", id=256478, badge="284413"),
    
    "Bowser 1":   course_stars_meta(sum_star_bits(0x18, range(1, 5)), 10, "Burrowed Stars", id=256469, badge="284404"),
    "Bowser 2":   course_stars_meta(sum_star_bits(0x1f, range(1, 5)), 10, "Time-Traveling Stars", id=256470, badge="284405"),
    "Bowser 3":   course_stars_meta(sum_star_bits(0x1e, range(1, 5)), 10, "Colorful Stars", id=256471, badge="284406"),
    
    "Wing Cap":   course_stars_meta(sum_star_bits(0x23, range(0, 4)), 5, "Towers of the Wing Cap", id=256489, badge="284424"),
    "Metal Cap":  course_stars_meta(sum_star_bits(0x1c, range(0, 4)), 5, "Hot Cavern of the Metal Cap", id=256487, badge="284422"),
    "Vanish Cap": course_stars_meta(sum_star_bits(0x22, range(0, 4)), 5, "Caged Vanish Cap Under the Moat?", id=256488, badge="284423"),
}

for c in course_offsets {
    info = course_offsets[c]
    bits = info["star bits"]["mem"]
    star_count = info["star bits"]["sum"]
    
    title = info["title"]
    description = ""
    if (c == "Course 14") {
        description = format("Collect all {0} stars in {1}{2}.",
        star_count,
        c,
        info["description add"])
    } else {
        description = format("Collect all {0} stars in {1}{2}.",
        star_count,
        course_infos[c]["full name"],
        info["description add"])
    }
    
    
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

// expects a star_bits-like object with a mem attribute
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
    stars=[sum_star_bits(0x0b, range(0, 6))], total = 7,
    title = "Parallel Worlds",
    description = "Collect all 7 stars across all 3 overworlds.",
    points = 5,
    id = 256490,
    badge = "284425"
)

// aaand Cannons...
cannon_bits = sum_cannon_bits([0x0c, 0x0d, 0x0e, 0x0f, 0x10, 0x12, 0x17, 0x1b, 0x1d, 0x22, 0x23])
star_collection_achievement(
    stars=[cannon_bits], total=11,
    title = "Parallel Cannoneer",
    description = "Open all 11 cannons.",
    points = 10,
    id = 256491,
    badge = "284426"
)

// Special - Mese's Trick Garden
function mese_star_meta(title="", points=0, id=0, badge="0") => {"title": title, "points": points, "id": id, "badge": badge}
mese_stars = {
    0: mese_star_meta("Simple Speedrunner Skip", 5,         id = 256492, badge="284427"),
    1: mese_star_meta("Yet Another Vanilla Trick", 1,       id = 256493, badge="284428"),
    2: mese_star_meta("It's Light Chuckya Time!", 10,       id = 256494, badge="284429"),
    3: mese_star_meta("Don't Need Metal Head to Move", 1,   id = 256495, badge="284430"),
    4: mese_star_meta("Ceiling Communication", 5,           id = 256496, badge="284431"),
    5: mese_star_meta("The Power of Love", 1,               id = 256497, badge="284432"),
    6: mese_star_meta("Y-y-y-y-Yahoo!", 10,                 id = 256498, badge="284433")
}

for id in mese_stars {
    info = mese_stars[id]
    achievement(
        title = info["title"],
        description = format("Collect star {0} in {1}.", id+1, course_infos["Aquarium"]["full name"]),
        points = info["points"],
        trigger = in_level("Aquarium") && collecting_star_object("regular star", id),
        id = info["id"],
        badge = info["badge"]
    )
}

// Milestones

function star_milestone_trigger(num_stars) {
    cond = level_id__mem == prev(level_id__mem) // to prevent switching files to pop the achievement
        && file_num__mem == prev(file_num__mem)
        && prev(nof_stars()) == num_stars - 1 
    if (num_stars > 1)
        cond = cond && measured(nof_stars() == num_stars, when=common_in_file_check())
    else
        cond = cond && nof_stars() == num_stars
    return cond
}

function milestone_meta(title, description, stars, points, id=0, badge="0") => {"title": title, "description": description, "stars": stars, "points": points, "id": id, "badge": badge}

milestones = [
    milestone_meta("Parallel Journey Has Started",
        "Collect your first parallel star.",
        stars=1, points=1, id=256499, badge="284434"),
    milestone_meta("Parallel Underground Door",
        "Collect 12 parallel stars.",
        stars=12, points=5, id=256500, badge="284435"),
    milestone_meta("Parallel Red Building",
        "Collect 35 parallel stars.",
        stars=35, points=5, id=256501, badge="284436"),
    milestone_meta("Parallel Lobby Door",
        "Collect 50 parallel stars.",
        stars=50, points=10, id=256502, badge="284437"),
    milestone_meta("Parallel Power",
        "Collect 80 parallel stars.",
        stars=80, points=25, id=256503, badge="284438"),
    milestone_meta("Parallel Shiny Collection",
        "Collect all 151 parallel stars.",
        stars=151, points=50, id=256504, badge="284439"),
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
    mushies_meta("Course 1", "Mushroom Hunt in the Flowers",
        "Collect all 3 1-up mushrooms in {0}.", 3, 
        [{"type": "impartial", "count": 2},
         {"type": "stationary", "count": 1}], 
        level_check=remained_in_level("Course 1", hit=0), id=256505, badge="284440"),
    mushies_meta("Course 2", "Cubic Lives Before the Tragedy",
        "Collect all 3 1-up mushrooms in {0}.", 3, 
        [{"type": "impartial", "count": 1},
         {"type": "stationary", "count": 1},
         {"type": "running away", "count": 1}], 
        level_check=remained_in_level("Course 2", hit=0), id=256506, badge="284441"),
    mushies_meta("Course 3", "Secret of the Coin Ring",
        "Collect the 1-up mushroom in {0}.", 1, 
        [{"type": "activator", "count": 1}], 
        level_check=remained_in_level("Course 3", hit=0), id=256568, badge="284503"),
    mushies_meta("Course 4", "Snowed-Over Lives",
        "Collect both 1-up mushrooms in {0}.", 2, 
        [{"type": "running away", "count": 1},
         {"type": "impartial", "count": 1}], 
        level_check=remained_in_level("Course 4", hit=0), id=256507, badge="284442"),
    mushies_meta("Course 6", "Lone Life in the Forest",
        "Collect the 1-up mushroom in {0}.", 1, 
        [{"type": "impartial", "count": 1}], 
        level_check=remained_in_level("Course 6", hit=0), id=256508, badge="284443"),
    mushies_meta("Course 7", "Toasted Mushrooms",
        "Collect all 5 1-up mushrooms in {0}.", 5, 
        [{"type": "stationary", "count": 4},
         {"type": "impartial", "count": 1}], 
        level_check=remained_in_level("Course 7", hit=0), id=256509, badge="284444"),
    mushies_meta("Course 8", "Mushrooms with Cheese",
        "Collect all 3 1-up mushrooms in {0}.", 3, 
        [{"type": "running away", "count": 1},
         {"type": "activator", "count": 1},
         {"type": "stationary", "count": 1}], 
        level_check=remained_in_level("Course 8", hit=0), id=256510, badge="284445"),
    mushies_meta("Course 9", "Lives in the Billboards",
        "Collect all 3 1-up mushrooms in {0}.", 3, 
        [{"type": "stationary", "count": 2},
         {"type": "impartial", "count": 1}], 
        level_check=remained_in_level("Course 9", hit=0), id=256511, badge="284446"),
    mushies_meta("Course 10", "Hillside Lives",
        "Collect all 3 1-up mushrooms in {0}.", 3, 
        [{"type": "stationary", "count": 2},
         {"type": "chasing", "count": 1}], 
        level_check=remained_in_level("Course 10", hit=0), id=256512, badge="284447"),
    mushies_meta("Course 11", "Lives of the Sky and Shallows",
        "Collect all 3 1-up mushrooms in {0}.", 3, 
        [{"type": "impartial", "count": 3}],
        level_check=remained_in_level("Course 11", hit=0), id=256513, badge="284448"),
    mushies_meta("Course 12", "Hexagon Shrooms",
        "Collect all 3 1-up mushrooms in {0}.", 3, 
        [{"type": "stationary", "count": 2},
         {"type": "impartial", "count": 1}], 
        level_check=remained_in_level("Course 12", hit=0), id=256514, badge="284449"),
    mushies_meta("Course 13", "Mese's Mushrooms",
        "Collect all 7 1-up mushrooms in {0}.", 5, 
        [{"type": "stationary", "count": 2},
         {"type": "activator", "count": 1},
         {"type": "running away", "count": 1},
         {"type": "impartial", "count": 3}], 
        level_check=remained_in_level("Course 13", hit=0), id=256515, badge="284450"),
    // C14 palooza time
    mushies_meta("Course 14", "Lustrous Lifesaver",
        "Collect all 3 1-up mushrooms in the first mission of {0}.", 3, 
        [{"type": "stationary", "count": 2},
         {"type": "impartial", "count": 1}], 
        level_check=remained_in_level("Course 14", hit=0) && mission__mem == 1, id=256516, badge="284451"),
    mushies_meta("Course 14", "Noxious Lifesaver",
        "Collect all 3 1-up mushrooms in the second mission of {0}.", 3, 
        [{"type": "stationary", "count": 2},
         {"type": "impartial", "count": 1}], 
        level_check=remained_in_level("Course 14", hit=0) && mission__mem == 2, id=256517, badge="284452"),
    mushies_meta("Course 14", "Levitating Lifesaver",
        "Collect all 3 1-up mushrooms in the third mission of {0}.", 3, 
        [{"type": "stationary", "count": 2},
         {"type": "impartial", "count": 1}], 
        level_check=remained_in_level("Course 14", hit=0) && mission__mem == 3, id=256518, badge="284453"),
    mushies_meta("Course 14", "Far Down Lifesaver",
        "Collect all 3 1-up mushrooms in the fourth mission of {0}.", 3, 
        [{"type": "stationary", "count": 2},
         {"type": "impartial", "count": 1}], 
        level_check=remained_in_level("Course 14", hit=0) && mission__mem == 4, id=256519, badge="284454"),
    mushies_meta("Course 14", "Wicked Lifesaver",
        "Collect all 3 1-up mushrooms in the fifth mission of {0}.", 3, 
        [{"type": "stationary", "count": 2},
         {"type": "impartial", "count": 1}], 
        level_check=remained_in_level("Course 14", hit=0) && mission__mem == 5, id=256520, badge="284455"),
    mushies_meta("Course 14", "Shady Lifesaver",
        "Collect all 3 1-up mushrooms in the sixth mission of {0}.", 3, 
        [{"type": "stationary", "count": 2},
         {"type": "impartial", "count": 1}], 
        level_check=remained_in_level("Course 14", hit=0) && mission__mem == 6, id=256521, badge="284456"),
    mushies_meta("Course 15", "Parallel Lifesaver",
        "Collect both 1-up mushrooms in {0}.", 2, 
        [{"type": "stationary", "count": 2}], 
        level_check=remained_in_level("Course 15", hit=0), id=256522, badge="284457"),
        
    mushies_meta("Bowser 1", "Underground Lifesaver",
        "Collect the 1-up mushroom in {0}.", 1, 
        [{"type": "stationary", "count": 1}], 
        level_check=remained_in_level("Bowser 1", hit=0), id=256523, badge="284458"),
    mushies_meta("Bowser 2", "Temporal Lifesaver",
        "Collect the 1-up mushroom in {0}.", 1, 
        [{"type": "impartial", "count": 1}], 
        level_check=remained_in_level("Bowser 2", hit=0), id=256524, badge="284459"),
    mushies_meta("Bowser 3", "Rainbow Lifesaver",
        "Collect all 3 1-up mushrooms in {0}.", 3, 
        [{"type": "stationary", "count": 3}], 
        level_check=remained_in_level("Bowser 3", hit=0), id=256525, badge="284460"),
        
    mushies_meta("Metal Cap", "Life Having a Meltdown",
        "Collect the 1-up mushroom in {0}.", 1,
        [{"type": "impartial", "count": 1}],
        level_check=remained_in_level("Metal Cap", hit=0), id=256526, badge="284461"),
    mushies_meta("Castle Grounds", "Lone Life on a Mountain",
        "Collect the 1-up mushroom in {0}.", 1,
        [{"type": "stationary", "count": 1}],
        level_check=remained_in_level("Castle Grounds", hit=0), id=256527, badge="284462"),
    mushies_meta("Castle Courtyard", "Building Lives",
        "Collect all 5 1-up mushrooms in {0}.", 5,
        [{"type": "stationary", "count": 4},
         {"type": "chasing", "count": 1}],
        level_check=remained_in_level("Castle Courtyard", hit=0), id=256528, badge="284463"),
]
 //  "Course 11": mushies_meta("Aquatic Lives", "Flooded Atlantis - Collect both 1-up mushrooms in the coin rings in the main area.", 2,
 //      [{"type": "stationary", "count": 2}], id = 244840, badge = "271667"),
 //  "Course 14": mushies_meta("No Star, No Thwomp", "Trick Top Clock - Collect the 1-up mushroom at the top of the clock.", 1, [{"type": "impartial", "count": 1}], id = 244841, badge = "271668"),
 //  "Course 1": mushies_meta("No Fast Travel for You", "Bob-omb Festival - Collect the 1-up mushroom where a warp used to be.", 1, [{"type": "stationary", "count": 1}], id = 244839, badge = "271666"),
 //  "Course 2": mushies_meta("Levitating Lives", "Floating Fortress - Collect all 3 1-up mushrooms. (2 box + blast walls)", 3, [{"type": "impartial", "count": 1},
 //  {"type": "running away", "count": 1},
 //  {"type": "activator", "count": 1}], id = 244842, badge = "271669"),
 //  "Course 3": mushies_meta("Ghostly Lives", "Haunted Shipwreck Bay - Collect both 1-up mushrooms. (1 box + 1 on ship)", 2, [{"type": "running away", "count": 1},
 //  {"type": "stationary", "count": 1}], id = 244843, badge = "271670")

for info in mushies_data {
    course = info["course"]
    
    mushie_count = sum_of(info["tallies"], t => t["count"])
    
    mushie_tally = tally_all_1ups(tallies = info["tallies"], total_count = mushie_count)
    trigger_tally = tally_all_1ups(tallies = info["tallies"], total_count = 1)
    
    collect_cond = always_true()
    
    if (mushie_count == 1) {
        collect_cond = mushie_tally
    }
    else {
        collect_cond = measured(mushie_tally, when=info["level check"]) || (trigger_tally && trigger_when(impossible_condition()))
    }

    
    achievement(
        title = info["title"],
        description = format(info["description"], course_infos[course]["full name"]),
        points = info["points"],
        trigger = info["level check"]
            && collect_cond
    )
}

// More gimme achievements - secret warps!
// for now, assume only need 1 of a pair of warps to pop achievement
// (same description, 1 point a pop)
function warp_meta(course="", title="", warps=[], id=0, badge="0") => {"course": course, "title": title, "warps": warps, "id": id, "badge": badge}

warp_infos = [
    warp_meta("Course 1", "Mushroom to Flower Circle", [0x0b, 0x0c],    id=256529, badge="284464"),
    warp_meta("Course 4", "Shortcut to Mountain Top", [0x03],           id=256530, badge="284465"),
    warp_meta("Course 7", "Cap Block Communication", [0x0d, 0x0e],      id=256531, badge="284466"),
    warp_meta("Course 8", "Water Escape", [0xe0e],                      id=256532, badge="284467"),
    warp_meta("Course 12", "Secret of the Red Coin", [0x03, 0x04],      id=256533, badge="284468"),
    warp_meta("Bowser 1", "Coin of the Deep Quicksand", [0xd0d],        id=256534, badge="284469"),
]

for w in warp_infos {
    achievement(
        title = w["title"],
        description = format("Use the secret warp in {0}.", course_infos[w["course"]]["full name"]),
        points = 1,
        trigger = in_level(w["course"]) && any_of(w["warps"], w => just_used_teleporter(w))
    )
}

// Challenge Time

//--------
// OW1
//--------

achievement(
    title = "Can't Fight Him Like This",
    description = format("Reach King Bob-omb in {0} while riding a Koopa Shell (mission 1 only).", course_infos["Course 1"]["full name"]),
    points = 2,
    trigger = in_level("Course 1")
        && mission__mem == 1
        && object_is(ridden_object(), "koopa shell")
        && trigger_when(airborne__mem == 0
            && in_3d_box(-150.0, -450.0, 900.0, 1100.0, 150.0, 450.0)),
    id=256535,
    badge="284470"
)

bad_triangles = [0x0066E700, 0x0066E730]
king_whomp = nth_array_object(59)
achievement(
    title = "Whomp's Sacred Ground",
    description = format("Defeat the Whomp King in {0} without standing on his central platform (mission 1 only).", course_infos["Course 2"]["full name"]),
    points = 5,
    trigger = remained_in_level("Course 2", hit=0)
        && mission__mem == 1
        && object_is(king_whomp, "king whomp")
        && once(just_changed(object_action(king_whomp), 0, 2))
        && never(boss_music_ended())
        && never(any_of(bad_triangles, a => airborne__mem == 0 && mario_floor_tri() == a))
        && trigger_when(just_changed(object_king_whomp_hp(king_whomp), 1, 0)),
    id=256536,
    badge="284471"
)

achievement(
    title = "Nowhere to Go With This but the Hole",
    description = format("Reach the cannon in {0} while riding a Koopa Shell.", course_infos["Course 3"]["full name"]),
    points = 2,
    trigger = in_level("Course 3")
        && object_was(ridden_object(), "koopa shell")
        && trigger_when(object_is(interaction_object(), "cannon base")),
    id=256537,
    badge="284472"
)

achievement(
    title = "Slippery Pickups",
    description = format("Collect 70 coins on the slide in {0} in one go, without pressing the A button.", course_infos["Course 4"]["full name"]),
    points = 10,
    trigger = once(in_area("Course 4", 2) && mario_action_is("airborne spawn"))
        && never(screen_changed() || music_id__mem == 0x21)
        && never(just_increased(controller_a_button()))
        && (measured(tally(70, just_increased(coin_display())), when=in_area("Course 4", 2))
            || trigger_when(impossible_condition())),
    id=256538,
    badge="284473"
)

c5_texts = [0x2E, 0x2A, 0x27, 0x23, 0x20, 0x13, 0x10, 0x0F]

achievement(
    title = "Mysterious Notes of the Rooms",
    description = format("Read all 8 exclamation points in {0} in one go.", course_infos["Course 5"]["full name"]),
    points = 3,
    trigger = remained_in_level("Course 5", hit=0)
        && (measured(tally(8, array_map(c5_texts, a => once(dialog_id__mem == a))))
            || (tally(1, array_map(c5_texts, a => once(dialog_id__mem == a))) && trigger_when(impossible_condition()))),
    id=256539,
    badge="284474"
)

wc_i_bodies = array_map(range(83, 87), a => nth_array_object(a))

achievement(
    title = "Not Seeing Eye to Eye",
    description = format("Collect the secrets star in {0} without taking damage or defeating any of the Mr. I's.", course_infos["Wing Cap"]["full name"]),
    points = 5,
    trigger = remained_in_level("Wing Cap", hit=1)
        && never(just_took_damage())
        && never(any_of(wc_i_bodies, a => 
                object_is(a, "Mr. I body")
                && just_changed(object_action(a), 2, 3)
        ))
        && trigger_when(collecting_star_object("spawned star", 0)),
    id=256540,
    badge="284475"
)

//-----------
// OW2
//-----------

achievement(
    title = "Jumpless Victory in the Flowers",
    description = format("Defeat the OTK-Roach (Wiggler) in {0} without taking damage or pressing the A button.", course_infos["Course 6"]["full name"]),
    points = 10,
    trigger = remained_in_level("Course 6", hit=1)
        && never(just_took_damage())
        && never(hud_stars_shown() != 0 && just_increased(controller_a_button())) // can use A button in star select
        && trigger_when(just_changed_to(dialog_id__mem, 152)),
    id=256541,
    badge="284476"
)

achievement(
    title = "Beat the Heat",
    description = format("Collect the 100 coin star in {0} without taking damage or getting a wing or metal cap.", course_infos["Course 7"]["full name"]),
    points = 10,
    trigger = remained_in_level("Course 7", hit=1)
        && never(just_took_damage())
        && never(just_increased(wearing_metal_cap()))
        && never(just_increased(wearing_wing_cap()))
        && trigger_when(collecting_star_object("100 coin star", 6)),
    id=256542,
    badge="284477"
)

achievement(
    title = "Way Too Cheese for Course 8?",
    description = format("Collect the star 'Quicksand Temple' in {0} without riding a Koopa Shell.", course_infos["Course 8"]["full name"]),
    points = 5,
    trigger = remained_in_level("Course 8", hit=1)
        && never(object_changed_to(ridden_object(), "koopa shell"))
        && collecting_star_object("regular star", 3),
    id=256543,
    badge="284478"
)

got_one_red = nof_coins() == prev(nof_coins()) + 2

achievement(
    title = "Shell Shredding the Legacy Flags",
    description = format("Collect all 8 red coins in {0} while riding a Koopa Shell.", course_infos["Course 8"]["full name"]),
    points = 5,
    trigger = remained_in_level("Course 8", hit=0)
        && never(object_changed_from(ridden_object(), "koopa shell"))
        && ((measured(repeated(8, object_is(ridden_object(), "koopa shell") && got_one_red)))
        || (once(object_is(ridden_object(), "koopa shell") && got_one_red && prev(g_red_coins_collected__mem) == 0) && trigger_when(impossible_condition()))),
    id=256544,
    badge="284479"
)

flag_checkpoint = nth_array_object(84) // being lazy with these because they are star specific anyway

achievement(
    title = "Bring a Buddy",
    description = format("Win the Koopa race in {0} while holding a Bob-omb.", course_infos["Course 9"]["full name"]),
    points = 5,
    trigger = in_level("Course 9")
        && object_is(flag_checkpoint, "koopa flag checkpoint")
        && object_koopa_flag_race_started(flag_checkpoint) != 0
        && prev(object_koopa_flag_race_finished(flag_checkpoint)) == 0
        && object_koopa_flag_ktq_finished(flag_checkpoint) == 0
        && trigger_when(
            just_increased(object_koopa_flag_race_finished(flag_checkpoint))
            && object_is(held_object(), "bob-omb")
            ),
    id=256545,
    badge="284480"
)

leaderboard(
    title = "Koopa's Race on the Rail",
    description = format("Race with Koopa the Quick in {0}.", course_infos["Course 9"]["full name"]),
    start = in_level("Course 9") && object_is(flag_checkpoint, "koopa flag checkpoint")
        && object_koopa_flag_race_started(flag_checkpoint) != 0
        && object_koopa_flag_ktq_finished(flag_checkpoint) == 0
        && just_increased(object_koopa_flag_race_finished(flag_checkpoint)),
    cancel = always_false(),
    submit = always_true(),
    value = hud_timer__mem*2,
    
    format="FRAMES",
    lower_is_better = true
)

achievement(
    title = "Quick Race Upstream",
    description = format("Collect the star 'Upstream Timed Race' in {0} with at least 12 seconds remaining.", course_infos["Course 10"]["full name"]),
    points = 10,
    trigger = in_level("Course 10")
        && custom_timer__mem >= int_seconds_to_frames(12)
        && trigger_when(collecting_star_object("timed star", 4)),
    id=256546,
    badge="284481"
)

leaderboard(
    title = "Rambi's Upstream Race",
    description = format("Collect the star 'Upstream Timed Race' in {0} as fast as possible (most time remaining).", course_infos["Course 10"]["full name"]),
    start = in_level("Course 10")
        && mission__mem == 5
        && collecting_star_object("timed star", 4),
    cancel = always_false(),
    submit = always_true(),
    value = custom_timer__mem*2,
    
    format = "FRAMES",
    lower_is_better = false
)

achievement(
    title = "There Was a Shell???",
    description = format("Collect the star 'Red Coins on Ice Lake' in {0} without riding a Koopa Shell.", course_infos["Course 10"]["full name"]),
    points = 10,
    trigger = remained_in_level("Course 10", hit=1)
        && mission__mem != 5
        && never(object_changed_to(ridden_object(), "koopa shell"))
        && trigger_when(collecting_star_object("spawned star", 3)),
    id=256547,
    badge="284482"
)

achievement(
    title = "Coin Rush in the Toxic Volcano",
    description = format("Collect the red coin star in {0} without riding a Koopa Shell or getting another metal cap.", course_infos["Metal Cap"]["full name"]),
    points = 10,
    trigger = remained_in_level("Metal Cap", hit=1)
        && never(object_changed_to(ridden_object(), "koopa shell"))
        && never(collided_with_object("metal cap"))
        && trigger_when(collecting_star_object("spawned star", 0)),
    id=256548,
    badge="284483"
)

achievement(
    title = "Beeline in the Cage",
    description = format("Collect the star in the red building {0} by picking up no more than one additional vanish cap.", course_infos["Vanish Cap"]["full name"]),
    points = 5,
    trigger = remained_in_level("Vanish Cap", hit=1)
        && never(mario_action_changed_to("BBH enter jump")) // just a hack to reset stale hits on the next reset
        && never(collided_with_object("vanish cap", 2))
        && trigger_when(collecting_star_object("regular star", 2)),
    id=256549,
    badge="284484"
)

achievement(
    title = "Tight Timed Race",
    description = format("Complete the {0} with at least 2 seconds remaining.", course_infos["Slide"]["full name"]),
    points = 10,
    trigger = in_level("Slide") 
        && custom_timer__mem >= int_seconds_to_frames(2)
        && trigger_when(collecting_star_object("timed star", 0)),
    id=256550,
    badge="284485"
)

leaderboard(
    title = "Race on Burnt Quicksand",
    description = format("Complete the {0} as fast as possible (most time remaining).", course_infos["Slide"]["full name"]),
    start = in_level("Slide")
        && collecting_star_object("timed star", 0),
    cancel = always_false(), // don't need to check for game over (free 1-up),
    submit = always_true(),
    value = custom_timer__mem*2,
    
    format = "FRAMES",
    lower_is_better = false
)

//--------------
//  OW3
//--------------

c11_taps = {
    57: 1739,
    105: 5323,
    106: 4146,
    107: 2610,
    108: 50,
    109: -3329
}
// not star specific, otherwise, would iterate the whole array

function tally_crystal_taps_touched(count) {
    tap_tally = []
    
    for index in c11_taps {
        obj_addr = nth_array_object(index)
        
        array_push(tap_tally, once(
            object_is(obj_addr, "crystal tap")
            && object_crystal_tap_water_level(obj_addr) == c11_taps[index]
            && just_changed(object_action(obj_addr), 1, 2)
        ))
    }
    
    return tally(count, tap_tally)
}

achievement(
    title = "Half Empty, Half Full, Way Too High, Way Too Dry",
    description = format("Touch all 6 water level changers in {0} in one go.", course_infos["Course 11"]["full name"]),
    points = 5,
    trigger = remained_in_level("Course 11", hit=0)
        && (measured(tally_crystal_taps_touched(6))
            || (tally_crystal_taps_touched(1) && trigger_when(impossible_condition()))),
    id=256551,
    badge="284486"
)

eyerok_boss = nth_array_object(93)

achievement(
    title = "Air to Ground",
    description = format("Begin the Eyerok fight in {0} while wearing a wing cap, then defeat Eyerok before your wing cap runs out, without refreshing it (mission 1 only).", course_infos["Course 12"]["full name"]),
    points = 5,
    trigger = remained_in_level("Course 12", hit=1)
        && mission__mem == 1
        && object_is(eyerok_boss, "eyerok manager")
        && once(just_changed(object_action(eyerok_boss), 2, 3) && wearing_wing_cap() != 0)
        && never(object_action(eyerok_boss) >= 3 && just_decreased(wearing_wing_cap()))
        && never(object_action(eyerok_boss) >= 3 && just_increased(cap_time()))
        && trigger_when(just_changed(object_eyerok_hands_remaining(eyerok_boss), 1, 0)),
    id=256552,
    badge="284487"
)

function tally_c13_hiding_star(count) {
    return tally(count, array_map(range(1, 6), a => once(collecting_star_object("box star", 5) && mission__mem == a)))
}

achievement(
    title = "Hiding All Over the Place",
    description = format("Collect the star 'Hide and Seek' in {0} 6 different times, one for each mission in the star select screen (see comment/picture) (one session).", course_infos["Course 13"]["full name"]),
    points = 5,
    trigger = (unless(!in_level("Course 13")) && measured(tally_c13_hiding_star(6)))
        || (unless(!in_level("Course 13")) && tally_c13_hiding_star(1) && trigger_when(impossible_condition())),
    id=256553,
    badge="284488"
)

function object_empty_box_broken(addr) =>
    object_is(addr, "exclamation box")
    && object_active(addr) != 0
    && object_subtype(addr) >= 15 // specific to these boxes
    && just_changed_to(object_action(addr), 3)

// the best c14 of all time
c14_empty_boxes = {
    1: {"title": "Bright Boxes",    "points": 3,"objs": array_map([2, 3, 6, 7, 8], a => nth_array_object(a)),
        "id":256554, "badge":"284489"},
    2: {"title": "Toxic Boxes",     "points": 5,"objs": array_map([4, 6, 7, 8, 10], a => nth_array_object(a)),
        "id":256555, "badge":"284490"        },
    3: {"title": "Floaty Boxes",    "points": 5,"objs": array_map([16, 17, 18, 19, 25], a => nth_array_object(a)),
        "id":256556, "badge":"284491"    },
    4: {"title": "Bottomless Boxes","points": 5,"objs": array_map([28, 29, 30, 31, 32], a => nth_array_object(a)),
        "id":256557, "badge":"284492"    },
    5: {"title": "Brutal Boxes",    "points": 5,"objs": array_map([28, 29, 30, 31, 32], a => nth_array_object(a)),
        "id":256558, "badge":"284493"    },
    6: {"title": "Murky Boxes",     "points": 3,"objs": array_map([1, 2, 3, 4, 6], a => nth_array_object(a)),
        "id":256559, "badge":"284494"         }
}

for act in c14_empty_boxes {
    achievement(
        title = format("{0}", c14_empty_boxes[act]["title"]),
        description = format("Break all 5 empty !-boxes in the {0} mission of {1}.", ordinals[act], course_infos["Course 14"]["full name"]),
        points = c14_empty_boxes[act]["points"],
        trigger = remained_in_level("Course 14", hit=0)
            && (measured(tally(5, array_map(c14_empty_boxes[act]["objs"], a => once(object_empty_box_broken(a)))), when=mission__mem == act))
            || (tally(1, array_map(c14_empty_boxes[act]["objs"], a => object_empty_box_broken(a))) 
                && mission__mem == act && trigger_when(impossible_condition())),
        id = c14_empty_boxes[act]["id"],
        badge = c14_empty_boxes[act]["badge"]
    )
}

c14_coins = {
    1: {"title": "Moneybag Yellow Side - Lit-Up Loot",          "points": 5,    "id":256560,"badge":"284495"},
    2: {"title": "Moneybag Green Side - Poisonous Plunder",     "points": 10,   "id":256561,"badge":"284496"},
    3: {"title": "Moneybag Teal Side - Fly-Away Finances",      "points": 10,   "id":256562,"badge":"284497"},
    4: {"title": "Moneybag Red Side - Abysmal Assemblage",      "points": 10,   "id":256563,"badge":"284498"},
    5: {"title": "Moneybag Purple Side - Cruel Collection",     "points": 10,   "id":256564,"badge":"284499"},
    6: {"title": "Moneybag Blue Side - Dark Dough",             "points": 5,    "id":256565,"badge":"284500"}
}

for act in c14_coins {
    achievement(
        title = format("{0}", c14_coins[act]["title"]),
        description = format("Collect the 100 coin star in the {0} mission of {1}.", ordinals[act], course_infos["Course 14"]["full name"]),
        points = c14_coins[act]["points"],
        trigger = remained_in_level("Course 14")
            && mission__mem == act
            && trigger_when(collecting_star_object("100 coin star", 6)),
        id=c14_coins[act]["id"],
        badge=c14_coins[act]["badge"]
    )
}

achievement(
    title = "Whoops, Wrong Daredevil Challenge",
    description = format("Collect the star 'Parallel Tourism' in {0} without taking damage.", course_infos["Course 15"]["full name"]),
    points = 10,
    trigger = remained_in_level("Course 15", hit=1)
        && mission__mem == 5
        && never(just_took_damage())
        && trigger_when(collecting_star_object("spawned star", 5)),
    id=256566,
    badge="284501"
)

achievement(
    title = "Classic Fire Spitter and Amp Spam for Red Coins",
    description = format("Collect the red coin star in {0} without getting damaged.", course_infos["Bowser 3"]["full name"]),
    points = 25,
    trigger = remained_in_level("Bowser 3", hit=1)
        && never(just_increased(hp_decrement())) // when you collect a coin on top of an enemy, you don't lose HP
        && trigger_when(collecting_star_object("spawned star", 5)),
    id=256567,
    badge="284502"
)

// RP

stars__value = rich_presence_value("Number", nof_stars())

meta_descriptions = {
    0x00: "Starting up the game",
    //0x02: "Playing with Mario head",
    0x21: "In File Select",
}

general_level_dict = {
    0x10: "out in the field of the first overworld",
    0x06: "inside a parallel castle",
    0x1a: "surrounded by buildings in the second overworld",
    
    0x09: "rustling some flowers in Bloomin' Garden",
    0x18: "climbing the Cubic Ruins",
    0x0C: "not looking for gemstones in Emerald Night Bay",
    0x05: "on a suspiciously similar Snowy Mountain",
    0x04: "doing detective work in Nightmare Rooms",
    0x07: "getting lost in the Forest of Dreams",
    0x16: "slipping by fire in Burning Heat Land",
    0x08: "on a Toasted Coast with much less quicksand",
    0x17: "making a ruckus in Copula City",
    0x0a: "getting snowed on in Freezy Riverside",
    0x0b: "swimming for ages in Flooded Harbor",
    0x24: "taking on the Sky Hexa Fortress",
    0x0d: "rummaging through the Abandoned Room",
    //0x0e: "c14 multiple areas",
    0x0f: "facing the trials of the Parallel Portal",
    
    0x1c: "inside a deadly volcano",
    0x1d: "flying around rainbow Skyward Towers",
    0x12: "Trapped in the Cage",

    0x1b: "riding for his life in Toasty Timed Race",
    0x14: "exploiting physics in Mese's Trick Garden",
    0x1f: "on his final adventure In the Rainbow",
    
    0x11: "searching for stars in tha Underground",
    0x1e: "fighting Big Boo underground",
    0x13: "platforming in Bowser's abandoned Time Factory",
    0x21: "fighting Big Boo in the seal of Orichalcos",
    0x15: "rising up the Rainbow Spiral",
    0x22: "fighting Bowser in a parallel arena",
    
    //0x19: end cake picture multiple areas
}

level_0e__lookup = rich_presence_lookup("Level0E", mission__mem,
    {
        0x01: "visiting a familiar light temple, climbing the tower of Ace",
        0x02: "maneuvering through a poison temple, traveling to the edge of Deuce",
        0x03: "ascending a levitating temple, traveling to the hole of Trey",
        0x04: "crashing down an abyssal temple, going to the same place of Cater",
        0x05: "having bad memories of a cruel temple, gathering the star pieces of Cinque",
        0x06: "engulfed in a dark temple, collecting the red coins of Sice",
    }
)

level_19__lookup = rich_presence_lookup("Level19", sublevel_id__mem,
    {
        0x01: "has concluded his parallel journey",
        0x06: "is in Hell"
    }
)

level__lookup = rich_presence_lookup("LevelsWithoutSublevels", level_id__mem, general_level_dict, "in an unbeknownst location")

stars__value = rich_presence_value("Number", nof_stars())
lives__value = rich_presence_value("Number", (byte(nof_lives__addr) ) - (bit7(nof_lives__addr) * 256))

file__lookup  = rich_presence_lookup("File", file_num__mem, {
    0x01: "A", 0x02: "B", 0x03: "C", 0x04: "D"
}, "??")

function rp_cond_same_display(cond, lookup) {
    rich_presence_conditional_display(cond, 
    "Mario-{2} is {0} with {1}⭐ and {6}🚶 [🔴{3}] [🟢{4}] [🔵{5}]", lookup, stars__value, file__lookup, 
        rich_presence_lookup("Switch", pressed_switch__mem("red"), {1:"▣"}, "▢"),
        rich_presence_lookup("Switch", pressed_switch__mem("green"), {1:"▣"}, "▢"),
        rich_presence_lookup("Switch", pressed_switch__mem("blue"), {1:"▣"}, "▢"),
        lives__value
    )
}

cond_displays = {
    "general": {"cond": mem_in(level_id__mem, general_level_dict), "lookup": level__lookup},
    "level0e": {"cond": (level_id__mem == 0x0e), "lookup": level_0e__lookup},
    "level19": {"cond": (level_id__mem == 0x19), "lookup": level_19__lookup},
}

rich_presence_conditional_display(in_intro_or_file_select() || level_id__mem == 1, "{0}", rich_presence_lookup("Fileless", music_id__mem, meta_descriptions))
//rich_presence_conditional_display(g_current_demo_input__mem != 0, "Mario is in a demo!")
for k in cond_displays {
    rp_cond_same_display(cond_displays[k]["cond"], cond_displays[k]["lookup"])
}
rich_presence_display("On a quest for parallel stars.")