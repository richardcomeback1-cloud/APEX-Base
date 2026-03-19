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
Core.WriteQueue = { players = Core.SaveQueue, interval = Config.SaveInterval, scheduled = false }
Core.ActivePlayerSync = {}
Core.LoginQueue = { head = 1, tail = 0, items = {} }
Core.LoginQueueScheduled = false
Core.PlayerSyncScheduled = false
Core.EventThrottle = {}
Core.PlayerCoords = {}
Core.PlayerScopeBuckets = {}
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
    Core.WriteQueue.scheduled = false
end

local function StartInventorySync()
    Core.PlayerSyncScheduled = false
end

local function scheduleWriteQueueFlush()
    if Core.WriteQueue.scheduled then
        return
    end

    Core.WriteQueue.scheduled = true
    SetTimeout(Core.WriteQueue.interval, function()
        Core.WriteQueue.scheduled = false
        Core.SavePlayers()

        if next(Core.WriteQueue.players) then
            scheduleWriteQueueFlush()
        end
    end)
end

local function schedulePlayerSyncFlush()
    if Core.PlayerSyncScheduled then
        return
    end

    Core.PlayerSyncScheduled = true
    SetTimeout(Config.InventorySyncInterval, function()
        Core.PlayerSyncScheduled = false
        Core.FlushPendingPlayerSync()

        if next(Core.ActivePlayerSync) then
            schedulePlayerSyncFlush()
        end
    end)
end

local function getScopeBucketKey(coords)
    return ("%s:%s"):format(
        math.floor(coords.x / Config.PlayerScopeBucketSize),
        math.floor(coords.y / Config.PlayerScopeBucketSize)
    )
end

local function StartPlayerScopeCache()
    CreateThread(function()
        while true do
            Wait(Config.PlayerScopeRefreshInterval)

            local scopedPlayers = {}
            local scopeBuckets = {}

            for source, xPlayer in pairs(ESX.Players) do
                local ped = GetPlayerPed(source)
                if ped and ped > 0 then
                    local coords = GetEntityCoords(ped)
                    local routingBucket = GetPlayerRoutingBucket(source)
                    local bucketKey = getScopeBucketKey(coords)
                    local scopedPlayer = {
                        coords = coords,
                        ped = ped,
                        routingBucket = routingBucket,
                        bucketKey = bucketKey,
                    }

                    scopedPlayers[source] = scopedPlayer

                    scopeBuckets[routingBucket] = scopeBuckets[routingBucket] or {}
                    scopeBuckets[routingBucket][bucketKey] = scopeBuckets[routingBucket][bucketKey] or {}
                    scopeBuckets[routingBucket][bucketKey][#scopeBuckets[routingBucket][bucketKey] + 1] = source
                end
            end

            Core.PlayerCoords = scopedPlayers
            Core.PlayerScopeBuckets = scopeBuckets
        end
    end)
end

function Core.GetScopeBucketKey(coords)
    return getScopeBucketKey(coords)
end

local function processLoginQueue()
    Core.LoginQueueScheduled = false

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
        return
    end

    Core.LoginQueueScheduled = true
    SetTimeout(Config.LoginQueueInterval, processLoginQueue)
end

local function StartLoginQueue()
    Core.LoginQueueScheduled = false
end

function Core.EnqueueLogin(playerId, handler)
    Core.LoginQueue.tail += 1
    Core.LoginQueue.items[Core.LoginQueue.tail] = {
        playerId = playerId,
        handler = handler,
    }

    if not Core.LoginQueueScheduled then
        Core.LoginQueueScheduled = true
        SetTimeout(Config.LoginQueueInterval, processLoginQueue)
    end
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
        state = xPlayer.state,
        accounts = xPlayer.state.money,
        accountLookup = xPlayer.state.money,
        job = xPlayer.state.job,
        inventory = xPlayer.state.inventory,
        inventoryList = xPlayer.inventoryList,
        metadata = xPlayer.state.metadata,
        lastSync = 0,
        dirty = {
            money = false,
            group = false,
            inventory = false,
            job = false,
            loadout = false,
            metadata = false,
            name = false,
            position = false,
        },
        pendingSync = {
            accounts = {},
            inventory = {},
        },
        nextSyncAt = 0,
        ammoSync = {
            acceptedAt = {},
            lastClientAmmo = {},
        },
    }
    cache.dirtyFlags = cache.dirty

    local account = xPlayer.state.money.money
    cache.money = account and account.money or 0

    xPlayer.cache = cache
    xPlayer.dirtyFlags = cache.dirty
    Core.PlayerCache[xPlayer.source] = cache

    return cache
