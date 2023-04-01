// ~Hack~ Plutonium Mario 64
// #ID = 16761
// Made in RATools v1.8.5

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

offsets = {
    "SAVE DATA":    (0x207700 - 0x70),
    
    "MUSIC ID":     0x22261e,

    "COLLECTED STAR ID":    0x32dd87, // 1-indexed
    "FILE ID":              0x32ddf6,
    "MAP ID":               0x32ddfa,
    
    "STOOD ON OBJECT":      0x330e34,
    "DIALOGUE ID":          0x331486,
    
    "LEVEL INDEX":      0x33bac6,
    "SUBMAP ID":        0x33b249,
    
    "TIME COUNTING":    0x33b25e,
    "HUD FLAGS":        0x33b268,   //  https://github.com/n64decomp/sm64/blob/1372ae1bb7cbedc03df366393188f4f05dcfc422/src/game/level_update.h#L91
    "HUD TIMER":        0x33b26e,
    
    "TRANSITION TYPE":  0x33bab2,
    
    "MARIO STRUCT":     0x33b170,
    "OBJECT ARRAY":     0x33d488,
    
    "RED COINS COLLECTED":  0x3613fd,
}

// https://retroachievements.org/ticketmanager.php?i=51203
// End cake picture to title screen shifts behavior script values, so must check what they point to!

// these checks gotta be unique
// also, just do simple offset checks, no more nested pointers...
function bhv_cmd_check_meta(offset, type, value) => {"offset": offset, "type": type, "value": value}
object_behavior_checks = {
    //!! cannot distinguish between grills/objects/boxes switch
    "purple box switch":bhv_cmd_check_meta(0x0c, "dword", 0x13001488),
    "koopa shell":      bhv_cmd_check_meta(0x24, "dword", 0x802bd680),
    
    //!! cannot distinguish between ordinary boo and merry go round boo
    "boo":              bhv_cmd_check_meta(0x0c, "dword", 0x13002808),
    "boo activates text":bhv_cmd_check_meta(0x54, "dword", 0x802c3440),
    "small chill bully":bhv_cmd_check_meta(0x20, "dword", 0x802eb05c),
    "crate":            bhv_cmd_check_meta(0x1c, "dword", 0x803839cc),
    "ice cube":         bhv_cmd_check_meta(0x18, "dword", 0x802f084c),
    
    "impartial 1-up":   bhv_cmd_check_meta(0x2c, "dword", 0x802f40cc),
    "running away 1-up":bhv_cmd_check_meta(0x2c, "dword", 0x802f4248),
    "stationary 1-up":  bhv_cmd_check_meta(0x30, "dword", 0x802f45b8),
    "chasing 1-up":     bhv_cmd_check_meta(0x30, "dword", 0x802f496c),
    "1-up in pole activator": bhv_cmd_check_meta(0x1c, "dword", 0x802f4b00),
    
    "stationary star":  bhv_cmd_check_meta(0x20, "dword", 0x802f25b0),
    "spawned star":     bhv_cmd_check_meta(0x20, "dword", 0x802f2768),
    
    "skeeter":          bhv_cmd_check_meta(0x30, "dword", 0x80313110),
}
//behaviour_script__values = { 
//    //"large cork box":   0x800EC660,
//    "purple box switch":0x800EC62C,
//    "koopa shell":      0x800ED0BC,
//    //"exclamation box":  0x800ED3D0,
//    
//    "boo":              0x800ED964,
//    "boo activates text":0x800ED984,
//    "small chill bully":0x800EE848,
//    "crate":            0x800EED24,
//    "ice cube":         0x800EEDD8,
//
//    "impartial 1-up":   0x800EF15C,
//    "stationary 1-up":  0x800EF1FC,
//    "running away 1-up":0x800EF190,
//    "chasing 1-up":     0x800EF2C8,
//    "1-up in pole activator":   0x800EF300,
//    
//    "stationary star":  0x800EEFBC,
//    "spawned star":     0x800EEFE4,
//    
//    "skeeter":          0x800F05E8,
//}

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
    "star grab fall":              0x00001904,
    "airborne spawn":              0x00001924,
    
    "death exit landing":          0x00020467,
    "burning ground":              0x00020449,
    "handstand":                   0x01000345,
    "burning jump":                0x010208B4,
    "burning fall":                0x010208B5,
    
    "ground pound landing":        0x0080023C,
    "lava boost":                  0x010208B7,
    "slide kick":                  0x018008AA,
    "air kick":                    0x018008AC,
    "air sitting":                 0x0300088E,
}

function mario_action_is(name) => mario_current_action__mem == mario_action__values[name]
function mario_prev_action_is(name) => mario_previous_action__mem == mario_action__values[name]

function mario_action_changed_to(name) {
    return prev(mario_current_action__mem) != mario_action__values[name]
        && mario_current_action__mem == mario_action__values[name]
}

star_grab_actions = ["star dance ground (exit)", "star dance water", "star dance ground (no exit)", "star grab fall"]

burning_actions = ["burning ground", "burning jump", "burning fall"]

