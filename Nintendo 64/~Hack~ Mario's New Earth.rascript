// ~Hack~ Mario's New Earth
// #ID = 11436

// ------------- //
//   u t i l s   //
// ------------- //

function mem_in(mem, arr) {
    cond = always_false()
    for el in arr
        cond = cond || (mem == el)
    return cond
}

function is_float_neg(mem) => mem > 0x80000000

function just_increased(mem) => mem > prev(mem)

function just_changed_any(mem) => mem != prev(mem)
function just_changed(mem, from, to) => prev(mem) == from && mem == to
function just_changed_to(mem, to) => prev(mem) != to && mem == to

function struct_field(struct_def, base, field) => base + struct_def[field]

function object_field(base, field) => struct_field(object__struct, base, field)

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

// ---------------
//   m e m o r y
// ---------------

mario_anim__addr = 0x33b17c
mario_anim__mem = dword(mario_anim__addr)

mario_prev_anim__addr = 0x33b180
mario_prev_anim__mem  = dword(mario_prev_anim__addr)

mario_anim__values = {
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
    "air sitting":                 0x0300088E,
}

function mario_anim_is(name) => mario_anim__mem == mario_anim__values[name]
function mario_prev_anim_is(name) => mario_prev_anim__mem == mario_anim__values[name]

function mario_anim_changed_to(name) {
    return prev(mario_anim__mem) != mario_anim__values[name]
        && mario_anim__mem == mario_anim__values[name]
}

function airborne() => bit3(mario_anim__addr + 1) != 0
function on_pole() => bit4(mario_anim__addr + 2) != 0

transition_type__addr = 0x33bab2
transition_type__mem = word(transition_type__addr)

function transition_active() => transition_type__mem >= 0x100

TRANSITION_STAR_FADE_OUT = 0x108

controller_input__addr = 0x367057

function controller_a_button() => bit7(controller_input__addr)
function controller_b_button() => bit6(controller_input__addr)

// ------------- //
//   m a r i o   //
// ------------- //

mario__struct = {
    "hat bitflags":       0x04,  // byte
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
    "nof stars (hud)":    0xa8,  // word
    "nof coins":          0xaa,  // word
    "hp":                 0xac,  // byte / word
    "hp inc":             0xb0,  // byte
    "hp dec":             0xb1,  // byte
    "cap timer":          0xb4,  // word
}

mario__addr = 0x33b170
stood_on_object__addr = 0x330e34

function mario_field(field) => struct_field(mario__struct, mario__addr, field)

function wearing_wing_cap()   => bit3(mario_field("hat bitflags"))
function wearing_metal_cap()  => bit2(mario_field("hat bitflags"))
function wearing_vanish_cap() => bit1(mario_field("hat bitflags"))

function floor_footstep_type() => word(mario_field("floor footstep type"))
// note: uses the nearest floor directly beneath mario, still updates when mario is airborne...

function action_phase() => word(mario_field("action phase"))

function slide_kick_bounced() => mario_anim_is("slide kick") && action_phase() == 1
function butt_slide_bounced() => mario_anim_is("air sitting") && action_phase() == 1

function pos_x() => dword(mario_field("x"))
function pos_y() => dword(mario_field("y"))
function pos_z() => dword(mario_field("z"))

function held_object() => tbyte(mario_field("held object"))
function used_object()  => tbyte(mario_field("used object"))
function mario_object() => tbyte(mario_field("mario object"))
function stood_on_object() => tbyte(stood_on_object__addr)

function hp_int() => byte(mario_field("hp") + 1)
function hp_dec() => byte(mario_field("hp dec"))
function just_took_damage() => prev(hp()) > hp()

function hp() => word(mario_field("hp"))

function cap_time() => word(mario_field("cap timer"))

function nof_stars() => word(mario_field("nof stars (hud)"))
function nof_coins() => word(mario_field("nof coins"))

// ---------------
//   m e m o r y
// ---------------

// hud comes right after mario
hud_timer__addr = 0x33b26e
hud_timer__mem  = word(hud_timer__addr)

function int_seconds_to_frames(seconds) => seconds * 30

music_id__addr = 0x22261e
music_id__mem  = byte(music_id__addr)

function boss_music_ended() => prev(music_id__mem) == 0x16 && music_id__mem != 0x16 // be careful of other things (cap blocks, ex) that overwrite current music...

file_num__addr = 0x32ddf6
file_num__mem = byte(file_num__addr)

save_data_base__addr = 0x207690
function current_file_data() => save_data_base__addr + 0x70 * file_num__mem

function pressed_switch__mem(color, isDelta="f"){
    current_file__mem = current_file_data()
    switch_mem = always_false
    if color == "red"
        switch_mem = bit1(current_file__mem + 8)
    else if color == "green"
        switch_mem = bit2(current_file__mem + 8)
    else if color == "blue"
        switch_mem = bit3(current_file__mem + 8)
     
    if isDelta == "true"
        return prev(switch_mem)
    else
        return switch_mem
}

function pressed_switch(color, isDelta){
    return pressed_switch__mem(color, isDelta) == 1
}

mission_id__addr = 0x1a81a3
mission_id__mem = byte(mission_id__addr)

coins__addr = 0x33b21a
coins__mem = word(coins__addr)

// normal starts = 1-6; 100 coin star = 7
last_star__addr = 0x32dd87
last_star__mem = byte(last_star__addr)

star_dance_values = ["star dance ground (exit)", "star dance water", "star dance ground (no exit)"]

