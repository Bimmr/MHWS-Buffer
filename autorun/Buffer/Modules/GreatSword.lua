local utils, config, language
local Module = {
    title = "great_sword",
    data = {
        true_charge_boost = false,
        charge_level = -1,
        instant_charge = false
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
    sdk.hook(sdk.find_type_definition("app.cHunterWp00Handling"):get_method("update"), function(args) 
        local managed = sdk.to_managed_object(args[2])
        if not managed:get_type_definition():is_a("app.cHunterWp00Handling") then return end
        if not managed:get_Hunter() then return end
        if not managed:get_Hunter():get_IsMaster() then return end

        -- True charge boost
        if Module.data.true_charge_boost then 
            managed:set_field("_IsSpiritSlashEnhanced", true) 
        end

        -- Charge level
        if Module.data.charge_level >= 0 and managed:get_field("_ChargeTimer") > 0 then
            managed:set_field("_ChargeLevel", Module.data.charge_level)
        end

         -- Instant charge
        if Module.data.instant_charge then 
            managed:set_field("_ChargeTimer", 3)
            managed:set_field("_ChargeLevel", 3)
        end

    end, function(retval) end)
end

function Module.draw()
    imgui.push_id(Module.title)
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."

    if imgui.collapsing_header(language.get(languagePrefix .. "title")) then
        imgui.indent(10)
       
        changed, Module.data.true_charge_boost = imgui.checkbox(language.get(languagePrefix .. "true_charge_boost"), Module.data.true_charge_boost)
        utils.tooltip(language.get(languagePrefix .. "true_charge_boost_tooltip"))
        any_changed = any_changed or changed

        changed, Module.data.charge_level = imgui.slider_int(language.get(languagePrefix .. "charge_level"), Module.data.charge_level, -1, 3, Module.data.charge_level == -1 and language.get("base.disabled") or "%d")
        any_changed = any_changed or changed    
        
        changed, Module.data.instant_charge = imgui.checkbox(language.get(languagePrefix .. "instant_charge"), Module.data.instant_charge)
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
