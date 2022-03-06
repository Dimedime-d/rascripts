// Advance Wars
// #ID = 506

achievement(
    title = "It's War! (Advance Campaign)", description = "Beat Advance Campaign Mission \"It's War!\"", points = 10,
    id = 11491, badge = "80327", published = "8/14/2014 4:42:09 AM", modified = "2/22/2022 10:31:37 AM",
    trigger = byte(0x01A284) == 0x01 && repeated(60, byte(0x01A3A4) <= 0x05) && unless(byte(0x01A3A4) == 0xFF) && 
              never(byte(0x01A284) != 0x01) && prev(dword(0x004358)) != 0x00 && prev(byte(0x01A3A4)) == 0xFF
)

achievement(
    title = "Gunfighter! (Advance Campaign)", description = "Beat Advance Campaign Mission \"Gunfighter!\"", points = 10,
    id = 11492, badge = "80328", published = "8/14/2014 4:42:11 AM", modified = "2/22/2022 10:31:38 AM",
    trigger = byte(0x01A284) == 0x01 && repeated(60, byte(0x01A3A8) <= 0x05) && unless(byte(0x01A3A8) == 0xFF) && 
              never(byte(0x01A284) != 0x01) && prev(dword(0x004358)) != 0x00 && prev(byte(0x01A3A8)) == 0xFF
)

achievement(
    title = "Air Ace! (Advance Campaign)", description = "Beat Advance Campaign Mission \"Air Ace!\"", points = 10,
    id = 11493, badge = "80329", published = "8/14/2014 4:42:13 AM", modified = "2/22/2022 10:31:38 AM",
    trigger = byte(0x01A284) == 0x01 && repeated(60, byte(0x01A3AC) <= 0x05) && unless(byte(0x01A3AC) == 0xFF) && 
              never(byte(0x01A284) != 0x01) && prev(dword(0x004358)) != 0x00 && prev(byte(0x01A3AC)) == 0xFF
)

achievement(
    title = "Max Strikes! (Advance Campaign)", description = "Beat Advance Campaign Mission \"Max Strikes!\"", points = 10,
    id = 11494, badge = "80330", published = "8/14/2014 4:42:15 AM", modified = "2/22/2022 10:31:38 AM",
    trigger = byte(0x01A284) == 0x01 && never(byte(0x01A284) != 0x01) && prev(dword(0x004358)) != 0x00 &&
              ((repeated(60, byte(0x01A3B0) <= 0x05) && unless(byte(0x01A3B0) == 0xFF) && prev(byte(0x01A3B0)) == 0xFF) ||
               (repeated(60, byte(0x01A3C1) <= 0x05) && unless(byte(0x01A3C1) == 0xFF) && prev(byte(0x01A3C1)) == 0xFF))
)

achievement(
    title = "Max's Folly? (Advance Campaign)", description = "Beat Advance Campaign Mission \"Max's Folly?\"", points = 10,
    id = 11495, badge = "80331", published = "8/14/2014 4:42:17 AM", modified = "2/22/2022 10:31:39 AM",
    trigger = byte(0x01A284) == 0x01 && repeated(60, byte(0x01A3B5) <= 0x05) && unless(byte(0x01A3B5) == 0xFF) && 
              never(byte(0x01A284) != 0x01) && prev(dword(0x004358)) != 0x00 && prev(byte(0x01A3B5)) == 0xFF
)

achievement(
    title = "Sniper! (Advance Campaign)", description = "Beat Advance Campaign Mission \"Sniper!\"", points = 10,
    id = 11497, badge = "80333", published = "8/14/2014 4:42:20 AM", modified = "2/22/2022 10:31:39 AM",
    trigger = byte(0x01A284) == 0x01 && never(byte(0x01A284) != 0x01) && prev(dword(0x004358)) != 0x00 &&
              ((repeated(60, byte(0x01A3C4) <= 0x05) && unless(byte(0x01A3C4) == 0xFF) && prev(byte(0x01A3C4)) == 0xFF) ||
               (repeated(60, byte(0x01A3C5) <= 0x05) && unless(byte(0x01A3C5) == 0xFF) && prev(byte(0x01A3C5)) == 0xFF))
)