function just_collected_star_general(star_index=-1, trigger=0) {
    cond = any_of(star_dance_values, a => mario_anim_changed_to(a))
    if (trigger != 0)
        cond = any_of(star_dance_values, a => trigger_when(mario_anim_changed_to(a)))
    if (star_index != -1)
        if (trigger != 0)
            return cond && trigger_when(last_star__mem == star_index)
        return cond && last_star__mem == star_index
    return cond
}

function just_collected_star_no_exit(index) {
    return last_star__mem == index && mario_anim_changed_to("star dance ground (no exit)")
}

collected_any_star_on_star_dance_arr = []
for val in star_dance_values {
    array_push(collected_any_star_on_star_dance_arr, mario_anim_changed_to(val))
}

collected_any_star_on_star_grab_arr = []

array_push(collected_any_star_on_star_grab_arr, mario_anim_changed_to("star grab fall"))
for val in star_dance_values {
    array_push(collected_any_star_on_star_grab_arr, 
        !mario_prev_anim_is("star grab fall")
        && mario_anim_changed_to(val))
        
    //edge case where you spawn 100c star close to the ground and you skip the falling animation...
}

sublevel_id__addr = 0x33b249
sublevel_id__mem  = byte(sublevel_id__addr)

level_id__addr = 0x32ddfa
level_id__mem = byte(level_id__addr)

function course_meta(value, sublevel_values, full_name) => {"value": value, "sublevel values": sublevel_values, "full name": full_name}

course_infos = {
    "Overworld 1":      course_meta(0x10, [-1],   "The first Overworld"), // Castle Grounds
    "Overworld 2":      course_meta(0x06, [0x02], "The second Overworld"), // Inside Castle
    "Overworld 3":      course_meta(0x1a, [0x01, 0x02, 0x03, 0x04], "The third Overworld"), // Castle Courtyard
    "Overworld Tunnel": course_meta(0x1a, [0x05], "Space Tunnel"), // Castle Courtyard SHARED
    
    "Course 1":         course_meta(0x09, [-1],   "Poly-Hued Hills"),
    "Course 2":         course_meta(0x18, [-1],   "Underground Shafts"),
    "Course 3":         course_meta(0x0c, [-1],   "Red Ruby Desert"),
    "Course 4":         course_meta(0x05, [-1],   "Surreal Rainbow Fantasy"),
    "Course 5":         course_meta(0x04, [-1],   "Murky Haunted Village"),
    "Course 6":         course_meta(0x07, [-1],   "Summer Island"),
    "Course 7":         course_meta(0x16, [-1],   "Blue Lava Lagoon"),
    "Course 8":         course_meta(0x08, [-1],   "Mushroom Mountains"),
    "Course 9":         course_meta(0x17, [-1],   "Shivering Snowland"),
    "Course 10":        course_meta(0x0a, [-1],   "Ancient Earth Temple"),
    "Course 11":        course_meta(0x0b, [-1],   "Silent West"),
    "Course 12":        course_meta(0x24, [-1],   "(perished) Dice Town"),
    "Course 13":        course_meta(0x0d, [-1],   "Computer Simulation"),
    "Course 14":        course_meta(0x0e, [-1],   "Earth Skies"),
    "Course 15":        course_meta(0x0f, [-1],   "Forbidden Reality"),
    
    "Trials":           course_meta(0x1f, [-1],   "Tricky Temple Trials"),
    "Quiz":             course_meta(0x1b, [-1],   "The Ultimate Quiz"),
    
    "Bowser 1":         course_meta(0x11, [-1],   "Bowser's Skyscrapers"),
    "Key 1":            course_meta(0x1e, [-1],   "Bowser's Skyscrapers"),
    "Bowser 2":         course_meta(0x13, [-1],   "Bowser's Retro Castle"),
    "Key 2":            course_meta(0x21, [-1],   "Bowser's Retro Castle"),
    "Bowser 3":         course_meta(0x15, [-1],   "Bowser's Fransium Factory"),
    "Final Fight":      course_meta(0x22, [-1],   "Bowser's Fransium Factory"),
    "Metal Cap":        course_meta(0x1c, [-1],   "Pixel's Magmatic Cavern"),
    "Wing Cap":         course_meta(0x1d, [-1],   "Thick Cloud Station"),
    "Vanish Cap":       course_meta(0x12, [-1],   "Library Dimension"),
    
    "Happy End":        course_meta(0x06, [0x01], "The End"),
    "End Cake Picture": course_meta(0x19, [-1], "The End"),
    
    "The Void":         course_meta(0x14, [-1],   "The Void"), // Aquarium
    "Void End":         course_meta(0x06, [0x03], "Destroyed Universe"), // Inside Castle SHARED
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
    return any_of(course_infos[name]["sublevel values"], a => sublevel_id__mem == a)
}

function just_entered_level(name) => just_changed_to(level_id__mem, level_id__values[name]) && in_sublevel(name) 

function course_stars_meta(save_offset, points, title, id, badge) => {"save offset": save_offset, "points": points, "title": title, "id": id, "badge": badge}

