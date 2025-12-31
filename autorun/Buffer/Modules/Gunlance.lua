local ModuleBase = require("Buffer.Misc.ModuleBase")
local language = require("Buffer.Misc.Language")
local utils = require("Buffer.Misc.Utils")

local Module = ModuleBase:new("gunlance", {
    shell_level = -1,
    infinite_wyvern_fire = false,
    instant_charge = false,
    unlimited_ammo = false,
})

function Module.create_hooks()
    
    Module:init_stagger("gunlance_handling_update", 10)
    sdk.hook(sdk.find_type_definition("app.cHunterWp07Handling"):get_method("doUpdate"), function(args) 
        local managed = sdk.to_managed_object(args[2])
        if not Module:weapon_hook_guard(managed, "app.cHunterWp07Handling") then return end

        if not Module:should_execute_staggered("gunlance_handling_update") then return end

        local ammo = managed:get_field("_Ammo")

        -- Shell level
        Module:cache_and_update_field("_ShellLevel", managed, "_ShellLevel", Module.data.shell_level)

        -- Infinite wyvernshots
        if Module.data.infinite_wyvern_fire then 
            managed:get_field("_RyuugekiGauge"):set_field("_Value", 2)
        end

        -- Instant charge
        if Module.data.instant_charge then 
            local max_ammo = ammo:get_LimitAmmo()
            managed:set_field("_ChargeShotBulletNum", max_ammo)
            managed:set_field("_ChargeShotElapsedTimer", max_ammo * 1.1)
        end

        -- Unlimited ammo
        if Module.data.unlimited_ammo then 
            ammo:setLoadedAmmo(ammo:get_LimitAmmo())
        end

    end)
end

function Module.add_ui()
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."

    changed, Module.data.shell_level = imgui.slider_int(language.get(languagePrefix .. "shell_level"), Module.data.shell_level, -1, 6, Module.data.shell_level == -1 and language.get("base.disabled") or "%d")
    any_changed = any_changed or changed

    changed, Module.data.unlimited_ammo = imgui.checkbox(language.get(languagePrefix .. "unlimited_ammo"), Module.data.unlimited_ammo)
    any_changed = any_changed or changed

    changed, Module.data.instant_charge = imgui.checkbox(language.get(languagePrefix .. "instant_charge"), Module.data.instant_charge)
    any_changed = any_changed or changed
    
    changed, Module.data.infinite_wyvern_fire = imgui.checkbox(language.get(languagePrefix .. "infinite_wyvern_fire"), Module.data.infinite_wyvern_fire)
    any_changed = any_changed or changed

    return any_changed
end

function Module.reset()
    local player = utils.get_master_character()
    if not player then return end
    
    local weapon_handling = player:get_WeaponHandling()
    if not weapon_handling then return end

    if not Module:weapon_hook_guard(weapon_handling, "app.cHunterWp07Handling") then return end

    -- Reset shell level if needed
    Module:cache_and_update_field("_ShellLevel", weapon_handling, "_ShellLevel", -1)
end

return Module