function airborne() => bit3(mario_current_action__addr + 1) != 0
function on_pole() => bit4(mario_current_action__addr + 2) != 0

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
    "behaviour script":     0x20c,  // dword (CHANGE to tbyte when using as pointer)
}
object__sizeof = 0x260

function object_field(base, field) => struct_field(object__struct, base, field)

function object_graph_invisible(addr) => bit4(object_field(addr, "graph node flags"))
function object_graph_animation_active(addr) => bit5(object_field(addr, "graph node flags"))

// https://github.com/n64decomp/sm64/blob/1372ae1bb7cbedc03df366393188f4f05dcfc422/include/object_constants.h#L7
function object_active(addr) => bit(0, object_field(addr, "active"))


function object_just_deactivated(addr) => prev(object_active(addr)) != 0 && object_active(addr) == 0

function object_behav_script(addr) => tbyte(object_field(addr, "behaviour script"))
function object_is(addr, name) => object_behav_script(addr) == behaviour_script__values[name]

function object_behavior_check(addr, check, delta=0) {
    offset = check["offset"]
    type = check["type"]
    value = check["value"]
    if (delta > 0)
        return prev(mem_access(object_behav_script(addr) + offset, type)) == value
    else
        return mem_access(object_behav_script(addr) + offset, type) == value
}

function object_is(addr, name) => object_behavior_check(addr, object_behavior_checks[name], delta=0)
function object_was(addr, name) => object_behavior_check(addr, object_behavior_checks[name], delta=1)
function object_changed_to(addr, name) => !object_was(addr, name) && object_is(addr, name)

function object_num_collided_objects(addr) => word(object_field(addr, "num collided objects"))
function object_nth_collided_object(addr, n) => tbyte(object_field(addr, format("collided object {0}", n)))

function object_boo_death_status(addr) => dword(object_field(addr, "boo death status"))

function object_anim(addr) => word(object_field(addr, "animation"))
function object_action(addr) => dword(object_field(addr, "action"))

function object_timer(addr) => dword(object_field(addr, "timer"))

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

// object specific
function object_star_mission(addr) => byte(object_field(addr, "star mission"))

function object_star_mission(addr) => byte(object_field(addr, "star mission"))

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