achievement(
    title = "Olaf's Navy! (Advance Campaign)", description = "Beat Advance Campaign Mission \"Olaf's Navy!\"", points = 10,
    id = 11496, badge = "80332", published = "8/14/2014 4:42:19 AM", modified = "2/22/2022 10:31:40 AM",
    trigger = byte(0x01A284) == 0x01 && never(byte(0x01A284) != 0x01) && prev(dword(0x004358)) != 0x00 &&
              ((repeated(60, byte(0x01A3B8) <= 0x05) && unless(byte(0x01A3B8) == 0xFF) && prev(byte(0x01A3B8)) == 0xFF) ||
               (byte(0x01A3B9) <= 0x05 && unless(byte(0x01A3B9) == 0xFF) && prev(byte(0x01A3B9)) == 0xFF))
)

achievement(
    title = "Blizzard Battle! (Advance Campaign)", description = "Beat Advance Campaign Mission \"Blizzard Battle!\"", points = 10,
    id = 11498, badge = "80334", published = "8/14/2014 4:42:22 AM", modified = "2/22/2022 10:31:40 AM",
    trigger = byte(0x01A284) == 0x01 && never(byte(0x01A284) != 0x01) && prev(dword(0x004358)) != 0x00 &&
              ((repeated(60, byte(0x01A3C9) <= 0x05) && unless(byte(0x01A3C9) == 0xFF) && prev(byte(0x01A3C9)) == 0xFF) ||
               (repeated(60, byte(0x01A3C8) <= 0x05) && unless(byte(0x01A3C8) == 0xFF) && prev(byte(0x01A3C8)) == 0xFF))
)

achievement(
    title = "Olaf's Sea Strike! (Advance Campaign)", description = "Beat Advance Campaign Mission \"Olaf's Sea Strike!\"", points = 10,
    id = 11500, badge = "80336", published = "8/14/2014 4:42:26 AM", modified = "2/22/2022 10:31:40 AM",
    trigger = byte(0x01A284) == 0x01 && never(byte(0x01A284) != 0x01) && prev(dword(0x004358)) != 0x00 &&
              ((repeated(60, byte(0x01A3BC) <= 0x05) && unless(byte(0x01A3BC) == 0xFF) && prev(byte(0x01A3BC)) == 0xFF) ||
               (repeated(60, byte(0x01A3BD) <= 0x05) && unless(byte(0x01A3BD) == 0xFF) && prev(byte(0x01A3BD)) == 0xFF))
)

achievement(
    title = "History Lesson! (Advance Campaign)", description = "Beat Advance Campaign Mission \"History Lesson!\"", points = 10,
    id = 11499, badge = "80335", published = "8/14/2014 4:42:24 AM", modified = "2/22/2022 10:31:41 AM",
    trigger = byte(0x01A284) == 0x01 && repeated(60, byte(0x01A3CD) <= 0x05) && unless(byte(0x01A3CD) == 0xFF) && 
              never(byte(0x01A284) != 0x01) && prev(dword(0x004358)) != 0x00 && prev(byte(0x01A3CD)) == 0xFF
)

achievement(
    title = "Sami's Debut! (Advance Campaign)", description = "Beat Advance Campaign Mission \"Sami's Debut!\"", points = 10,
    id = 11501, badge = "80337", published = "8/14/2014 4:42:27 AM", modified = "2/22/2022 10:31:41 AM",
    trigger = byte(0x01A284) == 0x01 && never(byte(0x01A284) != 0x01) && prev(dword(0x004358)) != 0x00 &&
              ((repeated(60, byte(0x01A3D0) <= 0x05) && unless(byte(0x01A3D0) == 0xFF) && prev(byte(0x01A3D0)) == 0xFF) ||
               (repeated(60, byte(0x01A3D1) <= 0x05) && unless(byte(0x01A3D1) == 0xFF) && prev(byte(0x01A3D1)) == 0xFF) ||
               (repeated(60, byte(0x01A3D2) <= 0x05) && unless(byte(0x01A3D2) == 0xFF) && prev(byte(0x01A3D2)) == 0xFF))
)

