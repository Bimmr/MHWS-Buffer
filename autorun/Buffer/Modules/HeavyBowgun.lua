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
    no_knockback = false,
    unlimited_bladescale = false,
    shell_level = -1
})

-- Local variables
local tetrad_shot_active = false

function Module.create_hooks()

    -- Watch for weapon changes to reset shell levels
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
    
    Module:init_stagger("heavy_bowgun_handling_update", 10)
    sdk.hook(sdk.find_type_definition("app.cHunterWp12Handling"):get_method("doUpdate"), function(args) 
        local managed = sdk.to_managed_object(args[2])
        if not Module:weapon_hook_guard(managed, "app.cHunterWp12Handling") then return end
        local weapon_id = managed:get_Hunter():get_WeaponID()

        if not Module:should_execute_staggered("heavy_bowgun_handling_update") then return end

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
                if managed:get_Skill218AdditionalShellNum() < managed:get_Skill218AdditionalShellMaxNum() then
                    managed:set_Skill218AdditionalShellNum(managed:get_Skill218AdditionalShellMaxNum())
                end
            end
        end

        -- Shell Level (Valid values are 0, 1, 2. Anything over 2 does 1 damage)
        local equip_shell_list = managed:get_EquipShellInfo()
        Module:cache_and_update_array_value("equip_shell_list_" .. weapon_id, equip_shell_list, "_ShellLv", Module.data.shell_level)

        if Module.data.no_reload then
            local ammo = managed:getCurrentAmmo()

            -- Check for Tetrad Shot skill (index 38)
            tetrad_shot_active = utils.has_skill(managed:get_Hunter(), 38)
            if tetrad_shot_active and ammo:get_LimitAmmo() > 3 then
                ammo:setLoadedAmmo(ammo:get_LimitAmmo()-3)
            else
                ammo:setLoadedAmmo(ammo:get_LimitAmmo())
            end
        end

    end)

    -- On shooting a shell, check if unlimited ammo is enabled, and if no reload is enabled
    local skip_ammo_usage = false
    sdk.hook(sdk.find_type_definition("app.cHunterWpGunHandling"):get_method("shootShell"), function(args) 
        local managed = sdk.to_managed_object(args[2])
        if not Module:weapon_hook_guard(managed, "app.cHunterWpGunHandling") then return end
        if managed:get_Weapon():get_WpType() ~= 12 then return end
        
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
    sdk.hook(sdk.find_type_definition("app.cHunterWp12Handling"):get_method("updateRequestRecoil(app.mcShellPlGun, System.Int32)"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not Module:weapon_hook_guard(managed, "app.cHunterWp12Handling") then return end

        if Module.data.no_recoil then
            return sdk.PreHookResult.SKIP_ORIGINAL
        end
    end, function(retval) return retval end)

    local skip_shot_knockback = false
    sdk.hook(sdk.find_type_definition("app.cHunterWp12Handling"):get_method("getShootActType"), function(args) 
        local managed = sdk.to_managed_object(args[2])
        if not Module:weapon_hook_guard(managed, "app.cHunterWp12Handling") then return end

        if Module.data.no_knockback then
            skip_shot_knockback = true
        end

    end, function(retval)
        if skip_shot_knockback then
            skip_shot_knockback = false
            
            -- Get the shell recoil type
            local value = sdk.to_int64(retval)
            
            -- 1 = BURST_RAPID_LIGHT - Doesn't shoot
            if (value >= 1 and value <= 3) then
                return sdk.to_ptr(2) -- Set to BURST_RAPID_MIDDLE
            end
            if  (value >= 4 and value <= 8) then
                return sdk.to_ptr(4)
            end
            -- 9 = RAPID_LIGHT - Doesn't shoot
            -- 10 = RAPID_MIDDLE - Doesn't shoot
            -- 11 = RAPID_HIGHT - Doesn't shoot
        end
        return retval
    end)

end

function Module.add_ui()
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."

    changed, Module.data.shell_level = imgui.slider_int(language.get(languagePrefix .. "shell_level"), Module.data.shell_level, -1, 2, Module.data.shell_level == -1 and language.get("base.disabled") or tostring(Module.data.shell_level + 1))
    any_changed = any_changed or changed

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
    if  tetrad_shot_active then
        imgui.same_line()
        utils.tooltip(language.get(languagePrefix .. "tetrad_shot_active"))
    end

    imgui.begin_table(Module.title.."3", 2, nil, nil, nil)
    imgui.table_next_row()
    imgui.table_next_column()

    changed, Module.data.no_recoil = imgui.checkbox(language.get(languagePrefix .. "no_recoil"), Module.data.no_recoil)
    any_changed = any_changed or changed

    imgui.table_next_column()

    changed, Module.data.no_knockback = imgui.checkbox(language.get(languagePrefix .. "no_knockback"), Module.data.no_knockback)
    any_changed = any_changed or changed

    imgui.end_table()

    return any_changed
end

local function reset_weapon(weapon)
    local weapon_id = weapon:get_Hunter():get_WeaponID()

    -- Restore original shell levels
    local equip_shell_list = weapon:get_EquipShellInfo()
    Module:cache_and_update_array_value("equip_shell_list_" .. weapon_id, equip_shell_list, "_ShellLv", -1)
end

function Module.reset()
    local player = utils.get_master_character()
    if not player then return end

    if player:get_WeaponType() == 13 then 
        reset_weapon(player:get_WeaponHandling())
    end
    if player:get_ReserveWeaponType() == 13 then 
        reset_weapon(player:get_ReserveWeaponHandling())
    end

end

return Module
