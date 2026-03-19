local pickups = {}
local inventoryIndex = {}
local pickupBuckets = {}
local pickupRenderState = {
    visible = {},
    promptPickupId = nil,
}
local ammoState = {
    lastAmmo = {},
    lastSyncTime = {},
    pending = {},
    currentWeapon = false,
}

local function getPickupBucketKey(coords)
    return ("%s:%s"):format(
        math.floor(coords.x / Config.PickupBucketSize),
        math.floor(coords.y / Config.PickupBucketSize)
    )
end

local function addPickupToBucket(pickupId, pickup)
    local bucketKey = getPickupBucketKey(pickup.coords)
    pickup.bucketKey = bucketKey
    pickupBuckets[bucketKey] = pickupBuckets[bucketKey] or {}
    pickupBuckets[bucketKey][pickupId] = true
end

local function removePickupFromBucket(pickupId, pickup)
    if not pickup or not pickup.bucketKey or not pickupBuckets[pickup.bucketKey] then
        return
    end

    pickupBuckets[pickup.bucketKey][pickupId] = nil
    if not next(pickupBuckets[pickup.bucketKey]) then
        pickupBuckets[pickup.bucketKey] = nil
    end
end

local function getNearbyPickupIds(coords)
    local nearbyPickupIds = {}
    local centerX = math.floor(coords.x / Config.PickupBucketSize)
    local centerY = math.floor(coords.y / Config.PickupBucketSize)

    for offsetX = -1, 1 do
        for offsetY = -1, 1 do
            local bucket = pickupBuckets[("%s:%s"):format(centerX + offsetX, centerY + offsetY)]
            if bucket then
                for pickupId in pairs(bucket) do
                    nearbyPickupIds[#nearbyPickupIds + 1] = pickupId
                end
            end
        end
    end

    return nearbyPickupIds
end

local function clearPickupRenderState()
    for pickupId, pickup in pairs(pickups) do
        if pickup.inRange then
            pickup.inRange = false
        end
    end

    pickupRenderState.visible = {}
    pickupRenderState.promptPickupId = nil
end

local function refreshPickupRenderState()
    local ped = ESX.PlayerData.ped
    if not ped or ped == 0 or not ESX.PlayerLoaded then
        clearPickupRenderState()
        return false
    end

    local playerCoords = GetEntityCoords(ped)
    local nearbyPickupIds = getNearbyPickupIds(playerCoords)
    local visiblePickups = {}
    local promptPickupId
    local closestPromptDistance = Config.PickupPromptDistance

    for i = 1, #nearbyPickupIds do
        local pickupId = nearbyPickupIds[i]
        local pickup = pickups[pickupId]

        if pickup then
            local distance = #(playerCoords - pickup.coords)

            if distance < Config.PickupDrawDistance then
                visiblePickups[#visiblePickups + 1] = {
                    id = pickupId,
                    distance = distance,
                }

                if distance < closestPromptDistance then
                    closestPromptDistance = distance
                    promptPickupId = pickupId
                end
            elseif pickup.inRange then
                pickup.inRange = false
            end
        end
    end

    pickupRenderState.visible = visiblePickups
    pickupRenderState.promptPickupId = promptPickupId

    return #visiblePickups > 0
end

local function rebuildInventoryIndex()
    inventoryIndex = {}

    if not ESX.PlayerData.inventory then
        return
    end

    for index = 1, #ESX.PlayerData.inventory do
        inventoryIndex[ESX.PlayerData.inventory[index].name] = index
    end
end

RegisterNetEvent("esx:requestModel", function(model)
    ESX.Streaming.RequestModel(model)
end)

RegisterNetEvent("esx:playerLoaded", function(xPlayer, _, skin)
    ESX.PlayerData = xPlayer
    rebuildInventoryIndex()

    ESX.SpawnPlayer(skin, ESX.PlayerData.coords, function()
        TriggerEvent("esx:onPlayerSpawn")
        TriggerEvent("esx:restoreLoadout")
        TriggerServerEvent("esx:onPlayerSpawn")
        TriggerEvent("esx:loadingScreenOff")
        ShutdownLoadingScreen()
        ShutdownLoadingScreenNui()
    end)

    while not DoesEntityExist(ESX.PlayerData.ped) do
        Wait(20)
    end

    ESX.PlayerLoaded = true

    local timer = GetGameTimer()
    while not HaveAllStreamingRequestsCompleted(ESX.PlayerData.ped) and (GetGameTimer() - timer) < 2000 do
        Wait(5)
    end

    Adjustments:Load()

    ClearPedTasksImmediately(ESX.PlayerData.ped)

    Core.FreezePlayer(false)

    if IsScreenFadedOut() then
        DoScreenFadeIn(500)
    end

    Actions:Init()
    StartPointsLoop()
    NetworkSetLocalPlayerSyncLookAt(true)
end)

local isFirstSpawn = true
ESX.SecureNetEvent("esx:onPlayerLogout", function()
    ESX.PlayerLoaded = false
    isFirstSpawn = true
    clearPickupRenderState()
end)

ESX.SecureNetEvent("esx:setMaxWeight", function(newMaxWeight)
    ESX.SetPlayerData("maxWeight", newMaxWeight)
end)

ESX.SecureNetEvent("esx:setInventory", function(newInventory)
    ESX.SetPlayerData("inventory", newInventory)
    rebuildInventoryIndex()
end)

local function syncWeaponAmmoState(weaponName, force)
    if Config.CustomInventory or not weaponName or not ESX.PlayerLoaded or not ESX.PlayerData.ped then
        return
    end

    local weaponHash = joaat(weaponName)
    local currentAmmo = GetAmmoInPedWeapon(ESX.PlayerData.ped, weaponHash)
    local lastAmmo = ammoState.lastAmmo[weaponName]
    local now = GetGameTimer()

    if not force and currentAmmo == lastAmmo then
        return
    end

    if not force and (now - (ammoState.lastSyncTime[weaponName] or 0)) < 250 then
        return
    end

    ammoState.lastAmmo[weaponName] = currentAmmo
    ammoState.lastSyncTime[weaponName] = now
    LocalPlayer.state:set(("ammo:%s"):format(weaponName), currentAmmo, true)
end

local function scheduleWeaponAmmoSync(weaponName, delay, force)
    if ammoState.pending[weaponName] then
        return
    end

    ammoState.pending[weaponName] = true
    SetTimeout(delay or 0, function()
        ammoState.pending[weaponName] = nil
        syncWeaponAmmoState(weaponName, force == true)
    end)
end

AddEventHandler("esx:weaponChanged", function(weaponHash)
    local previousWeapon = ammoState.currentWeapon
    if previousWeapon and previousWeapon ~= false then
        scheduleWeaponAmmoSync(previousWeapon, 0, true)
    end

    if not weaponHash or weaponHash == false or weaponHash == `WEAPON_UNARMED` then
        ammoState.currentWeapon = false
        return
    end

    local weaponConfig = ESX.GetWeaponFromHash(weaponHash)
    if not weaponConfig then
        ammoState.currentWeapon = false
        return
    end

    ammoState.currentWeapon = weaponConfig.name
    ammoState.lastAmmo[weaponConfig.name] = nil
    scheduleWeaponAmmoSync(weaponConfig.name, 0, true)
end)

AddEventHandler("gameEventTriggered", function(eventName)
    if Config.CustomInventory or not ESX.PlayerLoaded or not ESX.PlayerData.ped then
        return
    end

    local weaponName = ammoState.currentWeapon
    if not weaponName then
        return
    end

    if eventName == "CEventGunShot" or eventName == "CEventGunReload" or IsPedShooting(ESX.PlayerData.ped) or IsPedReloading(ESX.PlayerData.ped) then
        scheduleWeaponAmmoSync(weaponName, IsPedReloading(ESX.PlayerData.ped) and 250 or 0, false)
    end

    if eventName == "CEventParachuteDeploy" or eventName == "CEventParachuteLanding" then
        ammoState.lastAmmo.GADGET_PARACHUTE = nil
        scheduleWeaponAmmoSync("GADGET_PARACHUTE", 0, true)
    end
end)

AddStateBagChangeHandler(nil, nil, function(bagName, key, value, _, replicated)
    if not replicated or type(key) ~= "string" or key:sub(1, 5) ~= "ammo:" then
        return
    end

    if bagName ~= ("player:%s"):format(ESX.serverId) or not ESX.PlayerData.ped then
        return
    end

    local weaponName = key:sub(6)
    local ammoCount = math.max(0, math.floor(tonumber(value) or 0))
    SetPedAmmo(ESX.PlayerData.ped, joaat(weaponName), ammoCount)
    ammoState.lastAmmo[weaponName] = ammoCount
    ammoState.lastSyncTime[weaponName] = GetGameTimer()
end)

local function onPlayerSpawn()
    ESX.SetPlayerData("ped", PlayerPedId())
    ESX.SetPlayerData("dead", false)
end

AddEventHandler("playerSpawned", onPlayerSpawn)
AddEventHandler("esx:onPlayerSpawn", function()
    onPlayerSpawn()

    if isFirstSpawn then
        isFirstSpawn = false

        if ESX.PlayerData.metadata.health and (ESX.PlayerData.metadata.health > 0 or Config.SaveDeathStatus) then
            SetEntityHealth(ESX.PlayerData.ped, ESX.PlayerData.metadata.health)
        end

        if ESX.PlayerData.metadata.armor and ESX.PlayerData.metadata.armor > 0 then
            SetPedArmour(ESX.PlayerData.ped, ESX.PlayerData.metadata.armor)
        end
    end
end)

AddEventHandler("esx:onPlayerDeath", function()
    ESX.SetPlayerData("ped", PlayerPedId())
    ESX.SetPlayerData("dead", true)
end)

local isResyncingPlayerCache = false

local function resyncPlayerCacheFromServer(cb)
    if isResyncingPlayerCache then
        return cb and cb()
    end

    isResyncingPlayerCache = true
    ESX.TriggerServerCallback("esx:getPlayerData", function(payload)
        isResyncingPlayerCache = false

        if not payload then
            return cb and cb()
        end

        ESX.SetPlayerData("identifier", payload.identifier)
        ESX.SetPlayerData("job", payload.job)
        ESX.SetPlayerData("money", payload.money)
        ESX.SetPlayerData("metadata", payload.metadata)

        if payload.accounts then
            ESX.SetPlayerData("accounts", payload.accounts)
        end

        if payload.inventory then
            ESX.SetPlayerData("inventory", payload.inventory)
            rebuildInventoryIndex()
        end

        if payload.loadout then
            ESX.SetPlayerData("loadout", payload.loadout)
        end

        if payload.position then
            ESX.SetPlayerData("coords", payload.position)
        end

        if cb then
            cb()
        end
    end, true)
end

AddEventHandler("skinchanger:modelLoaded", function()
    while not ESX.PlayerLoaded do
        Wait(100)
    end

    resyncPlayerCacheFromServer(function()
        TriggerEvent("esx:restoreLoadout")
    end)
end)

AddEventHandler("esx:restoreLoadout", function()
    ESX.SetPlayerData("ped", PlayerPedId())

    if not Config.CustomInventory then
        local ammoTypes = {}
        RemoveAllPedWeapons(ESX.PlayerData.ped, true)

        for _, v in ipairs(ESX.PlayerData.loadout) do
            local weaponName = v.name
            local weaponHash = joaat(weaponName)

            GiveWeaponToPed(ESX.PlayerData.ped, weaponHash, 0, false, false)
            SetPedWeaponTintIndex(ESX.PlayerData.ped, weaponHash, v.tintIndex)

            local ammoType = GetPedAmmoTypeFromWeapon(ESX.PlayerData.ped, weaponHash)

            for _, v2 in ipairs(v.components) do
                local componentHash = ESX.GetWeaponComponent(weaponName, v2).hash
                GiveWeaponComponentToPed(ESX.PlayerData.ped, weaponHash, componentHash)
            end

            if not ammoTypes[ammoType] then
                AddAmmoToPed(ESX.PlayerData.ped, weaponHash, v.ammo)
                ammoTypes[ammoType] = true
            end
        end
    end
end)

---@diagnostic disable-next-line: param-type-mismatch
AddStateBagChangeHandler("VehicleProperties", nil, function(bagName, _, value)
    if not value then
        return
    end

    bagName = bagName:gsub("entity:", "")
    local netId = tonumber(bagName)
    if not netId then
        error("Tried to set vehicle properties with invalid netId")
        return
    end

    local tries = 0
    
    while not NetworkDoesEntityExistWithNetworkId(netId) do
        Wait(200)
        tries = tries + 1
        if tries > 20 then
            return error(("Invalid entity - ^5%s^7!"):format(netId))
        end
    end

    local vehicle = NetToVeh(netId)

    if NetworkGetEntityOwner(vehicle) ~= ESX.playerId then
        return
    end

    ESX.Game.SetVehicleProperties(vehicle, value)
end)

ESX.SecureNetEvent("esx:setAccountMoney", function(account)
    for i = 1, #ESX.PlayerData.accounts do
        if ESX.PlayerData.accounts[i].name == account.name then
            ESX.PlayerData.accounts[i] = account
            break
        end
    end

    ESX.SetPlayerData("accounts", ESX.PlayerData.accounts)
end)

ESX.SecureNetEvent("esx:updateAccounts", function(updates)
    local accounts = ESX.PlayerData.accounts
    if not accounts then
        return
    end

    for i = 1, #updates do
        local update = updates[i]
        for accountIndex = 1, #accounts do
            if accounts[accountIndex].name == update.name then
                accounts[accountIndex] = update
                break
            end
        end
    end

    ESX.SetPlayerData("accounts", accounts)
end)

if not Config.CustomInventory then
    ESX.SecureNetEvent("esx:updateInventory", function(updates)
        for i = 1, #updates do
            local update = updates[i]
            local index = inventoryIndex[update.name]

            if index then
                local inventoryItem = ESX.PlayerData.inventory[index]
                if update.delta > 0 then
                    ESX.UI.ShowInventoryItemNotification(true, inventoryItem.label, update.delta)
                elseif update.delta < 0 then
                    ESX.UI.ShowInventoryItemNotification(false, inventoryItem.label, -update.delta)
                end

                inventoryItem.count = update.count
            end
        end
    end)

    ESX.SecureNetEvent("esx:addInventoryItem", function(item, count, showNotification)
        local index = inventoryIndex[item]
        if index then
            local inventoryItem = ESX.PlayerData.inventory[index]
            ESX.UI.ShowInventoryItemNotification(true, inventoryItem.label, count - inventoryItem.count)
            inventoryItem.count = count
        end

        if showNotification then
            ESX.UI.ShowInventoryItemNotification(true, item, count)
        end
    end)

    ESX.SecureNetEvent("esx:removeInventoryItem", function(item, count, showNotification)
        local index = inventoryIndex[item]
        if index then
            local inventoryItem = ESX.PlayerData.inventory[index]
            ESX.UI.ShowInventoryItemNotification(false, inventoryItem.label, inventoryItem.count - count)
            inventoryItem.count = count
        end

        if showNotification then
            ESX.UI.ShowInventoryItemNotification(false, item, count)
        end
    end)

    ESX.SecureNetEvent("esx:addLoadoutItem", function(weaponName, weaponLabel, ammo)
        table.insert(ESX.PlayerData.loadout, {
            name = weaponName,
            ammo = ammo,
            label = weaponLabel,
            components = {},
            tintIndex = 0,
        })
    end)

    ESX.SecureNetEvent("esx:removeLoadoutItem", function(weaponName, weaponLabel)
        for i = 1, #ESX.PlayerData.loadout do
            if ESX.PlayerData.loadout[i].name == weaponName then
                table.remove(ESX.PlayerData.loadout, i)
                break
            end
        end
    end)

    RegisterNetEvent("esx:addWeapon", function()
        error("event ^5'esx:addWeapon'^1 Has Been Removed. Please use ^5xPlayer.addWeapon^1 Instead!")
    end)


    RegisterNetEvent("esx:addWeaponComponent", function()
        error("event ^5'esx:addWeaponComponent'^1 Has Been Removed. Please use ^5xPlayer.addWeaponComponent^1 Instead!")
    end)

    RegisterNetEvent("esx:setWeaponAmmo", function()
        error("event ^5'esx:setWeaponAmmo'^1 Has Been Removed. Please use ^5xPlayer.addWeaponAmmo^1 Instead!")
    end)

    ESX.SecureNetEvent("esx:setWeaponTint", function(weapon, weaponTintIndex)
        SetPedWeaponTintIndex(ESX.PlayerData.ped, joaat(weapon), weaponTintIndex)
    end)

    RegisterNetEvent("esx:removeWeapon", function()
        error("event ^5'esx:removeWeapon'^1 Has Been Removed. Please use ^5xPlayer.removeWeapon^1 Instead!")
    end)

    ESX.SecureNetEvent("esx:removeWeaponComponent", function(weapon, weaponComponent)
        local componentHash = ESX.GetWeaponComponent(weapon, weaponComponent).hash
        RemoveWeaponComponentFromPed(ESX.PlayerData.ped, joaat(weapon), componentHash)
    end)
end

ESX.SecureNetEvent("esx:setJob", function(Job)
    ESX.SetPlayerData("job", Job)
end)

ESX.SecureNetEvent("esx:setGroup", function(group)
    ESX.SetPlayerData("group", group)
end)

if not Config.CustomInventory then
    ESX.SecureNetEvent("esx:createPickup", function(pickupId, label, coords, itemType, name, components, tintIndex)
        local function setObjectProperties(object)
            SetEntityAsMissionEntity(object, true, false)
            PlaceObjectOnGroundProperly(object)
            FreezeEntityPosition(object, true)
            SetEntityCollision(object, false, true)

            pickups[pickupId] = {
                obj = object,
                label = label,
                inRange = false,
                coords = coords,
            }
            addPickupToBucket(pickupId, pickups[pickupId])
        end

        if itemType == "item_weapon" then
            local weaponHash = joaat(name)
            ESX.Streaming.RequestWeaponAsset(weaponHash)
            local pickupObject = CreateWeaponObject(weaponHash, 50, coords.x, coords.y, coords.z, true, 1.0, 0)
            SetWeaponObjectTintIndex(pickupObject, tintIndex)

            for _, v in ipairs(components) do
                local component = ESX.GetWeaponComponent(name, v)
                if component then
                    GiveWeaponComponentToWeaponObject(pickupObject, component.hash)
                end
            end

            setObjectProperties(pickupObject)
        else
            ESX.Game.SpawnLocalObject("prop_money_bag_01", coords, setObjectProperties)
        end
    end)

    ESX.SecureNetEvent("esx:createMissingPickups", function(missingPickups)
        for pickupId, pickup in pairs(missingPickups) do
            TriggerEvent("esx:createPickup", pickupId, pickup.label, vector3(pickup.coords.x, pickup.coords.y, pickup.coords.z - 1.0), pickup.type, pickup.name, pickup.components, pickup.tintIndex)
        end
    end)
end

ESX.SecureNetEvent("esx:registerSuggestions", function(registeredCommands)
    for name, command in pairs(registeredCommands) do
        if command.suggestion then
            TriggerEvent("chat:addSuggestion", ("/%s"):format(name), command.suggestion.help, command.suggestion.arguments)
        end
    end
end)

if not Config.CustomInventory then
    ESX.SecureNetEvent("esx:removePickup", function(pickupId)
        if pickups[pickupId] and pickups[pickupId].obj then
            removePickupFromBucket(pickupId, pickups[pickupId])
            ESX.Game.DeleteObject(pickups[pickupId].obj)
            pickups[pickupId] = nil
            if pickupRenderState.promptPickupId == pickupId then
                pickupRenderState.promptPickupId = nil
            end
        end
    end)
end

if not Config.CustomInventory then
    local function schedulePickupScan()
        local hasVisiblePickups = refreshPickupRenderState()
        SetTimeout(hasVisiblePickups and Config.PickupScanInterval or Config.PickupIdleInterval, schedulePickupScan)
    end

    local function renderVisiblePickups()
        if not ESX.PlayerLoaded or not ESX.PlayerData.ped then
            clearPickupRenderState()
            return SetTimeout(Config.PickupIdleInterval, renderVisiblePickups)
        end

        local visiblePickups = pickupRenderState.visible
        if #visiblePickups == 0 then
            return SetTimeout(Config.PickupIdleInterval, renderVisiblePickups)
        end

        local promptPickupId = pickupRenderState.promptPickupId
        local ped = ESX.PlayerData.ped

        for i = 1, #visiblePickups do
            local pickupState = visiblePickups[i]
            local pickup = pickups[pickupState.id]

            if pickup then
                local label = pickup.label

                if pickupState.id == promptPickupId then
                    label = ("%s~n~%s"):format(label, TranslateCap("threw_pickup_prompt"))
                elseif pickup.inRange then
                    pickup.inRange = false
                end

                local textCoords = pickup.coords + vector3(0.0, 0.0, 0.25)
                ESX.Game.Utils.DrawText3D(textCoords, label, 1.2, 1)
            end
        end

        if promptPickupId and IsControlJustReleased(0, 38) then
            local pickup = pickups[promptPickupId]
            if pickup and IsPedOnFoot(ped) and not pickup.inRange then
                local _, closestDistance = ESX.Game.GetClosestPlayer(GetEntityCoords(ped))
                if closestDistance == -1 or closestDistance > 3 then
                    pickup.inRange = true

                    local dict, anim = "weapons@first_person@aim_rng@generic@projectile@sticky_bomb@", "plant_floor"
                    ESX.Streaming.RequestAnimDict(dict)
                    TaskPlayAnim(ped, dict, anim, 8.0, 1.0, 1000, 16, 0.0, false, false, false)
                    RemoveAnimDict(dict)
                    Wait(1000)

                    TriggerServerEvent("esx:onPickup", promptPickupId)
                    PlaySoundFrontend(-1, "PICK_UP", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
                end
            end
        end

        SetTimeout(50, renderVisiblePickups)
    end

    schedulePickupScan()
    renderVisiblePickups()
end

----- Admin commands from esx_adminplus
RegisterNetEvent("esx:tpm", function()
    local GetEntityCoords = GetEntityCoords
    local GetGroundZFor_3dCoord = GetGroundZFor_3dCoord
    local GetFirstBlipInfoId = GetFirstBlipInfoId
    local DoesBlipExist = DoesBlipExist
    local DoScreenFadeOut = DoScreenFadeOut
    local GetBlipInfoIdCoord = GetBlipInfoIdCoord
    local GetVehiclePedIsIn = GetVehiclePedIsIn

    ESX.TriggerServerCallback("esx:isUserAdmin", function(admin)
        if not admin then
            return
        end
        local blipMarker = GetFirstBlipInfoId(8)
        if not DoesBlipExist(blipMarker) then
            ESX.ShowNotification(TranslateCap("tpm_nowaypoint"), "error")
            return "marker"
        end

        -- Fade screen to hide how clients get teleported.
        DoScreenFadeOut(650)
        while not IsScreenFadedOut() do
            Wait(5)
        end

        local ped, coords = ESX.PlayerData.ped, GetBlipInfoIdCoord(blipMarker)
        local vehicle = GetVehiclePedIsIn(ped, false)
        local oldCoords = GetEntityCoords(ped)

        -- Unpack coords instead of having to unpack them while iterating.
        -- 825.0 seems to be the max a player can reach while 0.0 being the lowest.
        local x, y, groundZ, Z_START = coords["x"], coords["y"], 850.0, 950.0
        local found = false
        FreezeEntityPosition(vehicle > 0 and vehicle or ped, true)

        for i = Z_START, 0, -25.0 do
            local z = i
            if (i % 2) ~= 0 then
                z = Z_START - i
            end

            NewLoadSceneStart(x, y, z, x, y, z, 50.0, 0)
            local curTime = GetGameTimer()
            while IsNetworkLoadingScene() do
                if GetGameTimer() - curTime > 1000 then
                    break
                end
                Wait(5)
            end
            NewLoadSceneStop()
            SetPedCoordsKeepVehicle(ped, x, y, z)

            while not HasCollisionLoadedAroundEntity(ped) do
                RequestCollisionAtCoord(x, y, z)
                if GetGameTimer() - curTime > 1000 then
                    break
                end
                Wait(5)
            end

            -- Get ground coord. As mentioned in the natives, this only works if the client is in render distance.
            found, groundZ = GetGroundZFor_3dCoord(x, y, z, false)
            if found then
                Wait(5)
                SetPedCoordsKeepVehicle(ped, x, y, groundZ)
                break
            end
            Wait(5)
        end

        -- Remove black screen once the loop has ended.
        DoScreenFadeIn(650)
        FreezeEntityPosition(vehicle > 0 and vehicle or ped, false)

        if not found then
            -- If we can't find the coords, set the coords to the old ones.
            -- We don't unpack them before since they aren't in a loop and only called once.
            SetPedCoordsKeepVehicle(ped, oldCoords["x"], oldCoords["y"], oldCoords["z"] - 1.0)
            ESX.ShowNotification(TranslateCap("tpm_success"), "success")
        end

        -- If Z coord was found, set coords in found coords.
        SetPedCoordsKeepVehicle(ped, x, y, groundZ)
        ESX.ShowNotification(TranslateCap("tpm_success"), "success")
    end)
end)

local noclip = false
local noclip_pos = vector3(0, 0, 70)
local heading = 0

local function noclipThread()
    while noclip do
        SetEntityCoordsNoOffset(ESX.PlayerData.ped, noclip_pos.x, noclip_pos.y, noclip_pos.z, false, false, true)

        if IsControlPressed(1, 34) then
            heading = heading + 1.5
            if heading > 360 then
                heading = 0
            end

            SetEntityHeading(ESX.PlayerData.ped, heading)
        end

        if IsControlPressed(1, 9) then
            heading = heading - 1.5
            if heading < 0 then
                heading = 360
            end

            SetEntityHeading(ESX.PlayerData.ped, heading)
        end

        if IsControlPressed(1, 8) then
            noclip_pos = GetOffsetFromEntityInWorldCoords(ESX.PlayerData.ped, 0.0, 1.0, 0.0)
        end

        if IsControlPressed(1, 32) then
            noclip_pos = GetOffsetFromEntityInWorldCoords(ESX.PlayerData.ped, 0.0, -1.0, 0.0)
        end

        if IsControlPressed(1, 27) then
            noclip_pos = GetOffsetFromEntityInWorldCoords(ESX.PlayerData.ped, 0.0, 0.0, 1.0)
        end

        if IsControlPressed(1, 173) then
            noclip_pos = GetOffsetFromEntityInWorldCoords(ESX.PlayerData.ped, 0.0, 0.0, -1.0)
        end
        Wait(5)
    end
end

RegisterNetEvent("esx:noclip", function()
    ESX.TriggerServerCallback("esx:isUserAdmin", function(admin)
        if not admin then
            return
        end

        if not noclip then
            noclip_pos = GetEntityCoords(ESX.PlayerData.ped, false)
            heading = GetEntityHeading(ESX.PlayerData.ped)
        end

        noclip = not noclip
        if noclip then
            CreateThread(noclipThread)
        end

        if noclip then
            ESX.ShowNotification(TranslateCap("noclip_message", Translate("enabled")), "success")
        else
            ESX.ShowNotification(TranslateCap("noclip_message", Translate("disabled")), "error")
        end
    end)
end)

RegisterNetEvent("esx:killPlayer", function()
    SetEntityHealth(ESX.PlayerData.ped, 0)
end)

RegisterNetEvent("esx:repairPedVehicle", function()
    local ped = ESX.PlayerData.ped
    local vehicle = GetVehiclePedIsIn(ped, false)
    SetVehicleEngineHealth(vehicle, 1000)
    SetVehicleEngineOn(vehicle, true, true, false)
    SetVehicleFixed(vehicle)
    SetVehicleDirtLevel(vehicle, 0)
end)

RegisterNetEvent("esx:freezePlayer", function(input)
    if input == "freeze" then
        SetEntityCollision(ESX.PlayerData.ped, false, false)
        FreezeEntityPosition(ESX.PlayerData.ped, true)
        SetPlayerInvincible(ESX.playerId, true)
    elseif input == "unfreeze" then
        SetEntityCollision(ESX.PlayerData.ped, true, true)
        FreezeEntityPosition(ESX.PlayerData.ped, false)
        SetPlayerInvincible(ESX.playerId, false)
    end
end)

ESX.RegisterClientCallback("esx:GetVehicleType", function(cb, model)
    cb(ESX.GetVehicleTypeClient(model))
end)

ESX.SecureNetEvent('esx:updatePlayerData', function(key, val)
	ESX.SetPlayerData(key, val)
end)

---@param command string
ESX.SecureNetEvent("esx:executeCommand", function(command)
    ExecuteCommand(command)
end)

AddEventHandler("onResourceStop", function(resource)
    if Core.Events[resource] then
        for i = 1, #Core.Events[resource] do
            RemoveEventHandler(Core.Events[resource][i])
        end
    end
end)
