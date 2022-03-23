// ~Hack~ Star Revenge 11: Star Adventure
// #ID = 18773
// Made in RATools v1.8.4

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

// stuff all memory addresses up here, in case another version comes out and I gotta update every bloody address

offsets = {
    "SAVE DATA":    (0x07a400 - 0x70),
    
    "MUSIC ID":     0x0af81a,

    "FILE ID":      0x1a30ae,
    "MAP ID":       0x1a30ac,
    
    "STOOD ON OBJECT":  0x1a58b4,
    "COLLECTED STAR ID":    0x1a3052,

    "LEVEL INDEX":      0x1b0a54,
    
    "SUBMAP ID":        0x1b0155,
    
    "HUD FLAGS":    0x1b0144,   //  https://github.com/n64decomp/sm64/blob/1372ae1bb7cbedc03df366393188f4f05dcfc422/src/game/level_update.h#L91
    
    "MARIO STRUCT": 0x1b0060,
    "OBJECT ARRAY": 0x1b1de0,
    
    "TEXT ENGINE STATE": 0x1d67d0, // https://github.com/jesusyoshi54/sm64ex-alo/blob/SR11/src/game/text_engine.h
}

behaviour_script__values = { // these can also get shuffled around in updates
    "ghost hunt boo":   0x802f30a0,
    "message panel":    0x802f3b90,
    "1up running away": 0x802f48c0,
    "1up stationary":   0x802f492c,
}

// ---------------
//   m e m o r y
// ---------------

