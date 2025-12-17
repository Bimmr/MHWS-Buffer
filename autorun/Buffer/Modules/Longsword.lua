local ModuleBase = require("Buffer.Misc.ModuleBase")
local language = require("Buffer.Misc.Language")
local utils = require("Buffer.Misc.Utils")

local Module = ModuleBase:new("long_sword", {
    aura_level = -1,
    max_aura_gauge = false,
    max_spirit_gauge = false,
})

function Module.create_hooks()
    
    sdk.hook(sdk.find_type_definition("app.cHunterWp03Handling"):get_method("update"), function(args) 
        local managed = sdk.to_managed_object(args[2])
        if not Module:weapon_hook_guard(managed, "app.cHunterWp03Handling") then return end

        -- Aura level
        if Module.data.aura_level ~= -1 then
            managed:set_field("<AuraLevel>k__BackingField", Module.data.aura_level+1)
        end

        -- Max aura gauge
        if Module.data.max_aura_gauge then 
            managed:get_field("<AuraGauge>k__BackingField"):set_field("_Value", 195) 
        end

        -- Max spirit gauge
        if Module.data.max_spirit_gauge then 
            managed:get_field("<RenkiGauge>k__BackingField"):set_field("_Value", 100)
        end

        --? <KabutowariAuraLevel>k__BackingField -- The dropping from the sky attack, not sure what it does besides that it's associated with that
        --? _KijinChargeLv -- Not sure

    end, function(retval) end)
end

function Module.add_ui()
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."
       
    changed, Module.data.aura_level = imgui.slider_int(language.get(languagePrefix .. "aura_level"), Module.data.aura_level, -1, 3, Module.data.aura_level == -1 and language.get("base.disabled") or "%d")   
    utils.tooltip(language.get(languagePrefix .. "aura_level_tooltip"))
    any_changed = any_changed or changed

    changed, Module.data.max_aura_gauge = imgui.checkbox(language.get(languagePrefix .. "max_aura_gauge"), Module.data.max_aura_gauge)
    any_changed = any_changed or changed

    changed, Module.data.max_spirit_gauge = imgui.checkbox(language.get(languagePrefix .. "max_spirit_gauge"), Module.data.max_spirit_gauge)
    any_changed = any_changed or changed

    return any_changed
end

return Module
