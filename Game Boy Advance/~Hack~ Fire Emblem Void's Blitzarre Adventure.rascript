// ~Hack~ Fire Emblem: Void's Blitzarre Adventure
// #ID = 7066

// Set these to ZERO before pushing to unofficial or core
GENERATE_DUMMY_ACHIEVEMENTS = 0
ALLOW_SUSPEND_SAVES_FOR_TESTING = 0

function dummy_achievement(title, description, points, trigger) {
    if (GENERATE_DUMMY_ACHIEVEMENTS == 1) {
        achievement(title=format("[Dummy] {0}", title),
        description=description,
        points=0,
        trigger=trigger)
    }
}

// ------------- //
//   u t i l s   //
// ------------- //

ewram_offset = 0x8000

function just_increased(mem) => mem > prev(mem)

function just_changed_any(mem) => mem != prev(mem)
function just_changed(mem, from, to) => prev(mem) == from && mem == to
function just_changed_to(mem, to) => prev(mem) != to && mem == to

function struct_field(struct_def, base, field) => base + struct_def[field]

// ----------------- //
//   s t r u c t s   //
// ----------------- //

// Never gonna use most of these, but just for documentation...
unit__struct = { 
    "character pointer":    0x00,   // dword (pointer to data)
    "class pointer":        0x04,   // dword (pointer to data)
    "level":                0x08,   // byte
    "experience":           0x09,   // byte
    
    "deployment":           0x0B,   // byte
    "state":                0x0C,   // byte
    "x":                    0x10,   // byte
    "y":                    0x11,   // byte
    "max HP":               0x12,   // byte
    "current HP":           0x13,   // byte
    "stats":                0x14,   // str/skl/spd/def/res/luk
    "constitution bonus":   0x1A,   // byte,
    "movement bonus":       0x1D,   // byte,
    "inventory":            0x1E,   // 10 bytes, item ID, then durability
    "weapon ranks":         0x28,   // 8 bytes,
    "status":               0x30,   // 2 lower4s, status type (lo)/duration(hi)
}

unit__sizeof = 0x48

function unit_field(base, field) => struct_field(unit__struct, base, field)

function unit_character(addr) => dword(unit_field(addr, "character pointer"))
function unit_class(addr) => dword(unit_field(addr, "class pointer"))

class_ptrs = {
    "phantom":      0x08808BA4,
}

unit_ptrs = {
    "Blank":        0x00000000,
    
    "Myrmidon Anna":0x08803E68,
    "Nikita":       0x088041A8,
    "Doot":         0x088042AC,
    "Evil Florina": 0x08804348, // tfw your name is so long, it breaks the deployment menu
    "Bjorn":        0x0880437C,
    "Marf":         0x088043E4,
    
    "Feditor":      0x088063C8,
}

function unit_exists(addr) => unit_character(addr) != 0
function unit_is(addr, name) => unit_character(addr) == unit_ptrs[name]
function unit_was(addr, name) => prior(unit_character(addr)) == unit_ptrs[name] // Prior for some repeated() calls in some resets to check if a recruitable character was killed, such that the reset would trigger after the recruitment

function unit_dead(addr) => bit(2, unit_field(addr, "state")) != 0

function unit_class_is(addr, class_name) => unit_class(addr) == class_ptrs[class_name]

chapter_data__addr = 0x33cf0

chapter__struct = {
    "game clock":           0x00,   // dword
    "money":                0x08,   // dword
    "save slot number":     0x0c,   // byte
    "vision range":         0x0d,   // byte, non-thief
    "map id":               0x0e,   // byte
    "current phase":        0x0f,   // byte
    "turn number":          0x10,   // word
    "cursor x":             0x12,   // byte
    "cursor y":             0x13,   // byte
    "chapter flags":        0x14,   // byte (bitfield)
    "weather":              0x15,   // byte
    "support gain total":   0x16,   // word, useless in this hack
    "playthrough id":       0x18,   // word,
}

function chapter_field(field) => struct_field(chapter__struct, chapter_data__addr, field)

function clock() => dword(chapter_field("game clock"))
function current_chapter() => byte(chapter_field("map id"))
function current_turn() => word(chapter_field("turn number"))
function current_phase() => byte(chapter_field("current phase"))
function prep_menu() => bit4(chapter_field("chapter flags"))
function hard_mode() => bit6(chapter_field("chapter flags"))

map_id__values = {
    "Prologue":     0x00,   "Chapter 1":    0x01,   "Chapter 2":    0x02,   "Chapter 3":    0x03,   "Chapter 4":    0x04,
    "Chapter 5":    0x06,   "Chapter 6":    0x07,   "Chapter 7":    0x08,   "Chapter 8":    0x09,   "Chapter 9":    0x0A,
    "Chapter 10":   0x0B,   "Chapter 11":   0x3D,   "Chapter 12":   0x0C,   "Chapter 13":   0x0D,   "Chapter 14":   0x0E,
    "Chapter 15":   0x0F,   "Chapter 16":   0x10,   "Chapter 17":   0x11,   "Chapter 18":   0x12,   "Chapter 19":   0x13,
    "Chapter 20":   0x14,   "Chapter 21":   0x15,   "Chapter 22":   0x16,   "Chapter 23":   0x17,   "Chapter 24":   0x18,
    "Chapter 25":   0x3E,   "Chapter 26":   0x19,   "Chapter 27":   0x1A,   "Chapter 28":   0x1B,   "Chapter 29":   0x22,
    "Final Chapter":0x23,
}

function in_chapter(name) => current_chapter() == map_id__values[name]
function in_player_phase() => current_phase() == 0x00

function in_hard_mode() => hard_mode() != 0

action__struct = {
    "rns":                  0x00,   // 3 words
    "character allegiance": 0x0C,   // byte
    "target allegiance":    0x0D,   // byte
    "action taken":         0x11,   // byte
    "suspend point type":   0x16,   // byte
}

action__addr = 0x42958

function action_field(field) => struct_field(action__struct, action__addr, field)

