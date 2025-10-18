local ModuleBase = require("Buffer.Misc.ModuleBase")
local language = require("Buffer.Misc.Language")
local utils = require("Buffer.Misc.Utils")

local Module = ModuleBase:new("light_bowgun", {
    max_special_ammo = false,
    max_rapid_shot = false,
    max_eagle_shot = false,
    instant_eagle_shot_charge = false,
    unlimited_ammo = false,
    no_reload = false,
    no_recoil = false,
    unlimited_bladescale = false,
    all_rapid_fire = false,
    shell_level = -1
})

function Module.create_hooks()

    -- Watch for weapon changes to reset ammo types
    sdk.hook(sdk.find_type_definition("app.HunterCharacter"):get_method("changeWeapon"), function(args) 
        local managed = sdk.to_managed_object(args[2])
        if not managed:get_type_definition():is_a("app.HunterCharacter") then return end
        if not managed:get_IsMaster() then return end

        Module:reset()
    end, function(retval) end)
    
    sdk.hook(sdk.find_type_definition("app.cHunterWp13Handling"):get_method("update"), function(args) 
        local managed = sdk.to_managed_object(args[2])
        if not Module:weapon_hook_guard(managed, "app.cHunterWp13Handling") then return end

        -- Special Ammo
        if Module.data.max_special_ammo and Module.old.special_ammo_heal_rate == nil then
            Module.old.special_ammo_heal_rate = managed:get_field("_SpecialAmmoHealRate")
            managed:set_field("_SpecialAmmoHealRate", 100)
        elseif not Module.data.max_special_ammo and Module.old.special_ammo_heal_rate ~= nil then
            managed:set_field("_SpecialAmmoHealRate", Module.old.special_ammo_heal_rate)
            Module.old.special_ammo_heal_rate = nil
        end
        
        -- Rapid Shot
        if Module.data.max_rapid_shot then
            managed:get_field("_RapidShotBoostInfo"):set_field("_ModeTime", 100)
        end
       
        -- Unlimited Eagle Shots
        if Module.data.max_eagle_shot then
            local weak_ammo_info = managed:get_field("_WeakAmmoInfo")
            if weak_ammo_info then
                weak_ammo_info:set_field("_Ammo", weak_ammo_info:get_field("_MaxAmmo"))
            end
        end

        -- Instant Eagle Shot Charge
        if Module.data.instant_eagle_shot_charge then
            local weak_ammo_info = managed:get_field("_WeakAmmoInfo")
            if weak_ammo_info then
                if weak_ammo_info:get_field("_CurrentChargeTime") > 0 then
                    weak_ammo_info:set_field("_CurrentLevel", 3)
                    weak_ammo_info:set_field("_CurrentChargeTime", 1.5)
                end
            end
        end

        -- Bladescale Loading
        if Module.data.unlimited_bladescale then
            if utils.has_skill(managed:get_Hunter(), 201) then -- Bladescale Loading
                managed:set_field("<Skill218AdditionalShellNum>k__BackingField", managed:get_field("<Skill218AdditionalShellMaxNum>k__BackingField"))
            end
        end

        -- All Rapid Fire (0 = Normal, 1 = Rapid)
        local ammos = managed:get_field("_Ammos")
        Module:cache_and_update_array_toggle("ammos", ammos, "_AmmoType", Module.data.all_rapid_fire)


        --* _Ammos
        -- 0  = Normal
        -- 1  = Pierce
        -- 2  = Spread
        -- 3  = Sticky
        -- 4  = Cluster
        -- 5  = Slicing
        -- 6  = Wyvern
        -- 7  = Flaming
        -- 8  = Water
        -- 9  = Thunder
        -- 10 = Ice
        -- 11 = Dragon
        -- 12 = Poison
        -- 13 = Paralysis
        -- 14 = Sleep
        -- 15 = Demon
        -- 16 = Armor
        -- 17 = Recovery
        -- 18 = Exhaust
        -- 19 = Tranq

        -- Shell Level (Valid values are 0, 1, 2. Anything over 2 does 1 damage)
        local equip_shell_info = managed:get_field("<EquipShellInfo>k__BackingField")
        Module:cache_and_update_array_value("equip_shell_info", equip_shell_info, "_ShellLv", Module.data.shell_level)

        --* Can't force ammo into the bowgun, need to explore this more
        -- for i = 0, #managed:get_field("_Ammos") do
        --     local ammo_info = managed:get_field("_Ammos")[i]
        --     if ammo_info then
        --         -- ammo_info:setLimitAmmo(9) -- Doesn't work
        --         -- ammo_info:setBackupAmmo(9) -- Doesn't work
        --         -- ammo_info:setLoadedAmmo(9) -- Unlimited ammo alternative
        --     end
        -- end


    end, function(retval) end)

    -- On shooting a shell, check if unlimited ammo is enabled, and if no reload is enabled
    local skip_ammo_usage = false
    local no_reload_managed_weapon = nil
    sdk.hook(sdk.find_type_definition("app.cHunterWpGunHandling"):get_method("shootShell"), function(args) 
        local managed = sdk.to_managed_object(args[2])
        if not Module:weapon_hook_guard(managed, "app.cHunterWpGunHandling") then return end
        if managed:get_Weapon():get_WpType() ~= 13 then return end
        
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
        if managed:get_Weapon():get_WpType() ~= 13 then return end

        if Module.data.no_recoil then
            return sdk.PreHookResult.SKIP_ORIGINAL
        end
    end, function(retval) return retval end)

    local skip_shot_knockback = false
    sdk.hook(sdk.find_type_definition("app.cHunterWpGunHandling"):get_method("getShootActType"), function(args) 
        local managed = sdk.to_managed_object(args[2])
        if not Module:weapon_hook_guard(managed, "app.cHunterWpGunHandling") then return end
        if managed:get_Weapon():get_WpType() ~= 13 then return end

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

    changed, Module.data.shell_level = imgui.slider_int(language.get(languagePrefix .. "shell_level"), Module.data.shell_level, -1, 2, Module.data.shell_level == -1 and language.get("base.disabled") or tostring(Module.data.shell_level + 1))
    any_changed = any_changed or changed

    changed, Module.data.max_special_ammo = imgui.checkbox(language.get(languagePrefix .. "max_special_ammo"), Module.data.max_special_ammo)
    any_changed = any_changed or changed

    changed, Module.data.max_rapid_shot = imgui.checkbox(language.get(languagePrefix .. "max_rapid_shot"), Module.data.max_rapid_shot)
    any_changed = any_changed or changed


    imgui.begin_table(Module.title.."1", 2, nil, nil, nil)
    imgui.table_next_row()
    imgui.table_next_column()

    changed, Module.data.max_eagle_shot = imgui.checkbox(language.get(languagePrefix .. "max_eagle_shot"), Module.data.max_eagle_shot)
    any_changed = any_changed or changed

    imgui.table_next_column()

    changed, Module.data.instant_eagle_shot_charge = imgui.checkbox(language.get(languagePrefix .. "instant_eagle_shot_charge"), Module.data.instant_eagle_shot_charge)
    any_changed = any_changed or changed

    imgui.end_table()
    
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

    changed, Module.data.all_rapid_fire = imgui.checkbox(language.get(languagePrefix .. "all_rapid_fire"), Module.data.all_rapid_fire)
    any_changed = any_changed or changed

    return any_changed
end

function Module.reset()
    local player = utils.get_master_character()
    if not player then return end
    
    local weapon_handling = player:get_WeaponHandling()
    if not weapon_handling then return end
    if not Module:weapon_hook_guard(weapon_handling, "app.cHunterWp13Handling") then return end

    -- Restore original ammo types
    local ammos = weapon_handling:get_field("_Ammos")
    Module:cache_and_update_array_toggle("ammos", ammos, "_AmmoType", false)
    
    -- Restore original shell levels
    local equip_shell_info = weapon_handling:get_field("<EquipShellInfo>k__BackingField")
    Module:cache_and_update_array_value("equip_shell_info", equip_shell_info, "_ShellLv", -1)
end

return Module