function collided_with_object(obj_name, count=1, check_action=-1, extra_logic=always_true()) {
    obj_tally = []
    for i in range(1,4) {
        obj_addr = object_nth_collided_object(mario_object(), i)
        
        coll_check = mario_collision_check(obj_addr, obj_name, i)
        if (check_action >= 0) {
            coll_check = coll_check && object_action(obj_addr) == check_action
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
    "Course 10": {"Crates": [57, 58, 59, 82, 83, 86, 93, 94, 95]}
}

//
//  Additional Memory
//

timer_counting__addr = mario_field("timer running")

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

function pressed_switch__mem(color, delta="f"){
    switch_mem = always_false
    if color == "red"
        switch_mem = bit1(current_file__addr + 8)
    else if color == "green"
        switch_mem = bit2(current_file__addr + 8)
    else if color == "blue"
        switch_mem = bit3(current_file__addr + 8)
     
    if delta == "true"
        return prev(switch_mem)
    else
        return switch_mem
}

function pressed_switch(color, delta){
    return pressed_switch__mem(color, delta) == 1
}


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

dialog_id__addr = offsets["DIALOGUE ID"]
dialog_id__mem = word(dialog_id__addr)

transition_type__addr = offsets["TRANSITION TYPE"]
transition_type__mem = word(transition_type__addr)

function transition_active() => transition_type__mem >= 0x100

TRANSITION_COLOR_FADE_IN = 0x101

g_red_coins_collected__addr = offsets["RED COINS COLLECTED"]
g_red_coins_collected__mem = byte(g_red_coins_collected__addr)

function course_meta(value, sublevel_values, full_name) => {"value": value, "sublevel values": sublevel_values, "full name": full_name}

course_infos = {
    "Overworld":        course_meta(0x10, [-1],   "The Overworld"), // Castle Grounds
    "Ending":           course_meta(0x22, [-1],   "Plutonic Atmosphere"),
    
    "Course 1":         course_meta(0x09, [-1],   "Bob-omb Backyard"),
    "Course 2":         course_meta(0x18, [-1],   "Infested Forgotten Forest"),
    "Course 3":         course_meta(0x0c, [-1],   "Frost Mountain"),
    "Course 4":         course_meta(0x05, [-1],   "Boneyard Backhouse"),
    "Course 5":         course_meta(0x04, [-1],   "Slippery Sand Dunes"),
    "Course 6":         course_meta(0x07, [-1],   "Sunlight Caverns"),
    "Course 7":         course_meta(0x16, [-1],   "Flat Volcanic Peaks"),
    "Course 8":         course_meta(0x08, [-1],   "Second Cloudy Construction Zone"),
    "Course 9":         course_meta(0x17, [-1],   "Dampened Woods"),
    "Course 10":        course_meta(0x0a, [-1],   "Stagnant Lake Triton"),
    "Course 11":        course_meta(0x0b, [-1],   "Maple Mushroom Mountain"),
    "Course 12":        course_meta(0x24, [-1],   "Rainbow Rush"),

    "Slide":            course_meta(0x1b, [-1],   "Whirlpool Lagoon"),
    "Aquarium":         course_meta(0x14, [-1],   "Underneath the Ice"),
    
    "Bowser 1":         course_meta(0x11, [-1],   "Diamond Galaxy Area 1"),
    "Key 1":            course_meta(0x1e, [-1],   "Diamond Galaxy Area 2"),
    "Bowser 2":         course_meta(0x13, [-1],   "Rusty Pits Area 1"),
    "Key 2":            course_meta(0x21, [-1],   "Rusty Pits Area 2"),
    "Bowser 3":         course_meta(0x15, [-1],   "Plutonic Atmosphere"),
    "Bowser 3 Part 1":  course_meta(0x15, [1, 2], "Plutonic Atmosphere"),
    "Bowser 3 Part 2":  course_meta(0x15, [3],    "Plutonic Atmosphere"),

    "Metal Cap":        course_meta(0x1c, [-1],   "Rocky Reservoir"),
    "Wing Cap":         course_meta(0x1d, [-1],   "Wing Towers"),
    "Vanish Cap":       course_meta(0x12, [-1],   "Translusent Funhouse"),

    "End Cake Picture": course_meta(0x19, [-1], "The End")
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

function in_same_level_from_last_frame() => level_id__mem == prev(level_id__mem) && sublevel_id__mem == prev(sublevel_id__mem)

function remained_in_level(name) => never(!in_level(name)) && once(prev(level_id__mem) != course_infos[name]["value"]) && hud_stars_shown() == 1 // beware for open-world type hacks...
function remained_in_sublevel(name) => never(!in_sublevel(name)) && once(prev(sublevel_id__mem) != course_infos[name]["sublevel values"]) && hud_stars_shown() == 1

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
    milestone_meta("First Valley of Pluto Exploration",
        "Collect your first star. More pipes in the overworld will appear as you progress.",
        stars=1, points=1, id=213176, badge="235458"),
    milestone_meta("Search for a Lost Key",
        "Collect 12 stars to gain access to the Diamond Galaxy.",
        stars=12, points=5, id=213177, badge="235459"),
    milestone_meta("Search for Another Lost Key",
        "Collect 30 stars to remove the barrier to the Rusty Pits. You'll also need a key to get in...",
        stars=30, points=5, id=213178, badge="235460"),
    milestone_meta("To the Top of the Valley",
        "Collect 60 stars to remove the barrier to Plutonic Atmosphere. You'll also need a key to get in...",
        stars=60, points=10, id=213179, badge="235461"),
    milestone_meta("Complete Planetary Exploration",
        "Collect all 101 stars in the Valley of Pluto.",
        stars=101, points=25, id=213180, badge="235462")
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

achievement(
    title = "Diamond Key",
    description = "Collect the lost key in the Diamond Galaxy.",
    points = 5,
    trigger = in_level("Key 1") && just_collected_star(),
    id = 213181,
    badge = "235463"
)

achievement(
    title = "Rusty Key",
    description = "Collect the lost key in the Rusty Pits.",
    points = 5,
    trigger = in_level("Key 2") && just_collected_star(),
    id = 213182,
    badge = "235464"
)

achievement(
    title = "Plutonic Clear",
    description = "Collect the star at the end of Plutonic Atmosphere.",
    points = 5,
    trigger = in_level("Bowser 3 Part 2") && just_collected_star(),
    id = 213183,
    badge = "235465"
)

// s w i t c h e s

function rgb_trigger() {
    return level_id__mem == prev(level_id__mem) // to prevent switching files after the ending picture puts you back to the title screen...
    
    && tally(2, 
    [once(pressed_switch("red", "true")),
    once(pressed_switch("green", "true")),
    once(pressed_switch("blue", "true"))
    ])
    
    && measured(tally(3, 
    [once(pressed_switch("red", "f")),
    once(pressed_switch("green", "f")),
    once(pressed_switch("blue", "f"))
    ]), when=!in_title_or_file_select())
    
    && never(tally(3, 
    [once(pressed_switch("red", "true")),
    once(pressed_switch("green", "true")),
    once(pressed_switch("blue", "true"))
    ]))
}

achievement(
    title = "Switcheroo on Pluto",
    description = "Press the red, green, and blue !-switches.",
    points = 5,
    trigger = rgb_trigger(),
    id = 213184,
    badge = "235466"
)

// c o u r s e s

function course_stars_meta(star_bits, points, title, description_add="", id=0, badge="0") => {"star bits": star_bits, "points": points, "title": title, "description add": description_add, "id": id, "badge": badge}

function sum_star_bits(file_offset, bits) {
    off = current_file__addr + file_offset
    return {
        "mem": sum_of(bits, b => bit(b, off)),
        "sum": length(bits)
    }
}

course_offsets = { // bytes offset from start of EEPROM, handle secret stars separately...
    "Course 1":  course_stars_meta(sum_star_bits(0x0f, range(0, 5)), 5, "A Beautiful Beach", id=213187, badge="235469"        ),
    "Course 2":  course_stars_meta(sum_star_bits(0x0e, range(0, 5)), 5, "Alternate Whomp's Fortress", id=213191, badge="235473"     ),
    "Course 3":  course_stars_meta(sum_star_bits(0x0d, range(0, 5)), 5, "Not Exactly Mt. Stardust", id=213192, badge="235474"           ),
    "Course 4":  course_stars_meta(sum_star_bits(0x0c, range(0, 5)), 5, "Mini Mansion", id=213193, badge="235475"       ),
    "Course 5":  course_stars_meta(sum_star_bits(0x13, range(0, 5)), 5, "Sloped Sand Valley", id=213194, badge="235476"         ),
    "Course 6":  course_stars_meta(sum_star_bits(0x12, range(0, 5)), 5, "Burning Light", id=213195, badge="235477"        ),
    "Course 7":  course_stars_meta(sum_star_bits(0x11, range(0, 5)), 5, "Land of Red Vegetation", id=213196, badge="235478"          ),
    "Course 8":  course_stars_meta(sum_star_bits(0x10, range(0, 5)), 5, "The Ricco Harbor of Pluto", id=213197, badge="235479"        ),
    "Course 9":  course_stars_meta(sum_star_bits(0x17, range(0, 5)), 5, "Deep Dank Forest", id=213198, badge="235480"          ),
    "Course 10": course_stars_meta(sum_star_bits(0x16, range(0, 5)), 5, "Frozen Over Like Triton", id=213188, badge="235470"         ),
    "Course 11": course_stars_meta(sum_star_bits(0x15, range(0, 5)), 5, "A Different Maple Mountain", id=213189, badge="235471"          ),
    "Course 12": course_stars_meta(sum_star_bits(0x14, range(0, 5)), 5, "The Rainbow Level at the End", id=213190, badge="235472"          ),
    
    "Metal Cap": course_stars_meta(sum_star_bits(0x1c, range(0, 5)), 5, "Dorrie Reservation in Pluto", id=213199, badge="235481"),
    "Slide":     course_stars_meta(sum_star_bits(0x1d, range(0, 4)), 5, "Lagoon Diving", id=213200, badge="235482"),
    "Bowser 3" : course_stars_meta(sum_star_bits(0x1e, range(0, 5)), 10, "Stars Between Worlds", description_add = " (must also get ending star)", id=213186, badge="235468"),
    
    "Aquarium" : course_stars_meta(sum_star_bits(0x20, range(0, 2)), 3, "More Wintery Platforming", id=213185, badge="235467"),
    "Vanish Cap":course_stars_meta(sum_star_bits(0x22, range(0, 2)), 3, "In the Other Pyramid", id=213201, badge="235483"),
    "Wing Cap" : course_stars_meta(sum_star_bits(0x23, range(0, 2)), 3, "Orange Liftoff", id=213202, badge="235484")
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
            && measured(bits == star_count, when=!in_title_or_file_select()),
        id = info["id"],
        badge = info["badge"]
    )
}

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
            
            // this 1-up is tangible while it is sparkling, so need additional action check
            if (obj_name == "chasing 1-up") {
            // https://github.com/n64decomp/sm64/blob/master/src/game/behaviors/mushroom_1up.inc.c
                // even if you are on top of the 1-up while handstanding, this will still hit
                coll_check1 = coll_check && object_action(obj_addr) == 1
                //coll_check2 = coll_check && object_action(obj_addr) == 3&& object_timer(obj_addr) >= 37
                array_push(mushie_tally, repeated(t["count"], coll_check1))
                //array_push(mushie_tally, repeated(t["count"], coll_check2))
            }
            else {
                array_push(mushie_tally,
                    repeated(t["count"], coll_check))   
            }
        }
    }
    return tally(total_count, mushie_tally)
}