function action_char_allegiance() => byte(action_field("character allegiance"))
function action_target_allegiance() => byte(action_field("target allegiance"))
function action_taken() => byte(action_field("action taken"))
function action_suspend_point_type() => byte(action_field("suspend point type"))

function suspend_point_changed() => just_changed_any(action_taken()) || just_changed_any(action_suspend_point_type())

function action_taken_is_combat() => action_taken() == 0x02

arena__struct = {
    "player unit pointer":      0x00,   // dword (pointer to unit)
    "opponent unit pointer":    0x04,   // dword (pointer to unit)
    "bet money":                0x08,   // word, inb4 someone makes a 'bet high in the arena' cheevo
    "battle results":           0x0A,   // byte
    // Other data i don't care about
}

arena_data__addr = 0x428F0
arena_opponent_unit__addr = 0x42910 // constant afaik, same as other unit structs

function arena_field(field) => struct_field(arena__struct, arena_data__addr, field)

function arena_bet_money() => word(arena_field("bet money"))
function arena_battle_results() => byte(arena_field("battle results"))
function arena_battle_won() => just_changed(arena_battle_results(), 0, 1) // Gets 00'd out as the game generates an enemy for the arena

// --------------------------------- //
//   c h a r a c t e r   a r r a y   //
// --------------------------------- //

// battle struct shares same ~72 bytes as unit struct, with additional info following (equipped weapons, AS, battle hit, etc.)
battle_actor_unit__addr = 0x424ec
battle_target_unit__addr = 0x4256c

function battle_actor_unit_is(name) => unit_is(battle_actor_unit__addr, name)
function battle_target_unit_is(name) => unit_is(battle_target_unit__addr, name)

unit_array = {
    "player":   0x33e4c,
    "enemy":    0x34fbc,
    "npc":      0x35dcc,
}

function nth_unit(faction, index) => unit_array[faction] + (index * unit__sizeof)

function nth_unit_exists(faction, index) => unit_exists(nth_unit(faction, index))
function nth_unit_is(faction, index, name) => unit_is(nth_unit(faction, index), name)
function nth_unit_was(faction, index, name) => unit_was(nth_unit(faction, index), name)

function nth_unit_dead(faction, index) => unit_dead(nth_unit(faction, index))

function nth_unit_class_is(faction, index, class_name) => unit_class_is(nth_unit(faction, index), class_name)

// --------------------- //
//   e v e n t   i d s   //
// --------------------- //

perm_event_bits__addr = 0x5250
temp_event_bits__addr = 0x5270

CHEATING_EID = 0xB2
CASUAL_EID = 0xB0
MAIN_LORD_DIED_EID = 0x65 // Game Over

BOSS_DEATH_QUOTE_EID = 0x02

function get_event_id(eid) {
    bit_off = -1
    base_addr = -1
    if (eid > 0x64) {
        base_addr = perm_event_bits__addr
        bit_off = eid - 0x65  // defined event IDs are 1-indexed
    } else {
        base_addr = temp_event_bits__addr
        bit_off = eid - 0x01
    }
    dword_off = bit_off / 32 * 4
    bit_off = bit_off % 32
    
    return bit(bit_off, base_addr + dword_off) // i'd like an extension of this method to take any arbitrary index (instead of 0-31)
}

function event_ids_set(eids, hits=0) {
    cond = always_true()
    if hits != 0 {
        cond = all_of(eids, eid => repeated(hits, get_event_id(eid) == 1))
    } else {
        cond = all_of(eids, eid => get_event_id(eid) == 1)
    }
    return cond
}

function event_id_just_set(eid) {
    return just_increased(get_event_id(eid))
}

function protected_achievement(title, description, points, trigger, id=0, badge="0") {
    achievement(title=title,
        description=description,
        points=points,
        trigger=disable_when(current_turn() >= 1 && event_ids_set([CHEATING_EID], 1)) && unless(event_ids_set([CASUAL_EID])) && trigger,
        id=id,
        badge=badge
        )
}

// ------------- //
//   p r o c s   //
// ------------- //

proc__struct = {
    "code start pointer":   0x00,   // dword (points to ROM, use as proc identifier)
    "first child proc":     0x18,   // dword (pointer to proc)
    "next proc":            0x20,   // dword (pointer to proc)
}

function proc_field(base, field) => struct_field(proc__struct, base, field)

function proc_is(addr, name) => dword(proc_field(addr, "code start pointer")) == proc_defs[name]

function proc_first_child_ptr(addr) => tbyte(proc_field(addr, "first child proc")) + ewram_offset
function proc_next_proc(addr) => tbyte(proc_field(addr, "next proc")) + ewram_offset

proc_defs = {
    "DialogueSkipInputListener":    0x08591340,
    "GAMECTRL":             0x085916D4,
    "Popup":                0x085921C8,
    "MapMain":              0x0859A1F0,
    "PlayerPhase":          0x0859AAD8,
    "PhaseSwitchGfx":       0x0859AF80,
    "BattleAnimSimpleLock": 0x0859BAC4,
    "Battle":               0x0859DABC,
    "TerrainHealLoop":      0x0859E308,
    "Menu":                 0x085B64D0,
    "SaveMenu2":            0x08A203A8,
    "Shop":                 0x08A39210,
    "PromotionInit":        0x08B126CC,
    "BattlePopup":          0x08B59D78,
    "MapAnimBattle":        0x08B59E7C,
}

popup_proc_defs = {
    "SkillLearned":         0x08B5A058, // skill system
    "WeaponBroke":          0x08592420,
}

main_proc_array__mem = 0x2ea70

function main_proc_ptr(index) => tbyte(main_proc_array__mem + 4*index) + ewram_offset

function shop_proc_type(addr) => byte(addr + 0x61)

SECRET_SHOP = 0x02