mario__struct = { // https://github.com/jesusyoshi54/sm64ex-alo/blob/SR11/include/types.h#L285
    "hat bitflags":       0x04,  // byte
    "current action":     0x0c,  // dword
    "previous action":    0x10,  // dword
    "floor footstep type":0x16, //0x14,  // word (yeah, these got shifted...)
    "action phase":       0x1a, //0x18,  // word
    "x":                  0x40, //0x3c,  // dword (float)
    "y":                  0x44, //0x40,  // dword (float)
    "z":                  0x48, //0x44,  // dword (float)
    "wall triangle pointer":    0x64, //0x60, // dword (pointer to tri)
    "ceiling triangle pointer": 0x68, //0x64, // dword (pointer to tri)
    "floor triangle pointer":   0x6c, //0x68, // dword (pointer to tri)
    "interaction object": 0x7c, //0x78,  // dword (pointer to object)
    "held object":        0x80, //0x7C,  // dword (pointer to object)
    "used object":        0x84, //0x80,  // dword (pointer to object) - like 
    "mario object":       0x8c, //0x88,  // dword (pointer to object)
    "controller":         0xa0, //0x9c,  // dword (pointer to controller struct)
    "nof stars":          0xac, //0xa8,  // word, NOT HUD
    "nof coins":          0xae, //0xaa,  // word
    "hp":                 0xb0, //0xac,  // byte / word
    "hp increment":       0xb4, //0xb0,  // byte
    "hp decrement":       0xb5, //0xb1,  // byte
    "cap timer":          0xb8, //0xb4,  // word
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

// Mario Object specific stuff

// watch out for animation value collisions (ex: airborne spawn and falling out of water both use general fall, 0x56)
mario_anim__values = {
    "Water Star Dance": 0xB3, //https://github.com/n64decomp/sm64/blob/1372ae1bb7cbedc03df366393188f4f05dcfc422/include/mario_animation_ids.h#L186
    "Star Dance":       0xCD,
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

}

// text engine

te_state__addr = offsets["TEXT ENGINE STATE"]

te_struct = {
    "ogStr":    0xF8 // dword (pointer to string)
}

function te_field(field) => struct_field(te__struct, te_state__addr, field)

function te_original_string() => dword(te_field("ogStr"))

// hint sign locations (for warping to later...)

//C4:
//-2482, -3857, 8220 (1a, "All caps to respect the name.")
//-4053, 39, -3114   (18, "There is no madness left. Only tranquility.")
//-3, -861, 889      (17, "The origin of this curse.")
//1140, -5041, 7289  (19, "This was supposed to be my greatest creation. Now all I have is empty pride.")

//C5:
//5981, -4148, 7776  (30, "Blue is the loneliest color.")
//-5754, -3283, 2567 (2d, "The reason for all things Star Revenge.")
//-13264, 2291, 1157 (2e, "Alone and silent, a sign of fortune.")
//-7869, -592, -10641 (2f, "No space, JustNature.")

//C6:
//-1366, -7157, 10155 (20, "TWO WORDS TWO DICE NO DEUCE")
//6372, -7131, 10264  (1e, "Reptilia Squamata Serpentes Colobroides Viperidae Crotalinae Crotalus.")
//-1675, -5033, 956   (1f, "A losing roll, never bet against the devil.")

//C7:
//-19981, 2681, -3725 (25, "blood for the blood god.")
//269, 4471, -2994    (24, "May 26 2021.")
//-10422, 5233, 1085  (27, "the world between this sun and moon.")
//14332, 6013, 13307  (26, "the darker and more somber of our pair.")

// ---------------
//   m e m o r y
// ---------------

hud_flags__addr = offsets["HUD FLAGS"]

function hud_stars_shown() => bit2(hud_flags__addr)

file_num__addr = offsets["FILE ID"]
file_num__mem = byte(file_num__addr)

save_data_base__addr = offsets["SAVE DATA"]
current_file__addr = save_data_base__addr + 0x70 * file_num__mem

challenge_flags = {
    "Buffed Enemies"    : bit(0, current_file__addr),
    "Coins Don't Heal"  : bit(1, current_file__addr),
    "Drain HP"          : bit(2, current_file__addr),
    "Double Lava Damage": bit(3, current_file__addr),
    "Double Koopa Speed": bit(4, current_file__addr),
    "Chaos Lite"        : bit(5, current_file__addr),
    "A Button Challenge": bit(6, current_file__addr),
    "B Button Challenge": bit(7, current_file__addr),
    "Z Button Challenge": bit(8, current_file__addr),
    "Hardcore"          : bit(9, current_file__addr),
    "Green Demon"       : bit(10, current_file__addr),
    "Move Badges"       : bit(11, current_file__addr),
    "Super Mode"        : bit(12, current_file__addr),
    "Daredevil"         : bit(13, current_file__addr),
}

function challenge_active(name) => challenge_flags[name] != 0

function star_specific_challenge_trigger(level, star_index=-1, challenges_required=[], challenges_excluded=[]) {
    return remained_in_level(level)
        && never(any_of(challenges_required, c => !challenge_active(c)))
        && never(any_of(challenges_excluded, c => challenge_active(c)))
        && just_collected_star(star_index=star_index, trigger=1)
}

// normal starts = 1-6; 100 coin star = 7
last_star__addr = offsets["COLLECTED STAR ID"]
last_star__mem = byte(last_star__addr)

sublevel_id__addr = offsets["SUBMAP ID"]
sublevel_id__mem  = byte(sublevel_id__addr)

level_id__addr = offsets["MAP ID"]
level_id__mem = byte(level_id__addr)

level_index__addr = offsets["LEVEL INDEX"]
level_index__mem = byte(level_index__addr)

function course_meta(value, sublevel_values, full_name) => {"value": value, "sublevel values": sublevel_values, "full name": full_name}

course_infos = {
    "The First Area":   course_meta(0x1a, -1,   "Grassy Valley"),
    "Overworld 1":      course_meta(0x06,  1,   "Overworld 1"),
    "Overworld 2":      course_meta(0x06,  2,   "Overworld 2"),
    
    "Quiz 1":           course_meta(0x09, -1,   "The First Quiz"),
    "Quiz 2":           course_meta(0x18, -1,   "The Second Quiz"),
    "Quiz 3":           course_meta(0x0c, -1,   "The Third Quiz"),
    
    "Course 4":         course_meta(0x05, -1,   "Prestigious Palace"),
    "Course 5":         course_meta(0x04, -1,   "Solitary Sand Desert"),
    "Course 6":         course_meta(0x07, -1,   "Rolling Deuce"),
    "Course 7":         course_meta(0x16, -1,   "Bloody Eclipse"),
    
    "Bowser 1":         course_meta(0x11, -1,   "Overlord's Palace"), // B1 Course

    "Bowser Fight":     course_meta(0x22, -1,   "Overlord's Palace"), // B3 fight
    
    "Aquarium":         course_meta(0x14, -1,   "Teasing Mr. Scuttlebug"),
    "End Cake Picture": course_meta(0x19, -1,   "End Cake Picture")
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
    if (course_infos[name]["sublevel values"] == -1) {return always_true()}
    
    // used to be an any_of statement but RATools won't let me compare an array to an integer constant :|
    return sublevel_id__mem == course_infos[name]["sublevel values"]
}

function in_same_level_from_last_frame() => level_id__mem == prev(level_id__mem) && sublevel_id__mem == prev(sublevel_id__mem)

function remained_in_level(name) => never(!in_level(name)) && once(prev(level_id__mem) != course_infos[name]["value"]) && hud_stars_shown() == 1 // beware for open-world type hacks...
function remained_in_sublevel(name) => never(!in_sublevel(name)) && once(prev(sublevel_id__mem) != course_infos[name]["sublevel values"]) && hud_stars_shown() == 1

function course_stars_meta(save_offset, points, title, ids=[0, 0], badges=["0", "0"]) => {"save offset": save_offset, "points": points, "title": title, "ids": ids, "badges": badges}

course_offsets = { // bytes offset from start of EEPROM, handle secret stars separately...
    4:  course_stars_meta(0x0c, 10, "Downhanging Eversnow Evening Peak Palace", ids = [206088, 206089], badges = ["228595", "228596"]),
    5:  course_stars_meta(0x13, 10, "A Different Colorful Pyramid Desert",  ids = [206090, 206091], badges = ["228597", "228598"] ),
    6:  course_stars_meta(0x12, 10, "Devil's Dice-Fortress Forest",         ids = [206092, 206093], badges = ["228599", "228600"]        ),
    7:  course_stars_meta(0x11, 25, "Eclipse of a Greater Sun and Moon",    ids = [206094, 206095], badges = ["228601", "228602"]   ),
}

function course_regular_stars_count(course_num, is_delta) {
    off = current_file__addr + course_offsets[course_num]["save offset"]
    mem = bitcount(off) - bit(7, off) - bit(6, off) - bit(5, off)
    if is_delta == "True"
        return prev(mem)
    return mem
}

for num in course_offsets {
    tot = 5
    course_name = format("Course {0}", num)
    course_full_name = course_infos[course_name]["full name"]
    course_info = course_infos[course_name]
    achievement(
        title = format("{0} [m]", course_offsets[num]["title"]),
        description = format("Collect all 5 regular (non-password) stars in {0}.", course_full_name),
        points = course_offsets[num]["points"],
        trigger = in_level(course_name)        
            && course_regular_stars_count(num, "True") == tot - 1
            && measured(course_regular_stars_count(num, "False") == tot, when=!in_title_or_file_select()),
        id = course_offsets[num]["ids"][0],
        badge = course_offsets[num]["badges"][0]
    )
    
    achievement(
        title = format("World Destruction - {0}", course_info["full name"]),
        description = format("Crack the password and collect that star in {0}.", course_name),
        points = 2,
        trigger = in_level(course_name)
            && just_collected_star(star_index = 6),
        id = course_offsets[num]["ids"][1],
        badge = course_offsets[num]["badges"][1]
    )
}

// 
// Other Achievements (all course stars are above...)
//

// progression / milestones

achievement(
    title = "Grassy Valley Mashup",
    description = "Collect the first star. Don't forget the red coin behind spawn!",
    points = 2,
    trigger = in_level("The First Area")
        && trigger_when(just_collected_star(trigger=1)),
    id = 206096,
    badge = "228603"
)

function quiz_meta(title, ordinal, level, id=0, badge="0") => {"title": title, "ordinal": ordinal, "level": level, "id": id, "badge": badge}

quiz_infos = [
    quiz_meta("Music Quiz - Original Source ID", "first", "Quiz 1",  206097, "228604"),
    quiz_meta("Music Quiz - Star Revenge ID",    "second", "Quiz 2", 206098, "228605"),
    quiz_meta("Music Quiz - Scuttle's Ports ID", "third", "Quiz 3",  206099, "228606"),
]

for qz in quiz_infos {
    achievement(
        title = qz["title"],
        description = format("Complete the {0} quiz.", qz["ordinal"]),
        points=10,
        trigger = in_level(qz["level"]) && just_collected_star()
    )
}

achievement(
    title = "Teasing Mr. Scuttlebug",
    description = "Keep talking to the scuttlebug until he gives you a second star, then get that star. Speedrunners will never find this LOL.",
    points = 1,
    trigger = in_level("Aquarium")
        && just_collected_star(1, trigger=1),
    id = 206100,
    badge = "228607"
)

function star_milestone_trigger(num_stars) {
    return measured(nof_stars() == num_stars, when=!in_title_or_file_select())
        && prev(nof_stars()) == num_stars - 1
        && level_id__mem == prev(level_id__mem) // to prevent switching files after S&Q...
}

achievement(
    title="Back to Normal",
    description="Defeat Bowser and save Star Revenge (wait 5 seconds at ending screen).",
    points=10,
    trigger= once(!in_level("End Cake Picture", delta=1))
        && repeated(300, in_level("End Cake Picture")), // some timing so the screenshot happens when the dorrie pic is fully faded in
    id = 206101,
    badge = "228608"
)

achievement(
    title = "Ultimate Star Collection [m]",
    description = "Collect all 31 obtainable stars on one save file (must get ending star last).",
    points = 25,
    trigger = star_milestone_trigger(31),
    id = 206102,
    badge = "228609"
)

// "challenges"

collected_any_regular_star_on_star_dance_arr = []
for val in star_dance_anim_values {
    array_push(collected_any_regular_star_on_star_dance_arr, last_star__mem != 6 && mario_anim_changed_to(val))
}

achievement(
    title = "Is This Even Different?",
    description = "Complete the first quiz (Coins Don't Heal, no Super Mode).",
    points = 3,
    trigger = star_specific_challenge_trigger("Quiz 1", -1, ["Coins Don't Heal"], ["Super Mode"]),
    id = 206103,
    badge = "228610"
)

function all_boos_died() {
    dead_boos = []
    for i in range(0, 239) {
        nth_obj = nth_array_object(i)
        array_push(dead_boos,
            repeated(10, object_active(nth_obj) == 1
                && object_is_boo_that_died(nth_obj)))
    }
    
    return measured(tally(10, dead_boos))
}

achievement(
    title = "Go on a Ghost Hunt - Star Revenge Edition",
    description = "Quiz 2 - defeat all 10 boos in the fourth part.",
    points = 5,
    trigger = never(!in_level("Quiz 2")) && sublevel_id__mem == 4
        && all_boos_died(),
    id = 206104,
    badge = "228611"
)

achievement(
    title = "An Annoying Journey",
    description = "Complete the third quiz (Buffed Enemies, no Super Mode).",
    points = 10,
    trigger = star_specific_challenge_trigger("Quiz 3", -1, ["Buffed Enemies"], ["Super Mode"]),
    id = 206105,
    badge = "228612"
)

achievement(
    title = "A Distorted Climb [m]",
    description = "Course 4 - collect the star at the end of the SR5.5 (purple) section (no wing cap or Super Mode)",
    points = 5,
    trigger = star_specific_challenge_trigger("Course 4", 4, [], ["Super Mode"])
        && never(wearing_wing_cap() == 1),
    id = 206106,
    badge = "228613"
)

achievement(
    title = "Unfortunately, There is no Secret Warp [m]",
    description = "Course 5 - collect the star behind the blue desert, next to a blue tree (Drain HP, no Super Mode)",
    points = 10,
    trigger = star_specific_challenge_trigger("Course 5", 4, ["Drain HP"], ["Super Mode"]),
    id = 206122,
    badge = "228629"
)

achievement(
    title = "Crossovers Against Time [m]",
    description = "Course 5 - collect the red coin star (A Button Challenge, no Super Mode)",
    points = 10,
    trigger = star_specific_challenge_trigger("Course 5", 5, ["A Button Challenge"], ["Super Mode"]),
    id = 206107,
    badge = "228614"
)

achievement(
    title = "Quick Chase to the Top of the World [m]",
    description = "Course 6 - collect the star on the floating islands without warping (Green Demon, no Super Mode)",
    points = 5,
    trigger = star_specific_challenge_trigger("Course 6", 2, ["Green Demon"], ["Super Mode"])
        && never(mario_action_is("start teleporting")),
    id = 206108,
    badge = "228615"
)

achievement(
    title = "Double Trouble Dice-Fortress Reds [m]",
    description = "Course 6 - collect the red coin star (Drain HP, A Button Challenge, no Super Mode)",
    points = 10,
    trigger = star_specific_challenge_trigger("Course 6", 5, ["Drain HP", "A Button Challenge"], ["Super Mode"]),
    id = 206109,
    badge = "228616"
)

achievement(
    title = "Eclipse Exploration, King Boo's Revenge Style [m]",
    description = "Course 7 - collect any 2 regular (non-password) stars without leaving (no Super Mode)",
    points = 10,
    trigger = remained_in_level("Course 7")
        && never(challenge_active("Super Mode"))
        && (trigger_when(tally(2, collected_any_regular_star_on_star_dance_arr)) || 
           measured(tally(2, collected_any_regular_star_on_star_dance_arr))),
    id = 206110,
    badge = "228617"
)

achievement(
    title = "Daredevil Comet in the Palace",
    description = "Overlord's Palace - collect the red coin star (Daredevil, no Super Mode)",
    points = 10,
    trigger = star_specific_challenge_trigger("Bowser 1", -1, ["Daredevil"], ["Super Mode"]),
    id = 206111,
    badge = "228618"
)

// 1-ups!

// Let tallies be a list of dicts of form
// {"type": (type of 1up), "count": (number of this type to count)}
// 
function tally_1ups(tallies=[], trigger=0, measured=0)
{
    total_count = sum_of(tallies, t => t["count"])
    mushie_tally = []
    
    for t in tallies {
        obj_name = format("1up {0}", t["type"])
        
        for i in range(1,4) {
        obj_addr = object_nth_collided_object(mario_object(), i)
        array_push(mushie_tally,
            repeated(t["count"], object_num_collided_objects(mario_object()) >= i
            && (obj_addr != prev(obj_addr) || (object_behav_script(obj_addr)) != prev(object_behav_script(obj_addr)))
            && object_is(obj_addr, obj_name)))    // right object type
        }
    }
    if (measured != 0)
        return measured(tally(total_count, mushie_tally))
    else if (trigger != 0)
        return trigger_when(tally(total_count, mushie_tally))
    return tally(total_count, mushie_tally)
}

function mushies_meta(title="", points=0, tallies=[], id=0, badge="0") => {"title": title, "points": points, "tallies": tallies, "id": id, "badge": badge}

mushies_data = {
    "The First Area": mushies_meta("Mushie of SR1 [m]", 1, [{"type": "stationary", "count": 1}], 206121, "228628"),
    "Quiz 1":   mushies_meta("Mushies of the First Quiz",  4, [{"type": "stationary", "count": 4}], 206114, "228621"),
    "Quiz 2":   mushies_meta("Mushie of the Peaceful Place", 1, [{"type": "running away", "count": 1}], 206115, "228622"),
    "Quiz 3":   mushies_meta("Mushie of the Bay Town",    1, [{"type": "running away", "count": 1}], 206116, "228623"),
    "Course 4": mushies_meta("Mushies of the Palace [m]", 3, [{"type": "stationary", "count": 2}, {"type": "running away", "count": 1}], 206112, "228619"),
    "Course 6": mushies_meta("Mushies of the Dice [m]",   5, [{"type": "stationary", "count": 7}], 206113, "228620"),
}

for course in mushies_data {
    
    mushie_count = sum_of(mushies_data[course]["tallies"], t => t["count"])
    mushie_qty_string = ""
    
    collected_cond = tally_1ups(tallies = mushies_data[course]["tallies"], measured=1)
    
    if (mushie_count == 1) {
        mushie_qty_string = format("the 1-up mushroom")
        collected_cond = tally_1ups(tallies = mushies_data[course]["tallies"])
    }
    else
        mushie_qty_string = format("all {0} 1-up mushrooms", mushie_count)
    
    achievement(
        title = mushies_data[course]["title"],
        description = format("{0} - collect {1} (green demon doesn't count, see picture)", course, mushie_qty_string),
        points = mushies_data[course]["points"],
        trigger = never(!in_level(course))
            && collected_cond
    )
}

// Signs
function tally_signs(signs, measured=1) {
    tally_count = length(signs)
    read_signs = []
    int_obj = interaction_object()
    for sign in signs {
        array_push(read_signs, once(object_is(int_obj, "message panel")
            && object_beh_param_2(int_obj) == sign))
    }
    
    if (measured != 0)
        return measured(tally(tally_count, read_signs))
    return tally(tally_count, read_signs)
}


function signs_meta(title="", points=0, signs=[], id=0, badge="0") => {"title": title, "points": points, "signs": signs, "id": id, "badge": badge}

sign_values = {
    "Course 4": signs_meta("Hints of the Palace [m]", 4, [0x17, 0x18, 0x19, 0x1a]),
    "Course 5": signs_meta("Hints of the Desert [m]", 4, [0x2d, 0x2e, 0x2f, 0x30]),
    "Course 6": signs_meta("Hints of the Dice [m]",   3, [0x1e, 0x1f, 0x20]),
    "Course 7": signs_meta("Hints of the Eclipse [m]",5, [0x24, 0x25, 0x26, 0x27]),
}

for course in sign_values {
    num_signs = length(sign_values[course]["signs"])
    achievement(
        title = sign_values[course]["title"],
        description = format("{0} - read all {1} password hint signs without leaving (Overlord Dev Logs don't count, see picture)", course, num_signs),
        points = sign_values[course]["points"],
        trigger = never(!in_level(course))
            && tally_signs(sign_values[course]["signs"], measured=1)
    )
}

DUMMY_ACHIEVEMENT(
    title = "sign1a",
    trigger=object_is(interaction_object(), "message panel")
        && object_beh_param_2(interaction_object()) == 0x1a
)

// RP

music_id__mem  = byte(offsets["MUSIC ID"])

meta_descriptions = {
    0x00: "Starting up the game",
    0x02: "Playing with Mario Head / Listening to Global Terminal Music",
    0x21: "In File Select",
}

level_descriptions = {
    0x1a: "is a familiar grassy valley",
    0x06: "is in the hub between dimensions",
    
    0x09: "is taking the first quiz, listening to Star Revenge music",
    0x18: "is taking the second quiz, listening to Star Revenge music",
    0x0c: "is taking the third quiz, listening to scuttlebug's custom music",
    
    0x05: "is in Course 4, traversing fragments of winter palaces",
    0x04: "is in Course 5, traveling in a motley desert",
    0x07: "is in Course 6, visiting the oh-so familiar Dice-Fortress",
    0x16: "is in Course 7, suffering a non-Star Revenge fate",
    
    0x11: "is on his way to the scuttlebug in Overlord's Palace",
    0x22: "is fighting Bowser yet again",
    0x14: "has defeated Bowser and has met up with scuttlebug",
    0x19: "has saved Star Revenge",
}

rich_presence_conditional_display(in_title_or_file_select(), 
    "{0}", rich_presence_lookup("Fileless", music_id__mem, meta_descriptions))
rich_presence_conditional_display(any_of(level_descriptions, a => level_id__mem == a), 
    "{1}{2}{3}{4}Mario {0} with ⭐{5}", 
        rich_presence_lookup("Levels", level_id__mem, level_descriptions, "is in an unbeknownst location"),
        rich_presence_lookup("SuperMode", challenge_flags["Super Mode"], {0:"", 1:"Super Mode "}),
        rich_presence_lookup("Hardcore", challenge_flags["Hardcore"], {0:"", 1:"Hardcore "}),
        rich_presence_lookup("Chaos", challenge_flags["Chaos Lite"], {0:"", 1:"Chaos "}),
        rich_presence_lookup("Daredevil", challenge_flags["Daredevil"], {0:"", 1:"Daredevil "}),
        rich_presence_value("Number", nof_stars()))
rich_presence_display("Mario is on a quest to save Star Revenge.")