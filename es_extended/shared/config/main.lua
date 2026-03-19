Config = {}

local txAdminLocale = GetConvar("txAdmin-locale", "en")
local esxLocale = GetConvar("esx:locale", "invalid")
Config.Locale = (esxLocale ~= "invalid") and esxLocale or (txAdminLocale ~= "custom" and txAdminLocale) or "en"

Config.CustomInventory = false

Config.Accounts = {
    bank = {
        label = TranslateCap("account_bank"),
        round = true,
    },
    black_money = {
        label = TranslateCap("account_black_money"),
        round = true,
    },
    money = {
        label = TranslateCap("account_money"),
        round = true,
    },
}

Config.StartingAccountMoney = { bank = 50000 }

Config.StartingInventoryItems = false -- ใช้ค่าเป็นตารางหรือ false

Config.DefaultSpawns = { -- หากต้องการเพิ่มจุดเกิดและสุ่มใช้งาน ให้เอาคอมเมนต์ออกหรือเพิ่มตำแหน่งใหม่
    { x = 222.2027, y = -864.0162, z = 30.2922, heading = 1.0 },
    --{x = 224.9865, y = -865.0871, z = 30.2922, heading = 1.0},
    --{x = 227.8436, y = -866.0400, z = 30.2922, heading = 1.0},
    --{x = 230.6051, y = -867.1450, z = 30.2922, heading = 1.0},
    --{x = 233.5459, y = -868.2626, z = 30.2922, heading = 1.0}
}

Config.AdminGroups = {
    ["owner"] = true,
    ["admin"] = true,
}

Config.ValidCharacterSets = { -- เปิดใช้ชุดอักขระเพิ่มเติมเฉพาะเมื่อเซิร์ฟเวอร์ของคุณรองรับหลายภาษา ค่าเริ่มต้นเป็น false ทั้งหมด.
    ['el'] = false, -- ภาษากรีก
    ['sr'] = false, -- อักษรซีริลลิก
    ['he'] = false, -- ภาษาฮิบรู
    ['ar'] = false, -- ภาษาอาหรับ
    ['zh-cn'] = false -- จีน ญี่ปุ่น เกาหลี
}

