local ModuleBase = require("Buffer.Misc.ModuleBase")
local language = require("Buffer.Misc.Language")

local Module = ModuleBase:new("hunting_horn", {
   unlimited_echo_bubbles = false,
})

function Module.createHooks()
    
    -- Weapon changes
    sdk.hook(sdk.find_type_definition("app.cHunterWp05Handling"):get_method("update"), function(args) 
        local managed = sdk.to_managed_object(args[2])
        if not Module:weaponHookGuard(managed, "app.cHunterWp05Handling") then return end

        if Module.data.unlimited_echo_bubbles then
            local echo_bubbles = managed:get_field("_HibikiFloatShellInfo")
            echo_bubbles:set_field("_ReloadTimer", echo_bubbles:get_field("_MaxReloadTime"))
        end


    end, function(retval) end)
end

function Module.addUI()
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."
   
    changed, Module.data.unlimited_echo_bubbles = imgui.checkbox(language.get(languagePrefix .. "unlimited_echo_bubbles"), Module.data.unlimited_echo_bubbles)
    any_changed = any_changed or changed

    return any_changed
end

function Module.reset()
    -- Implement reset functionality if needed
end

return Module
