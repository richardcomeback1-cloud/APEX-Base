ESX.Players = {}
ESX.Jobs = {}
ESX.Items = {}
Core = {}
Core.JobsPlayerCount = {}
Core.UsableItemsCallbacks = {}
Core.RegisteredCommands = {}
Core.Pickups = {}
Core.PickupId = 0
Core.PlayerFunctionOverrides = {}
Core.DatabaseConnected = false
Core.playersByIdentifier = {}
Core.JobsLoaded = false
Core.PlayerCache = {}
Core.SaveQueue = {}
Core.LoginQueue = { head = 1, tail = 0, items = {} }
Core.EventThrottle = {}
Core.Performance = {
    counters = {},
    slowPaths = {},
}

---@type table<string, CVehicleData>
Core.vehicles = {}
Core.vehicleTypesByModel = {}

RegisterNetEvent("esx:onPlayerSpawn", function()
    ESX.Players[source].spawned = true
end)

if Config.CustomInventory then
    SetConvarReplicated("inventory:framework", "esx")
    SetConvarReplicated("inventory:weight", tostring(Config.MaxWeight * 1000))
end

local function StartDBSync()
    CreateThread(function()
        while true do
            Wait(Config.SaveInterval)
            Core.SavePlayers()
        end
    end)
end

local function StartInventorySync()
    CreateThread(function()
        while true do
            Wait(Config.InventorySyncInterval)
            Core.FlushPendingInventorySync()
        end
    end)
end

local function StartLoginQueue()
    CreateThread(function()
        while true do
            Wait(Config.LoginQueueInterval)

            local processed = 0
            while processed < Config.LoginQueueBatchSize and Core.LoginQueue.head <= Core.LoginQueue.tail do
                local index = Core.LoginQueue.head
                local queueEntry = Core.LoginQueue.items[index]
                Core.LoginQueue.items[index] = nil
                Core.LoginQueue.head = index + 1

                if queueEntry and GetPlayerPing(queueEntry.playerId) > 0 then
                    queueEntry.handler()
                    processed += 1
                end
            end

            if Core.LoginQueue.head > Core.LoginQueue.tail then
                Core.LoginQueue.head = 1
                Core.LoginQueue.tail = 0
            end
        end
    end)
end

function Core.EnqueueLogin(playerId, handler)
    Core.LoginQueue.tail += 1
    Core.LoginQueue.items[Core.LoginQueue.tail] = {
        playerId = playerId,
        handler = handler,
    }
end

function Core.DebugCounter(name, amount)
    if not Config.EnablePerformanceDebug then
        return
    end

    Core.Performance.counters[name] = (Core.Performance.counters[name] or 0) + (amount or 1)
end

function Core.DebugDuration(name, startedAt)
    if not Config.EnablePerformanceDebug then
        return
    end

    local elapsed = GetGameTimer() - startedAt
    if elapsed < Config.SlowFunctionWarningMs then
        return
    end

    local entry = Core.Performance.slowPaths[name] or { count = 0, max = 0 }
    entry.count += 1
    entry.max = math.max(entry.max, elapsed)
    Core.Performance.slowPaths[name] = entry

    print(("[^3PERF^7] %s took %sms (count=%s, max=%sms)"):format(name, elapsed, entry.count, entry.max))
end

function Core.BindPlayerCache(xPlayer)
    local cache = {
        identifier = xPlayer.identifier,
        money = 0,
        accounts = xPlayer.accounts,
        accountLookup = xPlayer.accountsByName,
        job = xPlayer.job,
        inventory = xPlayer.inventory,
        inventoryList = xPlayer.inventoryList,
        metadata = xPlayer.metadata,
        dirtyFlags = {
            accounts = false,
            group = false,
            inventory = false,
            job = false,
            loadout = false,
            metadata = false,
            name = false,
            position = false,
        },
        pendingInventorySync = {},
        nextInventorySyncAt = 0,
    }

    local account = xPlayer.accountsByName.money
    cache.money = account and account.money or 0

    xPlayer.cache = cache
    xPlayer.dirtyFlags = cache.dirtyFlags
    Core.PlayerCache[xPlayer.source] = cache

    return cache
end

function Core.MarkPlayerDirty(xPlayer, flag)
    local cache = (xPlayer and xPlayer.cache) or Core.PlayerCache[xPlayer.source]
    if not cache then
        return
    end

    cache.dirtyFlags[flag] = true
    Core.SaveQueue[xPlayer.source] = xPlayer
end

function Core.ClearPlayerDirtyFlags(xPlayer)
    local cache = (xPlayer and xPlayer.cache) or Core.PlayerCache[xPlayer.source]
    if not cache then
        return
    end

    for key in pairs(cache.dirtyFlags) do
        cache.dirtyFlags[key] = false
    end

    Core.SaveQueue[xPlayer.source] = nil
end

function Core.QueueInventorySync(xPlayer, itemName, count, delta, displayLabel)
    local cache = (xPlayer and xPlayer.cache) or Core.PlayerCache[xPlayer.source]
    if not cache then
        return
    end

    cache.pendingInventorySync[itemName] = {
        name = itemName,
        count = count,
        delta = delta,
        label = displayLabel,
    }
    cache.nextInventorySyncAt = GetGameTimer() + Config.InventorySyncRateLimit
end

function Core.FlushPendingInventorySync()
    local now = GetGameTimer()

    for source, cache in pairs(Core.PlayerCache) do
        if next(cache.pendingInventorySync) and cache.nextInventorySyncAt <= now then
            local updates = {}
            local updateIndex = 1

            for itemName, payload in pairs(cache.pendingInventorySync) do
                updates[updateIndex] = payload
                updateIndex += 1
                cache.pendingInventorySync[itemName] = nil
            end

            if updateIndex > 1 then
                TriggerClientEvent("esx:updateInventory", source, updates)
                Core.DebugCounter("inventory_sync_batches")
            end
        end
    end
end

function Core.AllowPlayerEvent(playerId, eventName, cooldown)
    local now = GetGameTimer()
    local playerThrottle = Core.EventThrottle[playerId]

    if not playerThrottle then
        playerThrottle = {}
        Core.EventThrottle[playerId] = playerThrottle
    end

    local nextAllowed = playerThrottle[eventName] or 0
    if nextAllowed > now then
        return false
    end

    playerThrottle[eventName] = now + cooldown
    return true
end

MySQL.ready(function()
    Core.DatabaseConnected = true

    if not Config.CustomInventory then
        ESX.RefreshItems()
    end

    ESX.RefreshJobs()

    print(("[^2INFO^7] ESX ^5Legacy %s^0 initialized!"):format(GetResourceMetadata(GetCurrentResourceName(), "version", 0)))

    StartDBSync()
    StartInventorySync()
    StartLoginQueue()
    if Config.EnablePaycheck then
        StartPayCheck()
    end
end)

RegisterNetEvent("esx:clientLog", function(msg)
    if Config.EnableDebug then
        print(("[^2TRACE^7] %s^7"):format(msg))
    end
end)

RegisterNetEvent("esx:ReturnVehicleType", function(Type, Request)
    if Core.ClientCallbacks[Request] then
        Core.ClientCallbacks[Request](Type)
        Core.ClientCallbacks[Request] = nil
    end
end)

GlobalState.playerCount = 0
