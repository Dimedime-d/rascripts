// ~Hack~ Water Star Adventure
// #ID = 11645

// ------------- //
//   u t i l s   //
// ------------- //

function just_changed(mem, from, to) => prev(mem) == from && mem == to
function just_changed_to(mem, to) => prev(mem) != to && mem == to

function struct_field(struct_def, base, field) => base + struct_def[field]

// ------------- //
//   m a r i o   //
// ------------- //

mario__struct = {
    "hat bitflags":       0x04,  // byte
    "action":             0x0c,  // dword
    "previous action":    0x10,  // dword
    "x":                  0x3c,  // dword (float)
    "y":                  0x40,  // dword (float)
    "z":                  0x44,  // dword (float)
    "interaction object": 0x78,  // dword (pointer to object)
    "ridden object":      0x84,  // dword (pointer to object)
    "mario object":       0x88,  // dword (pointer to object)
    
    "nof stars (hud)":    0xb0,  // word, originally 0xf6
    "coins":              0xb2,  // word, originally 0xaa
    "hp":                 0xb4,  // word, originally 0xac
}

mario__addr = 0x19d9c0 // 0x33b170
// stood_on_object__addr = 0x330e34

function mario_field(field) => struct_field(mario__struct, mario__addr, field)

function hat_in_hand()        => bit5(mario_field("hat bitflags"))
function hat_on_head()        => bit4(mario_field("hat bitflags"))
function wearing_wing_cap()   => bit3(mario_field("hat bitflags"))
function wearing_metal_cap()  => bit2(mario_field("hat bitflags"))
function wearing_vanish_cap() => bit1(mario_field("hat bitflags"))

function pos_x() => dword(mario_field("x"))
function pos_y() => dword(mario_field("y"))
function pos_z() => dword(mario_field("z"))

function hp_int() => byte(mario_field("hp") + 1)
function hp_dec() => byte(mario_field("hp dec"))
function just_took_damage() => prev(hp()) > hp()

function hp() => word(mario_field("hp"))

function cap_time() => word(mario_field("cap timer"))

function nof_coins() => word(mario_field("coins"))
function nof_stars() => word(mario_field("nof stars (hud)"))

mario_anim__mem = dword(mario_field("action"))
mario_anim__values = {
    "star dance ground (exit)":    0x00001302,
    "star dance water":            0x00001303,
    "star dance ground (no exit)": 0x00001307,
    "reading sign":                0x00001308,
    "star grab fall":              0x00001904,
    "airborne spawn":              0x00001924,
    "death respawn":               0x00001929,
    "lava boost":                  0x010208B7,
}

function mario_anim_is(name) => mario_anim__mem == mario_anim__values[name]
function mario_anim_was(name) => prev(mario_anim__mem) == mario_anim__values[name]

function mario_anim_changed_to(name) {
    return prev(mario_anim__mem) != mario_anim__values[name]
        && mario_anim__mem == mario_anim__values[name]
}

function airborne() => bit3(mario_anim__addr + 1) != 0

// --------------- //
//   m e m o r y   //
// --------------- //

// normal starts = 1-6; 100 coin star = 7
last_star__addr = 0x190f12
last_star__mem = byte(last_star__addr)

current_mission__addr = 0x18fe93
current_mission__mem  = byte(current_mission__addr)

sublevel_id__addr = 0x19daba
sublevel_id__mem  = byte(sublevel_id__addr)

level_id__addr = 0x190f6c //0x32ddfa
level_id__mem = byte(level_id__addr)
level_id__values = {
    "Main Hub":       0x10,
    "Upper Hub":      0x06,
    
    "Course 1":       0x09,
    "Course 2":       0x18,
    "Course 3":       0x0c,
    "Course 4":       0x05,
    "Course 5":       0x04,
    "Course 6":       0x07,
    "Course 7":       0x16,
    
    "Bowser Course":  0x11,
    "Bowser Battle":  0x1E,
    "Ending":         0x14,
    "End Cake":       0x19,
}

