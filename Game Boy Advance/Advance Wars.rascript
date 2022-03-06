// Advance Wars
// #ID = 506

function constant_in_list(const, arr) {
    for thing in arr {
        if (const == thing)
            return true
    }
    return false
}

map_id__addr = 0x4312
map_id__mem = byte(map_id__addr)

victory_state__addr = 0x27dd5
victory_state__mem = byte(victory_state__addr)

ac_flag__addr = 0x1a28d
function advance_campaign_flag() => byte(ac_flag__addr)

game_mode__addr = 0x27d93
game_mode__mem = byte(game_mode__addr)

game_modes = {
    "Campaign": 0x01
}

function game_mode_is(name) => game_mode__mem == game_modes[name]

function ac_mission_meta(title, id=0, badge="0") => {
    "title": title,
    "id": id,
    "badge": badge
}

ac_missions = {
    "Mission 1":  ac_mission_meta("It's War!",           11491, "80327"),
    "Mission 2":  ac_mission_meta("Gunfighter!",         11492, "80328"),
    "Mission 3":  ac_mission_meta("Air Ace!",            11493, "80329"),
    "Mission 4":  ac_mission_meta("Max Strikes!",        11494, "80330"),
    "Mission 5a": ac_mission_meta("Max's Folly?",        11495, "80331"),
    "Mission 6a": ac_mission_meta("Olaf's Navy!",        11496, "80332"),
    "Mission 5b": ac_mission_meta("Sniper!",             11497, "80333"),
    "Mission 6b": ac_mission_meta("Blizzard Battle!",    11498, "80334"),
    "Mission 7b": ac_mission_meta("History Lesson!",     11499, "80335"),
    "Mission 7a": ac_mission_meta("Olaf's Sea Strike!",  11500, "80336"),
    "Mission 8":  ac_mission_meta("Sami's Debut!",       11501, "80337"),
    "Mission 9":  ac_mission_meta("Kanbei Arrives!",     11502, "80338"),
    "Mission 10": ac_mission_meta("Mighty Kanbei!",      11503, "80339"),
    "Mission 11": ac_mission_meta("Kanbei's Error?",     11504, "80340"),
    "Mission 12": ac_mission_meta("Divide and Conquer!", 11505, "80341"),
    "Mission 13": ac_mission_meta("Sami Marches On!",    11506, "80342"),
    "Mission 14": ac_mission_meta("Sonja's Goal!",       11507, "80343"),
    "Mission 15": ac_mission_meta("Captain Drake!",      11508, "80344"),
    "Mission 16": ac_mission_meta("Naval Clash!",        11509, "80345"),
    "Mission 17": ac_mission_meta("Wings of Victory!",   11510, "80346"),
    "Mission 18": ac_mission_meta("Battle Mystery!",     11511, "80347"),
    "Mission 19": ac_mission_meta("Andy Times Two!",     11512, "80348"),
    "Mission 20": ac_mission_meta("Enigma!",             11513, "80349"),
    "Mission 21": ac_mission_meta("The Final Battle!",   11514, "80350"),
    "Mission 22": ac_mission_meta("Rivals!",             11515, "80351"),
}    

    
maps = [                          
    "It's War!",                  
    "Gunfighter!",                 
    "Air Ace!",                    
    "Max Strikes! (Andy)",        
    "Max's Folly?",                
    "Olaf's Navy!",                
    "Olaf's Sea Strike!",
    "Max Strikes! (Max)",
    "Sniper!",
    "Blizzard Battle!",
    "History Lesson!",
    "Sami's Debut!",
    "Kanbei Arrives!",
    "Mighty Kanbei!",
    "Kanbei's Error?",
    "Divide and Conquer!",
    "Sami Marches On!",
    "Sonja's Goal!",
    "Captain Drake! (Andy)",
    "Captain Drake! (Max)",
    "Captain Drake! (Sami)",
    "Naval Clash! (Andy)",
    "Naval Clash! (Max)",
    "Naval Clash! (Sami)",
    "Wings of Victory! (Andy)",
    "Wings of Victory! (Max)",
    "Wings of Victory! (Sami)",
    "Battle Mystery! (Andy)",
    "Battle Mystery! (Max)",
    "Battle Mystery! (Sami)",
    "Andy Times Two!",
    "Enigma!",
    "The Final Battle!",
    "Rivals!",
]

map_ids = {}

campaign_id = 0x82
for map in maps {
    map_ids[map] = campaign_id
    campaign_id = campaign_id + 1
}

for mission in ac_missions {
    valid_maps = []
    title = ac_missions[mission]["title"]
    
    // a couple missions have different map ids depending on the CO, and the advance campaign logic must check for all of them
    if (constant_in_list(title, ["Max Strikes!", "Captain Drake!", "Naval Clash!", "Wings of Victory!", "Battle Mystery!"])) {
        array_push(valid_maps, map_ids[format("{0} (Andy)", title)])
        array_push(valid_maps, map_ids[format("{0} (Max)", title)])
        if (title != "Max Strikes!")
            array_push(valid_maps, map_ids[format("{0} (Sami)", title)])
    } else
        array_push(valid_maps, map_ids[title])
    
    mission_complete_trigger = never(!game_mode_is("Campaign"))
        && advance_campaign_flag() == 1
        && any_of(valid_maps, m => map_id__mem == m)
        && once(victory_state__mem == 0)
        && victory_state__mem == 1
    
    achievement(
        title = format("{0} (Advance Campaign)", title),
        description = format("Beat Advance Campaign Mission \"{0}\"", title),
        points = 10,
        trigger  = mission_complete_trigger,
        id = ac_missions[mission]["id"],
        badge = ac_missions[mission]["badge"]
    )
}

