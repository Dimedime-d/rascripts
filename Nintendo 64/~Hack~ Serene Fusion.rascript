// ~Hack~ Serene Fusion
// #ID = 21465
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
    "HACKTICE FLAG":        0x208d15,
    
    "SAVE DATA":    (0x06cee0 - 0x68),
    
    "MUSIC ID":     0x0f6fb2,

    "COLLECTED STAR ID":    0x20306b, // 1-indexed
    "FILE ID":              0x1ff694,
    "CREDITS ENTRY":        0x1ff6b0,
    "AREA":                 0x2012f8,
    "LEVEL ID":             0x1ff696,
    // "CURRENT DEMO INPUT":   0x32d5f0,
    
    "STOOD ON OBJECT":      0x203014,
    "DIALOGUE ID":          0x2015c2,
    
    //"LEVEL INDEX":      0x33bac8,
    //"SUBMAP ID":        0x33b249,
    "LAKITU STATE":     0x20e4a8,
    "TIME COUNTING":    0x20e765,
    "WARPDEST":         0x20e774,
    "HUD FLAGS":        0x20e78c,   //  https://github.com/n64decomp/sm64/blob/1372ae1bb7cbedc03df366393188f4f05dcfc422/src/game/level_update.h#L91
    "HUD TIMER":        0x20e792,
    
    "WARP TRANSITION":  0x20d530,
    "OBJECT CUTSCENE":  0x201304,
    "MISSION ACTIVE":   0x2013ae,
    
    "MARIO STRUCT":     0x20e794,
    "OBJECT ARRAY":     0x20f434,
    
    //"TTC SPEED SETTING":    0x36125a,
    "RED COINS COLLECTED":  0x20e6ef,
}

// double-check this list between hacks, custom objects can shift things...
behaviour_script__values = { 
    "golf sphere":          0x803aa000,
    "dan banana":           0x803aa058,

    "luigiman switch":      0x803aa134,
    "luigiman platform":    0x803aa168,

    "rovert hyperblock":    0x803aa3b0,
    "spiders death":        0x803aa4b0,

    "aglab fight":          0x803aaa5c,

    "mushie ctl":           0x803aacfc,

    "hf joel":              0x803aad48,

    "mtc brick":            0x803aafec,
    "mtc red ground":       0x803ab00c,

    "ab troll":             0x803ab378,
    "ab sand":              0x803ab3ac,

    "wooden post":          0x803ac2e0,
    "koopa flag checkpoint":0x803ac5bc,
    "hidden secret":        0x803acc74,
    "spawned star":         0x803acd28,
    "regular star":         0x803acd50,
    "blue coin for block":  0x803ae5b4,
    "exclamation box":      0x803ae8e0,
    "koopa shell":          0x803aebd0,
    
    "100 coin star":        0x803b02e0,
    "scut switch":          0x803b0ba0,
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
    "area":               0x90,  // dword (pointer to area)
    "controller":         0x9c,  // dword (pointer to controller struct)
    "nof stars":          0xa8,  // word, NOT HUD
    "nof coins":          0xaa,  // word
    "hp":                 0xac,  // byte / word
    "nof lives":              0xae,  // byte
    "hp increment":       0xb0,  // byte
    "hp decrement":       0xb1,  // byte
    "cap timer":          0xb4,  // word
    
    //"timer running":      0xed,  // bool
    //"coin display":       0xf0,  // word
}

function mario_field(field) => struct_field(mario__struct, mario__addr, field)

mario__addr = offsets["MARIO STRUCT"]
stood_on_object__addr = offsets["STOOD ON OBJECT"]
object_cutscene__addr = offsets["OBJECT CUTSCENE"]

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
function mario_area() => tbyte(mario_field("area"))
function stood_on_object() => tbyte(stood_on_object__addr)
function object_cutscene() => tbyte(object_cutscene__addr)

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

function nof_stars() => word(mario_field("nof stars"))
function nof_coins() => word(mario_field("nof coins"))

// need to trick the compiler to not optimize out an impossible condition
// your max hp is capped at 0x880
function impossible_condition() => hp() == 9001

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
    "falling death exit":          0x0000192A,
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
    "stomach slide":               0x008C0453,
    "crouch slide":                0x04808459,
    "hold butt slide":             0x00840454, // while holding an object
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

sliding_actions = ["dive slide", "butt slide", "stomach slide", "crouch slide"]

airborne__mem = bit3(mario_current_action__addr + 1)
swimming__mem = bit5(mario_current_action__addr + 1)
butt_or_belly_sliding__mem = bit2(mario_current_action__addr + 2)
on_pole__mem = bit4(mario_current_action__addr + 2)

// ------------------- //
//   other structs     //
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

// https://github.com/n64decomp/sm64/blob/1372ae1bb7cbedc03df366393188f4f05dcfc422/src/game/area.h#L57
area__struct = {
    "index":            0x00, // 8-bit
    "camera":           0x24, // pointer
}
area__sizeof = 0x40

function area_field(base, field) => struct_field(area__struct, base, field)

function area_index(addr) => byte(area_field(addr, "index"))
function area_camera(addr) => tbyte(area_field(addr, "camera"))

//https://github.com/n64decomp/sm64/blob/1372ae1bb7cbedc03df366393188f4f05dcfc422/src/game/camera.h#L520
camera__struct = {
    "focus x":          0x04, // float
    "focus y":          0x08, // float
    "focus z":          0x0c, // float
}
camera__sizeof = 0x6c

function camera_field(base, field) => struct_field(camera__struct, base, field)

function camera_focus(addr, coord) => float(camera_field(addr, format("focus {0}", coord)))

