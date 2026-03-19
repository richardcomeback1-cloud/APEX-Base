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

Config.StartingInventoryItems = false -- table/false

Config.DefaultSpawns = { -- If you want to have more spawn positions and select them randomly uncomment commented code or add more locations
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

Config.ValidCharacterSets = { -- Only enable additional charsets if your server is multilingual. By default everything is false.
    ['el'] = false, -- Greek
    ['sr'] = false, -- Cyrillic
    ['he'] = false, -- Hebrew
    ['ar'] = false, -- Arabic
    ['zh-cn'] = false -- Chinese, Japanese, Korean
}

Config.EnablePaycheck = true -- enable paycheck
Config.LogPaycheck = false -- Logs paychecks to a nominated Discord channel via webhook (default is false)
Config.EnableSocietyPayouts = false -- pay from the society account that the player is employed at? Requirement: esx_society
Config.MaxWeight = 24 -- the max inventory weight without a backpack
Config.InventoryMode = "limit" -- limit-based inventory mode, weight is ignored for carry validation
Config.DefaultItemLimit = -1 -- fallback limit when an item definition does not provide one
Config.PaycheckInterval = 7 * 60000 -- how often to receive paychecks in milliseconds
Config.SaveInterval = 15000 -- dirty-player autosave flush interval in milliseconds
Config.InventorySyncInterval = 750 -- inventory delta batch interval in milliseconds
Config.InventorySyncRateLimit = 500 -- minimum delay between queued sync batches per player in milliseconds
Config.LoginQueueInterval = 1000 -- login queue processing interval in milliseconds
Config.LoginQueueBatchSize = 4 -- maximum queued player loads processed per interval
Config.PaycheckChunkSize = 32 -- players processed per paycheck chunk
Config.PaycheckChunkDelay = 50 -- wait between paycheck chunks in milliseconds
Config.PedLoopInterval = 250 -- ped tracking loop interval in milliseconds
Config.PlayerScopeBucketSize = 128.0 -- server-side player scope spatial bucket size
Config.PlayerScopeRefreshInterval = 500 -- refresh interval for cached player coords/scope buckets
Config.PickupBucketSize = 25.0 -- client-side pickup spatial bucket size
Config.PickupDrawDistance = 5.0 -- 3D text render distance for world pickups
Config.PickupPromptDistance = 1.0 -- interaction prompt distance for world pickups
Config.PickupScanInterval = 250 -- pickup proximity refresh interval while nearby pickups are visible
Config.PickupIdleInterval = 1500 -- pickup proximity refresh interval while no nearby pickups are visible
Config.EventThrottle = {
    giveItem = 250,
    removeInventory = 250,
    useItem = 150,
    pickup = 250,
    updateWeaponAmmo = 200,
}
Config.WeaponStatebagInterval = 200 -- client-to-server weapon telemetry throttle in milliseconds
Config.WeaponTelemetryWindow = 4000 -- rolling telemetry window per player in milliseconds
Config.WeaponAutoDetect = true -- automatically scan resources for addon weapon meta files
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
    maxAmmoDeltaMultiplier = 1.0, -- maximum allowed positive delta relative to weapon max ammo
    perfectPatternThreshold = 6, -- consecutive low-variance samples before recoil/spread flag
    suspiciousScoreLimit = 5, -- threshold before a player is considered suspicious for weapon cheats
    damageGraceMultiplier = 1.25, -- allowed damage variance over configured max damage
    impossibleFireRateGrace = 20, -- extra milliseconds tolerated under configured min fire interval
}
Config.SaveDeathStatus = true -- Save the death status of a player
Config.EnableDebug = false -- Use Debug options?
Config.EnablePerformanceDebug = false -- track counters and slow-path warnings
Config.SlowFunctionWarningMs = 25 -- warn when a hot path exceeds this execution time in debug mode

Config.DefaultJobDuty = true -- A players default duty status when changing jobs
Config.OffDutyPaycheckMultiplier = 0.5 -- The multiplier for off duty paychecks. 0.5 = 50% of the on duty paycheck

Config.Multichar = false -- single-character only
Config.Identity = true -- keep character identity fields for single-character servers if desired
Config.DistanceGive = 4.0 -- Max distance when giving items, weapons etc.

Config.AdminLogging = false -- Logs the usage of certain commands by those with group.admin ace permissions (default is false)

Config.EnableDefaultInventory = Config.CustomInventory == false -- Display the default Inventory ( F2 )
