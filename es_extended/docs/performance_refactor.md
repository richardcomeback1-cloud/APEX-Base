# ESX 1.13.4 High-Concurrency Refactor Notes

## New core data structures

### Player cache
```lua
PlayerCache[source] = {
  identifier = xPlayer.identifier,
  money = xPlayer.getMoney(),
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
```

### Inventory
```lua
xPlayer.inventory[itemName] = {
  name = itemName,
  count = number,
  label = string,
  limit = number,
  metadata = table,
  weight = number, -- compatibility only
  usable = boolean,
  rare = boolean,
  canRemove = boolean,
}
```

`xPlayer.inventoryList` remains as an array compatibility layer for UI payloads and legacy resources that still expect iterable inventory data.

## Optimization summary

### CPU improvements
- Replaced linear `getInventoryItem` scans with direct hashmap lookups.
- Replaced linear account lookup with `accountsByName`.
- Removed hot-path inventory table rebuilds during normal gameplay.
- Added login queue batching to spread player load work over time.
- Added server-side event throttles for spam-prone inventory and pickup flows.
- Added optional hot-path profiling counters and slow-path warnings.

### Database reduction
- Removed synchronous gameplay persistence paths.
- Added dirty-flag-driven save queue.
- Autosave now flushes only dirty players.
- Logout save uses a single async transaction-style flush per player.
- Login now performs a single async load and immediately hydrates cache.

### Network reduction
- Inventory mutations are queued and sent as batched deltas.
- Full inventory payloads are only sent on login or item-definition refresh.
- Account sync payloads remain targeted per player.
- No new global broadcasts were introduced for hot inventory paths.

## Breaking changes
- Carry validation is now limit-based only. `weight` is ignored for carry checks.
- Item limits now default to `Config.DefaultItemLimit` when no item limit exists.
- Core inventory sync now uses `esx:updateInventory` batched delta payloads. Legacy add/remove events are retained for compatibility consumers but are no longer used by the default server inventory mutation path.
- Position persistence is no longer saved every autosave unless the player is already dirty; final logout save still persists the latest position.

## Migration guide
1. Add an item `limit` column to your items source if you want per-item caps. If omitted, the fallback limit is `Config.DefaultItemLimit`.
2. Audit custom resources for direct `xPlayer.inventory` array mutation. Replace with controlled APIs:
   - `xPlayer.addInventoryItem`
   - `xPlayer.removeInventoryItem`
   - `xPlayer.setInventoryItem`
   - `xPlayer.addAccountMoney`
   - `xPlayer.removeAccountMoney`
3. Remove weight-based carry checks from custom resources and replace them with `xPlayer.canCarryItem`.
4. If a client resource listens for inventory mutations, prefer the new batched delta event `esx:updateInventory`.
5. Keep DB writes out of gameplay events; queue state to the player cache instead.

## Resource audit checklist
- [ ] No `MySQL.*await` or synchronous DB access in gameplay hot paths.
- [ ] No `while true do Wait(0)` loops on the server.
- [ ] No inventory or money mutation from client-trusted payloads.
- [ ] No direct table mutation of `xPlayer.inventory`, `xPlayer.accounts`, or `xPlayer.job`.
- [ ] No full inventory sync on every item change.
- [ ] No global broadcasts for player-local state changes.
- [ ] No callback chains for inventory, money, or job mutations.
- [ ] Commands validate permissions and inputs before doing work.
- [ ] Entity-producing resources cap spawned vehicles/peds/objects.
- [ ] OneSync state bags are preferred for frequently changing entity state.
