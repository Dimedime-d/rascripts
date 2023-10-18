// ~Hack~ Super Mario 74: The Twelve Year Comet
// #ID = 26548
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
    "TITLE SCREEN GEO":     0x104610, // -> 104e50 after credits loop

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
function controller_d_pad() => low4(controller() + 0x13)

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
    "neutral enter":               0x00001932,
    
    "death exit landing":          0x00020467,
    "burning ground":              0x00020449,
    "burning jump":                0x010208B4,
    "burning fall":                0x010208B5,
    
    "ground pound":                0x008008A9,
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
    "type":             0x02, // word
    "related object":   0x2C // dword (pointer to object, if applicable)
}
surface__sizeof = 0x30

function surface_field(base, field) => struct_field(surface__struct, base, field)

function surface_type(addr) => word(surface_field(addr, "type"))
function surface_object(addr) => tbyte(surface_field(addr, "related object"))

function qslg() => mario_action_changed_to("ledge grab") && surface_type(mario_floor_tri()) == 0x23 // 0x23 = instant quicksand
function on_horiz_wind() => just_changed_to(surface_type(mario_floor_tri()), 0x2C) // 0x2c = horiz wind

// ----------------- //
//     a r e a s     //
// ----------------- //

// https://github.com/n64decomp/sm64/blob/9921382a68bb0c865e5e45eb594d9c64db59b1af/src/game/area.h#L57
// use case would be to pick out the title screen / file select

area__struct = {
    "index":            0x03, // 8-bit
    "geo layout":       0x04, // pointer
    "object spawn infos":0x20, // pointer
    "camera":           0x24, // pointer
}
area__sizeof = 0x40

function area_field(base, field) => struct_field(area__struct, base, field)

function area_index(addr) => byte(area_field(addr, "index"))
function area_camera(addr) => tbyte(area_field(addr, "camera"))
function area_object_spawn_infos(addr) => tbyte(area_field(addr, "object spawn infos"))
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

// remember, when using as a pointer, use tbyte
function object_behav_script(addr) => tbyte(object_field(addr, "behaviour script"))
function object_is(addr, name) => object_behavior_check(addr, object_behavior_checks[name], delta=0)
function object_was(addr, name) => object_behavior_check(addr, object_behavior_checks[name], delta=1)
function object_changed_to(addr, name) => !object_was(addr, name) && object_is(addr, name)

// these checks gotta be unique
// also, just do simple offset checks, no more nested pointers...
function bhv_cmd_check_meta(offset, type, value) => {"offset": offset, "type": type, "value": value}
object_behavior_checks = {
    "file manager":     bhv_cmd_check_meta(0x1c, "dword", 0x80173430),
    
    //!! cannot distinguish between grills/objects/boxes switch
    "purple box switch":bhv_cmd_check_meta(0x0c, "dword", 0x13001488),
    
    "blue coin block":   bhv_cmd_check_meta(0x18, "dword", 0x802c242c), // different from new earth
    
    "stationary 1-up":  bhv_cmd_check_meta(0x30, "dword", 0x802f45b8),
    "impartial 1-up":   bhv_cmd_check_meta(0x2c, "dword", 0x802f40cc),
    "running away 1-up":bhv_cmd_check_meta(0x2c, "dword", 0x802f4248),
    
    "warp":             bhv_cmd_check_meta(0x18, "dword", 0x802aaa60),
    "warp pipe":        bhv_cmd_check_meta(0x2c, "dword", 0x802aaa60), // both warp/warp pipe call same asm update function, but warp pipe loads extra geometry
    "teleporter":       bhv_cmd_check_meta(0x1c, "dword", 0x802aab54),
    
    "blue coin for block":bhv_cmd_check_meta(0x2c, "dword", 0x802c22b8),
    
    "koopa flag checkpoint": bhv_cmd_check_meta(0x24, "dword", 0x06001028),
    
    "eyerok manager":       bhv_cmd_check_meta(0x14, "dword", 0x8030ea9c),
    
    "mission star manager":             bhv_cmd_check_meta(0x18, "dword", 0x80176DF0),
    
    "grabbable cork box":             bhv_cmd_check_meta(0x24, "dword", 0x0802f6228),
    "koopa shell":             bhv_cmd_check_meta(0x24, "dword", 0x0802bd680),
}