item_icon_values = { // Not the same as item IDs, and doesn't work with gold.
    "Berserk":      0x51,
    "Angelic Robe": 0x59, 
    "Energy Ring":  0x5A, 
    "Secret Book":  0x5B, 
    "Speedwings":   0x5C, 
    "Goddess Icon": 0x5D, 
    "Dragonshield": 0x5E, 
    "Talisman":     0x6F, 
    "Boots":        0x60, 
    "Hero Crest":   0x62, 
    "Knight Crest": 0x63, 
    "Orion's Bolt": 0x64, 
    "Elysian Whip": 0x65, 
    "Guiding Ring": 0x66, 
    "Door Key":     0x68,
    "White Gem":    0x86, 
    "Blue Gem":     0x87, 
    "Red Gem":      0x88, 
    "Super Blitz":  0xB0, // Vanilla Sieglinde
    "Audhulma":     0xB1,
    "Vidofnir":     0xB2,
    "Garm":         0xB7,
    "Nidhogg":      0xBA,
    "Ivaldi":       0xBB,
    "Gleipnir":     0xBC,
    "Latona":       0xC3,
    "Master Seal":  0xD9, 
    "Fili Shield":  0xDA, 
    "Hoplon Guard": 0xDB, 
}

function popup_proc_def(addr) => dword(addr + 0x2c)
function popup_proc_is(addr, def_name) => popup_proc_def(addr) == popup_proc_defs[def_name]
function popup_proc_icon_id(addr) => byte(addr + 0x3e)
function popup_proc_item_icon_is(addr, icon_name) => popup_proc_icon_id(addr) == item_icon_values[icon_name]
function popup_proc_sfx_id(addr) => word(addr + 0x48) // Works even with sfx off!
function popup_proc_sfx_is(addr, value) => popup_proc_sfx_id(addr) == value 

SFX_PLAYER_ITEM_GET = 0x5A // Player unit item GET. Enemy/NPC units use the "weapon broke" sfx

// Battle proc
// is at a static location (0x28140)
battle_popup_proc__addr = tbyte(0x20140 + ewram_offset) + ewram_offset 
function battle_popup_proc_skill_learned(addr) => word(addr + 0x4e)

// Fortunately, none of these skills should be duplicated across different level up sets (ex: Live to Serve is only ever acquired at lv 10 unpromoted, no other levels)
level_10_unpromoted_skills = {
    "Aether":           16, // Ephraim Lord (also Void's personal skill)
    "Rightful King":    128,// Eirika Lord (Void)
    "Elbow Room":       99, // Cavalier
    "Natural Cover":    100,// Armor Knight
    "Acrobat":          1,  // Thief
    "Spur Speed":       60, // Mercenary
    "Vantage":          32, // Myrmidon
    "Sure Shot":        5,  // Archer
    "Tantivy":          91, // Wyvern Rider
    "Adept":            10, // Mage
    "Spur Defense":     61, // Shaman/Manakete, the latter of which is already leveled past 10
    "Desperation":      33, // Fighter
    "Intimidate":       84, // Brigand
    "Seal Skill":       102,// Pirate
    "Seal Resistance":  106,// Monk
    "Live To Serve":    79, // Priest/Cleric
    "Rally Speed":      71, // Peg Knight
    "Voice of Peace":   56, // Troubador
    "Rally Strength":   68, // Soldier
}

// (And level 10 promoted, considering Paragon)
level_5_promoted_skills = {
    "Rally Spectrum":   76, // Ephraim Great Lord
    "Nihil":            63, // Eirika Great Lord
    "Rally Skill":      70, // Paladin
    "Wary Fighter":     4,  // General
    "Sol":              15, // Hero
    "Astra":            17, // Swordmaster
    "Lifetaker":        47, // Assassin
    "Bowfaire":         41, // Sniper
    "Canto Plus":       3,  // Ranger
    "Savage Blow":      89, // Wyvern Lord / Entomed
    "Rally Movement":   75, // Wyvern Knight
    "Tomefaire":        42, // Sage, also Lv. 15 Necromancer, but that class is unobtainable
    "Rally Resistance": 74, // Mage Knight
    "Spur Resistance":  62, // Valkyrie / Bishop
    "Frenzy":           9,  // Druid
    "Anathema":         94, // Summoner
    "Lunge":            83, // Rogue
    "Luna":             14, // Great Knight
    "Death Blow":       27, // Warrior
    "Wrath":            34, // Berserker
    "Savior":           7,  // Falcoknight
    "Amaterasu":        57, // Dancer
    "Paragon":          65, // Super Trainees at Level 10, gonna count Paragon for Lv. 5 promoted
}

level_15_promoted_skills = {
    "Axebreaker":       21, // Ephraim Great Lord / Hero
    "Lancebreaker":     20, // Eirika Great Lord
    "Aegis":            24, // Paladin
    "Pavise":           25, // General
    "Swordfaire":       38, // Swordmaster
    "Pass":             2,  // Assassin
    "Galeforce":        48, // Sniper
    "Bowbreaker":       22, // Ranger
    "Swordbreaker":     19, // Wyvern Lord
    "Lancefaire":       39, // Wyvern Knight
    "Ignis":            80, // Sage
    "Quick Burn":       133,// Mage Knight
    "Counter Magic":    36, // Bishop
    "Tomebreaker":      23, // Druid
    "Renewal":          49, // Summoner
    "Celerity":         97, // Rouge / Dancer
    "Armored Blow":     31, // Great Knight
    "Counter":          35, // Warrior
    "Axefaire":         40, // Berserker
    "Warding Blow":     29, // Falcoknight
    "Charm":            55, // Valkyrie
    "Colossus":         67, // Entombed
}


function skill_cheevo(title, level_criteria, points, skill_list, id=0, badge="0") {
    battle_anims_on_trig = 
        any_of(skill_list, skill => proc_is(battle_popup_proc__addr, "BattlePopup")
            && battle_popup_proc_skill_learned(battle_popup_proc__addr) == skill_list[skill])
    battle_anims_off_popup = proc_first_child_ptr(main_proc_ptr(3))
    battle_anims_off_trig = 
        any_of(skill_list, skill => proc_is(battle_anims_off_popup, "Popup")
            && popup_proc_is(battle_anims_off_popup, "SkillLearned")
            && popup_proc_icon_id(battle_anims_off_popup) == skill_list[skill])
    
    protected_achievement(
        title=title,
        description=format("Make any unit learn a skill by training them to {0}.", level_criteria),
        points=points,
        trigger=(battle_anims_on_trig || battle_anims_off_trig),
        id=id,
        badge=badge
    )
}

