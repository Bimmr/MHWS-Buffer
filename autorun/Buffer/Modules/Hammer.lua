local ModuleBase = require("Buffer.Misc.ModuleBase")
local language = require("Buffer.Misc.Language")

local Module = ModuleBase:new("hammer", {
    charge_level = -1,
    super_charge_level = -1,
    instant_charge = false,
})

function Module.create_hooks()
    
    sdk.hook(sdk.find_type_definition("app.cHunterWp04Handling"):get_method("update"), function(args) 
        local managed = sdk.to_managed_object(args[2])
        if not Module:weapon_hook_guard(managed, "app.cHunterWp04Handling") then return end

       -- Charge level
       if Module.data.charge_level >= 0 and managed:get_field("_ChargeTimer") > 0 then
            managed:set_field("<ChargeLv>k__BackingField", Module.data.charge_level + 1)
       end

         -- Super charge level
       if Module.data.super_charge_level >= 0 and managed:get_field("_SuperChargeTimer") > 0 then
            managed:set_field("<SuperChargeLv>k__BackingField", Module.data.super_charge_level + 1)
       end

       -- Instant charge
        if Module.data.instant_charge then 
            managed:set_field("_ChargeTimer", 3) 
        end

    end, function(retval) end)
end

function Module.add_ui()
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."

    changed, Module.data.charge_level = imgui.slider_int(language.get(languagePrefix .. "charge_level"), Module.data.charge_level, -1, 2, Module.data.charge_level == -1 and language.get("base.disabled") or tostring(Module.data.charge_level + 1))
    any_changed = any_changed or changed

    changed, Module.data.super_charge_level = imgui.slider_int(language.get(languagePrefix .. "super_charge_level"), Module.data.super_charge_level, -1, 2, Module.data.super_charge_level == -1 and language.get("base.disabled") or tostring(Module.data.super_charge_level + 1))
    any_changed = any_changed or changed

    changed, Module.data.instant_charge = imgui.checkbox(language.get(languagePrefix .. "instant_charge"), Module.data.instant_charge)
    any_changed = any_changed or changed

    return any_changed
end

return Module
