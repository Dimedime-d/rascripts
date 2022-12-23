// ~Hack~ Victory Unity
// #ID = 21955
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
    "regular star":     0x800EEFBC, // unchanged
    "spawned star":     0x800EEFE4, // unchanged
    "box star":         0x800EB978,
    "100 coin star":    0x800EB98C,
    
    "exclamation box":  0x800ED3D0, // vanilla?
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

function collecting_star_object(obj_name, mission=-1) {
    obj = interaction_object()
    if (mission != -1)
        return obj != 0
           && object_is(obj, obj_name)
           && object_star_mission(obj) == mission
    return obj != 0
           && object_is(obj, obj_name)
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

function transition_active(del=1) {
    if (del==0)
        return transition_type__mem >= 0x100
    if (del==1)
        return prev(transition_type__mem) >= 0x100
}
    

TRANSITION_COLOR_FADE_IN = 0x101

ttc_speed_setting__addr = offsets["TTC SPEED SETTING"]
ttc_speed_setting__mem =  word(ttc_speed_setting__addr)

g_red_coins_collected__addr = offsets["RED COINS COLLECTED"]
g_red_coins_collected__mem = byte(g_red_coins_collected__addr)

g_current_demo_input__addr = offsets["CURRENT DEMO INPUT"]
g_current_demo_input__mem = dword(g_current_demo_input__addr)

function sum_star_bits(file_offset, bits) {
    if (file_offset == -1)
        return {
            "valid": false
        }
    off = current_file__addr + file_offset
    if (length(bits) == 7 && none_of(bits, b => b == 7))
        return { // just hard-code optimization for 7 bits
            "mem": (bitcount(off) - bit(7, off)),
            "sum": 7,
            "valid": true
        }
    return {
        "mem": sum_of(bits, b => bit(b, off)),
        "sum": length(bits),
        "valid": true
    }
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

// switch things up a bit, for each level, put a star bit in the course info
function course_meta(value, sublevel_value, bit_file_offset, bit, full_name, title="", points=0, id=0, badge="0") => {"value": value, "sublevel value": sublevel_value, "star bit": sum_star_bits(bit_file_offset, [bit]), "full name": full_name, "title": title, "points": points, "id": id, "badge": badge}

// https://github.com/n64decomp/sm64/blob/master/levels/level_defines.h level id's
course_infos = {
    "KBR2 OW1 Pluto":   course_meta(0x09, 0x01, 0x0F, 0, "the first overworld of King Boo's Revenge 2 requested by PlutoTheThing", "Wood Climbing", 1, 274344, "303456"),
    "KBR2 OW1 Morning": course_meta(0x09, 0x02, 0x0F, 1, "the first overworld of King Boo's Revenge 2 requested by MorningStorm", "8-Fold Wall Hugging Move", 4, 274343, "303455"),
    "KBR2 OW1 Iwer":    course_meta(0x09, 0x03, 0x0F, 2, "the first overworld of King Boo's Revenge 2 requested by Iwer Sonsch", "Healthy Environment", 3, 274342, "303454"),
    "KBR2 OW2":    course_meta(0x09, 0x04, 0x0F, 3, "the second overworld of King Boo's Revenge 2", "Invaders!", 3, 274345, "303457"),
    
    "SM74 OW1":         course_meta(0x18, 0x01, 0x0E, 0, "the first overworld of Super Mario 74", "Somewhere in the Nowhere", 2, 274368, "303480"),
    "SM74 OW2":         course_meta(0x18, 0x02, 0x0E, 1, "the second overworld of Super Mario 74", "Acrylic Blue Tower", 2, 274369, "303481"),
    
    "SR8 C10":          course_meta(0x0C, 0x01, 0x0D, 0, "Course 10 of Star Revenge 8", "The Upper Gardens", 3, 274391, "303503"),
    
    "SR8 C7":           course_meta(0x05, 0x01, 0x0C, 0, "Course 7 of Star Revenge 8", "Up High in the Sky", 10, 274392, "303504"),
    
    "LLT OW":           course_meta(0x04, 0x01, 0x13, 0, "the overworld of Lost Lunatic Trials", "Across the Big Wall", 3, 274349, "303461"),
    
    "MNE OW1 ARP":      course_meta(0x07, 0x01, 0x12, 0, "the first overworld of Mario's New Earth requested by A Random Player", "Jealous Caesar!", 3, 274352, "303464"),
    "MNE OW1 Hokk":     course_meta(0x07, 0x02, 0x12, 1, "the first overworld of Mario's New Earth requested by The Hokkanen", "Don't Be a Pushover Here!", 1, 274353, "303465"),
    "OoT Fort":         course_meta(0x07, 0x03, 0x12, 2, "Gerudo Fortress", "Cherry Coins of Panic", 10, 274359, "303471"),
    "OoT Temple":       course_meta(0x07, 0x04, 0x12, 3, "the Temple of Time", "Secret Above a Secret", 2, 274361, "303473"),
    "OoT Kakariko":     course_meta(0x07, 0x05, 0x12, 4, "the Kakariko Village and Graveyard", "Red Evils Over the Ruin", 5, 274360, "303472"),
    "OoT Valley":       course_meta(0x07, 0x06, 0x12, 5, "Gerudo Valley", "Should You Believe in Everything?", 4, 274362, "303474"),
    "OoT Well":         course_meta(0x07, 0x07, 0x12, 6, "the Bottom of the Well", "Fear of the Dark", 2, 274363, "303475"),
    
    "MNE OW2":          course_meta(0x16, 0x01, 0x11, 0, "the second overworld of Mario's New Earth", "Gum Under Your Shoe", 2, 274354, "303466"),
    "MNE Warp Zone":    course_meta(0x16, 0x02, 0x11, 1, "the warp zone of Mario's New Earth", "Boiled Veggies", 4, 274355, "303467"),
    "MNE Hallway":      course_meta(0x16, 0x03, 0x11, 2, "the hallway of Mario's New Earth", "You Won't Find Me!", 1, 274351, "303463"),
    "SR2.5 Warp Zone":  course_meta(0x16, 0x04, 0x11, 3, "the warp zone of Star Revenge 2.5", "Home Alone", 4, 274381, "303493"),
    
    "BSA OW2":          course_meta(0x08, 0x01, 0x10, 0, "the first overworld of Bloo Star Adventure", "Illusion Picture Room", 1, 274339, "303451"),
    "ASA OW1":          course_meta(0x08, 0x02, 0x10, 1, "the first overworld of All Star Adventure", "The Ways of the Water System", 3, 274338, "303450"),
    
    "TW OW1 galoomba":  course_meta(0x17, 0x01, 0x17, 0, "the first overworld of Super Mario Treasure World requeseted by galoomba", "Door-Knocking", 3, 274400, "303512"),
    "TW OW1 Zaol":      course_meta(0x17, 0x02, 0x17, 1, "the first overworld of Super Mario Treasure World requeseted by Zaoldieck", "Jealousy of 91", 3, 274401, "303513"),
    "TW OW2 Zaol":      course_meta(0x17, 0x03, 0x17, 2, "the second overworld of Super Mario Treasure World requeseted by Zaoldieck", "Inhabitant of the Sand Street", 4, 274405, "303517"),
    "TW OW2 Iwer":      course_meta(0x17, 0x04, 0x17, 3, "the second overworld of Super Mario Treasure World requeseted by Iwer Sonsch", "Watch for Rolling Balls in More Than 0.5 A Presses", 4, 274403, "303515"),
    "TW OW1 Blocky":    course_meta(0x17, 0x05, 0x17, 4, "the first overworld of Super Mario Treasure World requeseted by BlockyGamez", "A Sign's Revenge", 3, 274399, "303511"),
    "TW OW2 Blocky":    course_meta(0x17, 0x06, 0x17, 5, "the second overworld of Super Mario Treasure World requeseted by BlockyGamez", "Trust the Boxes of the Quicksand Sea?", 4, 274402, "303514"),
    "TW OW2 Tyler":     course_meta(0x17, 0x07, 0x17, 6, "the second overworld of Super Mario Treasure World requeseted by TylerSM64", "Chilly Lookout", 4, 274404, "303516"),
    
    // c10
    "KBR2 OW3 Morning": course_meta(0x0A, 0x01, 0x16, 0, "the third overworld of King Boo's Revenge 2 requested by MorningStorm", "The Boos Remain Unimpressed", 2, 274347, "303459"),
    "KBR2 OW3 WBM":     course_meta(0x0A, 0x02, 0x16, 1, "the third overworld of King Boo's Revenge 2 requested by WBM", "Unjustifiable Search", 3, 274348, "303460"),
    "KBR2 OW3 Baseball":course_meta(0x0A, 0x03, 0x16, 2, "the third overworld of King Boo's Revenge 2 requested by LuvBaseball58", "The Ambience's Truth", 2, 274346, "303458"),
    "KBR OW1":          course_meta(0x0A, 0x04, 0x16, 3, "the first overworld of King Boo's Revenge", "Are You Doing... Well... Today?", 3, 274341, "303453"),
    
    "SMSR OW1":         course_meta(0x0B, 0x01, 0x15, 0, "the first overworld of Super Mario Star Road", "The Chipped Grain II", 5, 274372, "303484"),
    
    "TTM OW1":          course_meta(0x24, 0x01, 0x14, 0, "the first overworld of Star Revenge 2: Act 1 - To the Moon", "Cross the Lava Lake", 1, 274397, "303509"),
    
    "TTM OW2":          course_meta(0x0D, 0x01, 0x1B, 0, "the second overworld of Star Revenge 2: Act 1 - To the Moon", "Planetary Plight", 3, 274398, "303510"),
    
    "VA OW1":           course_meta(0x0E, 0x01, 0x1A, 0, "the first overworld of Victory Ascent", "Cash That Star, How 'Bout That?", 4, 274408, "303520"),
    "SR5.5 OW Angry":   course_meta(0x0E, 0x02, 0x1A, 1, "the main overworld of Star Revenge 5.5 requested by Angry", "Narrow Paths of Fools", 5, 274384, "303496"),
    "SR5.5 OW Lily":    course_meta(0x0E, 0x03, 0x1A, 2, "the main overworld of Star Revenge 5.5 requested by SnowLily", "Find Nebby and Put it Back in the Bag", 3, 274385, "303497"),
    "SR5 OW1":          course_meta(0x0E, 0x04, 0x1A, 3, "the first overworld of Star Revenge 5", "Balance of Motion and Stillness", 3, 274383, "303495"),
    "SMA BK":           course_meta(0x0E, 0x05, 0x1A, 4, "Bowser's Kingdom from Super Mario Apocalypse", "In the Woods", 2, 274371, "303483"),
    "SMA Ante":         course_meta(0x0E, 0x06, 0x1A, 5, "the Ante-Apocalypse from Super Mario Apocalypse", "The Impossible Race?", 2, 274370, "303482"),
    
    "SMSR OW3":         course_meta(0x0F, 0x01, 0x19, 0, "the third overworld of Super Mario Star Road", "The Flying Stepping Stones", 5, 274373, "303485"),
    
    // Aquarium
    "SR7 OW1":          course_meta(0x14, 0x01, 0x20, 0, "the first overworld of Star Revenge 7", "Star in the Totally Realistic Holes", 3, 274386, "303498"),
    "SR7 OW2":          course_meta(0x14, 0x02, 0x20, 1, "the second overworld of Star Revenge 7", "Beneath the Gigant Isle", 1, 274387, "303499"),
    
    // Slide
    "SotB2 NICV":       course_meta(0x1B, 0x01, 0x1D, 0, "the New Ice Cream Vault of Stars of the Beast 2", "Lava", 3, 274375, "303487"),
    "SotB OW1":         course_meta(0x1B, 0x02, 0x1D, 1, "the first overworld of Stars of the Beast", "Into the Mountainside", 1, 274374, "303486"),
    
    // Cloud Stage - bookmark
    "SSB OW":           course_meta(0x1F, 0x01, 0x21, 0, "the overworld of Sunshine Secret Book 64", "Between the Two Sandfalls", 2, 274396, "303508"), // areas 2/3 also part of ssb
    "SS1r OW1":         course_meta(0x1F, 0x04, 0x21, 1, "the first overworld of Shining Stars Repainted", "Forest's Heart - Center of Attention", 1, 274394, "303506"),
    "SS1 OW1":          course_meta(0x1F, 0x05, 0x21, 2, "the first overworld of the original SM64: Shining Stars", "Remember Who You Are", 2, 274393, "303505"),
    
    // End Cake (need to check EEPROM)
    "TWDE OW1":         course_meta(0x19, 0x01, 0x27, 0, "the first overworld of Treasure World: Dream Edition", "Over the Wooden Planks", 4, 274406, "303518"),
    "TWDE OW2":         course_meta(0x19, 0x02, 0x27, 1, "the second overworld of Treasure World: Dream Edition", "Revolution of the Star", 4, 274407, "303519"),
    "VP OW2":           course_meta(0x19, 0x03, 0x27, 2, "the second overworld of Victory Plush", "A Cave Exploration", 2, 274409, "303521"),
    "Fantasy C1":       course_meta(0x19, 0x04, 0x27, 3, "Course 1 of Super Mario Fantasy", "The Bee's Treasure", 2, 274340, "303452"),
    
    // Castle Grounds
    "Spawn":            course_meta(0x10, 0x01, -1, -1, "the start of the journey"),
    "Wing Cap":         course_meta(0x10, 0x02, -1, -1, "the Wing Cap Switch"),
    "Metal Cap":        course_meta(0x10, 0x03, -1, -1, "the Metal Cap Switch"),
    "Vanish Cap":       course_meta(0x10, 0x04, -1, -1, "the Vanish Cap Switch"),
    
    // Inside Castle (check EEPROM)
    "PLUTO Iwer":       course_meta(0x06, 0x01, 0x0B, 0, "the overworld of Plutonium Mario 64 requested by Iwer Sonsch", "The Height of the Mountain", 1, 274364, "303476"),
    "PLUTO WBM":        course_meta(0x06, 0x02, 0x0B, 1, "the overworld of Plutonium Mario 64 requested by WBM", "Ztar's Fourer Capital", 2, 274365, "303477"),
    
    // Castle Courtyard
    "Servus OW1":       course_meta(0x1A, 0x01, 0x0B, 2, "the first overworld of Servus 64", "Upside Down Catastrophe", 4, 274367, "303479"),
    "SS3 OW1":          course_meta(0x1A, 0x02, 0x0B, 3, "the first overworld of Shining Stars 3", "Serene Structure in Dark Space", 2, 274395, "303507"),
    
    // Metal Cap
    "NoD OW1 Depsurrel":course_meta(0x1C, 0x01, 0x1C, 0, "the first overworld of Night of Doom requested by Depsurrel", "Lone Coastal Beachhome", 3, 274356, "303468"),
    "NoD OW1 WBM":      course_meta(0x1C, 0x02, 0x1C, 1, "the first overworld of Night of Doom requested by WBM", "Original Star Name - Do Not Steal", 3, 274358, "303470"),
    "NoD OW1 Katx":     course_meta(0x1C, 0x03, 0x1C, 2, "the first overworld of Night of Doom requested by Katx", "From Beyond the Infinite", 3, 274357, "303469"),
    
    // Wing Cap
    "SR4.5 C8":         course_meta(0x1D, 0x01, 0x23, 0, "Course 8 of Star Revenge 4.5", "Parallel Tragedy", 3, 274382, "303494"),
    
    // Vanish Cap
    "SR7.5 OW3":        course_meta(0x12, 0x01, 0x22, 0, "the third overworld of Star Revenge 7.5", "Tower", 3, 274390, "303502"),
    "SR7 OW3 Salty":    course_meta(0x12, 0x02, 0x22, 2, "the third overworld of Star Revenge 7 requested by SodiumChlorideLogic", "Deadly Domination", 3, 274389, "303501"),
    "SR7 OW3 Reverser": course_meta(0x12, 0x03, 0x22, 1, "the third overworld of Star Revenge 7 requested by TheReverserOfTime", "Perfect Maze Class", 3, 274388, "303500"),
    
    // B1
    "SR1.5 OW1 Iwer":   course_meta(0x11, 0x01, 0x18, 0, "the first overworld of Star Revenge 1.5 requested by Iwer Sonsch", "Somewhere in the Maze 18", 3, 274377, "303489"),
    "SR1.5 OW1 Blocky": course_meta(0x11, 0x02, 0x18, 1, "the first overworld of Star Revenge 1.5 requested by BlockyGamez", "Political Denoy Strategy", 1, 274376, "303488"),
    "LU1.5 C6":         course_meta(0x11, 0x03, 0x18, 2, "Course 6 of Lost Universe 1.5", "Dinner", 5, 274350, "303462"),
    
    // B2
    "SR1.5 OW2 Iwer":   course_meta(0x13, 0x01, 0x1F, 0, "the second overworld of Star Revenge 1.5 requested by Iwer Sonsch", "Railroad", 1, 274378, "303490"),
    "SR1.5 OW2 Squrly": course_meta(0x13, 0x02, 0x1F, 1, "the second overworld of Star Revenge 1.5 requested by MrSqurly", "Bon Lumps Voyage!", 1, 274379, "303491"),
    "PoE2 OW1":         course_meta(0x13, 0x03, 0x1F, 2, "the first overworld of Path of Eternity 2", "Small Path Over the Clouds", 3, 274366, "303478"),
    
    // B3
    "SR2.5 OW2":        course_meta(0x15, 0x01, 0x1E, 0, "the second overworld of Star Revenge 2.5", "Ice Block Fun!", 4, 274380, "303492"),
    
    // Key 1
    "Key 1":            course_meta(0x1E, 0x01, -1, -1, "the first key area"),
    
    // Key 2
    "Key 2":            course_meta(0x21, 0x01, -1, -1, "the second key area"),
    
    // Final
    "Final Fight":      course_meta(0x22, 0x01, -1, -1, "the ending area"), // reds does NOT count as a star
}

function in_intro_or_file_select() => any_of([0x21], a => music_id__mem == a) // TWDE OW2 uses 0x02

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

function in_sublevel(name) => sublevel_id__mem == course_infos[name]["sublevel value"]

function in_area(name, area=-1) {
    area_check = always_true()
    if (area != -1)
        area_check = sublevel_id__mem == area
    
    return level_id__mem == course_infos[name]["value"] && area_check
}

function in_same_level_from_last_frame() => level_id__mem == prev(level_id__mem) && sublevel_id__mem == prev(sublevel_id__mem)

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

function common_in_file_check() => !in_intro_or_file_select() && level_id__mem != 1 //&& g_current_demo_input__mem == 0

//
//  Cheevs
//

// da stars

possible_100c = ["KBR2 OW2", "OoT Fort", "OoT Kakariko", "OoT Well", "SR4.5 C8", "SR8 C7", "SR8 C10", "TW OW1 galoomba", "TW OW1 Zaol", "TW OW1 Blocky", "TW OW2 Zaol", "TW OW2 Iwer", "TW OW2 Blocky", "TW OW2 Tyler"]
for c in course_infos {
    info = course_infos[c]
    amend = ""
    if any_of(possible_100c, a => c == a) {
        amend = " (100 coin star doesn't count)"
    }
    if (info["star bit"]["valid"] == true)
    {
        if (any_of(["OoT Well", "TW OW2 Tyler"], a => c == a)) {
            achievement(
            title = info["title"],
            description = format("Collect the star in {0} (OK if already collected on file){1}.", info["full name"], amend),
            points = info["points"],
            trigger = in_level(c) && collecting_star_object("regular star", 6),
            id = info["id"],
            badge = info["badge"]
            )
        }
        else  {
            achievement(
            title = info["title"],
            description = format("Collect the star in {0}{1}.", info["full name"], amend),
            points = info["points"],
            trigger = in_level(c) && just_increased(info["star bit"]["mem"]),
            id = info["id"],
            badge = info["badge"]
            )
        }
    }
}

// switches / keys / endings / cannons
function file_bitflag_def(mem, title, description, id=0, badge="0") => {"mem": mem, "title": title, "description": description, "id": id, "badge": badge}
file_bitflags = {
    "Wing Cap":     file_bitflag_def(pressed_switch__mem("red"), "Cap of Many Skips", "Press the red !-switch.", 274414, "303526"),
    "Metal Cap":    file_bitflag_def(pressed_switch__mem("green"), "Cap That's Often Skipped", "Press the green !-switch.", 274412, "303524"),
    "Vanish Cap":   file_bitflag_def(pressed_switch__mem("blue"), "Cap of Invisible Skips", "Press the blue !-switch.", 274413, "303525"),
    "Key 1":        file_bitflag_def(pressed_switch__mem("key 1 strict"), "Kedama Key", "Obtain Key 1.", 274410, "303522"),
    "Key 2":        file_bitflag_def(pressed_switch__mem("key 2 strict"), "The Ice Cream's Treasure", "Obtain Key 2.", 274411, "303523")
}

for f in file_bitflags {
    info = file_bitflags[f]
    achievement(
        title = info["title"],
        description = info["description"],
        points = 3,
        trigger = in_level(f) && just_increased(info["mem"]),
        id = info["id"],
        badge = info["badge"]
    )
}

achievement(
    title = "Stopped Clock",
    description = "Collect the ending 'star' (does not count towards total).",
    points = 10,
    trigger = in_level("Final Fight") && collecting_star_object("spawned star"),
    id = 274415,
    badge = "303527"
)

cannon_bits = sum_cannon_bits([0x0d, 0x15, 0x13])
star_collection_achievement(
    stars=[cannon_bits], total=3,
    title = "Inter-Hack Cannoneer",
    description = "Open all 3 cannons.",
    points = 3,
    id = 274416,
    badge = "303528"
)

// 100s
function coin_collect_def(count, title, description, points, level_check, id=0, badge="0") => {"count": count, "title": title, "description": description, "points": points, "level check": level_check, "id": id, "badge": badge}
coin_collects = [
    coin_collect_def(100, "Gather the Spreaded Love", "Collect 100 coins in the second overworld of King Boo's Revenge 2 (star).", 5, in_level("KBR2 OW2"), 274417, "303529"),
    coin_collect_def(100, "Dawn of a Forsaken Reality", "Collect 100 coins in Course 6 of Lost Universe 1.5 (no star).", 5, in_level("LU1.5 C6"), 274418, "303530"),
    coin_collect_def(100, "Freshly Produced Coins", "Collect 100 coins in Ocarina of Time (Kakariko Village only) (shared star).", 5, in_level("OoT Kakariko"), 274419, "303531"),
    coin_collect_def(100, "Above Everything", "Collect 100 coins in Ocarina of Time (Gerudo Fortess only) (shared star).", 10, in_level("OoT Fort"), 274420, "303532"),
    coin_collect_def(100, "Investigating the Pipelines", "Collect 100 coins in Ocarina of Time (Bottom of Well only) (shared star).", 5, in_level("OoT Well"), 274421, "303533"),
    coin_collect_def(100, "Raining Blood", "Collect 100 coins in Course 8 of Star Revenge 4.5 (star).", 5, in_level("SR4.5 C8"), 274422, "303534"),
    coin_collect_def(100, "Spinning Fruits in Forest Town", "Collect 100 coins in Course 7 of Star Revenge 8 (star).", 10, in_level("SR8 C7"), 274423, "303535"),
    coin_collect_def(100, "Maximal Value of the Galaxy", "Collect 100 coins in Course 10 of Star Revenge 8 (star).", 5, in_level("SR8 C10"), 274424, "303536"),
    coin_collect_def(100, "A Bomb of Light", "Collect 100 coins in Course 1 of Super Mario Fantasy (no star).", 5, in_level("Fantasy C1"), 274425, "303537"),
    coin_collect_def(100, "The Edge of Possibility", "Collect 100 coins in the first overworld of Super Mario Treasure World (shared star).", 10, any_of(["TW OW1 galoomba", "TW OW1 Zaol", "TW OW1 Blocky"], a => in_level(a)), 274426, "303538"),
    coin_collect_def(100, "Touching the Heavens", "Collect 100 coins in the second overworld of Super Mario Treasure World (shared star).", 10, any_of(["TW OW2 Zaol", "TW OW2 Iwer", "TW OW2 Blocky", "TW OW2 Tyler"], a => in_level(a)), 274427, "303539"),
    coin_collect_def(120, "Challenging Gold Nuggets", "Collect 120 coins in the first overworld of Treasure World Dream Edition (no star).", 25, in_level("TWDE OW1"), 274428, "303540"),
    coin_collect_def(120, "Pharaoh Eddie's Treasure", "Collect 120 coins in the second overworld of Treasure World Dream Edition (no star).", 25, in_level("TWDE OW2"), 274429, "303541"),
]

for c in coin_collects {
    achievement(
        title = c["title"],
        description = c["description"],
        points = c["points"],
        trigger = (prev(coin_display()) == c["count"] - 1) && measured(coin_display() == c["count"], when=c["level check"])
    )
}

achievement(
    title = "Would've Been Lowest Percent",
    description = "Starting from a new file, without collecting any stars, press all 3 cap switches, collect both keys, and reach the ending area (indicator at 1/5).",
    points = 10,
    trigger = once(in_area("Spawn", 0) && never(just_changed_to(music_id__mem, 0x21)) && pressed_switch__mem("valid game") == 0) && nof_stars() == 0 && sum_of(["red", "green", "blue", "key 1", "key 2"], a => pressed_switch__mem(a)) >= 1 && (trigger_when(in_level("Final Fight") && sum_of(["red", "green", "blue", "key 1", "key 2"], a => pressed_switch__mem(a)) == 5) || (in_level("Final Fight") && measured(sum_of(["red", "green", "blue", "key 1", "key 2"], a => pressed_switch__mem(a)) == 5, when=!in_intro_or_file_select() && nof_stars() == 0))),
    id=274430,
    badge="303542"
)

// Misc.
achievement(
    title = "Secret of Space",
    description = "Collect the star in the second overworld of Mario's New Earth while still wearing your vanish cap (OK if star already got on file).",
    points = 2,
    trigger = in_level("MNE OW2")
        && prev(wearing_vanish_cap()) != 0
        && trigger_when(collecting_star_object("regular star", 0)),
    id=274431,
    badge="303543"
)

function object_box_broken(addr) => object_is(addr, "exclamation box")
    && object_active(addr) != 0
    //&& object_subtype(addr) > 2 // non respawnable type
    && just_changed_to(object_action(addr), 3)

achievement(
    title = "Cap Crisis",
    description = "In Course 7 of Star Revenge 8, stand on the former wing cap box that became a vanish cap box in this hack.",
    points = 1,
    trigger = in_level("SR8 C7")
        && in_3d_box(-3000.0, -4000.0, 400.0, 1000.0, -20000.0, -22000.0)
        && object_is(stood_on_object(), "exclamation box"),
    id=274432,
    badge="303544"
)

// RP

stars__value = rich_presence_value("Number", nof_stars())

meta_descriptions = {
    0x00: "Starting up the game",
    //0x02: "Playing with Mario head",
    0x21: "In File Select",
}

general_level_dict = {
    //0x10:
    //0x06: "Plutonium Mario 64",
    //0x1a:
    
    //0x09: "King Boo's Revenge 2",
    0x18: "Super Mario 74",
    0x0C: "Star Revenge 8",
    0x05: "Star Revenge 8",
    0x04: "Lost Lunatic Trials",
    //0x07: 
    //0x16: 
    //0x08:
    //0x17: "Super Mario Treasure World",
    //0x0a: 
    0x0b: "Super Mario Star Road",
    0x24: "Star Revenge 2: Act 1 - To the Moon",
    0x0d: "Star Revenge 2: Act 1 - To the Moon",
    //0x0e: 
    0x0f: "Super Mario Star Road",
    
    //0x1c: "Night of Doom",
    0x1d: "Star Revemge 4.5",
    //0x12:

    //0x1b:
    0x14: "Star Revenge 7",
    //0x1f:
    
    //0x11:
    //0x1e: 
    //0x13: 
    //0x21:
    0x15: "Star Revenge 2.5",
    //0x22:
}

fight_levels = {
    0x1e: "near Key 1",
    0x21: "near Key 2",
    0x22: "at the ending"
}

level__lookup = rich_presence_lookup("LevelsWithoutSublevels", level_id__mem, general_level_dict, "in an unbeknownst location")
fight_level__lookup = rich_presence_lookup("LevelFights", level_id__mem, fight_levels, "in an unbeknownst location")

stars__value = rich_presence_value("Number", nof_stars())

file__lookup  = rich_presence_lookup("File", file_num__mem, {
    0x01: "A", 0x02: "B", 0x03: "C", 0x04: "D"
}, "??")

level_09__lookup = rich_presence_lookup("Level09", sublevel_id__mem,{
    0x01: "King Boo's Revenge 2 (OW1 Pluto)",
    0x02: "King Boo's Revenge 2 (OW1 Morning)",
    0x03: "King Boo's Revenge 2 (OW1 Iwer)",
    0x04: "King Boo's Revenge 2 (OW2)",
})

level_07__lookup = rich_presence_lookup("Level07", sublevel_id__mem,{
    0x01: "Mario's New Earth (OW1 ARP)",
    0x02: "Mario's New Earth (OW1 Hokkanen)",
    0x03: "Ocarina of Time",
    0x04: "Ocarina of Time",
    0x05: "Ocarina of Time",
    0x06: "Ocarina of Time",
    0x07: "Ocarina of Time",
})

level_16__lookup = rich_presence_lookup("Level16", sublevel_id__mem,{
    0x01: "Mario's New Earth",
    0x02: "Mario's New Earth",
    0x03: "Mario's New Earth",
    0x04: "Star Revenge 2.5",
})

level_08__lookup = rich_presence_lookup("Level08", sublevel_id__mem,{
    0x01: "Bloo Star Adventure",
    0x02: "All Star Adventure",
})

level_17__lookup = rich_presence_lookup("Level17", sublevel_id__mem,{
    0x01: "Super Mario Treasure World (OW1 galoomba)",
    0x02: "Super Mario Treasure World (OW1 Zaoldieck)",
    0x03: "Super Mario Treasure World (OW2 Zaoldieck)",
    0x04: "Super Mario Treasure World (OW2 Iwer)",
    0x05: "Super Mario Treasure World (OW1 Blocky)",
    0x06: "Super Mario Treasure World (OW2 Blocky)",
    0x07: "Super Mario Treasure World (OW2 Tyler)",
})

level_0a__lookup = rich_presence_lookup("Level0a", sublevel_id__mem,{
    0x01: "King Boo's Revenge 2 (OW3 Morning)",
    0x02: "King Boo's Revenge 2 (OW3 WBM)",
    0x03: "King Boo's Revenge 2 (OW3 Baseball)",
    0x04: "King Boo's Revenge",
})

level_0e__lookup = rich_presence_lookup("Level0e", sublevel_id__mem,{
    0x01: "Victory Ascent",
    0x02: "Star Revenge 5.5 (Angry)",
    0x03: "Star Revenge 5.5 (SnowLily)",
    0x04: "Star Revenge 5",
    0x05: "Super Mario Apocalypse",
    0x06: "Super Mario Apocalypse",
})

level_1c__lookup = rich_presence_lookup("Level1c", sublevel_id__mem,{
    0x01: "Night of Doom (OW1 Depsurrel)",
    0x02: "Night of Doom (OW1 WBM)",
    0x03: "Night of Doom (OW1 Katx)",
})

level_1b__lookup = rich_presence_lookup("Level1b", sublevel_id__mem,{
    0x01: "Stars of the Beast 2",
    0x02: "Stars of the Beast",
})

level_1f__lookup = rich_presence_lookup("Level1f", sublevel_id__mem,{
    0x01: "Sunshine Secret Book",
    0x04: "Shining Stars Repainted",
    0x05: "Shining Stars 1",
})

level_19__lookup = rich_presence_lookup("Level19", sublevel_id__mem,{
    0x01: "Treasure World Dream Edition",
    0x02: "Treasure World Dream Edition",
    0x03: "Victory Plush",
    0x04: "Super Mario Fantasy",
})

level_1a__lookup = rich_presence_lookup("Level1a", sublevel_id__mem,{
    0x01: "Servus 64",
    0x02: "Shining Stars 3",
})

level_06__lookup = rich_presence_lookup("Level06", sublevel_id__mem,{
    0x01: "Plutonium Mario 64 (Iwer)",
    0x02: "Plutonium Mario 64 (WBM)",
})

level_12__lookup = rich_presence_lookup("Level12", sublevel_id__mem,{
    0x01: "Star Revenge 7.5",
    0x02: "Star Revenge 7 (OW3 Salty)",
    0x03: "Star Revenge 7 (OW3 Reverser)",
})

level_11__lookup = rich_presence_lookup("Level11", sublevel_id__mem,{
    0x01: "Star Revenge 1.5 (OW1 Iwer)",
    0x02: "Star Revenge 1.5 (OW1 Blocky)",
    0x03: "Lost Universe 1.5",
})

level_13__lookup = rich_presence_lookup("Level13", sublevel_id__mem,{
    0x01: "Star Revenge 1.5 (OW2 Iwer)",
    0x02: "Star Revenge 1.5 (OW2 Squrly)",
    0x03: "Path of Eternity 2",
})

level_10__lookup = rich_presence_lookup("Level10", sublevel_id__mem,{
    0x00: "in the spawn area",
    0x01: "in the spawn area",
    0x02: "near the red !-switch",
    0x03: "near the green !-switch",
    0x04: "near the blue !-switch",
})

function rp_cond_same_display(cond, lookup, verb_phrase) {
    rich_presence_conditional_display(cond, 
    "Mario-{2} {6}{0} with {1}⭐ [🔴{3}] [🟢{4}] [🔵{5}] [🔑1{7}] [🔑2{8}]", lookup, stars__value, file__lookup, 
        rich_presence_lookup("Switch", pressed_switch__mem("red"), {1:"▣"}, "▢"),
        rich_presence_lookup("Switch", pressed_switch__mem("green"), {1:"▣"}, "▢"),
        rich_presence_lookup("Switch", pressed_switch__mem("blue"), {1:"▣"}, "▢"),
        verb_phrase,
        rich_presence_lookup("Switch", pressed_switch__mem("key 1"), {1:"▣"}, "▢"),
        rich_presence_lookup("Switch", pressed_switch__mem("key 2"), {1:"▣"}, "▢")
    )
}

cond_displays = {
    "general": {"cond": mem_in(level_id__mem, general_level_dict), "lookup": level__lookup},
    "level06": {"cond": (level_id__mem == 0x06), "lookup": level_06__lookup},
    "level1a": {"cond": (level_id__mem == 0x1a), "lookup": level_1a__lookup},
    
    "level09": {"cond": (level_id__mem == 0x09), "lookup": level_09__lookup},
    "level07": {"cond": (level_id__mem == 0x07), "lookup": level_07__lookup},
    "level16": {"cond": (level_id__mem == 0x16), "lookup": level_16__lookup},
    "level08": {"cond": (level_id__mem == 0x08), "lookup": level_08__lookup},
    "level17": {"cond": (level_id__mem == 0x17), "lookup": level_17__lookup},
    "level0a": {"cond": (level_id__mem == 0x0a), "lookup": level_0a__lookup},
    "level0e": {"cond": (level_id__mem == 0x0e), "lookup": level_0e__lookup},
    "level1c": {"cond": (level_id__mem == 0x1c), "lookup": level_1c__lookup},
    "level12": {"cond": (level_id__mem == 0x12), "lookup": level_12__lookup},
    "level1b": {"cond": (level_id__mem == 0x1b), "lookup": level_1b__lookup},
    "level1f": {"cond": (level_id__mem == 0x1f), "lookup": level_1f__lookup},
    "level19": {"cond": (level_id__mem == 0x19), "lookup": level_19__lookup},
    
    "level11": {"cond": (level_id__mem == 0x11), "lookup": level_11__lookup},
    "level13": {"cond": (level_id__mem == 0x13), "lookup": level_13__lookup},
}

special_displays = {
    "fights": {"cond": mem_in(level_id__mem, fight_levels),
    "lookup": fight_level__lookup},
    "castle": {"cond": (level_id__mem == 0x10), "lookup":
    level_10__lookup},
}

rich_presence_conditional_display(in_intro_or_file_select() || level_id__mem == 1, "{0}", rich_presence_lookup("Fileless", music_id__mem, meta_descriptions))
//rich_presence_conditional_display(in_level("TWDE OW2"), "HEY!")
for k in cond_displays {
    rp_cond_same_display(cond_displays[k]["cond"], cond_displays[k]["lookup"], "is getting lost in ")
}
for s in special_displays {
    rp_cond_same_display(special_displays[s]["cond"], special_displays[s]["lookup"], "is ")
}
rich_presence_display("Traveling through many dimensions in search for stars.")