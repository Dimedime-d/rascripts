// ~Hack~ Another Boss Battle Test
// #ID = 18973
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
    
    "LEVEL INDEX":      0x33bac6,
    "SUBMAP ID":        0x33b249,
    
    "HUD FLAGS":        0x33b268,   //  https://github.com/n64decomp/sm64/blob/1372ae1bb7cbedc03df366393188f4f05dcfc422/src/game/level_update.h#L91
    
    "MARIO STRUCT":     0x33b170,
    "OBJECT ARRAY":     0x33d488,
}

behaviour_script__values = { 
    "stationary star": 0x80121C3C,
    "spawned star":    0x80121C64,
    "nighttime switch":0x804080E0,
    "boss controller": 0x8040811C,
    "tech demo switch":0x8040817C,
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
    "mario object":       0x88,  // dword (pointer to object)
    "controller":         0x9c,  // dword (pointer to controller struct)
    "nof stars":          0xa8,  // word, NOT HUD
    "nof coins":          0xaa,  // word
    "hp":                 0xac,  // byte / word
    "hp increment":       0xb0,  // byte
    "hp decrement":       0xb1,  // byte
    "cap timer":          0xb4,  // word
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

function interaction_object() => tbyte(mario_field("interaction object"))
function held_object() => tbyte(mario_field("held object"))
function used_object()  => tbyte(mario_field("used object"))
function mario_object() => tbyte(mario_field("mario object"))
function stood_on_object() => tbyte(stood_on_object__addr)

function controller() => tbyte(mario_field("controller"))

function controller_a_button() => bit(15, controller() + 0x12)

function hp_int() => byte(mario_field("hp") + 1)

function just_took_damage() => prev(hp()) > hp() // no regard for water damage...

function hp() => word(mario_field("hp"))

function hp_increment() => byte(mario_field("hp increment"))
function hp_decrement() => byte(mario_field("hp decrement"))

function cap_time() => word(mario_field("cap timer"))

function nof_stars() => word(mario_field("nof stars"))
function nof_coins() => word(mario_field("nof coins"))

function mario_current_action() => dword(mario_field("current action"))
function mario_previous_action() => dword(mario_field("previous action"))

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
    
    "ground pound landing":        0x0080023C,
    "lava boost":                  0x010208B7,
    "slide kick":                  0x018008AA,
    "air kick":                    0x018008AC,
    "air sitting":                 0x0300088E,
}

function mario_action_is(name) => mario_current_action() == mario_action__values[name]
function mario_prev_action_is(name) => mario_previous_action() == mario_action__values[name]

function mario_action_changed_to(name) {
    return prev(mario_current_action()) != mario_action__values[name]
        && mario_current_action() == mario_action__values[name]
}

star_grab_actions = ["star dance ground (exit)", "star dance water", "star dance ground (no exit)", "star grab fall"]

function airborne() => bit3(mario_action__addr + 1) != 0
function on_pole() => bit4(mario_action__addr + 2) != 0

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
    "hp":                   0x184,  // dword
    "star mission":         0x18b,  // byte (actually 0x188, but weirdness...)
    "behaviour script":     0x20c,  // dword
}
object__sizeof = 0x260

function object_field(base, field) => struct_field(object__struct, base, field)

function object_graph_invisible(addr) => bit4(object_field(addr, "graph node flags"))
function object_graph_animation_active(addr) => bit5(object_field(addr, "graph node flags"))

function object_active(addr) => bit(0, object_field(addr, "active"))
function object_just_deactivated(addr) => object_was_active(addr) && !object_active(addr)

function object_behav_script(addr) => dword(object_field(addr, "behaviour script"))
function object_is(addr, name) => object_behav_script(addr) == behaviour_script__values[name]

function object_num_collided_objects(addr) => word(object_field(addr, "num collided objects"))
function object_nth_collided_object(addr, n) => tbyte(object_field(addr, format("collided object {0}", n)))

function object_boo_death_status(addr) => dword(object_field(addr, "boo death status"))

function object_anim(addr) => word(object_field(addr, "animation"))
function object_action(addr) => dword(object_field(addr, "action"))

OBJ_ACTION_LAVA_DEATH = 100

function object_beh_param_2(addr) => dword(object_field(addr, "behavior param 2"))

function object_timer(addr) => dword(object_field(addr, "timer"))

// object specific

function object_is_boo_that_died(addr) => object_is(addr, "ghost hunt boo") && prev(object_boo_death_status(addr)) == 0 && object_boo_death_status(addr) == 1

function object_star_mission(addr) => byte(object_field(addr, "star mission"))

// Mario Object specific stuff