skill_cheevo("A Small Bonus Before Promotion", "Lv. 10 unpromoted", 2, level_10_unpromoted_skills, id=190038, badge="210894")
skill_cheevo("Another Power Spike", "Lv. 5 or Lv. 10 promoted", 5, level_5_promoted_skills, id=190039, badge="210895")
skill_cheevo("Serious Dedication", "Lv. 15 promoted", 10, level_15_promoted_skills, id=190040, badge="210896")

dummy_achievement(
    title = "Live to Serve",
    description = "Lv. 10 Bede",
    points = 10,
    trigger = proc_is(battle_popup_proc__addr, "BattlePopup")
        && battle_popup_proc_skill_learned(battle_popup_proc__addr) == 0x4F
)

// 
// Chapters
// 

function chapter_just_started(name) => once(current_turn() == 1 && in_player_phase() && proc_is(proc_first_child_ptr(main_proc_ptr(2)), "PhaseSwitchGfx") && in_chapter(name))
function chapter_just_changed(chap, next) => just_changed(current_chapter(), map_id__values[chap], map_id__values[next])

// Turn counter is reset when selecting "restart chapter" or moving to next chapter
function turn_reset() => current_turn() < prev(current_turn())

// Unnecessary reset if main lord dies just to make the indicator go away
function remained_in_chapter_from_beginning(name) {
    if (ALLOW_SUSPEND_SAVES_FOR_TESTING == 1)
        return once(in_chapter(name)) && never(turn_reset()) && never(event_ids_set([MAIN_LORD_DIED_EID]))
    return chapter_just_started(name) && never(turn_reset()) && never(event_ids_set([MAIN_LORD_DIED_EID]))}

// In the event of a route split or variations of the same chapter (ex: Ch17-Final of vanilla FE8), just wrap the chapter checks around some any_of functions.
function chapter_complete_cheevo(title, description, chap, points, next, difficult=0, flavor_text="", id=0, badge="0") {
    
    trig = remained_in_chapter_from_beginning(chap) && trigger_when(chapter_just_changed(chap, next))
    if (difficult != 0)
        trig = trig && in_hard_mode()

    protected_achievement(
        title=title,
        description=format(description, chap) + flavor_text,
        points=points,
        trigger=trig,
        id=id,
        badge=badge
    )
}

function chapters_meta(title, description, points, next, flavor_text="", id=0, badge="0") => {"title": title, "description": description, "points": points, "next": next, "flavor text": flavor_text, "id": id, "badge": badge}

chapter_cheevo_infos = {
    "Prologue":     chapters_meta("IT BEGINS", "Defeat O'Neill and seize the gate in the {0}.", 5, "Chapter 1", " Watch out for enemy skills!", id=190043, badge="210899"),
    "Chapter 1":    chapters_meta("Secret Chapter", "Escort Breguet to the village and seize the path in {0}.", 5, "Chapter 2", id=190042, badge="210898"),  
    "Chapter 2":    chapters_meta("The Bone Hole", "Do Bede a favor and seize the gate in {0}.", 5, "Chapter 3", id=190056, badge="210912"),
    "Chapter 3":    chapters_meta("Compile Proyect", "Slay Bazba Jenkins in {0}.", 5, "Chapter 4", id=190066, badge="210922"),
    "Chapter 4":    chapters_meta("Monkey Business", "Seize the Donateenary fort in {0}.", 5, "Chapter 5", id=190067, badge="210923"),
    "Chapter 5":    chapters_meta("Winter Invasion", "Fight through Saara's winter storm and seize the gate in {0}.", 10, "Chapter 6", id=190068, badge="210924"),
    "Chapter 6":    chapters_meta("Fort of Bad", "Defeat the generic armor knight and seize the throne in {0}.", 5, "Chapter 7", id=190069, badge="210925"),
    "Chapter 7":    chapters_meta("Port of Bad", "End Murray's donation demands by slaying him in {0}.", 5, "Chapter 8", id=190070, badge="210926"),
    "Chapter 8":    chapters_meta("Yet Another Chapter", "Help out Prine by routing the enemy in {0}.", 5, "Chapter 9", id=190071, badge="210927"),
    "Chapter 9":    chapters_meta("Tragic Backstory", "Avenge Edge's men by seizing the gate in {0}.", 5, "Chapter 10", id=190072, badge="210928"),
    "Chapter 10":    chapters_meta("here you like Men", "Rout the enemy in {0}.", 5, "Chapter 11", " One of them might be a friendly...", id=190046, badge="210902"),
    "Chapter 11":    chapters_meta("Factory Gold", "Seize the throne in {0}.", 5, "Chapter 12", " Take every droppable and stealable you can!", id=190047, badge="210903"),
    "Chapter 12":    chapters_meta("I Felt Sadistic", "Defeat both bosses in {0}.", 10, "Chapter 13", " Gheb really meant no harm...", id=190048, badge="210904"),
    "Chapter 13":    chapters_meta("Course. Rough. Irritating.", "Rout the enemy in {0}.", 5, "Chapter 14", id=190049, badge="210905"),
    "Chapter 14":    chapters_meta("Attack on Basement", "Overthrow Carlyle, the new Basement King, in {0}.", 5, "Chapter 15", id=190050, badge="210906"),
    "Chapter 15":    chapters_meta("The Shark Straits", "Defeat Grit and seize Blue Moon's HQ in {0}.", 10, "Chapter 16", id=190051, badge="210907"),
    "Chapter 16":    chapters_meta("Dead Valley", "Slay Orson in {0}.", 10, "Chapter 17", id=190052, badge="210908"),
    "Chapter 17":    chapters_meta("\'Slowly\' Corrupting", "Seize the throne in {0}.", 5, "Chapter 18", id=190053, badge="210909"),
    "Chapter 18":    chapters_meta("Island Clash", "Defeat Vigarde in {0}.", 5, "Chapter 19", " The filler arc begins...", id=190054, badge="210910"),
    "Chapter 19":    chapters_meta("Lit Chapter", "Seize Maeda's door in {0}.", 5, "Chapter 20", id=190055, badge="210911"),
    "Chapter 20":    chapters_meta("Great Rivalry", "Defeat Maeda and seize the throne in {0}.", 10, "Chapter 21", id=190057, badge="210913"),
    "Chapter 21":    chapters_meta("Doot Doot", "Slay Tatara of the Doma Faithful in {0}.", 5, "Chapter 22", id=190027, badge="210883"),
    "Chapter 22":    chapters_meta("N i c e B o a t s", "Defeat and recruit Celica in {0}.", 5, "Chapter 23", id=190058, badge="210914"),
    "Chapter 23":    chapters_meta("Flesh and Bone", "Seize Mr. Bones\'s spooky scary skeleton seat in {0}.", 10, "Chapter 24", id=190059, badge="210915"),
    "Chapter 24":    chapters_meta("River Rush", "Show Gwendolyn that she's a bad unit by defeating her in {0}.", 10, "Chapter 25", id=190060, badge="210916"),
    "Chapter 25":    chapters_meta("Shrine of Meals", "Defeat Banana and seize the throne in {0}.", 10, "Chapter 26", id=190061, badge="210917"),
    "Chapter 26":    chapters_meta("Darrman's Lakes", "Go deeper into Donateenary territory and seize the gate in {0}.", 10, "Chapter 27", id=190062, badge="210918"),
    "Chapter 27":    chapters_meta("Convenient Lake", "Seize the gate in {0}.", 10, "Chapter 28", id=190063, badge="210919"),
    "Chapter 28":    chapters_meta("Mess.jpg", "Regroup your army and seize the gate in {0}.", 10, "Chapter 29", id=190064, badge="210920"),
    "Chapter 29":    chapters_meta("Let It Be", "Kill Lyon in {0}.", 10, "Final Chapter", id=190065, badge="210921"),
}

