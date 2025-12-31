local ModuleBase = require("Buffer.Misc.ModuleBase")
local language = require("Buffer.Misc.Language")

local Module = ModuleBase:new("charge_blade", {
    max_phials = false,
    overcharge_phials = false,
    shield_enhanced = false,
    sword_enhanced = false,
    axe_enhanced = false  
})

function Module:init()
    ModuleBase.init(self)
end

function Module.create_hooks()
    
    Module:init_stagger("charge_blade_handling_update", 10)
    sdk.hook(sdk.find_type_definition("app.cHunterWp09Handling"):get_method("doUpdate"), function(args) 
        local managed = sdk.to_managed_object(args[2])
        if not Module:weapon_hook_guard(managed, "app.cHunterWp09Handling") then return end

        if not Module:should_execute_staggered("charge_blade_handling_update") then return end

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

    end)
end

function Module.add_ui()
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."
       
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

    return any_changed
end

return Module