course_names = {
    "Course 1": "Reflections of a Snowfall on a Warm Winter's Evening",
    "Course 2": "A proverb holds wisdom without hands",
    "Course 3": "A cool breeze across the bow of the gallery",
    "Course 4": "Within the heart you will find yourself",
    "Course 5": "Within the mind you find a friend",
    "Course 6": "Within your shadow hides your future",
    "Course 7": "Within your blood lies your will",
    
    "Bowser Course": "Apotheosis",
}

function in_level(name) => level_id__mem == level_id__values[name]
function just_entered_level(name) => just_changed_to(level_id__mem, level_id__values[name])

function just_collected_star_generic(level) {
    return in_level(level)
        && (mario_anim_changed_to("star dance ground (exit)")
            || mario_anim_changed_to("star dance ground (no exit)")
            || mario_anim_changed_to("star dance water"))
}

function just_collected_star(level, star_index) {
    return last_star__mem == star_index
        && just_collected_star_generic(level)
}

function just_collected_star_trigger_friendly(level, star_index) {
    star_dance_values = ["star dance ground (exit)", "star dance water", "star dance ground (no exit)"]
    star_dance_checks = []
    for name in star_dance_values {
        array_push(star_dance_checks, once(mario_anim_is(name)))
    }
    level_check = always_true()
    if level != "None"
        level_check = in_level(level)
    return level_check
        && trigger_when(last_star__mem == star_index
        && none_of(star_dance_values, a => mario_anim_was(a))
        && any_of(star_dance_values, a => mario_anim_is(a))
    )
}

dialog_id__addr = 0x193d32
dialog_id__mem  = word(dialog_id__addr)

achievement(
    title = "Some Higher Stakes",
    description = "Collect 150 coins in Course 1, 2, or 3, and get rewarded with a jewel of worship",
    points = 5,
    trigger = prev(nof_coins()) >= 100 && prev(nof_coins()) < 150 && nof_coins() >= 150 
        && any_of(["Course 1", "Course 2", "Course 3"], a => in_level(a))
)

for i in range(1, 3) {
    leaderboard(
        title = format("Course {0} Coin Cache", i),
        description = format("Coin Score in Course {0} (submits on star collect)", i),
        start  = just_collected_star_generic(format("Course {0}", i)),
        cancel = (0==1),
        submit = (1==1),
        value  = nof_coins(),
        format = "VALUE"
    )
}

// -------------------- //
//   s a v e  d a t a   //
// -------------------- //

file_num__addr = 0x190f6e //0x32ddf6 in non-decomp ROMs
file_num__mem = byte(file_num__addr)

save_data_base__addr = 0x7a390
function current_file_data() => save_data_base__addr + 0x70 * file_num__mem

challenge_flags = {
    "Buffed Enemies"    : bit(0, current_file_data()),
    "Coins Don't Heal"  : bit(1, current_file_data()),
    "Drain HP"          : bit(2, current_file_data()),
    "Double Lava Damage": bit(3, current_file_data()),
    "Double Koopa Speed": bit(4, current_file_data()),
    "Chaos Lite"        : bit(5, current_file_data()),
    "A Button Challenge": bit(6, current_file_data()),
    "B Button Challenge": bit(7, current_file_data()),
    "Z Button Challenge": bit(8, current_file_data()),
    "Hardcore"          : bit(9, current_file_data()),
    "Green Demon"       : bit(10, current_file_data()),
    "Move Badges"       : bit(11, current_file_data()),
    "Super Mode"        : bit(12, current_file_data()),
    "Daredevil"         : bit(13, current_file_data()),
}

function challenge_active(name) => challenge_flags[name] != 0

function pause_lock_unless_challenges_enabled_in_level(challenges, level) {
    cond = always_true()
    for chall in challenges {
        cond = cond && disable_when(!challenge_active(chall), until=!in_level(level))
    }
    return cond
}

