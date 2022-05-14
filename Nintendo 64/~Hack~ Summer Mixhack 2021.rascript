// ~Hack~ Summer Mixhack 2021
// #ID = 19565
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

offsets = {
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
    "impartial 1-up":   0x800EF13C,
    "stationary 1-up":  0x800EF1DC, // was 1FC
    "chasing 1-up":     0x800EF2A8, // was 2C8
    
    "target controller":0x800F086C,
    
    "blue warp block":  0x800F0998,
    
    "bowser phase 2":   0x800F0A58,
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
    "Castle Grounds": {"Blue Warp Blocks": [52, 49, 46, 43, 40, 37]},
    "Aquarium": {"Target Controller": 26}
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
    "Castle Grounds":   course_meta(0x10, [-1],   "The Overworld"), // Castle Grounds
    
    "Course 1":         course_meta(0x09, [-1],   "Vicky's Onsen 64"),
    "Course 2":         course_meta(0x18, [-1],   "Garbage Garage"), // 2 areas
    
    "Course 3":         course_meta(0x0c, [-1],   "Valley of the Winter Runner"),
        // Area 2 - winter runner jail
        // Area 3 - garden
        // Area 4 - upwards temple
        // Area 5 - bully battle
    
    "Course 4":         course_meta(0x05, [-1],   "Sand Bird Sanctuary"),
        // Area 2 - eyerok fight
        // Area 3 - sand bird
        // Area 4 - same as area 1, but with egg hatched
        // Area 5 - cliff side cave (without Klepto)
        // Area 6 - cliff side cave (with Klepto)
        // Area 7 - blocked off cave

    "Slide":            course_meta(0x1b, [-1],   "Secret Area"),
    "Aquarium":         course_meta(0x14, [-1],   "Break the Targets"),
    
    "Bowser 1":         course_meta(0x11, [-1],   "Bowser's Covenance"),
    "Key 1":            course_meta(0x1e, [-1],   "Bowser's Covenance"),

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
    milestone_meta("Finished the Summer Collab",
        "Collect all 28 stars.",
        stars=28, points=10)
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
    title="Rode Off Into the Sunset",
    description="Defeat Bowser and reach the ending screen.",
    points= 5 ,
    trigger= once(!in_level("End Cake Picture", delta=1))
        && repeated(300, in_level("End Cake Picture")) // some timing so the screenshot happens when the dorrie pic is fully faded in
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
    "Course 1":  course_stars_meta(sum_star_bits(0x0f, range(0, 5)), 5, "Stars by the Pool", id=218452, badge="241783"),
    "Course 2":  course_stars_meta(sum_star_bits(0x0e, range(0, 5)), 5, "Locked Outside", id=218453, badge="241784"),
    "Course 3":  course_stars_meta(sum_star_bits(0x0d, range(0, 6)), 10, "Upwards Journey Complete", id=218454, badge="241785"),
    "Course 4":  course_stars_meta(sum_star_bits(0x0c, range(0, 6)), 10, "Finally Hatched the Egg", id=218455, badge="241786"),
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
            
            if (obj_name == "chasing 1-up")
                coll_check = coll_check && object_action(obj_addr) == 1

            array_push(mushie_tally,
                repeated(t["count"], coll_check))   
        }
    }
    return tally(total_count, mushie_tally)
}

function mushies_meta(title="", points=0, tallies=[], numbered_course=1, id=0, badge="0") => {"title": title, "points": points, "tallies": tallies, "is numbered course": numbered_course, "id": id, "badge": badge}

mushies_data = {
    "Course 1": mushies_meta("Lifesaver Onsen", 2,
        [{"type": "stationary", "count": 2}], id=218456, badge="241791"),
    "Course 3": mushies_meta("Lifesaver Valley", 3, 
        [{"type": "stationary", "count": 3},], id=218456, badge="241787"),
    "Course 4": mushies_meta("Lifesaver Sanctuary", 5, 
        [{"type": "stationary", "count": 4}, 
         {"type": "chasing", "count": 1},
         {"type": "impartial", "count": 1}], id=218457, badge="241788"),
}

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
        mushie_qty_string = format("{0} without leaving", mushie_qty_string)
        collect_cond = measured(mushie_tally)
    }
        
    description_append = ""
    
    if (course == "Course 1")
        description_append = " Stand still on them to warp."
    if (course == "Course 4")
        description_append = " (missions 3-6 only, see comment)"

    //if (course == "Course 4")
    //    description_append = ", missions 2-6 only"
    //if (course == "Course 5")
    //    description_append = ", missions 4-6 only"
    //if (course == "Overworld")
    //    description_append = ", dying allowed"
    
    course_name = ""
    if (info["is numbered course"] != 0)
        course_name = course
    else
        course_name = course_infos[course]["full name"]
    
    description = format("{0} - collect {1}.{2}", course_name, mushie_qty_string, description_append)
    
    achievement(
        title = mushies_data[course]["title"],
        description = description,
        points = info["points"],
        trigger = never(!in_level(course))
            && collect_cond
    )
}

// Challenges

//

blocks = object_indexes["Castle Grounds"]["Blue Warp Blocks"]

stood_on_warp_boxes_array = array_map(blocks, i =>
            once(
                object_is(stood_on_object(), "blue warp block")
                && array_object_index_is(stood_on_object(), i)
                )
            )

achievement(
    title = "Overworld Box Jumps",
    description = "Stand on all six blue !-boxes in the overworld without touching the ground or entering another level.",
    points = 3,
    trigger = never(!in_level("Castle Grounds"))
        &&  tally(1, stood_on_warp_boxes_array)
        &&  never(pos_y() < 200.0 && !airborne())
        && (
            measured(tally(6, stood_on_warp_boxes_array))
            || trigger_when(tally(6, stood_on_warp_boxes_array))
            ),
    id = 218458, badge="241789"
)

