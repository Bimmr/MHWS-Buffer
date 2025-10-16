local ModuleBase = require("Buffer.Misc.ModuleBase")

local Module = ModuleBase:new("sword_and_shield", {})

function Module.createHooks()
    
    -- Weapon changes
    -- sdk.hook(sdk.find_type_definition("app.cHunterWp11Handling"):get_method("update"), function(args) 
    --     local managed = sdk.to_managed_object(args[2])
    --     if not Module:weaponHookGuard(managed, "app.cHunterWp11Handling") then return end


    -- end, function(retval) end)
end

function Module.addUI()
    local any_changed = false
   
    imgui.text("Sword and Shield has nothing...")

    return any_changed
end

function Module.reset()
    -- Implement reset functionality if needed
end

return Module