end

function Core.MarkPlayerDirty(xPlayer, flag)
    local cache = (xPlayer and xPlayer.cache) or Core.PlayerCache[xPlayer.source]
    if not cache then
        return
    end

    if flag == "accounts" then
        flag = "money"
    end

    cache.dirtyFlags[flag] = true
    Core.WriteQueue.players[xPlayer.source] = xPlayer
    scheduleWriteQueueFlush()
end

function Core.ClearPlayerDirtyFlags(xPlayer)
    local cache = (xPlayer and xPlayer.cache) or Core.PlayerCache[xPlayer.source]
    if not cache then
        return
    end

    for key in pairs(cache.dirtyFlags) do
        cache.dirtyFlags[key] = false
    end

    Core.WriteQueue.players[xPlayer.source] = nil
end

local function markPlayerSyncActive(source, cache)
    cache.nextSyncAt = GetGameTimer() + Config.InventorySyncRateLimit
    Core.ActivePlayerSync[source] = true
    schedulePlayerSyncFlush()
end

function Core.QueueAccountSync(xPlayer, account)
    local cache = (xPlayer and xPlayer.cache) or Core.PlayerCache[xPlayer.source]
    if not cache or not account then
        return
    end

    cache.pendingSync.accounts[account.name] = {
        name = account.name,
        money = account.money,
        label = account.label,
        round = account.round,
        index = account.index,
    }

    markPlayerSyncActive(xPlayer.source, cache)
end

function Core.QueueInventorySync(xPlayer, itemName, count, delta, displayLabel)
    local cache = (xPlayer and xPlayer.cache) or Core.PlayerCache[xPlayer.source]
    if not cache then
        return
    end

    cache.pendingSync.inventory[itemName] = {
        name = itemName,
        count = count,
        delta = delta,
        label = displayLabel,
    }
    markPlayerSyncActive(xPlayer.source, cache)
end

function Core.FlushPendingPlayerSync()
    local now = GetGameTimer()

    for source in pairs(Core.ActivePlayerSync) do
        local cache = Core.PlayerCache[source]
        if not cache then
            Core.ActivePlayerSync[source] = nil
            goto continue
        end

        if cache.nextSyncAt > now then
            goto continue
        end

        local pendingAccounts = cache.pendingSync.accounts
        if next(pendingAccounts) then
            local updates = {}
            local updateIndex = 1

            for accountName, payload in pairs(pendingAccounts) do
                updates[updateIndex] = payload
                updateIndex += 1
                pendingAccounts[accountName] = nil
            end

            if updateIndex > 1 then
                TriggerClientEvent("esx:updateAccounts", source, updates)
                Core.DebugCounter("account_sync_batches")
            end
        end

        local pendingInventory = cache.pendingSync.inventory
        if next(pendingInventory) then
            local updates = {}
            local updateIndex = 1

            for itemName, payload in pairs(pendingInventory) do
                updates[updateIndex] = payload
                updateIndex += 1
                pendingInventory[itemName] = nil
            end

            if updateIndex > 1 then
                TriggerClientEvent("esx:updateInventory", source, updates)
                Core.DebugCounter("inventory_sync_batches")
            end
        end

        cache.lastSync = now
        if not next(pendingAccounts) and not next(pendingInventory) then
            Core.ActivePlayerSync[source] = nil
        else
            cache.nextSyncAt = now + Config.InventorySyncRateLimit
        end
        ::continue::
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
    StartPlayerScopeCache()
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