function mushies_meta(title="", points=0, tallies=[], numbered_course=1, id=0, badge="0") => {"title": title, "points": points, "tallies": tallies, "is numbered course": numbered_course, "id": id, "badge": badge}

mushies_data = {
    "Course 1": mushies_meta("Lifesaver Backyard", 5, 
        [{"type": "stationary", "count": 6}, 
         {"type": "running away", "count": 2}], id=213207, badge="235489"),
    "Course 2": mushies_meta("Lifesaver Fortress", 2, 
        [{"type": "stationary", "count": 2},], id=213211, badge="235493"),
    "Course 3": mushies_meta("Lifesaver Mountain", 1, 
        [{"type": "chasing", "count": 1},], id=213212, badge="235494"),
    "Course 4": mushies_meta("Lifesaver Boneyard", 4, 
        [{"type": "stationary", "count": 3}, 
         {"type": "running away", "count": 1}], id=213213, badge="235495"),
    "Course 5": mushies_meta("Lifesaver Sand Dunes", 5, 
        [{"type": "stationary", "count": 4}, 
         {"type": "running away", "count": 1}], id=213214, badge="235496"),
    "Course 6": mushies_meta("Lifesaver Caverns", 2, 
        [{"type": "running away", "count": 2},], id=213215, badge="235497"),
    "Course 7": mushies_meta("Lifesaver Volcanoes", 2, 
        [{"type": "stationary", "count": 1}, 
         {"type": "running away", "count": 1}], id=213216, badge="235498"),
    "Course 8": mushies_meta("Lifesaver Construction", 5, 
        [{"type": "stationary", "count": 1}, 
         {"type": "running away", "count": 2},
         {"type": "impartial", "count": 2}], id=213217, badge="235499"),
    "Course 9": mushies_meta("Lifesaver Woods", 5, 
        [{"type": "stationary", "count": 4}, 
         {"type": "running away", "count": 3}], id=213218, badge="235500"),
    "Course 10": mushies_meta("Lifesaver Lake", 3, 
        [{"type": "stationary", "count": 1}, 
         {"type": "running away", "count": 1},
         {"type": "impartial", "count": 1}], id=213208, badge="235490"),
    "Course 11": mushies_meta("Lifesaver Maple Mountain", 3, 
        [{"type": "stationary", "count": 1},
         {"type": "impartial", "count": 1},
         {"type": "chasing", "count": 1}], id=213209, badge="235491"),
    "Course 12": mushies_meta("Lifesaver Rainbow", 3, 
        [{"type": "stationary", "count": 2}, 
         {"type": "running away", "count": 1}], id=213210, badge="235492"),
         
    "Wing Cap": mushies_meta("Winged Lifesaver", 1,
        [{"type": "stationary", "count": 1}], numbered_course = 0, id=213225, badge="235507"),
    "Vanish Cap": mushies_meta("Vanishing Lifesaver", 2,
        [{"type": "stationary", "count": 2}], numbered_course = 0, id=213224, badge="235506"),
    "Metal Cap": mushies_meta("Metalhead Lifesaver", 2, 
        [{"type": "stationary", "count": 1}, 
         {"type": "running away", "count": 1}], numbered_course = 0, id=213221, badge="235503"),
    
    "Slide": mushies_meta("Lifesaver Lagoon", 1, 
        [{"type": "stationary", "count": 1},], numbered_course = 0, id=213223, badge="235505"),
    "Aquarium": mushies_meta("Lifesaver Under the Ice", 1, 
        // [{"type": "stationary", "count": 1}, 
         [{"type": "running away", "count": 1}], numbered_course = 0, id=213203, badge="235485"),
        
    "Bowser 1": mushies_meta("Diamond Lifesaver Part 1", 2, 
        [{"type": "stationary", "count": 2},], numbered_course = 0, id=213204, badge="235486"),
    "Key 1": mushies_meta("Diamond Lifesaver Part 2", 2, 
        [{"type": "stationary", "count": 2},], numbered_course = 0, id=213219, badge="235501"),
    "Bowser 2": mushies_meta("Rusty Lifesaver Part 1", 2, 
        [{"type": "stationary", "count": 1}, // 1 stationary is unobtainable
         {"type": "chasing", "count": 1}], numbered_course = 0, id=213205, badge="235487"),
    "Key 2": mushies_meta("Rusty Lifesaver Part 2", 2, 
        [{"type": "stationary", "count": 1}, 
         {"type": "running away", "count": 1}], numbered_course = 0, id=213220, badge="235502"),
    
    "Bowser 3": mushies_meta("Lifesaver Pluto", 10, 
        [{"type": "stationary", "count": 4}, 
         {"type": "running away", "count": 3}], numbered_course = 0, id=213206, badge="235488"),
         
    "Overworld": mushies_meta("Lifesaver in the Valley", 5, 
        [{"type": "stationary", "count": 7},
         {"type": "running away", "count": 3},
         {"type": "impartial", "count": 1}], numbered_course = 0, id=213222, badge="235504")
}

