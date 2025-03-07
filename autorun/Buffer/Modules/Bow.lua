local utils, config, language
local Module = {
    title = "bow",
    data = {
        charge_level = -1,
        all_arrow_types = false,
        unlimited_bottles = false,
        max_trick_arrow_gauge = false
    },
    old = {}
}

function Module.init()
    utils = require("Buffer.Misc.Utils")
    config = require("Buffer.Misc.Config")
    language = require("Buffer.Misc.Language")

    Module.init_hooks()
end

function Module.init_hooks()
    
    -- Weapon changes
    sdk.hook(sdk.find_type_definition("app.cHunterWp11Handling"):get_method("update"), function(args) 
        local managed = sdk.to_managed_object(args[2])
        if not managed:get_type_definition():is_a("app.cHunterWp11Handling") then return end

        -- Charge Level
        if Module.data.charge_level ~= -1 then
            managed:set_field("<ChargeLv>k__BackingField", Module.data.charge_level)
            -- Could also use charge time, but does skills change this?
            -- managed:set_field("_ChargeTimer", 2) -- 2 = level 3
        end

        -- All arrow types
        if Module.data.all_arrow_types and not Module.old.arrow_types then
            if not Module.old.arrow_types then
                Module.old.arrow_types = {}
                for i = 1, #managed:get_field("<BottleInfos>k__BackingField") do
                    local bottle_info = managed:get_field("<BottleInfos>k__BackingField")[i]
                    if bottle_info then
                        Module.old.arrow_types[i] = bottle_info:get_field("<CanLoading>k__BackingField")
                        bottle_info:set_field("<CanLoading>k__BackingField", true)
                    end
                end
            end
        elseif not Module.data.all_arrow_types and Module.old.arrow_types then
            for i = 1, #managed:get_field("<BottleInfos>k__BackingField") do
                local bottle_info = managed:get_field("<BottleInfos>k__BackingField")[i]
                if bottle_info then
                    bottle_info:set_field("<CanLoading>k__BackingField", Module.old.arrow_types[i])
                end
            end
            Module.old.arrow_types = nil
        end

        -- Manually set type of arrow
        -- <BottleType>k__BackingField
            -- 1 = Close Range
            -- 2 = Power
            -- 3 = Pierce
            -- 4 = Paralysis
            -- 5 = Poison
            -- 6 = Sleep
            -- 7 = Blast
            -- 8 = Exhaust

        -- Unlimited bottles
        if Module.data.unlimited_bottles then
            managed:set_field("<BottleNum>k__BackingField", 10)
            managed:set_field("<BottleShotCount>k__BackingField", 0)
        end

        -- Trick Arrow Gauge 
        if Module.data.max_trick_arrow_gauge then
            managed:get_field("<ArrowGauge>k__BackingField"):set_field("_Value", 100)
        end

    end, function(retval) end)
end

function Module.draw()
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."

    if imgui.collapsing_header(language.get(languagePrefix .. "title")) then
        imgui.indent(10)
       
        changed, Module.data.charge_level = imgui.slider_int(language.get(languagePrefix .. "charge_level"), Module.data.charge_level, -1, 3, Module.data.charge_level == -1 and language.get("base.disabled") or "%d")
        any_changed = any_changed or changed

        changed, Module.data.all_arrow_types = imgui.checkbox(language.get(languagePrefix .. "all_arrow_types"), Module.data.all_arrow_types)
        any_changed = any_changed or changed

        changed, Module.data.unlimited_bottles = imgui.checkbox(language.get(languagePrefix .. "unlimited_bottles"), Module.data.unlimited_bottles)
        any_changed = any_changed or changed

        changed, Module.data.max_trick_arrow_gauge = imgui.checkbox(language.get(languagePrefix .. "max_trick_arrow_gauge"), Module.data.max_trick_arrow_gauge)
        any_changed = any_changed or changed

        if any_changed then config.save_section(Module.create_config_section()) end
        imgui.unindent(10)
        imgui.separator()
        imgui.spacing()
    end
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
    utils.mergeTables(Module.data, config_section)
end

return Module
