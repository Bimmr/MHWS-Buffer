local utils, config, language
local Module = {
    title = "charge_blade",
    data = {
        max_phials = false,
        overcharge_phials = false,
        shield_enhanced = false,
        sword_enhanced = false,
        axe_enhanced = false        
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
    sdk.hook(sdk.find_type_definition("app.cHunterWp09Handling"):get_method("update"), function(args) 
        local managed = sdk.to_managed_object(args[2])
        if not managed:get_type_definition():is_a("app.cHunterWp09Handling") then return end
        if not managed:get_Hunter() then return end
        if not managed:get_Hunter():get_IsMaster() then return end

        -- no overheat sword (Also no charge) _swordEnergyPoint:_Value

        -- Max Phials
        if Module.data.max_phials then
            managed:get_field("_SwordBinNum"):set_field("_Value", 10)
        end

        -- Overcharge Phials
        if Module.data.overcharge_phials then
            local phials = managed:get_field("_SwordBinNum"):get_field("_Value")
            managed:get_field("_SwordOverChargedBinNum"):set_field("_Value", phials / 2)
        end

        -- Shield Enhanced
        if Module.data.shield_enhanced then
            managed:set_field("_ShieldEnhancedTimer", 300)
        end

        -- Sword Enhanced
        if Module.data.sword_enhanced then
            managed:set_field("_SwordEnhancedTimer", 90)
        end

        -- Axe Enhanced
        if Module.data.axe_enhanced then
            managed:set_field("_AxeEnhancedTimer", 120)
        end

    end, function(retval) end)
end

function Module.draw()
    imgui.push_id(Module.title)
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."

    if imgui.collapsing_header("    " .. language.get(languagePrefix .. "title")) then
        imgui.indent(10)
       
        changed, Module.data.max_phials = imgui.checkbox(language.get(languagePrefix .. "max_phials"), Module.data.max_phials)
        any_changed = any_changed or changed

        changed, Module.data.overcharge_phials = imgui.checkbox(language.get(languagePrefix .. "overcharge_phials"), Module.data.overcharge_phials)
        any_changed = any_changed or changed

        imgui.begin_table(languagePrefix.."title", 3, nil, nil, nil)
        imgui.table_next_row()
        imgui.table_next_column()

        changed, Module.data.shield_enhanced = imgui.checkbox(language.get(languagePrefix .. "shield_enhanced"), Module.data.shield_enhanced)
        any_changed = any_changed or changed

        imgui.table_next_column()

        changed, Module.data.sword_enhanced = imgui.checkbox(language.get(languagePrefix .. "sword_enhanced"), Module.data.sword_enhanced)
        any_changed = any_changed or changed

        imgui.table_next_column()

        changed, Module.data.axe_enhanced = imgui.checkbox(language.get(languagePrefix .. "axe_enhanced"), Module.data.axe_enhanced)
        any_changed = any_changed or changed

        imgui.end_table()

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
