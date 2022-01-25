// ~Hack~ Speed Star Adventure
// #ID = 16766

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
function just_changed_from(mem, from) => prev(mem) == from && mem != from

function struct_field(struct_def, base, field) => base + struct_def[field]

function object_field(base, field) => struct_field(object__struct, base, field)

// ---------------
//   m e m o r y
// ---------------

mario_action__addr = 0x33b17c
mario_action__mem = dword(mario_action__addr)

mario_prev_action__addr = 0x33b180
mario_prev_action__mem  = dword(mario_prev_action__addr)

mario_action__values = {
    "uninitialized":               0x00000000,
    //"star dance ground (exit)":    0x00001302,
    //"star dance water":            0x00001303,
    //"star dance ground (no exit)": 0x00001307,
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

function mario_action_is(name) => mario_action__mem == mario_action__values[name]
function mario_prev_action_is(name) => mario_prev_action__mem == mario_action__values[name]

function mario_action_changed_to(name) {
    return prev(mario_action__mem) != mario_action__values[name]
        && mario_action__mem == mario_action__values[name]
}

function airborne() => bit3(mario_action__addr + 1) != 0
function on_pole() => bit4(mario_action__addr + 2) != 0

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
    "nof stars":          0xa8,  // word, NOT HUD
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

function pos_x() => dword(mario_field("x"))
function pos_y() => dword(mario_field("y"))
function pos_z() => dword(mario_field("z"))

function interaction_object() => tbyte(mario_field("interaction object"))
function held_object() => tbyte(mario_field("held object"))
function used_object()  => tbyte(mario_field("used object"))
function mario_object() => tbyte(mario_field("mario object"))
function stood_on_object() => tbyte(stood_on_object__addr)

function hp_int() => byte(mario_field("hp") + 1)
function hp_dec() => byte(mario_field("hp dec"))
function just_took_damage() => prev(hp()) > hp()

function hp() => word(mario_field("hp"))

function cap_time() => word(mario_field("cap timer"))

function nof_stars() => word(mario_field("nof stars"))
function nof_coins() => word(mario_field("nof coins"))

// ----------------- //
//   o b j e c t s   //
// ----------------- //

object__struct = {
    "animation":             0x3A,  // word (NEW)
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

behaviour_script__values = {
    "bowser 3":                 0x800ec9d0,
    "deployment box":           0x8010ad68, // same as vanilla grabbable cork box
    "lightning platform":       0x80406800,
    "propeller lift":          0x8040a500,
}

function object_is_active(addr) => word(object_field(addr, "active")) == 0x0101
function object_was_active(addr) => prev(word(object_field(addr, "active"))) == 0x0101
function object_just_deactivated(addr) => object_was_active(addr) && !object_active(addr)

function object_is(addr, name) => dword(object_field(addr, "behaviour script")) == behaviour_script__values[name]

function object_num_collided_objects(addr) => word(object_field(addr, "num collided objects"))
function object_nth_collided_object(addr, n) => tbyte(object_field(addr, format("collided object {0}", n)))

function object_anim(addr) => word(object_field(addr, "animation"))
function object_action(addr) => dword(object_field(addr, "action"))

// object specific
function object_bowser_hp(addr) => dword(object_field(addr, "hp"))

// Mario Object specific stuff

// watch out for animation value collisions (ex: airborne spawn and falling out of water both use general fall, 0x56)
mario_anim__values = {
    "Water Star Dance": 0xB3,
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
    if (star_index != -1)
        return cond && trigger_when(last_star__mem == star_index)
    return cond
}

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

function array_object_bowser_hp(index) => object_bowser_hp(nth_array_object(index))

object_indexes = { // try to only use this as a fallback, as this can change between updates...
    "Bowser Fight": {"Bowser": 1}
}

// ---------------
//   m e m o r y
// ---------------

// scripts (scut's advanced text engine)

current_script_ptr__addr = 0x7f6d68
current_script_ptr__mem = dword(current_script_ptr__addr)

script__values = {
    "File Select": 0x80409400,
    
    "Dorrie": {
        "Royal Blue":   0x80720000,
        "Orange":       0x80720A00,
        "Pink":         0x80720D00,
        "Pink2":        0x80721240,
        "Yellow":       0x80721E00,
        "Blue":         0x80721B00,
        "Purple":       0x80722200,
        "Orange2":      0x80722B00,
        "Gray":         0x80722F00,
        "Dark Blue":    0x80723250,    
        "Black":        0x80723600,
        "Green":        0x80723B00,
    }
}

function script_is(name, nested1="NULL", delta="f") {
    script_mem = current_script_ptr__mem
    if (delta == "true")
        script_mem = prev(script_mem)

    if (nested1 != "NULL")
        return script_mem == script__values[name][nested1]
    return script_mem == script__values[name]
}

// general m64 memory

hud_flags__addr = 0x33b268

function hud_stars_on() => bit2(hud_flags__addr) != 0

function picked_a_file() => repeated(30, hud_stars_on())

file_num__addr = 0x32ddf6
file_num__mem = byte(file_num__addr)

save_data_base__addr = 0x207690
function current_file_data() => save_data_base__addr + 0x70 * file_num__mem

function pressed_switch__mem(color, delta="f"){
    current_file__mem = current_file_data()
    switch_mem = always_false
    if color == "red"
        switch_mem = bit1(current_file__mem + 8)
    else if color == "green"
        switch_mem = bit2(current_file__mem + 8)
    else if color == "blue"
        switch_mem = bit3(current_file__mem + 8)
     
    if delta == "true"
        return prev(switch_mem)
    else
        return switch_mem
}

function pressed_switch(color, delta){
    return pressed_switch__mem(color, delta) == 1
}

mission_id__addr = 0x1a81a3
mission_id__mem = byte(mission_id__addr)

// normal starts = 1-6; 100 coin star = 7
last_star__addr = 0x32dd87
last_star__mem = byte(last_star__addr)

sublevel_id__addr = 0x33b249
sublevel_id__mem  = byte(sublevel_id__addr)

level_id__addr = 0x32ddfa
level_id__mem = byte(level_id__addr)

function course_meta(value, sublevel_values, full_name) => {"value": value, "sublevel values": sublevel_values, "full name": full_name}

course_infos = {
    "Overworld":      course_meta(0x10, -1,       "The Overworld"), // Castle Grounds
    
    "Course 1":         course_meta(0x09, -1,   "Water Land"),
    "Course 2":         course_meta(0x18, -1,   "Grass Land"),
    "Course 3":         course_meta(0x0c, -1,   "Snow Land"),
    "Course 4":         course_meta(0x05, -1,   "Sand Land"),
    "Course 5":         course_meta(0x04, -1,   "Fire Land"),
    "Course 6":         course_meta(0x07, -1,   "Space Land"),
    "Course 7":         course_meta(0x16, -1,   "Flower Land"),
    "Course 8":         course_meta(0x08, -1,   "Water Future"),
    "Course 9":         course_meta(0x17, -1,   "Grass Future"),
    "Course 10":        course_meta(0x0a, -1,   "Snow Future"),
    "Course 11":        course_meta(0x0b, -1,   "Sand Future"),
    "Course 12":        course_meta(0x24, -1,   "Fire Future"),
    "Course 13":        course_meta(0x0d, -1,   "Space Future"),
    "Course 14":        course_meta(0x0e, -1,   "Flower Future"),
    "Course 15":        course_meta(0x0f, -1,   "Colorless Fortress"),

    "Bowser Fight":     course_meta(0x22, -1,   "Colorless Fortress"),
    
    "End Cake Picture": course_meta(0x19, -1,   "The End"),
    
    "Shop":             course_meta(0x14, -1,   "The Shop"), // Aquarium
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
    if course_infos[name]["sublevel values"] == -1 {return always_true()}
    return any_of(course_infos[name]["sublevel values"], a => sublevel_id__mem == a)
}

function just_entered_level(name) => just_changed_to(level_id__mem, course_infos[name]["value"]) && in_sublevel(name) 
function remained_in_level(name) => never(!in_level(name)) && once(prev(level_id__mem) != course_infos[name]["value"])

function course_stars_meta(save_offset, points, title, id=0, badge="0") => {"save offset": save_offset, "points": points, "title": title, "id": id, "badge": badge}

course_offsets = { // bytes offset from start of EEPROM, handle secret stars separately...
    1:  course_stars_meta(0x0f, 5, "Proficient with Jump Kick Boxes"   ),
    2:  course_stars_meta(0x0e, 5, "Proficient with Launch Pads"   ),
    3:  course_stars_meta(0x0d, 5, "Proficient with A Boxes"   ),
    4:  course_stars_meta(0x0c, 5, "Proficient with Switch Boxes"   ),
    5:  course_stars_meta(0x13, 5, "Proficient with Slingshots"   ),
    6:  course_stars_meta(0x12, 5, "Proficient with Rotate Blocks"   ),
    7:  course_stars_meta(0x11, 5, "Proficient with Bounce Balloons"   ),
    8:  course_stars_meta(0x10, 5, "Proficient with Charge Cannons"   ),
    9:  course_stars_meta(0x17, 5, "Proficient with Propeller Lifts"   ),
    10: course_stars_meta(0x16, 5, "Proficient with Air Bubbles"   ),
    11: course_stars_meta(0x15, 5, "Proficient with Mirror Rings"   ),
    12: course_stars_meta(0x14, 5, "Proficient with Spinning Flowers"         ),
    13: course_stars_meta(0x1b, 5, "Proficient with Deployment Boxes"         ),
    14: course_stars_meta(0x1a, 5, "Proficient with Lightning Platforms"   ),
    15: course_stars_meta(0x19,10, "Master of Custom Objects"      ),
}

function course_stars_count(course_num, is_delta) {
    off = current_file_data() + course_offsets[course_num]["save offset"]
    mem = bit0(off) + bit1(off)
    if is_delta == "True"
        return prev(mem)
    return mem
}

for num in course_offsets {
    tot = 2
    course_info = course_infos[format("Course {0}", num)]
    achievement(
        title = course_offsets[num]["title"],
        description = format("Collect both stars in {0}.", course_info["full name"]),
        points = course_offsets[num]["points"],
        trigger = in_level(format("Course {0}", num))        
            && course_stars_count(num, "True") == tot - 1
            && measured(course_stars_count(num, "False") == tot)
    )
}

// 
// Other Achievements (all course stars are above...)
//

// m i l e s t o n e s

achievement(
    title = "Scuttlebug's Bargain",
    description = "Buy the wing cap block from scuttlebug after collecting 15 stars to show your appreciation for their hack.",
    points = 5,
    trigger = level_id__mem == prev(level_id__mem) && in_level("Shop")
        && pressed_switch__mem("red", delta="true") == 0
        && pressed_switch__mem("red", delta="f") == 1
        && measured(nof_stars() >= 15, when=picked_a_file())
)

achievement(
    title="End of the Dorrie Adventure",
    description="Defeat Bowser and save the universes from his evil influence.",
    points=10,
    trigger=in_level("End Cake Picture")
        && trigger_when(tally(300, in_level("End Cake Picture"))) // some timing so the screenshot happens when the dorrie pic is fully faded in
)

//
// challenges
//

achievement(
    title="I Don't Need Your Gimmick",
    description="In Water Land, collect the red coin star without jump kicking.",
    points=5,
    trigger=    remained_in_level("Course 1")
        && never(mario_action_is("air kick"))
        && mission_id__mem == 0
        && just_collected_star(1, trigger=1)
)

achievement(
    title="No Companion Cubes Needed",
    description="In Space Future, collect the second star without grabbing a deployment box.",
    points=10,
    trigger=    remained_in_level("Course 13")
        && never(object_is(held_object(), "deployment box"))
        && mission_id__mem == 1
        && just_collected_star(2, trigger=1)
)

achievement(
    title="Lightning Evader",
    description="In Flower Future, collect the second star without stepping on a lightning platform.",
    points=5,
    trigger=    remained_in_level("Course 14")
        && never(object_is(stood_on_object(), "lightning platform"))
        && mission_id__mem == 1
        && just_collected_star(2, trigger=1)
)

got_one_red = nof_coins() == prev(nof_coins()) + 2

achievement(
    title="I Have Other Movement Options",
    description="In Colorless Fortress, collect the red coin star without grabbing a propeller lift or leaving the red coin area. (Re-enter Colorless Fortress to try again.)",
    points=10,
    trigger=    remained_in_level("Course 15")
        && sublevel_id__mem == 2
        && never(just_changed_from(sublevel_id__mem, 2)) // exited red coin area (from death)
        && never(sublevel_id__mem == 2 && object_is(interaction_object(), "propeller lift"))
        && just_collected_star(2, trigger=1)
        //&& tally(8, got_one_red)
)

bowser = nth_array_object(object_indexes["Bowser Fight"]["Bowser"])

achievement(
    title="Beat You Anyway, No Throws Needed",
    description="Defeat Bowser without taking damage.",
    points=10,
    trigger=    remained_in_level("Bowser Fight")
        && never(hp() < prev(hp()))
        && trigger_when(prev(object_bowser_hp(bowser)) == 1
            && object_bowser_hp(bowser) == 0)
)

achievement(
    title="No Coin Star Here",
    description="Collect 100 Dorrie coins in the overworld without leaving (Wing Cap allowed).",
    points=10,
    trigger=    never(!in_level("Overworld"))
        && measured(repeated(100, nof_coins() == prev(nof_coins()) + 1))
)

dorrie_tallies = []
for dorrie in script__values["Dorrie"] {
    array_push(dorrie_tallies, 
        once(just_changed_from(current_script_ptr__mem, script__values["Dorrie"][dorrie])))
}

achievement(
    title="Friendly Dorries",
    description="Talk to all 12 Dorries in the overworld (One session, entering levels allowed).",
    points=5,
    trigger= unless(!in_level("Overworld"))
        && measured(tally(12, dorrie_tallies))
)

// RP

general_level_dict = {
    0x10: "chilling with the Dorries in the overworld",
    
    0x09: "playing with Jump Kick Boxes in Water Land",
    0x18: "leaping on Jump Pads in Grass Land",
    0x0C: "platforming on 'A' Boxes in Snow Land",
    0x05: "navigating Switch Boxes in Sand Land",
    0x04: "flying with Slingshots in Fire Land",
    0x07: "traversing Rotate Platforms in Space Land",
    0x16: "bouncing on balloons in Flower Land",
    
    0x08: "blasting with Charge Cannons in Water Future",
    0x17: "getting lifts from propellers in Grass Future",
    0x0a: "escaping some Air Bubbles in Snow Future",
    0x0b: "figuring out how Mirror Rings work in Sand Future",
    0x24: "climbing with Spinning Flowers in Fire Future",
    0x0d: "deploying some box platforms in Space Future",
    0x0e: "riding Lightning Platforms in Flower Future",
    
    0x0f: "within Bowser's Colorless Fortress",
    0x22: "fighting Bowser in his big grey party palace",
    0x19: "at the ending scene after having beaten Bowser",

    0x14: "vistiting the scuttlebugs' empty shop",
}

level__lookup = rich_presence_lookup("LevelsActions", level_id__mem, general_level_dict, "in an unbeknownst location")

stars__value = rich_presence_value("Number", nof_stars())

rich_presence_conditional_display(
    picked_a_file(),
    "Mario is {0} with {1}⭐ [🔴{2}]", level__lookup, stars__value,
        rich_presence_lookup("Switch", pressed_switch__mem("red"), {1:"▣"}, "▢")
)
rich_presence_display("Mario beginning his adventure to the land of the Dorries.")