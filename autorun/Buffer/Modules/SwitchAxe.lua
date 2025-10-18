local ModuleBase = require("Buffer.Misc.ModuleBase")
local language = require("Buffer.Misc.Language")

local Module = ModuleBase:new("switch_axe", {
    max_charge = false,
    max_sword_charge = false,
    powered_axe = false,
})

function Module.create_hooks()
    
    sdk.hook(sdk.find_type_definition("app.cHunterWp08Handling"):get_method("update"), function(args) 
        local managed = sdk.to_managed_object(args[2])
        if not Module:weapon_hook_guard(managed, "app.cHunterWp08Handling") then return end

        -- Max charge
        if Module.data.max_charge then 
            managed:get_field("_SlashGauge"):set_field("_Value", 100) 
        end

        -- Sword charge
        if Module.data.max_sword_charge then 
            managed:get_field("_SwordAwakeGauge"):set_field("_Value", 100) 
        end

        -- Powered axe
        if Module.data.powered_axe then 
            managed:set_field("_AxeEnhancedTimer", 45) 
        end

    end, function(retval) end)
end

function Module.add_ui()
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."
   
    changed, Module.data.max_charge = imgui.checkbox(language.get(languagePrefix .. "max_charge"), Module.data.max_charge)
    any_changed = any_changed or changed

    changed, Module.data.max_sword_charge = imgui.checkbox(language.get(languagePrefix .. "max_sword_charge"), Module.data.max_sword_charge)
    any_changed = any_changed or changed

    changed, Module.data.powered_axe = imgui.checkbox(language.get(languagePrefix .. "powered_axe"), Module.data.powered_axe)
    any_changed = any_changed or changed

    return any_changed
end

return Module
