// ~Hack~ Another Mario Adventure
// #ID = 16760
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

offsets = {
    "MISSION SELECTED": 0x1a81a7,
    
    "SAVE DATA":    (0x207700 - 0x70),
    
    "MUSIC ID":     0x22261e,

    "COLLECTED STAR ID":    0x32dd87, // 1-indexed
    "FILE ID":              0x32ddf6,
    "MAP ID":               0x32ddfa,
    
    "STOOD ON OBJECT":      0x330e34,
    "DIALOGUE ID":          0x331486,
    
    "LEVEL INDEX":      0x33bac8,
    "SUBMAP ID":        0x33b249,
    
    "TIME COUNTING":    0x33b25e,
    "HUD FLAGS":        0x33b268,   //  https://github.com/n64decomp/sm64/blob/1372ae1bb7cbedc03df366393188f4f05dcfc422/src/game/level_update.h#L91
    "HUD TIMER":        0x33b26e,
    
    "TRANSITION TYPE":  0x33bab2,
    
    "MARIO STRUCT":     0x33b170,
    "OBJECT ARRAY":     0x33d488,
    
    "RED COINS COLLECTED":  0x3613fd,
}

// double-check this list between hacks, custom objects can shift things...
behaviour_script__values = { 
    "teleporter":       0x800EB8DC,
    "coin formation":   0x800EBA6C,
    
    "purple box switch":0x800EC62C,
    "grand star":       0x800EC894,
    "bowser 3":         0x800EC9D0,
    "blue coin switch": 0x800ED6E8,
    
    "regular star":     0x800EEFBC,
    "spawned star":     0x800EEFE4,

    "stationary 1-up":  0x800EF1FC,
    "chasing 1-up":     0x800EF2C8,
    
    "c7 timer":         0x80408138,
    "c9 puzzle":        0x80408108,
    
    "b3 fight controller": 0x8040815C,
    "credits controller":  0x80408180,
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
    "in cannon":                   0x00001371,
    "star grab fall":              0x00001904,
    "airborne spawn":              0x00001924,
    
    "death exit landing":          0x00020467,
    "burning ground":              0x00020449,
    "burning jump":                0x010208B4,
    "burning fall":                0x010208B5,
    
    "ground pound landing":        0x0080023C,
    "lava boost":                  0x010208B7,
    "slide kick":                  0x018008AA,
    "air kick":                    0x018008AC,
    "air sitting":                 0x0300088E,
    
    "dive slide":                  0x00880456,
    "butt slide":                  0x00840452,
    "hold butt slide":             0x00840454,
}

function mario_action_is(name) => mario_current_action__mem == mario_action__values[name]
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
    
    "behavior param 2":     0x144,  // dword?
    "coin formation type":  0x144,  // dword
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
    
    // Hack specific
    "c7 timer":              0xF4,  // dword
    "credits mashed":        0xF8,  // dword
    "1-up text id":         0x188,  // dword_be
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

// object specific
function object_star_mission(addr) => byte(object_field(addr, "star mission"))
function object_teleporter_id(addr) => word(object_field(addr, "teleporter id"))

function object_coin_formation_type(addr) => dword(object_field(addr, "coin formation type"))
function object_coin_formation_collects(addr) => bitcount(object_field(addr, "collected coins"))

function object_1up_text_id(addr) => dword_be(object_field(addr, "1-up text id"))
function object_c7_timer(addr) => dword(object_field(addr, "c7 timer"))
function object_credits_mashed_count(addr) => dword(object_field(addr, "credits mashed"))

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
                (obj_addr != prev(obj_addr)) 
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

