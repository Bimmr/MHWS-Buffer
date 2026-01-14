local ModuleBase = require("Buffer.Misc.ModuleBase")
local Language = require("Buffer.Misc.Language")
local Utils = require("Buffer.Misc.Utils")

local Module = ModuleBase:new("light_bowgun", {
    max_special_ammo = false,
    max_rapid_shot = false,
    max_eagle_shot = false,
    instant_eagle_shot_charge = false,
    unlimited_ammo = false,
    no_reload = false,
    no_recoil = false,
    no_knockback = false,
    unlimited_bladescale = false,
    all_rapid_fire = false,
    shell_level = -1,
    full_auto = false,
})

-- Local variables
local tetrad_shot_active = false
local on_trigger_lbg = false

function Module.create_hooks()

    -- Watch for weapon changes to reset ammo types
    sdk.hook(sdk.find_type_definition("app.HunterCharacter"):get_method("changeWeapon"), function(args) 
        local managed = sdk.to_managed_object(args[2])
        if not managed:get_type_definition():is_a("app.HunterCharacter") then return end
        if not managed:get_IsMaster() then return end

        Module:reset()
    end)

    -- Watch for reserve weapon changes
    sdk.hook(sdk.find_type_definition("app.HunterCharacter"):get_method("changeWeaponFromReserve"), function(args) 
        local managed = sdk.to_managed_object(args[2])
        if not managed:get_type_definition():is_a("app.HunterCharacter") then return end
        if not managed:get_IsMaster() then return end

        Module:reset()
    end)
    
    Module:init_stagger("light_bowgun_handling_update", 10)
    sdk.hook(sdk.find_type_definition("app.cHunterWp13Handling"):get_method("doUpdate"), function(args) 
        local managed = sdk.to_managed_object(args[2])
        if not Module:weapon_hook_guard(managed, "app.cHunterWp13Handling") then return end
        local weapon_id = managed:get_Hunter():get_WeaponID()

        if not Module:should_execute_staggered("light_bowgun_handling_update") then return end

        -- Update cached values
        Module:update_cached_modifications(managed)
        
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
            if Utils.has_skill(managed:get_Hunter(), 201) and managed:get_Skill218or217Timer() > 0 then -- Bladescale Loading
                if not managed:get_IsSkill218AdditionalShellMax() then
                    managed:set_Skill218AdditionalShellNum(managed:get_Skill218AdditionalShellMaxNum())
                end
            end
        end

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

        --* Can't force ammo into the bowgun, need to explore this more
        -- for i = 0, #managed:get_field("_Ammos") do
        --     local ammo_info = managed:get_field("_Ammos")[i]
        --     if ammo_info then
        --         -- ammo_info:setLimitAmmo(9) -- Doesn't work
        --         -- ammo_info:setBackupAmmo(9) -- Doesn't work
        --         -- ammo_info:setLoadedAmmo(9) -- Unlimited ammo alternative
        --     end
        -- end

        if Module.data.no_reload then
            local ammo = managed:getCurrentAmmo()
            if ammo ~= nil then

                -- Check for Tetrad Shot skill (index 38)
                tetrad_shot_active = Utils.has_skill(managed:get_Hunter(), 38)
                if tetrad_shot_active and ammo:get_LimitAmmo() > 3 then
                    ammo:setLoadedAmmo(ammo:get_LimitAmmo()-3)
                else
                    ammo:setLoadedAmmo(ammo:get_LimitAmmo())
                end
            end
        end


    end)

    -- On shooting a shell, check if unlimited ammo is enabled, and if no reload is enabled
    local skip_ammo_usage = false
    sdk.hook(sdk.find_type_definition("app.cHunterWp13Handling"):get_method("shootShell"), function(args) 
        local managed = sdk.to_managed_object(args[2])
        if not Module:weapon_hook_guard(managed, "app.cHunterWp13Handling") then return end
        
        -- If unlimited ammo is enabled, set skip ammo usage
        if Module.data.unlimited_ammo then
            skip_ammo_usage = true
        end

    end, function(retval)

        -- Reset variables after the shot
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
    sdk.hook(sdk.find_type_definition("app.cHunterWp13Handling"):get_method("updateRequestRecoil(app.mcShellPlGun, System.Int32)"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not Module:weapon_hook_guard(managed, "app.cHunterWp13Handling") then return end

        if Module.data.no_recoil then
            return sdk.PreHookResult.SKIP_ORIGINAL
        end
    end, function(retval) return retval end)

    local skip_shot_knockback = false
    sdk.hook(sdk.find_type_definition("app.cHunterWpGunHandling"):get_method("getShootActType"), function(args) 
        local managed = sdk.to_managed_object(args[2])
        if not Module:weapon_hook_guard(managed, "app.cHunterWpGunHandling") then return end
        if managed:get_Weapon():get_WpType() ~= 13 then return end

        if Module.data.no_knockback then
            skip_shot_knockback = true
        end

    end, function(retval)
        if skip_shot_knockback then
            skip_shot_knockback = false

            -- Get the shell recoil type
            local value = sdk.to_int64(retval)

            -- 1 = No shoot
            -- 2 = 3 shot burst
            -- 3 = No shoot
            -- 4 = Burst
            -- 5 = Burst Middle
            -- 6 = Burst High
            -- 7 = Middle
            -- 8 = High
            -- 9-11 = No shoot
            if (value >= 1 and value <= 3) then
                return sdk.to_ptr(1)
            end
            if  (value >= 4 and value <= 8) then
                return sdk.to_ptr(4)
            end
        end
        return retval
    end)
    
    -- Toggle trigger state each frame
    re.on_frame(function()
        on_trigger_lbg = not on_trigger_lbg
    end)

    -- Helper function for full auto logic
    local function apply_full_auto(key_id, is_controller)
        local hunter = Utils.get_master_character()
        if not hunter then return end
        if hunter:get_WeaponType() ~= 13 then return end
        if not hunter:get_IsWeaponOn() then return end
        if hunter:get_WeaponHandling():get_field("_IsRapidShotBoost") then return end -- Don't allow on rapid shot (Full auto makes it shoot slower)

        local mouse_player_input, controller_player_input = Utils.get_player_input()
        local player_input = is_controller and controller_player_input or mouse_player_input
        if not player_input then return end

        local trigger = player_input:call("getKey", key_id)
        if not trigger then return end
        
        if trigger:get_field("_On") then
            trigger:set_field("_On", on_trigger_lbg)
            trigger:set_field("_OnTrigger", on_trigger_lbg)
        end
    end

    -- Full Auto for Light Bowgun (Controller)
    sdk.hook(sdk.find_type_definition('ace.cGameInput'):get_method('applyFromPad'), nil, function(retval)
        if  Module.data.full_auto then
            apply_full_auto(2, true) -- R2 trigger
        end
        return retval
    end)
    
    -- Full Auto for Light Bowgun (Mouse/Keyboard)
    sdk.hook(sdk.find_type_definition('ace.cGameInput'):get_method('applyFromMouseKeyboard'), nil, function(retval)
        if  Module.data.full_auto then
            apply_full_auto(15, false) -- Left Mouse Button
        end
        return retval
    end)
end

function Module:update_cached_modifications(managed)
    if not managed then
        local player = Utils.get_master_character()
        if not player then return end
        managed = player:get_WeaponHandling()
    end
    
    if not managed then return end
    if not Module:weapon_hook_guard(managed, "app.cHunterWp13Handling") then return end
    local weapon_id = managed:get_Hunter():get_WeaponID()

    -- Special Ammo
    Module:cache_and_update_field("special_ammo_heal_rate_"..weapon_id, managed, "_SpecialAmmoHealRate", Module.data.max_special_ammo and 100 or -1)

    -- All Rapid Fire (0 = Normal, 1 = Rapid)
    local ammo_types = 19
    for i = 0, ammo_types - 1 do
        local ammo_info = managed:getAmmo(i)
        local equip_ammo_info = managed:get_EquipShellInfo()[i]
        Module:cache_and_update_field("ammo_type_" .. weapon_id  .. "_" .. i, ammo_info, "_AmmoType", Module.data.all_rapid_fire and 1 or -1) -- 0 = Normal, 1 = Rapid
    end

    -- Shell Level (Valid values are 0, 1, 2. Anything over 2 does 1 damage)
    local equip_shell_list = managed:get_EquipShellInfo()
    Module:cache_and_update_array_value("equip_shell_list_" .. weapon_id, equip_shell_list, "_ShellLv", Module.data.shell_level)
end

function Module.add_ui()
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."

    changed, Module.data.shell_level = imgui.slider_int(Language.get(languagePrefix .. "shell_level"), Module.data.shell_level, -1, 2, Module.data.shell_level == -1 and Language.get("base.disabled") or tostring(Module.data.shell_level + 1))
    any_changed = any_changed or changed

    changed, Module.data.max_special_ammo = imgui.checkbox(Language.get(languagePrefix .. "max_special_ammo"), Module.data.max_special_ammo)
    any_changed = any_changed or changed

    changed, Module.data.max_rapid_shot = imgui.checkbox(Language.get(languagePrefix .. "max_rapid_shot"), Module.data.max_rapid_shot)
    any_changed = any_changed or changed


    imgui.begin_table(Module.title.."1", 2, nil, nil, nil)
    imgui.table_next_row()
    imgui.table_next_column()

    changed, Module.data.max_eagle_shot = imgui.checkbox(Language.get(languagePrefix .. "max_eagle_shot"), Module.data.max_eagle_shot)
    any_changed = any_changed or changed

    imgui.table_next_column()

    changed, Module.data.instant_eagle_shot_charge = imgui.checkbox(Language.get(languagePrefix .. "instant_eagle_shot_charge"), Module.data.instant_eagle_shot_charge)
    any_changed = any_changed or changed

    imgui.end_table()
    
    imgui.begin_table(Module.title.."2", 2, nil, nil, nil)
    imgui.table_next_row()
    imgui.table_next_column()
    
    changed, Module.data.unlimited_ammo = imgui.checkbox(Language.get(languagePrefix .. "unlimited_ammo"), Module.data.unlimited_ammo)
    any_changed = any_changed or changed

    imgui.table_next_column()

    changed, Module.data.unlimited_bladescale = imgui.checkbox(Language.get(languagePrefix .. "unlimited_bladescale"), Module.data.unlimited_bladescale)
    any_changed = any_changed or changed

    imgui.end_table()
    
    changed, Module.data.no_reload = imgui.checkbox(Language.get(languagePrefix .. "no_reload"), Module.data.no_reload)
    any_changed = any_changed or changed
    if  tetrad_shot_active then
        imgui.same_line()
        Utils.tooltip(Language.get(languagePrefix .. "tetrad_shot_active"))
    end

    imgui.begin_table(Module.title.."3", 2, nil, nil, nil)
    imgui.table_next_row()
    imgui.table_next_column()

    changed, Module.data.no_recoil = imgui.checkbox(Language.get(languagePrefix .. "no_recoil"), Module.data.no_recoil)
    any_changed = any_changed or changed

    imgui.table_next_column()

    changed, Module.data.no_knockback = imgui.checkbox(Language.get(languagePrefix .. "no_knockback"), Module.data.no_knockback)
    any_changed = any_changed or changed

    imgui.end_table()

    changed, Module.data.all_rapid_fire = imgui.checkbox(Language.get(languagePrefix .. "all_rapid_fire"), Module.data.all_rapid_fire)
    any_changed = any_changed or changed

    changed, Module.data.full_auto = imgui.checkbox(Language.get(languagePrefix .. "full_auto"), Module.data.full_auto)
    any_changed = any_changed or changed

    if any_changed then
        Module:update_cached_modifications()
    end

    return any_changed
end

local function reset_weapon(weapon)
    local weapon_id = weapon:get_Hunter():get_WeaponID()

    -- Restore original ammo types
    local ammo_types = 19
        for i = 0, ammo_types - 1 do
            local ammo_info = weapon:getAmmo(i)
            Module:cache_and_update_field("ammo_type_" .. weapon_id .. "_" .. i, ammo_info, "_AmmoType", -1)
        end

    -- Restore original shell levels
    local equip_shell_list = weapon:get_EquipShellInfo()
    Module:cache_and_update_array_value("equip_shell_list_" .. weapon_id, equip_shell_list, "_ShellLv", -1)
end

function Module.reset()
    local player = Utils.get_master_character()
    if not player then return end

    if player:get_WeaponType() == 13 then 
        reset_weapon(player:get_WeaponHandling())
    end
    if player:get_ReserveWeaponType() == 13 then 
        reset_weapon(player:get_ReserveWeaponHandling())
    end

end

return Module
