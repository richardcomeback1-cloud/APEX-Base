SetMapName("San Andreas")
SetGameType("ESX Legacy")

local oneSyncState = GetConvar("onesync", "off")
local newPlayer = "INSERT INTO `users` SET `accounts` = ?, `identifier` = ?, `group` = ?"
local loadPlayer = "SELECT `accounts`, `job`, `job_grade`, `group`, `position`, `inventory`, `skin`, `loadout`, `metadata`"
local missingSteamMessage = "Steam must be running to join this server"

if Config.StartingInventoryItems then
    newPlayer = newPlayer .. ", `inventory` = ?"
end

if Config.Identity then
    loadPlayer = loadPlayer .. ", `firstname`, `lastname`, `dateofbirth`, `sex`, `height`"
end

loadPlayer = loadPlayer .. " FROM `users` WHERE identifier = ?"

local function createESXPlayer(identifier, playerId)
    local accounts = {}

    for account, money in pairs(Config.StartingAccountMoney) do
        accounts[account] = money
    end

    local defaultGroup = "user"
    if Core.IsPlayerAdmin(playerId) then
        print(("[^2INFO^0] Player ^5%s^0 Has been granted admin permissions via ^5Ace Perms^7."):format(playerId))
        defaultGroup = "admin"
    end
    local parameters = { json.encode(accounts), identifier, defaultGroup }

    if Config.StartingInventoryItems then
        table.insert(parameters, json.encode(Config.StartingInventoryItems))
    end

    MySQL.prepare(newPlayer, parameters, function()
        loadESXPlayer(identifier, playerId, true)
    end)
end


local function onPlayerJoined(playerId)
    local identifier = ESX.GetIdentifier(playerId)
    if not identifier then
        return DropPlayer(playerId, missingSteamMessage)
    end

    if ESX.GetPlayerFromIdentifier(identifier) then
        DropPlayer(
            playerId,
            ("there was an error loading your character!\nError code: identifier-active-ingame\n\nThis error is caused by a player on this server who has the same Steam Hex as you have. Make sure you are not playing on the same Steam account.\n\nYour Steam Hex: %s"):format(
                identifier
            )
        )
    else
        Core.EnqueueLogin(playerId, function()
            MySQL.scalar("SELECT 1 FROM users WHERE identifier = ?", { identifier }, function(result)
                if GetPlayerPing(playerId) <= 0 then
                    return
                end

                if result then
                    loadESXPlayer(identifier, playerId, false)
                else
                    createESXPlayer(identifier, playerId)
                end
            end)
        end)
    end
end

---@param playerId number
---@param reason string
---@param cb function?
local function onPlayerDropped(playerId, reason, cb)
    local p = not cb and promise:new()
    local function resolve()
        if cb then
            return cb()
        elseif(p) then
            return p:resolve()
        end
    end

    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then
        return resolve()
    end

    TriggerEvent("esx:playerDropped", playerId, reason)
    local job = xPlayer.getJob().name
    local currentJob = Core.JobsPlayerCount[job]
    Core.JobsPlayerCount[job] = ((currentJob and currentJob > 0) and currentJob or 1) - 1

    GlobalState[("%s:count"):format(job)] = Core.JobsPlayerCount[job]

    Core.SavePlayer(xPlayer, function()
        GlobalState["playerCount"] = GlobalState["playerCount"] - 1
        ESX.Players[playerId] = nil
        Core.playersByIdentifier[xPlayer.identifier] = nil
        Core.PlayerCache[playerId] = nil
        Core.ActivePlayerSync[playerId] = nil
        Core.PlayerCoords[playerId] = nil
        Core.EventThrottle[playerId] = nil

        resolve()
    end, true)

    if p then
        return Citizen.Await(p)
    end
end
AddEventHandler("esx:onPlayerDropped", onPlayerDropped)


RegisterNetEvent("esx:onPlayerJoined", function()
    local _source = source
    while not next(ESX.Jobs) do
        Wait(50)
    end

    if not ESX.Players[_source] then
        onPlayerJoined(_source)
    end
end)