for chap in chapter_cheevo_infos {
    chapter_complete_cheevo(chapter_cheevo_infos[chap]["title"], 
    chapter_cheevo_infos[chap]["description"], 
    chap, 
    chapter_cheevo_infos[chap]["points"], 
    chapter_cheevo_infos[chap]["next"], 
    flavor_text=chapter_cheevo_infos[chap]["flavor text"], 
    id=chapter_cheevo_infos[chap]["id"], 
    badge=chapter_cheevo_infos[chap]["badge"])
}

difficult_chapters = {
    "Chapter 5":    chapters_meta("The Frontloaded Earlygame", "Complete {0} on Difficult.", 25, "Chapter 6", id=190083, badge="210939"),
    "Chapter 12":   chapters_meta("The Random Difficulty Spikes", "Complete {0} on Difficult.", 25, "Chapter 13", id=190080, badge="210936"),
    "Chapter 16":   chapters_meta("Halfway Through the Mooks", "Complete {0} on Difficult.", 25, "Chapter 17", id=190091, badge="210947"),
    "Chapter 20":   chapters_meta("The Boring Midgame", "Complete {0} on Difficult.", 25, "Chapter 21", id=190081, badge="210937"),
    "Chapter 24":   chapters_meta("Quantity Over Quality", "Complete {0} on Difficult.", 25, "Chapter 25", id=190082, badge="210938"),
}

for chap in difficult_chapters {
    chapter_complete_cheevo(difficult_chapters[chap]["title"], 
    difficult_chapters[chap]["description"], 
    chap, 
    difficult_chapters[chap]["points"], 
    difficult_chapters[chap]["next"], 
    difficult=1, 
    flavor_text=difficult_chapters[chap]["flavor text"], 
    id=difficult_chapters[chap]["id"], 
    badge=difficult_chapters[chap]["badge"])
}

// Final Chapter (One on not-casual, one on Difficult)
function demon_king_dead_in_final_chapter() {
    return remained_in_chapter_from_beginning("Final Chapter")
    && trigger_when(event_ids_set([BOSS_DEATH_QUOTE_EID], 1)
    && nth_unit_was("enemy", 0, "Feditor")
    && nth_unit_is("enemy", 0, "Blank")) // vanilla FE8 set style checking if dk was killed
}

protected_achievement(
    title="Family Avenged",
    description="Slay the Demon King in the Final Chapter.",
    points=25,
    trigger=demon_king_dead_in_final_chapter(),
    id=190086,
    badge="210942"
)

protected_achievement(
    title="The Brutal Endgame",
    description="Complete the game on Difficult.",
    points=50,
    trigger=demon_king_dead_in_final_chapter() && in_hard_mode(),
    id=190087,
    badge="210943"
)

// Full Recruitment

protected_achievement(
    title="Nobody Left Behind",
    description="Recruit all 34 obtainable characters and complete the game without any of them dying.",
    points=50,
    // Again, Void is always unit 0, no need to check for her
    trigger=all_of(range(1, 33), a => nth_unit_exists("player", a))
        && none_of(range(1, 33), a => nth_unit_dead("player", a))
        && none_of(range(1, 33), a => nth_unit_class_is("player", a, "phantom"))
        && demon_king_dead_in_final_chapter(),
    // Indicator pops up when you're in final chapter with everyone recruited and alive
    id=190088,
    badge="210944"
)

battle_round_array__mem = 0x42ac0

function first_attack_is_triangle_attack() {
    return bit0(battle_round_array__mem) != 0 // crit check
    && bit2(battle_round_array__mem + 1) != 0 // triangle attack check
}

function performed_triangle_attack() {
    return in_player_phase()
    && action_taken_is_combat()
    && first_attack_is_triangle_attack()
}

protected_achievement(
    title="Cash Money Triangle",
    description="Perform a triangle attack with the three Anna's (see comment).",
    points=5,
    trigger=performed_triangle_attack(),
    id=190090,
    badge="210946"
)

// Secret Shops
function shop_proc_is_secret(addr) {
    return proc_is(addr, "Shop")
        && shop_proc_type(addr) == SECRET_SHOP
}