Config.EnablePaycheck = true -- เปิดใช้งานเงินเดือน
Config.LogPaycheck = false -- บันทึกการจ่ายเงินเดือนไปยังห้อง Discord ที่กำหนดผ่าน webhook (ค่าเริ่มต้นคือ false)
Config.EnableSocietyPayouts = false -- จ่ายเงินจากบัญชี society ของงานที่ผู้เล่นสังกัดอยู่หรือไม่? ต้องใช้ esx_society
Config.MaxWeight = 24 -- น้ำหนักสูงสุดของกระเป๋าโดยไม่ใส่เป้
Config.InventoryMode = "limit" -- โหมดกระเป๋าแบบจำกัดจำนวน โดยจะไม่ใช้น้ำหนักในการตรวจสอบการถือของ
Config.DefaultItemLimit = -1 -- ค่าจำกัดสำรองเมื่อไอเท็มนั้นไม่ได้กำหนด limit ไว้
Config.PaycheckInterval = 7 * 60000 -- ระยะเวลาการรับเงินเดือน หน่วยเป็นมิลลิวินาที
Config.SaveInterval = 15000 -- ช่วงเวลาบันทึกข้อมูลผู้เล่นที่มีการเปลี่ยนแปลงอัตโนมัติ หน่วยเป็นมิลลิวินาที
Config.InventorySyncInterval = 750 -- ช่วงเวลาส่งชุดข้อมูลส่วนต่างของกระเป๋า หน่วยเป็นมิลลิวินาที
Config.InventorySyncRateLimit = 500 -- ระยะหน่วงขั้นต่ำระหว่างชุด sync ของผู้เล่นแต่ละคน หน่วยเป็นมิลลิวินาที
Config.LoginQueueInterval = 1000 -- ช่วงเวลาประมวลผลคิวเข้าสู่ระบบ หน่วยเป็นมิลลิวินาที
Config.LoginQueueBatchSize = 4 -- จำนวนผู้เล่นสูงสุดที่ประมวลผลจากคิวต่อรอบ
Config.PaycheckChunkSize = 32 -- จำนวนผู้เล่นที่ประมวลผลต่อหนึ่งชุดของการจ่ายเงินเดือน
Config.PaycheckChunkDelay = 50 -- ระยะเวลาหน่วงระหว่างแต่ละชุดการจ่ายเงินเดือน หน่วยเป็นมิลลิวินาที
Config.PedLoopInterval = 250 -- ช่วงเวลาลูปติดตาม ped หน่วยเป็นมิลลิวินาที
Config.PlayerScopeBucketSize = 128.0 -- ขนาด bucket เชิงพื้นที่สำหรับขอบเขตผู้เล่นฝั่งเซิร์ฟเวอร์
Config.PlayerScopeRefreshInterval = 500 -- ช่วงเวลารีเฟรช cache ตำแหน่งผู้เล่นและ scope bucket
Config.PickupBucketSize = 25.0 -- ขนาด bucket เชิงพื้นที่ของ pickup ฝั่งไคลเอนต์
Config.PickupDrawDistance = 5.0 -- ระยะเรนเดอร์ข้อความ 3 มิติสำหรับ pickup ในโลก
Config.PickupPromptDistance = 1.0 -- ระยะแสดงปุ่มโต้ตอบสำหรับ pickup ในโลก
Config.PickupScanInterval = 250 -- ช่วงเวลารีเฟรชการตรวจจับ pickup เมื่อมี pickup อยู่ใกล้และมองเห็นได้
Config.PickupIdleInterval = 1500 -- ช่วงเวลารีเฟรชการตรวจจับ pickup เมื่อไม่มี pickup ใกล้ตัว
Config.EventThrottle = {
    giveItem = 250,
    removeInventory = 250,
    useItem = 150,
    pickup = 250,
    updateWeaponAmmo = 200,
}
Config.WeaponStatebagInterval = 200 -- ช่วงเวลาหน่วงการส่ง telemetry อาวุธจากไคลเอนต์ไปเซิร์ฟเวอร์ หน่วยเป็นมิลลิวินาที
Config.WeaponTelemetryWindow = 4000 -- หน้าต่างเวลา telemetry แบบเลื่อนต่อผู้เล่น หน่วยเป็นมิลลิวินาที
Config.WeaponAutoDetect = true -- สแกน resource เพื่อหาไฟล์ meta ของอาวุธเสริมโดยอัตโนมัติ
Config.WeaponAutoDetectFiles = {
    "weapons.meta",
    "weaponcomponents.meta",
    "stream/weapons.meta",
    "stream/weaponcomponents.meta",
}
Config.WeaponTypeNamePatterns = {
    pistol = { "PISTOL", "REVOLVER" },
    rifle = { "RIFLE", "CARBINE", "M4", "AK", "BULLPUP" },
    smg = { "SMG", "PDW", "MACHINEPISTOL" },
    shotgun = { "SHOTGUN" },
    sniper = { "SNIPER", "MARKSMAN" },
    throwable = { "GRENADE", "MOLOTOV", "STICKY", "BOMB", "MINE", "SNOWBALL", "BZGAS", "BALL", "FLARE" },
}
Config.WeaponTypeDefaults = {
    unknown = { maxAmmo = 250, minFireInterval = 120, maxRange = 120.0, minDamage = 0, maxDamage = 75, spreadTolerance = 0.0035, recoilTolerance = 8.0 },
    melee = { maxAmmo = 0, minFireInterval = 350, maxRange = 3.5, minDamage = 1, maxDamage = 60, spreadTolerance = 0.0, recoilTolerance = 0.0 },
    pistol = { maxAmmo = 250, minFireInterval = 110, maxRange = 90.0, minDamage = 1, maxDamage = 55, spreadTolerance = 0.0032, recoilTolerance = 7.5 },
    smg = { maxAmmo = 500, minFireInterval = 65, maxRange = 110.0, minDamage = 1, maxDamage = 45, spreadTolerance = 0.0045, recoilTolerance = 8.5 },
    rifle = { maxAmmo = 500, minFireInterval = 85, maxRange = 180.0, minDamage = 1, maxDamage = 65, spreadTolerance = 0.0040, recoilTolerance = 9.0 },
    shotgun = { maxAmmo = 120, minFireInterval = 260, maxRange = 40.0, minDamage = 2, maxDamage = 120, spreadTolerance = 0.0090, recoilTolerance = 12.0 },
    sniper = { maxAmmo = 50, minFireInterval = 900, maxRange = 450.0, minDamage = 10, maxDamage = 160, spreadTolerance = 0.0010, recoilTolerance = 5.0 },
    launcher = { maxAmmo = 20, minFireInterval = 800, maxRange = 350.0, minDamage = 20, maxDamage = 250, spreadTolerance = 0.0120, recoilTolerance = 14.0 },
    throwable = { maxAmmo = 25, minFireInterval = 500, maxRange = 60.0, minDamage = 5, maxDamage = 150, spreadTolerance = 0.0080, recoilTolerance = 6.0 },
    utility = { maxAmmo = 4500, minFireInterval = 150, maxRange = 25.0, minDamage = 0, maxDamage = 10, spreadTolerance = 0.0, recoilTolerance = 0.0 },
    heavy = { maxAmmo = 9999, minFireInterval = 55, maxRange = 220.0, minDamage = 1, maxDamage = 90, spreadTolerance = 0.0060, recoilTolerance = 12.0 },
}
Config.WeaponAntiCheat = {
    enabled = true,
    maxAmmoDeltaMultiplier = 1.0, -- ค่าการเพิ่มขึ้นสูงสุดของกระสุนที่ยอมรับได้เมื่อเทียบกับ max ammo ของอาวุธ
    perfectPatternThreshold = 6, -- จำนวนตัวอย่างความแปรปรวนต่ำต่อเนื่องก่อนปักธงเรื่อง recoil/spread
    suspiciousScoreLimit = 5, -- คะแนนขั้นต่ำก่อนถือว่าผู้เล่นน่าสงสัยเรื่องโกงอาวุธ
    damageGraceMultiplier = 1.25, -- ค่าความคลาดเคลื่อนของดาเมจที่ยอมรับได้เหนือ max damage ที่ตั้งไว้
    impossibleFireRateGrace = 20, -- ค่ามิลลิวินาทีเผื่อเพิ่มเติมที่ยอมรับได้ต่ำกว่า min fire interval
}
Config.SaveDeathStatus = true -- บันทึกสถานะการตายของผู้เล่น
Config.EnableDebug = false -- เปิดใช้ตัวเลือก Debug หรือไม่
Config.EnablePerformanceDebug = false -- ติดตามตัวนับและคำเตือนของเส้นทางทำงานที่ช้า
Config.SlowFunctionWarningMs = 25 -- แจ้งเตือนเมื่อเส้นทางหลักใช้เวลานานเกินค่านี้ในโหมด debug

Config.DefaultJobDuty = true -- สถานะเข้างานเริ่มต้นของผู้เล่นเมื่อเปลี่ยนอาชีพ
Config.OffDutyPaycheckMultiplier = 0.5 -- ตัวคูณเงินเดือนตอนนอกเวลางาน เช่น 0.5 = 50% ของเงินเดือนตอนเข้างาน

Config.Multichar = false -- ใช้เฉพาะระบบตัวละครเดียว
Config.Identity = true -- เก็บข้อมูลตัวตนของตัวละครไว้สำหรับเซิร์ฟเวอร์ตัวละครเดียวหากต้องการ
Config.DistanceGive = 4.0 -- ระยะสูงสุดในการให้ไอเท็ม อาวุธ และอื่น ๆ

Config.AdminLogging = false -- บันทึกการใช้คำสั่งบางอย่างของผู้ที่มีสิทธิ์ group.admin ace (ค่าเริ่มต้นคือ false)

Config.EnableDefaultInventory = Config.CustomInventory == false -- แสดงกระเป๋าแบบเริ่มต้น (F2)