function pause_lock_unless_challenges_disabled_in_level(challenges, level) {
    cond = always_true()
    for chall in challenges {
        cond = cond && disable_when(challenge_active(chall), until=!in_level(level))
    }
    return cond
}

function star_specific_challenge_trigger(level, star_index, challenges_allowed, challenges_excluded=[]) {
    return pause_lock_unless_challenges_enabled_in_level(challenges_allowed, level)
        && pause_lock_unless_challenges_disabled_in_level(challenges_excluded, level)
        && just_collected_star_trigger_friendly(level, star_index)
}

achievement(
    title = "One hundred twenty meters of time on a clock with no hands",
    description = "In Course 1, collect the secrets star (Buffed Enemies, Daredevil, No Super Mode)",
    points = 5,
    trigger = star_specific_challenge_trigger("Course 1", 3, ["Buffed Enemies", "Daredevil"], ["Super Mode"])
)

achievement(
    title = "An increase in free cash flow breaks the resistance of your mind",
    description = "In Course 1, collect the red coin star (Chaos Lite)",
    points = 5,
    trigger = star_specific_challenge_trigger("Course 1", 5, ["Chaos Lite"])
)

achievement(
    title = "Boiling inside a pot with no lid are life's temptations",
    description = "In Course 2, collect the star in the volcano (Daredevil, No Super Mode)",
    points = 10,
    trigger = star_specific_challenge_trigger("Course 2", 4, ["Daredevil"], ["Super Mode"])
)

achievement(
    title = "Life is a poor man's luxury",
    description = "In Course 2, collect the red coin star (A Button Challenge, No Super Mode)",
    points = 10,
    trigger = star_specific_challenge_trigger("Course 2", 6, ["A Button Challenge"], ["Super Mode"])
)

achievement(
    title = "Under the sea of life's mysteries are the mind's mysteries",
    description = "In Course 3, collect the star in the warp pipe (Drain HP, B+Z Button Challenges, No Super Mode)",
    points = 10,
    trigger = star_specific_challenge_trigger("Course 3", 6, ["Drain HP", "B Button Challenge", "Z Button Challenge"], ["Super Mode"])
)

achievement(
    title = "The star is a friend. A friend to give my life to",
    description = "In Course 3, collect the 150 coin star (Buffed Enemies, Coins Don't Heal, Drain HP, No Super Mode)",
    points = 10,
    trigger = star_specific_challenge_trigger("Course 3", 7, ["Buffed Enemies", "Coins Don't Heal", "Drain HP"], ["Super Mode"])
)

achievement(
    title = "Surrounded by your friends and family you find yourself alone",
    description = "In Course 4, collect the second star (Buffed Enemies, Daredevil)",
    points = 5,
    trigger = star_specific_challenge_trigger("Course 4", 2, ["Buffed Enemies", "Daredevil"]) && current_mission__mem >= 1
)

achievement(
    title = "A stranger is tomorrow's friend",
    description = "In Course 5, collect the second star (A Button Challenge, No Super Mode)",
    points = 5,
    trigger = star_specific_challenge_trigger("Course 5", 2, ["A Button Challenge"], ["Super Mode"]) && current_mission__mem >= 1
)

achievement(
    title = "The past hides the key to the future",
    description = "In Course 6, collect the red coin star (Drain HP, No Super Mode)",
    points = 5,
    trigger = star_specific_challenge_trigger("Course 6", 2, ["Drain HP"], ["Super Mode"]) && current_mission__mem >= 1
)

achievement(
    title = "Your will paves the path for your bones' respite",
    description = "In Course 7, collect the red coin star (A Button Challenge, No Super Mode)",
    points = 10,
    trigger = star_specific_challenge_trigger("Course 7", 2, ["A Button Challenge"], ["Super Mode"]) && current_mission__mem >= 1
)