function secret_shop_cheevo(title, hint, chap, points, flavor_text="", id=0, badge="0") {
    trig=in_chapter(chap) && shop_proc_is_secret(main_proc_ptr(3)) // Allow suspend saves 'cause no indicator
    
    protected_achievement(
        title=title,
        description=format("Discover a secret shop {0}.{1}", hint, flavor_text),
        points=points,
        trigger=trig,
        id=id,
        badge=badge
    )
}

secret_shop_cheevo("A Friend's Place", "where Anna told you", "Chapter 15", 5, " You got your member card back, right?", id=190074, badge="210930")
secret_shop_cheevo("Spooky Scary Shop", "near some skeleton ships", "Chapter 23", 5, id=190075, badge="210931")
secret_shop_cheevo("By the River", "at a lone house in the middle of many, many red units", "Chapter 24", 5, id=190076, badge="210932")


//
//  Tile Changes
//
//  For Chapter 6 challenge + some reset-if-village-is-destroyed logic
//

terrain_map__addr = 0x2e4dc + ewram_offset // Points to table of row pointers
// Is NOT the same as visual tiles (ex: the destroyed village consists of 6 different tiles, but they are all of terrain type 0x25, ruins)

function value_from_map(ptr, x, y) {
    row_table__addr = tbyte(terrain_map__addr) + ewram_offset
    row__addr = tbyte(row_table__addr + y * 4) + ewram_offset
    return byte(row__addr + x)
}

function tile_chest_opened(x, y) {
    return prev(value_from_map(terrain_map__addr, x, y)) == 0x21
        && value_from_map(terrain_map__addr, x, y) == 0x20
}

function tile_village_destroyed(x, y) {
    return value_from_map(terrain_map__addr, x, y) == 0x25
    // 0x25 == "Ruins"
}

dummy_achievement(
    title = "DUMMY",
    description = "x",
    points = 0,
    trigger = tile_chest_opened(0, 1) // Chapter 12 guiding ring chest
)

// The enemy thieves are too stupid to open the chests (their AI will attack you), so only Bob can open the chests (as a Player or NPC unit), which I can allow
function ch6_special_clear_trigger() {
    return remained_in_chapter_from_beginning("Chapter 6")
    && current_turn() < 14
    && trigger_when(once(tile_chest_opened(16, 1))
    && once(tile_chest_opened(11, 1))
    && once(tile_chest_opened(1, 12))
    && chapter_just_changed("Chapter 6", "Chapter 7"))
}

protected_achievement(
    title = "Before You Get Overwhelmed",
    description = "In Chapter 6, open all 3 chests and seize the throne before Turn 14. Enemy thieves will not open chests.",
    points = 10,
    trigger = ch6_special_clear_trigger(),
    id=190077,
    badge="210933"
)

//
//  Recruitments
//

function recruitment_cheevo(title, char, chap, points, eids, check_suspend_point=0, check_menu=0, flavor_text="", additional_logic=always_true(), id=0, badge="0"){
    trig = remained_in_chapter_from_beginning(chap) && additional_logic && trigger_when(event_ids_set(eids, 1))
    if check_suspend_point == 1
        trig = trig && trigger_when(suspend_point_changed())
    if check_menu == 1
        trig = trig && trigger_when(proc_is(main_proc_ptr(3), "Menu"))
        
    protected_achievement(
        title=title,
        description=format("Recruit {0} in {1}.{2}", char, chap, flavor_text),
        points=points,
        trigger=trig,
        id=id,
        badge=badge
    )
}

// In the event that character recruitment can't be linked to an event id (ex: they must survive until the end of the chapter),
// just check every possible player unit slot for that character
function recruitment_cheevo_fallback(title, char, chap, points, num_units, flavor_text="", additional_logic=always_true(), id=0, badge="0") {
    trig = remained_in_chapter_from_beginning(chap) && additional_logic
    
    // Void *always* takes up unit slot 0, in prep menus and beforehand
    unit_check = any_of(range(1, num_units), a => nth_unit_is("player", a, char))
    
    protected_achievement(
        title=title,
        description=format("Recruit {0} in {1}.{2}", char, chap, flavor_text),
        points=points,
        trigger=trig && trigger_when(unit_check),
        id=id,
        badge=badge
    )
}

recruitment_cheevo_fallback("Secret Seller", "Myrmidon Anna", "Chapter 1", 5, 1+6, flavor_text=" You'll get your Member Card back soon...", id=190015, badge="210871") // finicky event ids
    // really not gonna bother with reset-if-this-unit-dies logic for most of these, especially when the character can be easily recruited turn 1
recruitment_cheevo("Renegade Translator", "Jay", "Chapter 3", 5, eids=[7], check_suspend_point=1, additional_logic=
    never(tile_village_destroyed(6, 6)), id=190016, badge="210872")   // village
    // villages are less clear, so challenge indicator will go away when the respective village is destroyed
recruitment_cheevo("Divine Lightning", "Not Arch", "Chapter 4", 5, eids=[7], check_suspend_point=1, additional_logic=
    never(tile_village_destroyed(19, 9)), id=190017, badge="210873") // village
recruitment_cheevo("You What, Mate?", "Kirsten", "Chapter 5", 5, eids=[7], check_menu=1, id=190018, badge="210874")   // talk
recruitment_cheevo("The Builder", "Bob", "Chapter 6", 5, eids=[0x20], check_menu=1, id=190019, badge="210875") // talk
recruitment_cheevo("Former Wolfguard", "Roshea", "Chapter 7", 5, eids=[9], check_suspend_point=1, additional_logic=
    never(tile_village_destroyed(19, 1)), id=190020, badge="210876") // village
recruitment_cheevo("Edgy Palette", "Edge", "Chapter 9", 5, eids=[7], check_menu=1, id=190021, badge="210877") // talk
recruitment_cheevo("The Confused", "Samson", "Chapter 10", 5, eids=[0x14], check_menu=1, id=190022, badge="210878") // talk
recruitment_cheevo("Sturdy General", "Tye", "Chapter 12", 5, eids=[7], check_menu=1, id=190023, badge="210879") // talk
    
