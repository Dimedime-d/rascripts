// ~Hack~ All Star Adventure: Extreme Edition
// #ID = 11581
// Made in RATools v1.10.2

// ------------- //
//   u t i l s   //
// ------------- //

function is_float_neg(mem) => mem > 0x80000000

function just_changed_any(mem) => mem != prev(mem)
function just_changed(mem, from, to) => prev(mem) == from && mem == to
function just_changed_to(mem, to) => prev(mem) != to && mem == to
function just_changed_from(mem, from) => prev(mem) == from && mem != from

function struct_field(struct_def, base, field) => base + struct_def[field]

function object_field(base, field) => struct_field(object__struct, base, field)

// ---------------
//   m e m o r y
// ---------------

mario_anim__addr = 0x33b17c
mario_anim__mem = dword(mario_anim__addr)
mario_anim__values = {
    "star dance ground (exit)":    0x00001302,
    "star dance water":            0x00001303,
    "star dance ground (no exit)": 0x00001307,
    "reading sign":                0x00001308,
    "star grab fall":              0x00001904,
    "airborne spawn":              0x00001924,
    "death respawn":               0x00001929,
    "lava boost":                  0x010208B7,
    
    "long jump":                   0x03000888, // slow or faste
}

function mario_anim_is(name) => mario_anim__mem == mario_anim__values[name]

function mario_anim_changed_to(name) {
    return prev(mario_anim__mem) != mario_anim__values[name]
        && mario_anim__mem == mario_anim__values[name]
}

function airborne() => bit3(mario_anim__addr + 1) != 0

fadeout_type__addr = 0x33b250
fadeout_type__mem = byte(fadeout_type__addr)

function death_fadeout() => fadeout_type__mem == 0x12 || fadeout_type__mem == 0x13

controller_input__addr = 0x367057

function controller_b_button() => bit6(controller_input__addr)

function swimming() => bit(5, mario_anim__addr + 1)

// ------------- //
//   m a r i o   //
// ------------- //

mario__struct = {
    "hat bitflags":       0x04,  // byte
    "x":                  0x3c,  // dword (float)
    "y":                  0x40,  // dword (float)
    "z":                  0x44,  // dword (float)
    "interaction object": 0x78,  // dword (pointer to object)
    "held object":        0x7C,  // dword (pointer to object)
    "mario object":       0x88,  // dword (pointer to object)
    "nof stars (hud)":    0xa8,  // word
    "hp":                 0xac,  // byte / word
    "hp inc":             0xb0,  // byte
    "hp dec":             0xb1,  // byte
    "cap timer":          0xb4,  // word
}

mario__addr = 0x33b170

function mario_field(field) => struct_field(mario__struct, mario__addr, field)

function wearing_wing_cap()   => bit3(mario_field("hat bitflags"))
function wearing_metal_cap()  => bit2(mario_field("hat bitflags"))
function wearing_vanish_cap() => bit1(mario_field("hat bitflags"))

function pos_x() => dword(mario_field("x"))
function pos_y() => dword(mario_field("y"))
function pos_z() => dword(mario_field("z"))

function pos_x_float() => float(mario_field("x"))
function pos_y_float() => float(mario_field("y"))
function pos_z_float() => float(mario_field("z"))

function held_object() => tbyte(mario_field("held object"))
function mario_object() => tbyte(mario_field("mario object"))

function hp_int() => byte(mario_field("hp") + 1)
function hp_dec() => byte(mario_field("hp dec"))
function just_took_damage() => prev(hp()) > hp()

function hp() => word(mario_field("hp"))

function cap_time() => word(mario_field("cap timer"))

function nof_stars() => word(mario_field("nof stars (hud)"))

// ---------------
//   m e m o r y
// ---------------

file_num__addr = 0x32ddf6
file_num__mem = byte(file_num__addr)

save_data_base__addr = 0x207698
function current_file_data() => save_data_base__addr + 0x70 * file_num__mem