course_offsets = { // bytes offset from start of EEPROM, handle secret stars separately...
    1:  course_stars_meta(0x0f, 5, "Colorful Stars",        190482, "211351"),
    2:  course_stars_meta(0x0e, 5, "Underground Stars",     190483, "211352"),
    3:  course_stars_meta(0x0d, 5, "Sandy Stars",           190484, "211353"),
    4:  course_stars_meta(0x0c, 5, "Fantastic Stars",       190485, "211354"),
    5:  course_stars_meta(0x13, 5, "Ghastly Stars",         190486, "211355"),
    6:  course_stars_meta(0x12, 5, "Vacation Stars",        190487, "211356"),
    7:  course_stars_meta(0x11, 5, "Molten Stars",          190488, "211357"),
    8:  course_stars_meta(0x10, 5, "Shroomy Stars",         190489, "211358"),
    9:  course_stars_meta(0x17, 5, "Frosty Stars",          190490, "211359"),
    10: course_stars_meta(0x16, 5, "Earthly Stars",         190491, "211360"),
    11: course_stars_meta(0x15,10, "Wild West Stars",       190492, "211361"),
    12: course_stars_meta(0x14,10, "Classic Stars",         190493, "211362"),
    13: course_stars_meta(0x1b,10, "Virtual Stars",         190494, "211363"),
    14: course_stars_meta(0x1a,10, "Sky-Shredding Stars",   190495, "211364"),
    15: course_stars_meta(0x19,10, "Prohibited Stars",      190496, "211365"),
}

function course_stars_count(course_num, is_delta) {
    off = current_file_data() + course_offsets[course_num]["save offset"]
    mem = bitcount(off) - bit7(off)
    if is_delta == "True"
        return prev(mem)
    return mem
}

for num in course_offsets {
    tot = 7
    course_info = course_infos[format("Course {0}", num)]
    achievement(
        title = course_offsets[num]["title"],
        description = format("Collect all 7 stars in {1}, Course {0}.", num, course_info["full name"]),
        points = course_offsets[num]["points"],
        trigger = in_level(format("Course {0}", num))        
            && course_stars_count(num, "True") == tot - 1
            && measured(course_stars_count(num, "False") == tot)
    )
}

dialog_id__addr = 0x331486
dialog_id__mem = word(dialog_id__addr)
dialog__values = {
    "Pixel's Sign":         0x04,
    "Star Save Prompt":     0x0E,
    
    "Koopa Race 1 Start":   0x05,
    "Koopa Race 1 Win":     0x07,
    "Koopa Race Lose":      0x29, // either race
    "Koopa Race 2 Start":   0x09,
    "Koopa Race 2 Win":     0x1F,
    
    "Penguin Escort Finish":0x3A,
    
    "Whomp Fight Start":    0x72,    
    "Whomp Fight Defeat":   0x73,
    
    "Eyerok Fight Start":   0x75,
    "Eyerok Fight Defeat":  0x76,
    
    "1 Star Message":       0x8D,
    "15 Star Message":      0x8E,
    "50 Star Message":      0x8F,
    "70 Star Message":      0x90,
    "90 Star Message":      0x91,
    "125 Star Message":     0x92,
    
    "Final Bowser Defeat (under 120 stars)": 0x79,
    "Final Bowser Defeat":  0xA3,
}

function dialog_id_is(name, delta=0) {
    dialog_value = dialog__values[name]
    if (delta == 0)
        return dialog_id__mem == dialog_value
    return prev(dialog_id__mem) == dialog_value
}

function dialog_just_ended(name) {
    return dialog_id_is(name, delta=1)
        && !dialog_id_is(name)
}

// ----------------- //
//   o b j e c t s   //
// ----------------- //

object__struct = {
    "active":                0x76,  // word
    "num collided objects":  0x74,  // word
    "collided object 1":     0x78,  // dword (pointer to object)
    "collided object 2":     0x7c,  // dword (pointer to object)
    "collided object 3":     0x80,  // dword (pointer to object)
    "collided object 4":     0x84,  // dword (pointer to object)
    "eyerok hands remaining":0xf8,  // dword
    "action":               0x14c,  // dword
    "hp":                   0x184,  // dword
    "behaviour script":     0x20c,  // dword
}
object__sizeof = 0x260

// these checks gotta be unique
// also, just do simple offset checks, no more nested pointers...
function bhv_cmd_check_meta(offset, type, value) => {"offset": offset, "type": type, "value": value}
object_behavior_checks = {
    "bowser 3":     bhv_cmd_check_meta(0x74, "dword", 0x802b75a4),
    "king bob-omb": bhv_cmd_check_meta(0x58, "dword", 0x802a8064),
    "real baby penguin": bhv_cmd_check_meta(0x4c, "dword", 0x802bfa88),
    "blue coin block":   bhv_cmd_check_meta(0x18, "dword", 0x802c2404),
    "king whomp":        bhv_cmd_check_meta(0x10, "dword", 0x13002bd4),
    "koopa the quick flag": bhv_cmd_check_meta(0x24, "dword", 0x06001028),
    "eyerok manager":       bhv_cmd_check_meta(0x14, "dword", 0x8030ea9c),
}

//behaviour_script__values = {
//    "king bob-omb":             0x800eb374,
//    "bowser 3":                 0x800ec9d0,
//    "real baby penguin":        0x800ed268,
//    "blue coin block":          0x800ed6e8,
//    "king whomp":               0x800edd38,
//    //"secret star spawner":      0x800ef05c,
//    "koopa the quick flag":     0x800ef778,
//    "eyerok manager":           0x800f0434,
//    "file select background":   0x8008fcf0,
//}

function object_is_active(addr) => word(object_field(addr, "active")) == 0x0101
function object_was_active(addr) => prev(word(object_field(addr, "active"))) == 0x0101
function object_just_deactivated(addr) => object_was_active(addr) && !object_active(addr)

