local ModuleBase = require("Buffer.Misc.ModuleBase")
local language = require("Buffer.Misc.Language")
local utils = require("Buffer.Misc.Utils")

local Module = ModuleBase:new("great_sword", {
    true_charge_boost = false,
    charge_level = -1,
    instant_charge = false
})

function Module.create_hooks()
    
    sdk.hook(sdk.find_type_definition("app.cHunterWp00Handling"):get_method("update"), function(args) 
        local managed = sdk.to_managed_object(args[2])
        if not Module:weapon_hook_guard(managed, "app.cHunterWp00Handling") then return end

        -- True charge boost
        if Module.data.true_charge_boost then 
            managed:set_field("_IsSpiritSlashEnhanced", true) 
        end

         -- Instant charge
        if Module.data.instant_charge then 
            managed:set_field("_ChargeTimer", 3)
            managed:set_field("_ChargeLevel", 3)
        end
        
        -- Charge level
        if Module.data.charge_level >= 0 and managed:get_field("_ChargeTimer") > 0 then
            managed:set_field("_ChargeLevel", Module.data.charge_level)
        end

    end, function(retval) end)
end

function Module.add_ui()
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."
       
    changed, Module.data.true_charge_boost = imgui.checkbox(language.get(languagePrefix .. "true_charge_boost"), Module.data.true_charge_boost)
    utils.tooltip(language.get(languagePrefix .. "true_charge_boost_tooltip"))
    any_changed = any_changed or changed

    changed, Module.data.charge_level = imgui.slider_int(language.get(languagePrefix .. "charge_level"), Module.data.charge_level, -1, 3, Module.data.charge_level == -1 and language.get("base.disabled") or "%d")
    any_changed = any_changed or changed    
    
    changed, Module.data.instant_charge = imgui.checkbox(language.get(languagePrefix .. "instant_charge"), Module.data.instant_charge)
    any_changed = any_changed or changed

    return any_changed
end

return Module