lakitu_state__struct = {
    "pos x":          0x00, // float
    "pos y":          0x04, // float
    "pos z":          0x08, // float
    "focus x":        0x0C, // float
    "focus y":        0x10, // float
    "focus z":        0x14, // float    
    "goal focus x":   0x18, // float
    "goal focus y":   0x1C, // float
    "goal focus z":   0x20, // float
    "goal pos x":     0x24, // float
    "goal pos y":     0x28, // float
    "goal pos z":     0x2C, // float      
}
lakitu_state__addr = offsets["LAKITU STATE"]

function lakitu_state_field(field, addr) {
    if (addr == -1)
        this_addr = lakitu_state__addr
    else
        this_addr = addr
    struct_field(lakitu_state__struct, this_addr, field)
    }

function lakitu_state_goal_focus(coord, addr=-1) {
    return float(lakitu_state_field(format("goal focus {0}", coord), addr))
    }

// shortcut
function camera() => area_camera(mario_area())

//https://github.com/n64decomp/sm64/blob/1372ae1bb7cbedc03df366393188f4f05dcfc422/src/game/level_update.h#L73
warp_dest__struct = {
    "node":         0x00,
    "area id":      0x01, 
    "level id":     0x02,
    "type":         0x03,
}
warp_dest__addr = offsets["WARPDEST"]

function warp_dest_field(field, addr) {
    if (addr == -1)
        this_addr = warp_dest__addr
    else
        this_addr = addr
    struct_field(warp_dest__struct, this_addr, field)
    }

function warp_dest_node(addr=-1) => byte(warp_dest_field("node", addr))
function warp_dest_area(addr=-1) => byte(warp_dest_field("area", addr))
function warp_dest_level(addr=-1) => byte(warp_dest_field("level", addr))
function warp_dest_type(addr=-1) => byte(warp_dest_field("type", addr))

// DOES NOT WORK
//function death_warp_in_level() => just_changed_to(warp_dest_type(), 3) && warp_dest_node() == 0xf1 // see level_update.h for standard warp nodes/types

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
    "num secrets":            0xF4, // dword
    "eyerok hands remaining": 0xF8, // dword
    "koopa flag ktq finished":0xF8, // dword
    "crystal tap water level":0xF8, // dword
    "koopa flag race finished":0x104, // dword
    
    "behavior param 2":     0x144,  // dword?
    "subtype":              0x144,  // dword
    "action":               0x14c,  // dword
    "timer":                0x154,  // dword
    "distance to mario":    0x15c,  // float (ONLY when obj flag is set to compute it)
    
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
function object_num_secrets(addr) => dword(object_field(addr, "num secrets"))

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
function object_distance_to_mario(addr) => float(object_field(addr, "distance to mario"))
function object_health(addr) => dword(object_field(addr, "hp"))

// object specific
function object_star_mission(addr) => byte(object_field(addr, "star mission"))
function object_teleporter_id(addr) => word(object_field(addr, "teleporter id"))

function object_coin_formation_collects(addr) => bitcount(object_field(addr, "collected coins"))

// Mario Object specific stuff

// generic (ex: any wooden post)
function ground_pounding_object(name) => mario_action_is("ground pound landing") && object_is(stood_on_object(), name)

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

//timer_counting__addr = mario_field("timer running")

hacktice__addr = offsets["HACKTICE FLAG"]

function hacktice_enabled() => bit0(hacktice__addr)

function pause_lock_hacktice_in_level(name) => disable_when(hacktice_enabled() == 1, until=level_changed())

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

credits_entry__addr = offsets["CREDITS ENTRY"]
credits_entry__mem = dword(credits_entry__addr)

save_data_base__addr = offsets["SAVE DATA"]
// DIFFERENT for Serene Fusion (0x68 instead of 0x70)
current_file__addr = save_data_base__addr + 0x68 * file_num__mem

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

area__addr = offsets["AREA"]
area__mem = low4(area__addr)

level_id__addr = offsets["LEVEL ID"]
level_id__mem = byte(level_id__addr)

music_id__addr = offsets["MUSIC ID"]
music_id__mem  = byte(music_id__addr)
music_tempo__mem = word(music_id__addr + 2) // cba to define the sequence player struct

function boss_music_ended() => prev(music_id__mem) == 0x16 && music_id__mem != 0x16 // be careful of other things (cap blocks, etc.) that overwrite current music...

dialog_id__addr = offsets["DIALOGUE ID"]
dialog_id__mem = word(dialog_id__addr)

g_red_coins_collected__addr = offsets["RED COINS COLLECTED"]
g_red_coins_collected__mem = byte(g_red_coins_collected__addr)

function course_meta(value, sublevel_values, full_name) => {"value": value, "sublevel values": sublevel_values, "full name": full_name}

