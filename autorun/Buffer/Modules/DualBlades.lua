local utils, config, language
local Module = {
    title = "dual_blades",
    data = {
        demon_gauge = false,
        demon_boost = false
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
    sdk.hook(sdk.find_type_definition("app.cHunterWp02Handling"):get_method("update"), function(args) 
        local managed = sdk.to_managed_object(args[2])
        if not managed:get_type_definition():is_a("app.cHunterWp02Handling") then return end
        if not managed:get_Hunter() then return end
        if not managed:get_Hunter():get_IsMaster() then return end

        -- Demon Gauge
        if Module.data.demon_gauge then 
            managed:get_field("<KijinGauge>k__BackingField"):set_field("_Value", 1.0)  
        end
        -- Demon Boost Mode
        if Module.data.demon_boost then 
            managed:set_field("<IsMikiriBuff>k__BackingField", true) 
        end

    end, function(retval) end)
end

function Module.draw()
    imgui.push_id(Module.title)
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."

    if imgui.collapsing_header("    " .. language.get(languagePrefix .. "title")) then
        imgui.indent(10)
        
        changed, Module.data.demon_gauge = imgui.checkbox(language.get(languagePrefix .. "demon_gauge"), Module.data.demon_gauge)
        any_changed = any_changed or changed
        changed, Module.data.demon_boost = imgui.checkbox(language.get(languagePrefix .. "demon_boost"), Module.data.demon_boost)
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