AddEventHandler("playerConnecting", function(_, _, deferrals)
    local playerId = source
    deferrals.defer()
    Wait(0) -- Required
    local identifier

    -- luacheck: ignore
    if not SetEntityOrphanMode then
        return deferrals.done(("[ESX] ESX Requires a minimum Artifact version of 10188, Please update your server."))
    end

    if oneSyncState == "off" or oneSyncState == "legacy" then
        return deferrals.done(("[ESX] ESX Requires Onesync Infinity to work. This server currently has Onesync set to: %s"):format(oneSyncState))
    end

    if not Core.DatabaseConnected then
        return deferrals.done("[ESX] OxMySQL Was Unable To Connect to your database. Please make sure it is turned on and correctly configured in your server.cfg")
    end

    local success = pcall(function()
        identifier = ESX.GetIdentifier(playerId)
    end)

    if not success or not identifier then
        return deferrals.done(missingSteamMessage)
    end

    local xPlayer = ESX.GetPlayerFromIdentifier(identifier)

    if not xPlayer then
        return deferrals.done()
    end

    if GetPlayerPing(xPlayer.source --[[@as string]]) > 0 then
        return deferrals.done(
            ("[ESX] There was an error loading your character!\nError code: identifier-active\n\nThis error is caused by a player on this server who has the same Steam Hex as you have. Make sure you are not playing on the same Steam account.\n\nYour Steam Hex: %s"):format(identifier)
        )
    end

    deferrals.update(("[ESX] Cleaning stale player entry..."):format(identifier))
    onPlayerDropped(xPlayer.source, "esx_stale_player_obj")
    deferrals.done()
end)

local function decodePlayerField(value, fallback)
    if not value or value == "" then
        return fallback
    end

    local decoded = json.decode(value)
    if decoded == nil then
        return fallback
    end

    return decoded
end