// https://github.com/n64decomp/sm64/blob/master/levels/level_defines.h level id's
course_infos = {
    "Title / File Select":   course_meta(0x01, [-1], "title screen / file select"), // actually works
    "Castle Courtyard":      course_meta(0x1a, [-1], "the starting area"), // Castle Courtyard
    "Overworld 1":      course_meta(0x10, [-1],   "the first overworld"), // Castle Grounds
    "Overworld 2": course_meta(0x06, [-1], "the second overworld"), // triarc
    
    "Dice Fortress":    course_meta(0x28, [-1], "Dice Fortress"), // arthur
    "Predestined Fate": course_meta(0x2c, [-1], "Predestined Fate"), // mushie
    "Course 1":         course_meta(0x27, [-1],   "Azure Abyss"), // arthur
    "Course 2":         course_meta(0x2a, [-1], "Molten Treasure Chest"), // brodute
    "Slide":            course_meta(0x1b, [-1], "Sandy Hill Slide"), // brodute
    "Course 3":         course_meta(0x29, [-1], "Flower Fields"), // Arthur
    "Pie":              course_meta(0x12, [-1], "Palace of Earth Spirits"), // sm64pie
    "Course 4":         course_meta(0x2b, [-1], "Haunted Factory"), // 
    "DNVIC":            course_meta(0x1f, [-1], "Grain Silo Ruins"), //
    "Course 5":         course_meta(0x09, [-1], "Abandoned Catacombs"),
    "Dual Rush":        course_meta(0x14, [-1], "Dual Rush"),
    "Flipnote":         course_meta(0x1d, [-1], "Flipnote Studio"),
    "LinCrash":         course_meta(0x2e, [-1], "Ashellerated Automata"),
    "Gear Tower":       course_meta(0x1c, [-1], "Ancient Gear Tower"),
    
    "Course 6":         course_meta(0x2f, [-1],   "Honeyhive Falls"), // spiders
    "Course 7":         course_meta(0x32, [-1],   "Dead Space Base"), // luigiman
    "Sphere":           course_meta(0x34, [-1],   "Golf Sphere"),
    "Course 8":         course_meta(0x30, [-1],   "Time Travel Ruins"),
    "GPTV":             course_meta(0x33, [-1],   "Slip on a Banana Peel"),
    "Medley":           course_meta(0x31, [-1],   "Star Gazed Medley"),
    
    "Bowser Course":    course_meta(0x2d, [-1],   "Bowser's Diorama Fortress"),
    "Bowser Battle":    course_meta(0x21, [-1],   "The Final Fight"),
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
        area_check = area__mem == area
    
    return level_id__mem == course_infos[name]["value"] && area_check
}

function in_same_level_from_last_frame() => level_id__mem == prev(level_id__mem) && area__mem == prev(area__mem)

function level_changed(except_when_entering="") {
    cond = just_changed_any(level_id__mem)
    if (except_when_entering != "")
        cond = cond && !in_level(except_when_entering)
    return cond
}
function screen_changed() => just_changed_any(level_id__mem) || just_changed_any(area__mem)

// the hit is for challenges that, if failed, require re-entering the level
function remained_in_level(name, hit=1) {
    if (hit != 0)
        return in_level(name) && once(prev(level_id__mem) != course_infos[name]["value"]) && never(level_changed(except_when_entering=name)) && hud_stars_shown() == 1
    return in_level(name) && never(level_changed()) && hud_stars_shown() == 1
}

function common_in_file_check() => !in_intro_or_file_select() && level_id__mem != 1 //&& g_current_demo_input__mem == 0

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

achievement(
    title = "Dicey Switcheroo",
    description = "Press the red, green, and blue !-switches.",
    points = 1,
    trigger = rgb_trigger(),
    id = 264470,
    badge = "292387"
)

// caps / bowsers


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
    //"Course 1":  course_stars_meta(sum_star_bits(0x0f, range(0, 6)), 10, "Tending to the Plants", id=256472, badge="284407"), 
    "Course 1": course_stars_meta(sum_star_bits(0x0f, range(0, 6)), 10, "Deepblue Depths", id=264471, badge="292388"),
    "Course 2": course_stars_meta(sum_star_bits(0x0e, range(0, 6)), 10, "An Actual Treasure Chest", id=264472, badge="292389"),
    "Course 3": course_stars_meta(sum_star_bits(0x0d, range(0, 6)), 10, "Makai Field of Hopes and Dreams", id=264473, badge="292390"),
    "Course 4": course_stars_meta(sum_star_bits(0x0c, range(0, 6)), 10, "Spooky Machinery", id=264474, badge="292391"),
    "Course 5": course_stars_meta(sum_star_bits(0x13, range(0, 6)), 10, "Another Star Adventure", id=264475, badge="292392"),
    "Course 6": course_stars_meta(sum_star_bits(0x12, range(0, 6)), 10, "Land of Oversized Arthropods", id=264476, badge="292393"),
    "Course 7": course_stars_meta(sum_star_bits(0x11, range(0, 6)), 10, "Spaceman Infiltration", id=264477, badge="292394"),
    "Course 8": course_stars_meta(sum_star_bits(0x10, range(0, 6)), 10, "Haven't Aged a Bit", id=264478, badge="292395"),
    "Medley": course_stars_meta(sum_star_bits(0x1b, range(0, 6)), 10, "Perilous Procgen", id=264479, badge="292396"),
}

