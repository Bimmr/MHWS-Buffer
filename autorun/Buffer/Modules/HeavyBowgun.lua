local ModuleBase = require("Buffer.Misc.ModuleBase")
local language = require("Buffer.Misc.Language")
local utils = require("Buffer.Misc.Utils")

local Module = ModuleBase:new("heavy_bowgun", {
    max_special_ammo = false,
    max_wyvern_howl = false,
    max_gatling_hits = false,
    unlimited_ammo = false,
    no_reload = false,
    no_recoil = false,
    unlimited_bladescale = false,
    shell_level = -1
})

function Module.create_hooks()

    -- Watch for weapon changes to reset shell levels
    sdk.hook(sdk.find_type_definition("app.HunterCharacter"):get_method("changeWeapon"), function(args) 
        local managed = sdk.to_managed_object(args[2])
        if not managed:get_type_definition():is_a("app.HunterCharacter") then return end
        if not managed:get_IsMaster() then return end

        Module:reset()
    end, function(retval) end)
    
    sdk.hook(sdk.find_type_definition("app.cHunterWp12Handling"):get_method("update"), function(args) 
        local managed = sdk.to_managed_object(args[2])
        if not Module:weapon_hook_guard(managed, "app.cHunterWp12Handling") then return end

        -- Energy Bullet Info
        local energy_bullet_info = managed:get_field("_EnergyBulletInfo")

        -- Max Special Mode (Special ammo)
        if Module.data.max_special_ammo then
            energy_bullet_info:set_field("_CurrentEnergy", energy_bullet_info:get_field("MAX_ENERGY"))
        end


        -- TODO: Not Working
        --* Wyverncounter Ignition - yes, charge level is spelled wrong
        --* Wyvernblast Ignition - Has no charge level
        -- if Module.data.wyvern_ignition_charge_level > -1 then
        --     energy_bullet_info:set_field("_CharageLevel", Module.data.wyvern_ignition_charge_level)
        -- end


        --? Unsure what these are
        --? _EnergyBulletInfo:_StandardEnergyShellType
        --? _EnergyBulletInfo:WeakEnergyShellType
        --? _EnergyBulletInfo:PowerEnergyShellType

        -- Snipe Ammo (FocusBlast: WyvernHowl)
        if Module.data.max_wyvern_howl then
            local snipe_ammo = managed:get_field("_SnipeAmmo")
            snipe_ammo:set_field("_ChargeTimer", snipe_ammo:get_field("_ChargeTime")) 
            -- snipe_ammo:set_field("_CurrentAmmo", snipe_ammo:get_field("_MaxAmmo")) -- DOESN'T WORK
        end

        -- Gatling Hit - Only affects Wyvernheart Ignition
        if Module.data.max_gatling_hits then
            managed:set_field("_GatlingHitCount", 9) 
        end

        -- Bladescale Loading
        if Module.data.unlimited_bladescale then
            if utils.has_skill(managed:get_Hunter(), 201) then -- Bladescale Loading
                managed:set_field("<Skill218AdditionalShellNum>k__BackingField", managed:get_field("<Skill218AdditionalShellMaxNum>k__BackingField"))
            end
        end

        -- Shell Level (Valid values are 0, 1, 2. Anything over 2 does 1 damage)
        local equip_shell_info = managed:get_field("<EquipShellInfo>k__BackingField")
        Module:cache_and_update_array_value("equip_shell_info", equip_shell_info, "_ShellLv", Module.data.shell_level)

    end, function(retval) end)

    -- On shooting a shell, check if unlimited ammo is enabled, and if no reload is enabled
    local skip_ammo_usage = false
    local no_reload_managed_weapon = nil
    sdk.hook(sdk.find_type_definition("app.cHunterWpGunHandling"):get_method("shootShell"), function(args) 
        local managed = sdk.to_managed_object(args[2])
        if not Module:weapon_hook_guard(managed, "app.cHunterWpGunHandling") then return end
        if managed:get_Weapon():get_WpType() ~= 12 then return end
        
        -- If unlimited ammo is enabled, set skip ammo usage
        if Module.data.unlimited_ammo then
            skip_ammo_usage = true
        end

        -- If no reload is enabled, pass the weapon to the no_reload_managed_weapon variable
        if Module.data.no_reload then
            no_reload_managed_weapon = managed
        end
    end, function(retval)

        -- If no reload is enabled, reload the weapon without an animation
        if no_reload_managed_weapon and Module.data.no_reload then
            no_reload_managed_weapon:allReloadAmmo()
        end

        -- Reset variables after the shot
        no_reload_managed_weapon = nil
        skip_ammo_usage = false

        return retval
    end)

    -- On changing the item pouch number, check if unlimited ammo is enabled, and if skip ammo usage is enabled
    sdk.hook(sdk.find_type_definition("app.savedata.cItemParam"):get_method("changeItemPouchNum(app.ItemDef.ID, System.Int16, app.savedata.cItemParam.POUCH_CHANGE_TYPE)"), function(args)
        if skip_ammo_usage then
            return sdk.PreHookResult.SKIP_ORIGINAL
        end
    end, function(retval) return retval end)

    -- On updating the request recoil, check if no recoil is enabled
    sdk.hook(sdk.find_type_definition("app.cHunterWpGunHandling"):get_method("updateRequestRecoil(app.mcShellPlGun, System.Int32)"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not Module:weapon_hook_guard(managed, "app.cHunterWpGunHandling") then return end
        if managed:get_Weapon():get_WpType() ~= 12 then return end

        if Module.data.no_recoil then
            return sdk.PreHookResult.SKIP_ORIGINAL
        end
    end, function(retval) return retval end)

    local skip_shot_knockback = false
    sdk.hook(sdk.find_type_definition("app.cHunterWpGunHandling"):get_method("getShootActType"), function(args) 
        local managed = sdk.to_managed_object(args[2])
        if not Module:weapon_hook_guard(managed, "app.cHunterWpGunHandling") then return end
        if managed:get_Weapon():get_WpType() ~= 12 then return end

        if Module.data.no_recoil then
            skip_shot_knockback = true
        end

    end, function(retval)
        if skip_shot_knockback then
            skip_shot_knockback = false
            return sdk.to_ptr(1)
        else
            return retval
        end
    end)

end

function Module.add_ui()
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."

    changed, Module.data.max_special_ammo = imgui.checkbox(language.get(languagePrefix .. "max_special_ammo"), Module.data.max_special_ammo)
    any_changed = any_changed or changed

    changed, Module.data.max_wyvern_howl = imgui.checkbox(language.get(languagePrefix .. "max_wyvern_howl"), Module.data.max_wyvern_howl)
    any_changed = any_changed or changed

    -- changed, Module.data.wyvern_ignition_charge_level = imgui.slider_int(language.get(languagePrefix .. "wyvern_ignition_charge_level"), Module.data.wyvern_ignition_charge_level, -1, 3, Module.data.wyvern_ignition_charge_level == -1 and language.get("base.disabled") or "%d")
    -- any_changed = any_changed or changed

    changed, Module.data.max_gatling_hits = imgui.checkbox(language.get(languagePrefix .. "max_gatling_hits"), Module.data.max_gatling_hits)
    utils.tooltip(language.get(languagePrefix .. "max_gatling_hits_tooltip"))
    any_changed = any_changed or changed

    imgui.begin_table(Module.title.."2", 2, nil, nil, nil)
    imgui.table_next_row()
    imgui.table_next_column()

    changed, Module.data.unlimited_ammo = imgui.checkbox(language.get(languagePrefix .. "unlimited_ammo"), Module.data.unlimited_ammo)
    any_changed = any_changed or changed

    imgui.table_next_column()

    changed, Module.data.unlimited_bladescale = imgui.checkbox(language.get(languagePrefix .. "unlimited_bladescale"), Module.data.unlimited_bladescale)
    any_changed = any_changed or changed

    imgui.end_table()

    changed, Module.data.no_reload = imgui.checkbox(language.get(languagePrefix .. "no_reload"), Module.data.no_reload)
    any_changed = any_changed or changed

    changed, Module.data.no_recoil = imgui.checkbox(language.get(languagePrefix .. "no_recoil"), Module.data.no_recoil)
    any_changed = any_changed or changed

    changed, Module.data.shell_level = imgui.slider_int(language.get(languagePrefix .. "shell_level"), Module.data.shell_level, -1, 2, Module.data.shell_level == -1 and language.get("base.disabled") or tostring(Module.data.shell_level + 1))
    any_changed = any_changed or changed

    return any_changed
end

function Module.reset()
    local player = utils.get_master_character()
    if not player then return end
    
    local weapon_handling = player:get_WeaponHandling()
    if not weapon_handling then return end
    if not Module:weapon_hook_guard(weapon_handling, "app.cHunterWp12Handling") then return end

    -- Restore original shell levels
    local equip_shell_info = weapon_handling:get_field("<EquipShellInfo>k__BackingField")
    Module:cache_and_update_array_value("equip_shell_info", equip_shell_info, "_ShellLv", -1)
end

return Module
