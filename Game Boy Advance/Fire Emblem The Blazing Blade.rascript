// Fire Emblem: The Blazing Blade
// #ID = 554

// ------------- //
//   u t i l s   //
// ------------- //

ewram_offset = 0x8000

function just_increased(mem) => mem > prev(mem)

function just_changed_any(mem) => mem != prev(mem)
function just_changed(mem, from, to) => prev(mem) == from && mem == to
function just_changed_to(mem, to) => prev(mem) != to && mem == to

function struct_field(struct_def, base, field) => base + struct_def[field]

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

function music_id() => byte(0x2ce20)
function battle_history_timer() => word(0x289a)

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
    "Battle History US":    0x08CC51D0,
    "Battle History EU":    0x08DC4D20,
}

main_proc_array__mem = 0x2ea30

function main_proc_ptr(index) => tbyte(main_proc_array__mem + 4*index) + ewram_offset

function lookup(type, offset) => {"type": type, "offset": offset}

battle_history__struct = {
    "Tactics Rank":     lookup("byte", 0x34),
    "Survival Rank":    lookup("byte", 0x35),
    "Funds Rank":       lookup("byte", 0x36),
    "EXP Rank":         lookup("byte", 0x37),
    "Combat Rank":      lookup("byte", 0x38),
    "Overall Rank":     lookup("byte", 0x39),
    "Tactician Stars":  lookup("byte", 0x3A),
    "Completed Tale":   lookup("byte", 0x3B),
    "Lord":             lookup("byte", 0x3C),
    "Difficulty":       lookup("byte", 0x3D),
    
    "Assets":           lookup("word", 0x54),
}

battle_history_proc = proc_first_child_ptr(proc_first_child_ptr(proc_next_proc(main_proc_ptr(3))))

function battle_history_field(field){
    lookup = battle_history__struct[field]
    return mem_access(battle_history_proc + lookup["offset"], lookup["type"])
}

achievement(
    title = "Sacaen Pride", description = "S-rank Lyn's Hard Tale then view her battle history. [See comments or forum]", points = 25,
    id = 33533, badge = "176592",
    trigger = battle_history_timer() > 0 && music_id() == 0x29
        && battle_history_field("Difficulty") == 1 // HM
        && battle_history_field("Lord")       == 0 // Lyn
        && battle_history_field("Completed Tale")   == 1 // 0 if empty
        && battle_history_field("Overall Rank") == 5 // S Rank
        
        && (proc_is(battle_history_proc, "Battle History US") || proc_is(battle_history_proc, "Battle History EU"))
)

achievement(
    title = "Expert Tactician", description = "A-rank E or H's Tale then view his battle history. [See comments or forum]", points = 25,
    id = 33534, badge = "176593",
    trigger = battle_history_timer() > 0 && music_id() == 0x29
        && battle_history_field("Difficulty") <= 1 // NM or HM
        && battle_history_field("Lord")       > 0 // Not Lyn
        && battle_history_field("Lord")       <= 2 // E or H
        && battle_history_field("Completed Tale")   == 1 // 0 if empty
        && battle_history_field("Overall Rank") >= 4 // min. A Rank
        && battle_history_field("Overall Rank") <= 5 // max. S Rank
        
        && (proc_is(battle_history_proc, "Battle History US") || proc_is(battle_history_proc, "Battle History EU"))
)

// Ticket 51341: I got S rank, but I only gotten the A rank cheev and not the S rank one.
//               RetroAchievements Hash: Unknown
//               Emulator: RetroArch (MGBA)
//               Emulator Version: 1.60
achievement(
    title = "Grandmaster Tactician", description = "S-rank E or H's Tale then view his battle history. [See comments or forum]", points = 50,
    id = 33535, badge = "176594",
    trigger = battle_history_timer() > 0 && music_id() == 0x29
        && battle_history_field("Difficulty") <= 1 // NM or HM
        && battle_history_field("Lord")       > 0 // Not Lyn
        && battle_history_field("Lord")       <= 2 // E or H
        && battle_history_field("Completed Tale")   == 1 // 0 if empty
        && battle_history_field("Overall Rank") == 5 // max. S Rank
        
        && (proc_is(battle_history_proc, "Battle History US") || proc_is(battle_history_proc, "Battle History EU"))
)