function object_behavior_check(addr, check, delta=0) {
    offset = check["offset"]
    type = check["type"]
    value = check["value"]
    if (delta > 0)
        return prev(mem_access(object_behav_script(addr) + offset, type)) == value
    else
        return mem_access(object_behav_script(addr) + offset, type) == value
}

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
hud_timer__mem = word(hud_timer__addr)

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

g_curr_credits_entry__addr = offsets["CREDITS ENTRY"]
g_curr_credits_entry__mem  = tbyte(g_curr_credits_entry__addr)

time_stop_state__addr = offsets["TIME STOP STATE"]
function time_stop_enabled() => bit(1, time_stop_state__addr)

function course_meta(value, sublevel_values, full_name, clean_name="0") {
    if (clean_name == "0")
        return {"value": value, "sublevel values": sublevel_values, "full name": full_name, "clean name": full_name}
    return {"value": value, "sublevel values": sublevel_values, "full name": full_name, "clean name": clean_name}
}

course_infos = {
    "Castle Grounds":       course_meta(0x10, [-1],   "the Original Castle Grounds"),
    "Castle Courtyard":     course_meta(0x1A, [-1],   "the first overworld"),
    "Cloud Stage":          course_meta(0x1f, [-1],   "the Training Grounds"),
    "Inside Castle":        course_meta(0x06, [-1],   "the third overworld"),
    
    
    "Course 1":         course_meta(0x09, [-1],   "Dice Domain"),
    "Course 2":         course_meta(0x18, [-1],   "Concrete Jungle"),
    "Course 3":         course_meta(0x0c, [-1],   "Wallowing Wells"),
    "Course 4":         course_meta(0x05, [-1],   "Bogey Bayou"),
    "Course 5":         course_meta(0x04, [-1],   "Flamework Factory"),
    "Course 6":         course_meta(0x07, [-1],   "Stalactite Cave"),
    "Course 7":         course_meta(0x16, [-1],   "Crumble Rumble Tower"),
    "Course 8":         course_meta(0x08, [-1],   "Absolute Zeroasis"),
    "Course 9":         course_meta(0x17, [-1],   "Nature Nocturne"),
    "Course 10":        course_meta(0x0a, [-1],   "Quicksand Beach"),
    "Course 11":        course_meta(0x0b, [-1],   "Polluted Pond"),
    "Course 12":        course_meta(0x24, [-1],   "Cliff of Time"),
    "Course 13":        course_meta(0x0d, [-1],   "Sea Salt Peaks"), //THI
    "Course 14":        course_meta(0x0e, [-1],   "Venenium-Sphere"), //TTC
    "Course 15":        course_meta(0x0f, [-1],    "Delombru-Sphere"),
    
    "Metal Cap":         course_meta(0x1c, [-1],   "Aerial Alpine"), // MC
    "Wing Cap":          course_meta(0x1d, [-1],   "Lava Pit of Inversion"), // WC
    "Vanish Cap":        course_meta(0x12, [-1],   "Dusty Darkness"), // VC
    
    "Aquarium":         course_meta(0x14, [-1],   "Void of the East"),
    "Slide":            course_meta(0x1b, [-1],   "Underground Slide"),
    "End Cake Picture": course_meta(0x19, [-1],   "Grandmaster's Goal"),
    "GG Race":          course_meta(0x19, [1], "Grandmaster's Goal"),
    "GG Main":          course_meta(0x19, [2, 3, 4, 5], "Grandmaster's Goal"),
    "Ending":           course_meta(0x19, [6],    "Grandmaster's Goal"),

    "Bowser 1":         course_meta(0x11, [-1],   "Bowser's Park Party"),
    "Key 1":            course_meta(0x1e, [-1],   "Bowser's Park Party"),
    "Bowser 2":         course_meta(0x13, [-1],   "Bowser's Tidal Tropics"),
    "Key 2":            course_meta(0x21, [-1],   "Bowser's Tidal Tropics"),
    "Bowser 3":         course_meta(0x15, [-1],   "Bowser's Rainbow Realm"),
    "Final Fight":      course_meta(0x22, [-1],   "Bowser's Rainbow Realm"),
}