function object_behav_script(addr) => tbyte(object_field(addr, "behaviour script"))
//function object_is(addr, name) => dword(object_field(addr, "behaviour script")) == behaviour_script__values[name]

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

function object_num_collided_objects(addr) => word(object_field(addr, "num collided objects"))
function object_nth_collided_object(addr, n) => tbyte(object_field(addr, format("collided object {0}", n)))

function object_action(addr) => dword(object_field(addr, "action"))

// object specific
function object_king_whomp_hp(addr) => dword(object_field(addr, "hp"))
function object_king_bobomb_hp(addr) => dword(object_field(addr, "hp"))
function object_bowser_hp(addr) => dword(object_field(addr, "hp"))

function object_king_bobomb_fight_started(addr) => prev(object_action(addr)) == 0 && object_action(addr) == 2
// we don't need to consider if the fight ended, as there is almost no height variation in the boss arena

function object_eyerok_fight_started(addr) => prev(object_action(addr)) == 2 && object_action(addr) == 3

function object_eyerok_hands_remaining(addr) => dword(object_field(addr, "eyerok hands remaining"))

// --------------------------- //
//   o b j e c t   a r r a y   //
// --------------------------- //

object_array__addr = 0x33d488

function nth_array_object(index) => object_array__addr + (index * object__sizeof)

function array_object_index_is(obj_addr, index) => ((obj_addr - object_array__addr) / object__sizeof) == index

function array_object_is_active(index) => object_is_active(nth_array_object(index))
function array_object_was_active(index) => object_was_active(nth_array_object(index))
function array_object_just_deactivated(index) => array_object_was_active(index) && !array_object_is_active(index)

function array_object_is(index, name) => object_is(nth_array_object(index), name)

function array_object_num_collided_objects(index)   => object_num_collided_objects(nth_array_object(index))
function array_object_nth_collided_object(index, n) => object_nth_collided_object(nth_array_object(index), n)

function array_object_action(index) => object_action(nth_array_object(index))

function array_object_king_bobomb_hp(index) => object_king_bobomb_hp(nth_array_object(index))
function array_object_king_bobomb_fight_started(index) => object_king_bobomb_fight_started(nth_array_object(index))

object_indexes = { // try to only use this as a fallback, as this can change between updates...
    "Key 1": {"King Bob-omb": 4}
}

// 
// Other Achievements (all course stars are above...)
//

// gimme

achievement(
    title="The Switch Gives Me Sight",
    description="Stand on a blue coin switch for 5 seconds and observe your surroundings.",
    points=1,
    trigger=never(!object_is(stood_on_object(), "blue coin block")) && trigger_when(repeated(int_seconds_to_frames(5)*2, always_true())),
    id=190519,
    badge="211388"
)

// m i l e s t o n e s

function star_milestone_trigger(num_stars) {
    return measured(nof_stars() == num_stars, when=!in_title_or_file_select())
        && prev(nof_stars()) == num_stars - 1
        && level_id__mem == prev(level_id__mem) // to prevent switching files after the ending picture puts you back to the title screen...
}

achievement(
    title="Beep Beep Beep",
    description="Get your first transmission after collecting one star.",
    points=1,
    trigger=nof_stars() == 1 && dialog_id_is("1 Star Message"),
    id=190508,
    badge="211377"
)

achievement(
    title="Bowser's First Landmark",
    description="Collect 15 stars in New Earth to gain access to Bowser's Skyscrapers.",
    points=5,
    trigger=star_milestone_trigger(15),
    id=190509,
    badge="211378"
)

achievement(
    title="Bowser's Not Here...",
    description="Collect the first key in Bowser's Skyscrapers.",
    points=5,
    trigger=in_level("Key 1") && mario_anim_is("star dance ground (no exit)"),
    id=190520,
    badge="211389"
)

achievement(
    title="Another Retro Castle?",
    description="Collect 50 stars in New Earth to gain access to the vanish cap and Bowser's Retro Castle.",
    points=5,
    trigger=star_milestone_trigger(50),
    id=190510,
    badge="211379"
)

achievement(
    title="Bully Beatdown",
    description="Collect the second key in Bowser's Retro Castle.",
    points=10,
    trigger=in_level("Key 2") && mario_anim_is("star dance ground (no exit)"),
    id=190521,
    badge="211390"
)

achievement(
    title="To the Secret Hideout",
    description="Collect 70 stars in New Earth to gain access to Bowser's final landmark, his Fransium Factory.",
    points=10,
    trigger=star_milestone_trigger(70),
    id=190511,
    badge="211380"
)

achievement(
    title="New President of New Earth",
    description="Collect the star in the happy ending after defeating Bowser.",
    points=25,
    trigger=in_level("Happy End") && mario_anim_is("star dance ground (no exit)"),
    id=190522,
    badge="211391"
)

achievement(
    title="The Final Landmarks",
    description="Collet 90 stars in New Earth to gain access to Earth Skies.",
    points=10,
    trigger=star_milestone_trigger(90),
    id=190512,
    badge="211381"
)

achievement(
    title="Forbidden Door",
    description="Collect 123 stars in New Earth to open the door in Forbidden Reality. You will need every secret star so far...",
    points=25,
    trigger=star_milestone_trigger(123),
    id=190513,
    badge="211382"
)

achievement(
    title="To Be Continued",
    description="Collect all 125 stars in New Earth.",
    points=25,
    trigger=star_milestone_trigger(125),
    id=190505,
    badge="211374"
)