for c in course_offsets {
    info = course_offsets[c]
    bits = info["star bits"]["mem"]
    star_count = info["star bits"]["sum"]
    
    title = info["title"]
    description = format("Collect all {0} stars in {1}{2}.",
    star_count,
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

secret_stars = [
    sum_star_bits(0x0b, [0, 1, 2]), // overworld
    sum_star_bits(0x14, [0]), // banana
    sum_star_bits(0x15, [0]), // golf
    sum_star_bits(0x18, [0]), // silo
    sum_star_bits(0x19, [0, 1]), // dual
    sum_star_bits(0x1a, [0]), // crash
    sum_star_bits(0x1c, [0]), // gear
    sum_star_bits(0x1d, [0]), // slide
    sum_star_bits(0x1e, [0]), // diorama fortress
    sum_star_bits(0x20, [0]), // dice
    sum_star_bits(0x21, [0, 1]), // pie
    sum_star_bits(0x22, [0]), // predestined
    sum_star_bits(0x23, [0]), // flipnote
]

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
    stars = secret_stars, total = 17,
    title = "Creators' Concept Challenges",
    description = format("Collect all 17 secret stars, excluding {0}.", course_infos["Medley"]["full name"]),
    points = 25,
    id = 264480,
    badge = "292397"
)

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
    milestone_meta("Start of Another aglab Collab", "Collect your first star.", stars=1, points=1, id=264481, badge="292398"),
    milestone_meta("Redemption of an Abandoned Project", "Collect all 80 stars.", stars=80, points=25, id=264482, badge="292399")
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


// save-protect key 1
achievement(
    title = "Prize of the Bridge",
    description = "Collect the key in the second overworld for the first time.",
    points = 3,
    trigger = in_level("Overworld 2")
        && just_increased(bit(4, current_file__addr + 8)),
    id=264483, badge="292400"
)

achievement(
    title = "Bowser Can't Catch a Break",
    description = "Collect the grand star inside Bowser's Fortress after beating Bowser.",
    points = 10,
    trigger = pause_lock_hacktice_in_level("Bowser Battle")
        && in_level("Bowser Battle")
        && just_increased(wearing_wing_cap()),
    id=264484, badge="292401"
)

// Misc / Challenges

ab_sand = nth_array_object(14)
achievement(
    title = "Depth Climbing Like It's 2012",
    description = format("Collect the star 'Climb Out of the Dried Valley' in {0} without falling down (no fading out).", course_infos["Course 1"]["full name"]),
    points = 5,
    trigger = pause_lock_hacktice_in_level("Course 1")
        && remained_in_level("Course 1", hit=0)
        && object_is(ab_sand, "ab sand")
        && once(just_changed(object_action(ab_sand), 0, 1))
        && never(just_changed(object_action(ab_sand), 1, 2))
        && trigger_when(collecting_star_object("spawned star", 2)),
    id=264485, badge="292402"
)

ab_troll = nth_array_object(1)
achievement(
    title = "Gotta Face the Fire",
    description = format("Climb the Wall of Failure in {0} the wrong way and get denied the star.", course_infos["Course 1"]["full name"]),
    points = 1,
    trigger = pause_lock_hacktice_in_level("Course 1")
        //&& in_level("Course 1")
        && object_is(ab_troll, "ab troll")
        && airborne__mem == 0
        && object_distance_to_mario(ab_troll) > 100.0
        && object_distance_to_mario(ab_troll) < 400.0,
    id=264486, badge="292403"
)

got_one_red = nof_coins() == prev(nof_coins()) + 2

achievement(
    title = "Dry Diving",
    description = format("Collect the star 'An Abyss Deep Dive' in {0} without swimming.", course_infos["Course 1"]["full name"]),
    points = 5,
    trigger = pause_lock_hacktice_in_level("Course 1")
        && remained_in_level("Course 1", hit=1)
        && area__mem == 1
        && once(got_one_red)
        && never(just_increased(swimming__mem))
        && trigger_when(collecting_star_object("spawned star", 0)),
    id=264487, badge="292404"
)

// mission 1-5, mission 6 case
mtc_bricks = [nth_array_object(61), nth_array_object(64)]
achievement(
    title = "Too Fast for Me",
    description = format("Pick the wrong star in the Golden Bar Adventure and hear a voiceover."),
    points = 0,
    trigger = pause_lock_hacktice_in_level("Course 2")
        && any_of(mtc_bricks, o => object_is(o, "mtc brick")
        && just_changed(object_action(o), 7, 4)),
    id=264488, badge="292405"
)

// object invariant
mtc_red_ground = nth_array_object(32)
achievement(
    title = "Don't Need Magic, Only Patience",
    description = format("Collect the star 'Red Coins of the Lava Lake' in {0} without taking damage or pressing the L button in the lava lake.", course_infos["Course 2"]["full name"]),
    points = 4,
    trigger = pause_lock_hacktice_in_level("Course 2")
        && remained_in_level("Course 2", hit=1)
        && object_is(mtc_red_ground, "mtc red ground")
        && object_action(mtc_red_ground) == 1
        && never(object_action(mtc_red_ground) == 1 && just_took_damage())
        && never(object_action(mtc_red_ground) == 1 && just_increased(controller_l_button()))
        && trigger_when(collecting_star_object("spawned star", 0)),
    id=264489, badge="292406"
)

mtc_high_secrets = array_map([28, 29, 30, 31], i => nth_array_object(i))
achievement(
    title = "Another Acrobatic Flier",
    description = format("Collect the 4 highest secrets in {0} in one go, without touching the ground or entering a cannon in between.", course_infos["Course 2"]["full name"]),
    points = 4,
    trigger = pause_lock_hacktice_in_level("Course 2")
        && remained_in_level("Course 2", hit=0)
        && mission__mem == 6
        // start
        && tally_of(range(1, 4), 1, a => repeated(1, all_of(mtc_high_secrets, o => object_was(o, "hidden secret") && prev(object_active(o)) != 0) && pos_y() > 1000.0 &&mario_collision_check(object_nth_collided_object(mario_object(), a), "hidden secret", a)))
        // cancel
        && never(just_decreased(airborne__mem))
        && never(mario_action_changed_to("in cannon"))
        // submit
        && trigger_when(tally_of(range(1, 4), 4, a => repeated(4, pos_y() > 1000.0 &&mario_collision_check(object_nth_collided_object(mario_object(), a), "hidden secret", a)))),
    id=264490, badge="292407"
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
    title = "Way Far Ahead, Too Far Ahead...",
    description = format("Finish the race with Koopa the Quick in {0} in under 15 seconds.", course_infos["Course 3"]["full name"]),
    points = 5,
    trigger = pause_lock_hacktice_in_level("Course 3")
        && in_area("Course 3", 1)
        && hud_timer_shown() != 0
        && hud_timer__mem < int_seconds_to_frames(15)
        && any_of(array_map(range(0, 239), a => object_koopa_race_started_and_won(nth_array_object(a), trig=1)), b => b),
    id=264491, badge="292408"
)

leaderboard(
    title = "Koopa's Hopeful Race",
    description = format("WIN the race with Koopa the Quick in {0}.", course_infos["Course 3"]["full name"]),
    start = pause_lock_hacktice_in_level("Course 3")
        && in_area("Course 3", 1) && any_of(array_map(range(0, 239), a => object_koopa_race_started_and_won(nth_array_object(a), trig=0)), b => b),
    cancel = always_false(),
    submit = always_true(),
    value = hud_timer__mem*2,
    
    format="FRAMES",
    lower_is_better = true
)

leaderboard(
    title = "Good Sport Race",
    description = format("Let Koopa the Quick finish the race in {0}. (Talk to Koopa)", course_infos["Course 3"]["full name"]),
    start = pause_lock_hacktice_in_level("Course 3")
        && in_area("Course 3", 1) && just_changed(dialog_id__mem, 0x29, 0xFFFF),
    cancel = always_false(),
    submit = always_true(),
    value = hud_timer__mem*2,
    
    format="FRAMES",
    lower_is_better = true
)

achievement(
    title = "Desire to Avoid Hot Ground",
    description = format("Collect the star 'Burning Red Coins Desire' in {0} without getting burned.", course_infos["Course 3"]["full name"]),
    points = 3,
    trigger = pause_lock_hacktice_in_level("Course 3")
        && remained_in_level("Course 3", hit=1)
        && once(got_one_red)
        && never(area__mem == 1 && mario_action_changed_to("lava boost"))
        && trigger_when(collecting_star_object("spawned star", 2)),
    id=264492, badge="292409"
)

achievement(
    title = "Boundary Break",
    description = format("Collect the star 'Pound Wooden Posts for the Throws!' without pounding any wooden posts.", course_infos["Course 3"]["full name"]),
    points = 10,
    trigger = pause_lock_hacktice_in_level("Course 3")
        && remained_in_level("Course 3", hit=1)
        && never(ground_pounding_object("wooden post"))
        && collecting_star_object("regular star", 5),
    id=264493, badge="292410"
)

achievement(
    title = "Slipping Past the Thwomps",
    description = format("Collect the star 'Find the Trash Compactor' in {0} while still wearing your vanish cap.", course_infos["Course 4"]["full name"]),
    points = 5,
    trigger = pause_lock_hacktice_in_level("Course 4")
        && in_level("Course 4")
        && prev(wearing_vanish_cap()) != 0
        && trigger_when(collecting_star_object("regular star", 1)),
    id=264494, badge="292411"
)

achievement(
    title = "Too Cursed to Ride",
    description = format("Collect the star 'Frozen Shell Ride' in {0} without riding on any of the Joel's.", course_infos["Course 4"]["full name"]),
    points = 5,
    trigger = pause_lock_hacktice_in_level("Course 4")
        && remained_in_level("Course 4", hit=1)
        && once(object_changed_to(ridden_object(), "koopa shell"))
        && never(object_changed_to(stood_on_object(), "hf joel"))
        && trigger_when(collecting_star_object("regular star", 5)),
    id=264495, badge="292412"
)

achievement(
    title = "Not Exactly Out of Place in Space",
    description = "Find a crewmate in Dual Rush (must be on ground).",
    points = 1,
    trigger = pause_lock_hacktice_in_level("Dual Rush")
        && area__mem == 4
        && lakitu_state_goal_focus("z") < -25200.0
        && lakitu_state_goal_focus("z") > -26000.0
        && airborne__mem == 0,
    id=264496, badge="292413"
)

achievement(
    title = "Switchless Chute",
    description = format("Collect the star 'Death Shute' in {0} without pressing a purple switch.", course_infos["Course 5"]["full name"]),
    points = 3,
    trigger = pause_lock_hacktice_in_level("Course 5")
        && remained_in_level("Course 5", hit=1)
        //&& in_3d_box(0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
        && never(object_is(stood_on_object(), "scut switch") && just_changed(object_action(stood_on_object()), 0, 1))
        && trigger_when(collecting_star_object("regular star", 3)),
    id=264497, badge="292414"
)

achievement(
    title = "Big Boo Beatdown",
    description = format("Collect the star 'Villanous Penthouse' in {0} without pressing the purple switches more than once.", course_infos["Course 5"]["full name"]),
    points = 4,
    trigger = pause_lock_hacktice_in_level("Course 5")
        && remained_in_level("Course 5", hit=1)
        //&& pos_y() > 1000.0
        && never(repeated(2,object_is(stood_on_object(), "scut switch") && just_changed(object_action(stood_on_object()), 0, 1)))
        && trigger_when(collecting_star_object("spawned star", 5)),
    id=264498, badge="292415"
)

function object_bee_nest_broken(addr) =>
    object_is(addr, "exclamation box")
    && object_active(addr) != 0
    && object_subtype(addr) == 15 // specific to these boxes
    && just_changed_to(object_action(addr), 3)

// not star specific

spiders_death = nth_array_object(73)
// should be 9
spiders_nests = array_map(range(11, 19), a => nth_array_object(a))
achievement(
    title = "Hive Extermination",
    description = format("Destroy all 9 bee nests in {0} in one go without taking damage or falling out.", course_infos["Course 6"]["full name"]),
    points = 5,
    trigger = pause_lock_hacktice_in_level("Course 6")
        && remained_in_level("Course 6", hit=1) // mind water
        && never(just_increased(hp_decrement()))
        && never(any_of(burning_actions, a => mario_action_changed_to(a)))
        && never(object_is(spiders_death, "spiders death") && just_changed(object_action(spiders_death), 0, 1))
        && ((measured(tally(length(spiders_nests), array_map(spiders_nests, a => once(object_bee_nest_broken(a)))), when=in_level("Course 6")))
            || (tally(1, array_map(spiders_nests, a => once(object_bee_nest_broken(a)))) 
                && in_level("Course 6") && trigger_when(impossible_condition()))),
    id=264499, badge="292416"
)

achievement(
    title = "Sticky Jump Button",
    description = format("Collect all 8 red coins in {0} without pressing the A button. (can hold A before entering)", course_infos["Course 6"]["full name"]),
    points = 5,
    trigger = pause_lock_hacktice_in_level("Course 6")
        && remained_in_level("Course 6", hit=1)
        && never(warp_dest_type() == 0 && just_increased(controller_a_button()))
        && once(got_one_red)
        && trigger_when(tally(8, got_one_red)),
    id=264500, badge="292417"
)

achievement(
    title = "There Was No Money",
    description = format("Talk to the secret tarantula hawk in {0}. (hacktice allowed)", course_infos["Course 6"]["full name"]),
    points = 1,
    trigger = in_level("Course 6")
        && just_changed(dialog_id__mem, 0x28, 0xFFFF),
    id=264501, badge="292418"
)

achievement(
    title = "No Lift Needed, Just Jumps",
    description = format("Collect the star 'Secrets in the Cargo Room' in {0} without standing on the moving platform.", course_infos["Course 7"]["full name"]),
    points = 4,
    trigger = pause_lock_hacktice_in_level("Course 7")
        && remained_in_level("Course 7", hit=1)
        && never(object_changed_to(stood_on_object(), "luigiman platform"))
        && tally_of(range(1, 4), 1, a => repeated(1,mario_collision_check(object_nth_collided_object(mario_object(), a), "hidden secret", a)))
        && trigger_when(collecting_star_object("spawned star", 2)),
    id=264502, badge="292419"
)

achievement(
    title = "Low-Grav Collector",
    description = format("Collect the star 'Red Coin Planetary Ring' in {0} without falling out of the course.", course_infos["Course 7"]["full name"]),
    points = 5,
    trigger = pause_lock_hacktice_in_level("Course 7")
        && remained_in_level("Course 7", hit=1)
        && never(mario_action_changed_to("falling death exit"))
        && once(got_one_red)
        && trigger_when(collecting_star_object("spawned star", 1)),
    id=264503, badge="292420"
)

achievement(
    title = "Fluxium-Free Collection",
    description = format("Collect the star 'Conquer the Rusted Cogs' in {0} without time traveling.", course_infos["Course 8"]["full name"]),
    points = 10,
    trigger = pause_lock_hacktice_in_level("Course 8")
        && remained_in_level("Course 8", hit=1)
        && never(just_changed_to(music_tempo__mem, 0x1750))
        //&& once(got_one_red && music_tempo__mem == 0x1df4)// music tempo check)
        && trigger_when(collecting_star_object("spawned star", 3)),
    id=264504, badge="292421"
)

gUsedHyper__addr = 0x203025

// ratools rartedness, optimizing bitcount to 0xFF
achievement(
    title = "4-Dimensional Destructor",
    description = format("Destroy all 8 hypercube blocks in {0}.", course_infos["Course 8"]["full name"]),
    points = 3,
    trigger = pause_lock_hacktice_in_level("Course 8")
        && remained_in_level("Course 8", hit=0)
        && once(just_changed(bitcount(gUsedHyper__addr), 0, 1))
        && (measured(sum_of(range(0, 7), a => bit(a, gUsedHyper__addr)/bit(a, gUsedHyper__addr)) == 8, when=in_level("Course 8")) || trigger_when(bitcount(gUsedHyper__addr) == 8)),
    id=264505, badge="292422"
)

// side courses

achievement(
    title = "The Metal Cap Proves Useless Again",
    description = format("Collect the red coin star in {0} without getting a metal cap.", course_infos["Dice Fortress"]["full name"]),
    points = 2,
    trigger = pause_lock_hacktice_in_level("Dice Fortress")
        && remained_in_level("Dice Fortress", hit=1)
        && never(just_increased(wearing_metal_cap()))
        && once(got_one_red)
        && trigger_when(collecting_star_object("spawned star", 0)),
    id=264506, badge="292423"
)

mushie_ctl = nth_array_object(2)

achievement(
    title = "Predestined Dusty Gravity",
    description = format("Collect any 4 red coins in {0} without falling out of the course.", course_infos["Predestined Fate"]["full name"]),
    points = 4,
    trigger = pause_lock_hacktice_in_level("Predestined Fate")
        && remained_in_level("Predestined Fate", hit=0)
        && object_is(mushie_ctl, "mushie ctl")
        && never(just_changed(object_action(mushie_ctl), 0, 1))
        && ((measured(tally(4, got_one_red))) ||
            (once(got_one_red && prev(g_red_coins_collected__mem) < 5) && trigger_when(tally(4, got_one_red)))),
    id=264507, badge="292424"
)

// lel
achievement(
    title = "To the Moon, Again Again",
    description = format("Fall too high in the first overworld, and hear some fitting music as you game over."),
    points = 1,
    trigger = pause_lock_hacktice_in_level("Overworld 1")
        && repeated(180, music_id__mem == 0x2F)
        && never(just_changed_from(music_id__mem, 0x2F)),
    id=264508, badge="292425"
)

achievement(
    title = "Inb4 Brodute Patches This Skip",
    description = format("Collect the star in {0} without butt sliding.", course_infos["Slide"]["full name"]),
    points = 5,
    trigger = pause_lock_hacktice_in_level("Slide")
        && remained_in_level("Slide", hit=1)
        && never(mario_action_changed_to("butt slide"))
        && trigger_when(collecting_star_object("regular star", 0)),
    id=264509, badge="292426"
)

achievement(
    title = "Staircase Memory",
    description = format("Collect the star in {0} without pressing the button that opens the map.", course_infos["DNVIC"]["full name"]),
    points = 3,
    trigger = pause_lock_hacktice_in_level("DNVIC")
        && remained_in_level("DNVIC", hit=1)
        && never(just_increased(controller_l_button()))
        && trigger_when(collecting_star_object("regular star", 0)),
    id=264510, badge="292427"
)

achievement(
    title = "Unscathed Duo",
    description = format("Collect both stars in {0} without taking damage or falling out.", course_infos["Dual Rush"]["full name"]),
    points = 10,
    trigger = pause_lock_hacktice_in_level("Dual Rush")
        && remained_in_level("Dual Rush", hit=1)
        && never(just_increased(hp_decrement()))
        && never(any_of(burning_actions, a => mario_action_changed_to(a)))
        && never(just_changed(warp_dest_type(), 0, 3)) // fall out
        && unless(in_area("Dual Rush", 1) && warp_dest_node() == 0x31 && warp_dest_type() != 0)
        && trigger_when(collecting_star_object("regular star", 0)),
    id=264511, badge="292428"
)

achievement(
    title = "Can't Get Too Far Without the Shell",
    description = format("Get on top of the first arch after the beginning in {0}.", course_infos["LinCrash"]["full name"]),
    points = 3,
    trigger = pause_lock_hacktice_in_level("LinCrash")
        && in_level("LinCrash")
        && in_3d_box(-16000.0, -17000.0, 12000.0, 11300.0, -21000.0, -22000.0),
    id=264512, badge="292429"
)

golf_sphere = nth_array_object(1)
achievement(
    title = "Quick Par Shot",
    description = format("Within 3 seconds of entering the {0}, lock in the right rotation and collect the star on your first try.", course_infos["Sphere"]["full name"]),
    points = 4,
    trigger = pause_lock_hacktice_in_level("Sphere")
        && remained_in_level("Sphere", hit=1)
        && object_is(golf_sphere, "golf sphere")
        && never(repeated(int_seconds_to_frames(3)*2, object_action(golf_sphere) == 1))
        && never(just_changed(object_action(golf_sphere), 2, 1))
        && trigger_when(collecting_star_object("regular star", 0)),
    id=264513, badge="292430"
)

dan_bp = nth_array_object(2)
achievement(
    title = "The Run's Good, Hopefully",
    description = "Skip the banana peel cutscene.",
    points = 0,
    trigger = pause_lock_hacktice_in_level("GPTV")
        && in_level("GPTV")
        && object_is(dan_bp, "dan banana")
        && just_changed(object_action(dan_bp), 1, 50),
    id=264514, badge="292431"
)

achievement(
    title = "RNG Proof Platforming",
    description = format("Get to the other side of the castle area in {0} without getting a cap or standing on a cap box. (wait for cap to run out if gotten and return to respawn to try again)", course_infos["Medley"]["full name"]),
    points = 3,
    trigger = pause_lock_hacktice_in_level("Medley")
        && in_area("Medley", 1) && never(screen_changed())
        && once(pos_z() > 4300.0 && airborne__mem == 0 && wearing_wing_cap() == 0 && wearing_vanish_cap() == 0 && wearing_metal_cap() == 0) // in 3d box at start
        && never(just_increased(wearing_wing_cap()))
        && never(just_increased(wearing_metal_cap()))
        && never(just_increased(wearing_vanish_cap()))
        && never(object_changed_to(stood_on_object(), "exclamation box"))
        && trigger_when(pos_z() < -1800.0),
    id=264515, badge="292432"
)

// funny lb
leaderboard(
    title = "RNG Red Coins",
    description = format("Collect as many red coins in the last area of {0} as possible.", course_infos["Medley"]["full name"]),
    start = in_level("Medley") && just_changed_to(area__mem, 7),
    cancel = hacktice_enabled() != 0 || level_changed(),
    submit = collecting_star_object("spawned star", 6),
    value = nof_coins() / 2,
    format = "VALUE",
    lower_is_better = false
)

aglab_fight = nth_array_object(1)
achievement(
    title = "Another Boss Battle... Test",
    description = "Defeat Bowser without taking damage.",
    points = 10,
    trigger = pause_lock_hacktice_in_level("Bowser Battle")
        && remained_in_level("Bowser Battle", hit=1)
        && object_is(aglab_fight, "aglab fight")
        && once(just_changed(object_action(aglab_fight), 0, 1))
        && never(just_took_damage())
        && trigger_when(just_changed(object_action(aglab_fight), 8, 9)),
    id=264516, badge="292433"
)

gCutsceneDialogID = 0x20e1b8

axo_submit = object_changed_to(object_cutscene(), "spawned star")
    && object_star_mission(object_cutscene()) == 0
axo_value = word(gCutsceneDialogID)

achievement(
    title = "Ace Tracing",
    description = format("Get at least 90% accuracy in {0}. (cannot check accuracy if star already spawned)", course_infos["Flipnote"]["full name"]),
    points = 10,
    trigger = pause_lock_hacktice_in_level("Flipnote")
        && in_level("Flipnote")
        && axo_submit
        && axo_value >= 90
        && axo_value <= 100,
    id=264517, badge="292434"
)

leaderboard(
    title = "Tracing Champion",
    description = format("Get the highest accuracy (percentage) in {0}. (cannot submit if star already spawned)", course_infos["Flipnote"]["full name"]),
    start = pause_lock_hacktice_in_level("Flipnote")
        && in_level("Flipnote")
        && axo_submit,
    cancel = always_false(),
    submit = always_true(),
    value = axo_value,
    
    format="VALUE",
    lower_is_better = false
)

// blue coins
function blue_coin_meta(title, level, points, coin_count, id=0, badge="") => {"title": title, "level": level, "points": points, "count": coin_count, "id":id, "badge":badge}

blue_coins = [
    blue_coin_meta("Azure Coins",               "Course 1", 3, 7, id=264518, badge="292435"),
    blue_coin_meta("Molten Treasures",          "Course 2", 4, 6, id=264519, badge="292436"),
    blue_coin_meta("Blue Cards, I Mean Coins",  "Course 3", 2, 7, id=264520, badge="292437"),
    blue_coin_meta("Haunted Blues",             "Course 4", 3, 11, id=264521, badge="292438"),
    blue_coin_meta("Double the Switches, Half the Effort",     "Course 5", 2, 6, id=264522, badge="292439"),
    blue_coin_meta("Tricky Sticky Coins",              "Course 6",10, 8, id=264523, badge="292440"),
    blue_coin_meta("Space Currency",            "Course 7", 3, 5, id=264524, badge="292441"),
    blue_coin_meta("A Timer 40 Years Back",     "Course 8", 5, 10, id=264525, badge="292442"),
]

for bc in blue_coins {
    achievement(
        title = bc["title"],
        description = format("Collect all {0} switch blue coins in {1}.", bc["count"], course_infos[bc["level"]]["full name"]),
        points = bc["points"],
        trigger = pause_lock_hacktice_in_level(bc["level"])
            && remained_in_level(bc["level"], hit=0)
            && measured(tally_of(range(1, 4), bc["count"], a => repeated(bc["count"] ,mario_collision_check(object_nth_collided_object(mario_object(), a), "blue coin for block", a))), when=in_level(bc["level"])),
        id = bc["id"],
        badge = bc["badge"]
    )
}

// RP

stars__value = rich_presence_value("Number", nof_stars())

meta_descriptions = {
    0x00: "Starting up the game",
    //0x02: "Playing with Mario head",
    0x21: "In File Select",
}

general_level_dict = {
    0x1a: "having his emulator checked",
    0x10: "on the floating platforms of the first overworld",
    0x06: "crossing a familiar bridge in the second overworld",
    
    0x28: "on a timed dicey mission in the good old fortress",
    0x2c: "impersonating Captain Viridian in Predestined Fate",
    0x27: "jamming along the Azure Abyss",
    0x2a: "plundering the Molten Treasure Chest",
    0x1b: "sliding on some rough sand",
    0x29: "collecting stars in the Flower Fields of Makai",
    0x12: "solving puzzles in the Palace of Earth Spirits",
    0x2b: "traversing spooky platforms in Haunted Factory",
    0x1f: "getting lost in the Grain Silo Ruins",
    0x09: "keeping his footing in the Abandoned Catacombs",
    0x14: "on a dual adventure with Luigi",
    0x1d: "drawing in Flipnote Studio with suboptimal controls",
    0x2e: "riding a shell to the end of the tunnel in Ashellerated Automata",
    0x1c: "climbing the Ancient Gear Tower",
    
    0x2f: "getting all sticky in Honeyhive Falls",
    0x32: "rummaging through the Dead Space Base",
    0x34: "playing golf in a familiar sphere",
    0x30: "using magic fluxium in Time Travel Ruins",
    0x33: "on a fruitful journey with bananas",
    0x31: "rerolling in Star Gazed Medley",
    
    0x2d: "taking on Bowser's Diorama Fortress",
    0x21: "battling Bowser yet again",
}

level__lookup = rich_presence_lookup("LevelsWithoutSublevels", level_id__mem, general_level_dict, "in an unbeknownst location")

file__lookup  = rich_presence_lookup("File", file_num__mem, { 0x01: "A", 0x02: "B", 0x03: "C", 0x04: "D"}, "?")

function rp_cond_same_display(cond, lookup, cheat_text="") {
    rich_presence_conditional_display(cond, 
    "Mario-{2} is {0}{3} with {1}⭐", lookup, stars__value, file__lookup, cheat_text
    )
}

cond_displays = [
    {"cond": (once(hacktice_enabled() != 0) && never(level_changed()) && mem_in(level_id__mem, general_level_dict)), "lookup": level__lookup, "cheat text": " and CHEATING"},
    {"cond": (mem_in(level_id__mem, general_level_dict)), "lookup": level__lookup, "cheat text":""},
]

rich_presence_conditional_display(in_intro_or_file_select() || level_id__mem == 1, "{0}", rich_presence_lookup("Fileless", music_id__mem, meta_descriptions))
rich_presence_conditional_display(credits_entry__mem != 0, "In the credits of this incredible collab.")
rich_presence_conditional_display(nof_stars() > 80 && nof_stars() < 255, "Mario is breaking the game with {0}⭐ (no RP for you)", stars__value)
for k in cond_displays {
    rp_cond_same_display(k["cond"], k["lookup"], k["cheat text"])
}
rich_presence_display("On a multi-faceted journey through old and new levels.")