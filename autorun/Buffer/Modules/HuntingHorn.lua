local ModuleBase = require("Buffer.Misc.ModuleBase")
local language = require("Buffer.Misc.Language")

local Module = ModuleBase:new("hunting_horn", {
   unlimited_echo_bubbles = false,
})

function Module.create_hooks()
    
    Module:init_stagger("hunting_horn_handling_update", 10)
    sdk.hook(sdk.find_type_definition("app.cHunterWp05Handling"):get_method("doUpdate"), function(args) 
        local managed = sdk.to_managed_object(args[2])
        if not Module:weapon_hook_guard(managed, "app.cHunterWp05Handling") then return end

        if not Module:should_execute_staggered("hunting_horn_handling_update") then return end

        -- Unlimited Echo Bubbles
        if Module.data.unlimited_echo_bubbles then
            local echo_bubbles = managed:get_field("_HibikiFloatShellInfo")
            if echo_bubbles:get_Ammo() < echo_bubbles:get_MaxAmmo() then
                echo_bubbles:reloadAmmo()
            end
        end

    end)
end

function Module.add_ui()
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."
   
    changed, Module.data.unlimited_echo_bubbles = imgui.checkbox(language.get(languagePrefix .. "unlimited_echo_bubbles"), Module.data.unlimited_echo_bubbles)
    any_changed = any_changed or changed

    return any_changed
end

return Module