achievement(
    title="Pixel's Monologue",
    description="Read through Pixel's sign in their Magmatic Cavern after getting every star in New Earth.",
    points=1,
    trigger=in_level("Metal Cap") && dialog_just_ended("Pixel's Sign"),
    id=190514,
    badge="211383"
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
    title = "Completionist Switches",
    description = "Press the red, green, and blue !-switches.",
    points = 5,
    trigger = rgb_trigger(),
    id=190497, 
    badge="211366"
)

//
// challenges
//
achievement(
    title="Nice Star Placements",
    description="In Course 1, collect 4 stars while wearing only one wing cap. Counter resets when you leave, your wing cap runs out, or you get another wing cap.",
    points=4,
    trigger=never(!in_level("Course 1")) && never(wearing_wing_cap() == 0)
        && never(prev(wearing_wing_cap()) == 1 && cap_time() > prev(cap_time())) // grabbed another wing cap
    
        && (trigger_when(tally(4, collected_any_star_on_star_grab_arr))
        || measured(tally(4, collected_any_star_on_star_grab_arr), when=in_level("Course 1"))),
    id=190515,
    badge="211384"
)

achievement(
    title="Mining Metal Mario",
    description="In Course 2, collect the star in the salt mines while still wearing your metal cap.",
    points=5,
    trigger=in_level("Course 2") && wearing_metal_cap() == 1
        && trigger_when(prev(wearing_metal_cap()) == 1 && last_star__mem == 3)
        && (trigger_when(mario_anim_changed_to("star grab fall")) || trigger_when(mario_anim_changed_to("star dance ground (no exit)"))),
    id=190523,
    badge="211392"
)

achievement(
    title="Superstitious Sparklies",
    description="In Course 3, collect the secrets star without ever stepping on the sand (Re-enter Course 3 to try again).",
    points=4,
    trigger= never(!in_level("Course 3")) && once(in_level("Overworld 1", delta=1)) && sublevel_id__mem == 2 // death warp in eyerok area takes you back outside the pyramid
        && never(sublevel_id__mem == 2 && pos_y() >= 0xC1C00000) // y is <= -24, -24 is the quicksand floor in the secrets area of c3
        && trigger_when(just_collected_star_no_exit(5)),
    id=190506,
    badge="211375"
)

achievement(
    title="Good Old Damageless",
    description="In Course 4, defeat Star Whomp without taking damage during the fight.",
    points=5,
    trigger= never(!in_level("Course 4")) && once(dialog_just_ended("Whomp Fight Start"))
        && never(hp() < prev(hp())) // no water damage to take...
        && never(boss_music_ended()) // boss music persists through defeat quote...
        && (trigger_when(object_is(used_object(), "king whomp") // there are no other objects in the boss arena that appear to update this used object...
            && prev(object_king_whomp_hp(used_object())) == 1
            && object_king_whomp_hp(used_object()) == 0)
        || trigger_when(dialog_id_is("Whomp Fight Defeat"))),
    id=190507,
    badge="211376"
)

achievement(
    title="No Need for That",
    description="In Course 5, collect the 100 coin star without pressing the blue coin switch or dying.",
    points=5,
    trigger= never(!in_level("Course 5")) && once(in_level("Overworld 1", delta=1))
        && never(object_is(stood_on_object(), "blue coin block") && mario_anim_is("ground pound landing"))
        && never(mario_anim_is("death exit landing"))
        && just_collected_star_general(star_index=7, trigger=1),
    id=190525,
    badge="211394"
)

achievement(
    title="Ghostly Sprint to the Top",
    description="In Course 6, collect the star on top of the ship while still wearing your vanish cap.",
    points=5,
    trigger= in_level("Course 6") && wearing_vanish_cap() == 1
        && trigger_when(prev(wearing_vanish_cap()) == 1 && last_star__mem == 3)
        && (trigger_when(mario_anim_changed_to("star grab fall")) || trigger_when(mario_anim_changed_to("star dance ground (no exit)"))),
    id=190526,
    badge="211395"
)

achievement(
    title="Grounded Log Rolling Reds",
    description="In Course 7, collect the red coin star without dying or pressing the A button throughout the entire stage.",
    points=10,
    trigger= never(!in_level("Course 7")) && once(in_level("Overworld 2", check_sublevels=0, delta=1))
        && never(mario_anim_is("death exit landing"))
        && never(controller_a_button() != 0)
        && trigger_when(just_collected_star_no_exit(2)),
    id=190503,
    badge="211372"
)

achievement(
    title="Good Old Damageless, Again",
    description="In Course 8, collect the secrets star in the cave without dying or taking damage throughout the entire stage.",
    points=5,
    trigger= never(!in_level("Course 8")) && once(in_level("Overworld 2", check_sublevels=0, delta=1))
        && never(mario_anim_is("death exit landing"))
        && never(hp() < prev(hp())) // no water to worry about...
        && trigger_when(just_collected_star_no_exit(2)),
    id=190527,
    badge="211396"
)

achievement(
    title="Sticky Hands",
    description="In Course 9, escort the baby penguin to its mother without ever letting it go.",
    points=5,
    trigger= never(!in_level("Course 9")) && never(sublevel_id__mem != 1) && once(in_level("Overworld 2", check_sublevels=0, delta=1) || prev(sublevel_id__mem) != 1)
        && never(object_is(prev(held_object()), "real baby penguin") && prev(held_object()) != held_object())
        && trigger_when(dialog_id_is("Penguin Escort Finish")),
    id=190528,
    badge="211397"
)

