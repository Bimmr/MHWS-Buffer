local utils, config, language
local Module = {
    title = "lance",
    data = {
        counter_charge_level = -1,
        rush_level = -1,
        infinite_backstep = false,
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
    sdk.hook(sdk.find_type_definition("app.cHunterWp06Handling"):get_method("update"), function(args) 
        local managed = sdk.to_managed_object(args[2])
        if not managed:get_type_definition():is_a("app.cHunterWp06Handling") then return end
        if not managed:get_Hunter() then return end
        if not managed:get_Hunter():get_IsMaster() then return end

        -- Counter charge level
        if Module.data.counter_charge_level ~= -1 then 
            managed:set_field("_FinishChargeLevel", Module.data.counter_charge_level) 
        end

        -- Rush level
        if Module.data.rush_level ~= -1 then 
            managed:set_field("_RushLevel", Module.data.rush_level) 
            managed:set_field("_RushLevelTimer", 1.4)
        end

    end, function(retval) end)
end

function Module.draw()
    imgui.push_id(Module.title)
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."

    if imgui.collapsing_header("    " .. language.get(languagePrefix .. "title")) then
        imgui.indent(10)
       
        changed, Module.data.counter_charge_level = imgui.slider_int(language.get(languagePrefix .. "counter_charge_level"), Module.data.counter_charge_level, -1, 3, Module.data.counter_charge_level == -1 and language.get("base.disabled") or "%d")
        any_changed = any_changed or changed     

        changed, Module.data.rush_level = imgui.slider_int(language.get(languagePrefix .. "rush_level"), Module.data.rush_level, -1, 1, Module.data.rush_level == -1 and language.get("base.disabled") or "%d")
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
