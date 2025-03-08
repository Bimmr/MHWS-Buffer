local utils, config, language
local Module = {
    title = "light_bowgun",
    data = {
        max_special_ammo = false,
        max_rapid_shot = false,
        max_eagle_shot = false,
        max_eagle_shot_charge = false,
        -- all_ammo = false
    },
    old = {}
}

function Module.init()
    utils = require("Buffer.Misc.Utils")
    config = require("Buffer.Misc.Config")
    language = require("Buffer.Misc.Language")

    Module.init_hooks()
end

function Module.init_hooks()
    
    -- Weapon changes
    sdk.hook(sdk.find_type_definition("app.cHunterWp13Handling"):get_method("update"), function(args) 
        local managed = sdk.to_managed_object(args[2])
        if not managed:get_type_definition():is_a("app.cHunterWp13Handling") then return end
        if not managed:get_Hunter() then return end
        if not managed:get_Hunter():get_IsMaster() then return end

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
       

        -- Weak Ammo (Also known in game as Eagle Shot)
        if Module.data.max_eagle_shot then
            local weak_ammo_info = managed:get_field("_WeakAmmoInfo")
            if weak_ammo_info then
                weak_ammo_info:set_field("_Ammo", weak_ammo_info:get_field("_MaxAmmo"))
            end
        end

        if Module.data.max_eagle_shot_charge then
            local weak_ammo_info = managed:get_field("_WeakAmmoInfo")
            if weak_ammo_info then
                if weak_ammo_info:get_field("_CurrentChargeTime") > 0 then
                    weak_ammo_info:set_field("_CurrentLevel", 3)
                    weak_ammo_info:set_field("_CurrentChargeTime", 1.5)
                end
            end
        end


        
        -- if Module.data.all_ammo then
        --     local ammos = managed:get_field("_Ammos")
        --     for i = 1, #ammos do
        --         local ammo = ammos[i]
        --         if ammo then
        --             local limitAmmo = ammo:get_field("_LimitAmmo")
        --             limitAmmo:set_field("v", 20*limitAmmo:get_field("m"))
        --             local loadedAmmo = ammo:get_field("_LoadedAmmo")
        --             loadedAmmo:set_field("v", 10*loadedAmmo:get_field("m"))
        --             local backupAmmo = ammo:get_field("_BackupAmmo")
        --             backupAmmo:set_field("v", 20*backupAmmo:get_field("m"))
        --         end
        --     end
        -- end

        -- Maybe convert this into setting max ammo and level for all currently equipable ammo types 
        -- if Module.data.all_ammo and not Module.old.ammo then
        --     Module.old.ammo = {}
        --     for i = 1, #managed:get_field("<EquipShellInfo>k__BackingField") do
        --         local ammo_info = managed:get_field("<EquipShellInfo>k__BackingField")[i]
        --         if ammo_info then
        --             Module.old.ammo[i] = {
        --                 num = ammo_info:get_field("<Num>k__BackingField"),
        --                 level = ammo_info:get_field("_ShellLv")
        --             }
        --             ammo_info:set_field("<Num>k__BackingField", 10)
        --             ammo_info:set_field("_ShellLv", 10)
        --         end
        --     end
        -- elseif not Module.data.all_ammo and Module.old.ammo then
        --     for i = 1, #managed:get_field("<EquipShellInfo>k__BackingField") do
        --         local ammo_info = managed:get_field("<EquipShellInfo>k__BackingField")[i]
        --         if ammo_info then
        --             ammo_info:set_field("<Num>k__BackingField", Module.old.ammo[i].num)
        --             ammo_info:set_field("_ShellLv", Module.old.ammo[i].level)
        --         end
        --     end
        --     Module.old.ammo = nil
        -- end

    end, function(retval) end)
end

function Module.draw()
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."

    if imgui.collapsing_header(language.get(languagePrefix .. "title")) then
        imgui.indent(10)

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

        changed, Module.data.max_eagle_shot_charge = imgui.checkbox(language.get(languagePrefix .. "max_eagle_shot_charge"), Module.data.max_eagle_shot_charge)
        any_changed = any_changed or changed

        imgui.end_table()
        
        -- changed, Module.data.all_ammo = imgui.checkbox(language.get(languagePrefix .. "all_ammo"), Module.data.all_ammo)
        -- any_changed = any_changed or changed

        if any_changed then config.save_section(Module.create_config_section()) end
        imgui.unindent(10)
        imgui.separator()
        imgui.spacing()
    end
end

function Module.reset()
    -- Implement reset functionality if needed
end

function Module.create_config_section()
    return {
        [Module.title] = Module.data
    }
end

function Module.load_from_config(config_section)
    if not config_section then return end
    utils.mergeTables(Module.data, config_section)
end

return Module
