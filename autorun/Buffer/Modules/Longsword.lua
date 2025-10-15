local utils, config, language
local Module = {
    title = "long_sword",
    data = {
        aura_level = -1,
        max_aura_gauge = false,
        max_spirit_gauge = false,
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
    sdk.hook(sdk.find_type_definition("app.cHunterWp03Handling"):get_method("update"), function(args) 
        local managed = sdk.to_managed_object(args[2])
        if not managed:get_type_definition():is_a("app.cHunterWp03Handling") then return end
        if not managed:get_Hunter() then return end
        if not managed:get_Hunter():get_IsMaster() then return end

        -- Aura level
        if Module.data.aura_level ~= -1 then
            managed:set_field("<AuraLevel>k__BackingField", Module.data.aura_level+1)
        end

        -- Max aura gauge
        if Module.data.max_aura_gauge then 
            managed:get_field("<AuraGauge>k__BackingField"):set_field("_Value", 195) 
        end

        -- Max spirit gauge
        if Module.data.max_spirit_gauge then 
            managed:get_field("<RenkiGauge>k__BackingField"):set_field("_Value", 100)
        end

        -- <KabutowariAuraLevel>k__BackingField -- The dropping from the sky attack, not sure what it does besides that it's associated with that
        -- _KijinChargeLv -- Not sure


    end, function(retval) end)
end

function Module.draw()
    imgui.push_id(Module.title)
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."

    if imgui.collapsing_header("    " .. language.get(languagePrefix .. "title")) then
        imgui.indent(10)
       
        changed, Module.data.aura_level = imgui.slider_int(language.get(languagePrefix .. "aura_level"), Module.data.aura_level, -1, 3, Module.data.aura_level == -1 and language.get("base.disabled") or "%d")   
        utils.tooltip(language.get(languagePrefix .. "aura_level_tooltip"))
        any_changed = any_changed or changed

        changed, Module.data.max_aura_gauge = imgui.checkbox(language.get(languagePrefix .. "max_aura_gauge"), Module.data.max_aura_gauge)
        any_changed = any_changed or changed

        changed, Module.data.max_spirit_gauge = imgui.checkbox(language.get(languagePrefix .. "max_spirit_gauge"), Module.data.max_spirit_gauge)
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