local function buildPlayerLoadPayload(identifier, playerId, result)
    local payload = {
        accounts = {},
        inventory = decodePlayerField(result.inventory, {}),
        loadout = {},
        weight = 0,
        name = GetPlayerName(playerId),
        identifier = identifier,
        firstName = "John",
        lastName = "Doe",
        dateofbirth = "01/01/2000",
        height = 120,
        dead = false,
        variables = {},
        metadata = decodePlayerField(result.metadata, {}),
    }

    local accounts = decodePlayerField(result.accounts, {})
    local normalizedAccounts = {}
    if #accounts > 0 then
        for i = 1, #accounts do
            local account = accounts[i]
            if account and account.name then
                normalizedAccounts[string.lower(account.name)] = account.money or 0
            end
        end
    else
        for accountName, money in pairs(accounts) do
            if type(accountName) == "string" then
                if type(money) == "table" then
                    normalizedAccounts[string.lower(accountName)] = money.money or money.amount or 0
                else
                    normalizedAccounts[string.lower(accountName)] = money or 0
                end
            end
        end
    end

    for accountName in pairs(Config.Accounts) do
        payload.accounts[accountName] = normalizedAccounts[accountName] or Config.StartingAccountMoney[accountName] or 0
    end

    for accountName, money in pairs(normalizedAccounts) do
        if payload.accounts[accountName] == nil then
            payload.accounts[accountName] = money or 0
        end
    end

    local job, grade = result.job, tostring(result.job_grade)
    if not ESX.DoesJobExist(job, grade) then
        print(("[^3WARNING^7] Ignoring invalid job for ^5%s^7 [job: ^5%s^7, grade: ^5%s^7]"):format(identifier, job, grade))
        job, grade = "unemployed", "0"
    end

    local jobObject, gradeObject = ESX.Jobs[job], ESX.Jobs[job].grades[grade]
    payload.job = {
        id = jobObject.id,
        name = jobObject.name,
        label = jobObject.label,
        grade = tonumber(grade),
        grade_name = gradeObject.name,
        grade_label = gradeObject.label,
        grade_salary = gradeObject.salary,
        skin_male = gradeObject.skin_male and json.decode(gradeObject.skin_male) or {},
        skin_female = gradeObject.skin_female and json.decode(gradeObject.skin_female) or {},
    }

    if not Config.CustomInventory then
        local loadout = decodePlayerField(result.loadout, {})
        for name, weapon in pairs(loadout) do
            local label = ESX.GetWeaponLabel(name)
            if label then
                payload.loadout[#payload.loadout + 1] = {
                    name = name,
                    ammo = weapon.ammo,
                    label = label,
                    components = weapon.components or {},
                    tintIndex = weapon.tintIndex or 0,
                }
            end
        end
    end

    payload.group = result.group == "superadmin" and "admin" or (result.group or "user")
    if result.group == "superadmin" then
        print("[^3WARNING^7] ^5Superadmin^7 detected, setting group to ^5admin^7")
    end

    payload.coords = decodePlayerField(result.position, Config.DefaultSpawns[ESX.Math.Random(1, #Config.DefaultSpawns)])
    payload.skin = decodePlayerField(result.skin, { sex = result.sex == "f" and 1 or 0 })

    if result.firstname and result.firstname ~= "" then
        payload.firstName = result.firstname
        payload.lastName = result.lastname
        payload.name = ("%s %s"):format(result.firstname, result.lastname)
        payload.variables.firstName = result.firstname
        payload.variables.lastName = result.lastname

        if result.dateofbirth then
            payload.dateofbirth = result.dateofbirth
            payload.variables.dateofbirth = result.dateofbirth
        end

        if result.sex then
            payload.sex = result.sex
            payload.variables.sex = result.sex
        end

        if result.height then
            payload.height = result.height
            payload.variables.height = result.height
        end
    end

    return payload
end

local function syncLoadedPlayer(xPlayer, payload, playerId, isNew)
    payload.inventory = xPlayer.inventoryList
    payload.money = xPlayer.getMoney()
    payload.maxWeight = xPlayer.getMaxWeight()
    payload.variables = xPlayer.variables or payload.variables or {}

    TriggerEvent("esx:playerLoaded", playerId, xPlayer, isNew)
    xPlayer.triggerEvent("esx:playerLoaded", payload, isNew, payload.skin)

    if not Config.CustomInventory then
        xPlayer.triggerEvent("esx:createMissingPickups", Core.Pickups)
    end

    xPlayer.triggerEvent("esx:registerSuggestions", Core.RegisteredCommands)
    print(('[^2INFO^0] Player ^5"%s"^0 has connected to the server. ID: ^5%s^7'):format(xPlayer.getName(), playerId))
end

function loadESXPlayer(identifier, playerId, isNew)
    MySQL.prepare(loadPlayer, { identifier }, function(result)
        if not result or GetPlayerPing(playerId) <= 0 then
            return
        end

        local payload = buildPlayerLoadPayload(identifier, playerId, result)
        local xPlayer = CreateExtendedPlayer(
            playerId,
            identifier,
            payload.group,
            payload.accounts,
            payload.inventory,
            payload.weight,
            payload.job,
            payload.loadout,
            payload.name,
            payload.coords,
            payload.metadata
        )

        GlobalState["playerCount"] = GlobalState["playerCount"] + 1
        ESX.Players[playerId] = xPlayer
        Core.playersByIdentifier[identifier] = xPlayer

        xPlayer.name = payload.name
        xPlayer.variables = payload.variables or {}
        Player(playerId).state:set("name", xPlayer.name, true)

        syncLoadedPlayer(xPlayer, payload, playerId, isNew)
    end)
end

AddEventHandler("chatMessage", function(playerId, _, message)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if xPlayer and message:sub(1, 1) == "/" and playerId > 0 then
        CancelEvent()
        local commandName = message:sub(1):gmatch("%w+")()
        xPlayer.showNotification(TranslateCap("commanderror_invalidcommand", commandName))
    end
end)

---@param reason string
AddEventHandler("playerDropped", function(reason)
    onPlayerDropped(source --[[@as number]], reason)
end)

AddEventHandler("esx:playerLoaded", function(_, xPlayer, isNew)
    local job = xPlayer.getJob().name
    local jobKey = ("%s:count"):format(job)

    Core.JobsPlayerCount[job] = (Core.JobsPlayerCount[job] or 0) + 1
    GlobalState[jobKey] = Core.JobsPlayerCount[job]
    if isNew then
        Player(xPlayer.source).state:set('isNew', true, false)
    end
end)

AddEventHandler("esx:setJob", function(_, job, lastJob)
    local lastJobKey = ("%s:count"):format(lastJob.name)
    local jobKey = ("%s:count"):format(job.name)
    local currentLastJob = Core.JobsPlayerCount[lastJob.name]

    Core.JobsPlayerCount[lastJob.name] = ((currentLastJob and currentLastJob > 0) and currentLastJob or 1) - 1
    Core.JobsPlayerCount[job.name] = (Core.JobsPlayerCount[job.name] or 0) + 1

    GlobalState[lastJobKey] = Core.JobsPlayerCount[lastJob.name]
    GlobalState[jobKey] = Core.JobsPlayerCount[job.name]
end)

AddEventHandler("esx:playerLogout", function(playerId, cb)
    onPlayerDropped(playerId, "esx_player_logout", cb)
    TriggerClientEvent("esx:onPlayerLogout", playerId)
end)

if not Config.CustomInventory then
    RegisterNetEvent("esx:updateWeaponAmmo", function(weaponName, ammoCount)
        Core.DebugCounter("event:updateWeaponAmmo")
        if not Core.AllowPlayerEvent(source, "updateWeaponAmmo", Config.EventThrottle.updateWeaponAmmo) then
            return
        end

        local xPlayer = ESX.GetPlayerFromId(source)

        if xPlayer then
            xPlayer.updateWeaponAmmo(weaponName, ammoCount)
        end
    end)

    RegisterNetEvent("esx:giveInventoryItem", function(target, itemType, itemName, itemCount)
        local playerId = source
        Core.DebugCounter("event:giveInventoryItem")
        if not Core.AllowPlayerEvent(playerId, "giveItem", Config.EventThrottle.giveItem) then
            return
        end

        local sourceXPlayer = ESX.GetPlayerFromId(playerId)
        local targetXPlayer = ESX.GetPlayerFromId(target)
        local distance = #(GetEntityCoords(GetPlayerPed(playerId)) - GetEntityCoords(GetPlayerPed(target)))
        if not sourceXPlayer or not targetXPlayer or distance > Config.DistanceGive then
            print(("[^3WARNING^7] Player Detected Cheating: ^5%s^7"):format(GetPlayerName(playerId)))
            return
        end

        if itemType == "item_standard" then
            local sourceItem = sourceXPlayer.getInventoryItem(itemName)

            if not sourceItem then
                return
            end

            if itemCount < 1 or sourceItem.count < itemCount then
                return sourceXPlayer.showNotification(TranslateCap("imp_invalid_quantity"))
            end

            if not targetXPlayer.canCarryItem(itemName, itemCount) then
                return sourceXPlayer.showNotification(TranslateCap("ex_inv_lim", targetXPlayer.name))
            end

            sourceXPlayer.removeInventoryItem(itemName, itemCount)
            targetXPlayer.addInventoryItem(itemName, itemCount)

            sourceXPlayer.showNotification(TranslateCap("gave_item", itemCount, sourceItem.label, targetXPlayer.name))
            targetXPlayer.showNotification(TranslateCap("received_item", itemCount, sourceItem.label, sourceXPlayer.name))
        elseif itemType == "item_account" then
            if itemCount < 1 or sourceXPlayer.getAccount(itemName).money < itemCount then
                return sourceXPlayer.showNotification(TranslateCap("imp_invalid_amount"))
            end

            sourceXPlayer.removeAccountMoney(itemName, itemCount, "Gave to " .. targetXPlayer.name)
            targetXPlayer.addAccountMoney(itemName, itemCount, "Received from " .. sourceXPlayer.name)

            sourceXPlayer.showNotification(TranslateCap("gave_account_money", ESX.Math.GroupDigits(itemCount), Config.Accounts[itemName].label, targetXPlayer.name))
            targetXPlayer.showNotification(TranslateCap("received_account_money", ESX.Math.GroupDigits(itemCount), Config.Accounts[itemName].label, sourceXPlayer.name))
        elseif itemType == "item_weapon" then
            if not sourceXPlayer.hasWeapon(itemName) then
                return
            end

            local weaponLabel = ESX.GetWeaponLabel(itemName)
            if targetXPlayer.hasWeapon(itemName) then
                sourceXPlayer.showNotification(TranslateCap("gave_weapon_hasalready", targetXPlayer.name, weaponLabel))
                targetXPlayer.showNotification(TranslateCap("received_weapon_hasalready", sourceXPlayer.name, weaponLabel))
                return
            end

            local _, weapon = sourceXPlayer.getWeapon(itemName)
            if not weapon then
                return
            end

            local _, weaponObject = ESX.GetWeapon(itemName)
            itemCount = weapon.ammo
            local weaponComponents = ESX.Table.Clone(weapon.components)
            local weaponTint = weapon.tintIndex

            if weaponTint then
                targetXPlayer.setWeaponTint(itemName, weaponTint)
            end

            if weaponComponents then
                for _, v in pairs(weaponComponents) do
                    targetXPlayer.addWeaponComponent(itemName, v)
                end
            end

            sourceXPlayer.removeWeapon(itemName)
            targetXPlayer.addWeapon(itemName, itemCount)

            if weaponObject.ammo and itemCount > 0 then
                local ammoLabel = weaponObject.ammo.label
                sourceXPlayer.showNotification(TranslateCap("gave_weapon_withammo", weaponLabel, itemCount, ammoLabel, targetXPlayer.name))
                targetXPlayer.showNotification(TranslateCap("received_weapon_withammo", weaponLabel, itemCount, ammoLabel, sourceXPlayer.name))
            else
                sourceXPlayer.showNotification(TranslateCap("gave_weapon", weaponLabel, targetXPlayer.name))
                targetXPlayer.showNotification(TranslateCap("received_weapon", weaponLabel, sourceXPlayer.name))
            end
        elseif itemType == "item_ammo" then
            if not sourceXPlayer.hasWeapon(itemName) then
                return
            end

            local _, weapon = sourceXPlayer.getWeapon(itemName)
            if not weapon then
                return
            end

            if not targetXPlayer.hasWeapon(itemName) then
                sourceXPlayer.showNotification(TranslateCap("gave_weapon_noweapon", targetXPlayer.name))
                targetXPlayer.showNotification(TranslateCap("received_weapon_noweapon", sourceXPlayer.name, weapon.label))
                return
            end

            local _, weaponObject = ESX.GetWeapon(itemName)

            if not weaponObject.ammo then return end

            local ammoLabel = weaponObject.ammo.label
            if weapon.ammo >= itemCount then
                sourceXPlayer.removeWeaponAmmo(itemName, itemCount)
                targetXPlayer.addWeaponAmmo(itemName, itemCount)

                sourceXPlayer.showNotification(TranslateCap("gave_weapon_ammo", itemCount, ammoLabel, weapon.label, targetXPlayer.name))
                targetXPlayer.showNotification(TranslateCap("received_weapon_ammo", itemCount, ammoLabel, weapon.label, sourceXPlayer.name))
            end
        end
    end)

    RegisterNetEvent("esx:removeInventoryItem", function(itemType, itemName, itemCount)
        local playerId = source
        Core.DebugCounter("event:removeInventoryItem")
        if not Core.AllowPlayerEvent(playerId, "removeInventory", Config.EventThrottle.removeInventory) then
            return
        end

        local xPlayer = ESX.GetPlayerFromId(playerId)

        if not xPlayer then
            return
        end

        if itemType == "item_standard" then
            if not itemCount or itemCount < 1 then
                return xPlayer.showNotification(TranslateCap("imp_invalid_quantity"))
            end

            local xItem = xPlayer.getInventoryItem(itemName)
            if not xItem then
                return
            end

            if itemCount > xItem.count or xItem.count < 1 then
                return xPlayer.showNotification(TranslateCap("imp_invalid_quantity"))
            end

            xPlayer.removeInventoryItem(itemName, itemCount)
            local pickupLabel = ("%s [%s]"):format(xItem.label, itemCount)
            ESX.CreatePickup("item_standard", itemName, itemCount, pickupLabel, playerId)
            xPlayer.showNotification(TranslateCap("threw_standard", itemCount, xItem.label))
        elseif itemType == "item_account" then
            if itemCount == nil or itemCount < 1 then
                return xPlayer.showNotification(TranslateCap("imp_invalid_amount"))
            end

            local account = xPlayer.getAccount(itemName)
            if not account then
                return
            end

            if itemCount > account.money or account.money < 1 then
                return xPlayer.showNotification(TranslateCap("imp_invalid_amount"))
            end

            xPlayer.removeAccountMoney(itemName, itemCount, "Threw away")
            local pickupLabel = ("%s [%s]"):format(account.label, TranslateCap("locale_currency", ESX.Math.GroupDigits(itemCount)))
            ESX.CreatePickup("item_account", itemName, itemCount, pickupLabel, playerId)
            xPlayer.showNotification(TranslateCap("threw_account", ESX.Math.GroupDigits(itemCount), string.lower(account.label)))
        elseif itemType == "item_weapon" then
            itemName = string.upper(itemName)

            if not xPlayer.hasWeapon(itemName) then return end

            local _, weapon = xPlayer.getWeapon(itemName)
            if not weapon then
                return
            end

            local _, weaponObject = ESX.GetWeapon(itemName)
            -- luacheck: ignore weaponPickupLabel
            local weaponPickupLabel = ""
            local components = ESX.Table.Clone(weapon.components)
            xPlayer.removeWeapon(itemName)

            if weaponObject.ammo and weapon.ammo > 0 then
                local ammoLabel = weaponObject.ammo.label
                weaponPickupLabel = ("%s [%s %s]"):format(weapon.label, weapon.ammo, ammoLabel)
                xPlayer.showNotification(TranslateCap("threw_weapon_ammo", weapon.label, weapon.ammo, ammoLabel))
            else
                weaponPickupLabel = ("%s"):format(weapon.label)
                xPlayer.showNotification(TranslateCap("threw_weapon", weapon.label))
            end

            ESX.CreatePickup("item_weapon", itemName, weapon.ammo, weaponPickupLabel, playerId, components, weapon.tintIndex)
        end
    end)

    RegisterNetEvent("esx:useItem", function(itemName)
        local source = source
        Core.DebugCounter("event:useItem")
        if not Core.AllowPlayerEvent(source, "useItem", Config.EventThrottle.useItem) then
            return
        end

        local xPlayer = ESX.GetPlayerFromId(source)

        if not xPlayer then
            return
        end

        local count = xPlayer.getInventoryItem(itemName).count

        if count < 1 then
            return xPlayer.showNotification(TranslateCap("act_imp"))
        end

        ESX.UseItem(source, itemName)
    end)

    RegisterNetEvent("esx:onPickup", function(pickupId)
        Core.DebugCounter("event:onPickup")
        if not Core.AllowPlayerEvent(source, "pickup", Config.EventThrottle.pickup) then
            return
        end

        local pickup, xPlayer, success = Core.Pickups[pickupId], ESX.GetPlayerFromId(source)

        if not xPlayer then
            return
        end

        if not pickup then return end

        local playerPickupDistance = #(pickup.coords - xPlayer.getCoords(true))
        if playerPickupDistance > 5.0 then
            print(("[^3WARNING^7] Player Detected Cheating (Out of range pickup): ^5%s^7"):format(xPlayer.getIdentifier()))
            return
        end

        if pickup.type == "item_standard" then
            if not xPlayer.canCarryItem(pickup.name, pickup.count) then
                return xPlayer.showNotification(TranslateCap("threw_cannot_pickup"))
            end

            xPlayer.addInventoryItem(pickup.name, pickup.count)
            success = true
        elseif pickup.type == "item_account" then
            success = true
            xPlayer.addAccountMoney(pickup.name, pickup.count, "Picked up")
        elseif pickup.type == "item_weapon" then
            if xPlayer.hasWeapon(pickup.name) then
                return xPlayer.showNotification(TranslateCap("threw_weapon_already"))
            end

            success = true
            xPlayer.addWeapon(pickup.name, pickup.count)
            xPlayer.setWeaponTint(pickup.name, pickup.tintIndex)

            for _, v in ipairs(pickup.components) do
                xPlayer.addWeaponComponent(pickup.name, v)
            end
        end

        if success then
            Core.Pickups[pickupId] = nil
            TriggerClientEvent("esx:removePickup", -1, pickupId)
        end
    end)
end

local function buildCallbackPlayerData(xPlayer, fullPayload)
    local payload = {
        identifier = xPlayer.identifier,
        job = xPlayer.getJob(),
        money = xPlayer.getMoney(),
        metadata = xPlayer.getMeta(),
    }

    if fullPayload then
        payload.accounts = xPlayer.getAccounts()
        payload.inventory = xPlayer.inventoryList
        payload.loadout = xPlayer.getLoadout()
        payload.position = xPlayer.getCoords(true)
    else
        payload.accounts = xPlayer.getAccounts(true)
        payload.inventory = xPlayer.getInventory(true)
        payload.loadout = xPlayer.getLoadout(true)
    end

    return payload
end

local function getCallbackTargetPlayer(source, target)
    return ESX.Players[target or source]
end

ESX.RegisterServerCallback("esx:getPlayerData", function(source, cb, fullPayload)
    local xPlayer = getCallbackTargetPlayer(source)

    if not xPlayer then
        return
    end

    cb(buildCallbackPlayerData(xPlayer, fullPayload == true))
end)

ESX.RegisterServerCallback("esx:isUserAdmin", function(source, cb)
    cb(Core.IsPlayerAdmin(source))
end)

ESX.RegisterServerCallback("esx:getGameBuild", function(_, cb)
    cb(tonumber(GetConvar("sv_enforceGameBuild", "1604")))
end)

ESX.RegisterServerCallback("esx:getOtherPlayerData", function(_, cb, target, fullPayload)
    local xPlayer = getCallbackTargetPlayer(nil, target)

    if not xPlayer then
        return
    end

    cb(buildCallbackPlayerData(xPlayer, fullPayload == true))
end)

ESX.RegisterServerCallback("esx:getPlayerNames", function(source, cb, players)
    players[source] = nil

    for playerId, _ in pairs(players) do
        local xPlayer = ESX.Players[playerId]

        if xPlayer then
            players[playerId] = xPlayer.name
        else
            players[playerId] = nil
        end
    end

    cb(players)
end)

ESX.RegisterServerCallback("esx:spawnVehicle", function(source, cb, vehData)
    local ped = GetPlayerPed(source)
    ESX.OneSync.SpawnVehicle(vehData.model or `ADDER`, vehData.coords or GetEntityCoords(ped), vehData.coords.w or 0.0, vehData.props or {}, function(id)
        if vehData.warp then
            local vehicle = NetworkGetEntityFromNetworkId(id)
            local timeout = 0
            while GetVehiclePedIsIn(ped, false) ~= vehicle and timeout <= 15 do
                Wait(0)
                TaskWarpPedIntoVehicle(ped, vehicle, -1)
                timeout += 1
            end
        end
        cb(id)
    end)
end)

AddEventHandler("txAdmin:events:scheduledRestart", function(eventData)
    if eventData.secondsRemaining == 60 then
        CreateThread(function()
            Wait(50000)
            Core.SavePlayers()
        end)
    end
end)

AddEventHandler("txAdmin:events:serverShuttingDown", function()
    Core.SavePlayers()
end)

local DoNotUse = {
    ["essentialmode"] = true,
    ["es_admin2"] = true,
    ["basic-gamemode"] = true,
    ["mapmanager"] = true,
    ["fivem-map-skater"] = true,
    ["fivem-map-hipster"] = true,
    ["qb-core"] = true,
    ["default_spawnpoint"] = true,
}

AddEventHandler("onResourceStart", function(key)
    if DoNotUse[string.lower(key)] then
        while GetResourceState(key) ~= "started" do
            Wait(0)
        end

        StopResource(key)
        error(("WE STOPPED A RESOURCE THAT WILL BREAK ^1ESX^1, PLEASE REMOVE ^5%s^1"):format(key))
    end
    -- luacheck: ignore
    if not SetEntityOrphanMode then
        CreateThread(function()
            while true do
                error("ESX Requires a minimum Artifact version of 10188, Please update your server.")
                Wait(60 * 1000)
            end
        end)
    end
end)

for key in pairs(DoNotUse) do
    if GetResourceState(key) == "started" or GetResourceState(key) == "starting" then
        StopResource(key)
        error(("WE STOPPED A RESOURCE THAT WILL BREAK ^1ESX^1, PLEASE REMOVE ^5%s^1"):format(key))
    end
end