// watch out for animation value collisions (ex: airborne spawn and falling out of water both use general fall, 0x56)
mario_anim__values = {
    "Water Star Dance": 0xB3, //https://github.com/n64decomp/sm64/blob/1372ae1bb7cbedc03df366393188f4f05dcfc422/include/mario_animation_ids.h#L186
    "Star Dance":       0xCD,
    "Breakdance Kick": 0x71,
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

// --------------------------- //
//   o b j e c t   a r r a y   //
// --------------------------- //

object_array__addr = offsets["OBJECT ARRAY"]

function nth_array_object(index) => object_array__addr + (index * object__sizeof)

function array_object_index_is(obj_addr, index) => ((obj_addr - object_array__addr) / object__sizeof) == index

function array_object_is_active(index) => object_is_active(nth_array_object(index))
function array_object_was_active(index) => object_was_active(nth_array_object(index))
function array_object_just_deactivated(index) => array_object_was_active(index) && !array_object_is_active(index)

function array_object_is(index, name) => object_is(nth_array_object(index), name)

function array_object_num_collided_objects(index)   => object_num_collided_objects(nth_array_object(index))
function array_object_nth_collided_object(index, n) => object_nth_collided_object(nth_array_object(index), n)

function array_object_action(index) => object_action(nth_array_object(index))

function array_object_bowser_hp(index) => object_bowser_hp(nth_array_object(index))

object_indexes = { // try to only use this as a fallback, as this can change between updates...
    "Course 1":     {"Nighttime Switch": 41},
    "Bowser Fight": {"Boss Controller": 1}
}

hud_flags__addr = offsets["HUD FLAGS"]

function hud_stars_shown() => bit2(hud_flags__addr)

file_num__addr = offsets["FILE ID"]
file_num__mem = byte(file_num__addr)

save_data_base__addr = offsets["SAVE DATA"]
current_file__addr = save_data_base__addr + 0x70 * file_num__mem

// normal stars = 1-6; 100 coin star = 7
last_star__addr = offsets["COLLECTED STAR ID"]
last_star__mem = byte(last_star__addr)

sublevel_id__addr = offsets["SUBMAP ID"]
sublevel_id__mem  = byte(sublevel_id__addr)

level_id__addr = offsets["MAP ID"]
level_id__mem = byte(level_id__addr)

level_index__addr = offsets["LEVEL INDEX"]
level_index__mem = byte(level_index__addr)

music_id__mem  = byte(offsets["MUSIC ID"])

used_save_state__mem = byte(0x40d40f) // no other hack seems to use this, so it's fine to hard-code this in

function course_meta(value, sublevel_values, full_name, entrance_action) => {"value": value, "sublevel values": sublevel_values, "full name": full_name, "entrance action": entrance_action}

course_infos = {
    "Hub":              course_meta(0x10, [1],   "The hub", "none"), // Castle Grounds
    "Firsty Cap Switch":    course_meta(0x10, [4],   "The Firsty Cap Switch Room", "warp door spawn"),
    "Burn Cap Switch":      course_meta(0x10, [3],   "The Burn Cap Switch Room", "warp door spawn"),
    "Quicksand Cap Switch": course_meta(0x10, [2],   "The Quicksand Cap Switch Room", "warp door spawn"),
    
    "Course 1":         course_meta(0x09, [-1],   "After the Storm", "airborne spawn"),
    "Bowser Fight":     course_meta(0x18, [-1],   "Bowser Fight", "spawn spin landing"), // c2
    "Any% End":         course_meta(0x0c, [-1],   "Ending", "none"), // c3
    
    "End Cake Picture": course_meta(0x19, [-1],   "All Clear", "none"),
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
// Individual stars
//

function collided_with_star_exit(obj_name, mission=-1) {
    star_tallies = []
    for i in range(1, 4) {
        obj_addr = object_nth_collided_object(mario_object(), i)
        if (mission != -1) {
            array_push(star_tallies, 
                once(object_num_collided_objects(mario_object()) >= i
                && object_is(obj_addr, obj_name)
                && object_star_mission(obj_addr) == mission)
            )
        } else {
            array_push(star_tallies, 
                once(object_num_collided_objects(mario_object()) >= i
                && object_is(obj_addr, obj_name))
            )
        }
    }
    
    return tally(1, star_tallies)
}

function course_stars_meta(title, star_name, star_type, points, id=0, badge="0") => {"title": title, "star name": star_name, "star type": format("{0} star", star_type), "points": points, "id": id, "badge": badge}

course_1_stars = [
    course_stars_meta("Warmup Across Moving Platforms", "Cold Hands Warmup", "stationary", 3, id=210975, badge="233718"),
    course_stars_meta("Custom Cap Triathlon", "Dark Home Cap Jamboree", "stationary", 5, id=210976, badge="233719"),
    course_stars_meta("Good Old Red Coins", "The Classic Red Coin Star", "spawned", 10, id=210977, badge="233720"),
    course_stars_meta("Floating to Victory", "Levitation and Transfiguration", "stationary", 10, id=210978, badge="233721"),
    course_stars_meta("Sleeping Shurikens", "Nighttime Secrets Hunt", "spawned", 25, id=210979, badge="233722"),
    course_stars_meta("The Rainbow Lit Path", "Three Way Autoscroller", "stationary", 25, id=210980, badge="233723")
]

for i in range(0, 5) {
    star = course_1_stars[i]
    
    achievement(
        title = star["title"],
        description = format("Collect the star '{0}' in {1} (no save states).", star["star name"], course_infos["Course 1"]["full name"]),
        points = star["points"],
        trigger = never(!in_level("Course 1"))
            && trigger_when(collided_with_star_exit(star["star type"], mission=i))
            && prev(used_save_state__mem) == 0
            && trigger_when(used_save_state__mem == 1) 
            && hud_stars_shown() == 1,
        id = star["id"],
        badge = star["badge"]
    )
}

function other_stars_meta(save_offset, bits) { // assume 1 byte per area
    off = current_file__addr + save_offset
    return sum_of(bits, b => bit(b, off))
}

other_stars_bits = {
    "Cap Tutorials":    other_stars_meta(0x0b, [0, 1, 2]),
    "Bowser":           other_stars_meta(0x0e, [0]),
}

function other_stars_count(key, is_delta="False") {
    mem = other_stars_bits[key]
    if (is_delta == "True")
        return prev(mem)
    return mem
}

achievement(
    title = "New Caps to Play With",
    description = "Collect all three stars in the cap tutorials.",
    points = 10,
    trigger = in_level("Hub", check_sublevels=0)
        && other_stars_count("Cap Tutorials", "True") == 2
        && other_stars_count("Cap Tutorials") == 3
        && level_id__mem == prev(level_id__mem),
    id = 210986,
    badge = "233729"
)

// progression / milestones (save states allowed)

function star_milestone_trigger(num_stars) {
    return measured(nof_stars() == num_stars, when=!in_title_or_file_select())
        && prev(nof_stars()) == num_stars - 1
        && level_id__mem == prev(level_id__mem) // to prevent switching files after the ending picture puts you back to the title screen...
}

achievement(
    title = "A Worthy Player",
    description = "Collect 5 stars to gain access to the Bowser fight.",
    points = 5,
    trigger = star_milestone_trigger(5),
    id = 210981,
    badge = "233724"
)

achievement(
    title = "Aglab All Clear",
    description = "Collect all 10 stars.",
    points = 10,
    trigger = star_milestone_trigger(10),
    id = 210982,
    badge = "233725"
)

achievement(
    title = "Bowser's Avoidance",
    description = "Collect the key that's actually a star in the Bowser fight (save states allowed).",
    points = 10,
    trigger = in_level("Bowser Fight") && just_collected_star(),
    id = 210983,
    badge = "233726"
)

// challenges / misc

achievement(
    title = "Aglab's Tech Demo",
    description = "Press the switch revealing a hint movie in After the Storm.",
    points = 1,
    trigger = in_level("Course 1")
        && object_is(stood_on_object(), "tech demo switch"),
    id = 210988,
    badge = "233731"
)

achievement(
    title = "To the Moon",
    description = "Levitate too high into the air and hear some fitting music as you Game Over.",
    points = 1,
    trigger = never(!in_level("Course 1"))
        && never(music_id__mem != 0x26)
        && repeated(210, always_true()),
    id = 210989,
    badge = "233732"
)

//achievement(
//    title = "Burn Out for Red Coins",
//    description = "Collect the red coin star in the Burn Cap Switch room while still wearing your burn cap, while collecting only one burn cap (resets on reload / re-entry).",
//    points = 5,
//    trigger = never(!in_level("Burn Cap Switch"))
//        && once(mario_action_is(course_infos["Burn Cap Switch"]["entrance action"]))
//        && never(prev(wearing_metal_cap()) == 1 && cap_time() > prev(cap_time()))
//        && never(repeated(2, prev(wearing_metal_cap()) == 0 && wearing_metal_cap() == 1))
//        && trigger_when(prev(wearing_metal_cap()) == 1)
//        && (trigger_when(mario_action_changed_to("star grab fall")) || trigger_when(mario_action_changed_to("star dance ground (no exit)")))
//)

nighttime_switch = nth_array_object(object_indexes["Course 1"]["Nighttime Switch"])

achievement(
    title = "Actually Dark Home Cap Jamboree",
    description = "Collect the star 'Dark Home Cap Jamboree' in After the Storm while it is nighttime (no save states).",
    points = 10,
    trigger = never(!in_level("Course 1"))
        && never(mario_action_is(course_infos["Course 1"]["entrance action"]))
        && once(object_is(stood_on_object(), "nighttime switch"))
        && trigger_when(collided_with_star_exit("stationary star", mission=2-1))
        && prev(used_save_state__mem) == 0
        && trigger_when(used_save_state__mem == 1) 
        && hud_stars_shown() == 1,
    id = 210987,
    badge = "233730"
)

bowser_fight = nth_array_object(object_indexes["Bowser Fight"]["Boss Controller"])

achievement(
    title = "Conquered the Bullet Hell",
    description = "Defeat Bowser with at least half HP remaining (no save states).",
    points = 25,
    trigger = in_level("Bowser Fight")
        && hp() >= 0x400
        && used_save_state__mem == 0
        && trigger_when(object_is(bowser_fight, "boss controller") && object_action(bowser_fight) == 10),  // 10 = bowser defeat
    id = 210984,
    badge = "233727"
        
)

achievement(
    title = "Styling on Bowser",
    description = "Perform 25 breakdance kicks during the Bowser fight without taking damage (no save states or reloading, Bowser must not be defeated, challenge begins on first breakdance).",
    points = 10,
    trigger = never(!in_level("Bowser Fight"))
        && once(mario_anim_changed_to("Breakdance Kick"))
        && never(hp() < prev(hp()))
        && used_save_state__mem == 0
        
        && object_is(bowser_fight, "boss controller")
        && never(object_action(bowser_fight) == 10) // fight active
        && never(mario_action_is(course_infos["Bowser Fight"]["entrance action"]))
        
        && (measured(repeated(25, mario_anim_changed_to("Breakdance Kick"))) || trigger_when(repeated(25, mario_anim_changed_to("Breakdance Kick")))),
    id = 210985,
    badge = "233728"
)

// LB's

leaderboard(
    title = "Coin Cache After the Storm",
    description = "Maximum coin score in Course 1 (no save states, must get a star, see RP).",
    start = never(!in_level("Course 1"))
        && any_of(star_grab_actions, a => once(mario_action_changed_to(a)))
        && prev(used_save_state__mem) == 0
        && used_save_state__mem == 1,
    cancel = always_false(),
    submit = always_true(),
    value = nof_coins(),
    format = "VALUE"
)

leaderboard(
    title = "Avoidance Champ",
    description = "Defeat Bowser with as much remaining HP as possible (no save states, max: 2176).",
    start = in_level("Bowser Fight") && mario_action_is(course_infos["Bowser Fight"]["entrance action"]),
    cancel = !in_level("Bowser Fight") || used_save_state__mem == 1,
    submit = object_is(bowser_fight, "boss controller") && object_action(bowser_fight) == 10,
    value = hp(),
    format = "VALUE"
)

// RP

stars__value = rich_presence_value("Number", nof_stars())
coins__value = rich_presence_value("Number", nof_coins())

save_state__lookup = rich_presence_lookup("SS", used_save_state__mem, {
    0x00: ""}, "[SS] ")

meta_descriptions = {
    0x00: "Starting up the game",
    0x21: "In File Select",
}

general_level_dict = {
    0x09: "navigating custom objects in After the Storm",
    0x18: "in Bowser's bullet hell",
    0x0c: "stuck in the ending after having beaten Bowser",
    0x19: "at the ending screen. Congrats on 100%!"
}

function rp_cond_display_same_display(cond, lookup) {
    rich_presence_conditional_display(cond, 
    "{2}Mario is {0} with {1}⭐ and {3}💰", lookup, stars__value, save_state__lookup, coins__value)
}

level__lookup = rich_presence_lookup("LevelsWithoutSublevels", level_id__mem, general_level_dict, "in an unbeknownst location")

level_10__lookup = rich_presence_lookup("Level10", sublevel_id__mem, {
    0x00: "in the main hub",
    0x01: "in the main hub",
    0x02: "near the yellow cap switch, navigating quicksand",
    0x03: "near the maroon cap switch, burning on demand",
    0x04: "near the purple cap switch, grinding firsties"
})

cond_displays = {
    "general": {"cond": mem_in(level_id__mem, general_level_dict), "lookup": level__lookup},
    "level10": {"cond": (level_id__mem == 0x10), "lookup": level_10__lookup}
}

rich_presence_conditional_display(in_title_or_file_select(), 
    "{0}", rich_presence_lookup("Fileless", music_id__mem, meta_descriptions))
rich_presence_conditional_display(is_collecting_star(), "Mario just got a star in {0}! [{1}⭐] [{2}💰]", rich_presence_lookup("GeneralLevels", level_id__mem, {
    0x10: "the cap tutorials",
    0x09: "After the Storm",
    0x18: "the Bowser fight"
}, "an unbeknownst location"), stars__value, coins__value)
for k in cond_displays {
    rp_cond_display_same_display(cond_displays[k]["cond"], cond_displays[k]["lookup"])
}
rich_presence_display("Mario is preparing to take on Bowser in his custom arena.")