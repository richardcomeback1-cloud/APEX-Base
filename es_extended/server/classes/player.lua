---@class ESXAccount
---@field name string               # Account name (e.g., "bank", "money").
---@field money number              # Current balance in this account.
---@field label string              # Human-readable label for the account.
---@field round boolean             # Whether amounts are rounded for display.
---@field index number              # Index of the account in the player's accounts list.

---@class ESXItem
---@field name string               # Item identifier (internal name).
---@field label string              # Display name of the item.
---@field weight number             # Weight of a single unit of the item.
---@field usable boolean            # Whether the item can be used.
---@field rare boolean              # Whether the item is rare.
---@field canRemove boolean         # Whether the item can be removed from inventory.

---@class ESXInventoryItem:ESXItem
---@field count number              # Number of this item in the player's inventory.

---@class ESXJob
---@field id number                 # Job ID.
---@field name string               # Job internal name.
---@field label string              # Job display label.
---@field grade number              # Current grade/rank number.
---@field grade_name string         # Name of the current grade.
---@field grade_label string        # Label of the current grade.
---@field grade_salary number       # Salary for the current grade.
---@field skin_male table           # Skin configuration for male characters.
---@field skin_female table         # Skin configuration for female characters.
---@field onDuty boolean?           # Whether the player is currently on duty.

---@class ESXWeapon
---@field name string               # Weapon identifier (internal name).
---@field label string              # Weapon display name.

---@class ESXInventoryWeapon:ESXWeapon
---@field ammo number               # Amount of ammo in the weapon.
---@field components string[]       # List of components attached to the weapon.
---@field tintIndex number          # Current weapon tint index.

---@class ESXWeaponComponent
---@field name string               # Component identifier (internal name).
---@field label string              # Component display name.
---@field hash string|number        # Component hash or identifier.

---@class StaticPlayer
---@field src number                                              # Player's server ID.
--- Money Functions
---@field setMoney fun(money: number)                             # Set player's cash balance.
---@field getMoney fun(): number                                   # Get player's current cash balance.
---@field addMoney fun(money: number, reason: string)             # Add money to the player's cash balance.
---@field removeMoney fun(money: number, reason: string)          # Remove money from the player's cash balance.
---@field setAccountMoney fun(accountName: string, money: number, reason?: string)  # Set specific account balance.
---@field addAccountMoney fun(accountName: string, money: number, reason?: string)  # Add money to an account.
---@field removeAccountMoney fun(accountName: string, money: number, reason?: string) # Remove money from an account.
---@field getAccount fun(account: string): ESXAccount             # Get account data by name.
---@field getAccountMoney fun(accountName: string): number        # Get account balance by name.
---@field getAccounts fun(minimal?: boolean): ESXAccount[]|table<string,number>  # Get all accounts, optionally minimal.
--- Inventory Functions
---@field getInventory fun(minimal?: boolean): ESXInventoryItem[]|table<string,number>  # Get inventory, optionally minimal.
---@field getInventoryItem fun(itemName: string): ESXInventoryItem? # Get a specific item from inventory.
---@field addInventoryItem fun(itemName: string, count: number)     # Add items to inventory.
---@field removeInventoryItem fun(itemName: string, count: number)  # Remove items from inventory.
---@field setInventoryItem fun(itemName: string, count: number)     # Set item count in inventory.
---@field getWeight fun(): number                                   # Get current carried weight.
---@field getMaxWeight fun(): number                                # Get maximum carry weight.
---@field setMaxWeight fun(newWeight: number)                       # Set maximum carry weight.
---@field canCarryItem fun(itemName: string, count: number): boolean # Check if player can carry more of an item.
---@field canSwapItem fun(firstItem: string, firstItemCount: number, testItem: string, testItemCount: number): boolean # Check if items can be swapped.
---@field hasItem fun(item: string): ESXInventoryItem|false, number? # Check if player has an item.
---@field getLoadout fun(minimal?: boolean): ESXInventoryWeapon[]|table<string, {ammo:number, tintIndex?:number, components?:string[]}> # Get player's weapon loadout.
--- Job Functions
---@field getJob fun(): ESXJob                                         # Get player's current job.
---@field setJob fun(newJob: string, grade: string, onDuty?: boolean)  # Set player's job and grade.
---@field setGroup fun(newGroup: string)                               # Set player's permission group.
---@field getGroup fun(): string                                       # Get player's permission group.
--- Weapon Functions
---@field addWeapon fun(weaponName: string, ammo: number)                 # Give player a weapon.
---@field removeWeapon fun(weaponName: string)                             # Remove weapon from player.
---@field hasWeapon fun(weaponName: string): boolean                       # Check if player has a weapon.
---@field getWeapon fun(weaponName: string): number?, table?               # Get weapon ammo & components.
---@field addWeaponAmmo fun(weaponName: string, ammoCount: number)        # Add ammo to a weapon.
---@field removeWeaponAmmo fun(weaponName: string, ammoCount: number)     # Remove ammo from a weapon.
---@field updateWeaponAmmo fun(weaponName: string, ammoCount: number)     # Update ammo count for a weapon.
---@field addWeaponComponent fun(weaponName: string, weaponComponent: string)    # Add component to weapon.
---@field removeWeaponComponent fun(weaponName: string, weaponComponent: string) # Remove component from weapon.
---@field hasWeaponComponent fun(weaponName: string, weaponComponent: string): boolean # Check if weapon has component.
---@field setWeaponTint fun(weaponName: string, weaponTintIndex: number) # Set weapon tint.
---@field getWeaponTint fun(weaponName: string): number                  # Get weapon tint.
--- Player State Functions
---@field getIdentifier fun(): string                              # Get player's unique identifier.
---@field getSource fun(): number                                  # Get player source/server ID.
---@field getPlayerId fun(): number                                # Alias for getSource.
---@field getName fun(): string                                     # Get player's name.
---@field setName fun(newName: string)                              # Set player's name.
---@field setCoords fun(coordinates: vector4|vector3|table)        # Teleport player to coordinates.
---@field getCoords fun(vector?: boolean, heading?: boolean): vector3|vector4|table # Get player's coordinates.
---@field isAdmin fun(): boolean                                    # Check if player is admin.
---@field kick fun(reason: string)                                  # Kick player from server.
---@field getPlayTime fun(): number                                  # Get total playtime in seconds.
---@field set fun(k: string, v: any)                                # Set custom variable.
---@field get fun(k: string): any                                    # Get custom variable.
--- Metadata Functions
---@field getMeta fun(index?: string, subIndex?: string|table): any   # Get metadata value(s).
---@field setMeta fun(index: string, value: any, subValue?: any)      # Set metadata value(s).
---@field clearMeta fun(index: string, subValues?: string|table)      # Clear metadata value(s).
--- Notification Functions
---@field showNotification fun(msg: string, notifyType?: string, length?: number, title?: string, position?: string) # Show a simple notification.
---@field showAdvancedNotification fun(sender: string, subject: string, msg: string, textureDict: string, iconType: string, flash: boolean, saveToBrief: boolean, hudColorIndex: number) # Show advanced notification.
---@field showHelpNotification fun(msg: string, thisFrame?: boolean, beep?: boolean, duration?: number) # Show help notification.
--- Misc Functions
---@field togglePaycheck fun(toggle: boolean)     # Enable/disable paycheck.
---@field isPaycheckEnabled fun(): boolean       # Check if paycheck is enabled.
---@field executeCommand fun(command: string)    # Execute a server command.
---@field triggerEvent fun(eventName: string, ...) # Trigger client event for this player.


