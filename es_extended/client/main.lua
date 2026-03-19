Core = {}
Core.Input = {}
Core.Events = {}

ESX.PlayerData = {}
ESX.PlayerLoaded = false
ESX.playerId = PlayerId()
ESX.serverId = GetPlayerServerId(ESX.playerId)

ESX.UI = {}
ESX.UI.Menu = {}
ESX.UI.Menu.RegisteredTypes = {}
ESX.UI.Menu.Opened = {}

ESX.Game = {}
ESX.Game.Utils = {}

local function waitForPlayerActivation()
    if not NetworkIsPlayerActive(ESX.playerId) then
        return SetTimeout(100, waitForPlayerActivation)
    end

    ESX.DisableSpawnManager()
    DoScreenFadeOut(0)
    Wait(500)
    TriggerServerEvent("esx:onPlayerJoined")
end

CreateThread(waitForPlayerActivation)
