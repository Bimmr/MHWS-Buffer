local ModuleBase = require("Buffer.Misc.ModuleBase")

local Module = ModuleBase:new("sword_and_shield", {})

--! Sword and Shield has nothing to modify, but I'll keep this module here in case it does later

-- function Module.create_hooks()

--     sdk.hook(sdk.find_type_definition("app.cHunterWp11Handling"):get_method("doUpdate"), function(args)
--         local managed = sdk.to_managed_object(args[2])
--         if not Module:weapon_hook_guard(managed, "app.cHunterWp11Handling") then return end


--     end)
-- end

-- function Module.add_ui()
--     local any_changed = false
   
--     imgui.text("Sword and Shield has nothing...")

--     return any_changed
-- end

return Module
