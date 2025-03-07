local utils, config, language
local Module = {
    title = "light_bowgun",
    data = {
    }
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


    end, function(retval) end)
end

function Module.draw()
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."

    if imgui.collapsing_header(language.get(languagePrefix .. "title")) then
        imgui.indent(10)
       

        -- _SpecialAmmoHealRate = 100 (Need to save backup of original)
        -- _RapidShotBoostInfo:_ModeTime 100 (Need to save backup of original)

        -- _WeakAmmoInfo:_Ammo = _WeakAmmoInfo:_MaxAmmo
        -- _WeakAmmoInfo:_CurrentLevel = 0-3
        -- _WeakAmmoInfo:_CurrentChargeTime = 1.5



        -- <EquipShellInfo>k__BackingField[]:<Num>k__BackingField (Amount of ammo)
        -- <EquipShellInfo>k__BackingField[]:_ShellLv (Level of ammo, -1 if not alllowed (Setting to a value doesn't make it allowed....))
        

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
