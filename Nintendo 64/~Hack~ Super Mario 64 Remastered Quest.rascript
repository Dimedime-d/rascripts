// ~Hack~ Super Mario 64: Remastered Quest
// #ID = 20413
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
    "CURRENT DEMO INPUT":   0x32d5f0,
    
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
    
    "TTC SPEED SETTING":    0x36125a,
    "RED COINS COLLECTED":  0x3613fd,
}

// double-check this list between hacks, custom objects can shift things...
behaviour_script__values = { 
    "TTM slide exit":   0x800EB8A0,
    "teleporter":       0x800EB8DC,
    "coin formation":   0x800EBA6C,
    
    "purple box switch":0x800EC62C, // unchanged
    "grand star":       0x800EC894, // unchanged
    "koopa shell":      0x800ED0BC, //
    "exclamation box":  0x800ED3D0, // vanilla?
    "grabbable cork box":   0x800EF398, //
    "carpet":               0x800EFC30, //
    "blue coin for block":  0x800ED708, //
    
    "bowser 3":         0x800EC9D0,
    "blue coin switch": 0x800ED6E8,
    
    "regular star":     0x800EEFBC, // unchanged
    "spawned star":     0x800EEFE4, // unchanged

    "impartial 1-up":   0x800EF15C, //
    "stationary 1-up":  0x800EF1FC,
    "running away 1-up":    0x800EF190,
    "activator 1-up":   0x800EF26C, //
    "chasing 1-up":     0x800EF2C8,
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

// tkt 50250 - add a delta for obj != teleporter to prevent popping during level transition
// note: interaction object is cleared upon switching screens (generally set to Mario Spawn / Pipe)
function just_used_teleporter(id) {
    obj = interaction_object()
    return obj != 0
        && !object_was(obj, "teleporter")
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

ttc_speed_setting__addr = offsets["TTC SPEED SETTING"]
ttc_speed_setting__mem =  word(ttc_speed_setting__addr)

g_red_coins_collected__addr = offsets["RED COINS COLLECTED"]
g_red_coins_collected__mem = byte(g_red_coins_collected__addr)

g_current_demo_input__addr = offsets["CURRENT DEMO INPUT"]
g_current_demo_input__mem = dword(g_current_demo_input__addr)

function course_meta(value, sublevel_values, full_name) => {"value": value, "sublevel values": sublevel_values, "full name": full_name}

// https://github.com/n64decomp/sm64/blob/master/levels/level_defines.h level id's
course_infos = {
    "Castle Grounds":      course_meta(0x10, [-1],   "Castle Grounds"), // Castle Grounds
    "Inside Castle": course_meta(0x06, [-1], "Inside Castle"), // 1-2-3: Lobby/Upstairs/Basement
    "Castle Courtyard":      course_meta(0x1a, [-1], "Castle Courtyard"), // Castle Courtyard
    
    "Course 1":         course_meta(0x09, [-1],   "Bob-omb Festival"),
    "Course 2":         course_meta(0x18, [-1],   "Floating Fortress"),
    "Course 3":         course_meta(0x0c, [-1],   "Haunted Shipwreck Bay"),
    "Course 4":         course_meta(0x05, [-1],   "Cool Combusting Mountain"),
    "Course 5":         course_meta(0x04, [-1],   "Big Boo's Funhouse"),
    "Course 6":         course_meta(0x07, [-1],   "Hazy Mazy Labyrinth"),
    "Course 7":         course_meta(0x16, [-1],   "Pyroclastic Perils"),
    "Course 8":         course_meta(0x08, [-1],   "Shifted Sands Mirage"),
    "Course 9":         course_meta(0x17, [-1],   "Bowser's Desolate Dockyard"),
    "Course 10":        course_meta(0x0a, [-1],   "Windrift Valley"),
    "Course 11":        course_meta(0x0b, [-1],   "Flooded Atlantis"),
    "Course 12":        course_meta(0x24, [-1],   "Fall Fall Mountain"),
    "Course 13":        course_meta(0x0d, [-1],   "Warp Maze Isles"),
    "Course 14":        course_meta(0x0e, [-1],   "Trick Top Clock"),
    "Course 15":        course_meta(0x0f, [-1],   "Risky Ride"),
    
    "Aquarium":         course_meta(0x14, [-1],   "The Secret Aquarium"),
    "Cloud Stage":      course_meta(0x1f, [-1],   "Cloudy Rainbow Sky"),
    "Slide":            course_meta(0x1b, [-1],   "Secret Slide"),
    
    "Bowser 1":         course_meta(0x11, [-1],   "The Dark World"),
    "Key 1":            course_meta(0x1e, [-1],   "The Dark World"),
    "Bowser 2":         course_meta(0x13, [-1],   "The Fire Sea"),
    "Key 2":            course_meta(0x21, [-1],   "The Fire Sea"),
    "Bowser 3":         course_meta(0x15, [-1],   "Bowser in the Sky"),
    "Final Fight":      course_meta(0x22, [-1],   "Bowser in the Sky"),
    
    "Metal Cap":        course_meta(0x1c, [-1],   "Cavern of the Metal Cap"),
    "Wing Cap":         course_meta(0x1d, [-1],   "Tower of the Wing Cap"),
    "Vanish Cap":       course_meta(0x12, [-1],   "Vanish Cap Under the Moat"),
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

function level_changed() => just_changed_any(level_id__mem)
function screen_changed() => just_changed_any(level_id__mem) || just_changed_any(sublevel_id__mem)

// for challenges that, if failed, require re-entering the level
function remained_in_level(name, hit=1) {
    trigger_hit = always_true()
    if (hit != 0)
        trigger_hit = once(prev(level_id__mem) != course_infos[name]["value"])
    return never(!in_level(name)) && trigger_hit && hud_stars_shown() == 1
}

function common_in_file_check() => !in_intro_or_file_select() && level_id__mem != 1 && g_current_demo_input__mem == 0

//
//  Cheevs
//

// gimme
achievement(
    title = "Secret Mountain Warp",
    description = "Find the warp to a pyramid and gain access to the castle basement.",
    points = 1,
    trigger = in_level("Course 12")
        && object_is(interaction_object(), "TTM slide exit"),
    id = 244861, badge = "271688"
)

// switches
function rgb_trigger() {
    return level_id__mem == prev(level_id__mem) // to prevent switching files after the ending picture puts you back to the title screen...
    && file_num__mem == prev(file_num__mem)
    
    && tally(2, 
    [once(pressed_switch("red", delta=1)),
    once(pressed_switch("green", delta=1)),
    once(pressed_switch("blue", delta=1))
    ])
    
    && measured(tally(3, 
    [once(pressed_switch("red")),
    once(pressed_switch("green")),
    once(pressed_switch("blue"))
    ]), when = common_in_file_check())
    
    && never(tally(3, 
    [once(pressed_switch("red", delta=1)),
    once(pressed_switch("green", delta=1)),
    once(pressed_switch("blue", delta=1))
    ]))
}

// caps / bowsers

achievement(
    title = "Switched up Switches",
    description = "Press the red, green, and blue !-switches.",
    points = 5,
    trigger = rgb_trigger(),
    id = 244810, badge = "271637"
)

achievement(
    title = "Same Old Bowser, Decades Later",
    description = "Defeat Bowser in the Dark World and collect his key.",
    points = 5,
    trigger = in_level("Key 1") && just_collected_star(),
    id = 244811, badge = "271638"
)

achievement(
    title = "Still Busted His Hideout",
    description = "Defeat Bowser in the Fire Sea and collect his key.",
    points = 5,
    trigger = in_level("Key 2") && just_collected_star(),
    id = 244812, badge = "271639"
)

achievement(
    title = "Now is Time for Bowser to Take a Nap",
    description = "Defeat Bowser in the Sky and collect the grand star.",
    points = 10,
    trigger = in_level("Final Fight") && interaction_object() != 0 && object_is(interaction_object(), "grand star"),
    id = 244813, badge = "271640"
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

// https://github.com/n64decomp/sm64/blob/master/levels/course_defines.h indexes (add 0x0c) (remember endian weirdness)
//and https://github.com/aglab2/SM64StarDisplay/blob/9d6c11e6af49a4f90a5d8020e8a94fdd611603d0/StarManager/LevelInfo.cs#L25
course_offsets = {
    "Course 1":  course_stars_meta(sum_star_bits(0x0f, range(0, 6)), 10, "Having a Blast", id = 244814, badge = "271641"), 
    "Course 2":  course_stars_meta(sum_star_bits(0x0e, range(0, 6)), 10, "Levitating Loot", id = 244821, badge = "271648"),
    "Course 3":  course_stars_meta(sum_star_bits(0x0d, range(0, 6)), 10, "Plundering the Ships", id = 244822, badge = "271649"),
    "Course 4":  course_stars_meta(sum_star_bits(0x0c, range(0, 6)), 10, "That Level with Fire and Ice", id = 244823, badge = "271650"),
    "Course 5":  course_stars_meta(sum_star_bits(0x13, range(0, 6)), 10, "Boos' Lost Treasures", id = 244824, badge = "271651"),
    "Course 6":  course_stars_meta(sum_star_bits(0x12, range(0, 6)), 10, "Always a Maze", id = 244825, badge = "271652"),
    "Course 7":  course_stars_meta(sum_star_bits(0x11, range(0, 6)), 10, "Scorching Shatters", id = 244826, badge = "271653"),
    "Course 8":  course_stars_meta(sum_star_bits(0x10, range(0, 6)), 10, "Coarse, Rough, Irritating Sand", id = 244827, badge = "271654"),
    "Course 9":  course_stars_meta(sum_star_bits(0x17, range(0, 6)), 10, "Dock of the Lost Submarine", id = 244828, badge = "271655"),
    "Course 10":  course_stars_meta(sum_star_bits(0x16, range(0, 6)), 10, "Snowman's Extra Treasures", id = 244815, badge = "271642"),
    "Course 11":  course_stars_meta(sum_star_bits(0x15, range(0, 6)), 10, "A Water Star Adventure", id = 244816, badge = "271643"),
    "Course 12":  course_stars_meta(sum_star_bits(0x14, range(0, 6)), 10, "Falling Forever", id = 244817, badge = "271644"),
    "Course 13":  course_stars_meta(sum_star_bits(0x1b, range(0, 6)), 10, "Mini-Mega Mario Maze", id = 244818, badge = "271645"),
    "Course 14":  course_stars_meta(sum_star_bits(0x1a, range(0, 6)), 10, "Over-Clocked Tower", id = 244819, badge = "271646"),
    "Course 15":  course_stars_meta(sum_star_bits(0x19, range(0, 6)), 10, "Perilous Platforming", id = 244820, badge = "271647"),
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

// expects a star_bits-like object with a mem attribute
function add_star_bits(star_bits) {
    return sum_of(star_bits, s => s["mem"])
}

overworld_stars = [
    sum_star_bits(0x0b, [0, 2, 3, 4]) // rip toad
]

cap_courses_stars = [
    sum_star_bits(0x1c, [0]), // MC
    sum_star_bits(0x23, [0, 1]), // WC
    sum_star_bits(0x22, [0, 1]) // VC, double check this pls
]

bowser_courses_stars = [
    sum_star_bits(0x18, [0]), // B1
    sum_star_bits(0x1f, [0, 1]), // B2
    sum_star_bits(0x1e, [0]), // B3
]

side_course_stars = [
    sum_star_bits(0x1d, [1]), // slide
    sum_star_bits(0x20, [0]), // aquarium
    sum_star_bits(0x21, [0]), // cloud stage
]

function remastered_star_total() {
    all_stars = []
    for c in course_offsets {
        array_push(all_stars, course_offsets[c]["star bits"]["mem"])
    }
    misc_stars = [overworld_stars, cap_courses_stars, bowser_courses_stars, side_course_stars]
    for m in misc_stars {
        array_push(all_stars, add_star_bits(m))
    }
    return sum_of(all_stars, s => s)
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
    stars = overworld_stars, total = 4,
    title = "Stars from Bowser's Well-Treated Minions",
    description = "Collect all 4 stars in the castle.",
    points = 1, id = 244829, badge = "271656"
)

star_collection_achievement(
    stars = cap_courses_stars, total = 5,
    title = "Old Caps, New Treasures",
    description = "Collect all 5 stars across the Wing Cap, Metal Cap, and Vanish Cap courses.",
    points = 5, id = 244830, badge = "271657"
)

star_collection_achievement(
    stars = bowser_courses_stars, total = 4,
    title = "Bowser's New Obstacles",
    description = "Collect all 4 stars across the Dark World, the Fire Sea, and Bowser in the Sky.",
    points = 5, id = 244831, badge = "271658"
)

star_collection_achievement(
    stars = side_course_stars, total = 3,
    title = "Small Castle Detours",
    description = "Collect all 3 stars across the Secret Slide, the Secret Aquarium, and the Cloudy Rainbow Sky.",
    points = 5, id = 244832, badge = "271659"
)

// Milestones

function star_milestone_trigger(num_stars) {
    cond = level_id__mem == prev(level_id__mem) // to prevent switching files to pop the achievement
        && file_num__mem == prev(file_num__mem)
        && prev(remastered_star_total()) == num_stars - 1 
    if (num_stars > 1)
        cond = cond && measured(remastered_star_total() == num_stars, when=common_in_file_check())
    else
        cond = cond && remastered_star_total() == num_stars
    return cond
}

function milestone_meta(title, description, stars, points, id=0, badge="0") => {"title": title, "description": description, "stars": stars, "points": points, "id": id, "badge": badge}

milestones = [
    milestone_meta("Something's Different...",
        "Collect your first star.",
        stars=1, points=1, id = 244833, badge = "271660"),
    milestone_meta("The Door Upstairs",
        "Collect 25 stars.",
        stars=25, points=5, id = 244834, badge = "271661"),
    milestone_meta("The Door in the Basement",
        "Collect 40 stars.",
        stars=40, points=5, id = 244835, badge = "271662"),
    milestone_meta("The Door in the Lobby",
        "Collect 60 stars.",
        stars=60, points=5, id = 244836, badge = "271663"),
    milestone_meta("The Door up Top",
        "Collect 75 stars.",
        stars=75, points=10, id = 244837, badge = "271664"),
    milestone_meta("Full Power, Remastered",
        "Collect all 121 stars.",
        stars=121, points=25, id = 244838, badge = "271665"),
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
            
            if (obj_name == "chasing 1-up") {
                coll_check1 = coll_check && object_action(obj_addr) == 1
                coll_check2 = coll_check && object_action(obj_addr) == 3
                    && object_timer(obj_addr) >= 37
                array_push(mushie_tally,
                    repeated(t["count"], coll_check1))
                array_push(mushie_tally,
                    repeated(t["count"], coll_check2))
            }
            else {
                array_push(mushie_tally,
                    repeated(t["count"], coll_check))   
            }
        }
    }
    return tally(total_count, mushie_tally)
}

function mushies_meta(title="", description="", points=0, tallies=[], numbered_course=1, id=0, badge="0") => {"title": title, "description": description, "points": points, "tallies": tallies,  "id": id, "badge": badge}

mushies_data = {
    "Course 11": mushies_meta("Aquatic Lives", "Flooded Atlantis - Collect both 1-up mushrooms in the coin rings in the main area.", 2,
        [{"type": "stationary", "count": 2}], id = 244840, badge = "271667"),
    "Course 14": mushies_meta("No Star, No Thwomp", "Trick Top Clock - Collect the 1-up mushroom at the top of the clock.", 1, [{"type": "impartial", "count": 1}], id = 244841, badge = "271668"),
    "Course 1": mushies_meta("No Fast Travel for You", "Bob-omb Festival - Collect the 1-up mushroom where a warp used to be.", 1, [{"type": "stationary", "count": 1}], id = 244839, badge = "271666"),
    "Course 2": mushies_meta("Levitating Lives", "Floating Fortress - Collect all 3 1-up mushrooms. (2 box + blast walls)", 3, [{"type": "impartial", "count": 1},
    {"type": "running away", "count": 1},
    {"type": "activator", "count": 1}], id = 244842, badge = "271669"),
    "Course 3": mushies_meta("Ghostly Lives", "Haunted Shipwreck Bay - Collect both 1-up mushrooms. (1 box + 1 on ship)", 2, [{"type": "running away", "count": 1},
    {"type": "stationary", "count": 1}], id = 244843, badge = "271670")
}

for course in mushies_data {
    info = mushies_data[course]
    
    mushie_count = sum_of(info["tallies"], t => t["count"])
    
    mushie_tally = tally_all_1ups(tallies = mushies_data[course]["tallies"], total_count = mushie_count)
    
    collect_cond = always_true()
    
    if (mushie_count == 1) {
        collect_cond = mushie_tally
    }
    else {
        collect_cond = measured(mushie_tally)
    }

    
    achievement(
        title = info["title"],
        description = info["description"],
        points = info["points"],
        trigger = remained_in_level(course, hit=0)
            && collect_cond
    )
}


// challenge time!

function object_box_broken(addr) => object_is(addr, "exclamation box")
    && object_active(addr) != 0
    && object_subtype(addr) > 2 // non respawnable type
    && just_changed_to(object_action(addr), 3)
    
function tally_broken_boxes(count) {
    broken_boxes = array_map(range(0, 239), i => once(object_box_broken(nth_array_object(i))))
    return tally(count, broken_boxes)
}

achievement(
    title = "Festival Box Hunt",
    description = "Bob-omb Festival - Break all 19 yellow !-boxes.",
    points = 5,
    trigger = remained_in_level("Course 1", hit=0)
        && measured(tally_broken_boxes(19)),
    id = 244844,
    badge = "271671"
)

achievement(
    title = "Magic Platforms with a Handicap",
    description = "Floating Fortress - Collect the star 'Quick Step - Magic Platforms' while holding a cork box.",
    points = 10,
    trigger = remained_in_level("Course 2", hit=0)
        && object_was(held_object(), "grabbable cork box")
        && trigger_when(collecting_star_object("regular star", 4)),
    id = 244845,
    badge = "271672"
)

achievement(
    title = "Careful Spooky Exploration",
    description = "Haunted Shipwreck Bay - Collect the star 'The Haunted Cavern' without taking damage.",
    points = 5,
    trigger = remained_in_level("Course 3")
        && never(hp_decrement() > 0)
        && never(any_of(burning_actions, a => mario_action_is(a)))
        && trigger_when(collecting_star_object("regular star", 3)),
    id = 244846,
    badge = "271673"
)

//achievement(
//    title = "Climbing Ships the Old-Fashioned Way",
//    description = "Haunted Shipwreck Bay - Collect the star 'Secrets of the Ships' without riding a shell.",
//    points = 5,
//    trigger = remained_in_level("Course 3")
//        && never(object_changed_to(ridden_object(), "koopa shell"))
//        && trigger_when(collecting_star_object("spawned star", 4))
//)

achievement(
    title = "Listening for the Ghost",
    description = "Haunted Shipwreck Bay - Talk to the Bob-omb Buddy's ghost friend (invisible) to open the cannon.",
    points = 1,
    trigger = in_level("Course 3")
        && (dialog_id__mem == 47 || dialog_id__mem == 106),
    id = 244847,
    badge = "271674"
)

achievement(
    title = "Hot-Headed Secrets",
    description = "Cool Combusting Mountain - Collect the star 'Secrets of the Fireballs' without taking damage or getting a metal cap.",
    points = 5,
    trigger = remained_in_level("Course 4")
        && never(just_took_damage())
        && never(just_increased(wearing_metal_cap()))
        && trigger_when(collecting_star_object("spawned star", 3)),
    id = 244848,
    badge = "271675"
)

achievement(
    title = "Gone in a Flash",
    description = "Big Boo's Funhouse - Collect the star 'Big Boo's Aerial Showdown' while still wearing both wing and vanish caps.",
    points = 5,
    trigger = remained_in_level("Course 5", hit=0)
        && prev(wearing_wing_cap()) != 0
        && prev(wearing_vanish_cap()) != 0
        && trigger_when(collecting_star_object("spawned star", 5)),
    id = 244849,
    badge = "271676"
)

achievement(
    title = "Flying Through the Maze",
    description = "Hazy Maze Labyrinth - Collect the star 'Switch Star of the Lake' while still wearing your wing cap.",
    points = 10,
    trigger = remained_in_level("Course 6", hit=0)
        && prev(wearing_wing_cap()) != 0
        && trigger_when(collecting_star_object("regular star", 1)),
    id = 244850,
    badge = "271677"
)

achievement(
    title = "Fiery Fight, Fiery Shot",
    description = "Pyroclastic Perils - Collect the star 'Circle the Fiery Eye' without taking damage.",
    points = 5,
    trigger = remained_in_level("Course 7")
        && sublevel_id__mem == 1
        && never(just_took_damage())
        && trigger_when(collecting_star_object("spawned star", 5)),
    id = 244851,
    badge = "271678"
)

achievement(
    title = "Just Fly Right In",
    description = "Shifting Sands Mirage - Collect the star 'Switch Box in the Tox' without standing on the purple switch.",
    points = 5,
    trigger = remained_in_level("Course 8")
        && sublevel_id__mem == 1
        && never(object_changed_to(stood_on_object(), "purple box switch"))
        && trigger_when(collecting_star_object("regular star", 1)),
    id = 244852,
    badge = "271679"
)

achievement(
    title = "Blues Around the Sinking Sand",
    description = "Shifting Sands Mirage - Collect all 6 switch blue coins inside the pyramid.",
    points = 5,
    trigger = remained_in_level("Course 8", hit=0)
        && sublevel_id__mem == 2
        && measured(tally_of(range(1, 4), 6, a => repeated(6,mario_collision_check(object_nth_collided_object(mario_object(), a), "blue coin for block", a)))),
    id = 244853,
    badge = "271680"
)

achievement(
    title = "Collect the Caps... Remastered Edition",
    description = "Bowser's Desolate Dockyard - Wear both metal and vanish caps at the same time.",
    points = 3,
    trigger = remained_in_level("Course 9")
        && wearing_vanish_cap() == 1
        && wearing_metal_cap() == 1,
    id = 244854,
    badge = "271681"
)

achievement(
    title = "Shallow Dives in the Freezing Pond",
    description = "Windrift Valley - Collect the star 'Red Coins in the Freezing Pond' without going below 7 HP.",
    points = 5,
    trigger = remained_in_level("Course 10")
        && sublevel_id__mem == 1
        && never(hp() < 0x700 && hp() >= 0x300)
        && trigger_when(collecting_star_object("spawned star", 1)),
    id = 244855,
    badge = "271682"
)

achievement(
    title = "Long Glide Below the Mountain",
    description = "Fall Fall Mountain - Collect the star 'The Mountain's Cannon Hole' while twirling.",
    points = 5,
    trigger = remained_in_level("Course 12")
        && mario_action_was("twirl")
        && trigger_when(collecting_star_object("regular star", 3)),
    id = 244856,
    badge = "271683"
)

achievement(
    title = "Wiggler's Blue Coins",
    description = "Warp Maze Isles - Collect 6 out of the 8 blue coins in the cave.",
    points = 5,
    trigger = remained_in_level("Course 13", hit=0)
        && sublevel_id__mem == 3
        && measured(tally_of(range(1, 4), 6, a => repeated(6,mario_collision_check(object_nth_collided_object(mario_object(), a), "blue coin for block", a)))),
    id = 244857,
    badge = "271684"
)

achievement(
    title = "Working Overtime",
    description = "Trick Top Clock - Collect the star 'Red Coins on the Hour' at the fastest clock speed.",
    points = 10,
    trigger = in_level("Course 14")
        && ttc_speed_setting__mem == 1
        && trigger_when(collecting_star_object("spawned star", 2)),
    id = 244858,
    badge = "271685"
)

leaderboard(
    title = "Overtime Red Coins",
    description = "Collect the star 'Red Coins on the Hour' at the fastest clock speed, as fast as possible.",
    start = in_level("Course 14") 
        && ttc_speed_setting__mem == 1
        && mario_action_is("airborne spawn"),
    cancel = !in_level("Course 14") || music_id__mem == 2,
    submit = collecting_star_object("spawned star", 2),
    value = measured(in_level("Course 14")),
    
    lower_is_better = true,
    format = "FRAMES"
)

achievement(
    title = "Slightly Longer Way Around",
    description = "Risky Ride - Collect the star 'Red Coins to the Ship' without standing on a carpet.",
    points = 4,
    trigger = remained_in_level("Course 15")
        && never(object_changed_to(stood_on_object(), "carpet"))
        && trigger_when(collecting_star_object("spawned star", 0)),
    id = 244859,
    badge = "271686"
)

achievement(
    title = "Fireproof Coins",
    description = "The Fire Sea - Collect the red coin star without taking damage.",
    points = 10,
    trigger = remained_in_level("Bowser 2")
        && never(just_took_damage())
        && trigger_when(collecting_star_object("spawned star", 0)),
    id = 244860,
    badge = "271687"
)

// RP

stars__value = rich_presence_value("Number", nof_stars())

meta_descriptions = {
    0x00: "Starting up the game",
    0x02: "Playing with Mario head",
    0x21: "In File Select",
}

general_level_dict = {
    0x10: "outside Peach's Castle",
    0x06: "inside Peach's Castle taken over by Bowser",
    0x1a: "hunting ghosts in the Castle Courtyard",
    
    0x09: "on an explosive adventure in Bob-omb Festival",
    0x18: "reaching new heights in Floating Fortress",
    0x0C: "exploring ships in Haunted Shipwreck Bay",
    0x05: "sliding around in Cool Combusting Mountain",
    0x04: "having a good time in Big Boo's Funhouse",
    0x07: "getting lost in Hazy Maze Labyrinth",
    0x16: "heating up in Pyroclastic Perils",
    0x08: "getting his clothes sandy in Shifted Sands Mirage",
    0x17: "not visiting the submarine in Bowser's Desolate Dockyard",
    0x0a: "getting blown away in Windrift Valley",
    0x0b: "diving deep in Flooded Atlantis",
    0x24: "descending for stars in Fall Fall Mountain",
    0x0d: "navigating the Warp Maze Isles",
    0x0e: "maneuvering around machinery in Trick Top Clock",
    0x0f: "traversing moving platforms in Risky Ride",
    
    0x1c: "in the familiar crystal Cavern of the Metal Cap",
    0x1d: "flying around in Tower of the Wing Cap",
    0x12: "under the moat again",

    0x1b: "on a familiar Secret Slide",
    0x14: "getting same old red coins in the Secret Aquarium",
    0x1f: "hopefully flying around in the Cloudy Rainbow Sky",
    
    0x11: "jumping around in a familiar Dark World",
    0x1e: "fighting Bowser in the Dark World",
    0x13: "not getting a warm welcome in the Fire Sea",
    0x21: "fighting Bowser on the tilting platform again in the Fire Sea",
    0x15: "searching for Bowser's secrets in the sky",
    0x22: "taking on Bowser in the Sky again",
}

level__lookup = rich_presence_lookup("LevelsWithoutSublevels", level_id__mem, general_level_dict, "in an unbeknownst location")

stars__value = rich_presence_value("Number", nof_stars())

file__lookup  = rich_presence_lookup("File", file_num__mem, {
    0x01: "A", 0x02: "B", 0x03: "C", 0x04: "D"
}, "??")

function rp_cond_same_display(cond, lookup) {
    rich_presence_conditional_display(cond, 
    "Mario-{2} is {0} with {1}⭐ [🔴{3}] [🟢{4}] [🔵{5}]", lookup, stars__value, file__lookup, 
        rich_presence_lookup("Switch", pressed_switch__mem("red"), {1:"▣"}, "▢"),
        rich_presence_lookup("Switch", pressed_switch__mem("green"), {1:"▣"}, "▢"),
        rich_presence_lookup("Switch", pressed_switch__mem("blue"), {1:"▣"}, "▢")
    )
}

cond_displays = {
    "general": {"cond": mem_in(level_id__mem, general_level_dict), "lookup": level__lookup}
}

rich_presence_conditional_display(in_intro_or_file_select() || level_id__mem == 1, "{0}", rich_presence_lookup("Fileless", music_id__mem, meta_descriptions))
rich_presence_conditional_display(g_current_demo_input__mem != 0, "Mario is in a demo!")
for k in cond_displays {
    rp_cond_same_display(cond_displays[k]["cond"], cond_displays[k]["lookup"])
}
rich_presence_display("On a remastered adventure through Peach's Castle")