achievement(
    title = "Kanbei Arrives! (Advance Campaign)", description = "Beat Advance Campaign Mission \"Kanbei Arrives!\"", points = 10,
    id = 11502, badge = "80338", published = "8/14/2014 4:42:29 AM", modified = "2/22/2022 10:31:42 AM",
    trigger = byte(0x01A284) == 0x01 && never(byte(0x01A284) != 0x01) && prev(dword(0x004358)) != 0x00 &&
              ((repeated(60, byte(0x01A3D4) <= 0x05) && unless(byte(0x01A3D4) == 0xFF) && prev(byte(0x01A3D4)) == 0xFF) ||
               (repeated(60, byte(0x01A3D5) <= 0x05) && unless(byte(0x01A3D5) == 0xFF) && prev(byte(0x01A3D5)) == 0xFF) ||
               (repeated(60, byte(0x01A3D6) <= 0x05) && unless(byte(0x01A3D6) == 0xFF) && prev(byte(0x01A3D6)) == 0xFF))
)

achievement(
    title = "Mighty Kanbei! (Advance Campaign)", description = "Beat Advance Campaign Mission \"Mighty Kanbei!\"", points = 10,
    id = 11503, badge = "80339", published = "8/14/2014 4:42:31 AM", modified = "2/22/2022 10:31:42 AM",
    trigger = byte(0x01A284) == 0x01 && never(byte(0x01A284) != 0x01) && prev(dword(0x004358)) != 0x00 &&
              ((repeated(60, byte(0x01A3D8) <= 0x05) && unless(byte(0x01A3D8) == 0xFF) && prev(byte(0x01A3D8)) == 0xFF) ||
               (repeated(60, byte(0x01A3D9) <= 0x05) && unless(byte(0x01A3D9) == 0xFF) && prev(byte(0x01A3D9)) == 0xFF) ||
               (repeated(60, byte(0x01A3DA) <= 0x05) && unless(byte(0x01A3DA) == 0xFF) && prev(byte(0x01A3DA)) == 0xFF))
)

achievement(
    title = "Kanbei's Error? (Advance Campaign)", description = "Beat Advance Campaign Mission \"Kanbei's Error?\"", points = 10,
    id = 11504, badge = "80340", published = "8/14/2014 4:42:33 AM", modified = "2/22/2022 10:31:42 AM",
    trigger = byte(0x01A284) == 0x01 && never(byte(0x01A284) != 0x01) && prev(dword(0x004358)) != 0x00 &&
              ((repeated(60, byte(0x01A3DC) <= 0x05) && unless(byte(0x01A3DC) == 0xFF) && prev(byte(0x01A3DC)) == 0xFF) ||
               (repeated(60, byte(0x01A3DD) <= 0x05) && unless(byte(0x01A3DD) == 0xFF) && prev(byte(0x01A3DD)) == 0xFF) ||
               (repeated(60, byte(0x01A3DE) <= 0x05) && unless(byte(0x01A3DE) == 0xFF) && prev(byte(0x01A3DE)) == 0xFF))
)

achievement(
    title = "Divide and Conquer! (Advance Campaign)", description = "Beat Advance Campaign Mission \"Divide and Conquer!\"", points = 10,
    id = 11505, badge = "80341", published = "8/14/2014 4:42:34 AM", modified = "2/22/2022 10:31:43 AM",
    trigger = byte(0x01A284) == 0x01 && repeated(60, byte(0x01A3E1) <= 0x05) && unless(byte(0x01A3E1) == 0xFF) && 
              never(byte(0x01A284) != 0x01) && prev(dword(0x004358)) != 0x00 && prev(byte(0x01A3E1)) == 0xFF
)

achievement(
    title = "Sami Marches On! (Advance Campaign)", description = "Beat Advance Campaign Mission \"Sami Marches On!\"", points = 10,
    id = 11506, badge = "80342", published = "8/14/2014 4:42:36 AM", modified = "2/22/2022 10:31:43 AM",
    trigger = byte(0x01A284) == 0x01 && repeated(60, byte(0x01A3E6) <= 0x05) && unless(byte(0x01A3E6) == 0xFF) && 
              never(byte(0x01A284) != 0x01) && prev(dword(0x004358)) != 0x00 && prev(byte(0x01A3E6)) == 0xFF
)