recruitment_cheevo("Mysterious Mage", "Celicia", "Chapter 13", 5, eids=[8], check_menu=1, id=190024, badge="210880") // talk
recruitment_cheevo("Basement King", "Eevster", "Chapter 14", 5, eids=[0x10], check_menu=1, id=190025, badge="210881") // talk
recruitment_cheevo("Another Anna", "Wyvern Anna", "Chapter 15", 5, eids=[0x0D], check_menu=1, id=190026, badge="210882") // talk
recruitment_cheevo_fallback("Echoes Character", "Doot", "Chapter 21", 5, 21+6, additional_logic=
    never(repeated(5, nth_unit_was("enemy", 1, "Doot") && nth_unit_is("enemy", 1, "Blank"))), id=190073, badge="210929") // make survive until end
    // added additional resets to make it clearer that you gotta keep these people alive
recruitment_cheevo("Lycian Knight?", "Doowile", "Chapter 23", 5, eids=[0x08], check_menu=1, id=190031, badge="210887") // talk
recruitment_cheevo_fallback("What Next?", "Evil Florina", "Chapter 24", 5, 24+6, flavor_text=" Note: She pays you to join you.", id=190032, badge="210888") // talk + gold offer
recruitment_cheevo_fallback("Banana Slayer", "Bjorn", "Chapter 25", 5, 23+7, additional_logic=
    never(repeated(5, nth_unit_was("npc", 0, "Bjorn") && nth_unit_is("npc", 0, "Blank"))), id=190028, badge="210884") // make survive until end
    // Just to be safe, check a couple more unit slots in case Phantoms are on the field, and they appear later in the player unit list
recruitment_cheevo("Anna's Husband", "Jake", "Chapter 26", 5, eids=[7], check_menu=1, id=190029, badge="210885") // talk
recruitment_cheevo_fallback("Mysterious Tactician", "Marf", "Chapter 27", 5, 27+7,  additional_logic=
    never(tile_village_destroyed(17, 2)), id=190030, badge="210886") // village without an event id

// Villages - just check event ids
// Enemies will never naturally visit villages (only destroy them), and I can easily protect against control enemy cheat.
function village_cheevo(title, housing, chap, points, eids, flavor_text="", additional_logic=always_true(), id=0, badge="0") {
    trig = remained_in_chapter_from_beginning(chap) && additional_logic
        && trigger_when(event_ids_set(eids, 1) && suspend_point_changed())
    
    protected_achievement(
        title=title,
        description=format("Visit {2} in {0}.{1}", chap, flavor_text, housing),
        points=points,
        trigger=trig,
        id=id,
        badge=badge
    )
}

village_cheevo("Hey Look! A Thing!", "both villages", "Chapter 2", 5, eids=[8, 9], additional_logic=
    never(tile_village_destroyed(14, 1)) && never(tile_village_destroyed(14, 10)), id=190033, badge="210889")
village_cheevo("Just Barging In", "both villages", "Chapter 8", 5, eids=[6, 7], additional_logic=
    never(tile_village_destroyed(2, 2)) && never(tile_village_destroyed(16, 9)), id=190034, badge="210890")
village_cheevo("More Free Stuff", "both houses", "Chapter 10", 5, eids=[0x12, 0x13], id=190035, badge="210891")
village_cheevo("Gifts from Wars World", "the village and both houses", "Chapter 15", 5, eids=[0x0A, 0x0B, 0x0C], additional_logic=
    never(tile_village_destroyed(4, 13)), id=190036, badge="210892")
village_cheevo("The Other River Folk", "both villages", "Chapter 24", 5, eids=[0x07, 0x08], flavor_text=" All these enemies and no wyverns to use these weapons on!", additional_logic=
    never(tile_village_destroyed(13, 1)) && never(tile_village_destroyed(1, 7)), id=190089, badge="210945")
village_cheevo("Even More Lore", "every village", "Chapter 26", 5, eids=[0x08, 0x09, 0x10], additional_logic=
    never(tile_village_destroyed(11, 7)) && never(tile_village_destroyed(2, 15)) && never(tile_village_destroyed(19, 12)), id=190037, badge="210893")

//
//  Got Items
//
function popup_proc_player_got_item(proc, item_name) { // takes in a 6c address and checks if icon and sfx are right
    return proc_is(proc, "Popup")
    && popup_proc_item_icon_is(proc, item_name)
    && popup_proc_sfx_is(proc, SFX_PLAYER_ITEM_GET)
}

// Lacking functionality for duplicate items, and situations where thieves can steal your items
// Likely resolvable with some deltas and subhits, but I don't have to worry about those cases for this hack...

function got_items_triggered_and_measured(item_list, chap) {
    arr = []
    popup_proc_from_map_event   = proc_first_child_ptr(proc_first_child_ptr(main_proc_ptr(3))) //chest/village
    popup_proc_from_steal       = proc_first_child_ptr(main_proc_ptr(3)) //steal from enemy thief
    popup_proc_from_pp_fight    = proc_first_child_ptr(proc_first_child_ptr(proc_first_child_ptr(proc_first_child_ptr(main_proc_ptr(2))))) //kill enemy thief on player phase
    popup_proc_from_bp_fight    = proc_first_child_ptr(proc_first_child_ptr(proc_first_child_ptr(proc_first_child_ptr(proc_first_child_ptr(proc_first_child_ptr(proc_first_child_ptr(main_proc_ptr(2)))))))) //counterattack and kill enemy thief when thief is berserked - 8 nested procs, yeah...
    
    for item_name in item_list {
        array_push(arr, once(popup_proc_player_got_item(popup_proc_from_map_event, item_name)))
        array_push(arr, once(popup_proc_player_got_item(popup_proc_from_steal, item_name)))
        array_push(arr, once(popup_proc_player_got_item(popup_proc_from_pp_fight, item_name)))
        array_push(arr, once(popup_proc_player_got_item(popup_proc_from_bp_fight, item_name)))
    }
    return trigger_when(tally(length(item_list), arr)) || measured(tally(length(item_list), arr), when=in_chapter(chap))
}