mushie_triggers = ["Bowser 1", "Key 1", "Bowser 2", "Key 2"]

for course in mushies_data {
    info = mushies_data[course]
    
    mushie_count = sum_of(info["tallies"], t => t["count"])
    mushie_qty_string = ""
    
    mushie_tally = tally_all_1ups(tallies = mushies_data[course]["tallies"], total_count = mushie_count)
    
    collect_cond = always_true()
    
    if (mushie_count == 1) {
        mushie_qty_string = format("the 1-up mushroom")
        collect_cond = mushie_tally
    }
    else {
        mushie_qty_string = format("all {0} 1-up mushrooms", mushie_count)
        if (mushie_count == 2)
            mushie_qty_string = "both 1-up mushrooms"
        if (course == "Bowser 3")
            mushie_qty_string = format("{0} in *all* areas", mushie_qty_string)
        mushie_qty_string = format("{0} without leaving", mushie_qty_string)
        collect_cond = measured(mushie_tally)
    }
    
    // hard-coded jank
    if (course == "Aquarium")
        mushie_qty_string = "the obtainable 1-up mushroom"
    if (course == "Bowser 2")
        mushie_qty_string = "both obtainable 1-up mushrooms"
        
    description_append = ""
    
    if (any_of(mushie_triggers, c => course == c)) {
        description_append = ", indicator appears in correct area"
        collect_cond = measured(mushie_tally) || trigger_when(mushie_tally)
    }
    if (course == "Course 4")
        description_append = ", missions 2-6 only"
    if (course == "Course 5")
        description_append = ", missions 4-6 only"
    if (course == "Overworld")
        description_append = ", dying allowed"
    
    course_name = ""
    if (info["is numbered course"] != 0)
        course_name = course
    else
        course_name = course_infos[course]["full name"]
    
    description = format("{0} - collect {1} (see picture{2}).", course_name, mushie_qty_string, description_append)
    
    achievement(
        title = mushies_data[course]["title"],
        description = description,
        points = info["points"],
        trigger = never(!in_level(course))
            && collect_cond
    )
}

