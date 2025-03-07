local utils, config, language
local Module = {
    title = "bow",
    data = {
       
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
    sdk.hook(sdk.find_type_definition("app.cHunterWp11Handling"):get_method("update"), function(args) 
        local managed = sdk.to_managed_object(args[2])
        if not managed:get_type_definition():is_a("app.cHunterWp11Handling") then return end

        -- Max Charge, use one of the below
        -- <ChargeLv>k__BackingField = 1 - 3
        -- _ChargeTimer  = 2.2

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

            -- Could loop through and set all to true for all arrow types
            -- <BottleInfos>k__BackingField[]
                --  <CanLoading>k__BackingField = true/false
            -- If using above, make a backup of the original to reset if disabled


        -- <BottleNum>k__BackingField = 1 - 10 (If unlimited set to 10)
        -- If setting above, also set <BottleShotCount>k__BackingField to 10 - above


        -- <ArrowGauge>k__BackingField = 0 - 100 (Trick Arrow Gauge)

    end, function(retval) end)
end

function Module.draw()
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."

    if imgui.collapsing_header(language.get(languagePrefix .. "title")) then
        imgui.indent(10)
       

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