function get_items_cheevo(title, chap, points, item_list, flavor_text="", id=0, badge="0") {
    chapter = chap
    if (chap == "Prologue" || chap == "Final Chapter") {
        chapter = format("the {0}", chap)
    }
    protected_achievement(
        title=title,
        description=format("Obtain the items from every chest in {0}.{1}", chapter, flavor_text),
        points=points,
        trigger= remained_in_chapter_from_beginning(chap) && got_items_triggered_and_measured(item_list, chap)
    )
}

get_items_cheevo("Sadistic Treasure Hunt", "Chapter 12", 10, ["Blue Gem", "Hero Crest", "Guiding Ring", "Speedwings", "Boots", "Berserk"], id=190041, badge="210897")
get_items_cheevo("Corrupting Treasure Trove", "Chapter 17", 3, ["Nidhogg", "Door Key"], flavor_text=" Where did the draco zombie go?", id=190044, badge="210900")
get_items_cheevo("Maeda's Loot", "Chapter 20", 5, ["Boots", "Hero Crest", "Elysian Whip"], id=190045, badge="210901")
get_items_cheevo("The Last Sacred Twins", "Final Chapter", 5, ["Garm", "Latona"], flavor_text=" Got the weapon ranks to use them?", id=190084, badge="210940")

// Miscellaneous Juice

protected_achievement(
    title = "Impostor Destroyed",
    description = "In Chapter 16, let Nikita deal the killing blow to Orson.",
    points = 10,
    trigger = remained_in_chapter_from_beginning("Chapter 16")
    && never(turn_reset())
    && trigger_when(event_id_just_set(BOSS_DEATH_QUOTE_EID))
    && (trigger_when(battle_actor_unit_is("Nikita"))
    || trigger_when(battle_target_unit_is("Nikita"))), // In case he kills by counterattacking
    id=190078,
    badge="210934"
)

protected_achievement(
    title = "Wars World Gladiator",
    description = "In Chapter 15, win a battle at the arena. A reminder that skills and rallies will work in arena battles!",
    points = 5,
    trigger = remained_in_chapter_from_beginning("Chapter 15")
    && trigger_when(arena_battle_won()),
    id=190079,
    badge="210935"
)

protected_achievement(
    title = "Messy Gladiator",
    description = "In Chapter 28, win a battle at the arena.",
    points = 5,
    trigger = remained_in_chapter_from_beginning("Chapter 28")
    && trigger_when(arena_battle_won()),
    id=190085, 
    badge="210941"
)

//-------
// b w l
//-------

battle_stats__struct = {
    "losses":           0x00, // byte
    "learned skills":   0x01, // 4 bytes
    "wins":             0x0b, // 10 bits, 1000 cap
    "battles":          0x0c, // 12 bits, offset by 2 bits from win count, 4000 cap
}
battle_stats__sizeof = 0x10

function battle_stats_field(base, field) => struct_field(battle_stats__struct, base, field)

function battle_stats_losses(addr) => byte(battle_stats_field(addr, "losses"))
function battle_stats_wins(addr) {
    sum = 0
    base = battle_stats_field(addr, "wins")
    sum = sum + byte(base) + bit0(base+1)*256 + bit1(base+1)*512
    return sum
}

// how to combine bitmasks with multiplication :/
function battle_stats_battles(addr) {
    sum = 0
    base = battle_stats_field(addr, "battles")
    sum = sum + bit2(base) + bit3(base)*2 + bit4(base)*4 + bit5(base)*8 + bit6(base)*16 + bit7(base)*32
        + bit0(base+1)*64 + bit1(base)*128 + bit2(base)*256 + bit3(base)*512 + bit4(base)*1024 + bit5(base)*2048
    return sum
}

battle_stats_table__addr = 0x46894

function nth_battle_stats(index) => battle_stats_table__addr + index * battle_stats__sizeof

function nth_battle_stats_losses(index) => battle_stats_losses(nth_battle_stats(index))
function nth_battle_stats_wins(index) => battle_stats_wins(nth_battle_stats(index))
function nth_battle_stats_battles(index) => battle_stats_battles(nth_battle_stats(index))

function sum_stats(stat) {
    stat_dict = {
        "losses":   nth_battle_stats_losses,
        "wins":     nth_battle_stats_wins,
        "battles":  nth_battle_stats_battles,
    }
    stat_func = stat_dict[stat]
    return sum_of(range(0, 35), i => stat_func(i))
}

//-----
// r p
//-----

function generate_flipped_map_id_values() {
    new_dict = {}
    for key in map_id__values {
        new_key = key
        if (key == "Prologue" || key == "Final Chapter")
            new_key = format("the {0}", key)
        
        val = map_id__values[key]
        new_dict[val] = new_key
    }
    return new_dict
}

flipped_map_ids = generate_flipped_map_id_values()

rich_presence_conditional_display(once(event_ids_set([CHEATING_EID])), "CHEATING / Debugging this session - Achievements are locked") // hit w/out reset
rich_presence_conditional_display(event_ids_set([CASUAL_EID]), "Playing on Casual Mode - Please start a playthrough with permadeath to enable achievements and Rich Presence")
rich_presence_conditional_display(any_of(flipped_map_ids, a => current_chapter() == a) && clock() != 0, 
    "Strategizing in {1}{0} on {3} | Turn {2} | Losses: {4}",
    rich_presence_lookup("Chapters", current_chapter(), flipped_map_ids),
    rich_presence_lookup("Prep Menu", prep_menu(), {0:"", 1:"the prep menu for "}),
    rich_presence_value("Number", current_turn()),
    rich_presence_lookup("Difficulty", hard_mode(), {0:"Normal", 1:"Difficult"}),
    rich_presence_value("Number", sum_stats("losses")),
    rich_presence_value("Number", sum_stats("wins")), // Scrap these, not sure how to fix atm
    rich_presence_value("Number", sum_stats("battles"))
    )
rich_presence_conditional_display(current_chapter() == 0x3A, "In the Link Arena - play at your own risk!")
rich_presence_display("On a blitzarre adventure (Title Screen / Sound Room / viewing nonexistent Supports)")