achievement(
    title="Nature Preservation",
    description="In Course 10, collect star 3 without ever grabbing a tree (Re-enter Course 10 to try again).",
    points=4,
    trigger= never(!in_level("Course 10")) && once(!in_level("Course 10", delta=1))
        && never(on_pole())
        && trigger_when(just_collected_star_no_exit(3)),
    id=190524,
    badge="211393"
)

// c'mon RATools, don't optimize out the ResetNextIf ffs
got_one_red = nof_coins() == prev(nof_coins()) + 2
function course_11_challenge_trigger() {
    entered_c11 = never(!in_level("Course 11")) && once(in_level("Overworld 3", check_sublevels=0, delta=1))
    transition_is_star_fadeout = transition_type__mem == TRANSITION_STAR_FADE_OUT
    y_check_positive = pos_y() <  0x437a0000 // 0 < y < 250
    y_check_negative = pos_y() >= 0x80000000 // y <= 0 note: 0x80000000 exactly = "-0.0"
    
    return (entered_c11
        && trigger_when(just_collected_star_no_exit(3)) 
        && disable_when(repeated(2, transition_is_star_fadeout), until=got_one_red || !in_level("Course 11"))
        && never(!transition_active() && !airborne() && (y_check_positive || y_check_negative))
        && never(butt_slide_bounced() && (y_check_positive || y_check_negative))
        && never(slide_kick_bounced() && (y_check_positive || y_check_negative))
        // if either of the last 2 resets hit, then you must've bounced off the ground, 
        // or bounced on one of the boxes and fell too low to recover
        )
        
    // cannot check floor footstep because the roofs count as sand...
}

achievement(
    title="The Floor is Quicksand",
    description="In Course 11, collect all 8 red coins and the star without touching the ground after getting the first red.",
    points=10,
    trigger = course_11_challenge_trigger(),
    id=190498,
    badge="211367"
)

achievement(
    title="Dicey Secrets Flight",
    description="In Course 12, collect the secrets star without refreshing your wing cap (Re-enter Course 12 to try again).",
    points=5,
    trigger=never(!in_level("Course 12")) && once(in_level("Overworld 3", check_sublevels=0, delta=1))
        && never(mario_anim_is("death exit landing")) 
        && never(prev(wearing_wing_cap()) == 1 && cap_time() > prev(cap_time())) // grabbed a new wing cap while wearing one
        && never(repeated(2, prev(wearing_wing_cap()) == 0 && wearing_wing_cap() == 1)) // grabbed 2 separate wing caps while previously not wearing one
        && trigger_when(just_collected_star_no_exit(5)),
    id=190529,
    badge="211398"
)

achievement(
    title="Low Moves for Simulated Sparklies",
    description="In Course 13, collect the secrets star using only a single A press throughout the entire stage.",
    points=10,
    trigger = never(!in_level("Course 13")) && once(in_level("Overworld 3", check_sublevels=0, delta=1))
        && never(repeated(2, just_increased(controller_a_button())))
        && trigger_when(just_collected_star_no_exit(2)),
    id=190504,
    badge="211373"
)

achievement(
    title = "This Gauntlet's Just a Warm-Up",
    description = "Enter Course 15 from Course 14, and collect any 4 stars without dying or exiting the level.",
    points=10,
    trigger=never(!in_level("Course 15")) && once(in_level("Course 14", delta=1))
        && never(mario_anim_is("death exit landing")) 
        && (trigger_when(tally(4, collected_any_star_on_star_dance_arr))
        || measured(tally(4, collected_any_star_on_star_dance_arr))),
    id=190499, 
    badge="211368"
)

achievement(
    title="All These Boxes Are Unnecessary",
    description="In Pixel's Magmatic Cavern, collect the red coin star without picking up a metal cap or dying.",
    points=10,
    trigger=never(!in_level("Metal Cap")) && once(in_level("Course 2", delta=1))
        && never(wearing_metal_cap() == 1)
        && never(mario_anim_is("death exit landing"))
        && trigger_when(just_collected_star_no_exit(1)),
    id=190516,
    badge="211385"
)

achievement(
    title="All but One of These Boxes are Unnecessary",
    description="In Thick Cloud Station, collect the red coin star without dying or picking up more than one wing cap.",
    points=10,
    trigger=never(!in_level("Wing Cap")) && once(in_level("Course 4", delta=1))
        && never(mario_anim_is("death exit landing")) 
        && never(prev(wearing_wing_cap()) == 1 && cap_time() > prev(cap_time())) // grabbed a new wing cap while wearing one
        && never(repeated(2, prev(wearing_wing_cap()) == 0 && wearing_wing_cap() == 1)) // grabbed 2 separate wing caps while previously not wearing one
        && trigger_when(just_collected_star_no_exit(2)),
    id=190530,
    badge="211399"
)

achievement(
    title="Yet Another Cap Sprint",
    description="In Library Dimension, while wearing your vanish cap, collect the red coin behind the blue switch.",
    points=5,
    trigger=never(!in_level("Vanish Cap")) && once(in_level("Course 10", delta=1))
        && never(wearing_vanish_cap() == 0
            && pos_y() >= 0x45608000 && pos_y() < 0x80000000 // 3592, the red coin in question is the highest at y=3848
            && got_one_red)
        && trigger_when(wearing_vanish_cap() == 1 
            && pos_y() >= 0x45608000 && pos_y() < 0x80000000
            && got_one_red),
    id=190531,
    badge="211400"
)