achievement(
    title = "Sonja's Goal! (Advance Campaign)", description = "Beat Advance Campaign Mission \"Sonja's Goal!\"", points = 10,
    id = 11507, badge = "80343", published = "8/14/2014 4:42:38 AM", modified = "2/22/2022 10:31:43 AM",
    trigger = byte(0x01A284) == 0x01 && repeated(60, byte(0x01A3E8) <= 0x05) && unless(byte(0x01A3E8) == 0xFF) && 
              never(byte(0x01A284) != 0x01) && prev(dword(0x004358)) != 0x00 && prev(byte(0x01A3E8)) == 0xFF
)

achievement(
    title = "Captain Drake! (Advance Campaign)", description = "Beat Advance Campaign Mission \"Captain Drake!\"", points = 10,
    id = 11508, badge = "80344", published = "8/14/2014 4:42:41 AM", modified = "2/22/2022 10:31:44 AM",
    trigger = byte(0x01A284) == 0x01 && never(byte(0x01A284) != 0x01) && prev(dword(0x004358)) != 0x00 &&
              ((repeated(60, byte(0x01A3EC) <= 0x05) && unless(byte(0x01A3EC) == 0xFF) && prev(byte(0x01A3EC)) == 0xFF) ||
               (repeated(60, byte(0x01A3F1) <= 0x05) && unless(byte(0x01A3F1) == 0xFF) && prev(byte(0x01A3F1)) == 0xFF) ||
               (repeated(60, byte(0x01A3F6) <= 0x05) && unless(byte(0x01A3F6) == 0xFF) && prev(byte(0x01A3F6)) == 0xFF))
)

achievement(
    title = "Naval Clash! (Advance Campaign)", description = "Beat Advance Campaign Mission \"Naval Clash!\"", points = 10,
    id = 11509, badge = "80345", published = "8/14/2014 4:42:44 AM", modified = "2/22/2022 10:31:44 AM",
    trigger = byte(0x01A284) == 0x01 && never(byte(0x01A284) != 0x01) && prev(dword(0x004358)) != 0x00 &&
              ((repeated(60, byte(0x01A3F8) <= 0x05) && unless(byte(0x01A3F8) == 0xFF) && prev(byte(0x01A3F8)) == 0xFF) ||
               (repeated(60, byte(0x01A3FD) <= 0x05) && unless(byte(0x01A3FD) == 0xFF) && prev(byte(0x01A3FD)) == 0xFF) ||
               (repeated(60, byte(0x01A402) <= 0x05) && unless(byte(0x01A402) == 0xFF) && prev(byte(0x01A402)) == 0xFF))
)

achievement(
    title = "Wings of Victory! (Advance Campaign)", description = "Beat Advance Campaign Mission \"Wings of Victory!\"", points = 10,
    id = 11510, badge = "80346", published = "8/14/2014 4:42:46 AM", modified = "2/22/2022 10:31:45 AM",
    trigger = byte(0x01A284) == 0x01 && never(byte(0x01A284) != 0x01) && prev(dword(0x004358)) != 0x00 &&
              ((repeated(60, byte(0x01A404) <= 0x05) && unless(byte(0x01A404) == 0xFF) && prev(byte(0x01A404)) == 0xFF) ||
               (repeated(60, byte(0x01A409) <= 0x05) && unless(byte(0x01A409) == 0xFF) && prev(byte(0x01A409)) == 0xFF) ||
               (repeated(60, byte(0x01A40E) <= 0x05) && unless(byte(0x01A40E) == 0xFF) && prev(byte(0x01A40E)) == 0xFF))
)