---@class xPlayer:StaticPlayer
--- Properties
---@field accounts table<string, ESXAccount> # Hashmap of the player's accounts.
---@field coords table              # Player's coordinates {x, y, z, heading}.
---@field group string              # Player permission group.
---@field identifier string         # Unique identifier (Steam Hex).
---@field inventory ESXInventoryItem[] # Player's inventory items.
---@field job ESXJob                # Player's current job.
---@field loadout ESXInventoryWeapon[] # Player's current weapons.
---@field name string               # Player's display name.
---@field playerId number           # Player's ID (server ID).
---@field source number             # Player's source (alias for playerId).
---@field variables table           # Custom player variables.
---@field weight number             # Current carried weight.
---@field maxWeight number          # Maximum carry weight.
---@field metadata table            # Custom metadata table.
---@field lastPlaytime number       # Last recorded playtime in seconds.
---@field paycheckEnabled boolean   # Whether paycheck is enabled.
---@field admin boolean             # Whether the player is an admin.

---@param playerId number
---@param identifier string
---@param group string
---@param accounts table<string, number|ESXAccount>|ESXAccount[]
---@param inventory table
---@param weight number
---@param job ESXJob
---@param loadout ESXInventoryWeapon[]
---@param name string
---@param coords vector4|{x: number, y: number, z: number, heading: number}
---@param metadata table
---@return xPlayer
local stringLower = string.lower

local function normalizeAccountName(accountName)
    if type(accountName) ~= "string" then
        return nil
    end

    return stringLower(accountName)
end

local function createAccountEntry(accountName, money, config, index)
    return {
        name = accountName,
        money = money or 0,
        label = config and config.label or accountName,
        round = config and (config.round ~= false) or true,
        index = index,
    }
end

local function normalizeAccountsTable(rawAccounts)
    local accounts = {}

    if type(rawAccounts) ~= "table" then
        return accounts
    end

    if #rawAccounts > 0 then
        for i = 1, #rawAccounts do
            local entry = rawAccounts[i]
            if entry and entry.name then
                accounts[normalizeAccountName(entry.name)] = entry.money or 0
            end
        end

        return accounts
    end

    for accountName, value in pairs(rawAccounts) do
        local normalizedName = normalizeAccountName(accountName)
        if normalizedName then
            if type(value) == "table" then
                accounts[normalizedName] = value.money or value.amount or 0
            else
                accounts[normalizedName] = value or 0
            end
        end
    end

    return accounts
end

local function getItemLimit(itemName)
    local item = ESX.Items[itemName]
    if not item then
        return Config.DefaultItemLimit
    end

    return item.limit or Config.DefaultItemLimit