function in_title_screen() => area_object_spawn_infos(current_area__mem) == 0x00
    && music_id__mem != 0x20 && music_id__mem != 0x1A
    && warp_transition_pause_rendering() == 0x00
// Dilemma - with the end cake picture returning you to title screen, the mario state, level data, etc. are preserved. We need to use memory that updates accordingly with the title screen, but the geometry layout unfortunately gets shifted.
// workaround - 3 checks - object infos of current area is empty (0x00) (only title screen/mario head/end cake picture should lack objects)
// music id NOT 0x20 or 0x1a (credits)
// warp transition IS rendering (the first check can be falsely true during warp transitions)

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
        
    // HACK
    if (name == "GG Main") {
        return sublevel_id__mem >= 2 && sublevel_id__mem <= 5
    }
    
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
    milestone_meta("Comet Completion",
        "Collect all 101 green stars.",
        stars=101, points=50),
]

function milestone_cheevs() {
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
}

milestone_cheevs()

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
    title = "He Could Fix the End Credits, but Not the End Picture",
    description = "Collect the fake star in the ending (Triarc).",
    points = 1,
    trigger = in_level("Ending") && collected_star_action_check()
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
    course_stars_meta("Course 1", sum_star_bits(0x0f, range(0,3)), 5, "Silent Green Devils", id=344846, badge="389933"), 
    course_stars_meta("Course 2", sum_star_bits(0x0e, range(0,4)), 10, "Stars Blending In", id=344847, badge="389934"),
    course_stars_meta("Course 3", sum_star_bits(0x0d, range(0,4)), 10, "Green Flood", id=344848, badge="389935"),
    course_stars_meta("Course 4", sum_star_bits(0x0c, range(0,2)), 10, "Comet Visiting Downtown", id=344849, badge="389936"),
    course_stars_meta("Course 5", sum_star_bits(0x13, range(0,3)), 10, "The Bullies' Greens", id=344850, badge="389937"),
    course_stars_meta("Course 6", sum_star_bits(0x12, range(0,2)), 5, "Back to Being Trivial", id=344851, badge="389938"),
    course_stars_meta("Course 7", sum_star_bits(0x11, range(0,3)), 10, "Rocky Green Road", id=344852, badge="389939"),
    course_stars_meta("Course 8", sum_star_bits(0x10, range(0,3)), 10, "Left Behind Overgrown Greens", id=344853, badge="389940"),
    course_stars_meta("Course 9", sum_star_bits(0x17, range(0,4)), 10, "Nighttime Flower Greens", id=344854, badge="389941"),
    course_stars_meta("Course 10", sum_star_bits(0x16, range(0,4)), 10, "Green Shines Across the Beach", id=344855, badge="389942"),
    course_stars_meta("Course 11", sum_star_bits(0x15, range(0,3)), 10, "Green Stars Back From the Grave", id=344856, badge="389943"),
    course_stars_meta("Course 12", sum_star_bits(0x14, range(0,5)), 25, "Green Cliff Lookout", id=344857, badge="389944"),
    course_stars_meta("Course 13", sum_star_bits(0x1b, range(0,3)), 10, "Shining Greens Over the Peaks", id=344858, badge="389945"),
    course_stars_meta("Course 14", sum_star_bits(0x1a, range(0,4)), 25, "Green Sparkles of Hope", id=344859, badge="389946"),
    course_stars_meta("Course 15", sum_star_bits(0x19, range(0,3)), 25, "Green Stars of Despair", id=344860, badge="389947"),
    
    course_stars_meta("Bowser 1",  sum_star_bits(0x18, range(0,1)), 3, "Green Party Balloons", id=344861, badge="389948"),
    course_stars_meta("Bowser 2",  sum_star_bits(0x1f, range(0,2)), 10, "Drowned Sunken Greens", id=344862, badge="389949"),
    course_stars_meta("Bowser 3",  sum_star_bits(0x1e, range(0,3)), 10, "Sparkling Green Crystals", id=344863, badge="389950"),
    
    course_stars_meta("Metal Cap",  sum_star_bits(0x1c, range(0,2)), 10, "Airy Stored Green Stars", id=344864, badge="389951"),
    course_stars_meta("Vanish Cap", sum_star_bits(0x22, range(0,2)), 10, "They Stand Out More Here", id=344865, badge="389952"),
    course_stars_meta("Wing Cap",   sum_star_bits(0x23, range(0,1)), 3, "Blazing Green Bath", id=344866, badge="389953"),
    
    course_stars_meta("Slide",      sum_star_bits(0x1d, range(0,2)), 10, "Mining Green Minerals", id=344867, badge="389954"), // Slide
    course_stars_meta("Aquarium",   sum_star_bits(0x20, range(0,2)), 10, "Green Comet Shards in the Void", id=344868, badge="389955"), // VE
    course_stars_meta("Cloud Stage",sum_star_bits(0x21, range(0,2)), 10, "Training to Jump Differently", id=344869, badge="389956"), // OW2
    course_stars_meta("End Cake Picture", sum_star_bits(0x27, range(0, 4)), 25, "Grandmaster's Greens")
    
]
function course_star_achievements(ignore_ids=0) {
    for info in course_offsets {
        course = info["course"]
        bits = info["star bits"]["mem"]
        star_count = info["star bits"]["sum"]
        star_qty = dict_lookup({
            1: "the star in",
            2: "both stars in",
            3: "all 3 stars in",
            4: "all 4 stars in",
            5: "all 5 stars in",
            6: "all 6 stars in",
            7: "all 7 stars in"
        }, star_count)
        
        star_qty = "every green star in"
        
        if (course == "End Cake Picture") {
            star_qty = "all green stars in ALL parts of"
        }
        
        title = info["title"]
        description = format("Collect {0} {1}{2}.",
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
    sum_star_bits(0x0b, range(0, 4))
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
    stars = overworld_stars, total=5,
    title = "Greens Out of Reach",
    description = "Collect all green stars across the first and third overworlds.",
    points = 10
)


// 1-ups

// Let tallies be a list of dicts of form
// {"type": (type of 1up), "count": (number of this type to count)}
// 
function tally_all_1ups(tallies=[], total_count=0, level_check=always_true())
{
    mushie_tally = []
    
    for t in tallies {
        obj_name = format("{0} 1-up", t["type"])

        for i in range(1,4) {
            obj_addr = object_nth_collided_object(mario_object(), i)
            
            coll_check = mario_collision_check(obj_addr, obj_name, i) && level_check
            
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

]

function mushie_cheevs() {
    for dict in mushies_data {
        course = dict["course"]
        
        mushie_count = sum_of(dict["tallies"], t => t["count"])
        
        mushie_tally = tally_all_1ups(tallies = dict["tallies"], total_count = mushie_count)
        trigger_tally = tally_all_1ups(tallies = dict["tallies"], total_count = 1)
        
        if (course == "GG Race" || course == "GG Main" || course == "Ending") {
            mushie_tally = tally_all_1ups(tallies = dict["tallies"], total_count = mushie_count, level_check = in_level(course))
        }
        
        collect_cond = always_true()
        
        if (mushie_count == 1) {
            collect_cond = mushie_tally
        }
        else {
            collect_cond = measured(mushie_tally, when=in_level(course)) || (trigger_tally && trigger_when(impossible_condition()))
        }

        core_level_check = remained_in_level(course, hit=0)
        
        achievement(
            title = dict["title"],
            description = format(dict["description"], course_infos[course]["clean name"]),
            points = dict["points"],
            trigger = core_level_check
                && collect_cond,
            id=dict["id"],
            badge=dict["badge"]
            )
    }
}

//mushie_cheevs()

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

function blue_coin_achievements() {
    function blue_coin_meta(title, level, points, coin_count, id=0, badge="") => {"title": title, "level": level, "points": points, "count": coin_count, "id":id, "badge":badge}

    blue_coins = [
    ]
    
    for bc in blue_coins {
        bc_title = bc["title"]
        bc_description = format("Collect all {0} switch blue coins in {1}.", bc["count"], course_infos[bc["level"]]["full name"])
        extra_logic = always_true()
        
        if (bc["level"] == "Course 11") {
            bc_description = bc_description + " (2 switches)"
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

//blue_coin_achievements()

// side challenge time...

achievement(
    title = "Daredevil Dice",
    description = "Collect Green Star 3 in Course 1 without riding a Koopa Shell.",
    points = 5,
    trigger = remained_in_level("Course 1", hit=1)
        && never(object_changed_to(ridden_object(), "koopa shell"))
        && trigger_when(collected_star_action_check(3))
)

achievement(
    title = "Clean Jump From Tower",
    description = "Collect Green Star 4 in Course 2 without ground pounding.",
    points = 5,
    trigger = remained_in_level("Course 2", hit=1)
        && never(mario_action_changed_to("ground pound"))
        && trigger_when(collected_star_action_check(4))
)

achievement(
    title = "Training Exercise",
    description = "Collect Green Star 2 in the Training Grounds (corner) while holding a cork box.",
    points = 10,
    trigger = in_level("Cloud Stage")
        && object_was(held_object(), "grabbable cork box")
        && trigger_when(collected_star_action_check(2))
)

achievement(
    title = "Hold Your Breath",
    description = "Collect Green Star 1 in Course 6 without going below 7 HP.",
    points = 5,
    trigger = remained_in_level("Course 6", hit=1)
        && never(hp() < 0x700)
        && trigger_when(collected_star_action_check(1))
)

achievement(
    title = "No Detour Needed",
    description = "Collect Green Star 2 in Course 10 without riding a Koopa Shell.",
    points = 2,
    trigger = remained_in_level("Course 10", hit=1)
        && never(object_changed_to(ridden_object(), "koopa shell"))
        && trigger_when(collected_star_action_check(2))
)

achievement(
    title = "Default Angle Works Fine",
    description = "Collect Green Star 3 in Course 12 without using the D-Pad.",
    points = 10,
    trigger = remained_in_level("Course 12", hit=1)
        && sublevel_id__mem == 2
        && never(controller_d_pad() != 0)
        && trigger_when(collected_star_action_check(3))
)

ending_signs = [
    94, 96, 97, 98, 102, 103, 113, 129, 130, 131, 34, 95 
]

achievement(
    title = "Triarc Gamers",
    description = "Read all 12 reachable signs in the ending area (Triarc).",
    points = 2,
    trigger = remained_in_level("Ending", hit=0)
        && measured(tally_of(ending_signs, 12, a => once(dialog_id__mem == a)))
)


// RP

general_level_dict = {
    0x0000: "kicking up slopes in the first overworld", // 
    0x1A01: "kicking up slopes in the first overworld", // Castle courtyard (OW3) is OW1
    0x1001: "back at Peach's Castle grounds after all these years...", // OW1
    0x1F01: format("practicing marginally different jumps in {0}", course_infos["Cloud Stage"]["full name"]), // cloud stage is OW2
    0x0601: "outside the trials of the Master Temple", // Inside castle (OW2) is OW3
    
    0x0901: format("starting his green star journey in {0}", course_infos["Course 1"]["full name"]),
    0x1801: format("looking for camouflaged green stars in {0}", course_infos["Course 2"]["full name"]),
    0x0C01: format("taking a green dive in {0}", course_infos["Course 3"]["full name"]),
    0x0501: format("revisiting the dead town in {0}", course_infos["Course 4"]["full name"]),
    0x0401: format("plundering the {0} for green stars", course_infos["Course 5"]["full name"]),

    0x0701: format("searching for undersea green stars in {0}", course_infos["Course 6"]["full name"]),
    0x0702: format("swimming through dark sewers in {0}", course_infos["Course 6"]["full name"]),
    0x1601: format("re-climbing the {0}", course_infos["Course 7"]["full name"]),
    0x0801: format("prospecting for green stars in {0}", course_infos["Course 8"]["full name"]),
    0x0802: format("in the temple for some reason in {0}", course_infos["Course 8"]["full name"]),
    0x1701: format("hunting for green stars in {0}", course_infos["Course 9"]["full name"]),
    0x0A01: format("staying above quicksand for green stars {0}", course_infos["Course 10"]["full name"]),
    
    0x0B01: format("looking for green garbage in {0}", course_infos["Course 11"]["full name"]),
    // 0x2401: format("taking risks over lava in {0}", course_infos["Course 12"]["full name"]), area 1 is unused
    0x2402: format("climbing the wrathful {0}", course_infos["Course 12"]["full name"]),
    0x2403: format("probably dying over and over again on the painful {0}", course_infos["Course 12"]["full name"]),
    0x0D01: format("swimming for green stars in {0}", course_infos["Course 13"]["full name"]),
    0x0E01: format("on a hopeful green quest through the {0}", course_infos["Course 14"]["full name"]),
    0x0F01: format("looking for easier green stars in {0}", course_infos["Course 15"]["full name"]),
    
    0x1C01: format("nearly freezing for floating green stars in {0}", course_infos["Metal Cap"]["full name"]),
    0x1D01: format("flying for free stars through the {0}", course_infos["Wing Cap"]["full name"]),
    0x1201: format("only able to see green stars in {0}", course_infos["Vanish Cap"]["full name"]),
    
    0x1B01: format("sliding around for green stars in {0}", course_infos["Slide"]["full name"]),
    0x1401: format("back at the {0} for green stars", course_infos["Aquarium"]["full name"]),
    0x1901: format("visiting the basically unchanged Champion's Challenge in {0}", course_infos["End Cake Picture"]["full name"]),
    0x1902: format("on a green star gauntlet in {0}", course_infos["End Cake Picture"]["full name"]),
    0x1903: format("on a green star gauntlet in {0}", course_infos["End Cake Picture"]["full name"]),
    0x1904: format("on a green star gauntlet in {0}", course_infos["End Cake Picture"]["full name"]),
    0x1905: format("on a green star gauntlet in {0}", course_infos["End Cake Picture"]["full name"]),
    0x1906: format("finishing his green star journey in {0}", course_infos["End Cake Picture"]["full name"]),

    0x1101: format("soaring to the skies in {0}", course_infos["Bowser 1"]["full name"]),
    //0x1E01: format("fighting Piranha Plants in {0}", course_infos["Key 1"]["full name"]),
    0x1301: format("sifting for green stars in {0}", course_infos["Bowser 2"]["full name"]),
    //0x2101: format("leaping across quicksand pits in {0}", course_infos["Key 2"]["full name"]),
    0x1501: format("outside Bowser's empty final hideout {0}", course_infos["Bowser 3"]["full name"]),
    0x1502: format("thankful he doesn't have to open the cannon again in {0}", course_infos["Bowser 3"]["full name"]),
    //0x2201: format("fighting Bowser yet again in {0}", course_infos["Final Fight"]["full name"]),
}

level__lookup = rich_presence_lookup("Levels", warp_dest_level_area(), general_level_dict, "in an unbeknownst location")

stars__value = rich_presence_value("Number", nof_stars())
lives__value = rich_presence_value("Number", (byte(nof_lives__addr) ) - (bit7(nof_lives__addr) * 256))
level_test__value = rich_presence_value("Number", warp_dest_level_area())

file__lookup  = rich_presence_lookup("File", file_num__mem, {
    0x01: "A", 0x02: "B", 0x03: "C", 0x04: "D"
}, "??")

a_presses__value = rich_presence_value("Number", never(level_changed()) && measured(repeated(0, warp_dest_type() == 0 && just_increased(controller_a_button()))))

rich_presence_conditional_display(in_title_screen(), "Starting up a new green 74xEE adventure. (Title Screen / Mario Head)")
rich_presence_conditional_display(g_curr_credits_entry__mem != 0, "Watching the fully functional end credits!") // the way this is set up, the credits entry is stale on the title screen, so the music checks catch the title screen state in the condition above
rich_presence_conditional_display(in_file_select(), 
    "Starting up a new green 74xEE adventure. (File Select)")
rich_presence_conditional_display(
    level_id__mem != 1 && (music_id__mem != 0x21 || effective_mario_object() != 0), // both are false on file select, including after game over
      "Mario-{2} is {0} with {1}⭐", level__lookup, stars__value, file__lookup, 
        rich_presence_lookup("Switch", pressed_switch__mem("red"), {1:"▣"}, "▢"),
        rich_presence_lookup("Switch", pressed_switch__mem("green"), {1:"▣"}, "▢"),
        rich_presence_lookup("Switch", pressed_switch__mem("blue"), {1:"▣"}, "▢")
    )
rich_presence_display("On a new green 74xEE adventure.")