function using_teleporter(id) {
    obj = interaction_object()
    return obj != 0
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

function hud_timer() => word(hud_timer__addr)

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

mission__addr = offsets["MISSION SELECTED"]
mission__mem = byte(mission__addr)

// normal stars = 1-6; 100 coin star = 7
last_star__addr = offsets["COLLECTED STAR ID"]
last_star__mem = byte(last_star__addr)

sublevel_id__addr = offsets["SUBMAP ID"]
sublevel_id__mem  = byte(sublevel_id__addr)

level_id__addr = offsets["MAP ID"]
level_id__mem = byte(level_id__addr)

function screen_changed() => just_changed_any(level_id__mem) || just_changed_any(sublevel_id__mem)

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

// https://github.com/n64decomp/sm64/blob/master/levels/level_defines.h level id's
course_infos = {
    "Overworld 1":      course_meta(0x10, [-1],   "the first overworld"), // Castle Grounds, not gonna distinguish day/night
    "Overworld 2 Fire": course_meta(0x06, [1], "the second overworld (fire side)"), // Inside Castle
    "Overworld 2 Ice":  course_meta(0x06, [2], "the second overworld (ice side)"), // Inside Castle
    "Overworld 3":      course_meta(0x1a, [-1], "the third overworld"), // Castle Courtyard
    "Halls of Fame":    course_meta(0x12, [-1], "the Halls of Fame"),
    
    "Course 1":         course_meta(0x09, [-1],   "Treetrunk Valley"),
    "Course 2":         course_meta(0x18, [-1],   "Brinstar Jungle"),
    "Course 3":         course_meta(0x0c, [-1],   "City in the Sky"),
    "Course 4":         course_meta(0x05, [-1],   "Bustin' Dusk Beach"),
    "Course 5":         course_meta(0x04, [-1],   "Colorful Pyramid Desert"),
    "Course 6":         course_meta(0x07, [-1],   "Burning Arctic Caverns"),
    "Course 7":         course_meta(0x16, [-1],   "Cryptic Phosphor Tower"),
    "Course 8":         course_meta(0x08, [-1],   "Dragon Road Chun-Nan"),
    "Course 9":         course_meta(0x17, [-1],   "Hang Mystic Mansion"),
    
    "Guest Course 1":        course_meta(0x0b, [-1],   "The Classic Stage"),
    "Guest Course 2":        course_meta(0x24, [-1],   "Mountain Above the Clouds"),
    "Guest Course 3":        course_meta(0x0d, [-1],   "Vintage Castle"),
    "Guest Course 4":        course_meta(0x0e, [-1],   "Temple of Prometheus"),
    "Guest Course 5":        course_meta(0x0f, [-1],   "Autumn Mountain"),
    
    // HF
    "Cheezepin":        course_meta(0x13, [-1], "Ascended Paradise"), // B2
    "Lincrash":         course_meta(0x14, [1], "Airship Force"), // Aquarium
    "Kaze":             course_meta(0x14, [2], "Jungle Falls"), // Aquarium
    "Dimps":            course_meta(0x14, [3], "Planet Wisp Constructions"),
    "ToasterKetchup":   course_meta(0x1b, [-1],   "Freezeflame Trials"), // slide
    "MrComit":          course_meta(0x1f, [1],   "Cosmic Cart Joy Ride"), // Cloud stage
    "SEGA":             course_meta(0x1f, [2],   "Cosmic Wall"), // Cloud stage
    
    
    "Bowser 1":         course_meta(0x11, [-1],   "Bowser in the Ice Mines"),
    "Key 1":            course_meta(0x1e, [-1],   "Bowser in the Ice Mines"),
    "Bowser 3":         course_meta(0x15, [-1],   "Bowser in the Crimson Carnival"),
    "Final Fight":      course_meta(0x22, [-1],   "Bowser in the Crimson Carnival"),
    
    "End Credits":      course_meta(0x0a, [1],   "the credits"), // C10
    "Frank's Dream":    course_meta(0x0a, [2],   "Frank's Dream"), // cheater area
    
    "Metal Cap":        course_meta(0x1c, [-1],   "Pyramid Cavern"),
    "Wing Cap":         course_meta(0x1d, [-1],   "Pink Flying House"),
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

function in_area(name, area=-1) {
    area_check = always_true()
    if (area != -1)
        area_check = sublevel_id__mem == area
    
    return level_id__mem == course_infos[name]["value"] && area_check
}

function in_same_level_from_last_frame() => level_id__mem == prev(level_id__mem) && sublevel_id__mem == prev(sublevel_id__mem)

function entered_level_from_star_select(name) => in_level(name) && just_changed_from(music_id__mem, 0x0D) // careful, specific to this hack (AMA)

function level_changed() => just_changed_any(level_id__mem)

// for challenges that, if failed, require re-entering the level
function remained_in_level(name) => once(entered_level_from_star_select(name)) && never(level_changed())

//
//  Cheevs
//

// Milestones

function star_milestone_trigger(num_stars) {
    return level_id__mem == prev(level_id__mem) // to prevent switching files to pop the achievement
        && prev(nof_stars()) == num_stars - 1 
        && measured(nof_stars() == num_stars, when=!in_title_or_file_select())
}

function milestone_meta(title, description, stars, points, id=0, badge="0") => {"title": title, "description": description, "stars": stars, "points": points, "id": id, "badge": badge}

milestones = [
    //milestone_meta("Finished the Summer Collab",
    //    "Collect all 28 stars.",
    //    stars=28, points=10)
    milestone_meta("Another Journey Has Started",
        "Collect your first star.",
        stars=1, points=1, id=237218, badge="263301"),
    milestone_meta("Opened a Star Door Somewhere",
        "Collect 8 stars.",
        stars=8, points=5, id=237219, badge="263302"),
    milestone_meta("To the Final Overworld",
        "Collect 50 stars.",
        stars=50, points=10, id=237220, badge="263303"),
    milestone_meta("End of This Community Collab",
        "Collect all 120 stars.",
        stars=120, points=25, id=237221, badge="263304"),
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

// switches
function rg_trigger() {
    return level_id__mem == prev(level_id__mem) // to prevent switching files after the ending picture puts you back to the title screen...
    && file_num__mem == prev(file_num__mem)
    
    && tally(1, 
    [once(pressed_switch("red", delta=1)),
    once(pressed_switch("green", delta=1)),
    //once(pressed_switch("blue", "true"))
    ])
    
    && measured(tally(2, 
    [once(pressed_switch("red")),
    once(pressed_switch("green")),
    //once(pressed_switch("blue", "f"))
    ]), when=!in_title_or_file_select())
    
    && never(tally(2, 
    [once(pressed_switch("red", delta=1)),
    once(pressed_switch("green", delta=1)),
    //once(pressed_switch("blue", delta=1))
    ]))
}

// caps / bowsers

achievement(
    title = "Vanish Cap Sucks Anyway",
    description = "Press the red and green !-switches.",
    points = 5,
    trigger = rg_trigger(),
    id = 237222,
    badge = "263305"
)

achievement(
    title = "Icy Retreat",
    description = "Defeat Bowser in the Ice Mines and collect his key.",
    points = 5,
    trigger = in_level("Key 1") && just_collected_star(),
    id = 237223,
    badge = "263306"
)

achievement(
    title = "Another Bowser Bites the Dust",
    description = "Defeat Bowser in the Crimson Carnival and collect the grand star.",
    points = 10,
    trigger = in_level("Final Fight") && interaction_object() != 0 && object_is(interaction_object(), "grand star"),
    id = 237224,
    badge = "263307"
)

//-------------
// course stars
//-------------

function course_stars_meta(star_bits, points, title, description_add="", id=0, badge="0") => {"star bits": star_bits, "points": points, "title": title, "description add": description_add, "id": id, "badge": badge}

function sum_star_bits(file_offset, bits) {
    off = current_file__addr + file_offset
    return {
        "mem": sum_of(bits, b => bit(b, off)),
        "sum": length(bits)
    }
}

// https://github.com/n64decomp/sm64/blob/master/levels/course_defines.h indexes (add 0x0c) (remember endian weirdness)
course_offsets = {
    "Course 1":  course_stars_meta(sum_star_bits(0x0f, range(0, 6)), 10, "Tree of Life", id=237225, badge="263308"),
    "Course 2":  course_stars_meta(sum_star_bits(0x0e, range(0, 6)), 10, "Go the Jungle Adventure", id=237226, badge="263309"),
    "Course 3":  course_stars_meta(sum_star_bits(0x0d, range(0, 6)), 10, "Skyline Before Twilight", id=237227, badge="10"),
    "Course 4":  course_stars_meta(sum_star_bits(0x0c, range(0, 6)), 10, "Beach Party", id=237228, badge="263311"),
    "Course 5":  course_stars_meta(sum_star_bits(0x13, range(0, 6)), 10, "Oasis in the Desert", id=237229, badge="263312"),
    "Course 6":  course_stars_meta(sum_star_bits(0x12, range(0, 6)), 10, "First Freezeflame Trials", id=237230, badge="263313"),
    "Course 7":  course_stars_meta(sum_star_bits(0x11, range(0, 6)), 10, "Luminescent Valley", id=237231, badge="263314"),
    "Course 8":  course_stars_meta(sum_star_bits(0x10, range(0, 6)), 10, "Mario's Trip in China, but Easier", id=237232, badge="263315"),
    "Course 9":  course_stars_meta(sum_star_bits(0x17, range(0, 6)), 10, "Magic House", id=237233, badge="263316"),
    
    "Guest Course 1":  course_stars_meta(sum_star_bits(0x15, range(0, 6)), 10, "Tomatobird's Classic Pack", id=237234, badge="263317"),
    "Guest Course 2":  course_stars_meta(sum_star_bits(0x14, range(0, 6)), 10, "Brodute's Mountain Range", id=237235, badge="263318"),
    "Guest Course 3":  course_stars_meta(sum_star_bits(0x1b, range(0, 6)), 10, "usernamesarespiders' Detailed Castle", id=237236, badge="263319"),
    "Guest Course 4":  course_stars_meta(sum_star_bits(0x1a, range(0, 6)), 10, "scuttlebugraiser's Fire Trials", id=237237, badge="263320"),
    "Guest Course 5":  course_stars_meta(sum_star_bits(0x19, range(0, 6)), 10, "Pie's Seasonal Papercraft", id=237238, badge="263321"),
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

// expects a star_bits-like object with a mem attribute
function add_star_bits(star_bits) {
    return sum_of(star_bits, s => s["mem"])
}

overworld_stars = [
    sum_star_bits(0x0b, range(0, 3))
]

side_courses_stars = [
    sum_star_bits(0x18, [0]), // B1
    sum_star_bits(0x1c, [0]), // MC
    sum_star_bits(0x1e, [0]), // B3
    sum_star_bits(0x23, [0]), // WC
]

halls_of_fame_stars = [
    sum_star_bits(0x1d, [0, 1]), // toasterketchup (Slide)
    sum_star_bits(0x1f, [0, 1]), // cheezepin (B2)
    sum_star_bits(0x20, range(0, 5)), // crash, kaze, dimps (aquarium)
    sum_star_bits(0x21, range(0, 3)) // mrcomit and SEGA (cloud stage) 
]

achievement(
    title = "Aglab's Scenic Overworlds",
    description = "Collect all 4 stars across all 3 overworlds.",
    points = 4,
    trigger = level_id__mem == prev(level_id__mem)
        && file_num__mem == prev(file_num__mem)
        && prev(add_star_bits(overworld_stars)) == 3
        && measured(add_star_bits(overworld_stars) == 4, when = !in_title_or_file_select()),
    id=237239,
    badge="263322"
)

achievement(
    title = "Small but Significant Sides",
    description = "Collect all 4 stars across Wing Cap, Metal Cap, and both Bowser courses",
    points = 4,
    trigger = level_id__mem == prev(level_id__mem)
        && file_num__mem == prev(file_num__mem)
        && prev(add_star_bits(side_courses_stars)) == 3
        && measured(add_star_bits(side_courses_stars) == 4, when = !in_title_or_file_select()),
    id=237240,
    badge="263323"
)

achievement(
    title = "Halls of Fame Silver",
    description = "Collect 7 stars across the Halls of Fame.",
    points = 5,
    trigger = level_id__mem == prev(level_id__mem) // not gonna bother checking each level
        && file_num__mem == prev(file_num__mem)
        && prev(add_star_bits(halls_of_fame_stars)) == 6
        && measured(add_star_bits(halls_of_fame_stars) == 7, when = !in_title_or_file_select()),
    id=237241,
    badge="263324"
)

achievement(
    title = "Halls of Fame Gold",
    description = "Collect all 14 stars across the Halls of Fame.",
    points = 10,
    trigger = level_id__mem == prev(level_id__mem) // not gonna bother checking each level
        && file_num__mem == prev(file_num__mem)
        && prev(add_star_bits(halls_of_fame_stars)) == 13
        && measured(add_star_bits(halls_of_fame_stars) == 14, when = !in_title_or_file_select()),
    id=237242,
    badge="263325"
)

// 1-ups
// Re-wire logic for single 1-ups
function collected_1up(type="stationary", text=0) {
    mushie_tally = []
    
    obj_name = format("{0} 1-up", type)
    
    for i in range(1, 4) {
        obj_addr = object_nth_collided_object(mario_object(), i)
        
        coll_check = mario_collision_check(obj_addr, obj_name, i)
        coll_check = coll_check && object_1up_text_id(obj_addr) == text
        
        if (obj_name == "chasing 1-up") {
                coll_check1 = coll_check && object_action(obj_addr) == 1
                coll_check2 = coll_check && object_action(obj_addr) == 3
                    && object_timer(obj_addr) >= 37
                array_push(mushie_tally,
                    repeated(1, coll_check1))
                array_push(mushie_tally,
                    repeated(1, coll_check2))
            }
            else {
                array_push(mushie_tally,
                    repeated(1, coll_check))   
            }
    }
    
    return tally(1, mushie_tally)
}

function mushie_meta(title="", description="", points=1, type="stationary", text=0, level_check=always_true(), id=0, badge="0") => {"title": title, "description": description, "points": points, "collect check": collected_1up(type, text), "level check": level_check, "id": id, "badge": badge}

mushie_infos = [
    mushie_meta("Familiar Structure", "Course 1 - Collect a 1-up mushroom on top of some scaffolding.", 1, "stationary", 2, in_area("Course 1", 1), id=237243, badge="263326"),
    mushie_meta("Sure is a Secret, Alright", "Course 1 - Collect a 1-up mushroom near a big tree.", 1, "stationary", 1, in_area("Course 1", 1), id=237244, badge="263327"),
    mushie_meta("Not a Satisfying Sound", "Course 3 - Collect a 1-up mushroom outside, beside the broken tower.", 1, "stationary", 3, in_area("Course 3"), id=237245, badge="263328"),
    mushie_meta("Like a Record, Baby", "Course 3 - Collect a 1-up mushroom at the very top of the rotating mill.", 1, "stationary", 24, in_area("Course 3"), id=237246, badge="263329"),
    mushie_meta("Good Collision, for Sure", "Course 5 - Collect a 1-up mushroom at the top of a waterfall.", 1, "stationary", 5, in_area("Course 5", 1), id=237247, badge="263330"),
    mushie_meta("Maybe, Maybe", "Course 7 - Collect a 1-up mushroom inside the dark wood room.", 1, "stationary", 6, in_area("Course 7", 3), id=237248, badge="263331"),
    mushie_meta("A Wet Life", "Course 8 - Collect a 1-up mushroom inside a waterfall.", 1, "stationary", 7, in_area("Course 8", 1), id=237249, badge="263332"),
    mushie_meta("Ridiculous Collectible", "Course 9 - Collect a 1-up mushroom high up, between some inverted platforms.", 1, "stationary", 8, in_area("Course 9", 1), id=237250, badge="263333"),
    
    
    mushie_meta("It's Okay, I Guess", "Guest Course 1 - Collect a 1-up mushroom inside a small pentagon pillar.", 1, "chasing", 0x200, in_area("Guest Course 1", 2), id=237251, badge="263334"),
    mushie_meta("Reference to Someone", "Guest Course 2 - Collect a 1-up mushroom above a waterfall.", 1, "stationary", 10, in_area("Guest Course 2", 1), id=237252, badge="263335"),
    mushie_meta("The Real Secret", "Guest Course 3 - Collect a 1-up mushroom between some bookshelves.", 1, "stationary", 11, in_area("Guest Course 3", 1), id=237253, badge="263336"),
    mushie_meta("It's Clean, Right?", "Guest Course 3 - Collect a 1-up mushroom inside one of the castle rooms.", 1, "stationary", 12, in_area("Guest Course 3", 1), id=237254, badge="263337"),
    mushie_meta("Pole Climbing, That's How", "Guest Course 3 - Collect a 1-up mushroom high up in the ice cavern.", 1, "stationary", 4, in_area("Guest Course 3", 2), id=237255, badge="263338"),
    mushie_meta("No BLJ's Required, Really", "Guest Course 4 - Collect a 1-up mushroom somewhere inside Zeus's domain.", 1, "stationary", 13, in_area("Guest Course 4", 4), id=237256, badge="263339"),
    mushie_meta("The Broken Floor", "Guest Course 5 - Collect a 1-up mushroom under a small staircase.", 1, "stationary", 23, in_area("Guest Course 5", 1), id=237257, badge="263340"),
    
    mushie_meta("Got Health?", "Metal Cap Stage - Collect a 1-up mushroom on top of a lavafall.", 1, "stationary", 18, in_area("Metal Cap"), id=237258, badge="263341"),
    
    mushie_meta("Safety Warp for the Crossovers", "Bowser in the Ice Mines - Collect a 1-up mushroom at the bottom of a slide.", 1, "stationary", 26, in_area("Bowser 1"), id=237259, badge="263342"),
    mushie_meta("Some Nerfed Slopes", "Bowser in the Crimson Carnival - Collect a 1-up mushroom around a tall building.", 1, "stationary", 17, in_area("Bowser 3"), id=237260, badge="263343"),
    mushie_meta("Not the Only Sonic Reference", "Bowser in the Crimson Carnival - Collect a 1-up mushroom on top of the buildings in the center.", 1, "stationary", 25, in_area("Bowser 3"), id=237261, badge="263344"),
    
    mushie_meta("The Hack Creator Likes Sonic, Alright", "The Halls of Fame - Collect a 1-up mushroom above the arches of the hall.", 1, "stationary", 19, in_area("Halls of Fame"), id=237262, badge="263345"),
    mushie_meta("This Doorway Doesn't Work", "SEGA's level - Collect a 1-up mushroom near the starting point.", 1, "stationary", 22, in_area("SEGA"), id=237263, badge="263346"),
    mushie_meta("Creator's Design Choice, That's Why", "Cheezepin's level - Collect a 1-up mushroom on top of a tree.", 1, "stationary", 16, in_area("Cheezepin"), id=237264, badge="263347"),
    mushie_meta("The Way Physics Work", "Kaze's level - Collect a 1-up mushroom under the starting point.", 1, "stationary", 21, in_area("Kaze"), id=237265, badge="263348"),
    
    mushie_meta("Strain-Free Tunnel", "Overworld 1 - Collect a 1-up mushroom in an underwater alcove.", 1, "stationary", 14, in_area("Overworld 1"), id=237266, badge="263349"),
    mushie_meta("It's Pretty Cool, Right?", "Overworld 2 Ice - Collect a 1-up mushroom off in the distance, behind the temple of Prometheus.", 1, "stationary", 15, in_area("Overworld 2 Ice"), id=237267, badge="263350"),
]

for dat in mushie_infos {

    achievement(
        title = dat["title"],
        description = dat["description"],
        points = dat["points"],
        trigger = never(screen_changed()) && dat["level check"] && dat["collect check"]
    )
}

// Challenges

achievement(
    title = "Another Adventure, Another Pointless Switch",
    description = "Course 1 - Collect the star 'Wooded Secrets Platforming' without pressing the purple switch.",
    points = 2,
    trigger = remained_in_level("Course 1")
        && sublevel_id__mem == 1
        && never(object_is(stood_on_object(), "purple box switch")
            && object_action(stood_on_object()) == 1)
        && trigger_when(collecting_star_object("spawned star", 1)),
    id=237268,
    badge="263351"
)

function blue_coin_switch_done(obj) {
    return unless(!object_is(obj, "blue coin switch"))
        && once(just_changed(object_action(obj), 1, 2))
        && never(just_changed_to(object_action(obj), 0))
        && trigger_when(object_action(obj) == 100)
}

achievement(
    title = "Rollout Grinding",
    description = "Course 2 - Collect all the blue coins without using the A button.",
    points = 10,
    trigger = in_area("Course 2", 1)
        && never(screen_changed())
        && never(controller_a_button() != 0)
        && any_of(array_map(range(0, 239), a => blue_coin_switch_done(nth_array_object(a))), b => b),
    id=237269,
    badge="263352"
)

achievement(
    title = "No Wings in This Sky",
    description = "Course 3 - Collect the star 'Top of the Spinning Tower' without getting a wing cap.",
    points = 5,
    trigger = remained_in_level("Course 3")
        && sublevel_id__mem == 1
        && never(just_increased(wearing_wing_cap()))
        && collecting_star_object("regular star", 5),
    id=237270,
    badge="263353"
)

achievement(
    title = "Good Old Tower Climbing",
    description = "Enter the other Course 4 entrance in the overworld without getting a wing cap (enter any level or switch day/night to reset).",
    points = 5,
    trigger = in_level("Overworld 1")
        && disable_when(just_increased(wearing_wing_cap()), until=screen_changed())
        && using_teleporter(0x22),
    id=237271,
    badge="263354"
)

achievement(
    title = "Another Cannonless Mission",
    description = "Course 5 - Collect the star 'Get on Yellow Desert Temple Top' without using the cannon.",
    points = 5,
    trigger = remained_in_level("Course 5")
        && sublevel_id__mem == 1
        && never(mario_action_changed_to("in cannon"))
        && trigger_when(collecting_star_object("regular star", 2)),
    id=237272,
    badge="263355"
)

achievement(
    title = "Keep Your Cool",
    description = "Course 6 - Collect the star 'Penguin Trapped in Burnt Room' without going below 6 HP.",
    points = 5,
    trigger = remained_in_level("Course 6")
        && never(hp() < 0x600 && hp() >= 0x200)
        && trigger_when(collecting_star_object("spawned star", 0)),
    id=237273,
    badge="263356"
)

// C7 timer

function c7_timer_cond(obj, check_threshold=1) {
    cond = unless(!object_is(obj, "c7 timer"))
        && never(just_changed_to(object_action(obj), 0)) 
        && once(just_changed(object_action(obj), 0, 1))
        && just_changed(object_action(obj), 1, 2)
    if (check_threshold > 0)
        return cond && object_c7_timer(obj) >= int_seconds_to_frames(5)
    else
        return cond
}

achievement(
    title = "Phosphor River Race",
    description = "Course 7 - Collect the star 'Deep Dive in Phosphor River' with at least 5 seconds remaining on the timer.",
    points = 5,
    trigger = in_area("Course 7", 1) && never(screen_changed()) && any_of(array_map(range(0, 239), a => c7_timer_cond(nth_array_object(a))), b => b),
    id=237274,
    badge="263357"
)

leaderboard(
    title = "Slide Down Phosphor River",
    description = "Collect the star 'Deep Dive in Phosphor River' in Course 7 with as much remaining time as possible.",
    start = in_area("Course 7", 1) && never(screen_changed()) && any_of(array_map(range(0, 239), a => c7_timer_cond(nth_array_object(a), check_threshold=0)), b => b),
    cancel = always_false(),
    submit = always_true(),
    value = max_of( // when's making a splat operator :(
        measured(2*object_c7_timer(nth_array_object(0  )), when=object_is(nth_array_object(0  ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(1  )), when=object_is(nth_array_object(1  ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(2  )), when=object_is(nth_array_object(2  ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(3  )), when=object_is(nth_array_object(3  ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(4  )), when=object_is(nth_array_object(4  ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(5  )), when=object_is(nth_array_object(5  ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(6  )), when=object_is(nth_array_object(6  ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(7  )), when=object_is(nth_array_object(7  ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(8  )), when=object_is(nth_array_object(8  ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(9  )), when=object_is(nth_array_object(9  ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(10 )), when=object_is(nth_array_object(10 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(11 )), when=object_is(nth_array_object(11 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(12 )), when=object_is(nth_array_object(12 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(13 )), when=object_is(nth_array_object(13 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(14 )), when=object_is(nth_array_object(14 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(15 )), when=object_is(nth_array_object(15 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(16 )), when=object_is(nth_array_object(16 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(17 )), when=object_is(nth_array_object(17 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(18 )), when=object_is(nth_array_object(18 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(19 )), when=object_is(nth_array_object(19 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(20 )), when=object_is(nth_array_object(20 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(21 )), when=object_is(nth_array_object(21 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(22 )), when=object_is(nth_array_object(22 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(23 )), when=object_is(nth_array_object(23 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(24 )), when=object_is(nth_array_object(24 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(25 )), when=object_is(nth_array_object(25 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(26 )), when=object_is(nth_array_object(26 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(27 )), when=object_is(nth_array_object(27 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(28 )), when=object_is(nth_array_object(28 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(29 )), when=object_is(nth_array_object(29 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(30 )), when=object_is(nth_array_object(30 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(31 )), when=object_is(nth_array_object(31 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(32 )), when=object_is(nth_array_object(32 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(33 )), when=object_is(nth_array_object(33 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(34 )), when=object_is(nth_array_object(34 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(35 )), when=object_is(nth_array_object(35 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(36 )), when=object_is(nth_array_object(36 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(37 )), when=object_is(nth_array_object(37 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(38 )), when=object_is(nth_array_object(38 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(39 )), when=object_is(nth_array_object(39 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(40 )), when=object_is(nth_array_object(40 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(41 )), when=object_is(nth_array_object(41 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(42 )), when=object_is(nth_array_object(42 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(43 )), when=object_is(nth_array_object(43 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(44 )), when=object_is(nth_array_object(44 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(45 )), when=object_is(nth_array_object(45 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(46 )), when=object_is(nth_array_object(46 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(47 )), when=object_is(nth_array_object(47 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(48 )), when=object_is(nth_array_object(48 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(49 )), when=object_is(nth_array_object(49 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(50 )), when=object_is(nth_array_object(50 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(51 )), when=object_is(nth_array_object(51 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(52 )), when=object_is(nth_array_object(52 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(53 )), when=object_is(nth_array_object(53 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(54 )), when=object_is(nth_array_object(54 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(55 )), when=object_is(nth_array_object(55 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(56 )), when=object_is(nth_array_object(56 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(57 )), when=object_is(nth_array_object(57 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(58 )), when=object_is(nth_array_object(58 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(59 )), when=object_is(nth_array_object(59 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(60 )), when=object_is(nth_array_object(60 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(61 )), when=object_is(nth_array_object(61 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(62 )), when=object_is(nth_array_object(62 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(63 )), when=object_is(nth_array_object(63 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(64 )), when=object_is(nth_array_object(64 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(65 )), when=object_is(nth_array_object(65 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(66 )), when=object_is(nth_array_object(66 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(67 )), when=object_is(nth_array_object(67 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(68 )), when=object_is(nth_array_object(68 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(69 )), when=object_is(nth_array_object(69 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(70 )), when=object_is(nth_array_object(70 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(71 )), when=object_is(nth_array_object(71 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(72 )), when=object_is(nth_array_object(72 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(73 )), when=object_is(nth_array_object(73 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(74 )), when=object_is(nth_array_object(74 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(75 )), when=object_is(nth_array_object(75 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(76 )), when=object_is(nth_array_object(76 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(77 )), when=object_is(nth_array_object(77 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(78 )), when=object_is(nth_array_object(78 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(79 )), when=object_is(nth_array_object(79 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(80 )), when=object_is(nth_array_object(80 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(81 )), when=object_is(nth_array_object(81 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(82 )), when=object_is(nth_array_object(82 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(83 )), when=object_is(nth_array_object(83 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(84 )), when=object_is(nth_array_object(84 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(85 )), when=object_is(nth_array_object(85 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(86 )), when=object_is(nth_array_object(86 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(87 )), when=object_is(nth_array_object(87 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(88 )), when=object_is(nth_array_object(88 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(89 )), when=object_is(nth_array_object(89 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(90 )), when=object_is(nth_array_object(90 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(91 )), when=object_is(nth_array_object(91 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(92 )), when=object_is(nth_array_object(92 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(93 )), when=object_is(nth_array_object(93 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(94 )), when=object_is(nth_array_object(94 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(95 )), when=object_is(nth_array_object(95 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(96 )), when=object_is(nth_array_object(96 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(97 )), when=object_is(nth_array_object(97 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(98 )), when=object_is(nth_array_object(98 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(99 )), when=object_is(nth_array_object(99 ), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(100)), when=object_is(nth_array_object(100), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(101)), when=object_is(nth_array_object(101), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(102)), when=object_is(nth_array_object(102), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(103)), when=object_is(nth_array_object(103), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(104)), when=object_is(nth_array_object(104), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(105)), when=object_is(nth_array_object(105), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(106)), when=object_is(nth_array_object(106), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(107)), when=object_is(nth_array_object(107), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(108)), when=object_is(nth_array_object(108), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(109)), when=object_is(nth_array_object(109), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(110)), when=object_is(nth_array_object(110), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(111)), when=object_is(nth_array_object(111), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(112)), when=object_is(nth_array_object(112), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(113)), when=object_is(nth_array_object(113), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(114)), when=object_is(nth_array_object(114), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(115)), when=object_is(nth_array_object(115), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(116)), when=object_is(nth_array_object(116), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(117)), when=object_is(nth_array_object(117), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(118)), when=object_is(nth_array_object(118), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(119)), when=object_is(nth_array_object(119), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(120)), when=object_is(nth_array_object(120), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(121)), when=object_is(nth_array_object(121), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(122)), when=object_is(nth_array_object(122), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(123)), when=object_is(nth_array_object(123), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(124)), when=object_is(nth_array_object(124), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(125)), when=object_is(nth_array_object(125), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(126)), when=object_is(nth_array_object(126), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(127)), when=object_is(nth_array_object(127), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(128)), when=object_is(nth_array_object(128), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(129)), when=object_is(nth_array_object(129), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(130)), when=object_is(nth_array_object(130), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(131)), when=object_is(nth_array_object(131), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(132)), when=object_is(nth_array_object(132), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(133)), when=object_is(nth_array_object(133), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(134)), when=object_is(nth_array_object(134), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(135)), when=object_is(nth_array_object(135), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(136)), when=object_is(nth_array_object(136), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(137)), when=object_is(nth_array_object(137), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(138)), when=object_is(nth_array_object(138), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(139)), when=object_is(nth_array_object(139), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(140)), when=object_is(nth_array_object(140), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(141)), when=object_is(nth_array_object(141), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(142)), when=object_is(nth_array_object(142), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(143)), when=object_is(nth_array_object(143), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(144)), when=object_is(nth_array_object(144), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(145)), when=object_is(nth_array_object(145), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(146)), when=object_is(nth_array_object(146), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(147)), when=object_is(nth_array_object(147), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(148)), when=object_is(nth_array_object(148), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(149)), when=object_is(nth_array_object(149), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(150)), when=object_is(nth_array_object(150), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(151)), when=object_is(nth_array_object(151), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(152)), when=object_is(nth_array_object(152), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(153)), when=object_is(nth_array_object(153), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(154)), when=object_is(nth_array_object(154), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(155)), when=object_is(nth_array_object(155), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(156)), when=object_is(nth_array_object(156), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(157)), when=object_is(nth_array_object(157), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(158)), when=object_is(nth_array_object(158), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(159)), when=object_is(nth_array_object(159), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(160)), when=object_is(nth_array_object(160), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(161)), when=object_is(nth_array_object(161), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(162)), when=object_is(nth_array_object(162), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(163)), when=object_is(nth_array_object(163), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(164)), when=object_is(nth_array_object(164), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(165)), when=object_is(nth_array_object(165), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(166)), when=object_is(nth_array_object(166), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(167)), when=object_is(nth_array_object(167), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(168)), when=object_is(nth_array_object(168), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(169)), when=object_is(nth_array_object(169), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(170)), when=object_is(nth_array_object(170), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(171)), when=object_is(nth_array_object(171), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(172)), when=object_is(nth_array_object(172), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(173)), when=object_is(nth_array_object(173), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(174)), when=object_is(nth_array_object(174), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(175)), when=object_is(nth_array_object(175), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(176)), when=object_is(nth_array_object(176), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(177)), when=object_is(nth_array_object(177), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(178)), when=object_is(nth_array_object(178), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(179)), when=object_is(nth_array_object(179), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(180)), when=object_is(nth_array_object(180), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(181)), when=object_is(nth_array_object(181), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(182)), when=object_is(nth_array_object(182), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(183)), when=object_is(nth_array_object(183), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(184)), when=object_is(nth_array_object(184), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(185)), when=object_is(nth_array_object(185), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(186)), when=object_is(nth_array_object(186), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(187)), when=object_is(nth_array_object(187), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(188)), when=object_is(nth_array_object(188), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(189)), when=object_is(nth_array_object(189), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(190)), when=object_is(nth_array_object(190), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(191)), when=object_is(nth_array_object(191), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(192)), when=object_is(nth_array_object(192), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(193)), when=object_is(nth_array_object(193), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(194)), when=object_is(nth_array_object(194), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(195)), when=object_is(nth_array_object(195), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(196)), when=object_is(nth_array_object(196), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(197)), when=object_is(nth_array_object(197), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(198)), when=object_is(nth_array_object(198), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(199)), when=object_is(nth_array_object(199), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(200)), when=object_is(nth_array_object(200), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(201)), when=object_is(nth_array_object(201), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(202)), when=object_is(nth_array_object(202), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(203)), when=object_is(nth_array_object(203), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(204)), when=object_is(nth_array_object(204), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(205)), when=object_is(nth_array_object(205), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(206)), when=object_is(nth_array_object(206), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(207)), when=object_is(nth_array_object(207), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(208)), when=object_is(nth_array_object(208), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(209)), when=object_is(nth_array_object(209), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(210)), when=object_is(nth_array_object(210), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(211)), when=object_is(nth_array_object(211), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(212)), when=object_is(nth_array_object(212), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(213)), when=object_is(nth_array_object(213), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(214)), when=object_is(nth_array_object(214), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(215)), when=object_is(nth_array_object(215), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(216)), when=object_is(nth_array_object(216), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(217)), when=object_is(nth_array_object(217), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(218)), when=object_is(nth_array_object(218), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(219)), when=object_is(nth_array_object(219), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(220)), when=object_is(nth_array_object(220), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(221)), when=object_is(nth_array_object(221), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(222)), when=object_is(nth_array_object(222), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(223)), when=object_is(nth_array_object(223), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(224)), when=object_is(nth_array_object(224), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(225)), when=object_is(nth_array_object(225), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(226)), when=object_is(nth_array_object(226), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(227)), when=object_is(nth_array_object(227), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(228)), when=object_is(nth_array_object(228), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(229)), when=object_is(nth_array_object(229), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(230)), when=object_is(nth_array_object(230), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(231)), when=object_is(nth_array_object(231), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(232)), when=object_is(nth_array_object(232), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(233)), when=object_is(nth_array_object(233), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(234)), when=object_is(nth_array_object(234), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(235)), when=object_is(nth_array_object(235), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(236)), when=object_is(nth_array_object(236), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(237)), when=object_is(nth_array_object(237), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(238)), when=object_is(nth_array_object(238), "c7 timer")),
        measured(2*object_c7_timer(nth_array_object(239)), when=object_is(nth_array_object(239), "c7 timer"))
        ),
    format = "FRAMES",
    lower_is_better = false
)

function c8_coin_arrow_cond(obj) {
    return unless(!object_is(obj, "coin formation"))
        && unless(object_coin_formation_type(obj) != 4)
        && once(prev(object_coin_formation_collects(obj)) < 8
        && prev(object_coin_formation_collects(obj)) >= 4)
        && object_coin_formation_collects(obj) == 8
}

achievement(
    title = "Coin Collecting with Certain Death",
    description = "Course 8 - Collect all 8 coins from the arrow over quicksand.",
    points = 5,
    trigger = in_area("Course 8", 1) && never(level_changed()) && any_of(array_map(range(0, 239), a => c8_coin_arrow_cond(nth_array_object(a))), b => b),
    id=237275,
    badge="263358"
)

function c9_puzzle_activated_cond(obj) {
    // fit this in one group
    return object_is(obj, "c9 puzzle")
        && prev(object_action(obj)) == 0
        && just_increased(object_action(obj))
}

achievement(
    title = "You're No Fun...",
    description = "Course 9 - Collect the star 'The Furnace Fun Wannabe' without activating any of the puzzles.",
    points = 3,
    trigger = remained_in_level("Course 9")
        && once(sublevel_id__mem == 1 && in_3d_box(3860.0, 4040.0, 600.0, 1000.0, -6540.0, -6600.0))
        && all_of(array_map(range(0, 239), a => c9_puzzle_activated_cond(nth_array_object(a))), b => never(b))
    
        && trigger_when(collecting_star_object("regular star", 5)),
    id=237276,
    badge="263359"
)

achievement(
    title = "Great View up Here",
    description = "Guest Course 1 - Stand on top of the roof of the Whomps' fortress (the second area).",
    points = 5,
    trigger = in_area("Guest Course 1", 2)
        && trigger_when(pos_y() > 6800.00 && pos_y() < 7000.00
            && airborne__mem == 0
            && surface_normal_y(mario_floor_tri()) > 0.99),
    id=237277,
    badge="263360"
)

achievement(
    title = "Bypassing the Slopes",
    description = "Guest Course 2 - Collect the star 'Slide-Slide for the Star' without butt sliding.",
    points = 5,
    trigger = remained_in_level("Guest Course 2")
        && never(mario_action_changed_to("butt slide"))
        && never(mario_action_changed_to("hold butt slide"))
        && trigger_when(collecting_star_object("regular star", 4)),
    id=237278,
    badge="263361"
)

achievement(
    title = "Let's Give Those Rabbits Glasses!",
    description = "Guest Course 3 - Collect the star 'All Hail King Carrot' without taking damage in the King Carrot area.",
    points = 5,
    trigger = in_level("Guest Course 3")
        && once(just_changed_to(sublevel_id__mem, 3))
        && never(level_changed())
        && never(just_took_damage())
        && trigger_when(collecting_star_object("spawned star", 5)),
    id=237279,
    badge="263362"
)

achievement(
    title = "I Still Don't Need Your Gimmick",
    description = "Guest Course 4 - Collect the star 'Zeus's Domain' without jump kicking.",
    points = 10,
    trigger = remained_in_level("Guest Course 4")
        && mission__mem == 5
        && never(mario_action_changed_to("air kick"))
        && trigger_when(collecting_star_object("regular star", 5)),
    id=237280,
    badge="263363"
)

achievement(
    title = "Not Really a Speedrun nor Water",
    description = "Guest Course 5 - Collect the star 'A Speedrun Over the Water without pressing the purple switch.",
    points = 3,
    trigger = remained_in_level("Guest Course 5")
        && sublevel_id__mem == 1
        && never(object_is(stood_on_object(), "purple box switch")
            && object_action(stood_on_object()) == 1)
        && trigger_when(collecting_star_object("regular star", 0)),
    id=237281,
    badge="263364"
)

achievement(
    title = "Acrobatic Flier Redux",
    description = "Wing Cap Stage - Begin your flight from the switch platform and directly collect the star without touching the ground.",
    points = 5,
    trigger = in_level("Wing Cap")
        && never(level_changed())
        && once(airborne__mem == 0
            && in_3d_box(-2800.0, -2200.0, 7200.0, 7500.0, 1600.0, 2200.0))
        && never(airborne__mem == 0
            && !in_3d_box(-2800.0, -2200.0, 7200.0, 7500.0, 1600.0, 2200.0))
        && trigger_when(collecting_star_object("regular star", 0)),
    id=237282,
    badge="263365"
)

achievement(
    title = "To the Moon, Again",
    description = "Cosmic Wall - Jump too high into the air and hear some fitting music as you Game Over.",
    points = 1,
    trigger = in_level("SEGA")
        && repeated(210, music_id__mem == 83)
        && never(just_changed_from(music_id__mem, 83)),
    id=237283,
    badge="263366"
)

achievement(
    title = "Keep Your Cool, Again",
    description = "ToasterKetchup's Level - Collect the star 'Slippery Snow' without taking damage.",
    points = 10,
    trigger = remained_in_level("ToasterKetchup")
        && never(just_took_damage())
        && trigger_when(collecting_star_object("regular star", 0)),
    id=237284,
    badge="263367"
)

gamer_mode__mem = bit0(0x40d793)
b3_fight = nth_array_object(3)

achievement(
    title = "Another Bullet Hell",
    description = "Defeat the final Bowser on Gamer Mode with at least half HP remaining (must talk to Bowser).",
    points = 10,
    trigger = in_level("Final Fight")
        && never(screen_changed())
        && once(just_increased(gamer_mode__mem))
        && hp() >= 0x400
        && object_is(b3_fight, "b3 fight controller")
        && trigger_when(object_is(used_object(), "bowser 3")),
    id=237285,
    badge="263368"
)

credits = nth_array_object(0)

achievement(
    title = "Always Ends With Dorrie",
    description = "Mash many buttons during the credits to spawn a friend (see Measured for progress).",
    points = 2,
    trigger = in_level("End Credits")
        && object_is(credits, "credits controller")
        && trigger_when(prev(object_credits_mashed_count(credits)) < 1600)
        && trigger_when(prev(object_credits_mashed_count(credits)) >= 1550)
        && (trigger_when(object_credits_mashed_count(credits) == 1600)
            || measured(object_credits_mashed_count(credits) == 1600, when=in_level("End Credits"))),
    id=237286,
    badge="263369"
)

// RP

stars__value = rich_presence_value("Number", nof_stars())

meta_descriptions = {
    0x00: "Starting up the game",
    0x21: "In File Select",
}

general_level_dict = {
    0x10: "exploring the first overworld",
    0x1a: "not doing much in the third overworld",
    
    0x09: "hanging around in Treetrunk Valley",
    0x18: "feeling like Samus in Brinstar Jungle",
    0x0C: "jumping around in City in the Sky",
    0x05: "grooving in Bustin' Dusk Beach",
    0x04: "exploring a multicolored Pyramid Desert",
    0x07: "having frostburn in Burning Arctic Cavern",
    0x16: "glowing with excitement in Cryptic Phosphor Tower",
    0x08: "visiting China in Dragon Road Chun-Nan",
    0x17: "making magic happen in Hang Mystic Mansion",
    
    0x0b: "taking down old enemies in The Classic Stage",
    0x24: "getting revenge on stars in Mountain Above the Clouds",
    0x0d: "meeting new friends in Vintage Castle",
    0x0e: "embracing the flame in Temple of Prometheus",
    0x0f: "on a papercraft adventure in Autumn Mountain",
    
    0x1c: "on an excavating mission in Pyramid Cavern",
    0x1d: "flying to the finish at Pink Flying House",
    0x12: "within the hack creators' Halls of Fame",

    0x13: "rising above in Ascended Paradise", // cheeze
    0x1b: "jumping and sliding in Freezeflame Trials", // toaster
    
    0x11: "on a cold journey in the Ice Mines",
    0x1e: "fighting Bowser in the Ice Mines",
    0x15: "not enjoying the theme park at the Crimson Carnival",
    0x22: "facing the Final Bowser in the Crimson Carnival",
}

level_06__lookup = rich_presence_lookup("Level06", sublevel_id__mem, {
    0x01: "burning with energy in the second overworld",
    0x02: "freezing in the night in the second overworld"
})

level_14__lookup = rich_presence_lookup("Level14", sublevel_id__mem, {
    0x01: "avoiding flying enemies in Airship Force", // crash
    0x02: "maneuvering through the ruins of Jungle Falls", // kaze
    0x03: "climbing the equipment in Planet Wisp Construction"
})

level_1f__lookup = rich_presence_lookup("Level1f", sublevel_id__mem,{
    0x01: "on a runaway vehicle in Cosmic Cart Joy Ride",
    0x02: "manipulating gravity in Cosmic Wall"
})

level_0a__lookup = rich_presence_lookup("Level0a", sublevel_id__mem,{
    0x01: "trapped in a tiny box in the End Credits",
    0x02: "about to crash the game due to having cheated",
})

level__lookup = rich_presence_lookup("LevelsWithoutSublevels", level_id__mem, general_level_dict, "in an unbeknownst location")

stars__value = rich_presence_value("Number", nof_stars())

file__lookup  = rich_presence_lookup("File", file_num__mem, {
    0x01: "A", 0x02: "B", 0x03: "C", 0x04: "D"
}, "??")

function rp_cond_same_display(cond, lookup) {
    rich_presence_conditional_display(cond, 
    "Mario-{2} is {0} with {1}⭐ [🔴{3}] [🟢{4}]", lookup, stars__value, file__lookup, 
        rich_presence_lookup("Switch", pressed_switch__mem("red"), {1:"▣"}, "▢"),
        rich_presence_lookup("Switch", pressed_switch__mem("green"), {1:"▣"}, "▢")
    )
}

cond_displays = {
    "general": {"cond": mem_in(level_id__mem, general_level_dict), "lookup": level__lookup},
    "level14": {"cond": (level_id__mem == 0x14), "lookup": level_14__lookup},
    "level1f": {"cond": (level_id__mem == 0x1f), "lookup": level_1f__lookup},
    "level0a": {"cond": (level_id__mem == 0x0a), "lookup": level_0a__lookup},
    "level06": {"cond": (level_id__mem == 0x06), "lookup": level_06__lookup},
}

rich_presence_conditional_display(in_title_or_file_select(), "{0}", rich_presence_lookup("Fileless", music_id__mem, meta_descriptions))
for k in cond_displays {
    rp_cond_same_display(cond_displays[k]["cond"], cond_displays[k]["lookup"])
}
rich_presence_display("On a grand adventure through many different levels.")