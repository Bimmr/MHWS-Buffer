local utils, config, language
local Module = {
    title = "miscellaneous",
    data = {
        akuma = {
            instant_drive_gauge = false,
            gou_hadoken_max_level = false
        }
    }
}

function Module.init()
    utils = require("Buffer.Misc.Utils")
    config = require("Buffer.Misc.Config")
    language = require("Buffer.Misc.Language")

    Module.init_hooks()
end

function Module.init_hooks()


    sdk.hook(sdk.find_type_definition("app.HunterCharacter"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not managed:get_type_definition():is_a("app.HunterCharacter") then return end
        if not managed:get_IsMaster() then return end    

        local ex_emote = managed:get_ExEmote00()
        if ex_emote == nil then return end

        -- Instant Drive Gauge
        if Module.data.akuma.instant_drive_gauge then
            ex_emote:set_field("_aimAttackTimer", 0)
        end       
        
        -- Set Gou Hadoken to maximum level (Technically 1 (0-1))
        if Module.data.akuma.gou_hadoken_max_level then
            if ex_emote:get_field("<ChargeLv>k__BackingField") ~= nil and ex_emote:get_field("ChargeLvMax") ~= nil then
                local max_level = ex_emote:get_field("ChargeLvMax")
                ex_emote:set_field("<ChargeLv>k__BackingField", max_level)
            end
        end
    end, function(retval)
    end)
end

function Module.draw()
    imgui.push_id(Module.title)
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."

    if imgui.collapsing_header(language.get(languagePrefix .. "title")) then
        imgui.indent(10)        
        
        languagePrefix = Module.title .. ".akuma."
        if imgui.tree_node(language.get(languagePrefix .. "title")) then            
            
            changed, Module.data.akuma.instant_drive_gauge = imgui.checkbox(language.get(languagePrefix .. "instant_drive_gauge"), Module.data.akuma.instant_drive_gauge)
            any_changed = any_changed or changed

            changed, Module.data.akuma.gou_hadoken_max_level = imgui.checkbox(language.get(languagePrefix .. "gou_hadoken_max_level"), Module.data.akuma.gou_hadoken_max_level)
            any_changed = any_changed or changed

            imgui.tree_pop()
        end

        if any_changed then
            config.save_section(Module.create_config_section())
        end

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
    if not config_section then
        return
    end
    utils.update_table_with_existing_table(Module.data, config_section)
end

return Module
