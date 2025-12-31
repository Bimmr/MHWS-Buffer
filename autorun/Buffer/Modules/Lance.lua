local ModuleBase = require("Buffer.Misc.ModuleBase")
local language = require("Buffer.Misc.Language")

local Module = ModuleBase:new("lance", {
    counter_charge_level = -1,
    rush_level = -1,
})

function Module.create_hooks()
    
    Module:init_stagger("lance_handling_update", 10)
    sdk.hook(sdk.find_type_definition("app.cHunterWp06Handling"):get_method("doUpdate"), function(args) 
        local managed = sdk.to_managed_object(args[2])
        if not Module:weapon_hook_guard(managed, "app.cHunterWp06Handling") then return end

        if not Module:should_execute_staggered("lance_handling_update") then return end

        -- Counter charge level
        if Module.data.counter_charge_level ~= -1 then 
            managed:set_field("_FinishChargeLevel", Module.data.counter_charge_level) 
        end

        -- Rush level
        if Module.data.rush_level ~= -1 then 
            managed:set_field("_RushLevel", Module.data.rush_level) 
            managed:set_field("_RushLevelTimer", 1.4)
        end

    end)
end

function Module.add_ui()
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."
       
    changed, Module.data.counter_charge_level = imgui.slider_int(language.get(languagePrefix .. "counter_charge_level"), Module.data.counter_charge_level, -1, 3, Module.data.counter_charge_level == -1 and language.get("base.disabled") or "%d")
    any_changed = any_changed or changed     

    changed, Module.data.rush_level = imgui.slider_int(language.get(languagePrefix .. "rush_level"), Module.data.rush_level, -1, 1, Module.data.rush_level == -1 and language.get("base.disabled") or "%d")
    any_changed = any_changed or changed

    return any_changed
end

return Module