achievement(
    title = "One with the power of Dorrie",
    description = "Enter Apotheosis and defeat Bowser (Daredevil, No Super Mode for entire stage, deaths allowed)",
    points = 10,
    trigger = disable_when(!challenge_active("Daredevil"), until=!in_level("Bowser Course") && !in_level("Bowser Battle"))
    && disable_when(challenge_active("Super Mode"), until=!in_level("Bowser Course") && !in_level("Bowser Battle"))
    && trigger_when(in_level("Bowser Battle") && mario_anim_is("star dance ground (exit)"))
)

course_offsets = { // bytes
    1:  0x0f,
    2:  0x0e,
    3:  0x0d,
    4:  0x0c,
    5:  0x13,
    6:  0x12,
    7:  0x11,
}

function course_stars_count(course_num, is_delta) {
    off = current_file_data() + course_offsets[course_num]
    mem = 0
    if course_num <= 3 {
        mem = bitcount(off) - bit7(off)
    } else {
        mem = bit0(off) + bit1(off)
    }
    
    if is_delta == "True"
        return prev(mem)
    return mem
}

for num in course_offsets {
    adj = ""
    pts = 0
    tot = 0
    if num <= 3 {
        adj = "all 7"
        pts = 10
        tot = 7
        if num >= 2
            pts = 25
    } else {
        adj = "both"
        pts = 5
        tot = 2
    }
    achievement(
        title = course_names[format("Course {0}", num)],
        description = format("Collect {0} jewels of worship in Course {1}", adj, num),
        points = pts,
        trigger = in_level(format("Course {0}", num))        
            && course_stars_count(num, "True") == tot - 1
            && measured(course_stars_count(num, "False") == tot)
    )
}

end_stars = current_file_data() + 0x20

achievement(
    title = "Divinity Attained",
    description = "Defeat Bowser in Apotheosis and make your choice in the ending",
    points = 10,
    trigger = tally(300, in_level("End Cake")) && (bit0(end_stars) + bit1(end_stars) >= 1)
)

// ------- //
//   r p   //
// ------- //

music_id__addr = 0xa94ab
music_id__mem  = byte(music_id__addr)

meta_descriptions = {
    0x00: "Starting up the game",
    0x02: "Playing with Mario Head / Listening to Lyra Encounter Music",
    0x21: "In File Select",
}

level_descriptions = {
    0x10: "is in the main hub, under the watch of the Dorrie statue",
    0x06: "is in the upper hub, continuing his pilgrimage",
    
    0x09: "is in Course 1, exploring an icy enclosure",
    0x18: "is in Course 2, exploring a volcanic area",
    0x0c: "is in Course 3, exploring a jungle",
    
    0x05: "is in Course 4, venturing through some cityscape clouds",
    0x04: "is in Course 5, venturing across a desert town",
    0x07: "is in Course 6, venturing within a frosty village",
    0x16: "is in Course 7, venturing deep into the woods",
    
    0x11: "is in Apotheosis, facing a trial to divinity",
    0x1E: "is in Apotheosis, battling Bowser",
    0x14: "has defeated Bowser and is considering his paths",
    0x19: "has finished his pilgrimage and has ascended into a higher being",
}

rich_presence_conditional_display(any_of(meta_descriptions, a => music_id__mem == a), 
    "{0}", rich_presence_lookup("Fileless", music_id__mem, meta_descriptions))
rich_presence_conditional_display(any_of(level_descriptions, a => level_id__mem == a), 
    "{1}{2}{3}{4}Mario {0} with ⭐{5}", 
        rich_presence_lookup("Levels", level_id__mem, level_descriptions, "is in an unbeknownst location"),
        rich_presence_lookup("SuperMode", challenge_flags["Super Mode"], {0:"", 1:"Super Mode "}),
        rich_presence_lookup("Hardcore", challenge_flags["Hardcore"], {0:"", 1:"Hardcore "}),
        rich_presence_lookup("Chaos", challenge_flags["Chaos Lite"], {0:"", 1:"Chaos "}),
        rich_presence_lookup("Daredevil", challenge_flags["Daredevil"], {0:"", 1:"Daredevil "}),
        rich_presence_value("Number", nof_stars()))
rich_presence_display("Mario is on an aquatic pilgrimage")