// Challenges

function tally_dead_skeeters(count) {
    dead_skeeters = array_map(range(0, 239), i =>
        repeated(count, object_is(nth_array_object(i), "skeeter")
        && object_just_deactivated(nth_array_object(i))
        && object_num_collided_objects(nth_array_object(i)) != 0)) // simple enough for a mario / bob-omb kill
        
    return tally(count, dead_skeeters)
}

achievement(
    title = "Bug Squasher",
    description = "Course 1 - Defeat all 8 skeeters without getting damaged.",
    points = 4,
    trigger = remained_in_level("Course 1")
        && never(hp_decrement() > 0) // don't need to worry about getting burned
        && (measured(tally_dead_skeeters(8))
        || trigger_when(tally_dead_skeeters(8))),
    id = 213226,
    badge = "235508"
)

achievement(
    title = "Detour with the Vanish Cap",
    description = "Course 2 - Collect the star 'Balance on the Board' while still wearing your vanish cap.",
    points = 5,
    trigger = in_level("Course 2") && prev(wearing_vanish_cap()) == 1 
        && trigger_when(collecting_star_object("stationary star", 0)),
    id = 213227,
    badge = "235509"
)

function tally_dead_chill_bullies(count) {
    dead_bullies = array_map(range(0, 239), i =>
        repeated(count, object_is(nth_array_object(i), "small chill bully")
            && object_active(nth_array_object(i)) != 0
            && just_changed_to(object_action(nth_array_object(i)), OBJ_ACTION_LAVA_DEATH)))
            
    return tally(count, dead_bullies)
}

// Ticket # 47675 - measured doesn't reset if you move from level to level (change lvl check to an inverted reset)
achievement(
    title = "They Melt in the Air",
    description = "Course 3 - Melt all 6 chill bullies by getting them low enough (bullies melting themselves count).",
    points = 5,
    trigger = never(!in_level("Course 3"))
        && measured(tally_dead_chill_bullies(6)),
    id = 213228,
    badge = "235510"
)

//achievement(
//    title = "Really Don't Need This",
//    description = "Course 4 - Collect the star 'Beneath the Carpet' without pressing the purple switch.",
//    points = 1,
//    trigger = remained_in_level("Course 4")
//        && never(object_is(stood_on_object(), "purple box switch")
//            && object_action(stood_on_object()) == 1)
//            // purple switch - action 1 = being pressed
//        && just_collected_star(star_index = 3, trigger = 1)
//)

achievement(
    title = "Where's My Coin Star?",
    description = "Collect 100 coins in Boneyard Backhouse.",
    points = 5,
    trigger = prev(nof_coins()) < 100
        && measured(nof_coins() >= 100, when=in_level("Course 4")),
    id = 213229,
    badge = "235511"
)

achievement(
    title = "Money Ride in the Desert",
    description = "Course 5 - Collect 70 coins while riding a koopa shell in one go (missions 4-6 only).",
    points = 10,
    trigger = never(!in_level("Course 5"))
        && never(!object_is(ridden_object(), "koopa shell"))
        && measured(repeated(70, coin_display() == prev(coin_display()) + 1)),
    id = 213230,
    badge = "235512"
          //|| trigger_when(repeated(70, coin_display() == prev(coin_display()) + 1)))
)

achievement(
    title = "Flame Dodger",
    description = "Course 6 - Collect the star 'Out of the Cavern' without taking damage.",
    points = 5,
    trigger = remained_in_level("Course 6")
        && never(hp_decrement() > 0)
        && never(any_of(burning_actions, a => mario_action_is(a)))
        && just_collected_star(star_index = 6, trigger = 1),
    id = 213231,
    badge = "235513"
)

got_one_red = nof_coins() == prev(nof_coins()) + 2

achievement(
    title = "Contrast Shell Ride for Reds",
    description = "Course 7 - Collect 7 out of the 8 red coins while riding a koopa shell in one go.",
    points = 10,
    trigger = never(!in_level("Course 7"))
        && never(!object_is(ridden_object(), "koopa shell"))
        && measured(repeated(7, got_one_red)),
    id = 213232,
    badge = "235514"
            //|| trigger_when(repeated(7, got_one_red)))
)

