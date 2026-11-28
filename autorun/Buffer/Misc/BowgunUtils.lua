local Utils = require("Buffer.Misc.Utils")

local BowgunUtils = {}

-- The shell levels are hashes (app.BowgunShellLv.SHELL_LV_Fixed), so rank them to find the highest
local SHELL_LV = Utils.generate_enum("app.BowgunShellLv.SHELL_LV_Fixed")
BowgunUtils.SHELL_LV_NONE = SHELL_LV.NONE
local shell_level_ranks = { [SHELL_LV.SL_000] = 1, [SHELL_LV.SL_001] = 2, [SHELL_LV.SL_002] = 3 }

--- Get the weapon data of every bowgun of a type
--- @param weapon_data_name string The weapon data to get ("_WeaponHeavyBowgun" or "_WeaponLightBowgun")
--- @return userdata|nil The app.user_data.WeaponData.cData array, or nil if it isn't loaded yet
function BowgunUtils.get_weapon_data(weapon_data_name)
    local various_data_manager = sdk.get_managed_singleton("app.VariousDataManager")
    if not various_data_manager then return nil end
    local weapon_data = various_data_manager:get_field("_Setting"):get_field("_EquipDatas"):get_field(weapon_data_name)
    return weapon_data and weapon_data:get_field("_Values")
end

--- Get the highest shell level and ammo capacity any bowgun has for each ammo
--- @param weapon_data userdata The app.user_data.WeaponData.cData array from BowgunUtils.get_weapon_data
--- @return table The highest shell level per ammo index (nil if no bowgun can use it)
--- @return table The highest ammo capacity per ammo index (nil if no bowgun can use it)
function BowgunUtils.get_max_ammo(weapon_data)
    local max_levels, max_capacities = {}, {}
    for e = 0, weapon_data:get_size() - 1 do
        local shell_levels = weapon_data[e]:get_field("_ShellLv")
        local shell_nums = weapon_data[e]:get_field("_ShellNum")
        for i = 0, shell_levels:get_size() - 1 do
            local shell_level = shell_levels[i]:get_field("value__")
            local rank = shell_level_ranks[shell_level]
            if rank and (not max_levels[i] or rank > shell_level_ranks[max_levels[i]]) then
                max_levels[i] = shell_level
            end
            local capacity = shell_nums:call("Get", i)
            if capacity > 0 and (not max_capacities[i] or capacity > max_capacities[i]) then
                max_capacities[i] = capacity
            end
        end
    end
    return max_levels, max_capacities
end

--- Cache and update the shell levels of every bowgun of a type, so each one can use every ammo type
--- Every NONE shell level is set to the highest level any bowgun of the same type has for that ammo.
--- The original levels are always NONE, so only the changed slots are cached. Pass false as enabled to restore them.
--- @param module table The module whose cache stores the changed slots
--- @param cache_key string The cache key to store the changed slots under
--- @param weapon_data userdata The app.user_data.WeaponData.cData array from BowgunUtils.get_weapon_data
--- @param max_levels table The highest shell level per ammo index from BowgunUtils.get_max_ammo
--- @param enabled boolean True to update the shell levels, false to restore them
function BowgunUtils.cache_and_update_shell_levels(module, cache_key, weapon_data, max_levels, enabled)
    if enabled then
        local changed_slots = module.old[cache_key] or {}
        for e = 0, weapon_data:get_size() - 1 do
            local shell_levels = weapon_data[e]:get_field("_ShellLv")
            local changed = false
            for i = 0, shell_levels:get_size() - 1 do
                if max_levels[i] and shell_levels[i]:get_field("value__") == BowgunUtils.SHELL_LV_NONE then
                    shell_levels[i] = max_levels[i]
                    changed_slots[e .. "_" .. i] = true
                    changed = true
                end
            end
            if changed then
                weapon_data[e]:call("onLoad")
            end
        end
        module.old[cache_key] = changed_slots
        module:save_cache()
    elseif module.old[cache_key] then
        -- Restore originals
        local changed_entries = {}
        for slot, _ in pairs(module.old[cache_key]) do
            local e, i = slot:match("(%d+)_(%d+)")
            weapon_data[tonumber(e)]:get_field("_ShellLv")[tonumber(i)] = BowgunUtils.SHELL_LV_NONE
            changed_entries[tonumber(e)] = true
        end
        for e, _ in pairs(changed_entries) do
            weapon_data[e]:call("onLoad")
        end
        module:clear_cache(cache_key)
    end
end

return BowgunUtils