end

local function normalizeInventoryEntry(name, count, metadata)
    local itemData = ESX.Items[name]
    local usable = Core.UsableItemsCallbacks[name] ~= nil

    return {
        name = name,
        count = count or 0,
        label = itemData and itemData.label or name,
        limit = itemData and (itemData.limit or Config.DefaultItemLimit) or 0,
        metadata = metadata or {},
        weight = itemData and itemData.weight or 0,
        usable = usable,
        rare = itemData and itemData.rare or false,
        canRemove = itemData and itemData.canRemove ~= false or false,
    }
end

local function normalizeInventoryTable(rawInventory)
    local counts, metadata = {}, {}

    if type(rawInventory) ~= "table" then
        return counts, metadata
    end

    if #rawInventory > 0 then
        for i = 1, #rawInventory do
            local entry = rawInventory[i]
            if entry and entry.name then
                counts[entry.name] = entry.count or 0
                metadata[entry.name] = entry.metadata or {}
            end
        end

        return counts, metadata
    end

    for itemName, value in pairs(rawInventory) do
        if type(value) == "table" then
            counts[itemName] = value.count or value.amount or 0
            metadata[itemName] = value.metadata or {}
        else
            counts[itemName] = value or 0
        end
    end

    return counts, metadata
end

function CreateExtendedPlayer(playerId, identifier, group, accounts, inventory, weight, job, loadout, name, coords, metadata)
    ---@diagnostic disable-next-line: missing-fields
    local self = {} ---@type xPlayer

    self.accounts = {}
    self.accountsByName = self.accounts
    self.accountList = {}
    self.accountArrayDirty = true
    self.coords = coords
    self.group = group
    self.identifier = identifier
    self.inventory = {}
    self.inventoryList = {}
    self.inventoryArrayDirty = false
    self.job = job
    self.loadout = loadout
    self.name = name
    self.playerId = playerId
    self.source = playerId
    self.variables = {}
    self.weight = weight
    self.maxWeight = Config.MaxWeight
    self.metadata = metadata
    self.lastPlaytime = self.metadata.lastPlaytime or 0
    self.paycheckEnabled = true
    self.admin = Core.IsPlayerAdmin(playerId)
    if type(self.metadata.jobDuty) ~= "boolean" then
        self.metadata.jobDuty = self.job.name ~= "unemployed" and Config.DefaultJobDuty or false
    end
    job.onDuty = self.metadata.jobDuty

    ExecuteCommand(("add_principal identifier.%s group.%s"):format(self.identifier, self.group))

    local stateBag = Player(self.source).state
    stateBag:set("identifier", self.identifier, false)
    stateBag:set("job", self.job, true)
    stateBag:set("group", self.group, true)
    stateBag:set("name", self.name, true)

    local normalizedAccounts = normalizeAccountsTable(accounts)
    local accountIndex = 0

    for accountName, data in pairs(Config.Accounts) do
        accountIndex += 1
        self.accounts[accountName] = createAccountEntry(
            accountName,
            normalizedAccounts[accountName] or Config.StartingAccountMoney[accountName] or 0,
            data,
            accountIndex
        )
    end

    for accountName, money in pairs(normalizedAccounts) do
        if accountName and not self.accounts[accountName] then
            accountIndex += 1
            self.accounts[accountName] = createAccountEntry(accountName, money, Config.Accounts[accountName], accountIndex)
        end
    end

    local inventoryCounts, inventoryMetadata = normalizeInventoryTable(inventory)
    for itemName, itemData in pairs(ESX.Items) do
        local normalizedItem = normalizeInventoryEntry(itemName, inventoryCounts[itemName] or 0, inventoryMetadata[itemName])
        self.inventory[itemName] = normalizedItem
        self.inventoryList[#self.inventoryList + 1] = normalizedItem
    end

    table.sort(self.inventoryList, function(a, b)
        return a.label < b.label
    end)

    Core.BindPlayerCache(self)

    function self.triggerEvent(eventName, ...)
        assert(type(eventName) == "string", "eventName should be string!")
        TriggerClientEvent(eventName, self.source, ...)
    end

    function self.togglePaycheck(toggle)
        self.paycheckEnabled = toggle
    end

    function self.isPaycheckEnabled()
        return self.paycheckEnabled
    end

    function self.isAdmin()
        return Core.IsPlayerAdmin(self.source)
    end

    function self.setCoords(coordinates)
        local ped <const> = GetPlayerPed(self.source)

        SetEntityCoords(ped, coordinates.x, coordinates.y, coordinates.z, false, false, false, false)
        SetEntityHeading(ped, coordinates.w or coordinates.heading or 0.0)
        Core.MarkPlayerDirty(self, "position")
    end

    function self.getCoords(vector, heading)
        local ped <const> = GetPlayerPed(self.source)
        local entityCoords <const> = GetEntityCoords(ped)
        local entityHeading <const> = GetEntityHeading(ped)

        local coordinates = { x = entityCoords.x, y = entityCoords.y, z = entityCoords.z }

        if vector then
            coordinates = (heading and vector4(entityCoords.x, entityCoords.y, entityCoords.z, entityHeading) or entityCoords)
        else
            if heading then
                coordinates.heading = entityHeading
            end
        end

        return coordinates
    end

    function self.kick(reason)
        DropPlayer(self.source --[[@as string]], reason)
    end

    function self.getPlayTime()
        -- luacheck: ignore
        return self.lastPlaytime + GetPlayerTimeOnline(self.source --[[@as string]])
    end

    function self.setMoney(money)
        assert(type(money) == "number", "money should be number!")
        money = ESX.Math.Round(money)
        self.setAccountMoney("money", money)
    end

    function self.getMoney()
        return self.getAccountMoney("money")
    end

    function self.addMoney(money, reason)
        money = ESX.Math.Round(money)
        self.addAccountMoney("money", money, reason)
    end

    function self.removeMoney(money, reason)
        money = ESX.Math.Round(money)
        self.removeAccountMoney("money", money, reason)
    end

    function self.getIdentifier()
        return self.identifier
    end

    function self.setGroup(newGroup)
        local lastGroup = self.group

        ExecuteCommand(("remove_principal identifier.%s group.%s"):format(self.identifier, self.group))

        self.group = newGroup
        Core.MarkPlayerDirty(self, "group")

        TriggerEvent("esx:setGroup", self.source, self.group, lastGroup)
        self.triggerEvent("esx:setGroup", self.group, lastGroup)
        Player(self.source).state:set("group", self.group, true)

        ExecuteCommand(("add_principal identifier.%s group.%s"):format(self.identifier, self.group))
    end

    function self.getGroup()
        return self.group
    end

    function self.set(k, v)
        self.variables[k] = v

        self.triggerEvent('esx:updatePlayerData', 'variables', self.variables)
    end

    function self.get(k)
        return self.variables[k]
    end

    function self.getAccounts(minimal)
        if minimal then
            local minimalAccounts = {}

            for accountName, account in pairs(self.accounts) do
                minimalAccounts[accountName] = account.money
            end

            return minimalAccounts
        end

        if not self.accountArrayDirty then
            return self.accountList
        end

        local accountList = {}
        local nextIndex = 0

        for accountName in pairs(Config.Accounts) do
            local account = self.accounts[accountName]
            if account then
                nextIndex += 1
                account.index = nextIndex
                accountList[nextIndex] = account
            end
        end

        for accountName, account in pairs(self.accounts) do
            if not Config.Accounts[accountName] then
                nextIndex += 1
                account.index = nextIndex
                accountList[nextIndex] = account
            end
        end

        self.accountList = accountList
        self.accountArrayDirty = false

        return self.accountList
    end

    function self.getAccount(account)
        local accountName = normalizeAccountName(account)
        local cachedAccount = accountName and self.accounts[accountName]
        if cachedAccount then
            return cachedAccount
        end

        return {
            name = accountName or account,
            money = 0,
            label = "Unknown",
            round = true,
        }
    end

    function self.getAccountMoney(accountName)
        local normalizedName = normalizeAccountName(accountName)
        local account = normalizedName and self.accounts[normalizedName]
        return account and account.money or 0
    end

    function self.getInventory(minimal)
        if minimal then
            local minimalInventory = {}

            for itemName, v in pairs(self.inventory) do
                if v.count > 0 then
                    if next(v.metadata) then
                        minimalInventory[itemName] = {
                            count = v.count,
                            metadata = v.metadata,
                        }
                    else
                        minimalInventory[itemName] = v.count
                    end
                end
            end

            return minimalInventory
        end

        return self.inventoryList
    end

    function self.getJob()
        return self.job
    end

    function self.getLoadout(minimal)
        if not minimal then
            return self.loadout
        end
        local minimalLoadout = {}

        for _, v in ipairs(self.loadout) do
            minimalLoadout[v.name] = { ammo = v.ammo }
            if v.tintIndex > 0 then
                minimalLoadout[v.name].tintIndex = v.tintIndex
            end

            if #v.components > 0 then
                local components = {}

                for _, component in ipairs(v.components) do
                    if component ~= "clip_default" then
                        components[#components + 1] = component
                    end
                end

                if #components > 0 then
                    minimalLoadout[v.name].components = components
                end
            end
        end

        return minimalLoadout
    end

    function self.getName()
        return self.name
    end

    function self.setName(newName)
        self.name = newName
        Core.MarkPlayerDirty(self, "name")
        Player(self.source).state:set("name", self.name, true)
    end

    function self.setAccountMoney(accountName, money, reason)
        reason = reason or "unknown"
        if type(money) ~= "number" then
            error(("Tried To Set Account ^5%s^1 For Player ^5%s^1 To An Invalid Number -> ^5%s^1"):format(accountName, self.playerId, money))
            return
        end
        if money < 0 then
            error(("Tried To Set Account ^5%s^1 For Player ^5%s^1 To An Invalid Number -> ^5%s^1"):format(accountName, self.playerId, money))
            return false
        end

        local normalizedName = normalizeAccountName(accountName)
        if not normalizedName then
            return false
        end

        local account = self.accounts[normalizedName]
        if not account then
            self.accountArrayDirty = true
            account = createAccountEntry(normalizedName, 0, Config.Accounts[normalizedName], #self.accountList + 1)
            self.accounts[normalizedName] = account
        end

        money = account.round and ESX.Math.Round(money) or money
        account.money = money
        if normalizedName == "money" then
            self.cache.money = money
        end
        Core.MarkPlayerDirty(self, "accounts")
        Core.DebugCounter("account_mutations")

        self.triggerEvent("esx:setAccountMoney", account)
        TriggerEvent("esx:setAccountMoney", self.source, normalizedName, money, reason)
        return true
    end

    function self.addAccountMoney(accountName, money, reason)
        reason = reason or "Unknown"
        if type(money) ~= "number" then
            error(("Tried To Set Account ^5%s^1 For Player ^5%s^1 To An Invalid Number -> ^5%s^1"):format(accountName, self.playerId, money))
            return
        end
        if money <= 0 then
            error(("Tried To Set Account ^5%s^1 For Player ^5%s^1 To An Invalid Number -> ^5%s^1"):format(accountName, self.playerId, money))
            return false
        end

        local normalizedName = normalizeAccountName(accountName)
        local account = normalizedName and self.accounts[normalizedName]
        if not account then
            return false
        end

        money = account.round and ESX.Math.Round(money) or money
        account.money = account.money + money
        if normalizedName == "money" then
            self.cache.money = account.money
        end
        Core.MarkPlayerDirty(self, "accounts")
        Core.DebugCounter("account_mutations")

        self.triggerEvent("esx:setAccountMoney", account)
        TriggerEvent("esx:addAccountMoney", self.source, normalizedName, money, reason)
        return true
    end

    function self.removeAccountMoney(accountName, money, reason)
        reason = reason or "Unknown"
        if type(money) ~= "number" then
            error(("Tried To Set Account ^5%s^1 For Player ^5%s^1 To An Invalid Number -> ^5%s^1"):format(accountName, self.playerId, money))
            return
        end
        if money <= 0 then
            error(("Tried To Set Account ^5%s^1 For Player ^5%s^1 To An Invalid Number -> ^5%s^1"):format(accountName, self.playerId, money))
            return false
        end

        local normalizedName = normalizeAccountName(accountName)
        local account = normalizedName and self.accounts[normalizedName]
        if not account then
            return false
        end

        money = account.round and ESX.Math.Round(money) or money
        account.money = account.money - money
        if account.money < 0 then
            account.money = 0
        end
        if normalizedName == "money" then
            self.cache.money = account.money
        end
        Core.MarkPlayerDirty(self, "accounts")
        Core.DebugCounter("account_mutations")

        self.triggerEvent("esx:setAccountMoney", account)
        TriggerEvent("esx:removeAccountMoney", self.source, normalizedName, money, reason)
        return true
    end

    function self.getInventoryItem(itemName)
        local inventoryItem = self.inventory[itemName]
        if inventoryItem then
            return inventoryItem
        end

        inventoryItem = normalizeInventoryEntry(itemName, 0, {})
        if ESX.Items[itemName] then
            self.inventory[itemName] = inventoryItem
            self.inventoryList[#self.inventoryList + 1] = inventoryItem
            self.inventoryArrayDirty = true
        end

        return inventoryItem
    end

    function self.addInventoryItem(itemName, count)
        local startedAt = GetGameTimer()
        local item = self.getInventoryItem(itemName)
        local itemDefinition = ESX.Items[itemName]

        if not itemDefinition then
            return error(("Tried To Add Invalid Item ^5%s^1 For Player ^5%s^1!"):format(itemName, self.playerId))
        end

        count = ESX.Math.Round(count)
        if count <= 0 then
            return error(("Player ID:^5%s Tried add an invalid count -> %s of %s"):format(self.playerId, count, itemName))
        end

        local limit = item.limit
        if limit ~= -1 and (item.count + count) > limit then
            return false
        end

        item.count = item.count + count
        self.weight = self.weight + (item.weight * count)

        Core.MarkPlayerDirty(self, "inventory")
        Core.QueueInventorySync(self, item.name, item.count, count, item.label)
        Core.DebugCounter("inventory_mutations")

        TriggerEvent("esx:onAddInventoryItem", self.source, item.name, item.count)
        Core.DebugDuration("xPlayer.addInventoryItem", startedAt)
        return true
    end

    function self.removeInventoryItem(itemName, count)
        local startedAt = GetGameTimer()
        local item = self.getInventoryItem(itemName)

        count = ESX.Math.Round(count)
        if count <= 0 then
            return error(("Player ID:^5%s Tried remove a Invalid count -> %s of %s"):format(self.playerId, count, itemName))
        end

        if item.count < count then
            return false
        end

        item.count = item.count - count
        self.weight = self.weight - (item.weight * count)
        if self.weight < 0 then
            self.weight = 0
        end

        Core.MarkPlayerDirty(self, "inventory")
        Core.QueueInventorySync(self, item.name, item.count, -count, item.label)
        Core.DebugCounter("inventory_mutations")

        TriggerEvent("esx:onRemoveInventoryItem", self.source, item.name, item.count)
        Core.DebugDuration("xPlayer.removeInventoryItem", startedAt)
        return true
    end

    function self.setInventoryItem(itemName, count)
        local item = self.getInventoryItem(itemName)

        count = ESX.Math.Round(count)
        if item and count >= 0 then
            local delta = count - item.count
            if delta == 0 then
                return true
            end

            if delta > 0 then
                return self.addInventoryItem(item.name, delta)
            end

            return self.removeInventoryItem(item.name, -delta)
        end

        return false
    end

    function self.getWeight()
        return self.weight
    end

    function self.getSource()
        return self.source
    end
    self.getPlayerId = self.getSource

    function self.getMaxWeight()
        return self.maxWeight
    end

    function self.canCarryItem(itemName, count)
        local itemDefinition = ESX.Items[itemName]
        if not itemDefinition then
            print(('[^3WARNING^7] Item ^5"%s"^7 was used but does not exist!'):format(itemName))
            return false
        end

        if type(count) ~= "number" or count <= 0 then
            return false
        end

        local item = self.getInventoryItem(itemName)
        local limit = item.limit or getItemLimit(itemName)

        return limit == -1 or (item.count + count) <= limit
    end

    function self.canSwapItem(firstItem, firstItemCount, testItem, testItemCount)
        local firstItemObject = self.getInventoryItem(firstItem)
        if not firstItemObject then
            return false
        end
        local testItemObject = self.getInventoryItem(testItem)
        if not testItemObject then
            return false
        end

        if firstItemObject.count < firstItemCount then
            return false
        end

        local limit = testItemObject.limit or getItemLimit(testItem)
        if limit == -1 then
            return true
        end

        return (testItemObject.count + testItemCount) <= limit
    end

    function self.setMaxWeight(newWeight)
        self.maxWeight = newWeight
        self.triggerEvent("esx:setMaxWeight", self.maxWeight)
    end

    function self.setJob(newJob, grade, onDuty)
        grade = tostring(grade)
        local lastJob = self.job

        if not ESX.DoesJobExist(newJob, grade) then
            return print(("[ESX] [^3WARNING^7] Ignoring invalid ^5.setJob()^7 usage for ID: ^5%s^7, Job: ^5%s^7"):format(self.source, newJob))
        end

        if newJob == "unemployed" then
            onDuty = false
        end

        if type(onDuty) ~= "boolean" then
            onDuty = Config.DefaultJobDuty
        end

        local jobObject, gradeObject = ESX.Jobs[newJob], ESX.Jobs[newJob].grades[grade]

        self.job = {
            id = jobObject.id,
            name = jobObject.name,
            label = jobObject.label,
            onDuty = onDuty,

            grade = tonumber(grade) or 0,
            grade_name = gradeObject.name,
            grade_label = gradeObject.label,
            grade_salary = gradeObject.salary,

            skin_male = gradeObject.skin_male and json.decode(gradeObject.skin_male) or {},
            skin_female = gradeObject.skin_female and json.decode(gradeObject.skin_female) or {},
        }

        self.metadata.jobDuty = onDuty
        Core.MarkPlayerDirty(self, "job")
        TriggerEvent("esx:setJob", self.source, self.job, lastJob)
        self.triggerEvent("esx:setJob", self.job, lastJob)
        Player(self.source).state:set("job", self.job, true)
    end

    function self.addWeapon(weaponName, ammo)
        if not self.hasWeapon(weaponName) then
            local weaponLabel <const> = ESX.GetWeaponLabel(weaponName)

            table.insert(self.loadout, {
                name = weaponName,
                ammo = ammo,
                label = weaponLabel,
                components = {},
                tintIndex = 0,
            })

            GiveWeaponToPed(GetPlayerPed(self.source), joaat(weaponName), ammo, false, false)
            Core.MarkPlayerDirty(self, "loadout")
            self.triggerEvent("esx:addInventoryItem", weaponLabel, false, true)
            self.triggerEvent("esx:addLoadoutItem", weaponName, weaponLabel, ammo)
        end
    end

    function self.addWeaponComponent(weaponName, weaponComponent)
        local loadoutNum <const>, weapon <const> = self.getWeapon(weaponName)

        if weapon then
            local component = ESX.GetWeaponComponent(weaponName, weaponComponent)

            if component then
                if not self.hasWeaponComponent(weaponName, weaponComponent) then
                    self.loadout[loadoutNum].components[#self.loadout[loadoutNum].components + 1] = weaponComponent
                    local componentHash = ESX.GetWeaponComponent(weaponName, weaponComponent).hash
                    GiveWeaponComponentToPed(GetPlayerPed(self.source), joaat(weaponName), componentHash)
                    Core.MarkPlayerDirty(self, "loadout")
                    self.triggerEvent("esx:addInventoryItem", component.label, false, true)
                end
            end
        end
    end

    function self.addWeaponAmmo(weaponName, ammoCount)
        local _, weapon = self.getWeapon(weaponName)

        if weapon then
            weapon.ammo = weapon.ammo + ammoCount
            Core.MarkPlayerDirty(self, "loadout")
            SetPedAmmo(GetPlayerPed(self.source), joaat(weaponName), weapon.ammo)
        end
    end

    function self.updateWeaponAmmo(weaponName, ammoCount)
        local _, weapon = self.getWeapon(weaponName)

        if not weapon then
            return
        end

        weapon.ammo = ammoCount
        Core.MarkPlayerDirty(self, "loadout")

        if weapon.ammo <= 0 then
            local _, weaponConfig = ESX.GetWeapon(weaponName)
            if weaponConfig.throwable then
                self.removeWeapon(weaponName)
            end
        end
    end

    function self.setWeaponTint(weaponName, weaponTintIndex)
        local loadoutNum <const>, weapon <const> = self.getWeapon(weaponName)

        if weapon then
            local _, weaponObject <const> = ESX.GetWeapon(weaponName)

            if weaponObject.tints and weaponObject.tints[weaponTintIndex] then
                self.loadout[loadoutNum].tintIndex = weaponTintIndex
                Core.MarkPlayerDirty(self, "loadout")
                self.triggerEvent("esx:setWeaponTint", weaponName, weaponTintIndex)
                self.triggerEvent("esx:addInventoryItem", weaponObject.tints[weaponTintIndex], false, true)
            end
        end
    end

    function self.getWeaponTint(weaponName)
        local _, weapon <const> = self.getWeapon(weaponName)

        if weapon then
            return weapon.tintIndex
        end

        return 0
    end

    function self.removeWeapon(weaponName)
        local weaponLabel, playerPed <const> = nil, GetPlayerPed(self.source)

        if not playerPed then
            return error("xPlayer.removeWeapon ^5invalid^1 player ped!")
        end

        for k, v in ipairs(self.loadout) do
            if v.name == weaponName then
                weaponLabel = v.label

                for _, v2 in ipairs(v.components) do
                    self.removeWeaponComponent(weaponName, v2)
                end

                local weaponHash = joaat(v.name)
                RemoveWeaponFromPed(playerPed, weaponHash)
                SetPedAmmo(playerPed, weaponHash, 0)

                table.remove(self.loadout, k)
                Core.MarkPlayerDirty(self, "loadout")
                break
            end
        end

        if weaponLabel then
            self.triggerEvent("esx:removeInventoryItem", weaponLabel, false, true)
            self.triggerEvent("esx:removeLoadoutItem", weaponName, weaponLabel)
        end
    end

    function self.removeWeaponComponent(weaponName, weaponComponent)
        local loadoutNum <const>, weapon <const> = self.getWeapon(weaponName)

        if weapon then
            local component <const> = ESX.GetWeaponComponent(weaponName, weaponComponent)

            if component then
                if self.hasWeaponComponent(weaponName, weaponComponent) then
                    for k, v in ipairs(self.loadout[loadoutNum].components) do
                        if v == weaponComponent then
                            table.remove(self.loadout[loadoutNum].components, k)
                            break
                        end
                    end

                    Core.MarkPlayerDirty(self, "loadout")
                    self.triggerEvent("esx:removeWeaponComponent", weaponName, weaponComponent)
                    self.triggerEvent("esx:removeInventoryItem", component.label, false, true)
                end
            end
        end
    end

    function self.removeWeaponAmmo(weaponName, ammoCount)
        local _, weapon = self.getWeapon(weaponName)

        if weapon then
            weapon.ammo = weapon.ammo - ammoCount
            Core.MarkPlayerDirty(self, "loadout")
            SetPedAmmo(GetPlayerPed(self.source), joaat(weaponName), weapon.ammo)
        end
    end

    function self.hasWeaponComponent(weaponName, weaponComponent)
        local _, weapon <const> = self.getWeapon(weaponName)

        if weapon then
            for _, v in ipairs(weapon.components) do
                if v == weaponComponent then
                    return true
                end
            end

            return false
        end

        return false
    end

    function self.hasWeapon(weaponName)
        for _, v in ipairs(self.loadout) do
            if v.name == weaponName then
                return true
            end
        end

        return false
    end

    function self.hasItem(item)
        local inventoryItem = self.getInventoryItem(item)
        if inventoryItem.count >= 1 then
            return inventoryItem, inventoryItem.count
        end

        return false
    end

    function self.getWeapon(weaponName)
        for k, v in ipairs(self.loadout) do
            if v.name == weaponName then
                return k, v
            end
        end

        return nil, nil
    end

    function self.showNotification(msg, notifyType, length, title, position)
        self.triggerEvent("esx:showNotification", msg, notifyType, length, title, position)
    end

    function self.showAdvancedNotification(sender, subject, msg, textureDict, iconType, flash, saveToBrief, hudColorIndex)
        self.triggerEvent("esx:showAdvancedNotification", sender, subject, msg, textureDict, iconType, flash, saveToBrief, hudColorIndex)
    end

    function self.showHelpNotification(msg, thisFrame, beep, duration)
        self.triggerEvent("esx:showHelpNotification", msg, thisFrame, beep, duration)
    end

    function self.getMeta(index, subIndex)
        if not index then
            return self.metadata
        end

        if type(index) ~= "string" then
            error("xPlayer.getMeta ^5index^1 should be ^5string^1!")
            return
        end

        local metaData = self.metadata[index]
        if metaData == nil then
            return Config.EnableDebug and error(("xPlayer.getMeta ^5%s^1 not exist!"):format(index)) or nil
        end

        if subIndex and type(metaData) == "table" then
            local _type = type(subIndex)

            if _type == "string" then
                local value = metaData[subIndex]
                return value
            end

            if _type == "table" then
                local returnValues = {}

                for i = 1, #subIndex do
                    local key = subIndex[i]
                    if type(key) == "string" then
                        returnValues[key] = self.getMeta(index, key)
                    else
                        error(("xPlayer.getMeta subIndex should be ^5string^1 or ^5table^1! that contains ^5string^1, received ^5%s^1!, skipping..."):format(type(key)))
                    end
                end

                return returnValues
            end

            error(("xPlayer.getMeta subIndex should be ^5string^1 or ^5table^1!, received ^5%s^1!"):format(_type))
            return
        end

        return metaData
    end

    function self.setMeta(index, value, subValue)
        if not index then
            return error("xPlayer.setMeta ^5index^1 is Missing!")
        end

        if type(index) ~= "string" then
            return error("xPlayer.setMeta ^5index^1 should be ^5string^1!")
        end

        if value == nil then
            return error("xPlayer.setMeta value is missing!")
        end

        local _type = type(value)

        if not subValue then
            if _type ~= "number" and _type ~= "string" and _type ~= "table" then
                return error(("xPlayer.setMeta ^5%s^1 should be ^5number^1 or ^5string^1 or ^5table^1!"):format(value))
            end

            self.metadata[index] = value
        else
            if _type ~= "string" then
                return error(("xPlayer.setMeta ^5value^1 should be ^5string^1 as a subIndex!"):format(value))
            end

            if not self.metadata[index] or type(self.metadata[index]) ~= "table" then
                self.metadata[index] = {}
            end

            self.metadata[index] = type(self.metadata[index]) == "table" and self.metadata[index] or {}
            self.metadata[index][value] = subValue
        end
        self.triggerEvent('esx:updatePlayerData', 'metadata', self.metadata)
        Core.MarkPlayerDirty(self, "metadata")
    end

    function self.clearMeta(index, subValues)
        if not index then
            return error("xPlayer.clearMeta ^5index^1 is Missing!")
        end

        if type(index) ~= "string" then
            return error("xPlayer.clearMeta ^5index^1 should be ^5string^1!")
        end

        local metaData = self.metadata[index]
        if metaData == nil then
            if Config.EnableDebug then
                error(("xPlayer.clearMeta ^5%s^1 does not exist!"):format(index))
            end

            return
        end

        if not subValues then
            -- If no subValues is provided, we will clear the entire value in the metaData table
            self.metadata[index] = nil
        elseif type(subValues) == "string" then
            -- If subValues is a string, we will clear the specific subValue within the table
            if type(metaData) == "table" then
                metaData[subValues] = nil
            else
                return error(("xPlayer.clearMeta ^5%s^1 is not a table! Cannot clear subValue ^5%s^1."):format(index, subValues))
            end
        elseif type(subValues) == "table" then
            -- If subValues is a table, we will clear multiple subValues within the table
            for i = 1, #subValues do
                local subValue = subValues[i]
                if type(subValue) == "string" then
                    if type(metaData) == "table" then
                        metaData[subValue] = nil
                    else
                        error(("xPlayer.clearMeta ^5%s^1 is not a table! Cannot clear subValue ^5%s^1."):format(index, subValue))
                    end
                else
                    error(("xPlayer.clearMeta subValues should contain ^5string^1, received ^5%s^1, skipping..."):format(type(subValue)))
                end
            end
        else
            return error(("xPlayer.clearMeta ^5subValues^1 should be ^5string^1 or ^5table^1, received ^5%s^1!"):format(type(subValues)))
        end
        self.triggerEvent('esx:updatePlayerData', 'metadata', self.metadata)
        Core.MarkPlayerDirty(self, "metadata")
    end

    function self.executeCommand(command)
        if type(command) ~= "string" then
            error("xPlayer.executeCommand must be of type string!")
            return
        end

        self.triggerEvent("esx:executeCommand", command)
    end

    for _, funcs in pairs(Core.PlayerFunctionOverrides) do
        for fnName, fn in pairs(funcs) do
            self[fnName] = fn(self)
        end
    end

    return self
end

local function runStaticPlayerMethod(src, method, ...)
    local xPlayer = ESX.Players[src]
    if not xPlayer then
        return
    end

    if not ESX.IsFunctionReference(xPlayer[method]) then
        error(("Attempted to call invalid method on playerId %s: %s"):format(src, method))
    end

    return xPlayer[method](...)
end
exports("RunStaticPlayerMethod", runStaticPlayerMethod)