course_8_dialogs = [0x28, 0x2C, 0x2D, 0x2E, 0x30, 0x31, 0x32, 0x33]

achievement(
    title = "Social Butterfly in the Construction Zone",
    description = "Course 8 - Talk to all 8 Bob-omb Buddies (including the one in the sewers) without leaving.",
    points = 2,
    trigger = never(!in_level("Course 8"))
        && tally_of(course_8_dialogs, 1, d => dialog_id__mem == d)
        && (measured(tally_of(course_8_dialogs, length(course_8_dialogs), d => once(dialog_id__mem == d)))
        || trigger_when(tally_of(course_8_dialogs, length(course_8_dialogs), d => once(dialog_id__mem == d)))),
    id = 213233,
    badge = "235515"
        
)

function tally_dead_boos(count) {
    dead_boos = array_map(range(0, 239), i => 
        repeated(count, (object_is(nth_array_object(i), "boo") || object_is(nth_array_object(i), "boo activates text"))
            && object_active(nth_array_object(i)) == 1
            && prev(object_boo_death_status(nth_array_object(i))) == 0&& object_boo_death_status(nth_array_object(i)) == 1)
    )
    
    return tally(count, dead_boos)
}

achievement(
    title = "Ghost Hunt in the Woods",
    description = "Course 9 - Defeat all 8 boos without leaving (see comment).",
    points = 5,
    trigger = never(!in_level("Course 9"))
        && measured(tally_dead_boos(8)),
    id = 213234,
    badge = "235516"
)

c10_crates = object_indexes["Course 10"]["Crates"]

function tally_pounded_crates(indexes, custom_count=-1) {
    pounded_crates = array_map(indexes, i =>
        once(
            mario_action_is("ground pound landing")
            && !airborne()
            && surface_object(mario_floor_tri()) == nth_array_object(i)
            && object_is(surface_object(mario_floor_tri()), "crate")
        ))
    
    if (custom_count == -1)
        return tally(length(indexes), pounded_crates)
    return tally(custom_count, pounded_crates)
}

achievement(
    title = "Sound Testing the Crates",
    description = "Course 10 - Ground pound all 9 unbreakable crates without leaving.",
    points = 2,
    trigger = never(!in_level("Course 10"))
        && tally_pounded_crates(c10_crates, custom_count = 1)
        && (measured(tally_pounded_crates(c10_crates))
            || trigger_when(tally_pounded_crates(c10_crates))),
    id = 213235,
    badge = "235517"
)

// C11 green demon
achievement(
    title = "Green Demon of the Maple Mushrooms",
    description = "Course 11 - Activate the chasing 1-up and then collect all 8 red coins and the star before getting that 1-up.",
    points = 5,
    trigger = remained_in_level("Course 11")
        &&  collided_with_object("1-up in pole activator", count=2, extra_logic = g_red_coins_collected__mem == 0)
            // pole 1-up spawners create 2 activators
        &&  never(tally_all_1ups([{"type": "chasing", "count": 1}], total_count=1))
            // action 1 = done looping and visible, is collectible
        &&  trigger_when(collecting_star_object("spawned star", mission=1-1)),
    id = 213236,
    badge = "235518"
)

function int_seconds_to_frames(sec) => sec * 60

leaderboard(
    title="Rainbow Rush Race Time",
    description="Complete the timed race in Rainbow Rush as fast as possible.",
    start = in_level("Course 12")
        && hud_timer_started_counting()
        && hud_timer_shown() == 1,
    cancel = !in_level("Course 12") || hud_timer_shown() == 0,
    submit = hud_timer_stopped_counting()
        && hud_timer_shown() == 1
        && hud_timer() > 0,
    value = 2*hud_timer(),
    format = "FRAMES",
    lower_is_better=true
)

achievement(
    title="Rush up the Spiral",
    description="Course 12 - Complete the timed race in under 24 seconds.",
    points=5,
    trigger = in_level("Course 12")
        && hud_timer_shown() == 1
        && hud_timer() > 0
        && hud_timer() < int_seconds_to_frames(24) / 2
        && trigger_when(hud_timer_stopped_counting()),
    id = 213237,
    badge = "235519"
)

achievement(
    title="Big Jumps on a Shell",
    description = "Whirlpool Lagoon - Collect the red coin star while riding a koopa shell.",
    points = 5,
    trigger = in_level("Slide") 
        && object_was(ridden_object(), "koopa shell") 
        && trigger_when(collecting_star_object("spawned star", 2)),
    id = 213238,
    badge = "235520"
)

achievement(
    title = "Careful Ice Platforming",
    description = "Underneath the Ice - Collect the star on the right-hand side without stepping on more than one shrinking ice cube.",
    points = 10,
    trigger = remained_in_level("Aquarium")
        && never(tally(2,
            array_map(range(0, 239), i => 
                once(
                    object_is(stood_on_object(), "ice cube")
                    && array_object_index_is(stood_on_object(), i)))))
        && just_collected_star(star_index=2, trigger=1),
    id = 213239,
    badge = "235521"
)