achievement(
    title = "Flying for Fun",
    description = "Course 3, Mission 5 or 6 - Fly from the garden in the sky and land on top of the bully's tower. Read some mission-specific text while you're at it, too...",
    points = 2,
    trigger = never(!in_level("Course 3"))
        && never(sublevel_id__mem != 3)
        && once(wearing_wing_cap() == 1)
        && trigger_when(!airborne()
            && pos_x() > -16000.0
            && pos_x() < -10000.0),
    id = 218459, badge="241790"
)

achievement(
    title = "No Gliding Needed",
    description = "Course 4 - Collect the star 'Rush and Glide to Five Tall Secrets' without picking up a wing cap.",
    points = 5,
    trigger = remained_in_level("Course 4")
        && once(sublevel_id__mem == 1 && mario_action_is("airborne spawn"))
        && sublevel_id__mem == 1
        && !transition_active()
        && transition_type__mem != 1 // hack
        && never(wearing_wing_cap() == 1)
        && just_collected_star(star_index = 4, trigger = 1),
    id = 218461, badge = "241792"
)

achievement(
    title = "Yet Another Bowser Fight",
    description = "Defeat Bowser without taking damage or using the A button.",
    points = 10,
    trigger = never(!in_level("Key 1"))
        && once(prev(dialog_id__mem) == 0x43
        && dialog_id__mem != 0x43)
        && never(just_took_damage())
        && never(controller_a_button() != 0)
        && trigger_when(
                (object_num_collided_objects(mario_object()) > 0
                && object_is(object_nth_collided_object(mario_object(), 1), "bowser phase 2")
                && object_health(object_nth_collided_object(mario_object(), 1)) == 0)
                || dialog_id__mem == 0x79
            ),
    id = 218462, badge="241793"
)
target_ctrl = nth_array_object(object_indexes["Aquarium"]["Target Controller"])
target_finished = object_is(target_ctrl, "target controller")
    && prev(object_action(target_ctrl)) == 0
    && object_action(target_ctrl) == 1

achievement(
    title = "Simple Target Speedrun",
    description = "Break all the targets in under 30 seconds.",
    points = 5,
    trigger = never(!in_level("Aquarium"))
        && once(in_level("Castle Grounds", delta=1))
        && never(repeated(int_seconds_to_frames(30) * 2, in_level("Aquarium")))
        && trigger_when(target_finished),
    id = 218463, badge = "241794"
)

leaderboard(
    title = "Break the Targets!",
    description = "Spawn the star as fast as possible",
    start = in_level("Aquarium") && in_level("Castle Grounds", delta=1),
    cancel = !in_level("Aquarium"),
    submit = target_finished,
    value = measured(in_level("Aquarium")),
    
    lower_is_better = true,
    format = "FRAMES"
)

// RP

stars__value = rich_presence_value("Number", nof_stars())

meta_descriptions = {
    0x00: "Starting up the game",
    0x21: "In File Select",
}

course_infos = {
    "Castle Grounds":   course_meta(0x10, [-1],   "The Overworld"), // Castle Grounds
    
    "Course 1":         course_meta(0x09, [-1],   "Vicky's Onsen 64"),
    "Course 2":         course_meta(0x18, [-1],   "Garbage Garage"), // 2 areas
    
    "Course 3":         course_meta(0x0c, [-1],   "Valley of the Winter Runner"),
        // Area 2 - winter runner jail
        // Area 3 - garden
        // Area 4 - upwards temple
        // Area 5 - bully battle
    
    "Course 4":         course_meta(0x05, [-1],   "Sand Bird Sanctuary"),
        // Area 2 - eyerok fight
        // Area 3 - sand bird
        // Area 4 - same as area 1, but with egg hatched
        // Area 5 - cliff side cave (without Klepto)
        // Area 6 - cliff side cave (with Klepto)
        // Area 7 - blocked off cave

    "Slide":            course_meta(0x1b, [-1],   "Secret Area"),
    "Aquarium":         course_meta(0x14, [-1],   "Break the Targets"),
    
    "Bowser 1":         course_meta(0x11, [-1],   "Bowser's Covenance"),
    "Key 1":            course_meta(0x1e, [-1],   "Bowser's Covenance"),

    "End Cake Picture": course_meta(0x19, [-1], "The End")
}

general_level_dict = {
    0x10: "exploring the looping overworld",
    
    0x09: "visiting Vicky's onsen",
    0x18: "outside gmd's Garbage Garage",
    0x0C: "in a valley with the Winter Runner",
    0x05: "helping some buddies in Sand Bird Sanctuary",

    0x1b: "in a secret area (well done!)",
    0x14: "on a mission to break targets",
    
    0x11: "platforming in Bowser's Covenance",
    0x1e: "taking on Bowser",

    0x19: "at the ending screen",
}

level__lookup = rich_presence_lookup("LevelsWithoutSublevels", level_id__mem, general_level_dict, "in an unbeknownst location")

rich_presence_conditional_display(in_title_or_file_select(), 
    "{0}", rich_presence_lookup("Fileless", music_id__mem, meta_descriptions))
rich_presence_conditional_display(
    mem_in(level_id__mem, general_level_dict),
    "Mario is {0} with {1}⭐ [🔴{2}]", level__lookup, stars__value,
        rich_presence_lookup("Switch", pressed_switch__mem("red"), {1:"▣"}, "▢")
)
rich_presence_display("Having some summer fun in this collab hack.")