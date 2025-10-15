local utils, config, language
local Module = {
    title = "gunlance",
    data = {
        shell_level = -1,
        infinite_wyvern_fire = false,
        infinite_backstep = false,
        instant_charge = false,
        unlimited_ammo = false,
    }
}

function Module.init()
    utils = require("Buffer.Misc.Utils")
    config = require("Buffer.Misc.Config")
    language = require("Buffer.Misc.Language")

    Module.init_hooks()
end

local function update_field(field_name, managed, new_value)
    if Module.old == nil then Module.old = {} end
    if Module.old[field_name] == nil then Module.old[field_name] = managed:get_field(field_name) end
    if new_value >= 0 then 
        managed:set_field(field_name, new_value) 
    else
        managed:set_field(field_name, Module.old[field_name])
        Module.old[field_name] = nil
    end 
end

function Module.init_hooks()
    
    -- Weapon changes
    sdk.hook(sdk.find_type_definition("app.cHunterWp07Handling"):get_method("update"), function(args) 
        local managed = sdk.to_managed_object(args[2])
        if not managed:get_type_definition():is_a("app.cHunterWp07Handling") then return end
        if not managed:get_Hunter() then return end
        if not managed:get_Hunter():get_IsMaster() then return end

        local ammo = managed:get_field("_Ammo")

        -- Shell level
        update_field("_ShellLevel", managed, Module.data.shell_level)

        -- Infinite wyvernshots
        if Module.data.infinite_wyvern_fire then 
            managed:get_field("_RyuugekiGauge"):set_field("_Value", 2)
        end

        -- Instant charge
        if Module.data.instant_charge then 
            local max_ammo = ammo:get_LimitAmmo()
            managed:set_field("_ChargeShotBulletNum", max_ammo)
            managed:set_field("_ChargeShotElapsedTimer", max_ammo * 1.1)
        end

        -- Unlimited ammo
        if Module.data.unlimited_ammo then 
            ammo:setLoadedAmmo(ammo:get_LimitAmmo())
        end


    end, function(retval) end)
end

function Module.draw()
    imgui.push_id(Module.title)
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."

    if imgui.collapsing_header("    " .. language.get(languagePrefix .. "title")) then
        imgui.indent(10)
       

        changed, Module.data.unlimited_ammo = imgui.checkbox(language.get(languagePrefix .. "unlimited_ammo"), Module.data.unlimited_ammo)
        any_changed = any_changed or changed

        changed, Module.data.instant_charge = imgui.checkbox(language.get(languagePrefix .. "instant_charge"), Module.data.instant_charge)
        any_changed = any_changed or changed

        changed, Module.data.shell_level = imgui.slider_int(language.get(languagePrefix .. "shell_level"), Module.data.shell_level, -1, 6, Module.data.shell_level == -1 and language.get("base.disabled") or "%d")
        any_changed = any_changed or changed
        
        changed, Module.data.infinite_wyvern_fire = imgui.checkbox(language.get(languagePrefix .. "infinite_wyvern_fire"), Module.data.infinite_wyvern_fire)
        any_changed = any_changed or changed
        
        if any_changed then config.save_section(Module.create_config_section()) end
        imgui.unindent(10)
        imgui.separator()
        imgui.spacing()
    end
    imgui.pop_id()
end

function Module.reset()
    -- Implement reset functionality if needed
end

function Module.create_config_section()
    return {
        [Module.title] = Module.data
    }
end

function Module.load_from_config(config_section)
    if not config_section then return end
    utils.update_table_with_existing_table(Module.data, config_section)
end

return Module