function pressed_switch__mem(color, isDelta){
    current_file__mem = current_file_data()
    switch_mem = always_false
    if color == "red"
        switch_mem = bit1(current_file__mem)
    else if color == "green"
        switch_mem = bit2(current_file__mem)
    else if color == "blue"
        switch_mem = bit3(current_file__mem)
    else if color == "yellow"
        switch_mem = bit1(current_file_data() + 1)
     
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

sublevel_id__addr = 0x33b249
sublevel_id__mem  = byte(sublevel_id__addr)

level_id__addr = 0x33b24a
level_id__mem = byte(level_id__addr)
level_id__values = {
    "Overworld":    0x10,
    
    "Course 1":       0x09,
    "Course 2":       0x18,
    "Course 3":       0x0c,
    "Course 4":       0x05,
    "Course 5":       0x04,
    "Course 6":       0x07,
    
    "Caps":           0x1B,
    "Bowser Course":  0x11,
    "Boss Battle":    0x1C, //Metal Cap
    "The End":        0x1D, //Wing Cap
    "End Cake":       0x19,
}

function level_changed() => just_changed_any(level_id__mem)

function in_level(name) => level_id__mem == level_id__values[name]
function in_level_(name) => byte(0x32ddfa) == level_id__values[name]
function just_entered_level(name) => just_changed_to(level_id__mem, level_id__values[name])
function just_entered_level_from(to, from) => prev(level_id__mem) == level_id__values[to] && level_id__mem == level_id__values[from]

function level_names(short, full) => { "short": short, "full": full }
level_names = {
    "Course 1":       "Dried Out Harbor",
    "Course 2":       "Hovering Sunrise Village",
    "Course 3":       "Valley of Rememberance",
    "Course 4":       "Kingdom of Immortality",
    "Course 5":       "Aerial Flying Acropolis",
    "Course 6":       "Abstraction of Time and Will",

    "Caps":           "Cap Switch Triathlon",
    "Bowser Course":  "Desolated Outlet",
    "Boss Battle":    "Desolated Outlet",
    "The End":        "The End",
    "End Cake":       "End Cake Picture",
}

star_names = {
    "Course 1": ["Grassland Survivor"        , "Around the Ancient Fishing Reserve", "Ruined Scaffoldings",
                 "Rooftop Acrobatics"        , "Atop the Deserted Altar"           , "Abandoned Pier"     , "Lost Box of the Harbor"],
    "Course 2": ["Pillars and Hills"         , "Enchanted Road Parts Trip"         , "The Path of the Bullet Hell",
                 "Explore the Village Inside", "Reds Drowned in the Quicksand"     , "The Secret of the Old House"],
    "Course 3": ["Rooftop Darkness"          , "An Old Enemy's Resting Spot"       , "Deceiving Walls",
                 "Precise Wallkicking Test"  , "Journey to the Fiery Undergrounds" , "Conquer the Vicious Room", "Red Coins of a Forgotten Reality"],
    "Course 4": ["Speedy Spindrift"          , "Nice VSC at the End"               , "Blue-Brick Slope Fortress",
                 "Blue-Brick Ascension"      , "Lonely Secret"                     ],
    "Course 5": ["What's in a Pool?"         , "Sliding and Kicking"               , "Above the Water",
                 "Going up and Back Around"  , "Race Back near the Start!"         , "Whose Run is it Now?", "High-Finance Acropolis"],
    "Course 6": ["Unwillful Reason"          , "Doubtful Persistence"              , "Future Dogmatism",
                 "Painless Opposition"       , "Prehistoric Ignorance"             ],
}

function just_collected_star(level, star_index) {
    return in_level(level)
           && last_star__mem == star_index
           && (mario_anim_changed_to("star dance ground (exit)")
               || mario_anim_changed_to("star dance ground (no exit)")
               || mario_anim_changed_to("star dance water"))
}

function just_collected_star_plain(star_index) {   // ordinary collected star function is too complex for Trigger clause
    return last_star__mem == star_index
        && (mario_anim_changed_to("star dance ground (exit)"))
}

function just_touched_star_air(star_index) {
    return last_star__mem == star_index
        && mario_anim_changed_to("star grab fall")
}

dialog_id__addr = 0x331486
dialog_id__mem = word(dialog_id__addr)
dialog_id_overworld__values = {
    "Introduction": 0x02,
    "Bowser Entry": 0x08,
    
    "Cap Level Credits": 0x24,
    "Course 1 Credits": 0x2B,
    "Course 2 Credits": 0x2E,
    "Course 3 Credits": 0x27,
    "Course 4 Credits": 0x2A,
    "Course 5 Credits": 0x24,
    "Course 6 Credits": 0x23
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
    "behaviour script":     0x20c,  // dword
    "spawner num secrets":   0xf4,  // dword
}
object__sizeof = 0x260

behaviour_script__values = {
    "secret star spawner":    0x800ef05c,
    "file select background": 0x8008fcf0,
    
    "secret":                 0x8011C3DC,
    "red coin":               0x8011C36C,
    
    "chuckya":                0x801189E8,
}

function object_is_active(addr) => word(object_field(addr, "active")) == 0x0101
function object_was_active(addr) => prev(word(object_field(addr, "active"))) == 0x0101
function object_just_deactivated(addr) => object_was_active(addr) && !object_active(addr)

function object_behav_script(addr) => dword(object_field(addr, "behaviour script"))
function object_is(addr, name) => dword(object_field(addr, "behaviour script")) == behaviour_script__values[name]

function object_num_collided_objects(addr) => word(object_field(addr, "num collided objects"))
function object_nth_collided_object(addr, n) => tbyte(object_field(addr, format("collided object {0}", n)))

// object specific
function object_spawner_num_secrets(addr)  => dword(object_field(addr, "spawner num secrets"))

function mario_collision_check(obj_addr, obj_name, nth_collided) {
    return object_num_collided_objects(mario_object()) >= nth_collided
            && (
                (obj_addr != prev(obj_addr)) 
                || (object_behav_script(obj_addr) != prev(object_behav_script(obj_addr)))
                || (object_num_collided_objects(mario_object()) != prev(object_num_collided_objects(mario_object())))
               )
            && object_is(obj_addr, obj_name)
}

// field_checks is a dict of the form {object field, field value}
function collided_with_object(obj_name, count=1, field_checks={}, extra_logic=always_true()) {
    obj_tally = []
    for i in range(1,4) {
        obj_addr = object_nth_collided_object(mario_object(), i)
        
        coll_check = mario_collision_check(obj_addr, obj_name, i)
        
        if (length(field_checks) > 0)
            for field in field_checks {
                coll_check = coll_check && check_object_field(obj_addr, field, field_checks[field])
            }
        
        coll_check = coll_check && extra_logic
        array_push(obj_tally,
            repeated(count, coll_check))   
    }
    return tally(count, obj_tally)
}

object_indexes = {
    "Course 2":  { "Secret Star Spawner": 35},
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

function array_object_cork_box_is_tangible(index) => object_cork_box_is_tangible(nth_array_object(index))
function array_object_block_is_open(index)        => object_block_is_open(nth_array_object(index))
function array_object_big_boo_hp(index)           => object_big_boo_hp(nth_array_object(index))
function array_object_king_whomp_attacking(index) => object_king_whomp_attacking(nth_array_object(index))
function array_object_spawner_num_secrets(index)  => object_spawner_num_secrets(nth_array_object(index))

object_indexes = {
    "Course 2": { "Secret Star Spawner": 35 },
}

function in_game() {
    // We're in-game when:
    //   - the first object in the object array is active (excludes title and mario screens)
    //   - that object is not the file select background (excludes the file select screen)
    // Since it's impossible to get out of the game without resetting, once the conditions
    // are met we're always in-game (a hit is stored without a corresponding reset)
    // note: be careful with some modern hacks that put you back in the title screen after the end cake picture. It doesn't apply here, but good to know
    return once(
        array_object_is_active(0)
        && !array_object_is(0, "file select background"))
}

// =========================== //
//                             //
//   A C H I E V E M E N T S   //
//                             //
// =========================== //

// s w i t c h e s

function rgb_trigger() {
    return in_level("Caps")
    
    && tally(2, 
    [once(pressed_switch("red", "true")),
    once(pressed_switch("green", "true")),
    once(pressed_switch("blue", "true"))
    ])
    
    && measured(tally(3, 
    [once(pressed_switch("red", "f")),
    once(pressed_switch("green", "f")),
    once(pressed_switch("blue", "f"))
    ]), in_game())
    
    && never(tally(3, 
    [once(pressed_switch("red", "true")),
    once(pressed_switch("green", "true")),
    once(pressed_switch("blue", "true"))
    ]))
}

achievement(
    id = 179566,
    badge = "199950",
    title = "One Tough Switcheroo",
    description = "Press the red, green, and blue !-switches",
    points = 10,
    trigger = rgb_trigger()
)

function yellow_switch_trigger() {
    return in_level("Bowser Course")
    
    && pressed_switch__mem("yellow", "f") > pressed_switch__mem("yellow", "true")
}

achievement(
    id = 179567,
    badge = "199951",
    title = "Shell Switch of Isolation",
    description = format("Press the yellow !-switch in {0}", level_names["Bowser Course"]),
    points = 50,
    trigger = yellow_switch_trigger()
)

//
// p o w e r   s t a r s
//

function stars_meta(points, ids, badge_ids) => { "points": points, "ids": ids, "badge_ids": badge_ids }

course_stars_meta = {
    "Course 1":  stars_meta([ 10,  4,  4,  10, 10,  5,  10], range(179568, 179574), range(199952, 199958)),
    "Course 2":  stars_meta([  4,  4,  4,  3, 10,  3],     range(179575, 179580), range(199959, 199964)),
    "Course 3":  stars_meta([  4,  5,  2, 10, 10, 10, 10], range(179581, 179587), range(199965, 199971)),
    "Course 4":  stars_meta([  5, 10, 10,  4, 25],         range(179588, 179592), range(199972, 199976)),
    "Course 5":  stars_meta([  5, 10, 10, 25, 25, 10, 25], range(179593, 179599), range(199977, 199983)),
    "Course 6":  stars_meta([  4,  5,  5,  5, 10],         range(179600, 179604), range(199984, 199988)),
}

function course_stars_achievements() {
    for course_index in range(1, 6)
    {
        course_key = format("Course {0}", course_index)
        course_name = level_names[course_key]
        
        star_index = 0
        for star_name in star_names[course_key]
        {
            star_index = star_index + 1
            title = star_name
            description = ""
            if star_index != 7 {
                description = format("Collect the star '{0}' in {1}", star_name, course_name)
            } else {
                if course_index == 1
                    description = format("Collect the hidden !-box star in {0}", course_name)
                else if course_index == 3
                    description = format("Collect the red coin star in {0}", course_name)
                else if course_index == 5
                    description = format("Collect the 100 coin star in {0}", course_name)
                else
                    description = "ERROR"
            }    
            
            trigger = just_collected_star(course_key, star_index)
            if (course_index == 2 && star_index < 6){
                description = description + " (No Wing Cap)"
                trigger = unless(once(wearing_wing_cap() == 1 && never(!in_level(course_key))))  && trigger
            }
            
            id = course_stars_meta[course_key]["ids"][star_index - 1]
            badge = format("{0}", course_stars_meta[course_key]["badge_ids"][star_index - 1])
            
            if (course_index == 3 && star_index == 6) {
                description = description + " (No grabbing Chuckya or BLJ on roof)"
                trigger = unless(once(object_is(held_object(), "chuckya") && never(level_changed())))
                    && unless(once(pos_z_float() < -2048.0 && pos_y_float() > 6864.0 && mario_anim_is("long jump") && never(level_changed())))
                && trigger
            }

            achievement(
                id=id,
                badge=badge,
                title=title,
                description=description,
                points=course_stars_meta[course_key]["points"][star_index - 1],
                trigger=trigger
            )
        }
    }
}

course_stars_achievements()

// Cap Switch Triathlon's the only non-course I'm considering

non_course_stars_meta = {
    "Caps":     stars_meta([5, 3, 10, 5, 5, 4], range(179606, 179611), range(199990, 199995)),
}

function non_course_star_achievements(course_key, star_cheevos) {
    course_name = level_names[course_key]
    i = 0
    for star_cheevo in star_cheevos {
        title = star_cheevo[0]
        star_index = i + 1
        description = format(star_cheevo[1], course_name)
        points = non_course_stars_meta[course_key]["points"][i]
        i = i + 1
        
        achievement(
            title = title,
            description = description,
            points = points,
            trigger = just_collected_star(course_key, star_index)
        )
    }
}

// Miscellaneous stars

function whomp_star_collect_trigger() => in_level("Boss Battle")
        && mario_anim_is("star dance ground (exit)")

achievement(
    id = 179623,
    badge = "200007",
    title = "Brick Battle on a Timer",
    description = format("Defeat King Whomp in {0} and collect his star", level_names["Boss Battle"]),
    points = 50,
    trigger = whomp_star_collect_trigger()
)

achievement(
    id = 179605,
    badge = "199989",
    title = "End of the Extreme Collab",
    description = format("Collect the star in {0}. Thanks for playing!", level_names["The End"]),
    points = 1,
    trigger = (
        in_level("The End")
        && mario_anim_changed_to("star dance ground (exit)")
    )
)

non_course_star_achievements("Caps", [
    ["Airborne Secrets", "Collect the secrets star in the red area of {0}"],
    ["Under and Behind the Glass", "Collect the hidden !-box star in the red area of {0}"],
    ["Sprint to the Pool and Boxes", "Collect the star past the !-switch in the pool in the green area of {0}"],
    ["Wallkicks and Lava Boosts", "Collect the star past the lava walls in the green area of {0}"],
    ["Up and Over", "Collect the star past a vertical shaft in the blue area of {0}"],
    ["Bunched Together Reds", "Collect the red coin star in the blue area of {0}"]
])

//challenges

function all_overworld_signs_trigger()
{
    cond = unless(!in_level("Overworld")) && never(death_fadeout())
    sign_check_tally = []
    for dialog in dialog_id_overworld__values
    {
        sign_check = dialog_id__mem == dialog_id_overworld__values[dialog]
        if (dialog == "Cap Level Credits")
            sign_check = sign_check && is_float_neg(pos_z())
        if (dialog == "Course 5 Credits")
            sign_check = sign_check && !is_float_neg(pos_z())
        array_push(sign_check_tally, once(sign_check))
    }
    cond = cond && measured(tally(length(dialog_id_overworld__values), sign_check_tally))
    return cond
}

achievement(
    id = 179612, badge = "199996",
    title = "Credits from Creators", description = "Read all nine signs in the overworld without dying (entering pipes, Bowser course is okay)",
    points = 3, trigger = all_overworld_signs_trigger()
)

//castle_top_y = 0x45D68000
//
//function box_snipe_trigger()
//{
//    cond = never(!in_level("Course 3"))
//    cond = cond && once(pos_z() > 0xC5000000 && pos_y() > castle_top_y && pos_y() < 0x80000000) // on top of castle
//    cond = cond && never(pos_y() <= castle_top_y && !airborne()) // just below castle
//    cond = cond && never(pos_y() > 0x80000000   && !airborne()) // negative floats
//    cond = cond && trigger_when(wearing_metal_cap() == 1)
//    return cond
//}
//
//achievement(
//    id = 179613, badge = "199997",
//    title = "Box Snipe from Above", description = "In Course 3, jump from the top of the castle and collect a metal cap before hitting the ground",
//    points = 5, trigger = box_snipe_trigger()
//)

achievement(
    id = 179613, badge="421730",
    title = "Swimming in the Vicious Room",
    description = "In Course 3, swim into an invisible water box in the star 6 area.",
    points = 4,
    trigger = in_level("Course 3")
        && swimming() != 0
        && pos_y_float() < 1000.0
)

function wing_cap_tour_trigger()
{
    return never(!in_level("Course 2")) 
    
    && once(mario_anim_is("airborne spawn") && mission_id__mem == 5)
    
    && collided_with_object("secret")
    && collided_with_object("red coin", 8)
    
    && trigger_when(
        just_collected_star_plain(6)
    )
}

achievement(
    id = 179614, badge = "199998",
    title = "Wing Cap Tour Through the Village", description = format("In Course 2, collect the secret and all 8 red coins, then get the star '{0}'",
    star_names["Course 2"][5]),
    points = 10, trigger = wing_cap_tour_trigger()
)

function course_1_challenge_trigger()
{
    return never(!in_level("Course 1"))
    
    && once(mario_anim_is("airborne spawn"))
    
    && never(pos_z() < 0x46684800 // && pos_z() > 0x46000000
          // && pos_x() < 0xC5000000 
          && pos_x() > 0x80000000) // was at ANY of the central buildings
          
    && never(pos_z() < 0x46600000 && pos_z() > 0x46000000
          && pos_x() < 0x45500000) // 2nd half of central building
          
    && never(pos_z() < 0x464E0000 && pos_z() > 0x46000000 // looser z restriction
          && pos_x() < 0x46260000 && pos_x() > 0x45500000) // was near star 6
    
    && trigger_when(just_collected_star_plain(1))
}

achievement(
    id = 179615, badge = "199999",
    title = "Window Jumps to the Grassland", description = format("In Course 1, get the star '{0}' by traversing only the houses along the edge of the course",
    star_names["Course 1"][0]),
    points = 10, trigger = course_1_challenge_trigger()
)

function course_4_challenge_trigger()
{
    return never(!in_level("Course 4"))
    
    && once(mario_anim_is("airborne spawn"))
    
    && never(controller_b_button() == 1)
    
    && trigger_when(just_collected_star_plain(1))
}


achievement(
    id = 179616, badge = "200000", // pog
    title = "No Kicks or Dives Needed, Just C-Up Hyperspeed", description = format("In Course 4, get the star '{0}' without using the B button during the entire stage",
    star_names["Course 4"][0]),
    points = 5, trigger = course_4_challenge_trigger()
)

achievement(
    id = 179617, badge = "200001",
    title = "Deadly Acropolis Blues", description = "In Course 5, collect all 10 blue coins (5 each) from both blue coin switches",
    points = 25, trigger = never(!in_level("Course 5")) && measured(repeated(10, coins__mem == prev(coins__mem) + 5))
)

function course_6_challenge_trigger()
{
    return never(!in_level("Course 6"))
    
    && once(mario_anim_is("airborne spawn"))
    
    && never(repeated(2, mario_anim_is("lava boost") && just_changed_to(hp_dec(), 0x0B)))
    
    && trigger_when(just_collected_star_plain(4))
}

achievement(
    id = 179618, badge = "200002",
    title = "One Bounce is All You Need", description = format("In Course 6, get the star '{0}' (the snufit star) by bouncing on lava only one time",
    star_names["Course 6"][3]),
    points = 25, trigger = course_6_challenge_trigger()
)

function wing_cap_secrets_challenge_trigger()
{
    return sublevel_id__mem == 2
    
    && disable_when(once(prev(wearing_wing_cap()) == 1 && cap_time() > prev(cap_time())),
    until = !in_level("Caps"))
    
    && disable_when(repeated(2, prev(wearing_wing_cap()) == 0 && wearing_wing_cap() == 1),
    until = !in_level("Caps"))
    
    && trigger_when(just_collected_star_plain(1))
}

achievement(
    id = 179619, badge = "200003",
    title = "Single Cycle Secrets", description = format("In the red area of {0}, get the secrets star without picking up more than one wing cap (Re-enter {0} to try again)", level_names["Caps"]),
    points = 5, trigger = wing_cap_secrets_challenge_trigger()
)

function vanish_cap_speedrun_trigger()
{
    return in_level("Caps")
    && sublevel_id__mem == 4
    
    && (trigger_when(prev(wearing_vanish_cap()) == 1 && just_touched_star_air(5))
    ||  trigger_when(prev(wearing_vanish_cap()) == 1 && just_collected_star_plain(5))
    )
}

achievement(
    id = 179620, badge = "200004",
    title = "Gone in a Flash", description = format("In the blue area of {0}, get the star past the vertical shaft while still wearing your vanish cap", level_names["Caps"]),
    points = 5, trigger = vanish_cap_speedrun_trigger()
)

function metal_cap_challenge_trigger()
{
    return once(in_level("Caps") && sublevel_id__mem == 3 && mario_anim_is("airborne spawn"))
    && never(sublevel_id__mem != 3)
    
    && never(just_took_damage())
    
    && trigger_when(just_collected_star_plain(4))
}

achievement(
    id = 179621, badge = "200005",
    title = "Clean Lavabouncing", description = format("In the green area of {0}, get the star past the lava walls without taking damage", level_names["Caps"]),
    points = 5, trigger = metal_cap_challenge_trigger()
)

achievement(
    id = 179622, badge = "200006",
    title = "Shoutouts to Summer SRM", description = format("Find and read the secret sign in {0}", level_names["Bowser Course"]),
    points = 1, trigger = in_level("Bowser Course") && dialog_id__mem == 0x0F
)

//
// Rich Presence
//

level__lookup = rich_presence_lookup("LevelAction", level_id__mem, {
    0x00: "navigating the overworld", // really a placeholder
    0x10: "navigating the overworld",
    
    0x09: "doing some rooftop parkour in Dried Out Harbor",
    0x18: "traversing floating platforms in Hovering Sunrise Village",
    0x0C: "taking a trip through the Valley of Rememberance",
    0x05: "performing exotic jumps in the Kingdom of Immortality",
    0x04: "platforming high up in Aerial Flying Acropolis",
    0x07: "in a far-off course in Abstraction of Time and Will",
    
    0x1B: "sprinting through the Cap Switch Triathlon",
    0x11: "suffering in the Desolated Outlet",
    0x1C: "fighting King Whomp in the Desolated Outlet!",
    0x1D: "at The End of this extreme hack collab",
    0x19: "having some teatime with Peach in the End Cake Picture"
}, "in an unbeknownst location")

stars__value = rich_presence_value("Number", nof_stars())
//deaths__value = rich_presence_value("Number", measured(mario_anim_changed_to("death respawn"))) // screw you compiler, I do what I want

//rich_presence_conditional_display(
//    in_game(),
//    "Mario is {0} [⭐{1}/45] [Deaths this session: {2}]", level__lookup, stars__value, deaths__value
//)

rich_presence_display("Mario is getting ready for another extreme adventure")

//leaderboard test
//desolated outlet trigger (on GROUND near switch) 
// pos_x() > 0xC5A80000 && pos_x() < 0xC5BB0000
// && pos_y() > 0x45C90000 && pos_y() < 0x45D80000
// && pos_z() > 0xC5C00000 && pos_z() < 0xC5D10000

//// scrap this lol
//leaderboard(title = "Yellow Switch Speedrun", description = "In Desolated Outlet, stand on the yellow !-switch as fast as possible",
//    start = just_entered_level_from("Bowser Course", "Overworld"), cancel = !in_level("Bowser Course"), 
//    submit = !airborne() && pos_x() > 0xC5A80000 && pos_x() < 0xC5BB0000
//        && pos_y() > 0x45C90000 && pos_y() < 0x45D80000
//        && pos_z() > 0xC5C00000 && pos_z() < 0xC5D10000, value = measured(in_level("Bowser Course")), format = "FRAMES")
//        
////achievement(title="DUMMY", description="Yellow switch check", points=0, trigger=in_level("Bowser Course") && !airborne() && pos_x() > 0xC5A80000 && pos_x() < 0xC5BB0000 && pos_y() > 0x45C90000 && pos_y() < 0x45D80000 && pos_z() > 0xC5C00000 && pos_z() < 0xC5D10000)
//
//leaderboard(title = "King Whomp Beatdown", description = "Enter Desolated Outlet and defeat King Whomp as fast as possible",
//    start = just_entered_level_from("Bowser Course", "Overworld"), cancel = in_level("Overworld"),
//    submit = whomp_star_collect_trigger(), value = measured(in_level("Bowser Course") || in_level("Boss Battle")), format = "FRAMES")