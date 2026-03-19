Config.DisableHealthRegeneration = false -- ปิดการฟื้นฟูพลังชีวิตอัตโนมัติของผู้เล่น
Config.DisableNPCDrops = false -- ป้องกันไม่ให้ NPC ดรอปอาวุธเมื่อตาย
Config.DisableDispatchServices = true -- ปิดระบบ Dispatch
Config.DisableScenarios = true -- ปิด Scenarios ต่าง ๆ
Config.DisableAimAssist = false -- ปิดระบบช่วยเล็ง (ส่วนใหญ่มีผลกับจอยคอนโทรลเลอร์)
Config.DisableVehicleSeatShuff = false -- ปิดการสลับที่นั่งอัตโนมัติในรถ
Config.DisableDisplayAmmo = false -- ปิดการแสดงผลจำนวนกระสุน
Config.EnablePVP = true -- อนุญาตให้ผู้เล่นต่อสู้กันเอง
Config.EnableWantedLevel = false -- ใช้ระบบดาวตำรวจแบบปกติของ GTA หรือไม่

Config.RemoveHudComponents = {
    [1] = false, --WANTED_STARS,
    [2] = false, --WEAPON_ICON
    [3] = false, --CASH
    [4] = false, --MP_CASH
    [5] = false, --MP_MESSAGE
    [6] = true, --VEHICLE_NAME
    [7] = true, -- AREA_NAME
    [8] = true, -- VEHICLE_CLASS
    [9] = true, --STREET_NAME
    [10] = false, --HELP_TEXT
    [11] = false, --FLOATING_HELP_TEXT_1
    [12] = false, --FLOATING_HELP_TEXT_2
    [13] = false, --CASH_CHANGE
    [14] = false, --RETICLE
    [15] = false, --SUBTITLE_TEXT
    [16] = false, --RADIO_STATIONS
    [17] = false, --SAVING_GAME,
    [18] = false, --GAME_STREAM
    [19] = false, --WEAPON_WHEEL
    [20] = false, --WEAPON_WHEEL_STATS
    [21] = false, --HUD_COMPONENTS
    [22] = false, --HUD_WEAPONS
}

-- รูปแบบสตริงของ pattern
-- 1 จะถูกแทนด้วยตัวเลขสุ่มตั้งแต่ 0-9
-- A จะถูกแทนด้วยตัวอักษรสุ่มตั้งแต่ A-Z
-- . จะถูกแทนด้วยตัวอักษรหรือตัวเลขแบบสุ่ม โดยมีโอกาส 50% เท่ากัน
-- ^1 จะถูกแสดงเป็นเลข 1 ตามตัวอักษรจริง
-- ^A จะถูกแสดงเป็นตัว A ตามตัวอักษรจริง
-- อักขระอื่น ๆ จะถูกแสดงตามตัวอักษรนั้นตรง ๆ
-- หากสตริงสั้นกว่า 8 ตัวอักษร ระบบจะเติมด้านขวาให้ครบ
Config.CustomAIPlates = "........" -- รูปแบบป้ายทะเบียนสำหรับรถ AI

--[[
    ตัวแปรแทนค่า:
    {server_name} - ชื่อแสดงผลของเซิร์ฟเวอร์
    {server_endpoint} - IP และพอร์ตของเซิร์ฟเวอร์
    {server_players} - จำนวนผู้เล่นปัจจุบัน
    {server_maxplayers} - จำนวนผู้เล่นสูงสุด

    {player_name} - ชื่อผู้เล่น
    {player_rp_name} - ชื่อ RP ของผู้เล่น
    {player_id} - ไอดีผู้เล่น
    {player_street} - ชื่อถนนที่ผู้เล่นอยู่
]]

Config.DiscordActivity = {
    appId = 0, -- Discord Application ID
    assetName = "LargeIcon", -- ชื่อรูปภาพสำหรับไอคอนขนาดใหญ่
    assetText = "{server_name}", -- ข้อความที่จะแสดงบน asset
    buttons = {
        { label = "Join Server", url = "fivem://connect/{server_endpoint}" },
        { label = "Discord", url = "https://discord.esx-framework.org" },
    },
    presence = "{player_name} [{player_id}] | {server_players}/{server_maxplayers}",
    refresh = 1 * 60 * 1000, -- 1 นาที
}
