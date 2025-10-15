local utils, config, language
local Module = {
    title = "switch_axe",
    data = {
        max_charge = false,
        max_sword_charge = false,
        powered_axe = false,
    }
}

function Module.init()
    utils = require("Buffer.Misc.Utils")
    config = require("Buffer.Misc.Config")
    language = require("Buffer.Misc.Language")

    Module.init_hooks()
end

function Module.init_hooks()
    
    -- Weapon changes
    sdk.hook(sdk.find_type_definition("app.cHunterWp08Handling"):get_method("update"), function(args) 
        local managed = sdk.to_managed_object(args[2])
        if not managed:get_type_definition():is_a("app.cHunterWp08Handling") then return end
        if not managed:get_Hunter() then return end
        if not managed:get_Hunter():get_IsMaster() then return end

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

function Module.draw()
    imgui.push_id(Module.title)
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."

    if imgui.collapsing_header("    " .. language.get(languagePrefix .. "title")) then
        imgui.indent(10)
       
        changed, Module.data.max_charge = imgui.checkbox(language.get(languagePrefix .. "max_charge"), Module.data.max_charge)
        any_changed = any_changed or changed

        changed, Module.data.max_sword_charge = imgui.checkbox(language.get(languagePrefix .. "max_sword_charge"), Module.data.max_sword_charge)
        any_changed = any_changed or changed

        changed, Module.data.powered_axe = imgui.checkbox(language.get(languagePrefix .. "powered_axe"), Module.data.powered_axe)
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