achievement(
    title = "Battle Mystery! (Advance Campaign)", description = "Beat Advance Campaign Mission \"Battle Mystery!\"", points = 10,
    id = 11511, badge = "80347", published = "8/14/2014 4:42:47 AM", modified = "2/22/2022 10:31:45 AM",
    trigger = byte(0x01A284) == 0x01 && never(byte(0x01A284) != 0x01) && prev(dword(0x004358)) != 0x00 &&
              ((repeated(60, byte(0x01A410) <= 0x05) && unless(byte(0x01A410) == 0xFF) && prev(byte(0x01A410)) == 0xFF) ||
               (repeated(60, byte(0x01A415) <= 0x05) && unless(byte(0x01A415) == 0xFF) && prev(byte(0x01A415)) == 0xFF) ||
               (byte(0x01A41A) <= 0x05 && prev(byte(0x01A41A)) == 0xFF))
)

achievement(
    title = "Andy Times Two! (Advance Campaign)", description = "Beat Advance Campaign Mission \"Andy Times Two!\"", points = 10,
    id = 11512, badge = "80348", published = "8/14/2014 4:42:50 AM", modified = "2/22/2022 10:31:46 AM",
    trigger = byte(0x01A284) == 0x01 && never(byte(0x01A284) != 0x01) && prev(dword(0x004358)) != 0x00 &&
              ((repeated(60, byte(0x01A41C) <= 0x05) && unless(byte(0x01A41C) == 0xFF) && prev(byte(0x01A41C)) == 0xFF) ||
               (repeated(60, byte(0x01A41D) <= 0x05) && unless(byte(0x01A41D) == 0xFF) && prev(byte(0x01A41D)) == 0xFF) ||
               (repeated(60, byte(0x01A41E) <= 0x05) && unless(byte(0x01A41E) == 0xFF) && prev(byte(0x01A41E)) == 0xFF))
)

achievement(
    title = "Enigma! (Advance Campaign)", description = "Beat Advance Campaign Mission \"Enigma!\"", points = 10,
    id = 11513, badge = "80349", published = "8/14/2014 4:42:51 AM", modified = "2/22/2022 10:31:46 AM",
    trigger = byte(0x01A284) == 0x01 && never(byte(0x01A284) != 0x01) && prev(dword(0x004358)) != 0x00 &&
              ((repeated(60, byte(0x01A420) <= 0x05) && unless(byte(0x01A420) == 0xFF) && prev(byte(0x01A420)) == 0xFF) ||
               (repeated(60, byte(0x01A421) <= 0x05) && unless(byte(0x01A421) == 0xFF) && prev(byte(0x01A421)) == 0xFF) ||
               (repeated(60, byte(0x01A422) <= 0x05) && unless(byte(0x01A422) == 0xFF) && prev(byte(0x01A422)) == 0xFF))
)

achievement(
    title = "The Final Battle! (Advance Campaign)", description = "Beat Advance Campaign Mission \"The Final Battle!\"", points = 10,
    id = 11514, badge = "80350", published = "8/14/2014 4:42:53 AM", modified = "2/22/2022 10:31:46 AM",
    trigger = byte(0x01A284) == 0x01 && never(byte(0x01A284) != 0x01) && prev(dword(0x004358)) != 0x00 &&
              ((repeated(60, byte(0x01A424) <= 0x05) && unless(byte(0x01A424) == 0xFF) && prev(byte(0x01A424)) == 0xFF) ||
               (repeated(60, byte(0x01A425) <= 0x05) && unless(byte(0x01A425) == 0xFF) && prev(byte(0x01A425)) == 0xFF) ||
               (repeated(60, byte(0x01A426) <= 0x05) && unless(byte(0x01A426) == 0xFF) && prev(byte(0x01A426)) == 0xFF))
)

achievement(
    title = "Rivals! (Advance Campaign)", description = "Beat Advance Campaign Mission \"Rivals!\"", points = 10,
    id = 11515, badge = "80351", published = "8/14/2014 4:42:55 AM", modified = "2/22/2022 10:31:47 AM",
    trigger = byte(0x01A284) == 0x01 && repeated(60, byte(0x01A428) <= 0x05) && unless(byte(0x01A428) == 0xFF) && 
              never(byte(0x01A284) != 0x01) && prev(dword(0x004358)) != 0x00 && prev(byte(0x01A428)) == 0xFF
)
