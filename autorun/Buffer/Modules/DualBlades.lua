local ModuleBase = require("Buffer.Misc.ModuleBase")
local language = require("Buffer.Misc.Language")

local Module = ModuleBase:new("dual_blades", {
    demon_gauge = false,
    demon_boost = false
})

function Module.create_hooks()
    
    Module:init_stagger("dual_blades_handling_update", 10)
    sdk.hook(sdk.find_type_definition("app.cHunterWp02Handling"):get_method("doUpdate"), function(args) 
        local managed = sdk.to_managed_object(args[2])
        if not Module:weapon_hook_guard(managed, "app.cHunterWp02Handling") then return end

        if not Module:should_execute_staggered("dual_blades_handling_update") then return end

        -- Demon Gauge
        if Module.data.demon_gauge then 
            managed:get_field("<KijinGauge>k__BackingField"):set_field("_Value", 1.0)  
        end
        -- Demon Boost Mode
        if Module.data.demon_boost then 
            managed:set_field("<IsMikiriBuff>k__BackingField", true)
            managed:set_field("_MikiriBuffTimer", 20.0)
        end

    end)
end

function Module.add_ui()
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."
    
    changed, Module.data.demon_gauge = imgui.checkbox(language.get(languagePrefix .. "demon_gauge"), Module.data.demon_gauge)
    any_changed = any_changed or changed
    changed, Module.data.demon_boost = imgui.checkbox(language.get(languagePrefix .. "demon_boost"), Module.data.demon_boost)
    any_changed = any_changed or changed

    return any_changed
end

function Module.reset()
    -- Implement reset functionality if needed
end

return Module