achievement(
    title = "Really Don't Need This",
    description = "Rocky Reservoir - Collect the star behind the highest door without standing on the purple switch.",
    points = 2,
    trigger = remained_in_level("Metal Cap")
        && never(object_changed_to(stood_on_object(), "purple box switch"))
        && just_collected_star(star_index = 6, trigger = 1),
    id = 213240,
    badge = "235522"
)

achievement(
    title = "Flying Coin Heist",
    description = "Wing Towers - Collect 40 coins while wearing one wing cap (refreshing wing cap resets counter).",
    points = 5,
    trigger = never(!in_level("Wing Cap"))
        && never(wearing_wing_cap() == 0)
        && never(prev(wearing_wing_cap()) == 1 && cap_time() > prev(cap_time())) // grabbed another wing cap
        && ( measured(repeated(40, coin_display() == prev(coin_display()) + 1))
          || trigger_when(repeated(40, coin_display() == prev(coin_display()) + 1))),
    id = 213241,
    badge = "235523"
)

achievement(
    title = "Simple Jumps for Red Coins",
    description = "Translusent Funhouse - Collect the red coin star without pressing B or Z buttons.",
    points = 10,
    trigger = remained_in_level("Vanish Cap")
        && never(controller_b_button() != 0)
        && never(controller_z_button() != 0)
        && trigger_when(collecting_star_object("spawned star", mission=1-1)),
    id = 213242,
    badge = "235524"
)

achievement(
    title = "Another Skippable Switch",
    description = "Rusty Pits - Collect the key without standing on the purple switch (re-enter the 2nd area to try again).",
    points = 5,
    trigger = remained_in_level("Key 2")
        && never(object_changed_to(stood_on_object(), "purple box switch"))
        && just_collected_star(trigger = 1),
    id = 213243,
    badge = "235525"
)

achievement(
    title = "Impressive Show of Wealth",
    description = "Collect 180 coins in Plutonic Atmosphere (see comment).",
    points = 25,
    trigger = prev(nof_coins()) < 180
        && measured(nof_coins() >= 180, when=in_level("Bowser 3")),
    id = 213244,
    badge = "235526"
)

// RP

stars__value = rich_presence_value("Number", nof_stars())
lives__value = rich_presence_value("Number", (byte(nof_lives__addr) ) - (bit7(nof_lives__addr) * 256))

meta_descriptions = {
    0x00: "Starting up the game",
    0x21: "In File Select",
}

general_level_dict = {
    0x10: "exploring the overworld",
    
    0x09: "visiting Bob-omb's Backyard",
    0x18: "scaling the Infested Forgotten Forest",
    0x0C: "climbing Frost Mountain",
    0x05: "touring the Boneyard Backhouse",
    0x04: "sifting for treasures in Slippery Sand Dunes",
    0x07: "venturing through Sunlight Caverns",
    0x16: "beating the heat in Flat Volcanic Peaks",
    0x08: "investigating the Second Cloudy Construction Zone",
    0x17: "going into the Dampened Woods",
    0x0a: "skating around in Stagnant Lake Triton",
    0x0b: "jumping around in Maple Mushroom Mountain",
    0x24: "on an intergalactic adventure in Rainbow Rush",
    
    0x1b: "surfing away in Whirlpool Lagoon",
    0x14: "platforming Underneath the Ice",
    
    0x11: "looking for a lost key in the Diamond Galaxy",
    0x1e: "in a valley in the Diamond Galaxy",
    0x13: "climbing out of the Rusty Pits",
    0x21: "traversing constructions in the Rusty Pits",
    0x15: "traveling between worlds in Plutonic Atmosphere",
    0x22: "finishing his journey in the Valley of Pluto",
    
    0x1c: "visiting the Dorries in Rocky Reservoir",
    0x1d: "flying through the Wing Towers",
    0x12: "jumping around in Translusent Funhouse",
    
    0x19: "at the ending screen",
}

level__lookup = rich_presence_lookup("LevelsWithoutSublevels", level_id__mem, general_level_dict, "in an unbeknownst location")

rich_presence_conditional_display(in_title_or_file_select(), 
    "{0}", rich_presence_lookup("Fileless", music_id__mem, meta_descriptions))
rich_presence_conditional_display(
    mem_in(level_id__mem, general_level_dict),
    "Mario is {0} with {1}⭐ and {5}🚶 [🔴{2}] [🟢{3}] [🔵{4}]", level__lookup, stars__value,
        rich_presence_lookup("Switch", pressed_switch__mem("red"), {1:"▣"}, "▢"),
        rich_presence_lookup("Switch", pressed_switch__mem("green"), {1:"▣"}, "▢"),
        rich_presence_lookup("Switch", pressed_switch__mem("blue"), {1:"▣"}, "▢"),
        lives__value
)
rich_presence_display("Mario is on an adventure in the Valley of Pluto.")