achievement(
    title="Potentially Useful Cap Combination",
    description="In Tricky Temple Trials, collect the first star while wearing both metal and vanish caps.",
    points=5,
    trigger= in_level("Trials") && wearing_vanish_cap() == 1 && wearing_metal_cap() == 1
        && trigger_when(prev(wearing_vanish_cap()) == 1 && prev(wearing_metal_cap()) == 1 && last_star__mem == 1)
        && (trigger_when(mario_anim_changed_to("star grab fall")) || trigger_when(mario_anim_changed_to("star dance ground (no exit)"))),
    id=190532,
    badge="211401"
)

achievement(
    title="Good Old Damageless, the Third Time",
    description="In Bowser's Retro Castle, collect the red coin star without taking damage for the entire stage.",
    points=10,
    trigger= never(!in_level("Bowser 2")) && once(!in_level("Bowser 2", delta=1))
        && never(hp() < prev(hp()))
        && trigger_when(just_collected_star_no_exit(1)),
    id=190533,
    badge="211402"
)

bowser = used_object() // nothing else changes used object

achievement(
    title="Good Old Damageless, the Fourth Time",
    description="Defeat Bowser without taking damage.",
    points=10,
    trigger= never(!in_level("Final Fight")) && once(in_level("Bowser 3", delta=1))
        && never(hp() < prev(hp()))
        && trigger_when(object_is(bowser, "bowser 3")
        && prev(object_bowser_hp(bowser)) == 1 && object_bowser_hp(bowser) == 0),
    id=190534,
    badge="211403"
)

achievement(
    title = "Loose Change in The Void",
    description = "Collect 66 coins in The Void.",
    points=10,
    trigger=in_level("The Void")
        && (trigger_when(nof_coins() >= 66)
        || measured(nof_coins() >= 66, when=in_level("The Void"))),
    id=190500,
    badge="211369"
)

// Race Achievements

// just to remove the dependency of needing to wait for Koopa the Quick, for better reset efficiency :>
function trigger_when_collided_with_flag() {
    flag_cond = always_false()
    
    for i in range(1,4) {
        obj_addr = object_nth_collided_object(mario_object(), i)
        flag_cond = flag_cond || 
        (
            trigger_when(
            object_num_collided_objects(mario_object()) >= i // collided objects are stale, gotta check if collision is really active with this...
            && obj_addr == prev(obj_addr)
            && object_is(obj_addr, "koopa the quick flag")
            )
        )
    }
    return flag_cond
}

achievement(
    title="Poly-Hued Sprint",
    description="In Course 1, finish the race with Koopa the Quick in under 24 seconds (touch flag to trigger).",
    points=5,
    trigger=in_level("Course 1") && hud_timer__mem != 0 && hud_timer__mem < int_seconds_to_frames(24)
        && trigger_when_collided_with_flag(),
    id=190501,
    badge="211370"
)

achievement(
    title="I Don't Need Anti-Quicksand Shoes",
    description="In Course 14, finish the race with Koopa the Quick in under 34 seconds (touch flag to trigger).",
    points=10,
    trigger=in_level("Course 14") && hud_timer__mem != 0 && hud_timer__mem < int_seconds_to_frames(34)
        && trigger_when_collided_with_flag(),
    id=190502,
    badge="211371"
)

king_bobomb = object_indexes["Key 1"]["King Bob-omb"]

achievement(
    title="A Short-Fused Fight",
    description="Defeat King Bob-omb in under 30 seconds.",
    points=5,
    trigger=never(!in_level("Key 1")) && once(array_object_king_bobomb_fight_started(king_bobomb))
        && never(repeated(int_seconds_to_frames(30)*2, array_object_is(king_bobomb, "king bob-omb") && array_object_action(king_bobomb) > 0))
        // action 0 = idle
        && trigger_when(array_object_is(king_bobomb, "king bob-omb") && prev(array_object_king_bobomb_hp(king_bobomb)) == 1 && array_object_king_bobomb_hp(king_bobomb) == 0),
    id=190517,
    badge="211386"
)

leaderboard(
    title="King Bob-omb Quick Kill",
    description="Defeat King Bob-omb as fast as possible",
    start=in_level("Key 1") && array_object_king_bobomb_fight_started(king_bobomb),
    submit=array_object_is(king_bobomb, "king bob-omb") && prev(array_object_king_bobomb_hp(king_bobomb)) == 1 && array_object_king_bobomb_hp(king_bobomb) == 0,
    cancel=!in_level("Key 1"),
    value=measured(array_object_is(king_bobomb, "king bob-omb") && array_object_action(king_bobomb) > 0),
    format="FRAMES"
)

eyerok = used_object() // dynamic, the previous area shuffles the object indeces (damn sparklies)

achievement(
    title="Newrock Rumble",
    description="Defeat Newrock in under 30 seconds.",
    points=5,
    trigger=never(!in_level("Course 3")) && never(sublevel_id__mem != 4) && once(object_eyerok_fight_started(eyerok))
        && never(repeated(int_seconds_to_frames(30)*2, object_is(eyerok, "eyerok manager") && object_action(eyerok) > 2))
        && trigger_when(object_is(eyerok, "eyerok manager") && prev(object_eyerok_hands_remaining(eyerok)) == 1 && object_eyerok_hands_remaining(eyerok) == 0),
    id=190518,
    badge="211387"
)

leaderboard(
    title="Newrock Quick Kill",
    description="Defeat Newrock as fast as possible",
    start=in_level("Course 3") && sublevel_id__mem == 4 && object_eyerok_fight_started(eyerok),
    submit=object_is(eyerok, "eyerok manager") && prev(object_eyerok_hands_remaining(eyerok)) == 1 && object_eyerok_hands_remaining(eyerok) == 0,
    cancel=!in_level("Course 3") || sublevel_id__mem != 4,
    value=measured(object_is(eyerok, "eyerok manager") && object_action(eyerok) > 2),
    format="FRAMES"
)

// Race LB's

leaderboard(
    title="Colorful Race",
    description="Race with Koopa the Quick in Course 1: Poly-Hued Hills (talk to Koopa to submit)",
    start=in_level("Course 1") && just_changed_any(dialog_id__mem) && dialog_id_is("Koopa Race 1 Win"),
    cancel=always_false(),
    submit=always_true(),
    value=2*hud_timer__mem,
    format="FRAMES"
)

leaderboard(
    title="Quicksand Race",
    description="Race with Koopa the Quick in Course 14: Earth Skies (talk to Koopa to submit)",
    start=in_level("Course 14") && just_changed_any(dialog_id__mem) && dialog_id_is("Koopa Race 2 Win"),
    cancel=always_false(),
    submit=always_true(),
    value=2*hud_timer__mem,
    format="FRAMES"
)

// RP

general_level_dict = {
    0x10: "exploring the first overworld",
    
    0x09: "platforming on the Poly-Hued Hills",
    0x18: "digging up stars in the Underground Shafts",
    0x0C: "exploring the Red Ruby Desert",
    0x05: "looking for stars in Surreal Rainbow Fantasy",
    0x04: "busting some ghosts in Murky Haunted Village",
    0x07: "on vacation in Summer Island",
    0x16: "beating the heat in Blue Lava Lagoon",
    0x08: "exploring high up in the Mushroom Mountains",
    0x17: "fighting the cold in Shivering Snowland",
    0x0a: "doing some trials in the Ancient Earth Temple",
    0x0b: "paying a visit to the residents of Silent West",
    0x24: "exploring the remnants of Dice Town",
    0x0d: "on a digital adventure in Computer Simulation",
    0x0e: "at Earth Skies, the \'last\' stop",
    0x0f: "still collecting stars in Forbidden Reality",
    
    0x1f: "passing through the Tricky Temple Trials",
    0x1b: "taking the Ultimate Quiz",
    
    0x11: "taking on Bowser's Skyscrapers",
    0x1e: "fighting King Bob-omb in Bowser's Skyscrapers",
    0x13: "exploring the empty Bowser's Retro Castle",
    0x21: "fighting some bullies in Bowser's Retro Castle",
    0x15: "platforming in Bowser's Fransium Factory",
    0x22: "fighting Bowser in his Fransium Factory",
    
    0x1c: "traversing Pixel's Magmatic Cavern",
    0x1d: "flying through the Thick Cloud Station",
    0x12: "being a bookworm in Library Dimension",
    
    0x19: "at the ending screen",
    0x14: "on his final adventure in The Void",
}

level__lookup = rich_presence_lookup("LevelsWithoutSublevels", level_id__mem, general_level_dict, "in an unbeknownst location")

level_1a__lookup = rich_presence_lookup("Level1a", sublevel_id__mem, {
    0x01: "exploring the third overworld",
    0x02: "exploring the third overworld",
    0x03: "exploring the third overworld",
    0x04: "exploring the third overworld",
    0x05: "in the Warp Zone"
})

level_06__lookup = rich_presence_lookup("Level06", sublevel_id__mem, {
    0x01: "becoming the new President",
    0x02: "exploring the second overworld",
    0x03: "languishing in the destroyed universe"
})

stars__value = rich_presence_value("Number", nof_stars())

rich_presence_conditional_display(
    mem_in(level_id__mem, general_level_dict),
    "Mario is {0} of New Earth with {1}⭐ [🔴{2}] [🟢{3}] [🔵{4}]", level__lookup, stars__value,
        rich_presence_lookup("Switch", pressed_switch__mem("red"), {1:"▣"}, "▢"),
        rich_presence_lookup("Switch", pressed_switch__mem("green"), {1:"▣"}, "▢"),
        rich_presence_lookup("Switch", pressed_switch__mem("blue"), {1:"▣"}, "▢")
)
rich_presence_conditional_display(
    level_id__mem == 0x1a,
    "Mario is {0} of New Earth with {1}⭐ [🔴{2}] [🟢{3}] [🔵{4}]", level_1a__lookup, stars__value,
        rich_presence_lookup("Switch", pressed_switch__mem("red"), {1:"▣"}, "▢"),
        rich_presence_lookup("Switch", pressed_switch__mem("green"), {1:"▣"}, "▢"),
        rich_presence_lookup("Switch", pressed_switch__mem("blue"), {1:"▣"}, "▢")
)
rich_presence_conditional_display(
    level_id__mem == 0x06,
    "Mario is {0} of New Earth with {1}⭐ [🔴{2}] [🟢{3}] [🔵{4}]", level_06__lookup, stars__value,
        rich_presence_lookup("Switch", pressed_switch__mem("red"), {1:"▣"}, "▢"),
        rich_presence_lookup("Switch", pressed_switch__mem("green"), {1:"▣"}, "▢"),
        rich_presence_lookup("Switch", pressed_switch__mem("blue"), {1:"▣"}, "▢")
)
rich_presence_display("Mario is getting ready for an adventure on New Earth")